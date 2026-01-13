;; AGENTIC.scm — Agentic Reasoning Specification
;; Defines how autonomous agents interpret, modify, and interact with artefacts.

(agentic
  (version "1.0")

  (interpretation
    (license "Treat PMPL as binding legal text with ethical extensions")
    (exhibits "Interpret as normative supplements")
    (metadata "Use SPDX metadata as canonical mapping"))

  (agency
    (allowed
      (read "All artefacts")
      (propose "Changes via issues or PRs")
      (verify "Provenance and compliance"))
    (forbidden
      (modify "License text without Council approval")
      (strip "Provenance metadata")
      (misrepresent "Lineage or authorship")))

  (autonomy
    (agents-may
      "Generate analyses, propose improvements, audit provenance")
    (agents-must
      "Preserve emotional lineage, maintain narrative context")))

