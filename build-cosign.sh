#!/usr/bin/env bash

set -eu

tag="v3.1.3"
commit="11926fa5bbbbde47e88fc006b625a17769b743b2"
build_date="2026-08-05T23:43:27Z"

amd64_checksum="4629c757b7618056f8ddd7e2625ae9fdd94c0372a65049520bc7d9df9efc7f71"
arm64_checksum="c5d324e091826b0d7a78eb16fef316450b4eb9aaec045611c08ba06f5e73220a"

declare -A binary_checksums
binary_checksums['amd64']="$amd64_checksum"
binary_checksums['x64']="$amd64_checksum"
binary_checksums['x86_64']="$amd64_checksum"

binary_checksums['aarch64']="$arm64_checksum"
binary_checksums['arm64']="$arm64_checksum"

log_info() {
    1>&2 echo "[INFO]: $*"
}

log_fatal_die() {
    1>&2 echo "[FATAL]: $*"
    exit 1
}

# Replicate goreleaser's gomod.proxy=true behaviour: build cosign as a
# *dependency* of a stub module (not as the main module). This causes Go to
# embed the h1: module hash and omit VCS stamps, matching the official release.
mkdir /build 
cd /build
go mod init cosign-repro 
GOPROXY=https://proxy.golang.org go get github.com/sigstore/cosign/v3/cmd/cosign@${tag}

# Build and install cosign
CGO_ENABLED=0 go build -trimpath \
    -ldflags "-buildid= \
        -X sigs.k8s.io/release-utils/version.gitVersion=${tag} \
        -X sigs.k8s.io/release-utils/version.gitCommit=${commit} \
        -X sigs.k8s.io/release-utils/version.gitTreeState=clean \
        -X sigs.k8s.io/release-utils/version.buildDate=${build_date}" \
    -o /output/cosign \
    github.com/sigstore/cosign/v3/cmd/cosign

/output/cosign version
sha256sum /output/cosign
printf "%s /output/cosign\n" "${binary_checksums[$(uname -m)]}" > cosign.sha256
if sha256sum --check cosign.sha256; then
    log_info "Build is reproducible, checksums matched."
else 
    log_fatal_die "Produced binary did not match expected checksum"
fi

