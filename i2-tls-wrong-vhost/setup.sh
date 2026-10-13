#!/usr/bin/env bash
# One drill CA and two server certificates, one per hostname. Everything stays
# in pki/ under this directory; no system trust store is touched.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf pki && mkdir -p pki
cd pki

openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
  -keyout root.key -out root.crt -subj "/CN=n9n Drill Root CA" \
  -addext "basicConstraints=critical,CA:TRUE" \
  -addext "keyUsage=critical,keyCertSign,cRLSign" 2>/dev/null

for host in app admin; do
  openssl req -newkey rsa:2048 -nodes -keyout "$host.key" -out "$host.csr" \
    -subj "/CN=$host.n9n.test" 2>/dev/null
  openssl x509 -req -in "$host.csr" -CA root.crt -CAkey root.key -CAcreateserial \
    -days 825 -out "$host.crt" \
    -extfile <(printf 'subjectAltName=DNS:%s.n9n.test\nbasicConstraints=critical,CA:FALSE\nextendedKeyUsage=serverAuth\n' "$host") 2>/dev/null
done

rm -f *.csr *.srl
chmod 644 *.crt *.key
echo "pki/ now contains:"
ls -1 | sed 's/^/  /'
