FROM redis:7-alpine

# Redis password is set via REDIS_PASSWORD env var.
# Volume mount geometry for data persistence.
VOLUME /data

HEALTHCHECK --interval=10s --timeout=3s --retries=5 --start-period=5s \
  CMD redis-cli -a ${REDIS_PASSWORD} ping | grep -q PONG || exit 1

EXPOSE 6379
CMD ["redis-server", "--appendonly", "yes", "--requirepass", "${REDIS_PASSWORD}"]