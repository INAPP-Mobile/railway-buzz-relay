FROM minio/minio:latest

# MinIO sibling service for Buzz Relay.
# Root credentials (MINIO_ROOT_USER, MINIO_ROOT_PASSWORD) are injected
# by Railway from template-vars.json at deploy time.
#
# Start command and port are configured in minio/railway.json via the
# `startCommand` and `port` fields — not here.

VOLUME /data

HEALTHCHECK --interval=10s --timeout=3s --retries=5 --start-period=15s \
  CMD curl -f http://127.0.0.1:8080/minio/health/live || exit 1

EXPOSE 8080
EXPOSE 9001