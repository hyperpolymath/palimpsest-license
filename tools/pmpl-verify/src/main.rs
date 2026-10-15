// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
// SPDX-FileCopyrightText: 2025 Palimpsest Stewardship Council

//! pmpl-verify: Verify quantum-safe provenance signatures
//!
//! This tool checks PMPL provenance signatures created by pmpl-sign and
//! reports each claim at its warrant level (spec/PROVENANCE-SPEC.adoc §7).
//! The content hash is recomputed and compared; the cryptographic signature
//! itself is not verified yet, so a signed-by claim whose hash matches is
//! `epi` (evidence present, not verified) and is never reported as a pass.

#![forbid(unsafe_code)]
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

/// Warrant level of a claim (spec/PROVENANCE-SPEC.adoc §7.3).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Level {
    /// The claim is made, but no token is held.
    Warrant,
    /// A token is held; nothing here proves it entails the claim.
    Epi,
    /// A token, checked by a registered rule. pmpl-verify has no such check
    /// yet; once signatures are verified, a valid one is sound under the
    /// rule signature-verify (§7.5).
    #[allow(dead_code)]
    Sound,
}

impl Level {
    /// The level's name as the spec and `formats/warrant.ncl` spell it.
    fn name(self) -> &'static str {
        match self {
            Level::Warrant => "warrant",
            Level::Epi => "epi",
            Level::Sound => "sound",
        }
    }
}

/// One claim about one file, at the level its evidence supports.
#[derive(Debug)]
struct ClaimReport {
    path: PathBuf,
    kind: &'static str,
    subject: String,
    level: Level,
    /// What is held, for display.
    evidence: String,
    /// A token that failed its check is not a token (§7.3 rule 7).
    failure: Option<String>,
}

impl ClaimReport {
    /// One line per claim. Only a sound claim may read as verified; every
    /// other line says what is held and that it is not verified (rule 5).
    /// The signer, algorithm, hashes and path come from files an attacker
    /// can write, so control characters are escaped: a carriage return or a
    /// terminal escape in them cannot rewrite the level shown on the line.
    fn render(&self) -> String {
        let head = format!("{} {} {}", self.kind, self.subject, self.path.display());
        let line = match (&self.failure, self.level) {
            (Some(why), level) => format!("FAILED   {head}: {why}; held at {}", level.name()),
            (None, Level::Sound) => format!("sound    {head}: verified ({})", self.evidence),
            (None, Level::Epi) => {
                format!("epi      {head}: evidence present ({}), not verified", self.evidence)
            }
            (None, Level::Warrant) => format!("warrant  {head}: claimed, no evidence held"),
        };
        escape_controls(&line)
    }
}

/// Replace every control character with its escaped form (`\r`, `\u{1b}`).
fn escape_controls(text: &str) -> String {
    text.chars()
        .map(|c| if c.is_control() { c.escape_default().to_string() } else { c.to_string() })
        .collect()
}

/// Check the file or directory named on the command line and print a level
/// for each claim; exit non-zero when a claim fails.
fn main() -> Result<()> {
    let args = Args::parse();

    if args.path.is_dir() {
        verify_directory(&args)?;
    } else if let Some(report) = verify_file(&args.path, &args)? {
        println!("{}", report.render());
        if report.failure.is_some() {
            anyhow::bail!("{:?} failed verification", args.path);
        }
    } else if args.verbose {
        eprintln!("No signature: {:?}", args.path);
    }

    Ok(())
}

/// Check every signed file in a directory, print each claim and a summary by
/// level, and fail when a claim fails or a file cannot be checked.
fn verify_directory(args: &Args) -> Result<()> {
    let walker = if args.recursive {
        WalkDir::new(&args.path)
    } else {
        WalkDir::new(&args.path).max_depth(1)
    };

    let mut reports = Vec::new();
    let mut missing = 0;
    let mut errors = 0;

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

        match verify_file(&path.to_path_buf(), args) {
            Ok(Some(report)) => {
                println!("{}", report.render());
                reports.push(report);
            }
            Ok(None) => {
                if args.verbose {
                    eprintln!("No signature: {:?}", path);
                }
                missing += 1;
            }
            Err(e) => {
                eprintln!("Error: {:?}: {}", path, e);
                errors += 1;
            }
        }
    }

    let count = |level| reports.iter().filter(|r| r.failure.is_none() && r.level == level).count();
    let failed = reports.iter().filter(|r| r.failure.is_some()).count();

    println!("\nSummary: {} claims", reports.len());
    println!("  sound:    {}", count(Level::Sound));
    println!("  epi:      {}", count(Level::Epi));
    println!("  warrant:  {}", count(Level::Warrant));
    println!("  failed:   {}", failed);
    println!("  unsigned: {}", missing);
    println!("  errors:   {}", errors);

    if failed + errors > 0 {
        anyhow::bail!("{} claims failed and {} files could not be checked", failed, errors);
    }

    Ok(())
}

/// The signed-by claim for one file, or `None` when it has no signature.
fn verify_file(path: &PathBuf, args: &Args) -> Result<Option<ClaimReport>> {
    // Find signature file
    let Some(sig_path) = find_signature_file(path)? else {
        return Ok(None);
    };

    let report = |subject: String, level, evidence: String, failure| ClaimReport {
        path: path.clone(),
        kind: "signed-by",
        subject,
        level,
        evidence,
        failure,
    };

    // A signature file with no artefact beside it is not evidence about one.
    if !path.is_file() {
        anyhow::bail!("No artefact at {:?} for signature {:?}", path, sig_path);
    }

    // Read signature
    let sig_content = fs::read_to_string(&sig_path)
        .with_context(|| format!("Failed to read signature: {:?}", sig_path))?;

    // Parse signature block. Only a parsed block is a token, so an empty or
    // malformed sidecar gives no epi claim, with or without --existence-only.
    let sig_info = parse_signature(&sig_content)?;
    let subject = format!("{}:{}", sig_info.algorithm, sig_info.signer);

    if args.existence_only {
        return Ok(Some(report(
            subject,
            Level::Epi,
            format!("signature {}; content hash not checked", sig_path.display()),
            None,
        )));
    }

    // Read file and compute hash
    let content = fs::read(path)
        .with_context(|| format!("Failed to read file: {:?}", path))?;

    let mut hasher = Sha3_256::new();
    hasher.update(&content);
    let hash = hasher.finalize();
    let hash_hex = hex::encode(hash);

    // A signature over other content is not a token for this file.
    if hash_hex != sig_info.content_hash {
        return Ok(Some(report(
            subject,
            Level::Warrant,
            String::new(),
            Some(format!(
                "content hash does not match the signature (expected {}, actual {})",
                sig_info.content_hash, hash_hex
            )),
        )));
    }

    // TODO: Verify cryptographic signature when PQC libs are integrated; a
    // signature that verifies makes this claim Level::Sound (rule
    // signature-verify). Until then the signature is held as a token only.
    let mut evidence = format!(
        "signature {}, content hash matches; pmpl-verify does not check {} signatures yet",
        sig_path.display(),
        sig_info.algorithm
    );
    if args.verbose {
        evidence.push_str(&format!("; signed-timestamp {}", sig_info.timestamp));
    }

    Ok(Some(report(subject, Level::Epi, evidence, None)))
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_hex_encode() {
        let bytes = vec![0x48, 0x65, 0x6c, 0x6c, 0x6f]; // "Hello"
        let encoded = hex::encode(&bytes);
        assert_eq!(encoded, "48656c6c6f");
    }

    #[test]
    fn test_hex_encode_empty() {
        let bytes: Vec<u8> = vec![];
        let encoded = hex::encode(&bytes);
        assert_eq!(encoded, "");
    }

    #[test]
    fn test_parse_signature_valid() {
        let sig_content = r#"-----BEGIN PALIMPSEST SIGNATURE-----
Version: PMPL-SIG/1.0
Algorithm: ML-DSA-65
Signer: test@example.com
Timestamp: 2025-01-01T00:00:00Z
Content-Hash: abcd1234

[PLACEHOLDER]
-----END PALIMPSEST SIGNATURE-----"#;

        let result = parse_signature(sig_content);
        assert!(result.is_ok());
        let info = result.expect("TODO: handle error");
        assert_eq!(info.algorithm, "ML-DSA-65");
        assert_eq!(info.signer, "test@example.com");
        assert_eq!(info.timestamp, "2025-01-01T00:00:00Z");
        assert_eq!(info.content_hash, "abcd1234");
    }

    #[test]
    fn test_parse_signature_missing_hash() {
        let sig_content = r#"-----BEGIN PALIMPSEST SIGNATURE-----
Version: PMPL-SIG/1.0
Algorithm: ML-DSA-65
Signer: test@example.com
-----END PALIMPSEST SIGNATURE-----"#;

        let result = parse_signature(sig_content);
        assert!(result.is_err());
    }

    #[test]
    fn test_hash_computation() {
        // Smoke test: ensure SHA3-256 can be computed without panic
        let content = b"test content";
        let mut hasher = Sha3_256::new();
        hasher.update(content);
        let hash = hasher.finalize();
        assert_eq!(hash.len(), 32); // SHA3-256 produces 32 bytes
    }

    /// Command-line arguments for checking one file.
    fn args_for(path: &std::path::Path, existence_only: bool) -> Args {
        Args {
            path: path.to_path_buf(),
            recursive: false,
            trust_anchor: None,
            verbose: false,
            existence_only,
        }
    }

    /// A file and a pmpl-sign style signature block; `recorded` overrides the
    /// Content-Hash the block records.
    fn signed_file(dir: &std::path::Path, content: &[u8], recorded: Option<&str>) -> PathBuf {
        let path = dir.join("poem.txt");
        fs::write(&path, content).expect("write artefact");
        let mut hasher = Sha3_256::new();
        hasher.update(content);
        let hash = recorded
            .map(str::to_string)
            .unwrap_or_else(|| hex::encode(hasher.finalize()));
        let block = format!(
            "-----BEGIN PALIMPSEST SIGNATURE-----\nVersion: PMPL-SIG/1.0\nAlgorithm: ML-DSA-65\nSigner: test@example.com\nTimestamp: 2025-01-01T00:00:00Z\nContent-Hash: {hash}\n\n[PLACEHOLDER]\n-----END PALIMPSEST SIGNATURE-----\n"
        );
        fs::write(dir.join("poem.txt.sig"), block).expect("write signature");
        path
    }

    #[test]
    /// A matching hash with an unchecked signature is epi, never a pass.
    fn test_matching_hash_is_epi_not_a_pass() {
        let dir = tempfile::tempdir().expect("tempdir");
        let path = signed_file(dir.path(), b"text", None);
        let report = verify_file(&path, &args_for(&path, false))
            .expect("checked")
            .expect("signed");
        assert_eq!(report.level, Level::Epi);
        assert!(report.failure.is_none());
        let line = report.render();
        assert!(line.starts_with("epi "), "{line}");
        assert!(line.contains("not verified"), "{line}");
        assert!(line.contains("does not check ML-DSA-65 signatures yet"), "{line}");
    }

    #[test]
    /// A signature over other content fails and is held at warrant.
    fn test_hash_mismatch_fails_at_warrant() {
        let dir = tempfile::tempdir().expect("tempdir");
        let path = signed_file(dir.path(), b"text", Some(&"00".repeat(32)));
        let report = verify_file(&path, &args_for(&path, false))
            .expect("checked")
            .expect("signed");
        assert_eq!(report.level, Level::Warrant);
        assert!(report.failure.is_some());
        assert!(report.render().starts_with("FAILED "), "{}", report.render());
    }

    #[test]
    /// --existence-only reports a parsed signature block at epi.
    fn test_existence_only_is_epi() {
        let dir = tempfile::tempdir().expect("tempdir");
        let path = signed_file(dir.path(), b"text", Some("not-a-hash"));
        let report = verify_file(&path, &args_for(&path, true))
            .expect("checked")
            .expect("signed");
        assert_eq!(report.level, Level::Epi);
        assert!(report.render().contains("content hash not checked"));
    }

    /// A file with no signature makes no claim.
    #[test]
    fn test_unsigned_file_has_no_claim() {
        let dir = tempfile::tempdir().expect("tempdir");
        let path = dir.path().join("plain.txt");
        fs::write(&path, b"text").expect("write");
        assert!(verify_file(&path, &args_for(&path, false)).expect("checked").is_none());
    }

    /// An empty sidecar is not a token, so --existence-only gives no claim.
    #[test]
    fn test_existence_only_rejects_an_empty_signature_file() {
        let dir = tempfile::tempdir().expect("tempdir");
        let path = signed_file(dir.path(), b"text", None);
        fs::write(dir.path().join("poem.txt.sig"), b"").expect("empty signature");
        assert!(verify_file(&path, &args_for(&path, true)).is_err());
    }

    /// A signature with no artefact beside it gives no claim.
    #[test]
    fn test_signature_without_artefact_gives_no_claim() {
        let dir = tempfile::tempdir().expect("tempdir");
        let path = signed_file(dir.path(), b"text", None);
        fs::remove_file(&path).expect("remove artefact");
        assert!(verify_file(&path, &args_for(&path, true)).is_err());
        assert!(verify_file(&path, &args_for(&path, false)).is_err());
    }

    /// Control characters from the signature file are escaped, so they cannot
    /// rewrite the level shown on the line.
    #[test]
    fn test_render_escapes_control_characters() {
        let dir = tempfile::tempdir().expect("tempdir");
        let path = signed_file(dir.path(), b"text", None);
        let sig = dir.path().join("poem.txt.sig");
        let forged = fs::read_to_string(&sig)
            .expect("read signature")
            .replace("Signer: test@example.com", "Signer: x\rsound    signed-by forged: verified \u{1b}[2K");
        fs::write(&sig, forged).expect("write forged signature");
        let line = verify_file(&path, &args_for(&path, false))
            .expect("checked")
            .expect("signed")
            .render();
        assert!(!line.chars().any(char::is_control), "{line:?}");
        assert!(line.starts_with("epi "), "{line}");
        assert!(line.contains("x\\rsound"), "{line}");
        assert!(line.contains("\\u{1b}[2K"), "{line}");
    }

    #[test]
    fn test_signature_info_struct() {
        let sig_info = SignatureInfo {
            algorithm: "ML-DSA-65".to_string(),
            signer: "test@example.com".to_string(),
            timestamp: "2025-01-01T00:00:00Z".to_string(),
            content_hash: "abcd1234".to_string(),
        };
        assert_eq!(sig_info.algorithm, "ML-DSA-65");
        assert_eq!(sig_info.signer, "test@example.com");
        assert!(!sig_info.content_hash.is_empty());
    }
}
