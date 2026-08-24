#!/bin/sh
# Entrypoint wrapper: ensure volume is writable by buzz user, then exec as buzz.
set -e
if [ -d /data/git ]; then
  chown -R buzz:buzz /data/git
fi

# Ensure a valid 64-hex-char Nostr secret key exists.
# Nostr requires exactly 64 hexadecimal characters (32 bytes).
KEY_FILE="/data/git/.relay-private-key"
is_valid_hex() {
  case "$1" in
    [0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]) return 0 ;;
    *) return 1 ;;
  esac
}

if is_valid_hex "${BUZZ_RELAY_PRIVATE_KEY:-}"; then
  # User provided a valid key via env — persist it
  printf '%s' "$BUZZ_RELAY_PRIVATE_KEY" > "$KEY_FILE"
elif [ -f "$KEY_FILE" ] && is_valid_hex "$(cat "$KEY_FILE")"; then
  # Valid key already persisted
  BUZZ_RELAY_PRIVATE_KEY="$(cat "$KEY_FILE")"
else
  # Generate new key
  BUZZ_RELAY_PRIVATE_KEY="$(openssl rand -hex 32)"
  printf '%s' "$BUZZ_RELAY_PRIVATE_KEY" > "$KEY_FILE"
fi
export BUZZ_RELAY_PRIVATE_KEY

exec su -s /bin/sh buzz -c 'exec /usr/local/bin/buzz-relay "$@"' -- "$@"
