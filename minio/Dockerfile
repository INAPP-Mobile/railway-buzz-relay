FROM minio/minio:latest

# MinIO sibling service for Buzz Relay.
# Root credentials (MINIO_ROOT_USER, MINIO_ROOT_PASSWORD) are injected
# by Railway from template-vars.json at deploy time.
#
# IMPORTANT: Railway does NOT expand ${PORT} inside Dockerfile CMD.
# The start command MUST use a hardcoded port. Port 8080 is the default
# MinIO API port; 9001 is the console.

VOLUME /data

HEALTHCHECK --interval=10s --timeout=3s --retries=5 --start-period=15s \
  CMD curl -f http://127.0.0.1:8080/minio/health/live || exit 1

EXPOSE 8080
EXPOSE 9001

CMD minio server /data --address 0.0.0.0:8080 --console-address 0.0.0.0:9001
