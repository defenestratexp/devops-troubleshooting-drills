#!/usr/bin/env bash
cd "$(dirname "$0")"
command -v docker  >/dev/null || { echo "SKIP - docker not installed"; exit 0; }
command -v openssl >/dev/null || { echo "SKIP - openssl not installed"; exit 0; }

[ -f pki/root.crt ] || ./setup.sh >/dev/null 2>&1
[ -f pki/app.crt ] || { echo "FAIL - ./setup.sh did not produce the certificates"; exit 1; }

finish() { docker compose down -v >/dev/null 2>&1; }
docker compose up -d >/dev/null 2>&1 || { echo "FAIL - docker compose up failed"; exit 1; }

get() { # host -> body
  curl -sS --max-time 5 --cacert pki/root.crt --resolve "$1:18444:127.0.0.1" \
    "https://$1:18444/" 2>/dev/null
}
subject_for() { # servername -> peer cert subject, empty if no cert was served
  openssl s_client -servername "$1" -connect 127.0.0.1:18444 </dev/null 2>/dev/null \
    | openssl x509 -noout -subject 2>/dev/null
}

ready=""
for _ in $(seq 1 20); do
  [ "$(get app.n9n.test)" = "app" ] && { ready=1; break; }
  sleep 1
done
if [ -z "$ready" ]; then
  echo "FAIL - app.n9n.test does not serve 'app' over a verifiable certificate"
  docker compose logs --tail 5 2>&1 | sed 's/^/  /'
  finish; exit 1
fi

fails=0
note() { echo "FAIL - $1"; fails=$((fails+1)); }

[ "$(get admin.n9n.test)" = "admin" ] || note "admin.n9n.test does not serve 'admin'"
subject_for app.n9n.test   | grep -q 'app\.n9n\.test'   || note "app.n9n.test is not served its own certificate"
subject_for admin.n9n.test | grep -q 'admin\.n9n\.test' || note "admin.n9n.test is not served its own certificate"

# The unconfigured name must get neither site's content nor certificate.
other_body=$(curl -skS --max-time 5 --resolve other.n9n.test:18444:127.0.0.1 \
               https://other.n9n.test:18444/ 2>/dev/null)
case "$other_body" in
  app)   note "an unconfigured hostname is served the app's content" ;;
  admin) note "an unconfigured hostname is served the admin site's content" ;;
esac
other_subject=$(subject_for other.n9n.test)
if [ -n "$other_subject" ]; then
  note "an unconfigured hostname was served a certificate: ${other_subject#subject=}"
fi

finish
[ "$fails" -eq 0 ] && { echo "PASS - both sites serve their own certificate and an unconfigured name is refused"; exit 0; }
echo "-- $fails problem(s) remaining"
exit 1
