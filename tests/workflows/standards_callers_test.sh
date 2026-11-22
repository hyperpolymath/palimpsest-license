#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
#
# Test: thin reusable-workflow callers of <owner>/standards.
#
# Checks every `uses: <owner>/standards/.github/workflows/<file>@<ref>` line in
# .github/workflows/*.yml of a tree:
#   1. the owner is the expected one (EXPECTED_OWNER, default metadatastician);
#   2. the ref is a full 40-character lowercase hex commit SHA;
#   3. .github/workflows/actions.lock lists `<owner>/standards@<sha>` under that
#      caller file and has a matching dependencies entry;
#   4. the caller does not use `secrets: inherit`;
#   5. when STANDARDS_DIR (a git checkout of standards, or a directory holding
#      .github/workflows/) is given, the callee file exists at the pinned ref,
#      declares every secret the caller passes, and every secret it declares
#      `required: true` is passed.
#
# Usage:
#   tests/workflows/standards_callers_test.sh            check this repo's tree
#   tests/workflows/standards_callers_test.sh --selftest run the fixture cases
#   tests/workflows/standards_callers_test.sh --tree DIR check another tree
# Env: EXPECTED_OWNER, STANDARDS_DIR. Needs bash, awk, grep, sed.
# Exit: 0 clean, 1 violation(s) found (or a fixture case misbehaved), 2 usage.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXPECTED_OWNER="${EXPECTED_OWNER:-metadatastician}"
STANDARDS_DIR="${STANDARDS_DIR:-}"

# callee_text <file> <ref>: print the callee workflow at <ref>. STANDARDS_DIR is
# either a git checkout of standards (read at <ref>, so each caller is judged
# against the commit it pins) or a plain directory holding .github/workflows/.
callee_text() {
  if [ -e "$STANDARDS_DIR/.git" ]; then
    git -C "$STANDARDS_DIR" show "$2:.github/workflows/$1" 2>/dev/null
  elif [ -f "$STANDARDS_DIR/.github/workflows/$1" ]; then
    cat "$STANDARDS_DIR/.github/workflows/$1"
  else
    return 1
  fi
}

# check_tree <root>: print "ERROR: ..." lines, return non-zero if any.
check_tree() {
  local root="$1" wf="$1/.github/workflows" lock="$1/.github/workflows/actions.lock"
  local bad=0 found=0 file name
  [ -d "$wf" ] || { echo "ERROR: no .github/workflows in $root"; return 1; }
  for file in "$wf"/*.yml "$wf"/*.yaml; do
    [ -f "$file" ] || continue
    name=".github/workflows/$(basename "$file")"
    # one record per standards caller job: "<uses>|<secret keys, space separated>|<inherit 0/1>"
    local rec
    while IFS= read -r rec; do
      [ -n "$rec" ] || continue
      found=$((found + 1))
      local uses="${rec%%|*}" rest="${rec#*|}"
      local keys="${rest%%|*}" inherit="${rest##*|}"
      local owner="${uses%%/*}" callee ref
      callee="$(printf '%s' "$uses" | sed -E 's#^[^/]+/standards/\.github/workflows/([^@]+)@.*$#\1#')"
      ref="${uses##*@}"
      if [ "$owner" != "$EXPECTED_OWNER" ]; then
        echo "ERROR: $name: calls $owner/standards, expected $EXPECTED_OWNER/standards"; bad=1
      fi
      if ! printf '%s' "$ref" | grep -Eq '^[0-9a-f]{40}$'; then
        echo "ERROR: $name: ref '$ref' is not a 40-character lowercase hex commit SHA"; bad=1
        continue
      fi
      if [ "$inherit" = 1 ]; then
        echo "ERROR: $name: uses 'secrets: inherit'; pass named secrets instead"; bad=1
      fi
      if [ ! -f "$lock" ]; then
        echo "ERROR: $name: no actions.lock to match the pin $owner/standards@$ref"; bad=1
      else
        if ! awk -v key="'$name':" -v want="- '$owner/standards@$ref'" '
              /^[^ ]/ { insec = ($0 ~ /^workflows:/) ; inblk = 0; next }
              insec && $0 ~ /^    '"'"'/ { inblk = (index($0, key) == 5); next }
              insec && inblk { t = $0; sub(/^[ \t]+/, "", t); if (t == want) ok = 1 }
              END { exit ok ? 0 : 1 }' "$lock"; then
          echo "ERROR: $name: actions.lock has no '$owner/standards@$ref' under $name"; bad=1
        fi
        if ! grep -Fxq "    '$owner/standards@$ref':" "$lock"; then
          echo "ERROR: $name: actions.lock has no dependencies entry for $owner/standards@$ref"; bad=1
        fi
      fi
      if [ -n "$STANDARDS_DIR" ]; then
        local text declared k
        if ! text="$(callee_text "$callee" "$ref")"; then
          echo "ERROR: $name: callee $callee not found in STANDARDS_DIR at $ref"; bad=1
        else
          # one line per declared secret: "NAME required" or "NAME optional"
          declared="$(printf '%s\n' "$text" | awk '
            function emit() { if (cur != "") print cur, (req ? "required" : "optional"); cur = ""; req = 0 }
            /^  workflow_call:/ { inwc = 1; next }
            inwc && /^  [^ ]/ { emit(); inwc = 0 }
            inwc && /^    secrets:/ { insec = 1; next }
            inwc && insec && /^    [^ ]/ { emit(); insec = 0 }
            inwc && insec && /^      [A-Za-z0-9_]+:/ { emit(); cur = $1; sub(/:$/, "", cur); next }
            inwc && insec && cur != "" && /^        required:[ \t]*true/ { req = 1 }
            END { emit() }')"
          for k in $keys; do
            if ! printf '%s\n' "$declared" | grep -q "^$k "; then
              echo "ERROR: $name: passes secret $k, which $callee does not declare"; bad=1
            fi
          done
          while IFS= read -r k; do
            [ -n "$k" ] || continue
            case " $keys " in *" $k "*) ;; *) echo "ERROR: $name: $callee requires secret $k, which the caller does not pass"; bad=1 ;; esac
          done < <(printf '%s\n' "$declared" | awk '$2 == "required" { print $1 }')
        fi
      fi
    done < <(awk '
      function flush() {
        if (uses != "") print uses "|" keys "|" inh
        uses = ""; keys = ""; inh = 0; insec = 0
      }
      /^jobs:/ { injobs = 1; next }
      !injobs { next }
      /^  [A-Za-z0-9_-]+:[ \t]*$/ { flush(); next }
      /^    uses:[ \t]*/ {
        v = $0; sub(/^    uses:[ \t]*/, "", v); sub(/[ \t]+#.*$/, "", v); gsub(/["\047]/, "", v)
        if (v ~ /^[^\/ ]+\/standards\/\.github\/workflows\//) uses = v
        next
      }
      /^    secrets:[ \t]*inherit/ { inh = 1; insec = 0; next }
      /^    secrets:[ \t]*$/ { insec = 1; next }
      insec && /^    [^ #]/ { insec = 0 }
      insec && /^      [A-Za-z0-9_]+:/ { k = $1; sub(/:$/, "", k); keys = keys (keys == "" ? "" : " ") k }
      END { flush() }' "$file")
  done
  if [ "$found" -eq 0 ]; then
    echo "ERROR: no <owner>/standards reusable callers found under $wf"; bad=1
  fi
  return "$bad"
}

# --selftest: each fixture dir is <case>/tree/ plus an optional <case>/callee/.
# Case names containing -pass- must be silent (exit 0), -fail- must fire.
selftest() {
  local FIX="$HERE/fixtures/standards-callers" pass=0 fail=0 d name out rc
  [ -d "$FIX" ] || { echo "fixtures not found: $FIX" >&2; exit 2; }
  for d in "$FIX"/*/; do
    name="$(basename "$d")"
    out=""; rc=0
    if [ -d "$d/callee" ]; then
      out="$(STANDARDS_DIR="$d/callee" check_tree "$d/tree" 2>&1)" || rc=$?
    else
      out="$(STANDARDS_DIR="" check_tree "$d/tree" 2>&1)" || rc=$?
    fi
    case "$name" in
      *-pass-*)
        if [ "$rc" -eq 0 ] && [ -z "$out" ]; then echo "PASS: $name (silent)"; pass=$((pass + 1))
        else echo "FAIL: $name should be silent (exit $rc)"; printf '%s\n' "$out" | sed 's/^/    /'; fail=$((fail + 1)); fi ;;
      *-fail-*)
        if [ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q '^ERROR'; then echo "PASS: $name (fired)"; pass=$((pass + 1))
        else echo "FAIL: $name should fire (exit $rc)"; printf '%s\n' "$out" | sed 's/^/    /'; fail=$((fail + 1)); fi ;;
      *) echo "FAIL: $name: case name must contain -pass- or -fail-"; fail=$((fail + 1)) ;;
    esac
  done
  echo
  echo "standards-callers fixtures: $pass passed, $fail failed"
  [ "$fail" -eq 0 ]
}

case "${1:-}" in
  --selftest) selftest ;;
  --tree) [ -n "${2:-}" ] || { echo "usage: $0 --tree DIR" >&2; exit 2; }
          check_tree "$2" ;;
  "") check_tree "$HERE/../.." ;;
  *) echo "usage: $0 [--selftest | --tree DIR]" >&2; exit 2 ;;
esac
