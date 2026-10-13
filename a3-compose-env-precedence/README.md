# Compose: wrong password despite the env file

**Budget:** ~25 minutes

## The report

A developer set the database password in `.env` and in `db.env`, but the api
still fails to authenticate. They insist the password is correct, and it IS the
one in the files they showed you.

    docker compose up --abort-on-container-exit --exit-code-from api

Make the api print `OK authenticated`. Do not change the password VALUE
anywhere - work out which value is actually winning and why.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
