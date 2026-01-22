// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Example Contributor

/**
 * Utility functions under MIT license.
 *
 * This file uses permissive MIT licensing and can be freely used.
 * ReScript code compiles to JavaScript.
 */

@val external log: string => unit = "console.log"

let mitFunction = () => {
  log("This function is licensed under MIT")
  log("Permissive: Can be relicensed if needed")
  log("ReScript compiles to clean, readable JavaScript")
}

let getLicenseInfo = () => {
  {
    "identifier": "MIT",
    "name": "MIT License",
    "compatible_with_pmpl": true,
    "file_type": "permissive",
  }
}
