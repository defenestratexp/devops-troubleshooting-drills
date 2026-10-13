# Postgres: FATAL too many clients, and who is to blame

**Budget:** ~35 minutes

## The report

An application starts failing with:

    FATAL: sorry, too many clients already

Restarting the app clears it for a while and it comes back. The team wants to
raise max_connections. Decide whether that is the right call, and prove what is
actually holding the connections.

    ./setup.sh     # starts a postgres with a low limit, plus some bad clients

This mirrors a real incident in my own history: KEDA-driven worker scaling
demanded ~9,700 connections against a ceiling of ~3,604.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
