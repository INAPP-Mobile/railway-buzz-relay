#!/bin/sh
# Entrypoint wrapper for Buzz Relay.
# - Ensures /data/git is writable by buzz user
# - Normalizes BUZZ_RELAY_PRIVATE_KEY to valid 64-char hex
# - Creates buzz-media bucket on MinIO if missing (zero-config)
# - Then execs as buzz user

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
# Uses MinIO's S3-compatible API with root credentials.
if [ -n "$BUZZ_S3_ENDPOINT" ] && [ -n "$MINIO_ROOT_USER" ] && [ -n "$MINIO_ROOT_PASSWORD" ]; then
  BUCKET="${BUZZ_S3_BUCKET:-buzz-media}"
  echo "Ensuring bucket ${BUCKET} exists on ${BUZZ_S3_ENDPOINT}..."
  
  # Extract host:port from endpoint URL
  S3_HOST=$(echo "$BUZZ_S3_ENDPOINT" | sed 's|http://||;s|https://||;s|/$||')
  
  for i in $(seq 1 30); do
    # Check if bucket exists (HEAD request)
    if curl -sf -o /dev/null \
      -u "${MINIO_ROOT_USER}:${MINIO_ROOT_PASSWORD}" \
      "${BUZZ_S3_ENDPOINT}/${BUCKET}" 2>/dev/null; then
      echo "Bucket ${BUCKET} already exists."
      break
    fi
    
    # Try to create bucket (PUT request)
    HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' \
      -X PUT \
      -u "${MINIO_ROOT_USER}:${MINIO_ROOT_PASSWORD}" \
      "${BUZZ_S3_ENDPOINT}/${BUCKET}" 2>/dev/null)
    
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
      echo "Bucket ${BUCKET} created."
      break
    fi
    
    if [ "$i" -eq 30 ]; then
      echo "WARNING: Could not create bucket ${BUCKET} (last HTTP ${HTTP_CODE}). Continuing anyway..."
    fi
    sleep 2
  done
fi

exec su -s /bin/sh buzz -c 'exec /usr/local/bin/buzz-relay "$@"' -- "$@"
