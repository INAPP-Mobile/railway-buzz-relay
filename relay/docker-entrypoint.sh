#!/bin/sh
# Entrypoint wrapper: ensure volume is writable by buzz user, then exec as buzz.
set -e
if [ -d /data/git ]; then
  chown -R buzz:buzz /data/git
fi
exec su -s /bin/sh buzz -c 'exec /usr/local/bin/buzz-relay "$@"' -- "$@"
