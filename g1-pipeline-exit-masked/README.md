# CI: the pipeline is green and the tests are failing

**Budget:** ~30 minutes

## The report

A broken build reached production on Friday. The pipeline was green for it.

Running the tests by hand shows two failures. The pipeline runs the same tests,
prints the same failures in its console log, and then reports success and
deploys. Someone has been looking at that green tick for weeks.

    FAIL_SUITES=unit ./pipeline.sh ; echo "exit=$?"

There are **three** independent reasons this script cannot fail, and they are
three different mechanisms. Fixing one still leaves the other two.

Two things that look like bugs are requirements, so do not "fix" them by
deletion:

- The unit test output has to appear on the console **and** land in
  `build/unit.log`. That is what the `tee` is for.
- A failing deploy has to be distinguishable in the log from a failing test.

Needs only bash.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
