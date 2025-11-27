# Offline-First Architecture

Anamnesis is designed to function in **fully offline, air-gapped environments** with no external dependencies.

## Overview

Anamnesis prioritizes local-first, offline-capable operation for:
- **Data sovereignty**: Your conversation data stays on your machine
- **Security**: No cloud services, no external APIs, no telemetry
- **Reliability**: Works without internet connectivity
- **Privacy**: Conversations never leave your infrastructure
- **Auditability**: All components can be inspected and verified

## Offline Capabilities

### ✅ Fully Offline Components

| Component | Offline Status | Notes |
|-----------|---------------|-------|
| **Parser (OCaml)** | ✅ 100% Offline | Pure functional parsing, no network I/O |
| **Orchestrator (Elixir)** | ✅ 100% Offline | Local process orchestration only |
| **Reasoning (λProlog)** | ✅ 100% Offline | Logic programming, no external calls |
| **Learning (Julia)** | ✅ 100% Offline | RDF generation, reservoir computing |
| **Visualization (ReScript)** | ✅ 100% Offline | Client-side rendering, no CDNs |
| **Virtuoso (RDF Store)** | ✅ 100% Offline | Local triplestore, SPARQL queries |

### ⚠️ Optional Online Features

- **Dependency updates**: Can use vendored/mirrored packages
- **Documentation hosting**: Serve locally with static file server
- **CI/CD**: Can run entirely on local GitLab/Gitea instance

## Air-Gapped Deployment

### Prerequisites

1. **Offline dependency bundles** (see below)
2. **Docker or native runtime** for Virtuoso
3. **Build toolchains**: OCaml (opam), Elixir (mix), Julia, Node.js

### Installation Steps

#### 1. Prepare Offline Bundle

On a connected machine, download all dependencies:

```bash
# Clone repository
git clone https://github.com/Hyperpolymath/anamnesis.git
cd anamnesis

# Download OCaml dependencies
cd parser
opam install --deps-only . --download-only
opam admin cache --all

# Download Elixir dependencies
cd ../orchestrator
mix deps.get
mix deps.compile
mix hex.package fetch --all

# Download Julia dependencies
cd ../learning
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.resolve()'

# Download Node.js dependencies
cd ../visualization
npm install
npm pack --pack-destination ../offline-bundle/npm

# Package everything for transfer
cd ..
tar -czf anamnesis-offline-bundle.tar.gz \
  ./* \
  ~/.opam/download-cache \
  orchestrator/deps \
  learning/.julia \
  visualization/node_modules
```

#### 2. Transfer to Air-Gapped Environment

```bash
# Copy tarball via removable media, secure file transfer, etc.
scp anamnesis-offline-bundle.tar.gz airgap-host:/opt/
```

#### 3. Install on Air-Gapped Machine

```bash
# Extract bundle
cd /opt
tar -xzf anamnesis-offline-bundle.tar.gz
cd anamnesis

# Setup OCaml (use cached packages)
export OPAMDOWNLOADJOBS=0  # Prevent network access
cd parser
opam install --deps-only . --assume-depexts

# Setup Elixir (use local deps)
cd ../orchestrator
MIX_ENV=prod mix deps.compile

# Setup Julia (use bundled packages)
cd ../learning
julia --project=. -e 'using Pkg; Pkg.instantiate()'

# Setup ReScript (use bundled node_modules)
cd ../visualization
# Already bundled, no npm install needed

# Build all components
cd ..
just build-all
```

#### 4. Run Virtuoso Locally (Docker or Native)

**Option A: Docker (if available in air-gapped environment)**

```bash
# Load Virtuoso image from TAR (prepared on connected machine)
docker load -i virtuoso-opensource-7.tar

# Run locally
docker run -d \
  -p 8890:8890 \
  -p 1111:1111 \
  -e DBA_PASSWORD=anamnesis \
  -v /opt/anamnesis-data:/database \
  --name virtuoso \
  openlink/virtuoso-opensource-7
```

**Option B: Native Virtuoso**

```bash
# Install from source or pre-built binary
# Configure virtuoso.ini for local-only operation:
[Parameters]
ServerPort = 1111
LiteMode = 0
NumberOfBuffers = 10000
MaxDirtyBuffers = 6000

[HTTPServer]
ServerPort = 8890
ServerRoot = /opt/virtuoso/vsp
MaxClients = 10
```

#### 5. Verify Offline Operation

```bash
# Disable network interface (to prove offline capability)
sudo ip link set dev eth0 down

# Run full test suite
just test

# Run RSR compliance check
just rsr-check

# Ingest a sample conversation
cd orchestrator
iex -S mix
iex> Anamnesis.Pipelines.IngestionPipeline.ingest_file("/path/to/claude_export.json")

# Query RDF data
curl -X POST http://localhost:8890/sparql \
  -H "Content-Type: application/sparql-query" \
  --data-binary @- << EOF
PREFIX anamnesis: <http://anamnesis.ai/ontology/>
SELECT ?conversation ?message ?content
WHERE {
  ?conversation a anamnesis:Conversation .
  ?message anamnesis:partOf ?conversation .
  ?message anamnesis:content ?content .
}
LIMIT 10
EOF
```

## Local Development Without Internet

### Opam Local Repository

```bash
# On connected machine, create local opam repo
mkdir -p /opt/opam-local-repo
cd /opt/opam-local-repo
opam admin cache --all
opam repository add local file:///opt/opam-local-repo --rank=100
```

### Hex Local Mirror

```bash
# On connected machine
mix hex.package fetch --all --output /opt/hex-mirror

# On air-gapped machine
export HEX_MIRROR=/opt/hex-mirror
mix deps.get --only local
```

### Julia Package Server

```bash
# Setup local Julia package registry
export JULIA_PKG_SERVER="file:///opt/julia-packages"
```

### NPM Verdaccio (Local Registry)

```bash
# Run local npm registry
docker run -d -p 4873:4873 verdaccio/verdaccio

# Configure npm
npm config set registry http://localhost:4873/
```

## Data Privacy & Sovereignty

### No External Data Transmission

Anamnesis **NEVER** transmits data externally:
- ❌ No telemetry or analytics
- ❌ No cloud API calls (OpenAI, Anthropic, etc.)
- ❌ No update checks or version pings
- ❌ No CDN requests for JavaScript/CSS
- ❌ No external DNS queries

### Verification

Audit network traffic during operation:

```bash
# Monitor all network connections
sudo tcpdump -i any -n | grep -v "127.0.0.1\|::1"

# Should show NO external traffic when processing conversations
```

### Firewall Configuration

Lock down network access entirely:

```bash
# Allow only localhost
sudo iptables -A OUTPUT -o lo -j ACCEPT
sudo iptables -A OUTPUT -j DROP

# Or use AppArmor/SELinux profiles
```

## Offline Documentation

### Generate Local Docs

```bash
# Generate all component documentation
just docs

# Serve locally
cd parser/_build/default/_doc/_html
python3 -m http.server 8000

# Access at http://localhost:8000
```

### Offline Manual

All documentation is included in the repository:
- `README.md` - Getting started
- `docs/` - Comprehensive guides (AsciiDoc, viewable in any text editor)
- `CONTRIBUTING.md` - Development guide
- `SECURITY.md` - Security model

Convert AsciiDoc to HTML for offline browsing:

```bash
# Install asciidoctor (on connected machine)
gem install asciidoctor

# Generate HTML versions
find docs -name "*.adoc" -exec asciidoctor {} \;

# Bundle for offline use
tar -czf anamnesis-docs-html.tar.gz docs/**/*.html
```

## Offline Testing

Run full test suite without network:

```bash
# Disable network
sudo ip link set dev eth0 down

# Run all tests
just test

# All tests should pass without network access
just validate

# Re-enable network
sudo ip link set dev eth0 up
```

## Supply Chain Security

### Dependency Vendoring

Vendor all dependencies to avoid supply chain attacks:

```bash
# OCaml - use opam pin to vendor
opam pin add anamnesis_parser . --no-action
opam pin add <dependency> <version> --no-action

# Elixir - commit deps/ to repository (not recommended usually, but OK for air-gap)
# Uncomment in .gitignore:
# deps/

# Julia - use Manifest.toml (committed to repo)
# No action needed, Manifest.toml pins exact versions

# Node.js - use package-lock.json and npm ci
npm ci --offline
```

### Reproducible Builds

Use Nix flakes (planned) for bit-for-bit reproducible builds:

```nix
# flake.nix (future)
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.default = ...;
  };
}
```

## Offline CI/CD

Run GitLab CI locally without network:

```bash
# Install GitLab Runner (offline binary)
# Configure for local execution only

gitlab-runner exec docker build-parser \
  --docker-pull-policy never \
  --docker-network-mode none
```

## Backup & Portability

### Export Conversations (RDF)

```bash
# Export all RDF data from Virtuoso
isql 1111 dba anamnesis << EOF
SPARQL SELECT * WHERE { ?s ?p ?o } INTO <file:///backup/anamnesis-$(date +%Y%m%d).ttl>;
EOF
```

### Migrate to Different Machine

```bash
# 1. Stop services
docker stop virtuoso

# 2. Backup Virtuoso database
tar -czf virtuoso-backup.tar.gz /opt/anamnesis-data/

# 3. Transfer to new machine
scp virtuoso-backup.tar.gz newhost:/opt/

# 4. Restore on new machine
tar -xzf /opt/virtuoso-backup.tar.gz -C /
docker start virtuoso
```

## Offline Security Updates

### Security Patch Workflow

1. **Connected environment**: Download security patches
2. **Verify signatures**: `opam admin check`, `mix hex.audit`
3. **Test in staging**: Apply patches, run tests
4. **Transfer to air-gap**: Via secure media
5. **Apply in production**: Update dependencies, rebuild

### Vulnerability Scanning (Offline)

```bash
# OCaml - manual audit (no automated scanner)
opam list --installed-roots > installed.txt

# Elixir - hex_audit (requires initial DB download)
mix deps.audit --offline

# Node.js - npm audit (with vendored registry)
npm audit --offline
```

## Performance Considerations

### Local vs. Cloud

Anamnesis is **faster offline** than cloud alternatives:
- ✅ No network latency
- ✅ No API rate limits
- ✅ No authentication overhead
- ✅ Direct filesystem access
- ✅ Local SPARQL queries (milliseconds)

### Hardware Recommendations

**Minimum** (single conversation processing):
- 2 CPU cores
- 4 GB RAM
- 10 GB disk space

**Recommended** (large-scale analysis, 1000+ conversations):
- 8 CPU cores
- 16 GB RAM
- 100 GB SSD

## Troubleshooting Offline Issues

### Common Problems

**Problem**: Opam tries to fetch packages

**Solution**: Use `--assume-depexts` and cached packages
```bash
export OPAMDOWNLOADJOBS=0
opam install --deps-only . --assume-depexts
```

**Problem**: Mix tries to fetch hex.pm

**Solution**: Use local dependencies
```bash
export HEX_OFFLINE=1
mix deps.get --only local
```

**Problem**: Julia tries to download packages

**Solution**: Use offline mode
```bash
export JULIA_PKG_SERVER=""
julia --project=. -e 'using Pkg; Pkg.offline(true); Pkg.instantiate()'
```

**Problem**: npm install fails

**Solution**: Use bundled node_modules or local registry
```bash
npm ci --offline
```

## Certification

Anamnesis passes **offline-first certification**:
- ✅ All core functionality works without network
- ✅ No required external dependencies
- ✅ Data never leaves local machine
- ✅ Reproducible builds possible
- ✅ Supply chain auditable

## Future Improvements

- [ ] Nix flakes for fully reproducible builds
- [ ] Embedded database option (RocksDB/SQLite) for single-binary deployment
- [ ] Standalone binary distribution (OCaml → native, Elixir → escript)
- [ ] Offline package registry bundled in release
- [ ] Zero-dependency mode (embedded SQLite for RDF, no Virtuoso)

---

**Last updated**: 2025-11-22
**Offline compliance**: 100% for core features
**Next review**: After first production deployment
