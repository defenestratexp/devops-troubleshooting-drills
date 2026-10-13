Write your answers in `ANSWERS.md` before reading `SOLUTION.md`.

1. **The ratio alert.** Between 02:14 and 02:23 the error ratio really was
   above 5%. `for: 10m` is part of the answer for that window. But after 02:28
   the alert could not have fired however long the outage lasted. Explain what
   `job:api_error_ratio:rate5m` evaluates to once the api series no longer
   exist, and why `> 0.05` is not true of it.

2. **The down alert.** `up{job="api-service"} == 0`. Compare that with
   `prometheus.yml` and say exactly why it never fired. Then say what the
   expression evaluates to — this is the important bit, and it is not `0`.

3. **Staleness.** After the last successful scrape at 02:23, how long does
   Prometheus keep returning a value for those series, and what happens after
   that? Look up the staleness handling and the 5-minute lookback delta, and
   say which of the two applies when a target disappears from service
   discovery versus when a scrape fails.

4. **The dashboard.** A flat line at zero. Say what `rate()` of a counter
   returns when the counter has stopped existing, how that renders on a graph,
   and why "zero errors" and "no data" look identical on a default panel.
   What would you change about the panel?

5. **The rules you would add.** Write the actual expressions:
   - an alert that fires when the api metrics stop being reported at all
   - an alert that fires when the scrape target is down, written so that a
     job rename cannot silently disable it
   - a check that the alerting pipeline itself is alive

6. **The design gap.** Name the pattern in 5c, say which component has to
   evaluate it, and explain why it cannot live in Prometheus alone.

7. **The `for:` interaction.** An alert is in Pending at 02:20, four minutes
   into its `for: 10m`. At 02:28 the series goes stale. What happens to the
   pending alert, and what does that mean for using long `for:` durations on
   symptom alerts?
