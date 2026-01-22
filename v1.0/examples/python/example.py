# SPDX-License-Identifier: PMPL-1.0-or-later
# SPDX-FileCopyrightText: 2025 Palimpsest Stewardship Council

"""Example Python module demonstrating PMPL-1.0 licensing.

This shows proper SPDX headers and module structure.
"""

def greet(name: str) -> str:
    """Greet the user with license information.

    Args:
        name: Name to greet

    Returns:
        Greeting message
    """
    return f"Hello, {name}! This code is licensed under PMPL-1.0-or-later."


def get_license_info() -> dict:
    """Get license information.

    Returns:
        License metadata dictionary
    """
    return {
        "identifier": "PMPL-1.0-or-later",
        "name": "Palimpsest-MPL License v1.0 or later",
        "compatible_with": ["MIT", "BSD", "Apache-2.0", "GPL", "MPL-2.0"],
        "url": "https://github.com/hyperpolymath/palimpsest-license"
    }


if __name__ == "__main__":
    print(greet("World"))
    print("License info:", get_license_info())
