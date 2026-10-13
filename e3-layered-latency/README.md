# Diagnose 'the site is slow' across four layers

**Budget:** ~45 minutes

## The report

A user reports the site is slow. That is all you get. The stack is
nginx -> api -> postgres, all in compose, and there is one deliberate red
herring that looks like the cause and is not.

    ./setup.sh
    curl -w '\n  total=%{time_total}s\n' -s -o /dev/null http://localhost:8081/

Requests take several seconds. Find the ACTUAL cause, in order, writing down
what you ruled out and how. Then fix it so p50 is under 300ms.

This is the closest exercise to Filevine's step 2 - they present a scenario and
score critical thinking and end-to-end ownership. Narrate out loud as you go.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
