;; SPDX-License-Identifier: AGPL-3.0-or-later
;; STATE.scm - Project state for anamnesis
;; Media-Type: application/vnd.state+scm

(state
  (metadata
    (version "0.1.0")
    (schema-version "1.0")
    (created "2025-11-22")
    (updated "2026-01-09")
    (project "anamnesis")
    (repo "github.com/hyperpolymath/anamnesis"))

  (project-context
    (name "anamnesis")
    (tagline "Conversation knowledge extraction and reconciliation system")
    (tech-stack
      ("Elixir" "orchestration" "OTP supervision, port management")
      ("OCaml" "parsing" "Angstrom combinators, Atdgen type generation")
      ("Julia" "analytics" "RDF manipulation, reservoir computing, KBANN")
      ("λProlog/ELPI" "reasoning" "Higher-order logic, meta-reasoning")
      ("ReScript" "visualization" "Type-safe React components")
      ("Virtuoso" "storage" "RDF triplestore, SPARQL 1.1")))

  (current-position
    (phase "initial-implementation")
    (overall-completion 25)
    (components
      (parser 30 "OCaml parsers, Claude format implemented")
      (orchestrator 40 "Elixir ports, pipeline skeleton")
      (reasoning 10 "λProlog module stubs")
      (learning 35 "Julia RDF and reservoir modules")
      (visualization 20 "ReScript domain types, color mixing"))
    (working-features
      "Claude JSON format detection"
      "Generic conversation type system"
      "RDF schema definitions"
      "Elixir supervision tree skeleton"
      "ReScript domain types"))

  (route-to-mvp
    (milestones
      ("M1" "Parse single Claude conversation → RDF triples"
        ("OCaml Claude parser" done)
        ("Generic conversation types" done)
        ("Elixir port communication" in-progress)
        ("Julia RDF generation" done)
        ("Virtuoso storage" pending))
      ("M2" "Multi-format parsing"
        ("ChatGPT parser" pending)
        ("Mistral parser" pending)
        ("Auto-detection" pending))
      ("M3" "λProlog reasoning"
        ("Artifact lifecycle tracking" pending)
        ("Contamination detection" pending)
        ("Fuzzy categorization" pending))
      ("M4" "Visualization"
        ("Graph rendering" pending)
        ("Timeline view" pending)
        ("Category color mixing" done))))

  (blockers-and-issues
    (critical)
    (high
      "OCaml ATD schema needs completion"
      "Port protocol needs testing")
    (medium
      "Virtuoso Docker setup documentation"
      "Julia package manifest incomplete")
    (low
      "README examples outdated"))

  (critical-next-actions
    (immediate
      "Complete OCaml conversation_types.atd"
      "Test Elixir-OCaml port communication"
      "Verify Julia module imports")
    (this-week
      "End-to-end Claude JSON to Virtuoso pipeline"
      "Basic SPARQL query tests")
    (this-month
      "Multi-format parser support"
      "λProlog artifact lifecycle module"))

  (session-history
    ("2025-11-22" "Project created, architecture designed")
    ("2025-11-23" "Tech stack research completed")
    ("2026-01-03" "Machine-readable files added")
    ("2026-01-09" "Resolved stubs, populated machine-readable files")))
