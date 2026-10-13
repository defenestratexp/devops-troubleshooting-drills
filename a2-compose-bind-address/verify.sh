#!/usr/bin/env bash
cd "$(dirname "$0")"
docker compose up -d >/dev/null 2>&1
for i in $(seq 1 15); do
  body=$(curl -sS --max-time 3 http://localhost:8080/ 2>/dev/null)
  [ "$body" = "hello" ] && { docker compose down -v >/dev/null 2>&1; echo "PASS"; exit 0; }
  sleep 1
done
echo "FAIL - localhost:8080 did not return hello"
docker compose logs --tail 5 2>&1 | sed 's/^/  /'
docker compose down -v >/dev/null 2>&1; exit 1
