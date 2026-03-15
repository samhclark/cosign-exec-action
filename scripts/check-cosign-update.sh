#!/usr/bin/env bash
# ABOUTME: Checks for new cosign releases and updates build-cosign.sh, action.yml, Containerfile, and README.md

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_SCRIPT="${REPO_ROOT}/build-cosign.sh"
ACTION_YML="${REPO_ROOT}/action.yml"
CONTAINERFILE="${REPO_ROOT}/Containerfile"
README_MD="${REPO_ROOT}/README.md"

# --- Read current version ---

current_tag=$(grep '^tag=' "$BUILD_SCRIPT" | head -1 | cut -d'"' -f2)
echo "Current cosign version: ${current_tag}"

# --- Query latest release ---

latest_tag=$(gh api repos/sigstore/cosign/releases/latest --jq .tag_name)
echo "Latest cosign version:  ${latest_tag}"

if [[ "$current_tag" == "$latest_tag" ]]; then
    echo "Already up to date."
    exit 0
fi

echo "New version available: ${current_tag} -> ${latest_tag}"

# --- Fetch commit hash (dereference annotated tag) ---

ref_response=$(gh api "repos/sigstore/cosign/git/ref/tags/${latest_tag}")
ref_type=$(echo "$ref_response" | jq -r '.object.type')
ref_sha=$(echo "$ref_response" | jq -r '.object.sha')

if [[ "$ref_type" == "tag" ]]; then
    # Annotated tag: dereference to get the commit
    commit_sha=$(gh api "repos/sigstore/cosign/git/tags/${ref_sha}" --jq '.object.sha')
else
    # Lightweight tag: already points to commit
    commit_sha="$ref_sha"
fi

echo "Commit: ${commit_sha}"

# --- Fetch build date ---

build_date=$(gh api "repos/sigstore/cosign/git/commits/${commit_sha}" --jq '.committer.date')
echo "Build date: ${build_date}"

# --- Fetch checksums ---

checksums_url=$(gh api "repos/sigstore/cosign/releases/latest" \
    --jq '.assets[] | select(.name == "cosign_checksums.txt") | .browser_download_url')

if [[ -z "$checksums_url" ]]; then
    echo "ERROR: Could not find cosign_checksums.txt in release assets" >&2
    exit 1
fi

checksums_content=$(curl -sSfL "$checksums_url")

amd64_checksum=$(echo "$checksums_content" | grep -E '\bcosign-linux-amd64$' | awk '{print $1}')
arm64_checksum=$(echo "$checksums_content" | grep -E '\bcosign-linux-arm64$' | awk '{print $1}')

if [[ -z "$amd64_checksum" || -z "$arm64_checksum" ]]; then
    echo "ERROR: Could not extract checksums from release" >&2
    echo "amd64: ${amd64_checksum:-MISSING}" >&2
    echo "arm64: ${arm64_checksum:-MISSING}" >&2
    exit 1
fi

echo "amd64 checksum: ${amd64_checksum}"
echo "arm64 checksum: ${arm64_checksum}"

# --- Fetch Go version from cosign's Dockerfile ---

go_version=$(gh api "repos/sigstore/cosign/contents/Dockerfile?ref=${latest_tag}" --jq '.content' \
    | base64 -d \
    | grep '^FROM golang:' \
    | sed 's/FROM golang://')

if [[ -z "$go_version" ]]; then
    echo "ERROR: Could not extract Go version from cosign's Dockerfile" >&2
    exit 1
fi

echo "Go version: ${go_version}"

go_digest=$(skopeo inspect --format '{{.Digest}}' "docker://docker.io/library/golang:${go_version}")

if [[ -z "$go_digest" ]]; then
    echo "ERROR: Could not fetch digest for golang:${go_version}" >&2
    exit 1
fi

echo "Go digest: ${go_digest}"

# --- Update build-cosign.sh ---

sed -i "s/^tag=\".*\"/tag=\"${latest_tag}\"/" "$BUILD_SCRIPT"
sed -i "s/^commit=\".*\"/commit=\"${commit_sha}\"/" "$BUILD_SCRIPT"
sed -i "s/^build_date=\".*\"/build_date=\"${build_date}\"/" "$BUILD_SCRIPT"
sed -i "s/^amd64_checksum=\".*\"/amd64_checksum=\"${amd64_checksum}\"/" "$BUILD_SCRIPT"
sed -i "s/^arm64_checksum=\".*\"/arm64_checksum=\"${arm64_checksum}\"/" "$BUILD_SCRIPT"

echo "Updated build-cosign.sh"

# --- Update Go version in Containerfile ---

sed -i "s|^FROM docker.io/library/golang:.*|FROM docker.io/library/golang:${go_version}@${go_digest} as builder|" "$CONTAINERFILE"

echo "Updated Containerfile Go version: golang:${go_version}@${go_digest}"

# --- Bump action version to match cosign's semver change ---

current_image_tag=$(grep 'image: docker://' "$ACTION_YML" | sed 's/.*:\(v[0-9.]*\)/\1/')
IFS='.' read -r cur_cosign_major cur_cosign_minor _ <<< "${current_tag#v}"
IFS='.' read -r new_cosign_major new_cosign_minor _ <<< "${latest_tag#v}"
IFS='.' read -r action_major action_minor action_patch <<< "${current_image_tag#v}"

if [[ "$new_cosign_major" != "$cur_cosign_major" ]]; then
    new_image_tag="v$((action_major + 1)).0.0"
elif [[ "$new_cosign_minor" != "$cur_cosign_minor" ]]; then
    new_image_tag="v${action_major}.$((action_minor + 1)).0"
else
    new_image_tag="v${action_major}.${action_minor}.$((action_patch + 1))"
fi

sed -i "s|${current_image_tag}|${new_image_tag}|" "$ACTION_YML"

echo "Bumped action.yml image tag: ${current_image_tag} -> ${new_image_tag}"

# --- Update README.md ---

sed -i "s|cosign ${current_tag}](https://github.com/sigstore/cosign/releases/tag/${current_tag})|cosign ${latest_tag}](https://github.com/sigstore/cosign/releases/tag/${latest_tag})|" "$README_MD"

echo "Updated README.md"

# --- Summary ---

echo ""
echo "=== Update Summary ==="
echo "cosign:    ${current_tag} -> ${latest_tag}"
echo "commit:    ${commit_sha}"
echo "build:     ${build_date}"
echo "amd64:     ${amd64_checksum}"
echo "arm64:     ${arm64_checksum}"
echo "golang:    ${go_version}@${go_digest}"
echo "image tag: ${current_image_tag} -> ${new_image_tag}"
