# Batch job says done, writes nothing

**Budget:** ~30 minutes

## The report

A nightly job imports records. It logs "import complete" and exits 0 every
time. The destination table stays empty, and there is nothing in the logs about
a failure.

Running the insert by hand in psql works fine.

Make the job actually write all 8 records before it reports completion, and make
a failure inside the loop cause a non-zero exit.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
