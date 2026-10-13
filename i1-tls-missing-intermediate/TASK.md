Reproduce it, then look at what is actually on the wire:

    ./setup.sh
    docker compose up -d

    # the failing client
    curl --cacert pki/root.crt --resolve drill.n9n.test:18443:127.0.0.1 \
         https://drill.n9n.test:18443/

    # what the server sends, and what it says about verification
    openssl s_client -connect 127.0.0.1:18443 -servername drill.n9n.test \
      -CAfile pki/root.crt -showcerts </dev/null

Read the `s_client` output from the top. Two specific things to find:

  1. The `Certificate chain` block at the start. **Count the certificates in
     it.** Then look at the `s:` and `i:` lines — subject and issuer — and
     write out the chain the server actually sent. Compare that with the chain
     in `pki/`: who signed `server.crt`?

  2. The `Verify return code` near the bottom, and its number.

Then the question that explains the browsers:

    If curl, Java and OpenSSL all cannot build a path to the root, why can
    Chrome?

Look up **AIA fetching** (`openssl x509 -in pki/server.crt -noout -text`, and
find the Authority Information Access extension — note whether this
certificate even has one) and what a browser caches from other sites it has
visited. The answer explains why this class of bug reaches production
constantly: the one client that cannot see the problem is the one everybody
tests with.

Fix it in `nginx.conf` plus whatever you need to build in `pki/`. The leaf must
still be signed by the intermediate, and `pki/root.crt` must still be the only
thing a client needs to trust.
