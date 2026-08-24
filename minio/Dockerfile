ARG MINIO_VERSION=latest

# Stage 1: Get minio binary from upstream
FROM minio/minio:${MINIO_VERSION} AS upstream

# Stage 2: Build runtime image with clean entrypoint
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy minio binary from upstream (bypasses the upstream entrypoint wrapper)
COPY --from=upstream /usr/bin/minio /usr/bin/minio

VOLUME /data

HEALTHCHECK --interval=10s --timeout=3s --retries=5 --start-period=15s \
  CMD curl -f http://127.0.0.1:8080/minio/health/live || exit 1

EXPOSE 8080
EXPOSE 9001

# Clean entrypoint — just run minio directly
ENTRYPOINT ["minio"]
CMD ["server", "/data", "--address", "0.0.0.0:8080", "--console-address", "0.0.0.0:9001"]
