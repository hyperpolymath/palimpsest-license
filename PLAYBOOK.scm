;; SPDX-License-Identifier: PMPL-1.0-or-later
;; PLAYBOOK.scm - Operational runbook

(define playbook
  `((version . "1.0.0")
    (procedures
      ((build . (("docs" . "just docs")
                 ("validate" . "just validate")))
       (test . (("lint" . "npm run lint")
                ("format" . "npm run format")))
       (release . (("version-bump" . "Update CHANGELOG.md")
                   ("tag" . "git tag -a vX.Y.Z")
                   ("publish" . "just release")))
       (translation . (("sync" . "Check bilingual-map.md")
                       ("review" . "Dutch legal review")))))
    (alerts . ())
    (contacts
      ((steward . "Jonathan D.A. Jewell")
       (repo . "github.com/hyperpolymath/palimpsest-license")))))
