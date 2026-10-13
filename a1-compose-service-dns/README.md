# Compose: connection refused between services

**Budget:** ~20 minutes

## The report

A developer says the api container cannot reach the database. It worked on
their laptop. `docker compose up` brings both containers up and neither exits.

Reproduce:
    docker compose up --abort-on-container-exit --exit-code-from api

Fix it so the api prints `OK connected` and exits 0. Change as little as
possible, and be able to say WHY it failed.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
