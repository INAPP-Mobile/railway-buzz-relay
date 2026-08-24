# Buzz Relay — Railway Zero-Config Template

Deploy a fully-functional Nostr relay with Buzz on Railway in one click.
No manual configuration needed — all secrets auto-generated.

## Services

| Service | Image | Purpose |
|---------|-------|---------|
| `relay` | ghcr.io/block/buzz:main | Nostr relay (buzz-relay binary) |
| `postgres` | postgres:16-alpine | Database for relay state |
| `redis` | redis:7-alpine | Pub/sub cache |
| `minio` | minio/minio | S3-compatible media storage |

## Environment Variables

All variables auto-populated from companion services:

| Variable | Source | Description |
|----------|--------|-------------|
| `DATABASE_URL` | postgres | PostgreSQL connection URL |
| `REDIS_URL` | redis | Redis connection URL |
| `BUZZ_S3_ENDPOINT` | minio | S3 endpoint for media |
| `BUZZ_S3_ACCESS_KEY` | minio | S3 access key |
| `BUZZ_S3_SECRET_KEY` | minio | S3 secret key |
| `BUZZ_RELAY_PRIVATE_KEY` | auto-generated | Nostr relay signing key |

## Architecture

```
                   +----------------------+
                   |       relay          |
                   |   ghcr.io/block/buzz |
                   |   :main              |
                   +------+---------------+
                          |
          +---------------+---------------+
          |               |               |
   +------+------+ +-----+------+ +------+------+
   |   postgres   | |   redis    | |    minio    |
   |  postgres:16 | |  redis:7   | |   minio     |
   +--------------+ +------------+ +-------------+
```

## Health Checks

- Relay: `/_readiness` on port 8080
- Postgres: built-in
- Redis: `redis-cli ping`
- Minio: `/minio/health/live`

## Deployment

Click the button below to deploy. No configuration needed:

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.com/deploy/buzz-relay)

## Post-Deploy

1. Relay is accessible at your Railway public domain
2. Nostr clients can connect via `wss://<your-domain>`
3. Git repos are persisted at `/data/git` on the relay volume
4. Media uploads go to the MinIO bucket

## Notes

- Default database credentials: `postgres` / `postgres` (rotate in dashboard before production)
- Default Redis password: `redis` (rotate in dashboard before production)
- Default MinIO credentials: `minioadmin` / auto-generated password (rotate in dashboard before production)
- Nostr relay private key is auto-generated on first deploy