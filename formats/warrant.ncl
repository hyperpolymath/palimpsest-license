# SPDX-License-Identifier: PMPL-1.0-or-later
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
#
# Warrant-level provenance records: spec/PROVENANCE-SPEC.adoc §7.
#
# The three levels are epistemic-types' records (src/EpistemicTypes/Warrant.agda
# at 6a68de3), stated as data:
#
#   warrant   Warrant K κ A        a claim and its evidence type; no token held
#   epi       Epi K κ A            a token held; holding it does not give A
#   sound     SoundWarrant K κ A   a token and a registered rule proved to
#             (+ token, sound-epi) entail A, with the rule's assumption named
#
# Usage, for a JSON array of records:
#
#   nickel export --format json <<< \
#     'let W = import "formats/warrant.ncl" in (import "records.json") | W.Records'
#
# Every check below is a §7.3 rule; the error message names the rule so a
# rejected record says which one it broke.

let level_names = ["warrant", "epi", "sound"] in

let standpoint_names = ["author", "licensor", "verifier", "consumer"] in

# §7.4: the evidence type of each claim kind (the Warrant's `Evidence` field).
let admissible_evidence = {
  "signed-by" = ["signature", "signature-chain"],
  "licensed-under" = ["spdx-header", "licence-file", "provenance-metadata"],
  "consented-for-training" = ["licence-header", "aibdp-declaration", "consent-record", "provenance-metadata"],
  "derived-from" = ["lineage-reference", "provenance-metadata", "signature-chain"],
}
in

# §7.5: verification rules that entail one claim kind under a named
# assumption.  `status` is that of the machine-checked proof at `proof`, and
# moves to "proven" only with that module.  No entry concludes
# consented-for-training (rule 4).
let rule_table = {
  "signature-verify" = {
    concludes = "signed-by",
    consumes = ["signature", "signature-chain"],
    assumption = "EUF-CMA security of the signature algorithm named in each signature",
    proof = "proofs/agda/Provenance/Warrant.agda",
    status = "designed",
  },
}
in

let member = fun x xs => std.array.elem x xs in

let fail = fun msg => 'Error { message = msg } in

let check_claim = fun c =>
  if !(std.record.has_field c.kind admissible_evidence) then
    fail "claim.kind must be one of: %{std.string.join ", " (std.record.fields admissible_evidence)}"
  else if !(member c.standpoint standpoint_names) then
    fail "claim.standpoint must be one of: %{std.string.join ", " standpoint_names}"
  else
    'Ok
in

let check_evidence = fun kind evidence =>
  let allowed = admissible_evidence."%{kind}" in
  let bad = std.array.filter (fun e => !(member e.kind allowed)) evidence in
  if bad != [] then
    fail "evidence kind '%{(std.array.first bad).kind}' is not admissible for %{kind} (admissible: %{std.string.join ", " allowed})"
  else
    'Ok
in

let check_level = fun r =>
  let kind = r.claim.kind in
  if !(member r.level level_names) then
    fail "level must be one of: %{std.string.join ", " level_names}"
  else if r.level == "warrant" then
    if r.evidence != [] then
      fail "rule 1: a record at warrant holds no token; evidence must be empty"
    else if r.sound_by != null then
      fail "rule 1: a record at warrant has no sound_by"
    else
      'Ok
  else if r.level == "epi" then
    if r.evidence == [] then
      fail "rule 2: a record at epi holds at least one token"
    else if r.sound_by != null then
      fail "rule 2: a record at epi has sound_by null; a named rule makes it sound"
    else
      'Ok
  else if kind == "consented-for-training" then
    fail "rule 4: no rule entails consented-for-training; a consent claim is at most epi"
  else if r.evidence == [] then
    fail "rule 3: a record at sound holds at least one token"
  else if r.sound_by == null then
    fail "rule 3: a record at sound names its rule in sound_by"
  else if !(std.record.has_field r.sound_by.rule rule_table) then
    fail "rule 3: sound_by.rule '%{r.sound_by.rule}' is not a registered rule (registered: %{std.string.join ", " (std.record.fields rule_table)})"
  else
    let rule = rule_table."%{r.sound_by.rule}" in
    if rule.concludes != kind then
      fail "rule 6: %{r.sound_by.rule} concludes %{rule.concludes}, not %{kind}; levels do not transfer between claims"
    else if r.sound_by.assumption != rule.assumption then
      fail "rule 3: sound_by.assumption must state the rule's assumption verbatim: \"%{rule.assumption}\""
    else if !(std.array.any (fun e => member e.kind rule.consumes) r.evidence) then
      fail "rule 3: %{r.sound_by.rule} consumes %{std.string.join ", " rule.consumes}; no such token is held"
    else
      'Ok
in

let Evidence = {
  kind | String,
  ref | String,
}
in

let SoundBy = {
  rule | String,
  assumption | String,
}
in

let Nullable = fun C =>
  std.contract.custom (fun label value =>
    if value == null then 'Ok value else 'Ok (std.contract.apply C label value)
  )
in

let Source = {
  file | String,
  line | Number,
  field | String,
}
in

let Shape = {
  artefact | String,
  claim | {
    kind | String,
    standpoint | String,
    subject | String,
    statement | String,
  },
  level | String,
  evidence | Array Evidence,
  sound_by | Nullable SoundBy,
  source | Source | optional,
}
in

let Rules = std.contract.from_validator (fun r =>
  let claim = check_claim r.claim in
  if claim != 'Ok then
    claim
  else
    let ev = check_evidence r.claim.kind r.evidence in
    if ev != 'Ok then ev else check_level r
)
in

{
  Record = std.contract.Sequence [ Shape, Rules ],
  Records = Array Record,
  admissible = admissible_evidence,
  rules = rule_table,
  levels = level_names,
  standpoints = standpoint_names,
}
