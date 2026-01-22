#!/usr/bin/env julia
# SPDX-License-Identifier: PMPL-1.0-or-later
# SPDX-FileCopyrightText: 2025 Palimpsest Stewardship Council

"""
migrate-version.jl - Automate version migration for palimpsest-license

Systematically archives the current version and prepares structure for new version.

Usage:
    ./scripts/migrate-version.jl --from 1.0 --to 1.1 [--dry-run]

Example:
    # Migrate from v1.0 to v1.1 (dry run)
    ./scripts/migrate-version.jl --from 1.0 --to 1.1 --dry-run

    # Actually perform migration
    ./scripts/migrate-version.jl --from 1.0 --to 1.1
"""

using Dates
using Printf

# Parse command line arguments
function parse_args()
    args = Dict{String,Any}()
    i = 1
    while i <= length(ARGS)
        if ARGS[i] == "--from"
            args["from"] = ARGS[i+1]
            i += 2
        elseif ARGS[i] == "--to"
            args["to"] = ARGS[i+1]
            i += 2
        elseif ARGS[i] == "--dry-run"
            args["dry_run"] = true
            i += 1
        else
            println("Unknown argument: $(ARGS[i])")
            exit(1)
        end
    end

    if !haskey(args, "from") || !haskey(args, "to")
        println("Error: --from and --to arguments required")
        println("Usage: ./migrate-version.jl --from 1.0 --to 1.1 [--dry-run]")
        exit(1)
    end

    args["dry_run"] = get(args, "dry_run", false)
    return args
end

# Validate version format
function validate_version(version_str)
    m = match(r"^(\d+)\.(\d+)$", version_str)
    if m === nothing
        error("Invalid version format: $version_str (expected: X.Y)")
    end
    return (parse(Int, m.captures[1]), parse(Int, m.captures[2]))
end

# Check if version directory exists
function check_version_exists(version_str)
    dir = "v$version_str"
    if !isdir(dir)
        error("Current version directory '$dir' does not exist")
    end
end

# Create archive directory structure
function archive_current_version(from_version, dry_run)
    from_dir = "v$from_version"
    archive_dir = "ARCHIVE/v$from_version"

    println("📦 Archiving v$from_version → $archive_dir")

    if dry_run
        println("   [DRY RUN] Would move $from_dir → $archive_dir")
        return
    end

    # Create ARCHIVE directory if needed
    if !isdir("ARCHIVE")
        mkdir("ARCHIVE")
    end

    # Move current version to archive
    if isdir(archive_dir)
        error("Archive directory already exists: $archive_dir")
    end

    mv(from_dir, archive_dir)
    println("   ✓ Moved $from_dir → $archive_dir")
end

# Create archive README
function create_archive_readme(from_version, to_version, dry_run)
    archive_dir = "ARCHIVE/v$from_version"
    readme_path = joinpath(archive_dir, "README.adoc")

    date_str = Dates.format(Dates.today(), "yyyy-mm-dd")

    content = """
= PMPL v$from_version - ARCHIVED VERSION

⚠️ **This version has been superseded by PMPL v$to_version**

This directory contains historical materials for PMPL v$from_version.

**For current version**: See link:../../v$to_version/[v$to_version/]

== Archival Information

- **Archived**: $date_str
- **Superseded by**: v$to_version
- **Status**: Historical reference only
- **Do not use for new projects**

== What's Here

This archived version includes:

- `LICENSE.txt` - PMPL v$from_version license text
- `docs/` - v$from_version documentation
- `exhibits/` - Exhibit A and B for v$from_version
- `examples/` - Sample implementations
- `INDEX.adoc` - Navigation guide

All materials preserved as-is from the v$from_version release.

== Migration

If you're using PMPL v$from_version, see the link:../../CHANGELOG.adoc[Changelog] and
link:../../docs/MIGRATION.md[Migration Guide] (if available) for upgrading to v$to_version.

== Support

v$from_version is no longer actively supported. For security issues in legacy versions,
please contact the Palimpsest Stewardship Council.

== License

These archived materials remain under PMPL v$from_version terms.

SPDX-License-Identifier: PMPL-$from_version-or-later
"""

    println("📝 Creating archive README")

    if dry_run
        println("   [DRY RUN] Would create $readme_path")
        return
    end

    write(readme_path, content)
    println("   ✓ Created $readme_path")
end

# Create new version directory structure
function create_new_version_structure(to_version, dry_run)
    new_dir = "v$to_version"

    println("🆕 Creating v$to_version structure")

    if dry_run
        println("   [DRY RUN] Would create $new_dir/")
        println("   [DRY RUN] Would create $new_dir/docs/")
        println("   [DRY RUN] Would create $new_dir/exhibits/")
        println("   [DRY RUN] Would create $new_dir/examples/")
        println("   [DRY RUN] Would create $new_dir/tools/")
        return
    end

    if isdir(new_dir)
        error("New version directory already exists: $new_dir")
    end

    mkdir(new_dir)
    mkdir(joinpath(new_dir, "docs"))
    mkdir(joinpath(new_dir, "exhibits"))
    mkdir(joinpath(new_dir, "examples"))
    mkdir(joinpath(new_dir, "tools"))

    println("   ✓ Created $new_dir directory structure")
end

# Copy template files for new version
function create_new_version_readme(to_version, dry_run)
    readme_path = "v$to_version/README.adoc"

    content = """
= PMPL v$to_version - CURRENT VERSION
:toc: macro
:toclevels: 2

*This is the current, canonical version of the Palimpsest-MPL License.*

Last Updated: $(Dates.format(Dates.today(), "yyyy u"))
Status: **STABLE**
SPDX Identifier: `PMPL-$to_version-or-later`

toc::[]

== What is PMPL v$to_version?

The Palimpsest-MPL License v$to_version is a file-level copyleft license that extends Mozilla Public License 2.0 with:

* **Ethical Use Framework** (Exhibit A) - Structured guidelines for responsible use
* **Quantum-Safe Provenance** (Exhibit B) - Post-quantum cryptographic signatures
* **Emotional Lineage Protection** - Recognition of cultural and narrative meaning
* **AI Training Clarity** - Clear guidance for machine learning use cases

== Quick Start

=== Download the License

The complete license text is in this directory:

----
v$to_version/LICENSE.txt
----

Or download directly from GitHub:

----
curl -O https://raw.githubusercontent.com/hyperpolymath/palimpsest-license/main/v$to_version/LICENSE.txt
----

=== Apply to Your Project

1. **Copy the license:**
+
----
cp v$to_version/LICENSE.txt YOUR_PROJECT/LICENSE
----

2. **Add SPDX headers to source files:**
+
[source,javascript]
----
// SPDX-License-Identifier: PMPL-$to_version-or-later
// SPDX-FileCopyrightText: 2025 Your Name
----

== What's New in v$to_version

[TODO: Document changes from previous version]

See link:../CHANGELOG.adoc[] for complete version history.

== Documentation

Key documents for v$to_version:

* link:docs/QUICK-START.adoc[Quick Start Guide]
* link:docs/FAQ.adoc[FAQ]
* link:docs/INTEGRATION-GUIDE.adoc[Integration Guide]
* link:docs/COMPATIBILITY.adoc[Compatibility Matrix]

== Tooling

PMPL v$to_version includes optional command-line tools:

[cols="2,5"]
|===
| Tool | Purpose

| `pmpl-sign`
| Create quantum-safe signatures for your files

| `pmpl-verify`
| Verify provenance and signature chains

| `pmpl-audit`
| Audit repositories for PMPL compliance
|===

Build instructions: link:../tools/README.adoc[tools/README.adoc]

== License of This Repository

This repository and all v$to_version materials are licensed under:

----
SPDX-License-Identifier: PMPL-$to_version-or-later
----
"""

    println("📝 Creating v$to_version README")

    if dry_run
        println("   [DRY RUN] Would create $readme_path")
        return
    end

    write(readme_path, content)
    println("   ✓ Created $readme_path")
end

# Create placeholder LICENSE.txt for new version
function create_new_version_license(to_version, dry_run)
    license_path = "v$to_version/LICENSE.txt"

    content = """
SPDX-License-Identifier: PMPL-$to_version
SPDX-FileCopyrightText: 2025 Palimpsest Stewardship Council

================================================================================
PALIMPSEST-MPL LICENSE VERSION $to_version
================================================================================

File-level copyleft with ethical use and quantum-safe provenance

Based on Mozilla Public License 2.0

[TODO: Complete license text for v$to_version]
[TODO: Update this file with final legal text before release]

This is a DRAFT placeholder created by migrate-version.jl.
Do not use this for actual licensing until finalized.
"""

    println("📝 Creating v$to_version LICENSE.txt placeholder")

    if dry_run
        println("   [DRY RUN] Would create $license_path")
        return
    end

    write(license_path, content)
    println("   ✓ Created $license_path (DRAFT - needs completion)")
end

# Update main README.adoc
function update_main_readme(to_version, dry_run)
    readme_path = "README.adoc"

    println("📝 Updating main README.adoc")

    if dry_run
        println("   [DRY RUN] Would update version references in $readme_path")
        return
    end

    content = read(readme_path, String)

    # Update version references (basic pattern matching)
    # This is a simple replacement - manual review recommended
    content = replace(content, r"v\d+\.\d+/" => "v$to_version/")
    content = replace(content, r"PMPL-\d+\.\d+-or-later" => "PMPL-$to_version-or-later")

    write(readme_path, content)
    println("   ✓ Updated $readme_path (review version references manually)")
end

# Update STATE.scm
function update_state_scm(to_version, dry_run)
    state_path = "STATE.scm"

    println("📝 Updating STATE.scm")

    if dry_run
        println("   [DRY RUN] Would update version in $state_path")
        return
    end

    content = read(state_path, String)
    date_str = Dates.format(Dates.today(), "yyyy-mm-dd")

    # Update version and date
    content = replace(content, r"\(version \"[\d.]+\"\)" => "(version \"$to_version.0\")")
    content = replace(content, r"\(updated \"[\d-]+\"\)" => "(updated \"$date_str\")")

    write(state_path, content)
    println("   ✓ Updated $state_path")
end

# Create git branch for release
function create_release_branch(to_version, dry_run)
    branch_name = "release/v$to_version"

    println("🌿 Creating git branch")

    if dry_run
        println("   [DRY RUN] Would create branch: $branch_name")
        return
    end

    run(`git checkout -b $branch_name`)
    println("   ✓ Created and checked out branch: $branch_name")
end

# Main migration workflow
function main()
    println("=" ^ 80)
    println("PMPL Version Migration Script")
    println("=" ^ 80)
    println()

    args = parse_args()
    from_version = args["from"]
    to_version = args["to"]
    dry_run = args["dry_run"]

    if dry_run
        println("⚠️  DRY RUN MODE - No actual changes will be made")
        println()
    end

    println("Migrating: v$from_version → v$to_version")
    println()

    # Validate versions
    from_ver = validate_version(from_version)
    to_ver = validate_version(to_version)

    if to_ver <= from_ver
        error("New version ($to_version) must be greater than current version ($from_version)")
    end

    # Check current version exists
    check_version_exists(from_version)

    # Perform migration steps
    try
        archive_current_version(from_version, dry_run)
        create_archive_readme(from_version, to_version, dry_run)
        create_new_version_structure(to_version, dry_run)
        create_new_version_readme(to_version, dry_run)
        create_new_version_license(to_version, dry_run)
        update_main_readme(to_version, dry_run)
        update_state_scm(to_version, dry_run)

        if !dry_run
            create_release_branch(to_version, dry_run)
        end

        println()
        println("=" ^ 80)
        println("✅ Migration complete!")
        println("=" ^ 80)
        println()

        if dry_run
            println("This was a DRY RUN. Run without --dry-run to apply changes.")
        else
            println("Next steps:")
            println("1. Complete v$to_version/LICENSE.txt with final legal text")
            println("2. Update v$to_version/docs/ with new documentation")
            println("3. Copy exhibits to v$to_version/exhibits/")
            println("4. Update CHANGELOG.adoc with v$to_version changes")
            println("5. Review all version references in README.adoc")
            println("6. Test everything thoroughly")
            println("7. Commit, review, and merge release/v$to_version branch")
            println("8. Tag release: git tag -a v$to_version -m 'Release PMPL v$to_version'")
        end

    catch e
        println()
        println("❌ Migration failed: $e")
        exit(1)
    end
end

# Run main function
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
