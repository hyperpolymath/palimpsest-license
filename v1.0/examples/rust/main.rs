// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Palimpsest Stewardship Council

//! Example Rust program demonstrating PMPL-1.0 licensing.
//!
//! This is a minimal example showing proper SPDX headers and structure.

fn main() {
    println!("Hello from PMPL-licensed Rust code!");
    println!("License: PMPL-1.0-or-later");
    println!("Compatible with MPL-2.0, MIT, BSD, Apache-2.0, GPL, and more");
}

#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }
}
