{-# OPTIONS --safe --without-K #-}
-- SPDX-License-Identifier: PMPL-1.0-or-later
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell

module ConsentFromToken where

open import Agda.Primitive using (lzero)
open import EpistemicTypes.Warrant using (SoundWarrant; soundWarrant)
open import Provenance.Warrant

module _ (Artefact : Set) (Consented Header : Artefact → Set) where
  open ConsentFromHeader Artefact Consented Header

  -- Must fail: consented-for-training is extracted from a licence-header
  -- token.  The token is evidence only as Epi; making the warrant sound needs
  -- a map from the header to consent, and the header is not consent.
  invalid : (x : Artefact) → SoundWarrant {wℓ = lzero} Standpoint licensor (Consented x)
  invalid x = soundWarrant (consent x) (λ token → token)
