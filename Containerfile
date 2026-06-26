# SPDX-License-Identifier: PMPL-1.0-or-later
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# Palimpsest License — documentation server.
#
# Serves the license texts, specifications, guides and examples as static
# files over HTTP. Deno-based (the repo's runtime per the language policy;
# Node/npm and Python are banned here), single-stage, non-root.
#
#   podman build -t palimpsest-license -f Containerfile .
#   podman run --rm -p 8000:8000 palimpsest-license
FROM denoland/deno:alpine

WORKDIR /app

# Public documentation surface — license texts, specs, guides, examples.
COPY legal/ ./legal/
COPY docs/ ./docs/
COPY spec/ ./spec/
COPY LICENSES/ ./LICENSES/
COPY examples/ ./examples/
COPY assets/ ./assets/
COPY .well-known/ ./.well-known/
COPY style.css README.adoc LICENSE ./

# Run as the image's non-root deno user and warm the std file-server cache
# so the container needs no network at runtime.
USER deno
RUN deno cache jsr:@std/http/file-server

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["deno", "eval", "--allow-net", "const r = await fetch('http://localhost:8000/'); Deno.exit(r.ok ? 0 : 1)"]

CMD ["deno", "run", "--allow-net", "--allow-read", "jsr:@std/http/file-server", ".", "--host", "0.0.0.0", "--port", "8000"]
