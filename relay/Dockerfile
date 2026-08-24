FROM ghcr.io/block/buzz:main

# Zero-config Railway template for Buzz Relay.
# Connection credentials (DATABASE_URL, REDIS_URL, BUZZ_S3_*) are injected
# by Railway from template-vars.json at deploy time — NOT hardcoded here.

ENV PORT=3000
ENV BUZZ_BIND_ADDR=0.0.0.0:${PORT}
ENV BUZZ_HEALTH_PORT=8080
ENV BUZZ_METRICS_PORT=9102

# Git repos persisted on volume
ENV BUZZ_GIT_REPO_PATH=/data/git

# Logging
ENV RUST_LOG=buzz_relay=info,buzz_db=info,buzz_auth=info,buzz_pubsub=info,tower_http=info

# Volume for git repos
VOLUME /data/git

# Healthcheck — bash /dev/tcp probe (no curl/wget in image)
HEALTHCHECK --interval=10s --timeout=3s --retries=12 --start-period=30s \
  CMD bash -ec 'exec 3<>/dev/tcp/127.0.0.1/8080; printf "GET /_readiness HTTP/1.1\r\nHost: 127.0.0.1\r\nConnection: close\r\n\r\n" >&3; grep -q "200 OK" <&3'

EXPOSE 3000
EXPOSE 8080

CMD ["buzz-relay"]