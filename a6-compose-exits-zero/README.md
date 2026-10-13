# Compose: worker exits immediately with code 0

**Budget:** ~20 minutes

## The report

The worker container "won't stay up". It exits 0 within a second, so nothing
looks like an error - no stack trace, no non-zero code. `docker compose ps`
shows nothing running. `docker compose logs worker` prints the startup banner
and then nothing.

Make the worker stay running for at least 10 seconds and keep printing a
heartbeat, without using `restart: always` to paper over it.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
