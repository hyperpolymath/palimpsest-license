{-# OPTIONS --safe --without-K #-}
-- SPDX-License-Identifier: PMPL-1.0-or-later
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell

module SignatureToConsent where

open import Agda.Builtin.Bool using (Bool; true)
open import Agda.Builtin.Equality using (_≡_)
open import Agda.Builtin.Sigma using (_,_)
open import EpistemicTypes.Warrant using (sound-epi)
open import Provenance.Warrant

module _
  (PublicKey Message Signature : Set)
  (verify      : PublicKey → Message → Signature → Bool)
  (SignedBy    : PublicKey → Message → Set)
  (unforgeable : (pk : PublicKey) (m : Message) (σ : Signature) →
                 verify pk m σ ≡ true → SignedBy pk m)
  (Artefact    : Set)
  (Consented   : Artefact → Set)
  where
  open SignatureVerify PublicKey Message Signature verify SignedBy unforgeable

  -- Must fail (rule 6): the signed bytes include the licence header that
  -- declares consent, and the signature verifies.  What is sound is that the
  -- key holder signed those bytes, which is signed-by, not consent.
  invalid : (x : Artefact) (pk : PublicKey) (m : Message) (σ : Signature) →
            verify pk m σ ≡ true → Consented x
  invalid x pk m σ ok = sound-epi (signature-sound verifier pk m) (σ , ok)
