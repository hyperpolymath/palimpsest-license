#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
#
# Regenerate poem.txt.provenance.json: a two-entry Ed25519 signature chain
# over poem.txt (author, then licensor) and the claims the fixture makes.
# Fresh keys are generated in a temporary directory and discarded, so no
# private key is ever written to the tree; re-running changes every key and
# signature, and expected.json must then be regenerated with the validator:
#   cabal run palimpsest-validate -- provenance <this dir>/poem.txt --json
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
artefact=poem.txt
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

hex() { od -An -tx1 | tr -d ' \n'; }
sha256() { sha256sum | cut -d' ' -f1; }

# The signed record: the artefact, its hash, a timestamp and the previous
# entry's record hash.  The validator rebuilds exactly these bytes.
message() { # timestamp parent
  printf 'PMPL-SIG/1\nartefact: %s\nartefact-sha256: %s\ntimestamp: %s\nparent: %s\n' \
    "$artefact" "$digest" "$1" "$2"
}

entry() { # standpoint timestamp parent
  local who=$1 ts=$2 parent=$3 pk sig
  openssl genpkey -algorithm ed25519 -out "$tmp/$who.pem" 2>/dev/null
  pk="$(openssl pkey -in "$tmp/$who.pem" -pubout -outform DER | tail -c 32 | hex)"
  message "$ts" "$parent" >"$tmp/$who.msg"
  sig="$(openssl pkeyutl -sign -inkey "$tmp/$who.pem" -rawin -in "$tmp/$who.msg" | hex)"
  printf '    {\n      "standpoint": "%s",\n      "algorithm": "ed25519",\n      "pk": "%s",\n      "artefact_sha256": "%s",\n      "timestamp": "%s",\n      "parent": %s,\n      "signature": "%s"\n    }' \
    "$who" "$pk" "$digest" "$ts" "$( [[ $parent == - ]] && echo null || echo "\"$parent\"" )" "$sig"
}

digest="$(sha256 <"$artefact")"
{
  printf '{\n  "artefact": "%s",\n  "chain": [\n' "$artefact"
  entry author 2026-10-14T00:00:00Z -
  printf ',\n'
  entry licensor 2026-10-14T00:05:00Z "$(sha256 <"$tmp/author.msg")"
  printf '\n  ],\n'
  cat <<'CLAIMS'
  "claims": [
    {
      "kind": "licensed-under",
      "standpoint": "licensor",
      "subject": "PMPL-1.0-or-later",
      "statement": "the licensor offers poem.txt under PMPL-1.0-or-later"
    },
    {
      "kind": "consented-for-training",
      "standpoint": "licensor",
      "subject": "poem.txt",
      "statement": "consent to train on poem.txt was given"
    }
  ]
}
CLAIMS
} >"$artefact.provenance.json"
echo "wrote $artefact.provenance.json"
