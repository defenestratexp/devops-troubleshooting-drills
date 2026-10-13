# Compose: published port refuses connections

**Budget:** ~25 minutes

## The report

The api service is published on port 8080. `docker compose ps` shows it
running and healthy-looking, but from the host:

    curl -sS http://localhost:8080/        -> connection reset / empty reply

Container logs show the server started. Make `curl http://localhost:8080/`
return `hello` from the host.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
