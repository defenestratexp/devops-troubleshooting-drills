# Alerting: a six-hour outage and a silent pager

**Budget:** ~45 minutes

## The report

The API was down for six hours. No alert fired. The alerting pipeline itself
was healthy — a test alert sent afterwards arrived in four seconds.

There were three alert rules in place, including one written after a previous
incident **specifically to catch the service being gone**. `rules.yml` has all
three, `prometheus.yml` has the scrape configuration, and `timeline.md` has
what actually happened minute by minute.

Four separate things went wrong. Two are defects in the rules, one is a
configuration mismatch, and one is a gap in the whole design rather than in
any single rule.

The engineer who looked at the dashboard at 08:52 concluded the graph was
broken. Understanding why that was a reasonable conclusion is part of the
exercise.

This one is graded on your reasoning: write `ANSWERS.md`, then `./verify.sh`.

No cluster needed.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
