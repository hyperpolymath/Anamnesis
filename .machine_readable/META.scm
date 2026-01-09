;; SPDX-License-Identifier: AGPL-3.0-or-later
;; META.scm - Meta-level information for anamnesis
;; Media-Type: application/meta+scheme

(meta
  (architecture-decisions
    ("ADR-001" "Multi-language architecture"
      "Each language for its strengths: OCaml for parsing, Elixir for orchestration,
       Julia for analytics, λProlog for reasoning, ReScript for UI"
      "accepted" "2025-11-22")
    ("ADR-002" "No Python constraint"
      "User requirement: Julia replaces Python for all scientific computing"
      "accepted" "2025-11-22")
    ("ADR-003" "RDF over property graphs"
      "Virtuoso + SPARQL chosen over Neo4j/PuppyGraph for semantic web standards,
       named graphs, and inference capabilities"
      "accepted" "2025-11-23")
    ("ADR-004" "Port-based inter-process communication"
      "Elixir ports for OCaml/Julia communication instead of NIFs for isolation"
      "accepted" "2025-11-23")
    ("ADR-005" "Fuzzy category membership"
      "Conversations can belong to multiple projects with varying strength (0.0-1.0)"
      "accepted" "2025-11-22"))

  (development-practices
    (code-style
      ("OCaml" "ocp-indent, 80 char lines, snake_case")
      ("Elixir" "mix format, typespecs required")
      ("Julia" "JuliaFormatter, docstrings required")
      ("ReScript" "rescript format, exhaustive pattern matching"))
    (security
      (principle "Defense in depth")
      (no-secrets-in-code #t)
      (input-validation "at port boundaries")
      (https-only #t))
    (testing
      ("OCaml" "Alcotest, qcheck for property testing")
      ("Elixir" "ExUnit, StreamData for property testing")
      ("Julia" "Test.jl, fixtures in test/fixtures")
      ("ReScript" "Jest, React Testing Library"))
    (versioning "SemVer")
    (documentation "AsciiDoc")
    (branching "main for stable, claude/* for features"))

  (design-rationale
    ("episodic-memory" "Named graphs partition data by conversation episode")
    ("artifact-lifecycle" "State machine: created→modified→removed→evaluated")
    ("fuzzy-boundaries" "Real conversations span multiple projects")
    ("contamination-detection" "Cross-project artifact sharing indicates mixing")
    ("reservoir-computing" "ESN for sequence prediction without backprop complexity")))
