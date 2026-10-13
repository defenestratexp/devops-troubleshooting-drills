#!/usr/bin/env bash
# Builds a three-level PKI for the drill: root CA -> intermediate CA -> leaf.
# Everything stays in pki/ under this directory. No system trust store is
# touched and nothing here is a real certificate.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf pki && mkdir -p pki
cd pki

echo "generating root CA"
openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
  -keyout root.key -out root.crt \
  -subj "/CN=n9n Drill Root CA" \
  -addext "basicConstraints=critical,CA:TRUE" \
  -addext "keyUsage=critical,keyCertSign,cRLSign" 2>/dev/null

echo "generating intermediate CA, signed by the root"
openssl req -newkey rsa:2048 -nodes -keyout intermediate.key -out intermediate.csr \
  -subj "/CN=n9n Drill Intermediate CA" 2>/dev/null
openssl x509 -req -in intermediate.csr -CA root.crt -CAkey root.key -CAcreateserial \
  -days 1825 -out intermediate.crt \
  -extfile <(printf 'basicConstraints=critical,CA:TRUE,pathlen:0\nkeyUsage=critical,keyCertSign,cRLSign\n') 2>/dev/null

echo "generating the server certificate, signed by the intermediate"
openssl req -newkey rsa:2048 -nodes -keyout server.key -out server.csr \
  -subj "/CN=drill.n9n.test" 2>/dev/null
openssl x509 -req -in server.csr -CA intermediate.crt -CAkey intermediate.key -CAcreateserial \
  -days 825 -out server.crt \
  -extfile <(printf 'subjectAltName=DNS:drill.n9n.test,DNS:localhost\nbasicConstraints=critical,CA:FALSE\nextendedKeyUsage=serverAuth\n') 2>/dev/null

rm -f *.csr *.srl
chmod 644 *.crt *.key
echo
echo "pki/ now contains:"
ls -1 | sed 's/^/  /'
echo
echo "the chain, for reference:"
echo "  root.crt          CN=n9n Drill Root CA          (the trust anchor)"
echo "  intermediate.crt  CN=n9n Drill Intermediate CA  (signed by the root)"
echo "  server.crt        CN=drill.n9n.test             (signed by the intermediate)"
