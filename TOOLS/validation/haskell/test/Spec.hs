{-
SPDX-License-Identifier: PMPL-1.0-or-later
SPDX-FileCopyrightText: 2024-2025 Palimpsest Stewardship Council
-}

module Main where

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
main = hspec $ do
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
