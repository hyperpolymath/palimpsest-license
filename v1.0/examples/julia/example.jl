# SPDX-License-Identifier: PMPL-1.0-or-later
# SPDX-FileCopyrightText: 2025 Palimpsest Stewardship Council

"""
    greet(name::String) -> String

Example Julia function demonstrating PMPL-1.0 licensing.

This file is licensed under PMPL-1.0-or-later. Any modifications to this
file must retain the PMPL license, but you can combine it with other
files under different licenses in the same project.
"""
function greet(name::String)
    println("Hello, $name! This code is licensed under PMPL-1.0-or-later.")
end

"""
    get_license_info() -> Dict{String, Any}

Returns license information for this code.
"""
function get_license_info()
    Dict(
        "identifier" => "PMPL-1.0-or-later",
        "name" => "Palimpsest-MPL License v1.0 or later",
        "compatible_with" => ["MIT", "BSD", "Apache-2.0", "GPL", "MPL-2.0", "LGPL"],
        "copyleft_scope" => "file-level"
    )
end

# Example usage
if abspath(PROGRAM_FILE) == @__FILE__
    greet("Julia Developer")
    info = get_license_info()
    println("\nLicense Information:")
    for (key, value) in info
        println("  $key: $value")
    end
end
