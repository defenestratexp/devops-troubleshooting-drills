# Import reports success but the table has one row

**Budget:** ~30 minutes

## The report

A seed importer runs clean - exit 0, "imported 12 quotes" on stdout, no
errors anywhere. But the app shows the same quote every time, and

    SELECT count(*) FROM quotes;

returns 1. The import has been "working" for weeks.

Get all 12 rows into the table. Do not delete the constraint.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
