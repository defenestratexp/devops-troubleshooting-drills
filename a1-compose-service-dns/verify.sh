#!/usr/bin/env bash
cd "$(dirname "$0")"
out=$(docker compose up --abort-on-container-exit --exit-code-from api 2>&1)
docker compose down -v >/dev/null 2>&1
if grep -q "OK connected" <<<"$out"; then echo "PASS"; exit 0; fi
echo "FAIL - api never printed OK connected"; echo "$out" | tail -5; exit 1
