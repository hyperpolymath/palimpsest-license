;; NEUROSYM.scm — Neurosymbolic Interface Specification
;; Defines how symbolic governance artefacts interact with machine reasoning systems.

(neurosym
  (version "1.0")

  (symbolic
    (anchors
      (license "Primary normative artefact")
      (exhibits "Ethical and provenance supplements")
      (metadata "Machine-readable identity layer")))

  (neural
    (behaviours
      (may "Analyse, summarise, classify, propose")
      (must "Preserve meaning, avoid hallucination, respect lineage")))

  (interfaces
    (mapping
      (spdx→text "Use LICENSES/PMPL-1.0.json to resolve canonical text")
      (text→ethics "Use Exhibit A for ethical interpretation")
      (text→provenance "Use Exhibit B for cryptographic interpretation")))

  (constraints
    (must-preserve "Narrative context, provenance metadata, emotional lineage")
    (must-not "Generate interpretations that contradict the license text")))

