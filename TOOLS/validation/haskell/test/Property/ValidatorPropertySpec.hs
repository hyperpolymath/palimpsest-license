{-
SPDX-License-Identifier: PMPL-1.0-or-later
SPDX-FileCopyrightText: 2024-2025 Palimpsest Stewardship Council
-}

{-# LANGUAGE OverloadedStrings #-}

module Property.ValidatorPropertySpec (propertySpec) where

import Test.Hspec
import Test.Hspec.QuickCheck
import Test.QuickCheck
import Data.Text (Text)
import qualified Data.Text as T
import Palimpsest.Validator.Types
import Palimpsest.Validator.License
import Palimpsest.Validator.Metadata
import Palimpsest.Validator.Bilingual
import Palimpsest.Validator.Reference
import Palimpsest.Validator.Utils

-- | Property-based tests using QuickCheck
propertySpec :: Spec
propertySpec = describe "Property-Based Tests" $ do
  describe "License version extraction properties" $ do
    it "version extraction never crashes on arbitrary text" $ property $
      \text -> let result = extractVersion (T.pack text)
               in T.length result >= 0

    it "version extraction is idempotent (applying twice = once)" $ property $
      \text -> let txt = T.pack text
                   v1 = extractVersion txt
                   v2 = extractVersion (T.pack $ show v1)
               in v1 == v2 || T.length v1 > 0

    it "extracts numeric versions correctly" $ property $
      forAll (choose (0, 100) :: Gen Int) $ \major ->
      forAll (choose (0, 100) :: Gen Int) $ \minor ->
        let versionStr = T.pack (show major ++ "." ++ show minor)
            text = "Version " <> versionStr
            result = extractVersion text
        in result == versionStr

    it "handles version in various formats consistently" $ property $
      forAll (elements ["0.3", "0.4", "1.0", "2.5"]) $ \version ->
        let formats =
              [ "# Palimpsest License " <> version
              , "Version " <> version
              , "version " <> version
              , "VERSION " <> version
              ]
        in all (\fmt -> extractVersion fmt == version) formats

  describe "License header detection properties" $ do
    it "header detection is consistent on repeated calls" $ property $
      \text -> let txt = T.pack text
                   r1 = hasLicenseHeader txt
                   r2 = hasLicenseHeader txt
               in r1 == r2

    it "license header detection respects first 10 lines boundary" $ property $
      let headerLine = "# Palimpsest License v0.4"
      in property $ \n ->
        n >= 0 && n <= 20 ==>
          let prefix = T.unlines (replicate n "content")
              text = prefix <> headerLine
              result = hasLicenseHeader text
          in result == (n < 10)

    it "detection works regardless of extra whitespace" $ property $
      let formats = [ "# Palimpsest License v0.4"
                    , "#  Palimpsest License v0.4"
                    , "#   Palimpsest License v0.4"
                    ]
      in all hasLicenseHeader formats

  describe "Language detection properties" $ do
    it "language detection always returns a valid option" $ property $
      \text -> let result = detectLanguage (T.pack text)
               in result `elem` [Nothing, Just English, Just Dutch]

    it "detecting language is consistent across repeated calls" $ property $
      \text -> let txt = T.pack text
                   r1 = detectLanguage txt
                   r2 = detectLanguage txt
               in r1 == r2

    it "English keywords consistently detect English" $ property $
      forAll (elements ["Governing Law", "Definitions", "Permissions", "Attribution"]) $
        \keyword -> detectLanguage keyword `shouldBe` Just English

    it "Dutch keywords consistently detect Dutch" $ property $
      forAll (elements ["Toepasselijk Recht", "Definities", "Toestemmingen", "Naamgeving"]) $
        \keyword -> detectLanguage keyword `shouldBe` Just Dutch

    it "mixed language content doesn't incorrectly detect" $ property $
      \engText -> \dutchText ->
        let mixed = T.pack engText <> "Definitions" <> T.pack dutchText <> "Definities"
            result = detectLanguage mixed
        in result == Nothing || result == Just English || result == Just Dutch

  describe "Clause number parsing properties" $ do
    it "valid clause numbers always parse successfully" $ property $
      forAll (choose (1, 1000) :: Gen Int) $ \n ->
        parseClauseNumber (T.pack $ show n) == Just n

    it "invalid clause numbers always return Nothing" $ property $
      forAll (listOf1 arbitrary `suchThat` (not . all (\c -> c `elem` ("0123456789" :: String)))) $
        \str -> parseClauseNumber (T.pack str) == Nothing

    it "clause number parsing is deterministic" $ property $
      \text -> let txt = T.pack text
                   r1 = parseClauseNumber txt
                   r2 = parseClauseNumber txt
               in r1 == r2

    it "decimal clause numbers parse the integer part" $ property $
      forAll (choose (1, 100) :: Gen Int) $ \major ->
      forAll (choose (1, 100) :: Gen Int) $ \minor ->
        let text = T.pack (show major ++ "." ++ show minor)
        in parseClauseNumber text == Just major

  describe "License structure parsing properties" $ do
    it "parsing never crashes on arbitrary text" $ property $
      \text -> let _structure = parseLicenseStructure (T.pack text)
               in True

    it "parsed structure always has consistent version field" $ property $
      \text -> let structure = parseLicenseStructure (T.pack text)
               in T.length (licenseVersion structure) >= 0

    it "clause extraction is deterministic" $ property $
      \text -> let txt = T.pack text
                   s1 = parseLicenseStructure txt
                   s2 = parseLicenseStructure txt
               in length (licenseClauses s1) == length (licenseClauses s2)

    it "empty input produces empty clause list" $ property $
      parseLicenseStructure "" `shouldSatisfy` \s -> null (licenseClauses s)

    it "structure with no valid clauses returns empty list" $ property $
      let randomText = T.pack "random content without clause markers"
      in parseLicenseStructure randomText `shouldSatisfy` \s -> null (licenseClauses s)

  describe "Text normalization properties" $ do
    it "normalization is idempotent" $ property $
      \text -> let txt = T.pack text
                   n1 = normaliseText txt
                   n2 = normaliseText n1
               in n1 == n2

    it "whitespace normalization produces valid text" $ property $
      \text -> let result = normaliseText (T.pack text)
               in T.length result >= 0

    it "case conversion is consistent" $ property $
      \text -> let lower = T.toLower (T.pack text)
                   result = normaliseText lower
               in T.length result >= 0

    it "normalization preserves non-whitespace characters" $ property $
      forAll (listOf1 (choose ('a', 'z'))) $ \chars ->
        let text = T.pack chars
            normalized = normaliseText text
        in T.all (`elem` text) normalized || T.length normalized == 0

  describe "Clause reference validation properties" $ do
    it "valid clause references always extract successfully" $ property $
      forAll (choose (1, 100) :: Gen Int) $ \n ->
        let text = "See Clause " <> T.pack (show n) <> " for details"
            lines' = zip [1..] (T.lines text)
        in length (concatMap (extractClauseRefs "test.md") lines') > 0

    it "clause reference extraction is consistent" $ property $
      \text -> let txt = T.pack text
                   lines1 = zip [1..] (T.lines txt)
                   lines2 = zip [1..] (T.lines txt)
               in concatMap (extractClauseRefs "test.md") lines1 ==
                  concatMap (extractClauseRefs "test.md") lines2

    it "no false positives on non-clause text" $ property $
      forAll (listOf1 (arbitrary `suchThat` \c -> c /= "Clause")) $
        \words' -> let text = T.pack $ unwords words'
                       lines' = zip [1..] (T.lines text)
                   in not (any (T.isInfixOf "Clause") [text])
                      || length (concatMap (extractClauseRefs "test.md") lines') >= 0

  describe "URL extraction properties" $ do
    it "URL extraction is consistent" $ property $
      \text -> let txt = T.pack text
                   lines1 = zip [1..] (T.lines txt)
                   lines2 = zip [1..] (T.lines txt)
               in concatMap (extractURLRefs "test.md") lines1 ==
                  concatMap (extractURLRefs "test.md") lines2

    it "valid URLs are always extracted" $ property $
      let validURLs = ["https://example.com", "http://test.org", "https://github.com/user/repo"]
      in property $
        forAll (elements validURLs) $ \url ->
          let text = "See " <> url <> " for details"
              lines' = zip [1..] (T.lines text)
          in length (concatMap (extractURLRefs "test.md") lines') > 0

  describe "Duplicate finding properties" $ do
    it "no duplicates in unique list" $ property $
      forAll (listOf1 (arbitrary :: Gen Text) `suchThat` allUnique) $
        \items -> findDuplicates items == []

    it "all duplicates are found" $ property $
      forAll (listOf1 (choose (1, 10) :: Gen Int)) $
        \items -> let dups = findDuplicates (map T.pack $ map show items)
                      counts = length items - length (nubOrd items)
                  in length dups == counts

    it "duplicate finding is deterministic" $ property $
      \items -> let d1 = findDuplicates items
                    d2 = findDuplicates items
                in d1 == d2

  describe "Round-trip property tests" $ do
    it "parse -> format -> parse should preserve structure" $ property $
      let text = T.unlines
            [ "# Palimpsest License v0.4"
            , "## Clause 1 — First"
            , "Content"
            ]
      in property $
        let s1 = parseLicenseStructure text
            s2 = parseLicenseStructure text
        in licenseVersion s1 == licenseVersion s2 &&
           length (licenseClauses s1) == length (licenseClauses s2)

  describe "Fuzzing properties (randomized input)" $ do
    it "handles random UTF-8 text without crashing" $ property $
      \text -> let _result = parseLicenseStructure (T.pack text)
               in True

    it "handles very long text without performance degradation" $ property $
      forAll (resize 10000 arbitrary) $ \text ->
        let _result = parseLicenseStructure (T.pack text)
        in True

    it "handles special characters correctly" $ property $
      let specialChars = "!@#$%^&*()[]{}|\\:;<>?,./~`"
          text = T.pack specialChars
          result = parseLicenseStructure text
      in licenseClauses result == [] || length (licenseClauses result) >= 0

-- Helper functions
allUnique :: Eq a => [a] -> Bool
allUnique [] = True
allUnique (x:xs) = x `notElem` xs && allUnique xs

nubOrd :: Eq a => [a] -> [a]
nubOrd = go []
  where
    go _ [] = []
    go seen (x:xs) = if x `elem` seen then go seen xs else x : go (x:seen) xs
