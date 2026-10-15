{-
SPDX-License-Identifier: PMPL-1.0-or-later
SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
-}

{-# LANGUAGE OverloadedStrings #-}

-- | Warrant levels for provenance claims (spec/PROVENANCE-SPEC.adoc §7).
--
-- Every claim gets a level.  A @signed-by@ claim is 'LevelSound' only when
-- its signature verifies here, under the rule @signature-verify@, whose
-- entailment is proved in proofs/agda/Provenance/Warrant.agda with the
-- EUF-CMA assumption as a parameter.  That this module's Ed25519 check (the
-- crypton library) implements the proof's @verify@ is assumed, not proved.
--
-- No rule concludes @licensed-under@ or @consented-for-training@: a header
-- that declares a licence or consent is a token, so those claims are at
-- most 'LevelEpi', and 'statedRecord' cannot return anything higher.
module Palimpsest.Validator.Provenance
  ( ProvenanceFile(..)
  , ChainEntry(..)
  , StatedClaim(..)
  , ClaimRecord(..)
  , Evidence(..)
  , SoundBy(..)
  , Failure(..)
  , readProvenance
  , checkProvenance
  , checkProvenanceFile
  , signedMessage
  , signatureVerifyRule
  , signatureVerifyAssumption
  , renderClaim
  , renderFailedCheck
  , renderSummary
  , recordsJSON
  ) where

import Crypto.Error (CryptoFailable(..))
import Crypto.Hash (Digest, SHA256, hash)
import qualified Crypto.PubKey.Ed25519 as Ed25519
import Data.Aeson
  ( FromJSON(..), ToJSON(..), Value(..), eitherDecodeStrict', object
  , withObject, (.:), (.=) )
import Data.Aeson.Encode.Pretty (Config(..), defConfig, encodePretty', keyOrder)
import Data.ByteArray.Encoding (Base(Base16), convertFromBase, convertToBase)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL
import Data.List (find)
import Data.Maybe (mapMaybe)
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import System.FilePath (takeDirectory, takeFileName, (</>))

import Palimpsest.Validator.Types (WarrantLevel(..))

-- | One entry of a provenance chain (§2.4): a signature over the record
-- 'signedMessage' rebuilds.
data ChainEntry = ChainEntry
  { entryStandpoint     :: Text
  , entryAlgorithm      :: Text
  , entryPk             :: Text        -- ^ hex
  , entryArtefactSha256 :: Text        -- ^ hex
  , entryTimestamp      :: Text        -- ^ a signed field, not a measured one
  , entryParent         :: Maybe Text  -- ^ SHA-256 of the previous entry's record
  , entrySignature      :: Text        -- ^ hex
  } deriving stock (Show, Eq)

-- | A claim the provenance file makes that no signature decides.
data StatedClaim = StatedClaim
  { statedKind       :: Text
  , statedStandpoint :: Text
  , statedSubject    :: Text
  , statedStatement  :: Text
  } deriving stock (Show, Eq)

data ProvenanceFile = ProvenanceFile
  { provArtefact :: Text
  , provChain    :: [ChainEntry]
  , provClaims   :: [StatedClaim]
  } deriving stock (Show, Eq)

instance FromJSON ChainEntry where
  parseJSON = withObject "ChainEntry" $ \o -> ChainEntry
    <$> o .: "standpoint"
    <*> o .: "algorithm"
    <*> o .: "pk"
    <*> o .: "artefact_sha256"
    <*> o .: "timestamp"
    <*> o .: "parent"
    <*> o .: "signature"

instance FromJSON StatedClaim where
  parseJSON = withObject "StatedClaim" $ \o -> StatedClaim
    <$> o .: "kind"
    <*> o .: "standpoint"
    <*> o .: "subject"
    <*> o .: "statement"

instance FromJSON ProvenanceFile where
  parseJSON = withObject "ProvenanceFile" $ \o -> ProvenanceFile
    <$> o .: "artefact"
    <*> o .: "chain"
    <*> o .: "claims"

data Evidence = Evidence
  { evidenceKind :: Text
  , evidenceRef  :: Text
  } deriving stock (Show, Eq)

data SoundBy = SoundBy
  { soundRule       :: Text
  , soundAssumption :: Text
  } deriving stock (Show, Eq)

-- | A provenance record in the shape of formats/warrant.ncl.
data ClaimRecord = ClaimRecord
  { recArtefact   :: Text
  , recKind       :: Text
  , recStandpoint :: Text
  , recSubject    :: Text
  , recStatement  :: Text
  , recLevel      :: WarrantLevel
  , recEvidence   :: [Evidence]
  , recSoundBy    :: Maybe SoundBy
  } deriving stock (Show, Eq)

-- | A token that failed its check (§7.3 rule 7).  Its claim is still
-- reported, at the level the remaining tokens support.
data Failure = Failure
  { failureRecord :: ClaimRecord
  , failureReason :: Text
  } deriving stock (Show, Eq)

instance ToJSON Evidence where
  toJSON e = object ["kind" .= evidenceKind e, "ref" .= evidenceRef e]

instance ToJSON ClaimRecord where
  toJSON r = object
    [ "artefact" .= recArtefact r
    , "claim" .= object
        [ "kind" .= recKind r
        , "standpoint" .= recStandpoint r
        , "subject" .= recSubject r
        , "statement" .= recStatement r
        ]
    , "level" .= levelName (recLevel r)
    , "evidence" .= recEvidence r
    , "sound_by" .= maybe Null soundJSON (recSoundBy r)
    ]
    where
      soundJSON s = object ["rule" .= soundRule s, "assumption" .= soundAssumption s]

levelName :: WarrantLevel -> Text
levelName LevelWarrant = "warrant"
levelName LevelEpi     = "epi"
levelName LevelSound   = "sound"

-- | The registered rule and its assumption, verbatim (spec §7.5,
-- formats/warrant.ncl).
signatureVerifyRule, signatureVerifyAssumption :: Text
signatureVerifyRule = "signature-verify"
signatureVerifyAssumption =
  "EUF-CMA security of the signature algorithm named in each signature"

-- | The bytes each chain entry signs.
signedMessage :: Text -> ChainEntry -> BS.ByteString
signedMessage artefact e = TE.encodeUtf8 $ T.concat
  [ "PMPL-SIG/1\n"
  , "artefact: ", artefact, "\n"
  , "artefact-sha256: ", entryArtefactSha256 e, "\n"
  , "timestamp: ", entryTimestamp e, "\n"
  , "parent: ", maybe "-" id (entryParent e), "\n"
  ]

sha256Hex :: BS.ByteString -> Text
sha256Hex bytes = TE.decodeUtf8 (convertToBase Base16 (hash bytes :: Digest SHA256))

fromHex :: Text -> Maybe BS.ByteString
fromHex t = either (const Nothing) Just (convertFromBase Base16 (TE.encodeUtf8 t))

readProvenance :: FilePath -> IO (Either String ProvenanceFile)
readProvenance path = eitherDecodeStrict' <$> BS.readFile path

-- | Read a provenance file and the artefact it names (relative to it).
checkProvenanceFile :: FilePath -> IO (Either String ([ClaimRecord], [Failure]))
checkProvenanceFile path = do
  parsed <- readProvenance path
  case parsed of
    Left err -> pure (Left err)
    Right prov -> do
      bytes <- BS.readFile (takeDirectory path </> T.unpack (provArtefact prov))
      pure (Right (checkProvenance (T.pack (takeFileName path)) prov bytes))

-- | Levels for every claim: one @signed-by@ per chain entry, then the
-- stated claims.  The first argument names the provenance file in refs.
checkProvenance :: Text -> ProvenanceFile -> BS.ByteString -> ([ClaimRecord], [Failure])
checkProvenance provName prov bytes = (records, failures)
  where
    artefact = provArtefact prov
    chain    = provChain prov
    parents  = Nothing : map (Just . sha256Hex . signedMessage artefact) chain
    checked  = zipWith3 (entryRecord provName artefact bytes) [0 ..] parents chain
    stated   = map (statedRecord artefact bytes) (provClaims prov)
    records  = map fst checked ++ map fst stated
    failures = mapMaybe (\(r, why) -> Failure r <$> why) (checked ++ stated)

entryRecord :: Text -> Text -> BS.ByteString -> Int -> Maybe Text -> ChainEntry
            -> (ClaimRecord, Maybe Text)
entryRecord provName artefact bytes i parent e
  | T.toLower (entryArtefactSha256 e) /= sha256Hex bytes =
      failed "the artefact's SHA-256 does not match the signed record"
  | fmap T.toLower (entryParent e) /= parent =
      failed (T.pack ("the parent link does not match entry " ++ show (i - 1)))
  | entryAlgorithm e /= "ed25519" =
      -- §7.5: a signature this tool cannot verify is held as a token.
      (record LevelEpi [token] Nothing, Nothing)
  | otherwise = case (,) <$> (fromHex (entryPk e) >>= key) <*> (fromHex (entrySignature e) >>= sig) of
      Nothing -> failed "the public key or signature is malformed"
      Just (pk, s)
        | Ed25519.verify pk (signedMessage artefact e) s ->
            (record LevelSound [token] (Just (SoundBy signatureVerifyRule signatureVerifyAssumption)), Nothing)
        | otherwise -> failed "the signature does not verify"
  where
    token = Evidence "signature-chain" (provName <> "#chain[" <> T.pack (show i) <> "]")
    record level ev sb = ClaimRecord
      { recArtefact = artefact
      , recKind = "signed-by"
      , recStandpoint = "verifier"
      , recSubject = entryAlgorithm e <> ":" <> entryPk e
      , recStatement = "the " <> entryStandpoint e <> "'s key signed the record binding the hash of "
          <> artefact <> " and the timestamp " <> entryTimestamp e
      , recLevel = level
      , recEvidence = ev
      , recSoundBy = sb
      }
    -- The failed token is not a token; nothing else is held (rule 7).
    failed why = (record LevelWarrant [] Nothing, Just why)
    key b = case Ed25519.publicKey b of CryptoPassed k -> Just k; CryptoFailed _ -> Nothing
    sig b = case Ed25519.signature b of CryptoPassed k -> Just k; CryptoFailed _ -> Nothing

-- | A stated claim is held at 'LevelEpi' when the artefact carries its token
-- and at 'LevelWarrant' when it does not.  There is no 'LevelSound' case.
statedRecord :: Text -> BS.ByteString -> StatedClaim -> (ClaimRecord, Maybe Text)
statedRecord artefact bytes c = case statedKind c of
  "licensed-under" ->
    held (headerLine ("SPDX-License-Identifier: " <> statedSubject c)) "spdx-header"
  "consented-for-training" ->
    held (headerLine "AI-Training: permitted") "licence-header"
  "derived-from" -> (record LevelWarrant [], Nothing)
  other -> (record LevelWarrant [], Just ("unknown claim kind " <> other))
  where
    numbered = zip [1 :: Int ..] (T.lines (TE.decodeUtf8 bytes))
    headerLine prefix = fst <$> find (T.isPrefixOf prefix . snd) numbered
    held found kind = case found of
      Just n  -> (record LevelEpi [Evidence kind (artefact <> ":" <> T.pack (show n))], Nothing)
      Nothing -> (record LevelWarrant [], Nothing)
    record level ev = ClaimRecord
      { recArtefact = artefact
      , recKind = statedKind c
      , recStandpoint = statedStandpoint c
      , recSubject = statedSubject c
      , recStatement = statedStatement c
      , recLevel = level
      , recEvidence = ev
      , recSoundBy = Nothing
      }

-- | One line per claim.  Only 'LevelSound' says "verified"; the others say
-- what is held and that it is not verified (§7.3 rule 5).
renderClaim :: ClaimRecord -> Text
renderClaim r = T.justifyLeft 9 ' ' (levelName (recLevel r)) <> recKind r <> " " <> recSubject r
  <> ": " <> case recLevel r of
    LevelSound -> "verified, assuming " <> maybe "" soundAssumption (recSoundBy r)
    LevelEpi -> "evidence present (" <> T.intercalate ", " (map ref (recEvidence r)) <> "), not verified"
    LevelWarrant -> "claimed, no evidence held"
  where
    ref e = evidenceKind e <> " " <> evidenceRef e

renderFailedCheck :: Failure -> Text
renderFailedCheck f = "FAILED   " <> recKind r <> " " <> recSubject r <> ": " <> failureReason f
  <> "; held at " <> levelName (recLevel r)
  where r = failureRecord f

renderSummary :: [ClaimRecord] -> [Failure] -> Text
renderSummary rs fs = T.pack $ show (length rs) ++ " claims: "
  ++ count LevelSound ++ " sound, " ++ count LevelEpi ++ " epi, "
  ++ count LevelWarrant ++ " warrant; " ++ show (length fs) ++ " failed"
  where count l = show (length (filter ((== l) . recLevel) rs))

-- | The records as formats/warrant.ncl expects them, keys in a fixed order.
recordsJSON :: [ClaimRecord] -> BL.ByteString
recordsJSON = encodePretty' defConfig { confCompare = keyOrder order }
  where
    order = ["artefact", "claim", "kind", "standpoint", "subject", "statement", "level", "evidence", "ref", "sound_by", "rule", "assumption"]
