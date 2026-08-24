#!/bin/sh
# Entrypoint wrapper for Buzz Relay.
# - Ensures /data/git is writable by buzz user
# - Normalizes BUZZ_RELAY_PRIVATE_KEY to valid 64-char hex
# - Creates buzz-media bucket on MinIO if missing (background, non-blocking)
# - Then execs as buzz user (relay runs in foreground so Railway can manage it)

set -e

if [ -d /data/git ]; then
  chown -R buzz:buzz /data/git
fi

# Normalize BUZZ_RELAY_PRIVATE_KEY to valid 64-char hex.
if [ -z "$BUZZ_RELAY_PRIVATE_KEY" ]; then
  export BUZZ_RELAY_PRIVATE_KEY=$(openssl rand -hex 32)
  echo "Generated random BUZZ_RELAY_PRIVATE_KEY"
elif ! echo "$BUZZ_RELAY_PRIVATE_KEY" | grep -qE '^[0-9a-fA-F]{64}$'; then
  export BUZZ_RELAY_PRIVATE_KEY=$(printf '%s' "$BUZZ_RELAY_PRIVATE_KEY" | sha256sum | cut -c1-64)
  echo "Derived hex BUZZ_RELAY_PRIVATE_KEY from seed"
fi

# Auto-create buzz-media bucket on MinIO (zero-config).
# Runs in background so the relay starts immediately and passes healthcheck.
if [ -n "$BUZZ_S3_ENDPOINT" ] && [ -n "$MINIO_ROOT_USER" ] && [ -n "$MINIO_ROOT_PASSWORD" ]; then
  BUCKET="${BUZZ_S3_BUCKET:-buzz-media}"
  echo "Starting bucket creation for ${BUCKET} in background..."
  (
    for i in $(seq 1 30); do
      if curl -sf -o /dev/null \
        -u "${MINIO_ROOT_USER}:${MINIO_ROOT_PASSWORD}" \
        "${BUZZ_S3_ENDPOINT}/${BUCKET}" 2>/dev/null; then
        echo "Bucket ${BUCKET} already exists."
        exit 0
      fi

      HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' \
        -X PUT \
        -u "${MINIO_ROOT_USER}:${MINIO_ROOT_PASSWORD}" \
        "${BUZZ_S3_ENDPOINT}/${BUCKET}" 2>/dev/null)

      if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
        echo "Bucket ${BUCKET} created."
        exit 0
      fi

      if [ "$i" -eq 30 ]; then
        echo "WARNING: Could not create bucket ${BUCKET} after 30 attempts. Continuing without bucket."
        exit 0
      fi

      sleep 1
    done
  ) &
fi

echo "Starting buzz-relay as buzz user..."
exec su -s /bin/sh buzz -c "exec /usr/local/bin/buzz-relay"
