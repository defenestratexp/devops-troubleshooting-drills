#!/usr/bin/env bash
# Verifies the chain the SERVER sends, trusting only the root -- which is the
# whole point. A client that already has the intermediate cached would not
# notice the bug, so the grader deliberately starts from nothing but the root.
cd "$(dirname "$0")"
command -v docker  >/dev/null || { echo "SKIP - docker not installed"; exit 0; }
command -v openssl >/dev/null || { echo "SKIP - openssl not installed"; exit 0; }

[ -f pki/root.crt ] || ./setup.sh >/dev/null 2>&1
[ -f pki/root.crt ] || { echo "FAIL - ./setup.sh did not produce pki/root.crt"; exit 1; }

finish() { docker compose down -v >/dev/null 2>&1; }

# The PKI itself must be intact: leaf signed by the intermediate, intermediate
# signed by the root. Otherwise "fix" could mean re-signing from the root.
openssl verify -CAfile pki/root.crt pki/intermediate.crt >/dev/null 2>&1 \
  || { echo "FAIL - pki/intermediate.crt is no longer signed by pki/root.crt"; exit 1; }
openssl verify -CAfile pki/root.crt -untrusted pki/intermediate.crt pki/server.crt >/dev/null 2>&1 \
  || { echo "FAIL - pki/server.crt is no longer signed by the intermediate"; exit 1; }
openssl x509 -in pki/server.crt -noout -issuer 2>/dev/null | grep -q "Intermediate" \
  || { echo "FAIL - the leaf must still be issued by the intermediate CA"; exit 1; }

docker compose up -d >/dev/null 2>&1 || { echo "FAIL - docker compose up failed"; exit 1; }

chain=""
for _ in $(seq 1 20); do
  chain=$(openssl s_client -connect 127.0.0.1:18443 -servername drill.n9n.test \
            -CAfile pki/root.crt -showcerts </dev/null 2>&1)
  grep -q "BEGIN CERTIFICATE" <<<"$chain" && break
  sleep 1
done
if ! grep -q "BEGIN CERTIFICATE" <<<"$chain"; then
  echo "FAIL - nothing is serving TLS on 127.0.0.1:18443"
  docker compose logs --tail 5 2>&1 | sed 's/^/  /'
  finish; exit 1
fi

sent=$(grep -c "BEGIN CERTIFICATE" <<<"$chain")
if ! grep -q "Verify return code: 0 (ok)" <<<"$chain"; then
  code=$(grep -o "Verify return code: .*" <<<"$chain" | head -1)
  echo "FAIL - a client trusting only the root cannot verify this server"
  echo "       the server sent $sent certificate(s); $code"
  finish; exit 1
fi
if [ "$sent" -lt 2 ]; then
  echo "FAIL - the server sent only $sent certificate; the chain to the root is incomplete"
  finish; exit 1
fi

# And a real client, with only the root in its trust store.
body=$(curl -sS --max-time 5 --cacert pki/root.crt \
         --resolve drill.n9n.test:18443:127.0.0.1 \
         https://drill.n9n.test:18443/ 2>&1)
if [ "$body" != "ok" ]; then
  echo "FAIL - curl trusting only the root still cannot complete the handshake:"
  sed 's/^/  /' <<<"$body" | head -3
  finish; exit 1
fi

finish
echo "PASS - the server sends $sent certificates and a root-only client verifies it"
