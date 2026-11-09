#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
#
# Agda proof gate for proofs/agda.  Run scripts/fetch-siblings.sh first.
# Flags: the estate theory profile (standards 3-practice/PROOF-POLICY.adoc
# §2.1, --safe --without-K --cubical-compatible) with epistemic-types' module
# options (--exact-split --no-sized-types --no-guardedness), and
# --no-libraries --ignore-interfaces --double-check -W error.
#   1. the positive set typechecks against the pinned epistemic-types, and
#      its import cone raises UnsupportedIndexedMatch at exactly the audited
#      upstream spans below and nowhere else;
#   2. every module under tests/reject is refused at its `invalid`
#      declaration by a type error (not a missing import, parse error or hole);
#   3. control: the harness itself reports a fixture that typechecks.
set -euo pipefail
cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
export LC_ALL=C.UTF-8 LANG=C.UTF-8
prover="${AGDA:-agda}"
epistemic=_build/dependencies/epistemic-types
pin=dcd464839333bc83e55c7ddf44ade7cc83426a99

"$prover" --version
if [[ "$(git -C "$epistemic" rev-parse HEAD 2>/dev/null)" != "$pin" ]]; then
  echo "ERROR: $epistemic is not at the pinned $pin; run scripts/fetch-siblings.sh" >&2
  exit 1
fi
profile=(--safe --without-K --cubical-compatible --exact-split --no-sized-types
         --no-guardedness --no-libraries --ignore-interfaces --double-check
         -i proofs/agda -i "$epistemic/src")
flags=("${profile[@]}" -W error -W noUnsupportedIndexedMatch)
logs=_build/agda-logs
mkdir -p "$logs"

# Agda cannot yet compute these indexed matches under transport.  The proofs
# still check; no Cubical transport-computation claim is made for them.  They
# are epistemic-types' own reviewed spans (its tests/check-proofs.sh manifest);
# none is in this repository.  A new, moved or vanished span fails the gate.
audited=(
  "$epistemic/src/EpistemicTypes/EchoBridge.agda:156,1-157,49"
  "$epistemic/src/EpistemicTypes/EchoBridge.agda:168,1-169,58"
)

# 1. Positive set first: missing imports or broken tooling must not turn
#    into successful expected-rejection tests.
"$prover" "${flags[@]}" proofs/agda/Provenance/Warrant.agda
# Audit pass: every warning left after the strict pass is an
# UnsupportedIndexedMatch, so the set of warned spans must equal the manifest.
"$prover" "${profile[@]}" -W noerror proofs/agda/Provenance/Warrant.agda >"$logs/audit.log" 2>&1
observed="$({ grep -oE '^/[^:]+\.agda:[0-9]+,[0-9]+-[0-9,]+' "$logs/audit.log" || [[ $? -eq 1 ]]; } |
            sed "s#^$PWD/##" | sort -u)"
expected="$(printf '%s\n' "${audited[@]}" | sort -u)"
if [[ "$observed" != "$expected" ]]; then
  cat "$logs/audit.log"
  printf 'ERROR: UnsupportedIndexedMatch spans differ from the audited manifest\nexpected:\n%s\nobserved:\n%s\n' \
    "$expected" "$observed" >&2
  exit 1
fi
echo "PASS: proofs/agda/Provenance/Warrant.agda; UnsupportedIndexedMatch confined to ${#audited[@]} audited upstream spans"

# Succeeds when $1 is refused by a type error at or after its `invalid :`
# signature; prints why and fails otherwise.
rejected() {
  local file=$1 name dir log sig at
  name="$(basename -- "$file" .agda)"
  dir="$(dirname -- "$file")"
  log="$logs/$name.log"
  if "$prover" "${flags[@]}" -i "$dir" "$file" >"$log" 2>&1; then
    cat "$log"
    echo "ERROR: invalid proof accepted: $name" >&2
    return 1
  fi
  sig="$(grep -n '^ *invalid :' "$file" | head -1 | cut -d: -f1)"
  at="$(grep -F "$(realpath -- "$file"):" "$log" | head -1 | grep -oE ':[0-9]+,' | grep -oE '[0-9]+' || true)"
  if [[ -z "$sig" || -z "$at" ]] || (( at < sig )) ||
     ! grep -q 'when checking that' "$log" ||
     grep -Eq 'Not in scope|Failed to find|Unsolved|Parse error' "$log"; then
    cat "$log"
    echo "ERROR: $name failed, but not by a type error at its invalid declaration" >&2
    return 1
  fi
}

# 2. Expected rejections.  An empty set is a broken checkout, not a pass.
shopt -s nullglob
rejects=(tests/reject/*.agda)
shopt -u nullglob
if (( ${#rejects[@]} == 0 )); then
  echo 'ERROR: no expected-rejection modules under tests/reject' >&2
  exit 1
fi
for file in "${rejects[@]}"; do
  rejected "$file"
  echo "PASS: rejected $(basename -- "$file" .agda) at its invalid declaration"
done

# 3. Control: the consent fixture with its invalid body replaced by a valid
#    one (an Epi from the token) must be reported as accepted.
control=_build/agda-control/ConsentFromToken.agda
mkdir -p "$(dirname -- "$control")"
sed -e 's/Σ (SoundWarrant {wℓ = lzero} Standpoint licensor (Consented x))$/Header x → Epi {wℓ = lzero} Standpoint licensor (Consented x)/' \
    -e '/(λ sw → SoundWarrant.warrant sw ≡ consent x)$/d' \
    -e 's/soundWarrant (consent x) (λ token → token) , refl$/consent-epi x/' \
    -e 's/using (SoundWarrant; soundWarrant)/using (Epi)/' \
    tests/reject/ConsentFromToken.agda >"$control"
if cmp -s "$control" tests/reject/ConsentFromToken.agda; then
  echo 'ERROR: control was not derived; tests/reject/ConsentFromToken.agda changed shape' >&2
  exit 1
fi
if ! "$prover" "${flags[@]}" -i "$(dirname -- "$control")" "$control" >"$logs/control.log" 2>&1; then
  cat "$logs/control.log"
  echo 'ERROR: control: the valid variant does not typecheck, so it cannot test the harness' >&2
  exit 1
fi
if rejected "$control" >/dev/null 2>&1; then
  echo 'ERROR: control: the harness did not report a fixture that typechecks' >&2
  exit 1
fi
echo 'PASS: control, a typechecking variant of ConsentFromToken is reported as accepted'
echo "PASS: Provenance.Warrant and all ${#rejects[@]} expected rejections"
