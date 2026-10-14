#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
#
# Warrant-level provenance records (spec/PROVENANCE-SPEC.adoc §7) against the
# Nickel contract formats/warrant.ncl:
#   1. every record under examples/provenance/ conforms;
#   2. the worked example in spec §7.6 conforms (the positive `sound` case),
#      the validator fixture's expected output conforms, and the contract's
#      rule registry matches the spec §7.5 table;
#   3. coverage: the metadata blocks under examples/ that declare a licence
#      and the blocks the records cite are the same set;
#   4. every fixture under tests/warrant/reject/ is refused, with the message
#      of the rule it names in its .expect file.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
nickel="${NICKEL:-nickel}"
contract=formats/warrant.ncl
out=_build/warrant
mkdir -p "$out"

"$nickel" --version
"$nickel" typecheck "$contract"

# Apply W.Records to a JSON file; stdout is the normalised export.
check() {
  "$nickel" export --format json <<<"let W = import \"$PWD/$contract\" in (import \"$PWD/$1\") | W.Records"
}

# 1. Positive set.  An empty set is a broken checkout, not a pass.
shopt -s nullglob
records=(examples/provenance/*.warrant.json)
rejects=(tests/warrant/reject/*.json)
shopt -u nullglob
if (( ${#records[@]} == 0 )); then
  echo 'ERROR: no records under examples/provenance' >&2
  exit 1
fi
count=0
for file in "${records[@]}"; do
  name="$(basename -- "$file" .warrant.json)"
  if ! check "$file" >"$out/$name.json" 2>"$out/$name.err"; then
    cat "$out/$name.err" >&2
    echo "ERROR: $file does not conform to $contract" >&2
    exit 1
  fi
  n="$("$nickel" export --format json <<<"std.array.length (import \"$PWD/$file\")")"
  count=$((count + n))
done
echo "PASS: ${#records[@]} files, $count records under examples/provenance conform"

# 2. The spec's worked example: the first JSON block after the §7.6 heading.
awk '/^=== 7\.6 /{s=1} s&&/^\[source,json\]/{j=1;next} j&&/^----$/{if(b)exit; b=1;next} b' \
  spec/PROVENANCE-SPEC.adoc >"$out/spec-7.6.json"
if [[ ! -s "$out/spec-7.6.json" ]]; then
  echo 'ERROR: no JSON example found under spec §7.6' >&2
  exit 1
fi
if ! check "$out/spec-7.6.json" >/dev/null 2>"$out/spec-7.6.err"; then
  cat "$out/spec-7.6.err" >&2
  echo 'ERROR: the spec §7.6 example does not conform' >&2
  exit 1
fi
levels="$("$nickel" export --format raw <<<"std.string.join \",\" (std.array.map (fun r => r.level) (import \"$PWD/$out/spec-7.6.json\"))")"
if [[ "$levels" != "sound,epi" ]]; then
  echo "ERROR: spec §7.6 example should be one sound and one epi record, got: $levels" >&2
  exit 1
fi
echo 'PASS: spec §7.6 example conforms (sound signature claim, epi consent claim)'

# 2a. The validator's output on its fixture (tests/warrant/fixture), which the
#     Haskell test suite requires the validator to reproduce exactly: the
#     signature chain at sound and the consent claim at epi, on one artefact.
fixture=tests/warrant/fixture/expected.json
if ! check "$fixture" >/dev/null 2>"$out/fixture.err"; then
  cat "$out/fixture.err" >&2
  echo "ERROR: $fixture does not conform" >&2
  exit 1
fi
claims="$("$nickel" export --format raw <<<"std.string.join \",\" (std.array.map (fun r => \"%{r.claim.kind}=%{r.level}\") (import \"$PWD/$fixture\"))")"
if [[ "$claims" != "signed-by=sound,signed-by=sound,licensed-under=epi,consented-for-training=epi" ]]; then
  echo "ERROR: $fixture should hold the chain at sound and licence and consent at epi, got: $claims" >&2
  exit 1
fi
echo "PASS: validator fixture conforms ($claims)"

# 2b. The rule registry in the contract and the §7.5 table agree: same rules,
#     same assumption text, same proof path and status.  A rule at "proven"
#     names a proof module that exists.
rules="$("$nickel" export --format raw <<<"let W = import \"$PWD/$contract\" in std.string.join \"\n\" (std.array.map (fun n => let r = W.rules.\"%{n}\" in \"%{n}|%{r.concludes}|%{r.assumption}|%{r.proof}|%{std.string.uppercase r.status}\") (std.record.fields W.rules))")"
spec_rules="$(awk '/^=== 7\.5 /{s=1;next} s&&/^=== /{exit} s&&/^\| `/' spec/PROVENANCE-SPEC.adoc |
  awk -F' [|] ' '{gsub(/^\| |`/,""); gsub(/`/,"",$0); print $1"|"$2"|"$4"|"$5"|"$6}')"
if [[ "$rules" != "$spec_rules" ]]; then
  diff -u --label 'formats/warrant.ncl rules' --label 'spec §7.5 table' <(echo "$rules") <(echo "$spec_rules") || true
  echo 'ERROR: the rule registry and the spec §7.5 table differ' >&2
  exit 1
fi
while IFS='|' read -r name _ _ proof status; do
  if [[ "$status" == PROVEN && ! -f "$proof" ]]; then
    echo "ERROR: rule $name is PROVEN but its proof $proof does not exist" >&2
    exit 1
  fi
done <<<"$rules"
echo "PASS: rule registry matches spec §7.5 ($(wc -l <<<"$rules") rule)"

# 3. Coverage.  A block is an AsciiDoc delimited block (---- or ....) with a
#    JSON "license"/"licence" key anywhere inside it; it is named by the line
#    of its opening delimiter.
# shellcheck disable=SC2016 # an awk program, not a shell expansion
git ls-files -z 'examples/*.adoc' | xargs -0 awk '
  FNR == 1 { inb = 0 }
  /^(----|\.\.\.\.)$/ {
    if (!inb) { inb = 1; start = FNR; hit = 0 } else { if (hit) print FILENAME ":" start; inb = 0 }
    next
  }
  inb && tolower($0) ~ /"licen[cs]e"[ \t]*:/ { hit = 1 }
' | sort -u >"$out/blocks.txt"
for file in "${records[@]}"; do
  "$nickel" export --format raw <<<"std.string.join \"\n\" (std.array.map (fun r => \"%{r.source.file}:%{std.to_string r.source.line}\") (import \"$PWD/$file\"))"
  echo
done | sed '/^$/d' | sort -u >"$out/cited.txt"
if [[ ! -s "$out/blocks.txt" ]]; then
  echo 'ERROR: found no licence-bearing metadata blocks under examples/' >&2
  exit 1
fi
if ! diff -u --label 'blocks under examples/' --label 'blocks cited by records' \
     "$out/blocks.txt" "$out/cited.txt"; then
  echo 'ERROR: records and licence-bearing example blocks differ; add or re-point records' >&2
  exit 1
fi
echo "PASS: coverage, $(wc -l <"$out/blocks.txt") licence-bearing example blocks each have records"

# 4. Expected rejections: refused, and refused for the named rule (not for a
#    parse error, a missing import or some other rule).
if (( ${#rejects[@]} == 0 )); then
  echo 'ERROR: no fixtures under tests/warrant/reject' >&2
  exit 1
fi
for file in "${rejects[@]}"; do
  name="$(basename -- "$file" .json)"
  expect="tests/warrant/reject/$name.expect"
  log="$out/reject-$name.log"
  if [[ ! -s "$expect" ]]; then
    echo "ERROR: $file has no $expect" >&2
    exit 1
  fi
  if check "$file" >"$log" 2>&1; then
    cat "$log"
    echo "ERROR: invalid record accepted: $name" >&2
    exit 1
  fi
  if ! grep -qF -- "$(<"$expect")" "$log"; then
    cat "$log"
    echo "ERROR: $name was refused, but not with: $(<"$expect")" >&2
    exit 1
  fi
  echo "PASS: rejected $name ($(<"$expect"))"
done
echo "PASS: warrant records, spec example, coverage and all ${#rejects[@]} expected rejections"
