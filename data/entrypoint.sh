#!/bin/sh

set -e

echo "Waiting for Kafka to be available..."

until nc -z kafka 9092; do
  echo "Kafka not available yet, retrying..."
  sleep 2
done

echo "Kafka is available, starting producer..."

exec uv run --no-dev python main.py
