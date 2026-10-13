# TLS: fine in the browser, broken everywhere else

**Budget:** ~35 minutes

## The report

A certificate was renewed on Tuesday. The site looks fine in Chrome and
Firefox — padlock, no warning, nobody complained.

Since Tuesday:

- the Java service that calls this API fails with
  `unable to find valid certification path to requested target`
- a `curl` from the deploy host fails with
  `SSL certificate problem: unable to get local issuer certificate`
- the monitoring check went red, and was muted because "the site is clearly up"

The certificate itself is valid, in date, has the right name on it, and is
signed by a CA everyone involved trusts.

    ./setup.sh                 # builds the drill's own little CA
    docker compose up -d
    curl --cacert pki/root.crt --resolve drill.n9n.test:18443:127.0.0.1 \
         https://drill.n9n.test:18443/

The CA here is a three-level one — root, intermediate, leaf — like every
public CA in use. That structure is a requirement and not the bug: do not fix
this by re-signing the leaf directly from the root, and do not add anything to
a trust store.

Needs Docker, OpenSSL and curl. Nothing touches your system trust store.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
