# invoicerr-server-image

Base image invoicerr's product image builds on: `nginx:bookworm` + Debian's `chromium` (PDF
rendering) + Node.js.

## Architectures

`linux/amd64` and `linux/arm64`. Not `linux/arm/v7`: Node 24 ships no `linux-armv7l` build. A 32-bit
Pi needs a 64-bit OS to run the `arm64` image.

## Tags

`:latest` is what invoicerr's Dockerfile builds `FROM`. It moves on every release and on the weekly
rebuild. `:<version>` is pinned, published alongside `:latest` on release. `:scheduled-<YYYYMMDD>`
is the weekly rebuild's own pin. `:<branch-name>` comes from a manual `workflow_dispatch` on a
branch and never touches `:latest`.

## Weekly rebuild

Monday 03:00 UTC, so Debian/chromium security patches reach `:latest` without a release.

## Manual rebuild

Actions tab -> "Publish Docker Image to GitHub Container Registry" -> "Run workflow". On the
default branch this moves `:latest`; on any other branch it only publishes `:<branch-name>`.
