#!/usr/bin/env bash
cd "$(dirname "$0")"
out=$(docker compose up --abort-on-container-exit --exit-code-from api 2>&1)
docker compose down -v >/dev/null 2>&1
if grep -q "OK authenticated" <<<"$out"; then echo "PASS"; exit 0; fi
echo "FAIL"; echo "$out" | tail -5 | sed 's/^/  /'; exit 1
