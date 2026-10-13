# Solution: Diagnose 'the site is slow' across four layers

> Stop. Have you run `./verify.sh`?

THE ANSWER: the api opens a brand-new TCP connection to the database on every
request and pays a fixed 1.2s cost each time. Fix is to connect once and reuse
it, or to use a pool.

The RED HERRING is `proxy_read_timeout 60s` in nginx, with a comment drawing
attention to it. A timeout is an upper bound on waiting. Raising or lowering it
cannot make a fast thing slow - at most it changes whether you get a 504 instead
of a slow success. Candidates who "fix" the timeout have not diagnosed anything,
and the comment is there to see whether you believe code comments.

The ordered method, which is what is actually being scored:

 1. Split client from server. `curl -w` with time_namelookup, time_connect and
    time_starttransfer separates DNS, TCP and server think-time. Here
    time_connect is tiny and time_starttransfer is huge, so the server is slow -
    not the network, not DNS.
 2. Split proxy from app. Hit the api directly from inside nginx's namespace:
    `docker compose exec nginx wget -qO- http://api:3000/`. Still slow, so nginx
    is exonerated. THIS is where the timeout gets ruled out, by evidence.
 3. Split app from database. The response body prints `db_ms=`, and the app logs
    show the same figure. ~1200ms of a ~1250ms response is inside the database
    call path.
 4. Is the database itself slow? `docker compose exec api nc -z db 5432` returns
    instantly, and postgres logs show no slow queries. So the database is fast
    and the CALL is slow - which points at connection setup, not query
    execution. That distinction is the insight.
 5. Read the code at that boundary. A new `net.connect` per request, never
    reused.

Fix: hoist the connection outside the handler, or use a real pool (`pg.Pool`).
Then p50 drops to roughly the handler cost.

 6. What to add so nobody guesses next time:
    - request duration as a HISTOGRAM, labelled by route, so you get real
      percentiles rather than averages
    - a separate timer around the database call, so app time and dependency time
      are distinguishable in one glance - this alone would have answered the
      whole question
    - connection-pool gauges: size, in-use, waiting. A pool that is always
      empty, or always saturated, is visible immediately
    - distributed tracing, which is precisely the nginx -> api -> db span
      breakdown done properly
    - and an SLO on latency so "slow" has a definition rather than being a user's
      adjective

Say the method out loud in the interview even if you spot the answer early.
Filevine is scoring HOW you think, and "I halved the problem at each layer and
here is what each measurement eliminated" is the answer they want.

