#!/usr/bin/env bash
cd "$(dirname "$0")"
pass=0
for run in 1 2 3; do
  out=$(docker compose up --abort-on-container-exit --exit-code-from api 2>&1)
  grep -q "OK db ready" <<<"$out" && pass=$((pass+1))
  docker compose down -v >/dev/null 2>&1
done
if [ "$pass" -eq 3 ]; then echo "PASS (3/3 runs)"; exit 0; fi
echo "FAIL - only $pass/3 runs succeeded"; exit 1
