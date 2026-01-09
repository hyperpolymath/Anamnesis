;; SPDX-License-Identifier: AGPL-3.0-or-later
;; AGENTIC.scm - AI agent interaction patterns for anamnesis

(define agentic-config
  `((version . "1.0.0")
    (claude-code
      ((model . "claude-opus-4-5-20251101")
       (tools . ("read" "edit" "bash" "grep" "glob" "write" "task"))
       (permissions . "read-all")))
    (patterns
      ((code-review . "thorough")
       (refactoring . "conservative")
       (testing . "comprehensive")
       (documentation . "academic-rigor")))
    (constraints
      ((languages
         (allowed . ("elixir" "ocaml" "julia" "rescript" "bash" "scheme" "ada" "rust" "nickel"))
         (preferred . ("elixir" "ocaml" "julia" "rescript"))
         (banned . ("typescript" "go" "python" "makefile" "java" "kotlin" "swift")))
       (documentation
         (format . "asciidoc")
         (fallback . "latex"))
       (no-python . #t)
       (type-safety . #t)
       (functional-paradigm . #t)))
    (workflows
      ((new-parser
         "1. Create ATD schema in parser/lib/"
         "2. Generate types with atdgen"
         "3. Implement parser using Angstrom"
         "4. Add detection function"
         "5. Write tests with Alcotest")
       (new-elixir-port
         "1. Create GenServer in orchestrator/lib/anamnesis/ports/"
         "2. Define protocol with Erlang term format"
         "3. Add to supervision tree"
         "4. Write ExUnit tests")
       (new-julia-module
         "1. Create .jl file in learning/src/"
         "2. Add include in AnamnesisAnalytics.jl"
         "3. Export public functions"
         "4. Add tests in learning/test/")))))
