ARG MINIO_VERSION=latest

# Stage 1: Get minio binary from upstream
FROM minio/minio:${MINIO_VERSION} AS upstream

# Stage 1b: Get mc binary
FROM minio/mc:latest AS mc_upstream

# Stage 2: Build runtime image with clean entrypoint
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy minio binary from upstream (bypasses the upstream entrypoint wrapper)
COPY --from=upstream /usr/bin/minio /usr/bin/minio

# Copy mc binary for bucket creation
COPY --from=mc_upstream /usr/bin/mc /usr/bin/mc

COPY minio-entrypoint.sh /minio-entrypoint.sh
RUN chmod +x /minio-entrypoint.sh

VOLUME /data

HEALTHCHECK --interval=10s --timeout=3s --retries=5 --start-period=15s \
  CMD curl -f http://127.0.0.1:8080/minio/health/live || exit 1

EXPOSE 8080
EXPOSE 9001

# Use our custom entrypoint (bypasses upstream wrapper that swallows CMD args)
ENTRYPOINT ["/minio-entrypoint.sh"]
