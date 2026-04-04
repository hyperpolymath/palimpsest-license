{-
SPDX-License-Identifier: PMPL-1.0-or-later
SPDX-FileCopyrightText: 2024-2025 Palimpsest Stewardship Council
-}

{-# LANGUAGE OverloadedStrings #-}

module Main where

import Criterion.Main
import Data.Text (Text)
import qualified Data.Text as T
import Palimpsest.Validator.License
import Palimpsest.Validator.Metadata
import Palimpsest.Validator.Bilingual
import Palimpsest.Validator.Reference
import Palimpsest.Validator.Utils

-- | Benchmark suite for Palimpsest validator performance
main :: IO ()
main = defaultMain
  [ bgroup "License validation"
    [ bench "single file (small)"     $ nf validateSmallLicense smallLicense
    , bench "single file (medium)"    $ nf validateMediumLicense mediumLicense
    , bench "single file (large)"     $ nf validateLargeLicense largeLicense
    , bench "version extraction"      $ nf extractVersion versionText
    , bench "header detection"        $ nf hasLicenseHeader headerText
    , bench "clause extraction (100)" $ nf (length . licenseClauses . parseLicenseStructure) mediumLicense
    , bench "clause extraction (500)" $ nf (length . licenseClauses . parseLicenseStructure) largeLicense
    ]
  , bgroup "Language detection"
    [ bench "detect English"          $ nf detectLanguage englishText
    , bench "detect Dutch"            $ nf detectLanguage dutchText
    , bench "detect ambiguous"        $ nf detectLanguage ambiguousText
    ]
  , bgroup "Clause operations"
    [ bench "parse clause number (valid)"   $ nf parseClauseNumber "42"
    , bench "parse clause number (invalid)" $ nf parseClauseNumber "abc"
    , bench "extract clause numbers"       $ nf extractClauseNumbers 100
    ]
  , bgroup "Text normalization"
    [ bench "normalize small text"    $ nf normaliseText smallText
    , bench "normalize medium text"   $ nf normaliseText mediumText
    , bench "normalize large text"    $ nf normaliseText largeText
    ]
  , bgroup "Reference extraction"
    [ bench "extract clause refs"     $ nf extractClauseRefsFromLines clauseRefLines
    , bench "extract URL refs"        $ nf extractURLRefsFromLines urlRefLines
    , bench "extract internal links"  $ nf extractInternalLinksFromLines internalLinkLines
    ]
  , bgroup "Metadata operations"
    [ bench "detect JSONLD file"      $ nf isJSONLDFile "metadata.jsonld"
    , bench "detect XML file"         $ nf isXMLFile "lineage.xml"
    ]
  , bgroup "Duplicate detection"
    [ bench "find duplicates (small)" $ nf findDuplicates smallList
    , bench "find duplicates (medium)"$ nf findDuplicates mediumList
    , bench "find duplicates (large)" $ nf findDuplicates largeList
    ]
  , bgroup "Parsing and structure"
    [ bench "parse license structure" $ nf parseLicenseStructure mediumLicense
    , bench "check anchor existence"  $ nf (checkAnchorExists "introduction") anchorText
    ]
  ]

-- Test data
-- =========

smallLicense :: Text
smallLicense = T.unlines
  [ "# Palimpsest License v0.4"
  , ""
  , "## Clause 1 — Definitions"
  , "Content"
  ]

mediumLicense :: Text
mediumLicense = T.unlines $
  [ "# Palimpsest License v0.4" ] ++
  concatMap (\n -> ["## Clause " <> T.pack (show n) <> " — Section", "Content"]) [1..100]

largeLicense :: Text
largeLicense = T.unlines $
  [ "# Palimpsest License v0.4" ] ++
  concatMap (\n ->
    [ "## Clause " <> T.pack (show n) <> " — Section"
    , "Content line 1"
    , "Content line 2"
    , "Content line 3"
    , "Governing Law: Netherlands"
    , ""
    ]) [1..500]

versionText :: Text
versionText = "# Palimpsest License v0.4"

headerText :: Text
headerText = T.unlines
  [ "# Palimpsest License v0.4"
  , ""
  , "## Clause 1 — Definitions"
  ]

englishText :: Text
englishText = "## Definitions\n\nIn this license, the following terms have meaning."

dutchText :: Text
dutchText = "## Definities\n\nIn deze licentie hebben de volgende termen betekenis."

ambiguousText :: Text
ambiguousText = "Some random content without language markers"

smallText :: Text
smallText = "   Hello   World   "

mediumText :: Text
mediumText = T.unlines
  [ "This is a medium text with multiple lines"
  , "Each line has some content  with  extra spaces"
  , "We want to normalize this text properly"
  ]

largeText :: Text
largeText = T.unlines $ replicate 1000 "This is a line of text   with   extra   spaces"

smallList :: [Text]
smallList = ["one", "two", "three"]

mediumList :: [Text]
mediumList = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"] ++ replicate 5 "duplicate"

largeList :: [Text]
largeList = concatMap (\n -> [T.pack $ show n, T.pack $ show n]) [1..500]

clauseRefLines :: [(Int, Text)]
clauseRefLines = zip [1..] $ replicate 100 "See Clause 1 for definitions"

urlRefLines :: [(Int, Text)]
urlRefLines = zip [1..] $ replicate 100 "Visit https://example.com for details"

internalLinkLines :: [(Int, Text)]
internalLinkLines = zip [1..] $ replicate 100 "Jump to [Introduction](#intro)"

anchorText :: Text
anchorText = T.unlines
  [ "## Introduction"
  , "Content here"
  , "## Methods"
  , "More content"
  ]

-- Helper functions for benchmarks
extractClauseRefsFromLines :: [(Int, Text)] -> [ClauseRef]
extractClauseRefsFromLines = concatMap (extractClauseRefs "test.md")

extractURLRefsFromLines :: [(Int, Text)] -> [URLRef]
extractURLRefsFromLines = concatMap (extractURLRefs "test.md")

extractInternalLinksFromLines :: [(Int, Text)] -> [InternalLink]
extractInternalLinksFromLines = concatMap (extractInternalLinks "test.md")

extractClauseNumbers :: Int -> [Text]
extractClauseNumbers n = map (T.pack . show) [1..n]

-- Simplified placeholder types (would be imported from actual modules)
-- These are used to satisfy type requirements in benchmarks
data ClauseRef = ClauseRef deriving (Show)
data URLRef = URLRef deriving (Show)
data InternalLink = InternalLink deriving (Show)

-- Helper for small benchmark (validates structure is parseable)
validateSmallLicense :: Text -> Bool
validateSmallLicense txt = licenseHasHeader (parseLicenseStructure txt)

validateMediumLicense :: Text -> Int
validateMediumLicense txt = length (licenseClauses (parseLicenseStructure txt))

validateLargeLicense :: Text -> Int
validateLargeLicense txt = length (licenseClauses (parseLicenseStructure txt))
