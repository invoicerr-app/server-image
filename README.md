# invoicerr-server-image

The base Docker image invoicerr's product image builds on: `nginx:bookworm` plus Debian's
`chromium` (used by the backend's Puppeteer PDF rendering) plus a Node.js runtime.

## Supported architectures

`linux/amd64` and `linux/arm64` only. `linux/arm/v7` (32-bit ARM) is not built: Node.js stopped
publishing `linux-armv7l` binaries starting with Node 24 (upstream's own `BUILDING.md` lists armv7
as "Experimental, Downgraded as of Node.js 24"). Self-hosters on a 32-bit ARM board (Raspberry Pi
2/3/Zero running the 32-bit OS) need a 64-bit OS on the same board to keep using this image; any
Pi capable of running 64-bit Debian (Pi 3 and newer) runs the `linux/arm64` image without changes.

## Image tags

- `:latest` moves on every release AND on the weekly scheduled rebuild (see below). invoicerr's
  own Dockerfile builds `FROM ghcr.io/invoicerr-app/server-image:latest`, so this is the tag that
  matters for the product image.
- `:<version>` (e.g. `:v1.0.7`) is published alongside `:latest` on every GitHub release, and never
  moves afterwards.
- `:scheduled-<YYYYMMDD>` is published alongside `:latest` on every scheduled rebuild, so a specific
  weekly build can still be pulled and inspected after `:latest` has moved again.
- `:<branch-name>` is published by a manual `workflow_dispatch` run on a branch (slashes in the
  branch name become dashes). This never touches `:latest` and is the safe way to test a change
  before opening a release.

## Rebuild schedule

`.github/workflows/docker-publish.yml` rebuilds and publishes to `:latest` automatically every
Monday at 03:00 UTC (`schedule: cron: "0 3 * * 1"`), in addition to the existing triggers (a GitHub
release, or a manual `workflow_dispatch`). This exists so Debian security updates, chromium
included, reach `:latest` within a week even when nothing else changed and no release was cut.
`apt-get upgrade` runs on every build (not just `apt-get install`) so the image always carries the
Debian security pocket's latest packages at build time, not just whatever versions the explicitly
listed packages' dependencies happened to resolve to.

## Triggering a rebuild manually

Actions tab, "Publish Docker Image to GitHub Container Registry", "Run workflow". On the default
branch this publishes to `:latest` the same way the weekly cron does. On any other branch it
publishes to `:<branch-name>` only, which is the way to test a change without touching `:latest`.
