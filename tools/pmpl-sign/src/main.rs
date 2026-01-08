// SPDX-License-Identifier: PMPL-1.0
// SPDX-FileCopyrightText: 2025 Palimpsest Stewardship Council

//! pmpl-sign: Sign files with quantum-safe provenance signatures
//!
//! This tool creates PMPL-compliant provenance signatures using post-quantum
//! cryptographic algorithms as specified in Exhibit B of the Palimpsest-MPL
//! license.

use anyhow::{Context, Result};
use clap::Parser;
use sha3::{Digest, Sha3_256};
use std::fs;
use std::path::PathBuf;

#[derive(Parser, Debug)]
#[command(name = "pmpl-sign")]
#[command(about = "Sign files with quantum-safe provenance signatures")]
#[command(version)]
struct Args {
    /// Path to the file to sign
    #[arg(required = true)]
    file: PathBuf,

    /// Path to the private key file
    #[arg(short, long, default_value = "~/.pmpl/private.pem")]
    key: PathBuf,

    /// Signing algorithm (ML-DSA-65, SLH-DSA-256s, FN-DSA-1024)
    #[arg(short, long, default_value = "ML-DSA-65")]
    algorithm: String,

    /// Signer identity (email or URL)
    #[arg(short, long)]
    signer: Option<String>,

    /// Force overwrite existing signature
    #[arg(short, long)]
    force: bool,

    /// Output signature to stdout instead of .sig file
    #[arg(long)]
    stdout: bool,
}

fn main() -> Result<()> {
    let args = Args::parse();

    // Read file content
    let content = fs::read(&args.file)
        .with_context(|| format!("Failed to read file: {:?}", args.file))?;

    // Compute SHA3-256 hash
    let mut hasher = Sha3_256::new();
    hasher.update(&content);
    let hash = hasher.finalize();
    let hash_hex = hex::encode(hash);

    // Get signer identity
    let signer = args.signer.unwrap_or_else(|| {
        std::env::var("PMPL_SIGNER")
            .unwrap_or_else(|_| "anonymous".to_string())
    });

    // Get current timestamp
    let timestamp = chrono::Utc::now().format("%Y-%m-%dT%H:%M:%SZ").to_string();

    // TODO: Implement actual PQC signing when libraries stabilize
    // For now, create a placeholder signature block
    let signature_block = format!(
        r#"-----BEGIN PALIMPSEST SIGNATURE-----
Version: PMPL-SIG/1.0
Algorithm: {}
Signer: {}
Timestamp: {}
Content-Hash: {}

[PLACEHOLDER: Actual {} signature would go here]
[Requires: pqcrypto or oqs library integration]
-----END PALIMPSEST SIGNATURE-----
"#,
        args.algorithm,
        signer,
        timestamp,
        hash_hex,
        args.algorithm
    );

    if args.stdout {
        print!("{}", signature_block);
    } else {
        let sig_path = args.file.with_extension(
            args.file
                .extension()
                .map(|e| format!("{}.sig", e.to_string_lossy()))
                .unwrap_or_else(|| "sig".to_string()),
        );

        if sig_path.exists() && !args.force {
            anyhow::bail!(
                "Signature file already exists: {:?}. Use --force to overwrite.",
                sig_path
            );
        }

        fs::write(&sig_path, &signature_block)
            .with_context(|| format!("Failed to write signature: {:?}", sig_path))?;

        eprintln!("Signed: {:?} -> {:?}", args.file, sig_path);
    }

    Ok(())
}

// Placeholder for hex encoding until we add the dep
mod hex {
    pub fn encode(bytes: impl AsRef<[u8]>) -> String {
        bytes.as_ref().iter().map(|b| format!("{:02x}", b)).collect()
    }
}
