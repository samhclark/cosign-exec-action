FROM docker.io/library/golang:1.27.3@sha256:e519d3b0a5b285e5aa53ab9eef02bc6bbb9cb04608389b743a136a9ce75f0d1e as builder

COPY ./build-cosign.sh /build-cosign.sh
RUN /build-cosign.sh

FROM docker.io/library/debian:trixie-20260803-slim@sha256:3a39a0592364683e6bab97937b72cad5a8fa6dcbbee90edb3bb48c7f8e94f258
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