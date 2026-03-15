#!/usr/bin/env bash

set -eu

tag="v3.0.5"
commit="479147a4df05f31be48aeb2b3a9d32dfc35ba877"
build_date="2026-02-19T18:42:21Z"

declare -A binary_checksums
binary_checksums['amd64']='db15cc99e6e4837daabab023742aaddc3841ce57f193d11b7c3e06c8003642b2'
binary_checksums['x64']='db15cc99e6e4837daabab023742aaddc3841ce57f193d11b7c3e06c8003642b2'
binary_checksums['x86_64']='db15cc99e6e4837daabab023742aaddc3841ce57f193d11b7c3e06c8003642b2'

binary_checksums['aarch64']='d098f3168ae4b3aa70b4ca78947329b953272b487727d1722cb3cb098a1a20ab'
binary_checksums['arm64']='d098f3168ae4b3aa70b4ca78947329b953272b487727d1722cb3cb098a1a20ab'

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

