# Palimpsest-MPL License

[![License: PMPL-1.0](https://img.shields.io/badge/License-PMPL--1.0-blue.svg)](legal/PALIMPSEST-MPL-1.0.txt)
[![License: MPL-2.0]()](https://www.mozilla.org/en-US/MPL/2.0/)

**File-level copyleft with ethical use and quantum-safe provenance**

## Quick Start

```bash
# Apply to your project
curl -O https://raw.githubusercontent.com/hyperpolymath/palimpsest-license/main/legal/PALIMPSEST-MPL-1.0.txt
mv PALIMPSEST-MPL-1.0.txt LICENSE
```

Add to your source files:
```
// SPDX-License-Identifier: PMPL-1.0
// SPDX-FileCopyrightText: 2025 Your Name
```

## Features

- **MPL-2.0 Foundation** - Proven, widely-compatible file-level copyleft
- **Ethical Use Guidelines** - Community norms for responsible use (Exhibit A)
- **Quantum-Safe Provenance** - Post-quantum signatures for long-term attribution (Exhibit B)
- **Emotional Lineage** - Recognition of cultural and narrative meaning in creative works
- **AI Training Permitted** - Clear guidance for machine learning use cases

## Documentation

| Document | Description |
|----------|-------------|
| [User Guide](docs/GUIDE.md) | How to use the license |
| [Integration Guide](docs/INTEGRATION.md) | CI/CD, package managers, tools |
| [FAQ](docs/FAQ.md) | Frequently asked questions |
| [Full License Text](legal/PALIMPSEST-MPL-1.0.txt) | The complete license |

## Tools

| Tool | Purpose |
|------|---------|
| `pmpl-sign` | Sign files with quantum-safe signatures |
| `pmpl-verify` | Verify provenance signatures |
| `pmpl-audit` | Audit repository for compliance |

Build tools:
```bash
cd tools/pmpl-sign && cargo build --release
cd tools/pmpl-verify && cargo build --release
cd tools/pmpl-audit && cargo build --release
```

## Project Structure

```
palimpsest-license/
├── legal/                    # License texts and exhibits
│   ├── PALIMPSEST-MPL-1.0.txt
│   ├── exhibits/
│   │   ├── EXHIBIT-A-ETHICAL-USE.txt
│   │   └── EXHIBIT-B-QUANTUM-SAFE.txt
│   └── historical/           # Previous versions
├── docs/                     # Documentation
├── tools/                    # Rust CLI tools and integrations
├── research/                 # Papers and presentations
├── spec/                     # Formal specifications
├── LICENSE                   # This repo's license (MPL-2.0 + Palimpsest)
└── Justfile                  # Build automation
```

## Compatibility

PMPL-1.0 is compatible with:
- MIT, BSD-2-Clause, BSD-3-Clause
- Apache-2.0
- MPL-2.0
- LGPL-2.1+, GPL-2.0+ (as secondary licenses)

## Governance

Maintained by the **Palimpsest Stewardship Council**:
- 3 Creator Representatives
- 2 Legal Experts
- 1 Technologist
- 1 Cultural Heritage Advocate

See [GOVERNANCE.md](GOVERNANCE.md) for decision-making process.

## Contributing

1. Read [CONTRIBUTING.adoc](CONTRIBUTING.adoc)
2. Submit issues for questions or proposals
3. Discuss in GitHub Discussions
4. Submit PRs for documentation or tool improvements

## License

This repository is licensed under [MPL-2.0](https://www.mozilla.org/en-US/MPL/2.0/) with the Palimpsest philosophy. Future versions will use PMPL-1.0 (self-hosting).

## Links

- **Repository**: https://github.com/hyperpolymath/palimpsest-license
- **Mirrors**: [GitLab](https://gitlab.com/hyperpolymath/palimpsest-license) | [Codeberg](https://codeberg.org/hyperpolymath/palimpsest-license)
- **Contact**: Issues on GitHub
