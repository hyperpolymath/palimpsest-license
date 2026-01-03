;; SPDX-License-Identifier: MPL-2.0
;; META.scm - Project metadata and architectural decisions

(define project-meta
  `((version . "1.0.0")
    (architecture-decisions
      ((adr-001
        (status . "accepted")
        (date . "2024-06-01")
        (context . "Need license compatible with AI age concerns")
        (decision . "Layer Palimpsest ethical framework on top of MPL-2.0")
        (consequences . "MPL-2.0 provides legal backing, Palimpsest adds ethical layer"))
       (adr-002
        (status . "accepted")
        (date . "2024-09-01")
        (context . "Need machine-readable project metadata")
        (decision . "Use 6SCM files standard (STATE, META, ECOSYSTEM, PLAYBOOK, AGENTIC, NEUROSYM)")
        (consequences . "Consistent metadata across all repos, AI-parseable"))))
    (development-practices
      ((code-style . "ocamlformat")
       (security . "openssf-scorecard")
       (testing . "comprehensive")
       (versioning . "semver")
       (documentation . "asciidoc")
       (branching . "trunk-based")))
    (design-rationale
      ((bilingual . "Dutch legally binding, English for accessibility")
       (layered . "MPL-2.0 legal + Palimpsest ethical")
       (6scm . "Machine-readable metadata for tooling and AI agents")))))
