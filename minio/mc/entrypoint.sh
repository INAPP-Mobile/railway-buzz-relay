#!/bin/sh
# Entrypoint for MinIO Client wrapper
# Creates the buzz-media bucket then lists buckets

set -e

echo "Setting up MinIO alias..."
mc alias set local http://minio.railway.internal:8080 minioadmin md83vu6xhlf2zgimuvnfv4wpfi3kzz03

echo "Creating buzz-media bucket..."
mc mb -p local/buzz-media || true

echo "Listing buckets..."
mc ls local

echo "Done. Sleeping to keep container alive for debugging..."
sleep infinity
