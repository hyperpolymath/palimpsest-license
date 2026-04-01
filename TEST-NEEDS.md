# TEST-NEEDS.md — palimpsest-license

> Generated 2026-03-29 by punishing audit.

## Current State

| Category     | Count | Notes |
|-------------|-------|-------|
| Unit tests   | 6     | Haskell Spec: BilingualSpec, LicenseSpec, MetadataSpec, ReferenceSpec, UtilsSpec + 1 Integration/PipelineSpec |
| Integration  | 1     | Integration/PipelineSpec.hs |
| E2E          | 0     | None |
| Benchmarks   | 0     | None |

**Source modules:** ~18 across multiple languages. Haskell validator: 8 modules (Main, Validator, Bilingual, License, Metadata, Reference, Types, Utils). Elixir: 5 Ecto modules (derivative, license, lineage, violation, work) in ARCHIVE. OCaml: 1 test. Rust: 6 files. PHP: 4 files.

## What's Missing

### P2P (Property-Based) Tests
- [ ] License validator: property tests for arbitrary license text classification
- [ ] Bilingual validator: property tests for language detection accuracy
- [ ] Metadata validator: arbitrary SPDX header validation
- [ ] Reference validator: property tests for citation format compliance

### E2E Tests
- [ ] Full validation pipeline: input file -> detect license -> validate -> report
- [ ] Multi-file: validate entire repository license compliance
- [ ] Cross-language: Haskell validator agrees with Rust validator agrees with OCaml validator

### Aspect Tests
- **Security:** No tests for malicious license text injection, path traversal in file scanning
- **Performance:** No validation throughput benchmarks
- **Concurrency:** No tests for parallel file scanning
- **Error handling:** No tests for binary files, empty files, files with mixed encodings

### Build & Execution
- [ ] `cabal test` or `stack test` for Haskell
- [ ] `cargo test` for Rust
- [ ] OCaml test execution

### Benchmarks Needed
- [ ] License detection speed per file
- [ ] Batch validation throughput (files/second)
- [ ] Bilingual detection accuracy and speed

### Self-Tests
- [ ] Validate its own LICENSE file
- [ ] Validate its own SPDX headers across all source files

## Priority

**MEDIUM.** The Haskell validator has 7 test files for 8 modules — actually decent coverage ratio. But the Rust, OCaml, PHP, and Elixir implementations have ZERO tests. The cross-language consistency is completely unverified. No benchmarks for a tool that needs to scan entire repositories quickly.

## FAKE-FUZZ ALERT

- `tests/fuzz/placeholder.txt` is a scorecard placeholder inherited from rsr-template-repo — it does NOT provide real fuzz testing
- Replace with an actual fuzz harness (see rsr-template-repo/tests/fuzz/README.adoc) or remove the file
- Priority: P2 — creates false impression of fuzz coverage
