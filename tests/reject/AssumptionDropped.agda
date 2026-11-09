{-# OPTIONS --safe --without-K --cubical-compatible --exact-split --no-sized-types --no-guardedness #-}
-- SPDX-License-Identifier: PMPL-1.0-or-later
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell

module AssumptionDropped where

open import Agda.Primitive using (lzero)
open import Agda.Builtin.Bool using (Bool; true)
open import Agda.Builtin.Equality using (_≡_; refl)
open import Agda.Builtin.Sigma using (Σ; _,_)
open import EpistemicTypes.Warrant using (Warrant; mkWarrant; SoundWarrant; soundWarrant)
open import Provenance.Warrant

module _
  (PublicKey Message Signature : Set)
  (verify   : PublicKey → Message → Signature → Bool)
  (SignedBy : PublicKey → Message → Set)
  where

  -- Must fail (rule 3): signed-by made sound on a verified signature with no
  -- assumption.  A signature that verifies is a fact about verify, not about
  -- who signed; without unforgeable there is no map from the one to the
  -- other (no-signature-sound).  The evidence is pinned, because a warrant
  -- whose evidence is the claim itself would meet a bare SoundWarrant type.
  invalid : (κ : Standpoint) (pk : PublicKey) (m : Message) →
            Σ (SoundWarrant {wℓ = lzero} Standpoint κ (SignedBy pk m))
              (λ sw → Warrant.Evidence (SoundWarrant.warrant sw) ≡
                      Σ Signature (λ σ → verify pk m σ ≡ true))
  invalid κ pk m =
    soundWarrant (mkWarrant (Σ Signature (λ σ → verify pk m σ ≡ true)))
                 (λ { (σ , ok) → ok }) ,
    refl
