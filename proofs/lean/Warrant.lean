-- SPDX-License-Identifier: PMPL-1.0-or-later
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell

/-
Lean leg of proofs/agda/Provenance/Warrant.agda, re-proved by hand
(standards 3-practice/PROOF-POLICY.adoc §2).  The Agda module is the source
of truth; the proof ledger (PROOF-NEEDS.adoc, Correspondence) compares each
statement here with its Agda statement.  Lean core only: no Mathlib, no
imports.

Results whose type is a Type, not a Prop, are `def`s: Lean reserves
`theorem` for propositions.  The kernel checks both alike.
-/

namespace Provenance

/-! epistemic-types' records (EpistemicTypes.Warrant), restated at Agda's
`Set`, i.e. `wℓ = lzero` as Provenance.Warrant uses them. -/

structure Warrant (K : Type) (κ : K) (A : Type) : Type 1 where
  mkWarrant ::
  Evidence : Type

structure Epi (K : Type) (κ : K) (A : Type) : Type 1 where
  epi ::
  warrant : Warrant K κ A
  evidence : warrant.Evidence

structure SoundWarrant (K : Type) (κ : K) (A : Type) : Type 1 where
  soundWarrant ::
  warrant : Warrant K κ A
  sound : warrant.Evidence → A

def soundEpi {K : Type} {κ : K} {A : Type}
    (sw : SoundWarrant K κ A) (token : sw.warrant.Evidence) : A :=
  sw.sound token

/-- EpistemicTypes.EchoBridge.Impossible -/
inductive Impossible : Type

inductive Standpoint : Type
  | author | licensor | verifier | consumer

/-! signed-by at sound: the rule signature-verify.  The module parameters of
the Agda `SignatureVerify` are explicit arguments here. -/

namespace SignatureVerify

variable {PublicKey Message Signature : Type}

def Verified (verify : PublicKey → Message → Signature → Bool)
    (pk : PublicKey) (m : Message) : Type :=
  Σ' σ : Signature, verify pk m σ = true

def signedBy (verify : PublicKey → Message → Signature → Bool)
    (SignedBy : PublicKey → Message → Type)
    (κ : Standpoint) (pk : PublicKey) (m : Message) :
    Warrant Standpoint κ (SignedBy pk m) :=
  ⟨Verified verify pk m⟩

def signatureSound (verify : PublicKey → Message → Signature → Bool)
    (SignedBy : PublicKey → Message → Type)
    (unforgeable : ∀ (pk : PublicKey) (m : Message) (σ : Signature),
      verify pk m σ = true → SignedBy pk m)
    (κ : Standpoint) (pk : PublicKey) (m : Message) :
    SoundWarrant Standpoint κ (SignedBy pk m) :=
  ⟨signedBy verify SignedBy κ pk m, fun v => unforgeable pk m v.1 v.2⟩

theorem signatureSound_evidence (verify : PublicKey → Message → Signature → Bool)
    (SignedBy : PublicKey → Message → Type)
    (unforgeable : ∀ (pk : PublicKey) (m : Message) (σ : Signature),
      verify pk m σ = true → SignedBy pk m)
    (κ : Standpoint) (pk : PublicKey) (m : Message) :
    (signatureSound verify SignedBy unforgeable κ pk m).warrant.Evidence =
      Verified verify pk m :=
  rfl

def verifiedSignedBy (verify : PublicKey → Message → Signature → Bool)
    (SignedBy : PublicKey → Message → Type)
    (unforgeable : ∀ (pk : PublicKey) (m : Message) (σ : Signature),
      verify pk m σ = true → SignedBy pk m)
    (pk : PublicKey) (m : Message) (σ : Signature)
    (ok : verify pk m σ = true) : SignedBy pk m :=
  soundEpi (signatureSound verify SignedBy unforgeable .verifier pk m) ⟨σ, ok⟩

end SignatureVerify

/-- Rule 3: the assumption is necessary. -/
def noSignatureSound
    (sound : ∀ (PublicKey Message Signature : Type)
      (verify : PublicKey → Message → Signature → Bool)
      (SignedBy : PublicKey → Message → Type)
      (pk : PublicKey) (m : Message),
      (Σ' σ : Signature, verify pk m σ = true) → SignedBy pk m) :
    Impossible :=
  sound Unit Unit Unit (fun _ _ _ => true) (fun _ _ => Impossible) () () ⟨(), rfl⟩

/-! consented-for-training at most Epi. -/

namespace ConsentFromHeader

variable {Artefact : Type}

def consent (ConsentedForTraining LicenceHeader : Artefact → Type) (x : Artefact) :
    Warrant Standpoint .licensor (ConsentedForTraining x) :=
  ⟨LicenceHeader x⟩

def consentEpi (ConsentedForTraining LicenceHeader : Artefact → Type)
    (x : Artefact) (header : LicenceHeader x) :
    Epi Standpoint .licensor (ConsentedForTraining x) :=
  ⟨consent ConsentedForTraining LicenceHeader x, header⟩

def ConsentSound (ConsentedForTraining LicenceHeader : Artefact → Type)
    (x : Artefact) : Type :=
  (consent ConsentedForTraining LicenceHeader x).Evidence → ConsentedForTraining x

end ConsentFromHeader

def noConsentSound
    (sound : ∀ (Artefact : Type) (C H : Artefact → Type) (x : Artefact),
      ConsentFromHeader.ConsentSound C H x) :
    Impossible :=
  sound Unit (fun _ => Impossible) (fun _ => Unit) () ()

/-- Rule 6: levels do not transfer. -/
def noTransfer
    (transfer : ∀ A B : Type,
      SoundWarrant Standpoint .verifier A → Epi Standpoint .licensor B → B) :
    Impossible :=
  transfer Unit Impossible ⟨⟨Unit⟩, fun t => t⟩ ⟨⟨Unit⟩, ()⟩

/-! The parameters of SignatureVerify can be supplied. -/

namespace ToyModel

def toyVerify (pk m σ : Nat) : Bool := Nat.beq σ (pk + m)

def ToySignedBy (pk m : Nat) : Type := Σ' σ : Nat, toyVerify pk m σ = true

def toyUnforgeable (pk m σ : Nat) (ok : toyVerify pk m σ = true) : ToySignedBy pk m :=
  ⟨σ, ok⟩

def toyExample : ToySignedBy 2 3 :=
  SignatureVerify.verifiedSignedBy toyVerify ToySignedBy toyUnforgeable 2 3 5 rfl

end ToyModel

end Provenance

#print axioms Provenance.SignatureVerify.signatureSound_evidence
#print axioms Provenance.SignatureVerify.verifiedSignedBy
#print axioms Provenance.noSignatureSound
#print axioms Provenance.noConsentSound
#print axioms Provenance.noTransfer
#print axioms Provenance.ToyModel.toyExample
