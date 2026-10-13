#!/usr/bin/env bash
cd "$(dirname "$0")"
docker compose down -v >/dev/null 2>&1
docker compose up -d db >/dev/null 2>&1
for i in $(seq 1 30); do
  docker compose exec -T db psql -U postgres -d app -tAc 'SELECT 1' >/dev/null 2>&1 && break
  sleep 1
done
docker compose run --rm job >/dev/null 2>&1
n=$(docker compose exec -T db psql -U postgres -d app -tAc 'SELECT count(*) FROM records' 2>/dev/null | tr -d '[:space:]')
docker compose down -v >/dev/null 2>&1
if [ "$n" = "8" ]; then echo "PASS - 8 rows written"; exit 0; fi
echo "FAIL - expected 8 rows, found ${n:-none}"
exit 1
