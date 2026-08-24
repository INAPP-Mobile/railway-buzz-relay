#!/bin/sh
# Entrypoint wrapper: ensure volume is writable by buzz user, then exec as buzz.
set -e
if [ -d /data/git ]; then
  chown -R buzz:buzz /data/git
fi

# Normalize BUZZ_RELAY_PRIVATE_KEY to valid 64-char hex.
# - If unset: generate random hex
# - If already valid hex: use as-is
# - If non-hex (e.g. Railway's ${{secret(64)}}): SHA-256 hash to derive stable hex
if [ -z "$BUZZ_RELAY_PRIVATE_KEY" ]; then
  export BUZZ_RELAY_PRIVATE_KEY=$(openssl rand -hex 32)
  echo "Generated random BUZZ_RELAY_PRIVATE_KEY"
elif ! echo "$BUZZ_RELAY_PRIVATE_KEY" | grep -qE '^[0-9a-fA-F]{64}$'; then
  export BUZZ_RELAY_PRIVATE_KEY=$(printf '%s' "$BUZZ_RELAY_PRIVATE_KEY" | sha256sum | cut -c1-64)
  echo "Derived hex BUZZ_RELAY_PRIVATE_KEY from seed"
fi

exec su -s /bin/sh buzz -c 'exec /usr/local/bin/buzz-relay "$@"' -- "$@"
