;; META.scm — Repository Identity Manifest
;; Defines the canonical identity, purpose, and interpretive frame.

(meta
  (id "palimpsest-license")
  (version "1.0")
  (spdx "PMPL-1.0-or-later")
  (governed-by "Dutch law")
  (steward "Palimpsest Stewardship Council")

  (purpose
    "To maintain the canonical text, governance, provenance, and tooling for the Palimpsest-MPL License.")

  (scope
    (legal "License text, exhibits, jurisdictional frameworks")
    (governance "Council processes, versioning, interpretive guidance")
    (tooling "Provenance tools, audit tools, signing tools")
    (documentation "User guides, integration guides, compatibility notes"))

  (constraints
    (must-preserve "Emotional lineage, provenance metadata, narrative context")
    (must-not "Strip provenance, misrepresent lineage, obscure authorship"))

  (lineage
    (root "MPL-2.0")
    (extension "Ethical use, emotional lineage, quantum-safe provenance")))
