#!/usr/bin/env bash
cd "$(dirname "$0")"
out=$(docker compose up --build --abort-on-container-exit --exit-code-from api 2>&1)
docker compose down -v >/dev/null 2>&1
if grep -q "OK 00042" <<<"$out"; then echo "PASS"; exit 0; fi
echo "FAIL"; echo "$out" | grep -iE "cannot find module|error" | head -3 | sed 's/^/  /'; exit 1
