{-
SPDX-License-Identifier: PMPL-1.0-or-later
SPDX-FileCopyrightText: 2024-2025 Palimpsest Stewardship Council
-}

module Main (main) where

import GHC.IO.Encoding (setLocaleEncoding, utf8)
import Test.Hspec
import Palimpsest.Validator.LicenseSpec
import Palimpsest.Validator.MetadataSpec
import Palimpsest.Validator.BilingualSpec
import Palimpsest.Validator.ReferenceSpec
import Palimpsest.Validator.UtilsSpec
import Integration.PipelineSpec
import E2E.ValidationE2ESpec
import Property.ValidatorPropertySpec

main :: IO ()
main = do
  -- The fixtures contain non-ASCII text (em dashes) and are written and read
  -- with the locale encoding; don't let the result depend on the machine's
  -- locale (e.g. LANG unset or POSIX).
  setLocaleEncoding utf8
  hspec spec

spec :: Spec
spec = do
  describe "Palimpsest Validator Test Suite" $ do
    describe "Unit Tests" $ do
      licenseSpec
      metadataSpec
      bilingualSpec
      referenceSpec
      utilsSpec

    describe "Integration Tests" $ do
      pipelineSpec

    describe "End-to-End Tests" $ do
      e2eSpec

    describe "Property-Based Tests" $ do
      propertySpec
