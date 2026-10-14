#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
#
# Fetch the sibling proof repositories this repo consumes into
# _build/dependencies with plain git, at pinned commits.  A checkout that does
# not resolve to the pinned commit is a failure, never a fallback to whatever
# the remote currently serves.  Re-pin deliberately, one commit per pin, and
# update the module headers that record it.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
deps=_build/dependencies

# Fetch commit $3 (full SHA) from GitHub $2 (owner/repo) into $deps/$1,
# creating the repository if needed and checking out the commit detached.
# Existing repositories use their configured origin. Print the name and SHA
# on success; Git failures or a revision mismatch terminate the script.
fetch() {
  local name=$1 repo=$2 sha=$3 dir
  dir=$deps/$name
  if [[ ! -d "$dir/.git" ]]; then
    git init -q "$dir"
    git -C "$dir" remote add origin "https://github.com/$repo.git"
  fi
  git -C "$dir" fetch -q --depth 1 origin "$sha"
  git -C "$dir" checkout -q --detach FETCH_HEAD
  test "$(git -C "$dir" rev-parse HEAD)" = "$sha"
  echo "$name @ $sha"
}

mkdir -p "$deps"
# Warrant / Epi / SoundWarrant (E-1); Impossible, as used by no-receipt-reflection (E-2).
fetch epistemic-types hyperpolymath/epistemic-types 6a68de3141a981d766fd006b312f0919ade334bf
