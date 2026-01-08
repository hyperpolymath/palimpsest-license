# Palimpsest-MPL User Guide

## Overview

The Palimpsest-MPL License (PMPL-1.0) is a file-level copyleft license built on Mozilla Public License 2.0, extended with ethical use requirements and quantum-safe provenance.

## Quick Start

### For New Projects

1. Copy the license file to your project root:

```bash
curl -O https://raw.githubusercontent.com/hyperpolymath/palimpsest-license/main/legal/PALIMPSEST-MPL-1.0.txt
mv PALIMPSEST-MPL-1.0.txt LICENSE
```

2. Add the header to your source files:

```
// SPDX-License-Identifier: PMPL-1.0
// SPDX-FileCopyrightText: [Year] [Your Name/Organization]
```

3. Create a NOTICE file acknowledging the license:

```
This project is licensed under Palimpsest-MPL-1.0.
See LICENSE for full text.
See https://github.com/hyperpolymath/palimpsest-license for license details.
```

### For Existing Projects

If you're relicensing an existing project:

1. Ensure all contributors agree to the license change
2. Update all file headers
3. Document the license change in your CHANGELOG
4. Update any SPDX metadata

## License Components

### Base License (MPL-2.0)

The Palimpsest-MPL inherits all terms from MPL-2.0:

- **File-level copyleft**: Modified files must remain under PMPL-1.0
- **Larger works**: Can be combined with proprietary code in separate files
- **Patent grants**: Contributors grant patent rights for their contributions
- **Notice requirements**: Must preserve copyright notices and license references

### Exhibit A: Ethical Use

The ethical use exhibit adds voluntary guidelines for:

- Respecting emotional lineage and cultural context
- Transparent attribution beyond legal minimums
- Responsible use with AI/ML systems
- Cultural sensitivity in derivative works

These are primarily community norms, not legal mandates.

### Exhibit B: Quantum-Safe Provenance

Optional cryptographic provenance using post-quantum algorithms:

- Sign contributions with ML-DSA, SLH-DSA, or FN-DSA
- Maintain provenance chains for attribution
- Future-proof against quantum computing threats

## Common Use Cases

### Using PMPL-Licensed Code

You may:
- Use the software for any purpose
- Modify the software
- Distribute the software
- Combine with other licensed code

You must:
- Preserve copyright notices
- Include the license text
- Share modifications to PMPL-licensed files under PMPL
- Preserve provenance metadata where present

### Creating Derivative Works

When modifying PMPL-licensed files:

1. Keep the SPDX header updated with your copyright
2. Document your changes
3. If provenance signatures exist, extend the chain
4. Consider the emotional lineage guidance when making significant changes

### AI/ML Training Use

The license permits AI training use with these expectations:

1. Document training use in model cards
2. Do not claim AI outputs carry original work's authority
3. Preserve attribution information through your pipeline
4. Consider opt-out mechanisms for creators who request them

## Compliance Checklist

### Minimum Requirements

- [ ] LICENSE file present with full PMPL-1.0 text
- [ ] SPDX headers on source files
- [ ] Copyright notices preserved
- [ ] License terms not removed or altered

### Best Practices

- [ ] NOTICE file with attribution details
- [ ] Provenance signatures on contributions
- [ ] CONTRIBUTORS file listing all contributors
- [ ] Meaningful commit messages for audit trail

### For Organizations

- [ ] Legal review of license compatibility
- [ ] Developer training on license requirements
- [ ] Automated SPDX header verification in CI
- [ ] Provenance verification in release pipeline

## Compatibility

### Compatible Licenses

PMPL-1.0 can be combined with:
- MIT
- BSD (2-clause, 3-clause)
- Apache 2.0
- MPL-2.0
- LGPL 2.1+ (as secondary license)
- GPL 2.0+ (as secondary license)

### Incompatible Licenses

Cannot be directly combined with:
- Proprietary licenses (in same files)
- Licenses prohibiting additional terms

When in doubt, consult the license compatibility matrix or seek legal advice.

## Tools

### pmpl-sign

Sign files with quantum-safe signatures:

```bash
pmpl-sign --key ~/.pmpl/key.pem source.rs
```

### pmpl-verify

Verify provenance signatures:

```bash
pmpl-verify source.rs
```

### pmpl-audit

Audit a repository for PMPL compliance:

```bash
pmpl-audit /path/to/repo
```

## FAQ

See [FAQ.md](FAQ.md) for frequently asked questions.

## Getting Help

- **Repository**: https://github.com/hyperpolymath/palimpsest-license
- **Issues**: File issues for questions or problems
- **Discussions**: Join community discussions for broader topics

## Version History

- **PMPL-1.0** (2025): Initial release based on MPL-2.0
- **v0.4** (2024): Pre-release development version
- **v0.3** (2024): Early conceptual framework

See [CHANGELOG](../CHANGELOG.adoc) for detailed history.
