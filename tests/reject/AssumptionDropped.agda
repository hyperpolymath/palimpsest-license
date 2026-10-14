{-# OPTIONS --safe --without-K #-}
-- SPDX-License-Identifier: PMPL-1.0-or-later
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell

module AssumptionDropped where

open import Agda.Primitive using (lzero)
open import Agda.Builtin.Bool using (Bool; true)
open import Agda.Builtin.Equality using (_≡_)
open import Agda.Builtin.Sigma using (Σ; _,_)
open import EpistemicTypes.Warrant using (Warrant; mkWarrant; SoundWarrant; soundWarrant)
open import Provenance.Warrant

module _
  (PublicKey Message Signature : Set)
  (verify   : PublicKey → Message → Signature → Bool)
  (SignedBy : PublicKey → Message → Set)
  where

  -- Must fail (rule 3): signed-by made sound with no assumption.  A
  -- signature that verifies is a fact about verify, not about who signed;
  -- without unforgeable there is no map from the one to the other.
  invalid : (κ : Standpoint) (pk : PublicKey) (m : Message) →
            SoundWarrant {wℓ = lzero} Standpoint κ (SignedBy pk m)
  invalid κ pk m =
    soundWarrant (mkWarrant (Σ Signature (λ σ → verify pk m σ ≡ true)))
                 (λ { (σ , ok) → ok })
