# DNS: every external call does three lookups

**Budget:** ~35 minutes

## The report

A service was moved into the cluster. Nothing about its code changed. Its
p99 latency went up by about 40ms per outbound call, and the DNS server's
query rate went up by roughly 3x for the same traffic.

Someone looked at the DNS server's logs and found that most of the questions
it is being asked are for names that do not exist, and never have.

    docker compose up -d
    docker compose exec client getent ahosts api.vendor.test
    docker compose exec dns cat /var/log/dns/queries.log

Two names exist: `api.vendor.test` (external) and `payments.svc.drill.local`
(internal, normally called as just `payments`). Everything else is NXDOMAIN.

Make it so that:

1. Resolving `api.vendor.test` asks about **that name and nothing else**.
2. The short name `payments` still resolves.

Both matter. The obvious way to satisfy the first one breaks the second.

`dnsd.py` is the instrument — it records every question it is asked. Read it;
do not edit it.

Needs Docker.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
