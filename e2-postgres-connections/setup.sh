#!/usr/bin/env bash
# Postgres with max_connections=15, plus 12 idle-in-transaction hogs.
set -e
docker rm -f practice-pg >/dev/null 2>&1 || true
docker run -d --name practice-pg -e POSTGRES_PASSWORD=pw -p 55432:5432 \
  postgres:16-alpine -c max_connections=15 -c log_connections=on >/dev/null
echo -n "waiting for postgres"
for i in $(seq 1 30); do
  docker exec practice-pg pg_isready -U postgres >/dev/null 2>&1 && break
  echo -n .; sleep 1
done; echo
# Hogs: open a transaction, run one statement, then SIT IDLE inside it.
#
# The subtlety: a session running pg_sleep() reports state='active', not
# 'idle in transaction'. To get idle-in-transaction the session must execute
# BEGIN and then do NOTHING while holding the connection open. Feeding psql
# from a pipe that stays open does exactly that - psql runs the statements it
# has read, then blocks waiting for more input.
for i in $(seq 1 12); do
  docker exec -d practice-pg sh -c '(echo "begin; select 1;"; sleep 3600) | psql -U postgres -q' 2>/dev/null
done
sleep 3
echo "Situation created. Connect with:"
echo "  docker exec -it practice-pg psql -U postgres"
