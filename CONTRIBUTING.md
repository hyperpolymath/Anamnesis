# Contributing to Anamnesis

Thank you for your interest in contributing to Anamnesis! This document provides guidelines for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [TPCF Perimeter Classification](#tpcf-perimeter-classification)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Contribution Workflow](#contribution-workflow)
- [Coding Standards](#coding-standards)
- [Testing Requirements](#testing-requirements)
- [Documentation](#documentation)
- [Commit Messages](#commit-messages)
- [Pull Request Process](#pull-request-process)
- [Review Process](#review-process)
- [Community](#community)

## Code of Conduct

This project adheres to a Code of Conduct based on **CCCP (Compassionate Code Conduct Pledge)** principles. Please read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) before contributing.

**Key Points:**
- Be respectful and considerate
- Prioritize emotional safety over efficiency
- Assume good faith
- Embrace reversibility and experimentation
- No harassment, discrimination, or aggressive behavior

## TPCF Perimeter Classification

**Current Classification: Perimeter 2 - Trusted Collaborators**

### What This Means

**Perimeter 2** is a graduated trust model designed for research-grade projects with technical complexity:

- **Read Access**: Public (anyone can clone, fork, study)
- **Write Access**: Maintainers + approved collaborators only
- **Admin Access**: Project owner (Hyperpolymath)

### Access Levels

| Level | Permissions | Requirements |
|-------|-------------|--------------|
| **Public** | Read, fork, open issues | None (open source) |
| **Contributor** | Submit PRs (reviewed before merge) | Signed Contributor Agreement, 1+ merged PR |
| **Collaborator** | Direct push to feature branches | 3+ merged PRs, technical expertise, maintainer approval |
| **Maintainer** | Push to main, release management | 10+ merged PRs, 6+ months activity, MAINTAINERS.md vote |
| **Admin** | Repository settings, security | Project founder(s) only |

### Why Perimeter 2?

Anamnesis is currently:
- **Research-grade** (not production-ready)
- **Multi-language complexity** (OCaml, Elixir, Julia, λProlog, ReScript)
- **Experimental** (testing novel approaches)
- **Pre-Milestone 1** (foundational phase)

**Not suitable for**:
- Drive-by contributions without context
- Unreviewed direct commits to main
- Breaking changes without discussion

### Migration to Perimeter 3 (Future)

We'll move to **Perimeter 3 (Community Sandbox)** when:
- [x] Milestone 1 complete (Claude JSON → Virtuoso RDF pipeline working)
- [ ] CI/CD with automated tests (>50% coverage)
- [ ] Comprehensive contributor documentation
- [ ] 3+ active maintainers
- [ ] Community governance structure established

## How to Contribute

### Types of Contributions Welcome

1. **Bug Reports**: Found an issue? Open a GitHub Issue with details
2. **Feature Requests**: Suggest improvements via GitHub Discussions
3. **Code Contributions**: Fix bugs, add features, improve performance
4. **Documentation**: Fix typos, clarify explanations, add examples
5. **Testing**: Write tests, improve coverage, report test failures
6. **Research**: Validate tech choices, benchmark performance, academic papers
7. **Design**: UX/UI improvements, architecture proposals
8. **Community**: Answer questions, help newcomers, organize events

### Not Ready Yet (But Soon!)

- **Proving Ground Testing**: Copy zotero-voyant-export, run end-to-end tests (after Milestone 1)
- **Additional Format Parsers**: ChatGPT, Mistral, Git logs (OCaml proficiency required)
- **Visualization Components**: ReScript components for Reagraph (after data pipeline works)

## Development Setup

### Prerequisites

**Language Runtimes:**
- **OCaml** 5.0+ (install via [OPAM](https://opam.ocaml.org/))
- **Elixir** 1.15+ (install via [asdf](https://asdf-vm.com/) or package manager)
- **Julia** 1.10+ (install via [juliaup](https://github.com/JuliaLang/juliaup))
- **Node.js** 18+ (for ReScript)
- **Virtuoso** 7+ (Docker recommended)

**Build Tools:**
- **Dune** 3.0+ (OCaml build system)
- **Just** (command runner - install from https://github.com/casey/just)
- **Nix** (optional, for reproducible builds)

### Quick Start

```bash
# Clone the repository
git clone https://github.com/Hyperpolymath/anamnesis.git
cd anamnesis

# Setup component dependencies
just setup-all  # Runs setup for all components

# Or setup individually:
cd parser && opam install --deps-only . && dune build
cd orchestrator && mix deps.get && mix compile
cd learning && julia --project=. -e 'using Pkg; Pkg.instantiate()'
cd visualization && npm install && npm run res:build

# Run tests
just test

# Verify RSR compliance
just rsr-check
```

See component READMEs for detailed setup:
- `parser/README.md` - OCaml parser setup
- `orchestrator/README.md` - Elixir orchestrator setup
- `reasoning/README.md` - λProlog/ELPI setup
- `learning/README.md` - Julia analytics setup
- `visualization/README.md` - ReScript visualization setup

## Contribution Workflow

### 1. Before You Start

- **Check existing issues/PRs**: Avoid duplicate work
- **Open a discussion**: For major changes, discuss first
- **Read the architecture**: `docs/architecture/system-architecture.adoc`
- **Review research**: `docs/research/` for tech stack decisions

### 2. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/bug-description
```

**Branch Naming Convention:**
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation only
- `test/` - Test additions
- `refactor/` - Code refactoring (no behavior change)
- `chore/` - Build system, dependencies, tooling

### 3. Make Changes

- Follow [Coding Standards](#coding-standards)
- Write tests for new code
- Update documentation
- Run `just validate` before committing

### 4. Commit Changes

See [Commit Messages](#commit-messages) for format.

```bash
git add <files>
git commit -m "feat(parser): add ChatGPT format parser

Implements ChatGPT conversation JSON parsing with:
- Node-based structure handling
- Message tree flattening
- Artifact extraction from code blocks

Refs #123"
```

### 5. Push and Create PR

```bash
git push origin feature/your-feature-name
```

Then open a Pull Request on GitHub with:
- **Title**: Clear, concise description
- **Description**: What, why, how
- **Issue reference**: `Closes #123` or `Refs #456`
- **Checklist**: Tests pass, docs updated, etc.

## Coding Standards

### General Principles

- **Type Safety**: Leverage static typing in every language
- **Functional Paradigm**: Prefer pure functions, immutability
- **Explicit over Implicit**: Clear naming, no magic
- **Small Functions**: <50 lines ideally
- **No Side Effects**: Isolate I/O, mutation, randomness
- **Error Handling**: Use Result/Option types, not exceptions in hot paths

### Language-Specific

#### OCaml

- **Style**: Follow [OCaml style guide](https://ocaml.org/docs/guidelines)
- **Formatting**: Use `ocamlformat` (config in `.ocamlformat`)
- **Naming**: `snake_case` for functions/variables, `CamelCase` for modules
- **Documentation**: OCamldoc comments for public APIs
- **No `Obj.magic`**: Avoid unsafe casts

#### Elixir

- **Style**: Follow [Elixir style guide](https://github.com/christopheradams/elixir_style_guide)
- **Formatting**: Use `mix format` (config in `.formatter.exs`)
- **Naming**: `snake_case` for functions/variables, `CamelCase` for modules
- **Documentation**: `@moduledoc` and `@doc` for all public functions
- **Typespecs**: Add `@spec` for all public functions
- **Pattern Matching**: Prefer pattern matching over conditionals

#### Julia

- **Style**: Follow [Julia style guide](https://docs.julialang.org/en/v1/manual/style-guide/)
- **Formatting**: Use `JuliaFormatter.jl`
- **Naming**: `snake_case` for functions, `CamelCase` for types
- **Documentation**: Docstrings for all exported functions
- **Type Stability**: Avoid type-unstable code (use `@code_warntype`)

#### λProlog (ELPI)

- **Style**: Consistent indentation (2 spaces)
- **Naming**: `snake_case` for predicates
- **Documentation**: Comment clauses, especially complex rules
- **Modularity**: Separate concerns into different files

#### ReScript

- **Style**: Follow [ReScript conventions](https://rescript-lang.org/docs/manual/latest/introduction)
- **Formatting**: Use `rescript format`
- **Naming**: `camelCase` for values/functions, `PascalCase` for modules/types
- **Documentation**: JSDoc comments for exported functions
- **Phantom Types**: Use for ID safety (e.g., `MessageId`, `ArtifactId`)

## Testing Requirements

### Minimum Coverage

- **Bronze Level (RSR)**: 50% coverage required
- **Silver Level**: 70% coverage
- **Gold Level**: 85% coverage

**Current Target**: 50%+ for Milestone 1 completion

### Test Structure

#### OCaml (Alcotest + qcheck)

```ocaml
(* test/test_claude_parser.ml *)
let test_parse_valid_conversation () =
  let json = {|{"uuid": "123", "name": "Test", ...}|} in
  match Claude_parser.parse json with
  | Ok conv ->
      Alcotest.(check string) "conversation id" "123" conv.id
  | Error e ->
      Alcotest.fail e

let () =
  Alcotest.run "Claude Parser Tests" [
    "parsing", [
      test_case "valid conversation" `Quick test_parse_valid_conversation;
    ];
  ]
```

#### Elixir (ExUnit)

```elixir
# test/anamnesis/ports/parser_port_test.exs
defmodule Anamnesis.Ports.ParserPortTest do
  use ExUnit.Case, async: true

  test "parses Claude conversation" do
    content = File.read!("test/fixtures/claude_conversation.json")
    {:ok, conv} = Anamnesis.Ports.ParserPort.parse(content, :claude)

    assert conv["platform"] == "claude"
    assert length(conv["messages"]) > 0
  end
end
```

#### Julia (Test.jl)

```julia
# test/rdf_tests.jl
using Test
using AnamnesisAnalytics

@testset "RDF Generation" begin
    conv = Dict("id" => "test-123", "messages" => [])
    triples = conversation_to_rdf(conv)

    @test length(triples) >= 1
    @test any(t -> t.predicate == RDF.type, triples)
end
```

#### ReScript (Jest)

```javascript
// __tests__/ColorMixing.test.js
import { mixColors } from '../src/transforms/ColorMixing.bs.js';

test('mixColors returns gray for empty memberships', () => {
  expect(mixColors([])).toBe('#999999');
});
```

### Running Tests

```bash
# All tests
just test

# Component-specific
cd parser && dune runtest
cd orchestrator && mix test
cd learning && julia --project=. test/runtests.jl
cd visualization && npm test
```

## Documentation

### What to Document

- **Public APIs**: All exported functions, modules, types
- **Architecture Changes**: Update `docs/architecture/system-architecture.adoc`
- **Tech Decisions**: Add to research docs or create new doc in `docs/guides/`
- **Examples**: Add code examples for non-trivial features
- **CHANGELOG.md**: Update for user-facing changes

### Documentation Formats

- **AsciiDoc** (`.adoc`): Complex technical documents, architecture
- **Markdown** (`.md`): READMEs, contribution guides, simple docs
- **Inline Comments**: Complex algorithms, non-obvious code
- **API Docs**: Language-specific (OCamldoc, ExDoc, Julia docstrings, JSDoc)

### Writing Style

- **Clear and Concise**: No jargon without explanation
- **Examples**: Show, don't just tell
- **Audience**: Assume technical competence, explain domain-specific concepts
- **Grammar**: Use spell-check, but don't obsess (substance > perfection)

## Commit Messages

### Format

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting, missing semicolons, etc. (no code change)
- `refactor`: Code refactoring (no behavior change)
- `perf`: Performance improvement
- `test`: Adding/fixing tests
- `chore`: Build system, dependencies, tooling

### Scope

Component affected: `parser`, `orchestrator`, `reasoning`, `learning`, `visualization`, `docs`, `build`

### Examples

```
feat(parser): add ChatGPT format parser

Implements ChatGPT conversation JSON parsing with node-based structure
handling and message tree flattening.

Closes #42

---

fix(orchestrator): handle parser port timeout gracefully

Previously, parser port timeouts would crash the IngestionPipeline.
Now we return {:error, :timeout} and let supervision tree restart.

Refs #67

---

docs(architecture): add offline-first deployment guide

Explains how to run Anamnesis without internet access using local
Virtuoso instance and air-gapped configuration.
```

## Pull Request Process

### Before Submitting

- [ ] Code compiles without warnings
- [ ] All tests pass (`just test`)
- [ ] New code has tests (aim for 50%+ coverage)
- [ ] Documentation updated (if applicable)
- [ ] CHANGELOG.md updated (for user-facing changes)
- [ ] Commit messages follow Conventional Commits format
- [ ] No merge conflicts with `main`
- [ ] RSR compliance check passes (`just rsr-check`)

### PR Template

Use this template when opening a PR:

```markdown
## Description

Briefly describe what this PR does and why.

## Changes

- Added X
- Fixed Y
- Refactored Z

## Testing

How was this tested? Include:
- Manual testing steps
- Automated test coverage
- Performance impact (if relevant)

## Checklist

- [ ] Tests pass locally
- [ ] Documentation updated
- [ ] CHANGELOG.md updated (if user-facing change)
- [ ] No breaking changes (or documented in CHANGELOG)
- [ ] Reviewed own code before requesting review

## Related Issues

Closes #123
Refs #456
```

### Review Process

1. **Automated Checks**: CI/CD runs tests, linters, RSR compliance
2. **Maintainer Review**: 1+ maintainer approval required
3. **Discussion**: Reviewers may request changes
4. **Iteration**: Address feedback, push new commits
5. **Approval**: Once approved, maintainer merges

**Review SLA**:
- Initial response: 48 hours
- Full review: 7 days
- Urgent fixes: 24 hours

### After Merge

- PR author: Delete feature branch
- Maintainer: Update CHANGELOG.md if not done
- Celebrate! 🎉

## Community

### Communication Channels

- **GitHub Discussions**: General questions, ideas, announcements
- **GitHub Issues**: Bug reports, feature requests
- **Email**: [CONTACT_EMAIL_TO_BE_ADDED] (for private matters)
- **Security**: [SECURITY_EMAIL_TO_BE_ADDED] (vulnerabilities only)

### Getting Help

- **First**: Check documentation (`docs/`, component READMEs)
- **Second**: Search GitHub Issues and Discussions
- **Third**: Open a GitHub Discussion (Q&A category)
- **Last Resort**: Email maintainers

### Asking Good Questions

Include:
- What you're trying to do
- What you've tried
- Error messages (full text, not screenshots)
- Environment (OS, language versions)
- Minimal reproducible example

## Recognition

Contributors will be acknowledged in:
- **MAINTAINERS.md** (for maintainers)
- **.well-known/humans.txt** (all contributors)
- **CHANGELOG.md** (for significant contributions)
- **GitHub Contributors** (automatic)

## Legal

By contributing, you agree:
- Your contributions are your original work or you have rights to contribute them
- You grant the project a license to use your contributions under MIT OR Palimpsest-0.8
- You've read and agree to the [Code of Conduct](CODE_OF_CONDUCT.md)

**Contributor Agreement**: First-time contributors will be asked to sign a simple CLA (coming soon).

---

**Questions?** Open a GitHub Discussion or email [CONTACT_EMAIL_TO_BE_ADDED]

Thank you for contributing to Anamnesis! 🙏
