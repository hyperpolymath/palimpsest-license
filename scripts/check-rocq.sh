#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
#
# Rocq leg of the warrant proofs (standards 3-practice/PROOF-POLICY.adoc §2):
#   1. proofs/rocq/Warrant.v compiles, every statement it reports with
#      Print Assumptions is closed under the global context, and no
#      declaration anywhere in it is admitted or assumed (Admitted, admit,
#      Axiom, Parameter, Conjecture), printed or not;
#   2. controls: the same file with one printed proof Admitted, and with one
#      unprinted definition Admitted, is reported.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
export LC_ALL=C.UTF-8 LANG=C.UTF-8
prover="${COQC:-coqc}"
src=proofs/rocq/Warrant.v
work=_build/rocq
mkdir -p "$work"

"$prover" --version

# Compile $1 in $work; succeed only when no declaration in it is admitted or
# assumed and every Print Assumptions line of the source is answered "Closed
# under the global context".  Print Assumptions covers only the statements
# it names, so the hole scan is what covers the rest of the file.
axiom_free() {
  local file=$1 name log printed closed holes
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
  holes="$({ grep -nE '\<(Admitted|admit|Axioms?|Parameters?|Conjecture)\>' "$file" || [[ $? -eq 1 ]]; })"
  if [[ -n "$holes" ]]; then
    printf '%s\n' "$holes"
    echo "ERROR: $file admits or assumes a declaration" >&2
    return 1
  fi
  echo "PASS: $file compiles; $printed statements are axiom-free; no declaration is admitted or assumed"
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

# Control: admitting a definition that no Print Assumptions line names must
# be reported too.
unprinted="$work/control-unprinted/Warrant.v"
mkdir -p "$(dirname -- "$unprinted")"
sed -e 's/^    : Epi Standpoint licensor (ConsentedForTraining x) :=$/    : Epi Standpoint licensor (ConsentedForTraining x)./' \
    -e 's/^    epi (consent x) header\.$/  Admitted./' "$src" >"$unprinted"
if cmp -s "$unprinted" "$src" || grep -q '^Print Assumptions consent_epi' "$src"; then
  echo "ERROR: unprinted control was not derived; $src changed shape" >&2
  exit 1
fi
if axiom_free "$unprinted" >/dev/null 2>&1; then
  echo 'ERROR: control: an Admitted definition outside Print Assumptions was not reported' >&2
  exit 1
fi
echo 'PASS: control, an Admitted definition outside Print Assumptions is reported'
