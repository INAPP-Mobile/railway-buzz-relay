FROM redis:7-alpine

# Redis runs unauthenticated on Railway's private network, which is already
# isolated per-project (same pattern as the paperless-ngx template). The relay
# connects over redis.railway.internal:6379, which is not reachable publicly.
# Volume mount geometry for data persistence.

HEALTHCHECK --interval=10s --timeout=3s --retries=5 --start-period=5s \
  CMD redis-cli ping | grep -q PONG || exit 1

EXPOSE 6379
CMD ["redis-server", "--appendonly", "yes"]
