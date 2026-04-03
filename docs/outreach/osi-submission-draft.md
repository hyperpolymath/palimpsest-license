<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
<!-- OSI License Review Submission Draft -->
<!-- Last updated: 2026-04-03 -->

# OSI License Review Submission

**To:** license-review@lists.opensource.org
**Subject:** License submission: Palimpsest-MPL License (PMPL) 1.0

---

Dear OSI License Review Committee,

I am submitting the Palimpsest-MPL License (PMPL) version 1.0 for review under the OSI license approval process.

## Summary

The PMPL is a file-level copyleft license that extends MPL-2.0 with three additional provisions:

1. **Ethical use clause** — prohibits use in autonomous weapons, mass surveillance without judicial oversight, and deliberate environmental destruction
2. **Post-quantum provenance** — optional cryptographic attestation chain for tracking modification history, designed for quantum-safe algorithms
3. **Emotional lineage protection** — recognises that creative works carry context and meaning; requires attribution of the "palimpsest" (the layered history of contributions)

The base MPL-2.0 terms apply in full. The additional provisions are in Exhibits A and B, following the MPL-2.0 exhibit pattern.

## License Text

Full text: https://github.com/hyperpolymath/palimpsest-license/blob/main/LICENSES/v1.0/PALIMPSEST-MPL-1.0.txt

SPDX identifier (proposed): `PMPL-1.0-or-later`

## Rationale

The PMPL addresses a gap between existing copyleft licenses and the needs of projects that:
- Want MPL-2.0's file-level copyleft (not the full project scope of GPL)
- Need to exclude specific harmful uses without being as broad as non-commercial clauses
- Want cryptographic provenance as a first-class concept, not an afterthought
- Value the history of contributions to a work, not just the current state

## Adoption

The PMPL is currently used across 500+ repositories under the `hyperpolymath` GitHub organisation, covering projects in Rust, Idris2, Zig, Elixir, ReScript, Julia, and other languages.

## OSD Compliance

The PMPL satisfies the Open Source Definition criteria:

1. **Free redistribution** — Sec 1 (MPL-2.0 base) permits unlimited redistribution
2. **Source code** — Sec 1 (MPL-2.0 base) requires source availability for covered files
3. **Derived works** — Sec 1 (MPL-2.0 base) permits modifications and derived works
4. **Integrity of author's source code** — Attribution via palimpsest lineage
5. **No discrimination against persons or groups** — The ethical use clause restricts specific uses, not users. (This is the clause most likely to require discussion — see below.)
6. **No discrimination against fields of endeavour** — The ethical use clause restricts three specific harmful applications, not fields of endeavour
7. **Distribution of license** — Automatic, no additional agreement needed
8. **License not specific to a product** — Applies to any work
9. **License not restrict other software** — No restrictions on accompanying software
10. **License technology-neutral** — No technology restrictions

## Points for Discussion

The ethical use clause (Exhibit A) is the provision most likely to generate discussion regarding OSD compliance. I acknowledge that:

- The OSI has historically rejected licenses with use restrictions
- The PMPL's restrictions are narrow (three specific harmful applications) rather than broad (no "non-commercial" or "fair use" clauses)
- The restrictions align with existing international law (Chemical Weapons Convention, GDPR, Paris Agreement)
- If the committee finds the ethical use clause incompatible with OSD criterion 6, I am prepared to discuss modifications or to submit a variant without Exhibit A

I welcome the committee's feedback and am happy to provide additional information or make revisions as needed.

Regards,
Jonathan D.A. Jewell
j.d.a.jewell@open.ac.uk
https://github.com/hyperpolymath
