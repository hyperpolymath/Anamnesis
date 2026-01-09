;; SPDX-License-Identifier: AGPL-3.0-or-later
;; ECOSYSTEM.scm - Ecosystem position for anamnesis
;; Media-Type: application/vnd.ecosystem+scm

(ecosystem
  (version "1.0")
  (name "anamnesis")
  (type "knowledge-management-system")
  (purpose "Extract, reconcile, and visualize knowledge from multi-LLM conversations")

  (position-in-ecosystem
    (category "developer-tools")
    (subcategory "ai-assisted-development")
    (unique-value
      "Multi-LLM conversation parsing"
      "Artifact lifecycle tracking across sessions"
      "Fuzzy multi-category membership"
      "RDF-based knowledge representation"
      "Cross-conversation fragment linking"))

  (related-projects
    ("rescript-evangeliser" "sibling" "Shares ReScript visualization patterns")
    ("zotero-nsai" "sibling" "Neurosymbolic AI integration techniques")
    ("fogbinder" "sibling" "Uncertainty-as-feature framework concepts")
    ("proving-ground" "test-data" "zotero-voyant-export with contamination"))

  (what-this-is
    "A tool for parsing conversation exports from multiple LLM providers"
    "A knowledge graph builder from development conversations"
    "An artifact lifecycle tracker (created→modified→removed→evaluated)"
    "A cross-conversation linker for related discussion fragments"
    "A project categorization system with fuzzy boundaries"
    "A research-grade documentation generator")

  (what-this-is-not
    "NOT a chat interface or LLM frontend"
    "NOT a real-time conversation tool"
    "NOT a replacement for version control"
    "NOT a project management system"
    "NOT a search engine (uses SPARQL for structured queries)"))
