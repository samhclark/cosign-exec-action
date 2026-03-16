# cosign-exec-action

![CI](https://github.com/samhclark/cosign-exec-action/actions/workflows/ci.yml/badge.svg)

Bundles [cosign v3.0.5](https://github.com/sigstore/cosign/releases/tag/v3.0.5).

A simple wrapper around the `cosign` executable for use as a step in GitHub
Actions. The container image is prebuilt and pulled from
[GitHub Container Registry](https://ghcr.io/samhclark/cosign-exec-action)
rather than built on every action run.

## Inputs

| Input | Required | Default | Description |
| ----- | -------- | ------- | ----------- |
| `args` | yes | `version` | Arguments passed to `cosign` |
| `each` | no | — | Newline-separated list of values. Each line is substituted for `{}` in `args` and `cosign` is called once per line. `args` must contain `{}` when `each` is set. |
| `registry` | no | `ghcr.io` | Container registry hostname to authenticate to. Required when `registry-token` is set. |
| `registry-username` | no | `github.repository_owner` | Username for registry authentication. |
| `registry-token` | no | — | Token for authenticating to the container registry. If set, runs `cosign login` before the main command. |

## Usage

### Verify a single image

```yaml
- name: Verify image
  uses: samhclark/cosign-exec-action@v1
  with:
    args: >-
      verify
      --certificate-identity=https://github.com/org/repo/.github/workflows/release.yml@refs/heads/main
      --certificate-oidc-issuer=https://token.actions.githubusercontent.com
      docker.io/org/image@sha256:<digest>
```

### Sign an image (keyless)

Sign with Sigstore's keyless flow using GitHub OIDC. Requires `id-token: write`
and `packages: write` permissions.

```yaml
- name: Sign image
  uses: samhclark/cosign-exec-action@v1
  with:
    args: 'sign ghcr.io/org/image@sha256:<digest> --yes'
    registry-token: ${{ secrets.GITHUB_TOKEN }}
```

### Verify multiple images

Use `each` to call `cosign` once per image, substituting `{}` in `args`:

```yaml
- name: Verify images
  uses: samhclark/cosign-exec-action@v1
  with:
    args: >-
      verify
      --certificate-identity=https://github.com/org/repo/.github/workflows/release.yml@refs/heads/main
      --certificate-oidc-issuer=https://token.actions.githubusercontent.com
      {}
    each: |
      docker.io/org/image1@sha256:<digest1>
      docker.io/org/image2@sha256:<digest2>
```

## Local testing

```bash
podman build -t cosign-exec-action .

# Simple mode
podman run --env INPUT_ARGS=version --rm cosign-exec-action

# Each mode
podman run \
  --env INPUT_ARGS="{}" \
  --env INPUT_EACH=version \
  --rm cosign-exec-action
```

## Releasing

The [`cd.yml`](./.github/workflows/cd.yml) workflow publishes a new container
image, signs it with cosign (keyless via Sigstore), and creates a GitHub release
whenever a pull request is merged into `main`. To release a new version, bump the image tag in
[`action.yml`](./action.yml) as part of your pull request. The
[`version-check.yml`](./.github/workflows/version-check.yml) workflow will
block merging if the version has not been incremented.
