# CLAUDE.md

This file provides guidance for Claude Code when working with this project.

## Project Overview

**Anamnesis** - A conversation knowledge extraction and reconciliation system that parses tangled multi-LLM discussion threads, tracks artifact lifecycles (created→modified→removed→evaluated), cross-links related fragments across conversations, and generates clean summaries with content properly bucketed by project/topic.

**Problem Solved**: Mixed-project conversations, dead-end tangents, and lost context in AI-assisted development workflows.

**Current State**: Initial implementation phase. Core components scaffolded, parsers and ports functional.

## Tech Stack

### Core Components
- **Elixir** (orchestration) - Stable concurrency model
- **OCaml→Elixir bridge** (parsing) - Parser combinators via ports/NIFs
- **Virtuoso + SPARQL** (knowledge graph) - RDF storage and querying
- **Julia** (RDF manipulation, KBANN, reservoir computing) - Never Python per user constraint
- **λProlog/Teyjus** (meta-reasoning) - Conversation/artifact reasoning
- **ReScript** (visualization) - Type safety, functional, eventual JS replacement

### Constraints
- ❌ **NO PYTHON** - Use Julia for scientific computing
- ✅ Multi-LLM support from start (stub complexity initially)
- ✅ Type safety throughout
- ✅ Functional paradigm
- ✅ Academic rigor

## Data Sources

**Current**: Claude, Mistral, ChatGPT, LMArena, Copilot, Genesis, Edge Phi3, Firefox/Chrome, git logs, local LLMs

**Future**: WhatsApp, LinkedIn

## Project Structure

```
.
├── CLAUDE.md                    # This file - guidance for Claude Code
├── parser/                      # OCaml parsing components
├── orchestrator/               # Elixir orchestration layer
├── reasoning/                  # λProlog meta-reasoning
├── learning/                   # Julia KBANN/reservoir computing
├── visualization/              # ReScript UI components
├── proving-ground/             # Test workspace (zotero-voyant-export copy)
└── docs/                       # Documentation (AsciiDoc preferred)
```

## Key Architectural Concepts

### Design Principles
- Multi-category membership (conversations span projects)
- Episodic memory structure
- Fuzzy boundaries (not rigid categorization)
- Artifact lifecycle tracking (created→modified→removed→evaluated)
- Cross-conversation fragment linking

### Test Case
**zotero-voyant-export** repository - contaminated with Anamnesis planning discussions, needs untangling. This IS our proving ground.

**Strategy**: Copy entire repo to `proving-ground/`, preserve original, store iterations.

**Handover Docs Location**: `zotero-voyant-export/docs/contamination-notice/`
- `ANAMNESIS_HANDOVER_MINIMAL.adoc`
- `THREAD_CONTAMINATION_WARNING.adoc`

## Development Guidelines

### Documentation
- **Default format**: AsciiDoc (`.adoc`)
- **Complex documents**: LaTeX when needed
- **Academic rigor**: Maintain research-grade documentation

### Code Style
- Functional paradigm throughout
- Type safety (OCaml, ReScript, Elixir typespecs)
- Clear naming conventions
- Small, focused functions
- Parser combinators for OCaml parsing

### Git Workflow
- Work on feature branches (prefixed with `claude/`)
- Write clear, descriptive commit messages
- Push changes when requested by user

### Testing
- Test-driven approach
- Use proving ground for real-world testing
- Ensure type safety catches errors early

## Next Steps (Roadmap)

### Phase 1: Research & Setup
1. ✅ Create Anamnesis repository (this repo)
2. ✅ Research tech options:
   - ✅ Julia RDF libraries (Serd.jl recommended)
   - ✅ Julia reservoir computing (ReservoirComputing.jl)
   - ✅ PuppyGraph evaluation (stick with Virtuoso)
   - ✅ ReScript visualization (Reagraph, recharts)
3. ⬜ Copy proving ground: Clone zotero-voyant-export to `proving-ground/`
4. ⬜ Create maximal handover document (necessary AND sufficient version)
5. ✅ Setup project structure directories

### Phase 2: Milestone 1 (In Progress)
**Goal**: Parse single Claude conversation JSON → Virtuoso RDF triples
- ✅ Claude JSON format parser (OCaml)
- ✅ Generic conversation types
- ✅ Elixir port infrastructure
- ✅ Julia RDF generation modules
- ⬜ End-to-end integration testing
- ⬜ Virtuoso storage integration

## Related Projects

- **ReScript Evangeliser** - Learning curve synergies with ReScript
- **Zotero:NSAI** - Neurosymbolic AI integration
- **Fogbinder** - Uncertainty-as-feature framework

## Academic Context

Relevant concepts to user's research/journalism work:
- **Agnotology** - Study of culturally-induced ignorance
- **Nescience** - Absence of knowledge (vs agnotology=knowing wrong)
- **Axiology** - Theory of value
- **Ethics** - Moral philosophy applications

## Notes for Claude

### Critical Constraints
- **NEVER** suggest Python - always use Julia for scientific computing
- **ALWAYS** use AsciiDoc for documentation unless user requests LaTeX
- **MULTI-LLM**: Design for multiple LLM sources from start, but stub complexity initially
- **PROVING GROUND**: Work on copies, preserve originals, store iterations

### User Preferences
- OCaml/Haskell hybrid approach for parsing
- ReScript for visualization (type safety, functional, kill JS)
- Academic rigor in documentation and design
- Question assumptions, provide rigorous analysis

### Tool Usage
- Use TodoWrite for complex multi-step tasks
- Leverage Task tool for exploratory research
- Read, Edit, Write for file operations (not bash)
- Ask for clarification when requirements are ambiguous

## Resources

- Repository: https://github.com/Hyperpolymath/anamnesis
- Test Case Repo: zotero-voyant-export (contaminated, needs untangling)
- Machine-readable state: `.machine_readable/STATE.scm`

---

Last updated: 2026-01-09
