{-
SPDX-License-Identifier: PMPL-1.0-or-later
SPDX-FileCopyrightText: 2024-2025 Palimpsest Stewardship Council
-}

{-# LANGUAGE OverloadedStrings #-}

module E2E.ValidationE2ESpec (e2eSpec) where

import Test.Hspec
import Test.Hspec.QuickCheck
import Test.QuickCheck
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import System.IO.Temp
import System.Directory
import System.FilePath
import Control.Exception (bracket)
import Palimpsest.Validator.Types
import Palimpsest.Validator.License
import Palimpsest.Validator.Metadata
import Palimpsest.Validator.Bilingual
import Palimpsest.Validator.Reference
import Palimpsest.Validator.Utils

-- | End-to-end tests for complete validation workflows
e2eSpec :: Spec
e2eSpec = describe "E2E: Full Validation Pipeline" $ do
  describe "Single file validation workflow" $ do
    it "validates a complete license file from disk" $ do
      withSystemTempDirectory "palimpsest-e2e" $ \tmpDir -> do
        let licenseFile = tmpDir </> "LICENSE.md"
        let licenseContent = T.unlines
              [ "# Palimpsest License v0.4"
              , ""
              , "## Clause 1 — Definitions"
              , ""
              , "**Non-Interpretive (NI) Systems**: AI systems that process"
              , "content without generating interpretive outputs."
              , ""
              , "## Clause 2 — Permissions"
              , ""
              , "You may copy and distribute the work."
              , ""
              , "## Clause 3 — Conditions"
              , ""
              , "Attribution must be preserved per Clause 2.3."
              , ""
              , "Governing Law: Netherlands"
              ]

        -- Write file
        TIO.writeFile licenseFile licenseContent

        -- Read and validate
        readContent <- TIO.readFile licenseFile
        let structure = parseLicenseStructure readContent

        -- Assertions
        licenseVersion structure `shouldBe` "0.4"
        licenseHasHeader structure `shouldBe` True
        length (licenseClauses structure) `shouldBe` 3
        licenseGoverningLaw structure `shouldBe` Just "Netherlands"

    it "detects license language from file" $ do
      withSystemTempDirectory "palimpsest-e2e" $ \tmpDir -> do
        let englishFile = tmpDir </> "english.md"
        let dutchFile = tmpDir </> "dutch.md"

        let englishContent = "# Palimpsest License\n\n## Definitions\n\nContent..."
        let dutchContent = "# Palimpsest Licentie\n\n## Definities\n\nInhoud..."

        TIO.writeFile englishFile englishContent
        TIO.writeFile dutchFile dutchContent

        engRead <- TIO.readFile englishFile
        dutchRead <- TIO.readFile dutchFile

        let engStruct = parseLicenseStructure engRead
        let dutchStruct = parseLicenseStructure dutchRead

        licenseLanguage engStruct `shouldBe` Just English
        licenseLanguage dutchStruct `shouldBe` Just Dutch

  describe "Multi-file directory validation" $ do
    it "validates all files in a directory" $ do
      withSystemTempDirectory "palimpsest-dir-e2e" $ \tmpDir -> do
        -- Create multiple license files
        let license1 = tmpDir </> "LICENSE.md"
        let license2 = tmpDir </> "COPYING.md"
        let license3 = tmpDir </> "LICENSE_v0.3.md"

        let content1 = "# Palimpsest License v0.4\n\n## Clause 1 — Definitions\n\nContent"
        let content2 = "# Palimpsest License v0.4\n\n## Clause 1 — Definitions\n\nContent"
        let content3 = "# Palimpsest License v0.3\n\n## Clause 1 — Definitions\n\nContent"

        TIO.writeFile license1 content1
        TIO.writeFile license2 content2
        TIO.writeFile license3 content3

        -- Read all files
        files <- listDirectory tmpDir
        let mdFiles = filter (\f -> takeExtension f == ".md") files

        -- Validate each file
        structures <- mapM (\f -> TIO.readFile (tmpDir </> f) >>= \c -> pure $ parseLicenseStructure c) mdFiles

        -- Assertions
        length structures `shouldBe` 3
        all licenseHasHeader structures `shouldBe` True

        -- Check version diversity
        let versions = map licenseVersion structures
        length (filter (== "0.4") versions) `shouldBe` 2
        length (filter (== "0.3") versions) `shouldBe` 1

  describe "Error handling and edge cases" $ do
    it "handles missing SPDX header gracefully" $ do
      let malformedContent = "Some random license text without proper header"
      let structure = parseLicenseStructure malformedContent
      licenseHasHeader structure `shouldBe` False
      licenseVersion structure `shouldBe` "unknown"

    it "handles binary file detection" $ do
      withSystemTempDirectory "palimpsest-bin-e2e" $ \tmpDir -> do
        let binFile = tmpDir </> "binary.bin"
        -- Write some binary data
        writeFile binFile "\NUL\NUL\NUL\NUL"

        -- Attempt to read and should not crash
        content <- readFile binFile `catch` \(_::IOError) -> pure ""
        let structure = parseLicenseStructure (T.pack content)

        -- Should handle gracefully
        licenseHasHeader structure `shouldBe` False

    it "handles empty file gracefully" $ do
      withSystemTempDirectory "palimpsest-empty-e2e" $ \tmpDir -> do
        let emptyFile = tmpDir </> "empty.md"
        writeFile emptyFile ""

        content <- readFile emptyFile
        let structure = parseLicenseStructure (T.pack content)

        licenseVersion structure `shouldBe` "unknown"
        licenseClauses structure `shouldBe` []

    it "handles very large files without performance degradation" $ do
      let largeContent = T.unlines $
            [ "# Palimpsest License v0.4" ] ++
            concatMap (\n ->
              [ "## Clause " <> T.pack (show n) <> " — Section"
              , "Content line 1 for clause " <> T.pack (show n)
              , "Content line 2 for clause " <> T.pack (show n)
              , "Content line 3 for clause " <> T.pack (show n)
              , ""
              ]) [1..500]

      let structure = parseLicenseStructure largeContent

      -- Should complete without timeout
      licenseHasHeader structure `shouldBe` True
      length (licenseClauses structure) `shouldBe` 500

    it "handles mixed line endings (CRLF, LF)" $ do
      let crlfContent = "# Palimpsest License v0.4\r\n\r\n## Clause 1 — Definitions\r\n\r\nContent"
      let lfContent = "# Palimpsest License v0.4\n\n## Clause 1 — Definitions\n\nContent"

      let crlfStruct = parseLicenseStructure crlfContent
      let lfStruct = parseLicenseStructure lfContent

      -- Both should parse successfully
      licenseVersion crlfStruct `shouldBe` "0.4"
      licenseVersion lfStruct `shouldBe` "0.4"

  describe "Cross-component integration" $ do
    it "validates license with complete metadata" $ do
      withSystemTempDirectory "palimpsest-metadata-e2e" $ \tmpDir -> do
        let licenseFile = tmpDir </> "LICENSE.md"
        let metadataFile = tmpDir </> "metadata.jsonld"

        let licenseContent = "# Palimpsest License v0.4\n\n## Clause 1 — Definitions\n\nContent"
        let metadataContent = "{\"license\": \"Palimpsest-0.4\", \"language\": \"en\"}"

        TIO.writeFile licenseFile licenseContent
        TIO.writeFile metadataFile metadataContent

        -- Validate both
        licRead <- TIO.readFile licenseFile
        let licStruct = parseLicenseStructure licRead

        licenseVersion licStruct `shouldBe` "0.4"
        isJSONLDFile "metadata.jsonld" `shouldBe` True

    it "validates license with bilingual documentation" $ do
      withSystemTempDirectory "palimpsest-bilingual-e2e" $ \tmpDir -> do
        let engFile = tmpDir </> "LICENSE_en.md"
        let dutchFile = tmpDir </> "LICENSE_nl.md"

        let engContent = "# Palimpsest License v0.4\n\n## Clause 1 — Definitions\n\nContent"
        let dutchContent = "# Palimpsest Licentie v0.4\n\n## Artikel 1 — Definities\n\nInhoud"

        TIO.writeFile engFile engContent
        TIO.writeFile dutchFile dutchContent

        engRead <- TIO.readFile engFile
        dutchRead <- TIO.readFile dutchFile

        let engStruct = parseLicenseStructure engRead
        let dutchStruct = parseLicenseStructure dutchRead

        licenseLanguage engStruct `shouldBe` Just English
        licenseLanguage dutchStruct `shouldBe` Just Dutch
        -- Versions should match
        licenseVersion engStruct `shouldBe` licenseVersion dutchStruct

  describe "Performance benchmarks (not timed)" $ do
    it "validates single file structure extraction" $ do
      let content = T.unlines $
            [ "# Palimpsest License v0.4" ] ++
            concatMap (\n -> ["## Clause " <> T.pack (show n), "Content"]) [1..100]

      let structure = parseLicenseStructure content
      length (licenseClauses structure) `shouldBe` 100

    it "processes multiple validation operations sequentially" $ do
      let contents = replicate 10 $ T.unlines
            [ "# Palimpsest License v0.4"
            , "## Clause 1 — Definitions"
            , "Content"
            ]

      let structures = map parseLicenseStructure contents

      -- All should validate
      all licenseHasHeader structures `shouldBe` True
      length structures `shouldBe` 10

  describe "Self-validation tests" $ do
    it "can validate its own test file content" $ do
      let testContent = T.unlines
            [ "# Palimpsest License v0.4"
            , ""
            , "This is a self-validating test file."
            , ""
            , "## Clause 1 — Definitions"
            , ""
            , "**Non-Interpretive**: Systems that do not interpret."
            , ""
            , "## Clause 2 — Permissions"
            , ""
            , "Permission granted."
            ]

      let structure = parseLicenseStructure testContent

      licenseVersion structure `shouldBe` "0.4"
      licenseHasHeader structure `shouldBe` True
      length (licenseClauses structure) `shouldBe` 2
      any (T.isInfixOf "Non-Interpretive") (map clauseHeading (licenseClauses structure)) `shouldBe` True

-- Helper function for exception handling
catch :: IO a -> (IOError -> IO a) -> IO a
catch = Control.Exception.catch
