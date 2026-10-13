#!/usr/bin/env bash
cd "$(dirname "$0")"
docker compose down -v >/dev/null 2>&1
docker compose up -d >/dev/null 2>&1
for i in $(seq 1 30); do
  docker compose exec -T db psql -U postgres -d app -tAc 'SELECT 1' >/dev/null 2>&1 && break
  sleep 1
done
n=$(docker compose exec -T db psql -U postgres -d app -tAf /report.sql 2>/dev/null | grep -c '@example.com')
docker compose down -v >/dev/null 2>&1
if [ "$n" = "7" ]; then echo "PASS - 7 active users"; exit 0; fi
echo "FAIL - report returned $n rows, expected 7"
exit 1
