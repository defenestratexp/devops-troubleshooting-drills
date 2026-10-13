# Solution: TLS: fine in the browser, broken everywhere else

> Stop. Have you run `./verify.sh`?

## What the wire shows

    openssl s_client -connect 127.0.0.1:18443 -servername drill.n9n.test \
      -CAfile pki/root.crt -showcerts </dev/null

    Certificate chain
     0 s:CN=drill.n9n.test
       i:CN=n9n Drill Intermediate CA
    ...
    Verify return code: 21 (unable to verify the first certificate)

One certificate. The server sent the leaf and stopped.

The client trusts `n9n Drill Root CA`. The leaf says it was issued by
`n9n Drill Intermediate CA`, and the client has never heard of that. It cannot
get from what it was given to what it trusts, so there is no path and
verification fails. Error 21 — "unable to verify the first certificate" — is
specifically this: *the chain you sent me does not reach anything I trust*.

Note what is **not** wrong: the certificate is in date, the name matches, the
key is fine, and it genuinely is signed by a CA the client trusts — two hops
up. Every check people perform by hand passes, which is why the renewal was
signed off.

## The fix

TLS requires the server to send the leaf **and every intermediate** needed to
chain to a trusted root. The root itself is not sent — the client already has
it, by definition.

    cat pki/server.crt pki/intermediate.crt > pki/fullchain.pem

and point nginx at that:

    ssl_certificate     /etc/nginx/pki/fullchain.pem;
    ssl_certificate_key /etc/nginx/pki/server.key;

**Order matters**: leaf first, then each issuer going up. nginx reads the first
certificate in the file as the server certificate and offers the rest as the
chain. Reverse them and nginx serves the intermediate as the server
certificate, which fails differently and more confusingly.

This is what `fullchain.pem` means in Let's Encrypt's output, and it is the
single most common certbot mistake: `cert.pem` is the leaf alone and
`fullchain.pem` is leaf + intermediate. Point nginx at `cert.pem` and you have
built exactly this outage. (nginx wants `fullchain.pem`; Apache's older
`SSLCertificateChainFile` directive took the chain separately, which is where
some of the confusion comes from.)

## Why the browsers were fine

Three reasons, and the first two are the ones that matter:

1. **Browsers cache intermediates.** Once Chrome has seen that intermediate
   from any site, it keeps it and will happily use it to complete a chain a
   server failed to send. So the first person to test is usually the least
   likely to see the failure.
2. **Browsers do AIA fetching.** If a chain is incomplete, a browser reads the
   leaf's Authority Information Access extension and *downloads* the missing
   issuer. curl, OpenSSL and Java deliberately do not — a client silently
   fetching certificates over the network to make verification succeed is a
   trade-off browsers accept and libraries do not. (The leaf in this drill has
   no AIA extension at all, which is why even that would not save it here.)
3. Browsers show a padlock for a chain they completed themselves, with no hint
   that the server misbehaved.

So the bug is invisible to the client everybody tests with and fatal to every
client that matters in production: your Java services, your `curl` healthchecks,
your Go and Python clients, mobile apps, and anything with a pinned CA bundle.

## How to check this properly

The command to keep in your head:

    openssl s_client -connect host:443 -servername host -showcerts </dev/null

Three things to read every time:

- the number of certificates in the `Certificate chain` block — a leaf plus one
  intermediate is the usual correct answer for a public CA
- the `i:` of the last certificate sent, which must be a root in your trust
  store
- `Verify return code: 0 (ok)`

`-servername` is not optional on anything shared. Without it, OpenSSL sends no
SNI and you get whichever certificate the server serves by default — which may
be a completely different site. (That is a drill of its own.)

For a one-shot external check, `openssl s_client` on a fresh machine or
`curl -v --cacert` with an explicit bundle both work; what you must avoid is
testing from somewhere that already has the intermediate.

## Worth knowing

- **Monitor the chain, not the port.** A 200 from `curl -k`, or any check that
  skips verification, cannot see this. The check that catches it verifies the
  chain against a clean trust store — and it is also the check that catches
  expiry, which is the other half of this failure class. The muted monitor in
  the report is the real root cause: it was checking reachability, not
  correctness.
- **Pin your alerting to days-until-expiry too**, from the served chain rather
  than from the file on disk, because the file being right does not mean the
  running server reloaded it.
- The same incomplete-chain bug exists in every TLS terminator: ALB and NLB
  target groups, HAProxy's `crt` file, Envoy, and any Kubernetes `tls.crt`
  secret — a Secret whose `tls.crt` holds only the leaf produces precisely
  this, and `cert-manager` writes the full chain for you, which is one of the
  better arguments for using it.
