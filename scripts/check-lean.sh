#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
#
# Lean leg of the warrant proofs (standards 3-practice/PROOF-POLICY.adoc §2):
#   1. proofs/lean/Warrant.lean elaborates with no error, and every
#      declaration it reports with #print axioms depends on no axiom (so no
#      sorry, which is the axiom sorryAx);
#   2. control: the same file with one proof replaced by sorry is reported.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
export LC_ALL=C.UTF-8 LANG=C.UTF-8
prover="${LEAN:-lean}"
src=proofs/lean/Warrant.lean
work=_build/lean
mkdir -p "$work"

"$prover" --version

# Elaborate $1; succeed only when every #print axioms line of the source is
# answered "does not depend on any axioms".
axiom_free() {
  local file=$1 log printed clean
  log="$work/$(basename -- "$(dirname -- "$file")")-$(basename -- "$file" .lean).log"
  if ! "$prover" "$file" >"$log" 2>&1; then
    cat "$log"
    echo "ERROR: $file does not elaborate" >&2
    return 1
  fi
  printed="$(grep -c '^#print axioms ' "$file")"
  clean="$(grep -c 'does not depend on any axioms$' "$log" || true)"
  if (( printed == 0 || clean != printed )); then
    cat "$log"
    echo "ERROR: $file: $clean of $printed declarations are axiom-free" >&2
    return 1
  fi
  echo "PASS: $file elaborates; $printed declarations are axiom-free"
}

axiom_free "$src"

# Control: a sorry in one proof must be reported.
control="$work/control/Warrant.lean"
mkdir -p "$(dirname -- "$control")"
sed '0,/^  rfl$/s//  sorry/' "$src" >"$control"
if cmp -s "$control" "$src"; then
  echo "ERROR: control was not derived; $src changed shape" >&2
  exit 1
fi
if axiom_free "$control" >/dev/null 2>&1; then
  echo 'ERROR: control: a sorry was not reported' >&2
  exit 1
fi
echo 'PASS: control, a sorry is reported'
