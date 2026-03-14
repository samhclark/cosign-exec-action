FROM docker.io/library/golang:1.26.1-trixie@sha256:ab8c4944b04c6f97c2b5bffce471b7f3d55f2228badc55eae6cce87596d5710b as builder

COPY ./install-cosign.sh /install-cosign.sh

# Bootstrap and configure HTTPS
RUN echo 'Acquire::https::Verify-Peer "false";' > /etc/apt/apt.conf.d/99_tmp_ssl-verify-off.conf && \
    sed -i'.bak' 's|http://deb.debian.org|https://deb.debian.org|g' /etc/apt/sources.list.d/debian.sources && \
    apt-get update && \
    apt-get install -y ca-certificates && \
    rm -rf /etc/apt/apt.conf.d/99_tmp_ssl-verify-off.conf

RUN apt-get update && \
    apt-get install -y jq && \
    chmod +x /install-cosign.sh && \
    /install-cosign.sh /tmp /

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

COPY --from=builder /cosign /usr/local/bin/cosign

ENTRYPOINT [ "/usr/local/bin/cosign" ]
CMD [ "version" ]