# AGENTS.md

## Project overview

A GitHub Action that wraps the `cosign` executable. The container image is
prebuilt and published to GHCR — it is not built on every action run.

Key files:

- `action.yml` — Action definition; the image tag here is the source of truth for the version
- `build-cosign.sh` — Runs inside the container build; pins cosign tag, commit, build date, and per-arch checksums for reproducible builds
- `Containerfile` — Multi-stage build: compiles cosign from source, copies binary into a slim Debian image
- `entrypoint.sh` — Action entrypoint; runs cosign with args, optionally iterating over `each` lines
- `scripts/check-cosign-update.sh` — Detects new cosign releases and updates `build-cosign.sh`, `Containerfile`, `action.yml`, and `README.md`

## Conventions

- Shell scripts use `set -eu` or `set -euo pipefail`
- Shell scripts start with an `# ABOUTME:` comment describing their purpose
- Container builds use `podman`, not `docker` (both locally and in CI)
- GHA workflows pin actions by commit hash with a version comment: `uses: actions/checkout@<sha> # v6.0.2`
- No third-party actions for PR creation or publishing — use `gh` CLI directly

## Versioning

- The action version lives in the `image:` line of `action.yml` (e.g., `v1.0.2`)
- The `version-check.yml` workflow blocks PRs that don't bump the version — **every PR must bump the image tag in `action.yml`** (except dependabot PRs)
- The `cd.yml` workflow publishes the container image and creates a GitHub release on merge to `main`
- Cosign updates bump the patch version; major/minor bumps are manual

## Reproducible builds

The cosign binary is built from source to match the official release exactly.
`build-cosign.sh` replicates goreleaser's `gomod.proxy=true` behavior by
building cosign as a dependency of a stub module. The build output is verified
against checksums from the official release assets.

## Testing

Run `podman build -t cosign-exec-action .` to verify the build is reproducible
(checksums match). CI does the same plus runs the action in simple and each modes.
