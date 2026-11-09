#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
#
# Rocq leg of the warrant proofs (standards 3-practice/PROOF-POLICY.adoc §2):
#   1. proofs/rocq/Warrant.v compiles, and every statement it reports with
#      Print Assumptions is closed under the global context (no axiom, no
#      Admitted);
#   2. control: the same file with one proof Admitted is reported.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
export LC_ALL=C.UTF-8 LANG=C.UTF-8
prover="${COQC:-coqc}"
src=proofs/rocq/Warrant.v
work=_build/rocq
mkdir -p "$work"

"$prover" --version

# Compile $1 in $work; succeed only when every Print Assumptions line of the
# source is answered "Closed under the global context".
axiom_free() {
  local file=$1 name log printed closed
  name="$(basename -- "$file")"
  cp -- "$file" "$work/$name"
  log="$work/${name%.v}.log"
  if ! (cd "$work" && "$prover" -q "$name") >"$log" 2>&1; then
    cat "$log"
    echo "ERROR: $file does not compile" >&2
    return 1
  fi
  printed="$(grep -c '^Print Assumptions ' "$file")"
  closed="$(grep -c '^Closed under the global context$' "$log" || true)"
  if (( printed == 0 || closed != printed )); then
    cat "$log"
    echo "ERROR: $file: $closed of $printed statements are axiom-free" >&2
    return 1
  fi
  echo "PASS: $file compiles; $printed statements are axiom-free"
}

axiom_free "$src"

# Control: admitting one proof must be reported.
control="$work/control/Warrant.v"
mkdir -p "$(dirname -- "$control")"
sed 's/^  Proof\. reflexivity\. Qed\.$/  Proof. Admitted./' "$src" >"$control"
if cmp -s "$control" "$src"; then
  echo "ERROR: control was not derived; $src changed shape" >&2
  exit 1
fi
if axiom_free "$control" >/dev/null 2>&1; then
  echo 'ERROR: control: an Admitted proof was not reported' >&2
  exit 1
fi
echo 'PASS: control, an Admitted proof is reported'
