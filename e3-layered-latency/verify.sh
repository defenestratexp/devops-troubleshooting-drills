#!/usr/bin/env bash
cd "$(dirname "$0")"
docker compose ps --status running --services 2>/dev/null | grep -q nginx || { echo "SKIP - run ./setup.sh first"; exit 0; }
tot=0; n=5
for i in $(seq 1 $n); do
  t=$(curl -s -o /dev/null -w '%{time_total}' --max-time 20 http://localhost:8081/ 2>/dev/null)
  tot=$(awk -v a="$tot" -v b="$t" 'BEGIN{print a+b}')
done
avg=$(awk -v t="$tot" -v n="$n" 'BEGIN{printf "%.3f", t/n}')
ok=$(awk -v a="$avg" 'BEGIN{print (a<0.300)?1:0}')
[ -f ANSWERS.md ] || { echo "FAIL - write ANSWERS.md as you go"; exit 1; }
if [ "$ok" = "1" ]; then echo "PASS - avg ${avg}s over $n requests"; exit 0; fi
echo "FAIL - avg ${avg}s, need < 0.300s"; exit 1
