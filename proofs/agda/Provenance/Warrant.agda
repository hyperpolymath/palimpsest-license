{-# OPTIONS --safe --without-K #-}
-- SPDX-License-Identifier: PMPL-1.0-or-later
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
--
-- Warrant levels for provenance claims (spec/PROVENANCE-SPEC.adoc §7), as
-- epistemic-types' records.  The sibling is consumed by pin, fetched by
-- scripts/fetch-siblings.sh; nothing from it is re-declared here:
--
--   epistemic-types  6a68de3141a981d766fd006b312f0919ade334bf
--     EpistemicTypes.Warrant     Warrant, Epi, SoundWarrant, sound-epi (E-1)
--     EpistemicTypes.EchoBridge  Impossible, the empty type that
--                                no-receipt-reflection (E-2) refutes into
--
-- One SoundWarrant: signature-verify concludes signed-by.  The cryptographic
-- assumption (EUF-CMA for the algorithm named in the signature) is the
-- parameter `unforgeable` of SignatureVerify, not a postulate, so every use
-- of the rule is given it explicitly.
--
-- One deliberate non-upgrade: a licence-header token warrants
-- consented-for-training only as Epi.  tests/reject/ConsentFromToken.agda is
-- refused by the typechecker, and no-consent-sound below shows that no
-- soundness map for that warrant can be given uniformly.

module Provenance.Warrant where

open import Agda.Primitive using (lzero)
open import Agda.Builtin.Bool using (Bool; true)
open import Agda.Builtin.Equality using (_≡_; refl)
open import Agda.Builtin.Nat using (Nat; _==_; _+_)
open import Agda.Builtin.Sigma using (Σ; _,_)
open import Agda.Builtin.Unit using (⊤; tt)

open import EpistemicTypes.Warrant
  using (Warrant; mkWarrant; Epi; epi; SoundWarrant; soundWarrant; sound-epi)
open import EpistemicTypes.EchoBridge using (Impossible)

-- κ, whose warrant it is (§7.2).
data Standpoint : Set where
  author licensor verifier consumer : Standpoint

------------------------------------------------------------------------
-- signed-by at sound: the rule signature-verify (§7.5).
--
--   verify       the algorithm named in the signature
--   SignedBy     the claim: the holder of pk's secret key signed m
--   unforgeable  the assumption, EUF-CMA: a signature that verifies under pk
--                for m was made by that key holder
--
-- m is the signed record, which binds the artefact's hash and a timestamp;
-- the timestamp is a signed field, not a measured one (§7.4).

module SignatureVerify
  (PublicKey Message Signature : Set)
  (verify      : PublicKey → Message → Signature → Bool)
  (SignedBy    : PublicKey → Message → Set)
  (unforgeable : (pk : PublicKey) (m : Message) (σ : Signature) →
                 verify pk m σ ≡ true → SignedBy pk m)
  where

  -- The evidence type: a signature together with the fact that it verifies.
  -- A signature that has not been checked is not a token of it (rule 7).
  Verified : PublicKey → Message → Set
  Verified pk m = Σ Signature (λ σ → verify pk m σ ≡ true)

  signed-by : (κ : Standpoint) (pk : PublicKey) (m : Message) →
              Warrant {wℓ = lzero} Standpoint κ (SignedBy pk m)
  signed-by κ pk m = mkWarrant (Verified pk m)

  -- The soundness map is the assumption applied to the verified signature.
  signature-sound : (κ : Standpoint) (pk : PublicKey) (m : Message) →
                    SoundWarrant {wℓ = lzero} Standpoint κ (SignedBy pk m)
  signature-sound κ pk m =
    soundWarrant (signed-by κ pk m) (λ { (σ , ok) → unforgeable pk m σ ok })

  -- What a verifier holds after checking one signature: the claim, through
  -- sound-epi, under the assumption it was given.
  verified-signed-by : (pk : PublicKey) (m : Message) (σ : Signature) →
                       verify pk m σ ≡ true → SignedBy pk m
  verified-signed-by pk m σ ok = sound-epi (signature-sound verifier pk m) (σ , ok)

------------------------------------------------------------------------
-- consented-for-training at most Epi (§7.3 rule 4).

module ConsentFromHeader
  (Artefact             : Set)
  (ConsentedForTraining : Artefact → Set)
  (LicenceHeader        : Artefact → Set)  -- a header that declares consent
  where

  consent : (x : Artefact) →
            Warrant {wℓ = lzero} Standpoint licensor (ConsentedForTraining x)
  consent x = mkWarrant (LicenceHeader x)

  consent-epi : (x : Artefact) → LicenceHeader x →
                Epi {wℓ = lzero} Standpoint licensor (ConsentedForTraining x)
  consent-epi x header = epi (consent x) header

  -- A soundness map for this warrant would be a proof that the header
  -- entails consent.
  ConsentSound : Artefact → Set
  ConsentSound x = Warrant.Evidence (consent x) → ConsentedForTraining x

-- No soundness map for the consent warrant can be given uniformly: where a
-- header is present and consent was not given, one would inhabit Impossible.
no-consent-sound :
  ((Artefact : Set) (C H : Artefact → Set) (x : Artefact) →
     ConsentFromHeader.ConsentSound Artefact C H x) →
  Impossible
no-consent-sound sound = sound ⊤ (λ _ → Impossible) (λ _ → ⊤) tt tt

-- Rule 6: levels do not transfer.  A sound warrant for one claim, held with
-- a token for another, does not give the other: here a sound signature
-- claim and a consent token, with consent not given.
no-transfer :
  ((A B : Set) →
     SoundWarrant {wℓ = lzero} Standpoint verifier A →
     Epi {wℓ = lzero} Standpoint licensor B →
     B) →
  Impossible
no-transfer transfer =
  transfer ⊤ Impossible
    (soundWarrant (mkWarrant ⊤) (λ t → t))
    (epi (mkWarrant ⊤) tt)

------------------------------------------------------------------------
-- The parameters of SignatureVerify can be supplied, so the rule is not
-- vacuous.  This toy algorithm is not a signature scheme: here a
-- "signature" verifies when it equals pk + m, and unforgeability holds by
-- definition of SignedBy.  Nothing about Ed25519 or any real algorithm is
-- proved here; that remains the assumption.

module ToyModel where

  toy-verify : Nat → Nat → Nat → Bool
  toy-verify pk m σ = σ == (pk + m)

  ToySignedBy : Nat → Nat → Set
  ToySignedBy pk m = Σ Nat (λ σ → toy-verify pk m σ ≡ true)

  toy-unforgeable : (pk m σ : Nat) → toy-verify pk m σ ≡ true → ToySignedBy pk m
  toy-unforgeable pk m σ ok = σ , ok

  open SignatureVerify Nat Nat Nat toy-verify ToySignedBy toy-unforgeable

  -- pk = 2, m = 3: the signature 5 verifies, and the rule gives the claim.
  example : ToySignedBy 2 3
  example = verified-signed-by 2 3 5 refl
