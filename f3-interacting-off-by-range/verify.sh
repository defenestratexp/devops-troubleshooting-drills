#!/usr/bin/env bash
cd "$(dirname "$0")"
docker compose down -v >/dev/null 2>&1
docker compose up -d >/dev/null 2>&1
for i in $(seq 1 40); do curl -sf --max-time 2 http://localhost:7799/item >/dev/null 2>&1 && break; sleep 1; done
ok=0; fail=0
for i in $(seq 1 25); do
  b=$(curl -s --max-time 5 http://localhost:7799/item)
  if [ -n "$b" ] && [ "$b" != "error" ]; then ok=$((ok+1)); else fail=$((fail+1)); fi
done
docker compose down -v >/dev/null 2>&1
if [ "$ok" = 25 ]; then echo "PASS - 25/25 returned a body"; exit 0; fi
echo "FAIL - $ok/25 succeeded, $fail failed"
exit 1
