# cosign-exec-action

![CI](https://github.com/samhclark/cosign-exec-action/actions/workflows/ci.yml/badge.svg)

A simple wrapper around the `cosign` executable for use as a step in GitHub
Actions. The container image is prebuilt and pulled from
[GitHub Container Registry](https://ghcr.io/samhclark/cosign-exec-action)
rather than built on every action run.

## Inputs

| Input | Required | Default | Description |
| ----- | -------- | ------- | ----------- |
| `args` | yes | `version` | Arguments passed to `cosign` |
| `each` | no | — | Newline-separated list of values. Each line is substituted for `{}` in `args` and `cosign` is called once per line. `args` must contain `{}` when `each` is set. |

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
image and creates a GitHub release whenever a pull request is merged into
`main`. To release a new version, bump the image tag in
[`action.yml`](./action.yml) as part of your pull request. The
[`version-check.yml`](./.github/workflows/version-check.yml) workflow will
block merging if the version has not been incremented.
