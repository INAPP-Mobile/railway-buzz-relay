# syntax=docker/dockerfile:1.7
#
# Railway multi-stage build for Buzz Relay.
# Clones the upstream buzz repo from GitHub and builds from source.
# This replaces the private ghcr.io/block/buzz:main image with a
# reproducible source build.
#
# Build args (all optional, defaults match upstream):
#   RUST_VERSION=1.95
#   NODE_VERSION=24
#   DEBIAN_VERSION=bookworm
#   BUZZ_REPO=https://github.com/block/buzz.git
#   BUZZ_BRANCH=main

ARG RUST_VERSION=1.95
ARG NODE_VERSION=24
ARG DEBIAN_VERSION=bookworm
ARG BUZZ_REPO=https://github.com/block/buzz.git
ARG BUZZ_BRANCH=main

# ─── Stage 1: cargo-chef base ───────────────────────────────────────────────
FROM rust:${RUST_VERSION}-${DEBIAN_VERSION} AS chef
ENV CARGO_HTTP_CAINFO=/etc/ssl/certs/ca-certificates.crt
RUN cargo install cargo-chef --locked --version 0.1.71
WORKDIR /build

# ─── Stage 2: clone upstream buzz repo ───────────────────────────────────────
FROM rust:${RUST_VERSION}-${DEBIAN_VERSION} AS src
ARG BUZZ_REPO
ARG BUZZ_BRANCH
RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch ${BUZZ_BRANCH} ${BUZZ_REPO} /build

# ─── Stage 3: plan dependency graph ─────────────────────────────────────────
FROM chef AS planner
COPY --from=src /build/ .
RUN cargo chef prepare --recipe-path recipe.json

# ─── Stage 4: build the binary ───────────────────────────────────────────────
FROM chef AS builder
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        pkg-config \
        libssl-dev \
        ca-certificates \
        git \
    && rm -rf /var/lib/apt/lists/*
ENV CARGO_PROFILE_RELEASE_DEBUG=line-tables-only
COPY --from=planner /build/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json
COPY --from=src /build/ .
RUN cargo build --release --locked -p buzz-relay --bin buzz-relay \
                                   -p buzz-admin --bin buzz-admin \
                                   -p buzz-pair-relay --bin buzz-pair-relay

# ─── Stage 5: strip binaries ─────────────────────────────────────────────────
FROM builder AS stripped-binaries
RUN strip target/release/buzz-relay \
    && strip target/release/buzz-admin \
    && strip target/release/buzz-pair-relay

# ─── Stage 6: web bundle (pnpm + vite) ───────────────────────────────────────
FROM node:${NODE_VERSION}-${DEBIAN_VERSION}-slim AS web-builder
WORKDIR /build
RUN corepack enable
COPY --from=src /build/package.json /build/pnpm-lock.yaml /build/pnpm-workspace.yaml ./
COPY --from=src /build/patches/ patches/
COPY --from=src /build/web/package.json web/
COPY --from=src /build/admin-web/package.json admin-web/
RUN pnpm install --frozen-lockfile --filter buzz-web --filter buzz-admin-web
COPY --from=src /build/web/ web/
COPY --from=src /build/admin-web/ admin-web/
RUN pnpm -C web build && pnpm -C admin-web build

# ─── Stage 7: runtime ────────────────────────────────────────────────────────
FROM debian:${DEBIAN_VERSION}-slim AS runtime
LABEL org.opencontainers.image.title="Buzz" \
      org.opencontainers.image.description="WebSocket relay server for the Buzz communications platform" \
      org.opencontainers.image.source="https://github.com/block/buzz" \
      org.opencontainers.image.url="https://github.com/block/buzz" \
      org.opencontainers.image.licenses="Apache-2.0"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        openssl \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system --gid 1000 buzz \
    && useradd  --system --uid 1000 --gid 1000 --home-dir /var/lib/buzz \
                --create-home --shell /usr/sbin/nologin buzz

COPY --from=web-builder /build/web/dist                 /srv/buzz/web
COPY --from=web-builder /build/admin-web/dist           /srv/buzz/admin-web

ENV BUZZ_WEB_DIR=/srv/buzz/web \
    BUZZ_ADMIN_WEB_DIR=/srv/buzz/admin-web \
    PORT=3000 \
    BUZZ_BIND_ADDR=0.0.0.0:3000 \
    BUZZ_HEALTH_PORT=8080 \
    BUZZ_METRICS_PORT=9102 \
    BUZZ_GIT_REPO_PATH=/data/git \
    RUST_LOG=buzz_relay=info,buzz_db=info,buzz_auth=info,buzz_pubsub=info,tower_http=info

# 3000: app (WS + REST)  ·  8080: /_liveness, /_readiness  ·  9102: /metrics
EXPOSE 3000 8080 9102

# Volume for git repos
RUN mkdir -p /data/git && chown buzz:buzz /data/git

COPY relay/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Healthcheck — bash /dev/tcp probe (no curl/wget in image)
HEALTHCHECK --interval=10s --timeout=3s --retries=12 --start-period=30s \
  CMD bash -ec 'exec 3<>/dev/tcp/127.0.0.1/8080; printf "GET /_readiness HTTP/1.1\r\nHost: 127.0.0.1\r\nConnection: close\r\n\r\n" >&3; grep -q "200 OK" <&3'

WORKDIR /var/lib/buzz

COPY --from=stripped-binaries /build/target/release/buzz-relay /usr/local/bin/buzz-relay
COPY --from=stripped-binaries /build/target/release/buzz-admin /usr/local/bin/buzz-admin
COPY --from=stripped-binaries /build/target/release/buzz-pair-relay /usr/local/bin/buzz-pair-relay

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
