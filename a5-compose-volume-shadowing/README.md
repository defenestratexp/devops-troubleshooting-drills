# Compose: MODULE_NOT_FOUND after adding a bind mount

**Budget:** ~20 minutes

## The report

This worked before someone added a bind mount for live reload. Now:

    Error: Cannot find module 'left-pad'

The dependency IS in package.json, and `docker compose build` succeeds and
installs it - you can see it in the build output. Make the api print
`OK 00042`.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
