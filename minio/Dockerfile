ARG MINIO_VERSION=latest
FROM minio/minio:${MINIO_VERSION}

# MinIO sibling service for Buzz Relay.
# Root credentials (MINIO_ROOT_USER, MINIO_ROOT_PASSWORD) are injected
# by Railway from template-vars.json at deploy time.
#
# IMPORTANT: Railway does NOT expand ${PORT} inside Dockerfile CMD.
# The start command MUST use a hardcoded port. Port 8080 is the default
# MinIO API port; 9001 is the console.
#
# Cache-bust: 4

# Install mc (MinIO Client) for bucket auto-creation
ADD https://dl.min.io/client/mc/release/linux-amd64/mc /usr/local/bin/mc
RUN chmod +x /usr/local/bin/mc

COPY minio-entrypoint.sh /usr/local/bin/minio-entrypoint.sh
RUN chmod +x /usr/local/bin/minio-entrypoint.sh

VOLUME /data

HEALTHCHECK --interval=10s --timeout=3s --retries=5 --start-period=15s \
  CMD curl -f http://127.0.0.1:8080/minio/health/live || exit 1

EXPOSE 8080
EXPOSE 9001

CMD ["/usr/local/bin/minio-entrypoint.sh"]
