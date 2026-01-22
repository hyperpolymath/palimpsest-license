# SPDX-License-Identifier: PMPL-1.0
# SPDX-FileCopyrightText: 2025 Palimpsest Stewardship Council
#
# Palimpsest-MPL License - Justfile
# Build automation for the Palimpsest-MPL project

# Default recipe (shows help)
default:
    @just --list

# ============================================================================
# BUILD
# ============================================================================

# Build all Rust tools
build:
    @echo "Building PMPL tools..."
    cd tools/pmpl-sign && cargo build --release
    cd tools/pmpl-verify && cargo build --release
    cd tools/pmpl-audit && cargo build --release
    @echo "Build complete. Binaries in tools/*/target/release/"

# Build in debug mode (faster compilation)
build-debug:
    cd tools/pmpl-sign && cargo build
    cd tools/pmpl-verify && cargo build
    cd tools/pmpl-audit && cargo build

# Install tools to ~/.cargo/bin
install:
    cargo install --path tools/pmpl-sign
    cargo install --path tools/pmpl-verify
    cargo install --path tools/pmpl-audit

# ============================================================================
# TEST
# ============================================================================

# Run all tests
test:
    @echo "Running tests..."
    cd tools/pmpl-sign && cargo test
    cd tools/pmpl-verify && cargo test
    cd tools/pmpl-audit && cargo test
    @echo "All tests passed!"

# Run tests with verbose output
test-verbose:
    cd tools/pmpl-sign && cargo test -- --nocapture
    cd tools/pmpl-verify && cargo test -- --nocapture
    cd tools/pmpl-audit && cargo test -- --nocapture

# ============================================================================
# VALIDATION
# ============================================================================

# Run full compliance check on this repository
validate:
    @echo "Running PMPL compliance check..."
    @test -f LICENSE || (echo "Missing LICENSE file" && exit 1)
    @test -f legal/PALIMPSEST-MPL-1.0.txt || (echo "Missing PMPL-1.0 license" && exit 1)
    @echo "Checking SPDX headers..."
    @find tools -name "*.rs" -exec grep -L "SPDX-License-Identifier" {} \; | \
        (read line && echo "Missing SPDX header: $$line" && exit 1) || true
    @echo "Validation passed!"

# Lint markdown files
lint:
    @echo "Linting markdown..."
    @if command -v prettier &> /dev/null; then \
        prettier --check "**/*.md"; \
    else \
        echo "prettier not found, skipping lint"; \
    fi

# Format all files
format:
    @if command -v prettier &> /dev/null; then \
        prettier --write "**/*.md" "**/*.json" "**/*.yml" "**/*.yaml"; \
    else \
        echo "prettier not found, skipping format"; \
    fi

# ============================================================================
# DOCUMENTATION
# ============================================================================

# Generate HTML from AsciiDoc specs
docs:
    @echo "Generating documentation..."
    @if command -v asciidoctor &> /dev/null; then \
        asciidoctor -b html5 -D docs/html spec/*.adoc; \
    else \
        echo "asciidoctor not found, skipping doc generation"; \
    fi

# ============================================================================
# SIGNING & PROVENANCE
# ============================================================================

# Sign all source files in a directory
sign DIR:
    @echo "Signing files in {{DIR}}..."
    find {{DIR}} -name "*.rs" -exec ./tools/pmpl-sign/target/release/pmpl-sign {} \;

# Verify all signatures in a directory
verify DIR:
    @echo "Verifying signatures in {{DIR}}..."
    ./tools/pmpl-verify/target/release/pmpl-verify --recursive {{DIR}}

# Audit a repository for compliance
audit DIR=".":
    @echo "Auditing {{DIR}}..."
    ./tools/pmpl-audit/target/release/pmpl-audit {{DIR}}

# ============================================================================
# RELEASE
# ============================================================================

# Package for distribution
package: build
    @echo "Packaging release..."
    mkdir -p dist
    cp legal/PALIMPSEST-MPL-1.0.txt dist/
    cp legal/exhibits/*.txt dist/
    cp tools/pmpl-sign/target/release/pmpl-sign dist/ 2>/dev/null || true
    cp tools/pmpl-verify/target/release/pmpl-verify dist/ 2>/dev/null || true
    cp tools/pmpl-audit/target/release/pmpl-audit dist/ 2>/dev/null || true
    @echo "Package created in dist/"

# Create release tarball
tarball: package
    tar -czf "dist/pmpl-tools-$(git describe --tags 2>/dev/null || echo 'dev').tar.gz" dist/pmpl-*

# ============================================================================
# CLEAN
# ============================================================================

# Clean all build artifacts
clean:
    cd tools/pmpl-sign && cargo clean
    cd tools/pmpl-verify && cargo clean
    cd tools/pmpl-audit && cargo clean
    rm -rf dist/

# ============================================================================
# DEVELOPMENT
# ============================================================================

# Check Rust code
check:
    cd tools/pmpl-sign && cargo check
    cd tools/pmpl-verify && cargo check
    cd tools/pmpl-audit && cargo check

# Run clippy lints
clippy:
    cd tools/pmpl-sign && cargo clippy -- -D warnings
    cd tools/pmpl-verify && cargo clippy -- -D warnings
    cd tools/pmpl-audit && cargo clippy -- -D warnings

# Format Rust code
fmt:
    cd tools/pmpl-sign && cargo fmt
    cd tools/pmpl-verify && cargo fmt
    cd tools/pmpl-audit && cargo fmt

# Check Rust formatting
fmt-check:
    cd tools/pmpl-sign && cargo fmt -- --check
    cd tools/pmpl-verify && cargo fmt -- --check
    cd tools/pmpl-audit && cargo fmt -- --check

# ============================================================================
# HELP
# ============================================================================

# Show project info
info:
    @echo "Palimpsest-MPL License"
    @echo "======================"
    @echo ""
    @echo "Structure:"
    @echo "  legal/     - License texts and exhibits"
    @echo "  docs/      - Documentation"
    @echo "  tools/     - Rust CLI tools"
    @echo "  spec/      - Formal specifications"
    @echo "  research/  - Papers and presentations"
    @echo ""
    @echo "Tools:"
    @echo "  pmpl-sign   - Sign files with quantum-safe signatures"
    @echo "  pmpl-verify - Verify provenance signatures"
    @echo "  pmpl-audit  - Audit repository compliance"
