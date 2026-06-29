FROM docker.io/library/golang:1.26.3@sha256:2d6c80227255c3112a4d08e67ba98e58efd3846daf15d9d7d4c389565d881b1a as builder

COPY ./build-cosign.sh /build-cosign.sh
RUN /build-cosign.sh

FROM docker.io/library/debian:trixie-20260223-slim@sha256:1d3c811171a08a5adaa4a163fbafd96b61b87aa871bbc7aa15431ac275d3d430
LABEL com.github.actions.name="cosign-exec-action" \
    com.github.actions.description="A simple wrapper around the cosign executable for use as a step in GitHub Actions" \
    com.github.actions.icon="lock" \
    com.github.actions.color="blue" \
    maintainer="@samhclark" \
    org.opencontainers.image.url="https://github.com/samhclark/cosign-exec-action" \
    org.opencontainers.image.source="https://github.com/samhclark/cosign-exec-action" \
    org.opencontainers.image.documentation="https://github.com/samhclark/cosign-exec-action" \
    org.opencontainers.image.description="A simple wrapper around the cosign executable for use as a step in GitHub Actions"

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder /output/cosign /usr/local/bin/cosign
COPY --chmod=755 ./entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]