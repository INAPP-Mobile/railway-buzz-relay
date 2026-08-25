# syntax=docker/dockerfile:1.7
#
# Railway build for Buzz Relay — single-stage cargo build.
# Clones upstream buzz repo and compiles from source.

FROM rust:1.96.1-bookworm AS builder
WORKDIR /build
RUN apt-get update && apt-get install -y git ca-certificates
RUN git clone --depth 1 --branch main https://github.com/block/buzz.git .
RUN cargo build --release -p buzz-relay -p buzz-admin -p buzz-pair-relay

FROM node:24-bookworm-slim AS web-builder
WORKDIR /build
RUN corepack enable
COPY --from=builder /build/package.json /build/pnpm-lock.yaml /build/pnpm-workspace.yaml ./
COPY --from=builder /build/patches/ patches/
COPY --from=builder /build/web/package.json web/
COPY --from=builder /build/admin-web/package.json admin-web/
RUN pnpm install --frozen-lockfile --filter buzz-web --filter buzz-admin-web
COPY --from=builder /build/web/ web/
COPY --from=builder /build/admin-web/ admin-web/
RUN pnpm -C web build && pnpm -C admin-web build

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates curl git openssl \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -r -U -d /var/lib/buzz -s /bin/sh buzz

COPY --from=web-builder /build/web/dist /srv/buzz/web
COPY --from=web-builder /build/admin-web/dist /srv/buzz/admin-web

ENV BUZZ_WEB_DIR=/srv/buzz/web \
    BUZZ_ADMIN_WEB_DIR=/srv/buzz/admin-web \
    PORT=3000 \
    BUZZ_BIND_ADDR=0.0.0.0:3000 \
    BUZZ_HEALTH_PORT=8080 \
    BUZZ_METRICS_PORT=9102 \
    BUZZ_GIT_REPO_PATH=/data/git \
    RUST_LOG=buzz_relay=info,buzz_db=info,buzz_auth=info,buzz_pubsub=info,tower_http=info

EXPOSE 8080 3000 9102

RUN mkdir -p /data/git && chown buzz:buzz /data/git

COPY relay/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

HEALTHCHECK --interval=10s --timeout=3s --retries=12 --start-period=30s \
  CMD bash -ec 'exec 3<>/dev/tcp/127.0.0.1/8080; printf "GET /_readiness HTTP/1.1\r\nHost: 127.0.0.1\r\nConnection: close\r\n\r\n" >&3; grep -q "200 OK" <&3'

WORKDIR /var/lib/buzz

COPY --from=builder /build/target/release/buzz-relay /usr/local/bin/buzz-relay
COPY --from=builder /build/target/release/buzz-admin /usr/local/bin/buzz-admin
COPY --from=builder /build/target/release/buzz-pair-relay /usr/local/bin/buzz-pair-relay

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
