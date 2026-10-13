# A filter silently drops rows

**Budget:** ~25 minutes

## The report

A report is supposed to list all active users. It lists 3. The table has 8
users and only 1 is actually archived, so the answer should be 7.

The query looks obviously correct, the column exists, and there is no error.

Make the report return the 7 active users.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
