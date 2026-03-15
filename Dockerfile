FROM docker.io/library/golang:1.25.7-trixie@sha256:2b174ffcf56c7ad0c47d30d2630693265639ddf2a5141149c2da34db921791b4 as builder

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

COPY --from=builder /output/cosign /usr/local/bin/cosign
COPY --chmod=755 ./entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]