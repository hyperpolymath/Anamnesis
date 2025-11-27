# Security Policy

## Supported Versions

Anamnesis is currently in **pre-release development** (v0.1.0-alpha). Security updates will be provided for:

| Version | Supported          | Status |
| ------- | ------------------ | ------ |
| 0.1.x   | :white_check_mark: | Development |
| < 0.1   | :x:                | Not applicable |

**Note**: Production releases (1.0.0+) will have a formal security support policy with LTS versions.

## Security Model

Anamnesis follows a **defense-in-depth** approach across multiple dimensions:

### 1. Input Validation
- **Parser Layer (OCaml)**: Type-safe parsing with Angstrom combinators
- **Port Communication**: 4-byte length-prefixed framing prevents buffer overflows
- **Content Sanitization**: Escape special characters before RDF serialization
- **File Size Limits**: Configurable maximum conversation file sizes

### 2. Process Isolation
- **Erlang Ports**: Parser, reasoner, and analytics run in separate OS processes
- **Fault Tolerance**: Crashes isolated via OTP supervision trees
- **No Shared Memory**: Communication via message passing only
- **Resource Limits**: Per-process memory and CPU quotas

### 3. Type Safety
- **OCaml**: Strong static typing, no runtime type errors
- **Elixir**: Dialyzer typespecs, pattern matching exhaustiveness checks
- **ReScript**: Compile-time type guarantees, phantom types prevent ID mixing
- **Julia**: Optional type annotations, multiple dispatch safety

### 4. Memory Safety
- **No Unsafe Code**: Zero `unsafe` blocks in any component
- **Garbage Collection**: OCaml, Elixir, Julia use managed memory
- **No Manual Allocation**: No malloc/free, no buffer overruns
- **Ownership Model**: (Future: If Rust components added)

### 5. Injection Prevention
- **SPARQL Injection**: Parameterized queries, input sanitization
- **Command Injection**: No shell execution, ports use direct binary protocol
- **Path Traversal**: Validated file paths, no user-controlled path components
- **RDF Injection**: Escape literals, validate URIs

### 6. Access Control
- **TPCF Perimeter 2**: Trusted collaborators only (currently)
- **Read-only by Default**: Public can read, write requires approval
- **No Network Exposure**: Local-first, no public APIs in default configuration
- **Virtuoso ACLs**: Database-level access control (user configured)

### 7. Dependencies
- **Minimal Dependencies**: OCaml parser has zero external deps (100 lines)
- **Vendoring**: Critical dependencies vendored where feasible
- **SBOM**: Software Bill of Materials (planned)
- **Dependency Scanning**: Automated security advisories (planned)

### 8. Secrets Management
- **No Hardcoded Secrets**: All credentials via environment variables
- **No Secrets in Logs**: Redact sensitive data in telemetry
- **No Secrets in Git**: .gitignore for .env files
- **Virtuoso Credentials**: User-managed, not in repository

### 9. Data Privacy
- **Local-First**: All data stays on user's infrastructure by default
- **No Telemetry**: Zero external API calls unless user-configured
- **No Cloud Services**: No mandatory SaaS dependencies
- **Conversation Privacy**: Sensitive conversation content handled with care

### 10. Cryptography
- **No Custom Crypto**: Use proven libraries only (if needed)
- **HTTPS for SPARQL**: Recommend TLS for Virtuoso endpoints
- **Future**: GPG signing of releases, SBOM signatures

## Reporting a Vulnerability

**DO NOT** open a public GitHub issue for security vulnerabilities.

### Preferred Reporting Method

Email: **[SECURITY EMAIL TO BE ADDED]**

Include:
- Description of the vulnerability
- Steps to reproduce
- Affected versions
- Potential impact
- Suggested mitigation (if any)

### Response Timeline

- **Initial Response**: Within 48 hours
- **Severity Assessment**: Within 7 days
- **Fix Timeline**:
  - **Critical**: 7-14 days
  - **High**: 14-30 days
  - **Medium**: 30-60 days
  - **Low**: Next minor release

### Disclosure Policy

We follow **coordinated disclosure**:

1. You report the vulnerability privately
2. We confirm receipt and assess severity
3. We develop and test a fix
4. We release the fix and a security advisory
5. You may publicly disclose 90 days after our fix (or earlier with mutual agreement)

### Bug Bounty

**No formal bug bounty program** at this time (pre-release project). Acknowledgment in:
- SECURITY.md Hall of Fame
- Release notes for the fix
- Public security advisory

Post-1.0.0: We may establish a funded bug bounty program.

## Security Advisories

Published at:
- **GitHub**: https://github.com/Hyperpolymath/anamnesis/security/advisories
- **.well-known/security.txt**: RFC 9116 compliant

Subscribe to:
- **GitHub Watch** → Security alerts
- **RSS Feed**: [To be configured]

## Security Checklist for Users

### Before Deployment

- [ ] Review `docs/RSR_COMPLIANCE_AUDIT.md` for current security status
- [ ] Run `just security-scan` (dependency vulnerabilities)
- [ ] Configure Virtuoso with authentication enabled
- [ ] Use HTTPS for SPARQL endpoints
- [ ] Set up firewall rules (localhost-only by default)
- [ ] Review conversation files for sensitive content before ingestion
- [ ] Enable Elixir/OTP telemetry for anomaly detection
- [ ] Configure resource limits (ulimit, systemd, Docker)

### During Operation

- [ ] Monitor logs for suspicious activity
- [ ] Regularly update dependencies (`mix deps.update`, `opam update`, `juliaup update`)
- [ ] Review new security advisories
- [ ] Backup Virtuoso database (encrypted backups recommended)
- [ ] Test disaster recovery procedures

### Post-Incident

- [ ] Isolate affected systems
- [ ] Preserve logs for forensics
- [ ] Report to security@anamnesis (when established)
- [ ] Review and update security procedures

## Security Architecture Deep-Dive

See `docs/architecture/system-architecture.adoc` → Security Considerations section for:
- Threat model
- Attack surface analysis
- Security boundaries
- Mitigation strategies

## Compliance

### Current Status

- **OWASP Top 10**: Addressed in design (no web app yet, but prepared)
- **CWE/SANS Top 25**: Type safety prevents most memory corruption
- **GDPR**: Local-first design supports data sovereignty
- **HIPAA/PCI-DSS**: Not currently compliant (future if needed)

### Future Certifications

Post-1.0.0, we may pursue:
- SOC 2 Type II (if SaaS version offered)
- ISO 27001 (information security management)
- Common Criteria EAL4+ (for high-assurance deployments)

## Security Contacts

- **Primary**: [SECURITY EMAIL TO BE ADDED]
- **Secondary**: GitHub Security Advisories
- **GPG Key**: [TO BE ADDED]
- **Security.txt**: `.well-known/security.txt`

## Hall of Fame

Researchers who have responsibly disclosed vulnerabilities:

_(None yet - project in early development)_

---

**Last Updated**: 2025-11-22
**Next Review**: Q1 2026

For general questions, see CONTRIBUTING.md or open a public discussion.
