{-
SPDX-License-Identifier: PMPL-1.0-or-later
SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
-}

{-# LANGUAGE OverloadedStrings #-}

module Palimpsest.Validator.ProvenanceSpec (provenanceSpec) where

import Data.Aeson (Value, eitherDecode)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import System.FilePath ((</>))
import Test.Hspec
import Test.QuickCheck

import Palimpsest.Validator.Provenance
import Palimpsest.Validator.Types (WarrantLevel(..))

-- | tests/warrant/fixture, from the package directory cabal runs tests in.
fixtureDir :: FilePath
fixtureDir = ".." </> ".." </> ".." </> "tests" </> "warrant" </> "fixture"

loadFixture :: IO (ProvenanceFile, BS.ByteString)
loadFixture = do
  parsed <- readProvenance (fixtureDir </> "poem.txt.provenance.json")
  prov <- either fail pure parsed
  bytes <- BS.readFile (fixtureDir </> "poem.txt")
  pure (prov, bytes)

check :: ProvenanceFile -> BS.ByteString -> ([ClaimRecord], [Failure])
check = checkProvenance "poem.txt.provenance.json"

levels :: [ClaimRecord] -> [(T.Text, WarrantLevel)]
levels = map (\r -> (recKind r, recLevel r))

-- Replace the first character of a hex field with a different hex digit.
flipHex :: T.Text -> T.Text
flipHex t = case T.uncons t of
  Just ('0', rest) -> T.cons '1' rest
  Just (_, rest)   -> T.cons '0' rest
  Nothing          -> t

onEntry :: Int -> (ChainEntry -> ChainEntry) -> ProvenanceFile -> ProvenanceFile
onEntry i f prov = prov { provChain = zipWith pick [0 ..] (provChain prov) }
  where pick j e = if j == i then f e else e

provenanceSpec :: Spec
provenanceSpec = describe "Palimpsest.Validator.Provenance (PROVENANCE-SPEC section 7)" $ do

  it "puts the signature chain at sound and the consent claim at epi on the same artefact" $ do
    (prov, bytes) <- loadFixture
    let (rs, fs) = check prov bytes
    fs `shouldBe` []
    map recArtefact rs `shouldSatisfy` all (== "poem.txt")
    levels rs `shouldBe`
      [ ("signed-by", LevelSound)
      , ("signed-by", LevelSound)
      , ("licensed-under", LevelEpi)
      , ("consented-for-training", LevelEpi)
      ]
    map recSoundBy (take 2 rs) `shouldBe`
      replicate 2 (Just (SoundBy signatureVerifyRule signatureVerifyAssumption))

  it "emits exactly the committed expected.json, which formats/warrant.ncl checks" $ do
    (prov, bytes) <- loadFixture
    expected <- BL.readFile (fixtureDir </> "expected.json")
    let decode = eitherDecode :: BL.ByteString -> Either String Value
    decode (recordsJSON (fst (check prov bytes))) `shouldBe` decode expected

  it "renders only sound claims as verified, and every other claim as not verified" $ do
    (prov, bytes) <- loadFixture
    let (rs, _) = check prov bytes
    mapM_ (\r -> do
             let line = renderClaim r
             case recLevel r of
               LevelSound -> line `shouldSatisfy` T.isInfixOf ": verified, assuming "
               _ -> do
                 line `shouldSatisfy` T.isSuffixOf "not verified"
                 line `shouldNotSatisfy` T.isInfixOf ": verified")
          rs
    renderSummary rs [] `shouldBe` "4 claims: 2 sound, 2 epi, 0 warrant; 0 failed"

  it "fails both signatures over a changed artefact and holds them at warrant" $ do
    (prov, bytes) <- loadFixture
    let (rs, fs) = check prov (bytes <> "one more line\n")
    levels (take 2 rs) `shouldBe` replicate 2 ("signed-by", LevelWarrant)
    map recEvidence (take 2 rs) `shouldBe` [[], []]
    map failureReason fs `shouldBe`
      replicate 2 "the artefact's SHA-256 does not match the signed record"

  it "fails a signature that does not verify, and only that one" $ do
    (prov, bytes) <- loadFixture
    let (rs, fs) = check (onEntry 1 (\e -> e { entrySignature = flipHex (entrySignature e) }) prov) bytes
    levels (take 2 rs) `shouldBe` [("signed-by", LevelSound), ("signed-by", LevelWarrant)]
    map failureReason fs `shouldBe` ["the signature does not verify"]

  it "fails an entry whose signature is valid for a different signer" $ do
    (prov, bytes) <- loadFixture
    let swapped = onEntry 1 (\e -> e { entryPk = entryPk (head (provChain prov)) }) prov
        (rs, fs) = check swapped bytes
    recLevel (rs !! 1) `shouldBe` LevelWarrant
    map failureReason fs `shouldBe` ["the signature does not verify"]

  it "fails a broken parent link" $ do
    (prov, bytes) <- loadFixture
    let (rs, fs) = check (onEntry 1 (\e -> e { entryParent = fmap flipHex (entryParent e) }) prov) bytes
    recLevel (rs !! 1) `shouldBe` LevelWarrant
    map failureReason fs `shouldBe` ["the parent link does not match entry 0"]

  it "holds a signature in an algorithm it cannot check at epi, not sound" $ do
    (prov, bytes) <- loadFixture
    let (rs, fs) = check (onEntry 0 (\e -> e { entryAlgorithm = "ml-dsa-65" }) prov) bytes
    levels (take 1 rs) `shouldBe` [("signed-by", LevelEpi)]
    recSoundBy (head rs) `shouldBe` Nothing
    fs `shouldBe` []

  it "holds the consent claim at warrant when the artefact carries no consent header" $ do
    (prov, bytes) <- loadFixture
    let stripped = TE.encodeUtf8 . T.unlines . filter (not . T.isPrefixOf "AI-Training:")
                 . T.lines . TE.decodeUtf8 $ bytes
        (rs, _) = check prov stripped
    lookup "consented-for-training" (levels rs) `shouldBe` Just LevelWarrant

  it "never puts a licence or consent claim at sound, whatever the artefact says" $
    property $ \(ASCIIString s) -> ioProperty $ do
      (prov, _) <- loadFixture
      let header = "SPDX-License-Identifier: PMPL-1.0-or-later\nAI-Training: permitted\n"
          (rs, _) = check prov { provChain = [] } (TE.encodeUtf8 (header <> T.pack s))
      pure (length rs == 2 && all ((/= LevelSound) . recLevel) rs)
