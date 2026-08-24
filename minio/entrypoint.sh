#!/bin/sh
# Custom entrypoint for MinIO that bypasses the upstream wrapper.
# Railway's startCommand args are passed as $@ — forward them directly to minio.
exec minio "$@"
