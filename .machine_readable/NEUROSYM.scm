;; SPDX-License-Identifier: PMPL-1.0-or-later
;; NEUROSYM.scm - Neurosymbolic integration config

(define neurosym-config
  `((version . "1.0.0")
    (symbolic-layer
      ((type . "scheme")
       (reasoning . "deductive")
       (verification . "formal")
       (ontology . "license-compliance")))
    (neural-layer
      ((embeddings . false)
       (fine-tuning . false)
       (consent-required . true)))
    (integration
      ((license-parsing . "Extract clauses from license text")
       (compliance-checking . "Verify project meets Palimpsest requirements")
       (metadata-validation . "Validate 6SCM file structure")))))
