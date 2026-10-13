# Compose: api crashes on first start, fine on retry

**Budget:** ~25 minutes

## The report

Intermittent in CI, works locally "most of the time". The api exits non-zero
roughly every other run with a connection error, and a plain re-run often
succeeds. A developer has already added `depends_on` and says that should have
fixed it.

    docker compose up --abort-on-container-exit --exit-code-from api

Make it pass RELIABLY. Run it at least three times to prove it.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
