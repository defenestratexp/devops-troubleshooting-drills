# Random lookup fails most of the time

**Budget:** ~30 minutes

## The report

An endpoint returns a random row. It works, sometimes. Hit it ten times and
you get a body maybe twice; the rest come back empty. There is no pattern to
which requests succeed.

The table has rows. The query is correct SQL. The connection is fine.

Make 25 consecutive requests all return a non-empty body.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
