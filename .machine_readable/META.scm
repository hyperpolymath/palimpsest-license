;; SPDX-License-Identifier: AGPL-3.0-or-later
;; META.scm - Architecture decisions and practices for palimpsest-license
;; Media-Type: application/meta+scheme

(meta
  (architecture-decisions
    (adr-001
      (status "accepted")
      (date "2025-12-09")
      (title "OCaml as primary implementation language")
      (context "Need type-safe implementation for license validation logic")
      (decision "Use OCaml with Melange for browser, OCanren for logic programming")
      (consequences
        ("Strong static typing catches errors early"
         "Melange enables browser-based validation"
         "OCanren provides declarative license rules"
         "Haskell codebase requires migration")))
    (adr-002
      (status "accepted")
      (date "2025-04-05")
      (title "Dutch law as primary jurisdiction")
      (context "Need stable, creator-friendly legal framework")
      (decision "Dutch law primary, Scottish courts for disputes")
      (consequences
        ("Strong moral rights protection"
         "EU GDPR alignment"
         "Requires Dutch translation of all legal texts")))
    (adr-003
      (status "accepted")
      (date "2024-12-15")
      (title "Bilingual documentation")
      (context "Legal enforceability requires native language")
      (decision "Dutch legally binding, English informative")
      (consequences
        ("Increased documentation burden"
         "Translation consistency checks needed"
         "Wider accessibility"))))

  (development-practices
    (code-style
      (ocaml "ocp-indent, ocamlformat")
      (docs "AsciiDoc primary, Markdown for GitHub"))
    (security
      (principle "Defense in depth")
      (requirements
        ("SHA-256+ for hashing"
         "HTTPS only"
         "No hardcoded secrets"
         "SPDX headers on all files")))
    (testing
      (framework "OUnit2 for OCaml")
      (coverage-target 80))
    (versioning "SemVer")
    (documentation "AsciiDoc with bilingual support")
    (branching "main for stable, feature branches for development"))

  (design-rationale
    (why-ocaml
      "Type safety for legal logic, Melange for browser reach, OCanren for declarative rules")
    (why-dutch-law
      "Strong moral rights, GDPR alignment, established IP framework")
    (why-not-creative-commons
      "CC lacks AI training consent, emotional lineage, quantum-proof attribution")
    (why-palimpsest-metaphor
      "Layers of meaning preserved through overwriting - like cultural memory")))
