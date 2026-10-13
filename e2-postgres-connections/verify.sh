#!/usr/bin/env bash
cd "$(dirname "$0")"
docker ps --format '{{.Names}}' | grep -q practice-pg || { echo "SKIP - run ./setup.sh first"; exit 0; }
[ -f ANSWERS.md ] || { echo "FAIL - write ANSWERS.md first"; exit 1; }
score=0
grep -qiE 'pg_stat_activity' ANSWERS.md && score=$((score+1))
grep -qiE 'idle in transaction' ANSWERS.md && score=$((score+1))
grep -qiE 'pg_terminate_backend' ANSWERS.md && score=$((score+1))
grep -qiE 'xact_start|state_change|query_start' ANSWERS.md && score=$((score+1))
grep -qiE 'pool|pgbouncer|rds proxy' ANSWERS.md && score=$((score+1))
grep -qiE 'idle_in_transaction_session_timeout|statement_timeout' ANSWERS.md && score=$((score+1))
echo "self-check score: $score/6"
remaining=$(docker exec practice-pg psql -U postgres -tAc "select count(*) from pg_stat_activity where state='idle in transaction'" 2>/dev/null | tr -dc '0-9')
echo "idle-in-transaction sessions remaining: ${remaining:-?}"
[ "$score" -ge 5 ] && [ "${remaining:-9}" -le 2 ] && { echo "PASS"; exit 0; }
echo "Need score >=5 AND the hogs terminated"; exit 1
