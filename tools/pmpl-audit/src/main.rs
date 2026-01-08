// SPDX-License-Identifier: PMPL-1.0
// SPDX-FileCopyrightText: 2025 Palimpsest Stewardship Council

//! pmpl-audit: Audit repository for PMPL license compliance
//!
//! This tool checks a repository for compliance with Palimpsest-MPL
//! requirements, including SPDX headers, license files, and provenance.

use anyhow::{Context, Result};
use clap::Parser;
use regex::Regex;
use serde::Serialize;
use std::fs;
use std::path::PathBuf;
use walkdir::WalkDir;

#[derive(Parser, Debug)]
#[command(name = "pmpl-audit")]
#[command(about = "Audit repository for PMPL license compliance")]
#[command(version)]
struct Args {
    /// Path to the repository to audit
    #[arg(default_value = ".")]
    path: PathBuf,

    /// Output format (text, json)
    #[arg(short, long, default_value = "text")]
    format: String,

    /// Check SPDX headers
    #[arg(long, default_value = "true")]
    check_headers: bool,

    /// Check LICENSE file
    #[arg(long, default_value = "true")]
    check_license: bool,

    /// Check provenance signatures
    #[arg(long, default_value = "false")]
    check_signatures: bool,

    /// File extensions to check (comma-separated)
    #[arg(long, default_value = "rs,py,js,ts,go,java,c,cpp,h,hpp")]
    extensions: String,
}

#[derive(Debug, Serialize)]
struct AuditResult {
    path: String,
    license_present: bool,
    license_type: Option<String>,
    files_checked: usize,
    files_with_headers: usize,
    files_missing_headers: Vec<String>,
    files_with_signatures: usize,
    issues: Vec<String>,
    passed: bool,
}

fn main() -> Result<()> {
    let args = Args::parse();
    let result = audit_repository(&args)?;

    match args.format.as_str() {
        "json" => {
            println!("{}", serde_json::to_string_pretty(&result)?);
        }
        _ => {
            print_text_report(&result);
        }
    }

    if result.passed {
        std::process::exit(0);
    } else {
        std::process::exit(1);
    }
}

fn audit_repository(args: &Args) -> Result<AuditResult> {
    let mut result = AuditResult {
        path: args.path.display().to_string(),
        license_present: false,
        license_type: None,
        files_checked: 0,
        files_with_headers: 0,
        files_missing_headers: Vec::new(),
        files_with_signatures: 0,
        issues: Vec::new(),
        passed: true,
    };

    // Check LICENSE file
    if args.check_license {
        check_license_file(&args.path, &mut result)?;
    }

    // Check file headers
    if args.check_headers {
        let extensions: Vec<&str> = args.extensions.split(',').collect();
        check_file_headers(&args.path, &extensions, args.check_signatures, &mut result)?;
    }

    // Determine pass/fail
    result.passed = result.license_present && result.files_missing_headers.is_empty();

    Ok(result)
}

fn check_license_file(path: &PathBuf, result: &mut AuditResult) -> Result<()> {
    let license_files = ["LICENSE", "LICENSE.txt", "LICENSE.md", "COPYING"];

    for name in license_files {
        let license_path = path.join(name);
        if license_path.exists() {
            result.license_present = true;

            let content = fs::read_to_string(&license_path)
                .with_context(|| format!("Failed to read license file: {:?}", license_path))?;

            // Detect license type
            if content.contains("PALIMPSEST-MPL") || content.contains("PMPL-1.0") {
                result.license_type = Some("PMPL-1.0".to_string());
            } else if content.contains("Mozilla Public License") {
                result.license_type = Some("MPL-2.0".to_string());
            } else if content.contains("MIT License") {
                result.license_type = Some("MIT".to_string());
            } else if content.contains("Apache License") {
                result.license_type = Some("Apache-2.0".to_string());
            }

            return Ok(());
        }
    }

    result.issues.push("No LICENSE file found".to_string());
    Ok(())
}

fn check_file_headers(
    path: &PathBuf,
    extensions: &[&str],
    check_signatures: bool,
    result: &mut AuditResult,
) -> Result<()> {
    let spdx_pattern = Regex::new(r"SPDX-License-Identifier:\s*\S+").unwrap();

    for entry in WalkDir::new(path)
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| e.file_type().is_file())
    {
        let file_path = entry.path();

        // Skip hidden files and directories
        if file_path
            .components()
            .any(|c| c.as_os_str().to_string_lossy().starts_with('.'))
        {
            continue;
        }

        // Skip common non-source directories
        let path_str = file_path.to_string_lossy();
        if path_str.contains("/target/")
            || path_str.contains("/node_modules/")
            || path_str.contains("/vendor/")
            || path_str.contains("/_build/")
        {
            continue;
        }

        // Check file extension
        let ext = file_path
            .extension()
            .and_then(|e| e.to_str())
            .unwrap_or("");

        if !extensions.contains(&ext) {
            continue;
        }

        result.files_checked += 1;

        // Read first 10 lines to check for header
        let content = match fs::read_to_string(file_path) {
            Ok(c) => c,
            Err(_) => continue, // Skip binary files
        };

        let header: String = content.lines().take(10).collect::<Vec<_>>().join("\n");

        if spdx_pattern.is_match(&header) {
            result.files_with_headers += 1;
        } else {
            result.files_missing_headers.push(
                file_path
                    .strip_prefix(path)
                    .unwrap_or(file_path)
                    .display()
                    .to_string(),
            );
        }

        // Check for signature file
        if check_signatures {
            let sig_path = file_path.with_extension(format!("{}.sig", ext));
            if sig_path.exists() {
                result.files_with_signatures += 1;
            }
        }
    }

    Ok(())
}

fn print_text_report(result: &AuditResult) {
    println!("PMPL Compliance Audit Report");
    println!("============================");
    println!();
    println!("Repository: {}", result.path);
    println!();

    // License status
    println!("License File:");
    if result.license_present {
        println!(
            "  [PASS] Present ({})",
            result.license_type.as_deref().unwrap_or("Unknown")
        );
    } else {
        println!("  [FAIL] Missing");
    }
    println!();

    // File headers
    println!("SPDX Headers:");
    println!("  Files checked:  {}", result.files_checked);
    println!("  With headers:   {}", result.files_with_headers);
    println!(
        "  Missing headers: {}",
        result.files_missing_headers.len()
    );

    if !result.files_missing_headers.is_empty() {
        println!();
        println!("Files missing SPDX headers:");
        for file in &result.files_missing_headers {
            println!("  - {}", file);
        }
    }
    println!();

    // Signatures
    if result.files_with_signatures > 0 {
        println!("Provenance Signatures:");
        println!("  Files with signatures: {}", result.files_with_signatures);
        println!();
    }

    // Issues
    if !result.issues.is_empty() {
        println!("Issues:");
        for issue in &result.issues {
            println!("  - {}", issue);
        }
        println!();
    }

    // Overall result
    println!("Overall: {}", if result.passed { "PASS" } else { "FAIL" });
}
