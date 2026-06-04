// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
// SPDX-FileCopyrightText: 2025 Palimpsest Stewardship Council

/**
 * Example JavaScript module demonstrating PMPL-1.0 licensing.
 *
 * This shows proper SPDX headers and exports.
 */

/**
 * Greet the user with license information
 * @param {string} name - Name to greet
 * @returns {string} Greeting message
 */
export function greet(name) {
  return `Hello, ${name}! This code is licensed under PMPL-1.0-or-later.`;
}

/**
 * Get license information
 * @returns {object} License metadata
 */
export function getLicenseInfo() {
  return {
    identifier: "PMPL-1.0-or-later",
    name: "Palimpsest-MPL License v1.0 or later",
    compatibleWith: ["MIT", "BSD", "Apache-2.0", "GPL", "PMPL-1.0-or-later"],
    url: "https://github.com/hyperpolymath/palimpsest-license"
  };
}

// Example usage (Deno)
if (import.meta.main) {
  console.log(greet("World"));
  console.log("License info:", getLicenseInfo());
}
