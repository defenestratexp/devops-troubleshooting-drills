#!/usr/bin/env bash
cd "$(dirname "$0")"
docker compose up -d >/dev/null 2>&1
for i in $(seq 1 20); do curl -sf --max-time 2 -X OPTIONS http://localhost:7788/quote >/dev/null 2>&1 && break; sleep 1; done

# call the API exactly the way the front end does, whatever method that now is
m=$(grep -oE 'hx-(get|post|put)' app/index.html | head -1 | cut -d- -f2 | tr 'a-z' 'A-Z')
[ -n "$m" ] || m=GET
code=$(curl -s -o /tmp/f2body -w '%{http_code}' --max-time 5 -X "$m" http://localhost:7788/quote)
body=$(tr -d '[:space:]' < /tmp/f2body)

# a genuine server-side error must NOT report success
err=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://localhost:7788/boom)

docker compose down -v >/dev/null 2>&1; rm -f /tmp/f2body
ok=1
[ "$code" = "200" ] && [ -n "$body" ] || { echo "FAIL - front-end method $m got HTTP $code, body '${body:-empty}'"; ok=0; }
[ "$err" -ge 500 ] 2>/dev/null || { echo "FAIL - /boom returned $err, expected 5xx"; ok=0; }
[ "$ok" = 1 ] && { echo "PASS - $m /quote returned a body, /boom returned $err"; exit 0; }
exit 1
