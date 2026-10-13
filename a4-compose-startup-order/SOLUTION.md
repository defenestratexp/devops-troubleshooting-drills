# Solution: Compose: api crashes on first start, fine on retry

> Stop. Have you run `./verify.sh`?

`depends_on` in its short list form waits for the container to be STARTED,
not for the application inside it to be READY. Postgres here sleeps 6 seconds
before even execing its entrypoint, so the api races it and usually loses.

Fix: give db a healthcheck and make the dependency conditional.

    db:
      healthcheck:
        test: ["CMD-SHELL", "pg_isready -U postgres"]
        interval: 2s
        timeout: 3s
        retries: 20
    api:
      depends_on:
        db:
          condition: service_healthy

Points worth making out loud:
- `condition: service_started` is the default and is what the short form means.
  `service_healthy` requires a healthcheck to exist; without one Compose errors.
- A healthcheck is not free - it runs on an interval forever, so `pg_isready`
  (cheap) is right and `psql -c 'select 1'` (a real connection per interval) is
  not.
A note on compose syntax, learned building this exercise: a `command:`
written as a folded scalar (`command: >`) collapses to one line and is then
word-split, which mangles shell operators such as && and brace groups -
producing `sh: syntax error: unexpected "&&"`. The explicit argv list form,
`command: ["sh","-c","..."]`, removes the ambiguity entirely.

- The DEEPER answer, and the one that separates senior candidates: orchestrator
  ordering is a convenience, not a correctness guarantee. In Kubernetes there is
  no `depends_on` at all. The client should retry with backoff, because the
  database can also disappear at 3am long after startup. Say both: here is the
  compose fix, and here is why the application still needs to tolerate it.

