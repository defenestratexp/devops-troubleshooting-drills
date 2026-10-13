#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
docker compose up -d --build
echo "up. try: curl -w '\\n total=%{time_total}s\\n' -s -o /dev/null http://localhost:8081/"
