;; SPDX-License-Identifier: MPL-2.0
;; AGENTIC.scm - AI agent interaction patterns

(define agentic-config
  `((version . "1.0.0")
    (claude-code
      ((model . "claude-opus-4-5-20251101")
       (tools . ("read" "edit" "bash" "grep" "glob"))
       (permissions . "read-all")))
    (patterns
      ((code-review . "thorough")
       (refactoring . "conservative")
       (testing . "comprehensive")
       (documentation . "bilingual-aware")))
    (constraints
      ((languages . ("ocaml" "scheme" "asciidoc" "nickel"))
       (banned . ("typescript" "go" "python" "makefile"))))
    (special-instructions
      ((bilingual . "Maintain Dutch/English parity")
       (legal . "Do not modify license text without review")
       (governance . "Follow GOVERNANCE.md for major changes")))))
