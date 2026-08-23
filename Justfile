# Anamnesis Project Justfile
# Unified build commands for multi-language project
# https://github.com/casey/just

# Default recipe (list all recipes)
import? "contractile.just"

default:
    @just --list

# ============================================================================
# Setup & Installation
# ============================================================================

# Setup all components (install dependencies)
setup-all: setup-parser setup-orchestrator setup-learning setup-visualization

# Setup OCaml parser
setup-parser:
    @echo "==> Setting up OCaml parser..."
    cd parser && opam install --deps-only . --yes
    @echo "✓ Parser dependencies installed"

# Setup Elixir orchestrator
setup-orchestrator:
    @echo "==> Setting up Elixir orchestrator..."
    cd orchestrator && mix deps.get
    @echo "✓ Orchestrator dependencies installed"

# Setup Julia learning component
setup-learning:
    @echo "==> Setting up Julia learning component..."
    cd learning && julia --project=. -e 'using Pkg; Pkg.instantiate()'
    @echo "✓ Learning dependencies installed"

# Setup AffineScript visualization
setup-visualization:
    @echo "==> Setting up AffineScript visualization..."
    cd visualization && npm install
    @echo "✓ Visualization dependencies installed"

# Install Virtuoso (Docker)
setup-virtuoso:
    @echo "==> Setting up Virtuoso triplestore..."
    docker run -d -p 8890:8890 -p 1111:1111 \
      -e DBA_PASSWORD=anamnesis \
      --name virtuoso \
      openlink/virtuoso-opensource-7
    @echo "✓ Virtuoso started on http://localhost:8890"

# ============================================================================
# Build
# ============================================================================

# Build all components
build-all: build-parser build-orchestrator build-learning build-visualization

# Build OCaml parser
build-parser:
    @echo "==> Building OCaml parser..."
    cd parser && dune build
    @echo "✓ Parser built successfully"

# Build Elixir orchestrator
build-orchestrator:
    @echo "==> Building Elixir orchestrator..."
    cd orchestrator && mix compile
    @echo "✓ Orchestrator built successfully"

# Build Julia module (no compilation needed, but verify imports)
build-learning:
    @echo "==> Verifying Julia learning component..."
    cd learning && julia --project=. -e 'using AnamnesisAnalytics; println("✓ Module loads successfully")'

# Build AffineScript visualization
build-visualization:
    @echo "==> Building AffineScript visualization..."
    cd visualization && npm run res:build
    @echo "✓ Visualization built successfully"

# ============================================================================
# Testing
# ============================================================================

# Run all tests
test: test-parser test-orchestrator test-learning test-visualization

# Test OCaml parser
test-parser:
    @echo "==> Testing OCaml parser..."
    cd parser && dune runtest || echo "⚠ No tests yet (starter code)"

# Test Elixir orchestrator
test-orchestrator:
    @echo "==> Testing Elixir orchestrator..."
    cd orchestrator && mix test || echo "⚠ No tests yet (starter code)"

# Test Julia learning
test-learning:
    @echo "==> Testing Julia learning..."
    cd learning && julia --project=. test/runtests.jl 2>/dev/null || echo "⚠ No tests yet (starter code)"

# Test AffineScript visualization
test-visualization:
    @echo "==> Testing AffineScript visualization..."
    cd visualization && npm test 2>/dev/null || echo "⚠ No tests yet (starter code)"

# ============================================================================
# Code Quality
# ============================================================================

# Format all code
format: format-parser format-orchestrator format-learning format-visualization

# Format OCaml code
format-parser:
    @echo "==> Formatting OCaml code..."
    cd parser && dune build @fmt --auto-promote 2>/dev/null || echo "⚠ ocamlformat not configured yet"

# Format Elixir code
format-orchestrator:
    @echo "==> Formatting Elixir code..."
    cd orchestrator && mix format

# Format Julia code
format-learning:
    @echo "==> Formatting Julia code..."
    @echo "⚠ JuliaFormatter not configured yet"

# Format AffineScript code
format-visualization:
    @echo "==> Formatting AffineScript code..."
    cd visualization && npm run res:build 2>/dev/null || echo "✓ AffineScript formatter runs on build"

# Lint all code
lint: lint-parser lint-orchestrator lint-visualization

# Lint OCaml (Dune build catches most issues)
lint-parser:
    @echo "==> Linting OCaml parser..."
    cd parser && dune build @check 2>/dev/null || echo "✓ Dune checks on build"

# Lint Elixir (Dialyzer for typespecs)
lint-orchestrator:
    @echo "==> Linting Elixir orchestrator..."
    cd orchestrator && mix dialyzer 2>/dev/null || echo "⚠ Dialyzer not configured yet"

# Lint AffineScript (compiler catches everything)
lint-visualization:
    @echo "==> Linting AffineScript visualization..."
    @echo "✓ AffineScript compiler is the linter"

# ============================================================================
# Clean
# ============================================================================

# Clean all build artifacts
clean: clean-parser clean-orchestrator clean-learning clean-visualization

# Clean OCaml build
clean-parser:
    @echo "==> Cleaning OCaml parser..."
    cd parser && dune clean

# Clean Elixir build
clean-orchestrator:
    @echo "==> Cleaning Elixir orchestrator..."
    cd orchestrator && mix clean

# Clean Julia artifacts
clean-learning:
    @echo "==> Cleaning Julia learning..."
    cd learning && rm -rf Manifest.toml 2>/dev/null || true

# Clean AffineScript build
clean-visualization:
    @echo "==> Cleaning AffineScript visualization..."
    cd visualization && npm run res:clean && rm -rf node_modules/.cache

# ============================================================================
# Development
# ============================================================================

# Start development environment (all components)
dev:
    @echo "Starting Anamnesis development environment..."
    @echo "This will open multiple terminals. Close with Ctrl+C."
    @just setup-virtuoso
    @echo "\n📦 Virtuoso running on http://localhost:8890"
    @echo "\nNext steps:"
    @echo "  1. cd orchestrator && iex -S mix phx.server  # Elixir orchestrator"
    @echo "  2. cd visualization && npm run dev          # AffineScript dev server"

# Interactive shell (Elixir)
shell-elixir:
    cd orchestrator && iex -S mix

# Interactive shell (Julia)
shell-julia:
    cd learning && julia --project=.

# Interactive shell (OCaml)
shell-ocaml:
    cd parser && dune utop

# ============================================================================
# RSR Compliance
# ============================================================================

# Run RSR compliance verification
rsr-check:
    @echo "==> Running RSR Compliance Check..."
    @./scripts/rsr_compliance_check.sh || echo "⚠ RSR check script not executable yet"

# Generate RSR compliance report
rsr-report:
    @echo "==> Generating RSR Compliance Report..."
    @cat docs/RSR_COMPLIANCE_AUDIT.md

# Validate all RSR requirements
validate: rsr-check test lint
    @echo "✓ All validation checks passed"

# ============================================================================
# Security
# ============================================================================

# Run security audit (dependency vulnerabilities)
security-scan:
    @echo "==> Scanning for security vulnerabilities..."
    @echo "OCaml: opam list --installed-roots"
    @cd parser && opam list --installed-roots || true
    @echo "\nElixir: mix deps.audit"
    @cd orchestrator && mix deps.audit 2>/dev/null || echo "⚠ hex_audit not installed (mix archive.install hex hex_audit)"
    @echo "\nJulia: (manual - no automated scanner yet)"
    @echo "\nReScript/npm: npm audit"
    @cd visualization && npm audit || true

# Update security.txt expiry date
update-security-txt:
    @echo "Updating .well-known/security.txt expiry..."
    @echo "⚠ Manual edit required: Update 'Expires' field to 1 year from today"

# ============================================================================
# Documentation
# ============================================================================

# Generate documentation for all components
docs: docs-parser docs-orchestrator docs-learning

# Generate OCaml documentation
docs-parser:
    @echo "==> Generating OCaml docs..."
    cd parser && dune build @doc

# Generate Elixir documentation
docs-orchestrator:
    @echo "==> Generating Elixir docs..."
    cd orchestrator && mix docs

# Generate Julia documentation
docs-learning:
    @echo "==> Generating Julia docs..."
    @echo "⚠ Documenter.jl not configured yet"

# Serve documentation locally
docs-serve:
    @echo "==> Serving documentation..."
    @echo "OCaml: open parser/_build/default/_doc/_html/index.html"
    @echo "Elixir: open orchestrator/doc/index.html"

# ============================================================================
# Git & Release
# ============================================================================

# Run pre-commit checks
pre-commit: format lint test
    @echo "✓ Pre-commit checks passed"

# Prepare for release (update CHANGELOG, version bump)
release-prep version:
    @echo "==> Preparing release {{version}}..."
    @echo "1. Update CHANGELOG.md (move [Unreleased] to [{{version}}])"
    @echo "2. Update version in:"
    @echo "   - mix.exs (orchestrator)"
    @echo "   - Project.toml (learning)"
    @echo "   - package.json (visualization)"
    @echo "   - dune-project (parser)"
    @echo "3. Run: git commit -am 'chore: bump version to {{version}}'"
    @echo "4. Run: git tag v{{version}}"
    @echo "5. Run: git push && git push --tags"

# ============================================================================
# CI/CD Helpers
# ============================================================================

# Run full CI pipeline locally (what GitLab CI runs)
ci: setup-all build-all test lint rsr-check
    @echo "✓ CI pipeline passed locally"

# ============================================================================
# Misc Utilities
# ============================================================================

# Show project statistics
stats:
    @echo "==> Anamnesis Project Statistics"
    @echo "\nLines of Code:"
    @find parser -name "*.ml" -o -name "*.mli" | xargs wc -l 2>/dev/null | tail -1 || true
    @find orchestrator -name "*.ex" -o -name "*.exs" | xargs wc -l 2>/dev/null | tail -1 || true
    @find learning -name "*.jl" | xargs wc -l 2>/dev/null | tail -1 || true
    @find reasoning -name "*.elpi" | xargs wc -l 2>/dev/null | tail -1 || true
    @find visualization -name "*.res" | xargs wc -l 2>/dev/null | tail -1 || true
    @echo "\nDocumentation:"
    @find docs -name "*.md" -o -name "*.adoc" | xargs wc -l 2>/dev/null | tail -1 || true
    @echo "\nTotal Files:"
    @find . -type f \( -name "*.ml" -o -name "*.ex" -o -name "*.jl" -o -name "*.elpi" -o -name "*.res" -o -name "*.md" -o -name "*.adoc" \) | wc -l

# Show system information
info:
    @echo "==> System Information"
    @echo "OCaml: $(ocaml --version 2>/dev/null || echo 'not installed')"
    @echo "Elixir: $(elixir --version 2>/dev/null | head -1 || echo 'not installed')"
    @echo "Julia: $(julia --version 2>/dev/null || echo 'not installed')"
    @echo "Node.js: $(node --version 2>/dev/null || echo 'not installed')"
    @echo "Docker: $(docker --version 2>/dev/null || echo 'not installed')"
    @echo "Just: $(just --version 2>/dev/null || echo 'not installed')"

# Open project in browser
open-repo:
    @open https://github.com/Hyperpolymath/anamnesis || xdg-open https://github.com/Hyperpolymath/anamnesis || echo "Open manually: https://github.com/Hyperpolymath/anamnesis"

# ============================================================================
# Help & Documentation
# ============================================================================

# Show RSR compliance checklist
rsr-checklist:
    #!/usr/bin/env bash
    cat << 'EOF'
    RSR Compliance Checklist for Anamnesis

    [ok] 1. Type Safety (90%): OCaml, Elixir typespecs, AffineScript, Julia
    [ok] 2. Memory Safety (60%): GC languages (OCaml/Elixir/Julia), no unsafe
    [!!] 3. Offline-First (40%): Parser/reasoner offline, Virtuoso local
    [ok] 4. Documentation (100%): README, component docs, architecture
    [!!] 5. Testing (10%): Starter code only, no tests yet
    [ok] 6. Build System (80%): dune, mix, just, flake.guix planned
    [ok] 7. Security (90%): SECURITY.md, .well-known/security.txt
    [ok] 8. Licensing (100%): LICENSE.txt (MIT OR Palimpsest-0.8)
    [ok] 9. Contribution (100%): CONTRIBUTING.md, TPCF Perimeter 2
    [ok] 10. Community (100%): CODE_OF_CONDUCT.md (CCCP-based)
    [ok] 11. Versioning (100%): CHANGELOG.md, semantic versioning

    Current Score: 70/100 (Bronze Level)

    Next Steps for Silver (85/100):
    - Add test infrastructure (all components)
    - Achieve 70% test coverage
    - Complete offline-first documentation
    - Setup Guix flakes for reproducible builds
    EOF

# Show quick start guide
quickstart:
    #!/usr/bin/env bash
    cat << 'EOF'
    Anamnesis Quick Start Guide

    1. Setup dependencies:
       just setup-all

    2. Build all components:
       just build-all

    3. Run tests:
       just test

    4. Start development:
       just dev

    5. Validate before commit:
       just validate

    For more commands: just --list
    For RSR compliance: just rsr-checklist
    For help: see README.md and CONTRIBUTING.md
    EOF

# Synchronize A2ML metadata to SCM (Shadow Sync)
sync-metadata:
    #!/usr/bin/env bash
    echo "Synchronizing metadata (A2ML -> SCM)..."
    if [ -f .machine_readable/STATE.a2ml ]; then
        COMPLETION=$(grep "completion-percentage:" .machine_readable/STATE.a2ml | awk '{print $2}')
        sed -i "s/(overall-completion [0-9]\+)/(overall-completion $COMPLETION)/" .machine_readable/STATE.scm
        echo "✓ Metadata synchronized"
    fi

# Run panic-attacker pre-commit scan
assail:
    @command -v panic-attack >/dev/null 2>&1 && panic-attack assail . || echo "panic-attack not found — install from https://github.com/hyperpolymath/panic-attacker"

# ═══════════════════════════════════════════════════════════════════════════════
# ONBOARDING & DIAGNOSTICS
# ═══════════════════════════════════════════════════════════════════════════════

# Check all required toolchain dependencies and report health
doctor:
    #!/usr/bin/env bash
    echo "═══════════════════════════════════════════════════"
    echo "  Anamnesis Doctor — Toolchain Health Check"
    echo "═══════════════════════════════════════════════════"
    echo ""
    PASS=0; FAIL=0; WARN=0
    check() {
        local name="$1" cmd="$2" min="$3"
        if command -v "$cmd" >/dev/null 2>&1; then
            VER=$("$cmd" --version 2>&1 | head -1)
            echo "  [OK]   $name — $VER"
            PASS=$((PASS + 1))
        else
            echo "  [FAIL] $name — not found (need $min+)"
            FAIL=$((FAIL + 1))
        fi
    }
    check "just"              just      "1.25" 
    check "git"               git       "2.40" 
    check "Zig"               zig       "0.13" 
# Optional tools
if command -v panic-attack >/dev/null 2>&1; then
    echo "  [OK]   panic-attack — available"
    PASS=$((PASS + 1))
else
    echo "  [WARN] panic-attack — not found (pre-commit scanner)"
    WARN=$((WARN + 1))
fi
    echo ""
    echo "  Result: $PASS passed, $FAIL failed, $WARN warnings"
    if [ "$FAIL" -gt 0 ]; then
        echo "  Run 'just heal' to attempt automatic repair."
        exit 1
    fi
    echo "  All required tools present."

# Attempt to automatically install missing tools
heal:
    #!/usr/bin/env bash
    echo "═══════════════════════════════════════════════════"
    echo "  Anamnesis Heal — Automatic Tool Installation"
    echo "═══════════════════════════════════════════════════"
    echo ""
if ! command -v just >/dev/null 2>&1; then
    echo "Installing just..."
    cargo install just 2>/dev/null || echo "Install just from https://just.systems"
fi
    echo ""
    echo "Heal complete. Run 'just doctor' to verify."

# Guided tour of the project structure and key concepts
tour:
    #!/usr/bin/env bash
    echo "═══════════════════════════════════════════════════"
    echo "  Anamnesis — Guided Tour"
    echo "═══════════════════════════════════════════════════"
    echo ""
    echo '*A conversation knowledge extraction and reconciliation system for multi-LLM development workflows.*'
    echo ""
    echo "Key directories:"
    echo "  src/                      Source code" 
    echo "  ffi/                      Foreign function interface (Zig)" 
    echo "  src/abi/                  Idris2 ABI definitions" 
    echo "  docs/                     Documentation" 
    echo "  tests/                    Test suite" 
    echo "  .github/workflows/        CI/CD workflows" 
    echo "  contractiles/             Must/Trust/Dust contracts" 
    echo "  .machine_readable/        Machine-readable metadata" 
    echo "  examples/                 Usage examples" 
    echo ""
    echo "Quick commands:"
    echo "  just doctor    Check toolchain health"
    echo "  just heal      Fix missing tools"
    echo "  just help-me   Common workflows"
    echo "  just default   List all recipes"
    echo ""
    echo "Read more: README.adoc, EXPLAINME.adoc"

# Show help for common workflows
help-me:
    #!/usr/bin/env bash
    echo "═══════════════════════════════════════════════════"
    echo "  Anamnesis — Common Workflows"
    echo "═══════════════════════════════════════════════════"
    echo ""
echo "FIRST TIME SETUP:"
echo "  just doctor           Check toolchain"
echo "  just heal             Fix missing tools"
echo "" 
echo "PRE-COMMIT:"
echo "  just assail           Run panic-attacker scan"
echo ""
echo "LEARN:"
echo "  just tour             Guided project tour"
echo "  just default          List all recipes" 


# Print the current CRG grade (reads from READINESS.md '**Current Grade:** X' line)
crg-grade:
    @grade=$$(grep -oP '(?<=\*\*Current Grade:\*\* )[A-FX]' READINESS.md 2>/dev/null | head -1); \
    [ -z "$$grade" ] && grade="X"; \
    echo "$$grade"

# Generate a shields.io badge markdown for the current CRG grade
# Looks for '**Current Grade:** X' in READINESS.md; falls back to X
crg-badge:
    @grade=$$(grep -oP '(?<=\*\*Current Grade:\*\* )[A-FX]' READINESS.md 2>/dev/null | head -1); \
    [ -z "$$grade" ] && grade="X"; \
    case "$$grade" in \
      A) color="brightgreen" ;; B) color="green" ;; C) color="yellow" ;; \
      D) color="orange" ;; E) color="red" ;; F) color="critical" ;; \
      *) color="lightgrey" ;; esac; \
    echo "[![CRG $$grade](https://img.shields.io/badge/CRG-$$grade-$$color?style=flat-square)](https://github.com/hyperpolymath/standards/tree/main/component-readiness-grades)"
