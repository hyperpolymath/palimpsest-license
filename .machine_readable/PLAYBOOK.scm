;; PLAYBOOK.scm — Agent Playbook for Palimpsest License
;; Defines canonical behaviours, rituals, and operational flows.

(playbook
  (version "1.0")

  (rituals
    (submit-proposal
      "Open issue → Provide rationale → Link to exhibits → Await Council triage")
    (update-license
      "Draft revision → Public comment → Council vote → Publish → Archive previous version")
    (provenance
      "pmpl-sign → commit → pmpl-verify → CI audit"))

  (behaviours
    (agents
      (must "Respect emotional lineage, preserve provenance metadata")
      (should "Annotate changes with narrative context")
      (must-not "Strip signatures, obscure authorship, or remove lineage chains")))

  (interfaces
    (cli "pmpl-sign, pmpl-verify, pmpl-audit")
    (docs "README.adoc, GOVERNANCE.adoc, VERSIONING.adoc")
    (legal "legal/PALIMPSEST-MPL-1.0.txt")))
