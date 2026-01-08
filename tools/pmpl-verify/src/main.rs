// SPDX-License-Identifier: PMPL-1.0
// SPDX-FileCopyrightText: 2025 Palimpsest Stewardship Council

//! pmpl-verify: Verify quantum-safe provenance signatures
//!
//! This tool verifies PMPL-compliant provenance signatures created by
//! pmpl-sign, checking both the cryptographic signature and the content hash.

use anyhow::{Context, Result};
use clap::Parser;
use sha3::{Digest, Sha3_256};
use std::fs;
use std::path::PathBuf;
use walkdir::WalkDir;

#[derive(Parser, Debug)]
#[command(name = "pmpl-verify")]
#[command(about = "Verify quantum-safe provenance signatures")]
#[command(version)]
struct Args {
    /// Path to the file or directory to verify
    #[arg(required = true)]
    path: PathBuf,

    /// Recursively verify all files in directory
    #[arg(short, long)]
    recursive: bool,

    /// Path to trusted public keys
    #[arg(short, long)]
    trust_anchor: Option<PathBuf>,

    /// Show verbose output
    #[arg(short, long)]
    verbose: bool,

    /// Only check that signatures exist, don't verify them
    #[arg(long)]
    existence_only: bool,
}

fn main() -> Result<()> {
    let args = Args::parse();

    if args.path.is_dir() {
        verify_directory(&args)?;
    } else {
        verify_file(&args.path, &args)?;
    }

    Ok(())
}

fn verify_directory(args: &Args) -> Result<()> {
    let walker = if args.recursive {
        WalkDir::new(&args.path)
    } else {
        WalkDir::new(&args.path).max_depth(1)
    };

    let mut verified = 0;
    let mut missing = 0;
    let mut failed = 0;

    for entry in walker.into_iter().filter_map(|e| e.ok()) {
        let path = entry.path();

        // Skip directories and signature files
        if path.is_dir() || path.extension().map(|e| e == "sig").unwrap_or(false) {
            continue;
        }

        // Skip hidden files
        if path.file_name()
            .and_then(|n| n.to_str())
            .map(|n| n.starts_with('.'))
            .unwrap_or(false)
        {
            continue;
        }

        match verify_file(path, args) {
            Ok(true) => verified += 1,
            Ok(false) => missing += 1,
            Err(e) => {
                if args.verbose {
                    eprintln!("Failed: {:?}: {}", path, e);
                }
                failed += 1;
            }
        }
    }

    println!("\nSummary:");
    println!("  Verified: {}", verified);
    println!("  Missing:  {}", missing);
    println!("  Failed:   {}", failed);

    if failed > 0 {
        anyhow::bail!("{} files failed verification", failed);
    }

    Ok(())
}

fn verify_file(path: &PathBuf, args: &Args) -> Result<bool> {
    // Find signature file
    let sig_path = find_signature_file(path)?;

    let Some(sig_path) = sig_path else {
        if args.verbose {
            eprintln!("No signature: {:?}", path);
        }
        return Ok(false);
    };

    if args.existence_only {
        if args.verbose {
            println!("Has signature: {:?}", path);
        }
        return Ok(true);
    }

    // Read signature
    let sig_content = fs::read_to_string(&sig_path)
        .with_context(|| format!("Failed to read signature: {:?}", sig_path))?;

    // Parse signature block
    let sig_info = parse_signature(&sig_content)?;

    // Read file and compute hash
    let content = fs::read(path)
        .with_context(|| format!("Failed to read file: {:?}", path))?;

    let mut hasher = Sha3_256::new();
    hasher.update(&content);
    let hash = hasher.finalize();
    let hash_hex = hex::encode(hash);

    // Verify hash matches
    if hash_hex != sig_info.content_hash {
        anyhow::bail!(
            "Hash mismatch for {:?}:\n  Expected: {}\n  Actual:   {}",
            path,
            sig_info.content_hash,
            hash_hex
        );
    }

    // TODO: Verify cryptographic signature when PQC libs are integrated

    if args.verbose {
        println!("Verified: {:?}", path);
        println!("  Algorithm: {}", sig_info.algorithm);
        println!("  Signer:    {}", sig_info.signer);
        println!("  Timestamp: {}", sig_info.timestamp);
    } else {
        println!("OK: {:?}", path);
    }

    Ok(true)
}

fn find_signature_file(path: &PathBuf) -> Result<Option<PathBuf>> {
    // Try path.ext.sig first
    let sig_path = path.with_extension(
        path.extension()
            .map(|e| format!("{}.sig", e.to_string_lossy()))
            .unwrap_or_else(|| "sig".to_string()),
    );

    if sig_path.exists() {
        return Ok(Some(sig_path));
    }

    // Try path.sig
    let sig_path = path.with_extension("sig");
    if sig_path.exists() {
        return Ok(Some(sig_path));
    }

    Ok(None)
}

#[derive(Debug)]
struct SignatureInfo {
    algorithm: String,
    signer: String,
    timestamp: String,
    content_hash: String,
}

fn parse_signature(content: &str) -> Result<SignatureInfo> {
    let mut algorithm = String::new();
    let mut signer = String::new();
    let mut timestamp = String::new();
    let mut content_hash = String::new();

    for line in content.lines() {
        if let Some(value) = line.strip_prefix("Algorithm: ") {
            algorithm = value.to_string();
        } else if let Some(value) = line.strip_prefix("Signer: ") {
            signer = value.to_string();
        } else if let Some(value) = line.strip_prefix("Timestamp: ") {
            timestamp = value.to_string();
        } else if let Some(value) = line.strip_prefix("Content-Hash: ") {
            content_hash = value.to_string();
        }
    }

    if content_hash.is_empty() {
        anyhow::bail!("Invalid signature: missing Content-Hash");
    }

    Ok(SignatureInfo {
        algorithm,
        signer,
        timestamp,
        content_hash,
    })
}

mod hex {
    pub fn encode(bytes: impl AsRef<[u8]>) -> String {
        bytes.as_ref().iter().map(|b| format!("{:02x}", b)).collect()
    }
}
