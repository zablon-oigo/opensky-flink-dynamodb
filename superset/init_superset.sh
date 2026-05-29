#!/bin/bash

set -e

echo "Initializing Superset..."

echo "Upgrading database..."
superset db upgrade

echo "Creating admin user..."
superset fab create-admin \
    --username admin \
    --firstname Superset \
    --lastname Admin \
    --email admin@superset.com \
    --password admin || \
    echo "Admin already exists"

echo "Initializing Superset..."
superset init

echo "Starting Superset..."

gunicorn \
    --bind 0.0.0.0:8088 \
    --workers 2 \
    "superset.app:create_app()"

