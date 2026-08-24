#!/bin/sh
# MinIO entrypoint wrapper: auto-create buzz-media bucket on first start.
set -e

MINIO_USER="${MINIO_ROOT_USER:-minioadmin}"
MINIO_PASS="${MINIO_ROOT_PASSWORD:-minioadmin}"
BUCKET="${BUZZ_S3_BUCKET:-buzz-media}"

# Start MinIO in background
minio server /data --address 0.0.0.0:8080 --console-address 0.0.0.0:9001 &
MINIO_PID=$!

echo "Waiting for MinIO to start..."
for i in $(seq 1 30); do
  if curl -sf http://127.0.0.1:8080/minio/health/live > /dev/null 2>&1; then
    echo "MinIO is ready."
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "MinIO failed to start within 30 seconds."
    exit 1
  fi
  sleep 1
done

# Create bucket using mc
echo "Creating bucket: ${BUCKET}"
mc alias set local http://127.0.0.1:8080 "$MINIO_USER" "$MINIO_PASS" && \
  mc mb --ignore-existing "local/${BUCKET}" && \
  echo "Bucket ${BUCKET} ready."

# Keep MinIO running in foreground
wait $MINIO_PID
