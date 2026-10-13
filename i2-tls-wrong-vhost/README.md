# TLS: the wrong site answers for a name nobody configured

**Budget:** ~30 minutes

## The report

Two sites on one nginx: `app.n9n.test` and `admin.n9n.test`. Both work.

A monitoring check was added for a third name that has not been set up yet.
Instead of failing cleanly, it came back **200 OK** — serving the app's
content, under a certificate issued to `app.n9n.test`.

Which raised a worse question that nobody could answer: when a client connects
to this server for a hostname that has no configuration at all, what does it
get, and why that one?

    ./setup.sh
    docker compose up -d

    curl -sS --cacert pki/root.crt --resolve app.n9n.test:18444:127.0.0.1   https://app.n9n.test:18444/
    curl -sS --cacert pki/root.crt --resolve admin.n9n.test:18444:127.0.0.1 https://admin.n9n.test:18444/
    curl -skS            --resolve other.n9n.test:18444:127.0.0.1 https://other.n9n.test:18444/

Make it so that:

1. `app.n9n.test` still serves `app`, under its own certificate.
2. `admin.n9n.test` still serves `admin`, under its own certificate.
3. A hostname with no configuration gets **neither** — no content from either
   site, and no certificate belonging to either site.

Needs Docker, OpenSSL and curl.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
