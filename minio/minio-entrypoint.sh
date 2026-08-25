#!/bin/sh
# MinIO entrypoint: pre-create the media bucket, then exec the server.
#
# MinIO's filesystem backend treats each top-level directory under the data
# dir as a bucket, so creating the directory BEFORE the server starts makes
# the bucket exist from the very first request. This avoids the mc/alias
# race, needs no SigV4 signing, and is fully idempotent across restarts.
set -e

BUCKET="${BUZZ_S3_BUCKET:-buzz-media}"
DATA_DIR="${MINIO_DATA_DIR:-/data}"

mkdir -p "${DATA_DIR}/${BUCKET}"
echo "minio-entrypoint: bucket directory ready at ${DATA_DIR}/${BUCKET}"

echo "minio-entrypoint: starting minio server on :8080 (console :9001)"
exec minio server "${DATA_DIR}" \
  --address 0.0.0.0:8080 \
  --console-address 0.0.0.0:9001
