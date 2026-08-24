FROM minio/minio:latest

# MinIO sibling service for Buzz Relay.
# Root credentials (MINIO_ROOT_USER, MINIO_ROOT_PASSWORD) are injected
# by Railway from template-vars.json at deploy time.
#
# IMPORTANT: the start command MUST live here as a Dockerfile CMD.
# Railway only reads `railway.json` from the repository ROOT — a
# `railway.json` inside a service subdirectory (minio/railway.json) is
# ignored, so its `startCommand` never applies. Without a CMD the base
# image runs `minio` with no subcommand, which prints the usage banner
# and exits immediately ("Unexposed service", container never listens).
#
# Shell form (not exec form) is required so ${PORT} is expanded at
# runtime by the shell. Exec form would pass the literal string.

VOLUME /data

HEALTHCHECK --interval=10s --timeout=3s --retries=5 --start-period=15s \
  CMD curl -f http://127.0.0.1:${PORT:-8080}/minio/health/live || exit 1

EXPOSE 8080
EXPOSE 9001

CMD minio server /data --address 0.0.0.0:${PORT:-8080} --console-address 0.0.0.0:9001
