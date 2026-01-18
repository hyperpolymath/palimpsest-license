;; SPDX-License-Identifier: PMPL-1.0-or-later
;; STATE.scm - Project state for palimpsest-license

(state
  (metadata
    (version "0.4.0")
    (schema-version "1.0")
    (created "2024-01-01")
    (updated "2025-01-03")
    (project "palimpsest-license")
    (repo "hyperpolymath/palimpsest-license"))

  (project-context
    (name "Palimpsest License")
    (tagline "Ethical open source licensing framework for the AI age")
    (tech-stack "Scheme" "AsciiDoc" "OCaml" "Nickel"))

  (current-position
    (phase "v0.4")
    (overall-completion 70)
    (components
      (license-text 90)
      (guides 80)
      (tooling 50)
      (governance 85)
      (translations 40)))

  (route-to-mvp
    (milestone "v1.0 - Legally Formalized"
      (items
        ("Legal review complete" pending)
        ("Dutch/English parity" in-progress)
        ("Governance council formed" done)
        ("Tooling suite complete" pending))))

  (critical-next-actions
    (immediate
      ("Complete legal review")
      ("Finalize v0.4 text"))))
