#!/usr/bin/env bash

set -eu

tag="v3.0.6"
commit="f1ad3ee952313be5d74a49d67ba0aa8d0d5e351f"
build_date="2026-04-06T21:39:58Z"

amd64_checksum="c956e5dfcac53d52bcf058360d579472f0c1d2d9b69f55209e256fe7783f4c74"
arm64_checksum="bedac92e8c3729864e13d4a17048007cfafa79d5deca993a43a90ffe018ef2b8"

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

