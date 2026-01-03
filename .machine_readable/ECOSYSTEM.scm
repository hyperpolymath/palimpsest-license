;; SPDX-License-Identifier: AGPL-3.0-or-later
;; ECOSYSTEM.scm - Ecosystem position for palimpsest-license
;; Media-Type: application/vnd.ecosystem+scm

(ecosystem
  (version "1.0")
  (name "palimpsest-license")
  (type "legal-framework")
  (purpose "Ethical licensing for creative works in the age of AI")

  (position-in-ecosystem
    (category "open-source-licensing")
    (subcategory "ai-ethics-aware")
    (unique-value
      ("Emotional lineage protection"
       "Quantum-proof traceability"
       "DAO governance support"
       "Dutch/Scottish dual jurisdiction"
       "NI system consent requirements")))

  (related-projects
    (sibling-standard
      (name "rhodium-standard-repositories")
      (relationship "RSR-certified project")
      (url "github.com/hyperpolymath/rhodium-standard-repositories"))
    (sibling-standard
      (name "affinescript")
      (relationship "Affine type system for license verification")
      (url "github.com/hyperpolymath/affinescript"))
    (potential-consumer
      (name "creative-commons")
      (relationship "Complementary license ecosystem")
      (integration-point "CC-BY-SA + Palimpsest layering"))
    (potential-consumer
      (name "open-source-projects")
      (relationship "Projects needing AI training consent")
      (integration-point "License adoption"))
    (inspiration
      (name "mozilla-public-license")
      (relationship "MPL-2.0 base")
      (note "Palimpsest extends MPL with AI/ethics clauses")))

  (what-this-is
    ("A license framework for creative works"
     "Protection for emotional and cultural lineage"
     "Consent mechanism for AI training use"
     "Bilingual legal text (Dutch/English)"
     "Machine-readable metadata schemas"
     "Validation tools for compliance checking"))

  (what-this-is-not
    ("Not a replacement for copyright law"
     "Not a software license (use for creative/cultural works)"
     "Not legally tested in court (yet)"
     "Not a DRM system")))
