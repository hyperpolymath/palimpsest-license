{-# OPTIONS --safe --without-K #-}
-- SPDX-License-Identifier: PMPL-1.0-or-later
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell

module UnverifiedSignature where

open import Agda.Builtin.Bool using (Bool; true)
open import Agda.Builtin.Equality using (_≡_; refl)
open import Agda.Builtin.Sigma using (_,_)
open import Provenance.Warrant

module _
  (PublicKey Message Signature : Set)
  (verify      : PublicKey → Message → Signature → Bool)
  (SignedBy    : PublicKey → Message → Set)
  (unforgeable : (pk : PublicKey) (m : Message) (σ : Signature) →
                 verify pk m σ ≡ true → SignedBy pk m)
  where
  open SignatureVerify PublicKey Message Signature verify SignedBy unforgeable

  -- Must fail (rule 7): a signature that has not been checked is offered as
  -- the evidence token.  Whether it verifies is not known, so refl does not
  -- prove verify pk m σ ≡ true.
  invalid : (pk : PublicKey) (m : Message) (σ : Signature) → SignedBy pk m
  invalid pk m σ = verified-signed-by pk m σ refl
