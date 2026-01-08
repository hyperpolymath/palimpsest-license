# CLAUDE.md - Palimpsest License Project

## Project Overview

The **Palimpsest-MPL License (PMPL-1.0)** is a file-level copyleft license built on Mozilla Public License 2.0, extended with ethical use guidelines and quantum-safe provenance.

**Current Version:** PMPL-1.0 (based on MPL-2.0)

**Core Features:**
- File-level copyleft (MPL-2.0 foundation)
- Ethical use guidelines (Exhibit A)
- Quantum-safe provenance signatures (Exhibit B)
- Emotional lineage recognition
- AI training permitted with documentation

## Project Structure

```
palimpsest-license/
├── legal/                      # License texts
│   ├── PALIMPSEST-MPL-1.0.txt  # Main license
│   ├── MPL-2.0.txt             # Base license
│   ├── exhibits/               # Exhibit A & B
│   └── historical/             # v0.3, v0.4 archives
├── docs/                       # Documentation
│   ├── GUIDE.md                # User guide
│   ├── FAQ.md                  # FAQ
│   ├── INTEGRATION.md          # Integration guide
│   └── examples/               # Language examples
├── tools/                      # Rust CLI tools
│   ├── pmpl-sign/              # Signing tool
│   ├── pmpl-verify/            # Verification tool
│   ├── pmpl-audit/             # Compliance audit
│   └── integrations/           # CI/CD configs
├── spec/                       # Formal specifications
│   ├── PMPL-SPEC.adoc
│   ├── ETHICAL-USE-SPEC.adoc
│   └── QUANTUM-SAFE-SPEC.adoc
├── research/                   # Papers and presentations
│   ├── papers/
│   └── presentations/
├── .github/                    # CI/CD workflows
│
├── LICENSE                     # MPL-2.0 + Palimpsest
├── README.md                   # Project overview
├── CONTRIBUTING.adoc           # Contribution guidelines
├── GOVERNANCE.md               # Decision-making
├── CHANGELOG.adoc              # Version history
├── SECURITY.md                 # Security policy
└── Justfile                    # Build automation
```

## Key Principles

### 1. MPL-2.0 Foundation
Built on proven legal framework:
- File-level copyleft (not project-level)
- Compatible with proprietary code in separate files
- Patent grants included
- Well-understood licensing terms

### 2. Ethical Use Guidelines (Exhibit A)
Community norms for responsible use:
- Emotional lineage preservation
- Transparent attribution
- AI/ML training documentation
- Cultural sensitivity

### 3. Quantum-Safe Provenance (Exhibit B)
Future-proof attribution:
- Post-quantum cryptographic signatures (ML-DSA, SLH-DSA, FN-DSA)
- Provenance chains for contribution tracking
- NIST-approved algorithms

### 4. Governance
Managed by the **Palimpsest Stewardship Council** (7 members):
- 3 Creator Representatives
- 2 Legal Experts
- 1 Technologist
- 1 Cultural Heritage Advocate

## Development Guidelines

### Building Tools
```bash
# Build all tools
just build

# Run tests
just test

# Check compliance
just validate
```

### Adding SPDX Headers
All source files must include:
```
// SPDX-License-Identifier: PMPL-1.0
// SPDX-FileCopyrightText: YEAR Your Name
```

### Before Committing
1. Run `just fmt` to format code
2. Run `just check` to verify builds
3. Ensure SPDX headers present
4. Update CHANGELOG.adoc if needed

## Working with Components

### License Text (legal/)
- **Critical:** Legal precision is paramount
- Changes require Council review
- Always maintain versioned copies

### Documentation (docs/)
- User-facing, accessible language
- Practical examples included
- Keep current with license changes

### Tools (tools/)
- Rust CLI tools for compliance
- Must compile and pass tests
- Include SPDX headers

### Specifications (spec/)
- Formal specification documents
- AsciiDoc format
- Normative requirements

## Technology Stack

- **Primary Implementation:** Rust
- **Documentation:** Markdown, AsciiDoc
- **Build System:** Justfile
- **CI/CD:** GitHub Actions, GitLab CI

## Quick Reference

### Key Files
1. `legal/PALIMPSEST-MPL-1.0.txt` - License text
2. `docs/GUIDE.md` - User guide
3. `docs/FAQ.md` - Common questions
4. `GOVERNANCE.md` - Decision-making

### Common Tasks
- **Use license:** Copy LICENSE, add SPDX headers
- **Build tools:** `just build`
- **Run tests:** `just test`
- **Audit compliance:** `just audit`

## Mission

> "This is a license born not just from copyright, but from care. From narrative debt. From cultural refusal. From emotional fidelity."

The Palimpsest-MPL License protects creators' works while enabling open collaboration, with clear guidance for the age of AI.
