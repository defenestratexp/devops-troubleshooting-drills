#!/usr/bin/env bash
# Counts the questions the DNS server is actually asked. Two requirements:
# an external name must cost one name, and a short internal name must still
# resolve through the search path.
#
# The query log lives inside the dns container and is read and truncated with
# `docker compose exec` -- bind-mounting it put a root-owned file on the host
# that the grader could not truncate.
cd "$(dirname "$0")"
command -v docker >/dev/null || { echo "SKIP - docker not installed"; exit 0; }

finish() { docker compose down -v >/dev/null 2>&1; }
docker compose up -d >/dev/null 2>&1 || { echo "FAIL - docker compose up failed"; exit 1; }

# ahosts rather than hosts: it still looks up both address families, which is
# the behaviour under test, but it prints every address it found. `getent
# hosts` prints only the first, and with an AAAA present that is the v6 one.
resolve()  { docker compose exec -T client getent ahosts "$1" 2>/dev/null; }
log_clear(){ docker compose exec -T dns sh -c ': > /var/log/dns/queries.log' 2>/dev/null; }
log_read() { docker compose exec -T dns cat /var/log/dns/queries.log 2>/dev/null; }

ready=""
for _ in $(seq 1 25); do
  resolve api.vendor.test | grep -q 10.9.9.9 && { ready=1; break; }
  sleep 1
done
if [ -z "$ready" ]; then
  echo "FAIL - the client cannot resolve api.vendor.test at all"
  docker compose logs --tail 8 dns 2>&1 | sed 's/^/  /'
  finish; exit 1
fi

fails=0
note() { echo "FAIL - $1"; fails=$((fails+1)); }

# --- requirement 1: one external lookup must ask about one name -------------
log_clear
resolve api.vendor.test >/dev/null
sleep 1
queries=$(log_read)
total=$(printf '%s\n' "$queries" | grep -c . )
wasted=$(printf '%s\n' "$queries" | grep -c -v '^api\.vendor\.test\. ' )
if [ "${wasted:-0}" -gt 0 ]; then
  note "resolving api.vendor.test asked $total questions, $wasted of them about names that do not exist:"
  printf '%s\n' "$queries" | grep -v '^api\.vendor\.test\. ' \
    | awk '{print $1}' | sort -u | sed 's/^/        /' | head -6
fi

# --- requirement 2: a short internal name must still work -------------------
log_clear
if ! resolve payments | grep -q 10.9.77.20; then
  note "the short name 'payments' no longer resolves; it must still find payments.svc.drill.local"
fi

# --- the instrument must not have been edited -------------------------------
grep -q 'queries.log' dnsd.py || note "dnsd.py no longer logs the queries it is asked"

finish
[ "$fails" -eq 0 ] && { echo "PASS - external names ask about one name and short internal names still resolve"; exit 0; }
echo "-- $fails problem(s) remaining"
exit 1
