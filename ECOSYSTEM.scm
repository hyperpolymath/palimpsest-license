;; ECOSYSTEM.scm — Palimpsest License Ecosystem Specification
;; Canonical ontology for agents, artefacts, and governance flows.

(ecosystem
  (name "palimpsest-license")
  (version "1.0")
  (governance "Palimpsest Stewardship Council")
  (jurisdiction "NL")

  (actors
    (council "Palimpsest Stewardship Council")
    (contributors "Individuals submitting improvements")
    (maintainers "Repository maintainers")
    (agents "Automated systems interacting with the license"))

  (artefacts
    (license "legal/PALIMPSEST-MPL-1.0.txt")
    (exhibit-a "legal/exhibits/EXHIBIT-A-ETHICAL-USE.txt")
    (exhibit-b "legal/exhibits/EXHIBIT-B-QUANTUM-SAFE.txt")
    (metadata "LICENSES/PMPL-1.0.json")
    (governance "GOVERNANCE.adoc")
    (versioning "VERSIONING.adoc"))

  (flows
    (proposal "Contributor submits proposal → Council review → Public comment → Ratification")
    (versioning "Council publishes new version → Metadata updated → Historical archive extended")
    (provenance "pmpl-sign → pmpl-verify → pmpl-audit"))

  (principles
    (ethical-use "Preserve emotional lineage and cultural meaning")
    (provenance "Maintain cryptographic lineage")
    (reversibility "All artefacts must be reversible and auditable")
    (narratability "Every artefact must tell its own story")))
