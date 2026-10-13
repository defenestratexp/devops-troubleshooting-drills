# Observability: the alert that never fires and the one that always does

**Budget:** ~40 minutes

## The report

Two complaints from the same team, same week:

  1. "We had a 20-minute outage and PagerDuty never called anyone."
  2. "The HighLatency alert pages constantly and we have started ignoring it."

`rules.yml` holds the alerting rules. Find the defect in each, and write the
corrected rules. Then write the two PromQL queries asked for at the bottom of
TASK.md. No cluster needed - this is reading and writing, graded on reasoning.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
