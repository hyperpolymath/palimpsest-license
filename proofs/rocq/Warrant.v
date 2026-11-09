(* SPDX-License-Identifier: PMPL-1.0-or-later *)
(* SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell *)

(* Rocq leg of proofs/agda/Provenance/Warrant.agda, re-proved by hand
   (standards 3-practice/PROOF-POLICY.adoc §2).  The Agda module is the
   source of truth; the proof ledger compares each statement here
   with its Agda statement (PROOF-NEEDS.adoc, Correspondence).  Core
   library only. *)

(* epistemic-types' records (EpistemicTypes.Warrant), restated at Agda's
   Set, i.e. wℓ = lzero as Provenance.Warrant uses them.  Coq record fields
   are global, so Epi's fields are prefixed. *)
Record Warrant (K : Set) (k : K) (A : Set) : Type :=
  mkWarrant { Evidence : Set }.
Arguments mkWarrant {K k A} Evidence.
Arguments Evidence {K k A} w.

Record Epi (K : Set) (k : K) (A : Set) : Type :=
  epi { epi_warrant : Warrant K k A; epi_evidence : Evidence epi_warrant }.
Arguments epi {K k A} epi_warrant epi_evidence.

Record SoundWarrant (K : Set) (k : K) (A : Set) : Type :=
  soundWarrant { warrant : Warrant K k A; sound : Evidence warrant -> A }.
Arguments soundWarrant {K k A} warrant sound.
Arguments warrant {K k A} s.
Arguments sound {K k A} s _.

Definition sound_epi {K : Set} {k : K} {A : Set}
  (sw : SoundWarrant K k A) (token : Evidence (warrant sw)) : A :=
  sound sw token.

(* EpistemicTypes.EchoBridge.Impossible *)
Inductive Impossible : Set := .

Inductive Standpoint : Set := author | licensor | verifier | consumer.

(* signed-by at sound: the rule signature-verify. *)
Section SignatureVerify.
  Variables PublicKey Message Signature : Set.
  Variable verify : PublicKey -> Message -> Signature -> bool.
  Variable SignedBy : PublicKey -> Message -> Set.
  Variable unforgeable :
    forall (pk : PublicKey) (m : Message) (s : Signature),
      verify pk m s = true -> SignedBy pk m.

  Definition Verified (pk : PublicKey) (m : Message) : Set :=
    { s : Signature & verify pk m s = true }.

  Definition signed_by (k : Standpoint) (pk : PublicKey) (m : Message)
    : Warrant Standpoint k (SignedBy pk m) :=
    mkWarrant (Verified pk m).

  Definition signature_sound (k : Standpoint) (pk : PublicKey) (m : Message)
    : SoundWarrant Standpoint k (SignedBy pk m) :=
    soundWarrant (signed_by k pk m)
      (fun v => unforgeable pk m (projT1 v) (projT2 v)).

  Theorem signature_sound_evidence :
    forall (k : Standpoint) (pk : PublicKey) (m : Message),
      Evidence (warrant (signature_sound k pk m)) = Verified pk m.
  Proof. reflexivity. Qed.

  Definition verified_signed_by (pk : PublicKey) (m : Message) (s : Signature)
    (ok : verify pk m s = true) : SignedBy pk m :=
    sound_epi (signature_sound verifier pk m) (existT _ s ok).
End SignatureVerify.

(* Rule 3: the assumption is necessary. *)
Definition no_signature_sound
  (sound_map :
     forall (PublicKey Message Signature : Set)
            (verify : PublicKey -> Message -> Signature -> bool)
            (SignedBy : PublicKey -> Message -> Set)
            (pk : PublicKey) (m : Message),
       { s : Signature & verify pk m s = true } -> SignedBy pk m)
  : Impossible :=
  sound_map unit unit unit (fun _ _ _ => true) (fun _ _ => Impossible)
            tt tt (existT _ tt eq_refl).

(* consented-for-training at most Epi. *)
Section ConsentFromHeader.
  Variable Artefact : Set.
  Variables ConsentedForTraining LicenceHeader : Artefact -> Set.

  Definition consent (x : Artefact)
    : Warrant Standpoint licensor (ConsentedForTraining x) :=
    mkWarrant (LicenceHeader x).

  Definition consent_epi (x : Artefact) (header : LicenceHeader x)
    : Epi Standpoint licensor (ConsentedForTraining x) :=
    epi (consent x) header.

  Definition ConsentSound (x : Artefact) : Set :=
    Evidence (consent x) -> ConsentedForTraining x.
End ConsentFromHeader.

Definition no_consent_sound
  (sound_map : forall (Artefact : Set) (C H : Artefact -> Set) (x : Artefact),
                 ConsentSound Artefact C H x)
  : Impossible :=
  sound_map unit (fun _ => Impossible) (fun _ => unit) tt tt.

(* Rule 6: levels do not transfer. *)
Definition no_transfer
  (transfer : forall A B : Set,
                SoundWarrant Standpoint verifier A ->
                Epi Standpoint licensor B -> B)
  : Impossible :=
  transfer unit Impossible
    (soundWarrant (mkWarrant unit) (fun t => t))
    (epi (mkWarrant unit) tt).

(* The parameters of SignatureVerify can be supplied. *)
Module ToyModel.
  Definition toy_verify (pk m s : nat) : bool := Nat.eqb s (pk + m).
  Definition ToySignedBy (pk m : nat) : Set :=
    { s : nat & toy_verify pk m s = true }.
  Definition toy_unforgeable (pk m s : nat) (ok : toy_verify pk m s = true)
    : ToySignedBy pk m := existT _ s ok.
  Definition example : ToySignedBy 2 3 :=
    verified_signed_by nat nat nat toy_verify ToySignedBy toy_unforgeable
      2 3 5 eq_refl.
End ToyModel.

Print Assumptions signature_sound_evidence.
Print Assumptions verified_signed_by.
Print Assumptions no_signature_sound.
Print Assumptions no_consent_sound.
Print Assumptions no_transfer.
Print Assumptions ToyModel.example.
