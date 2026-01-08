// SPDX-License-Identifier: PMPL-1.0
// SPDX-FileCopyrightText: 2025 Example Author <author@example.com>

//! Example Rust library demonstrating PMPL-1.0 license headers.
//!
//! This file shows the correct way to apply the Palimpsest-MPL license
//! to Rust source files.

/// A greeting function.
pub fn greet(name: &str) -> String {
    format!("Hello, {}!", name)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_greet() {
        assert_eq!(greet("World"), "Hello, World!");
    }
}
