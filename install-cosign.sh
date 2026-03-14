#!/usr/bin/env bash

set -eu

tempdir="$1" # Something like $RUNNER_TEMP
outdir="$2"  # Where to copy the binary

tag="v3.0.5"
commit="479147a4df05f31be48aeb2b3a9d32dfc35ba877"

log_info() {
    1>&2 echo "[INFO]: $*"
}

log_fatal_die() {
    1>&2 echo "[FATAL]: $*"
    exit 1
}

[[ -n "$tempdir" && -n "$outdir" ]] || log_fatal_die "Usage: $0 <tempdir> <outdir>"


# Clone the repo
trap 'rm -rf "${tempdir}/cosign"' EXIT
git clone --branch "${tag}" --depth 1 https://github.com/sigstore/cosign.git "${tempdir}/cosign"
cd "${tempdir}/cosign"

# Verify the tag and commit
current_commit=$(git rev-parse HEAD)
if [ "${current_commit}" = "${commit}" ]; then
    log_info "Commit hash verified: ${current_commit}"
else
    log_fatal_die "Commmit hash mismatch!"
fi

# Build and install cosign
go install ./cmd/cosign
cp "$(go env GOPATH)/bin/cosign" "${outdir}/cosign"
log_info "Installed cosign from commit $(${outdir}/cosign version --json | jq -r '.gitCommit')"
