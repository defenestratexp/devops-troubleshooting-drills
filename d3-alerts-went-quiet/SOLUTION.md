# Solution: Alerting: a six-hour outage and a silent pager

> Stop. Have you run `./verify.sh`?

Every one of these failures has the same shape: **an alert that can only fire
when the data exists, protecting a system whose failure removes the data.**

## 1. The ratio alert cannot fire on an absent metric

    job:api_error_ratio:rate5m > 0.05

Once the api pods stop being scraped, `http_requests_total{job="api"}` has no
series. `rate()` over no series returns an **empty vector**, not zero. Dividing
empty by empty is empty. Comparing empty to `0.05` is empty.

A PromQL comparison is a *filter*, not a boolean: `x > 0.05` returns the
elements of `x` that exceed 0.05. If `x` has no elements, the result has no
elements, so the alert has nothing to fire on. It is not false — there is
simply nothing there.

This is the single most important thing to understand about alerting on ratios
and rates: **they are defined only while the system is working well enough to
report.** The better the alert is at measuring quality of service, the more
completely it goes quiet when service stops entirely.

The `for: 10m` compounds it for the 02:14–02:23 window: the ratio was high for
nine minutes, which is less than ten, so the alert never matured out of
Pending. Then the data vanished.

## 2. The down alert matched nothing at all

    up{job="api-service"} == 0

The scrape config's `job_name` is `api`. So `up{job="api-service"}` is a
selector that matches **no time series** — and again, `== 0` over an empty
vector is empty. The alert has been incapable of firing for eleven weeks, since
the migration renamed the job.

The diagnosis worth internalising: this rule looked correct in review, and a
rule that selects nothing is **indistinguishable from a rule whose condition is
never met**. Both are permanently silent and both look fine in the UI. The
job rename did not break the alert loudly; it deleted it.

There is a general principle here: **every alert that depends on a label value
is one rename away from being deleted**, silently. Which is why part 5 asks for
one written so a rename cannot disable it.

## 3. Staleness

Two mechanisms, and the distinction is the answer:

- **A failed scrape** marks the series **explicitly stale**. Prometheus writes
  a stale marker, and from the next evaluation the series is gone from query
  results. This is what happened at 02:28 — fast, within a scrape interval or
  two of the target failing.
- **A target that disappears from service discovery** stops being scraped with
  no failure. Its last sample then remains visible for the **lookback delta**,
  which defaults to **5 minutes**: a query at time T can see a sample up to 5
  minutes old. After that, the series reads as absent.

So for roughly five minutes after the pods went away, queries still returned
the last known values — the pre-outage healthy ones. Then everything went
empty. That five-minute window of stale-but-healthy data is its own hazard: it
is long enough for an alert to resolve and send an "OK" notification.

## 4. The dashboard

`rate()` over an absent counter returns an empty vector, so the panel receives
**no data points**, not zero-valued ones. On a default Grafana time series
panel with "connect null values" or with points simply absent, that renders as
a line that stops, or — if the panel is a stat/gauge, or the query is wrapped
in something that defaults to zero — as a flat line at zero.

"Zero errors" and "no data" are therefore the same picture. The engineer at
08:52 was looking at an honest graph and could not tell which one it was
showing. Concluding the graph was broken was reasonable.

What to change:

- Set the panel's "No value" handling explicitly, and do not connect null
  values — a gap should look like a gap.
- Put `up{job="api"}` or the request rate on the same dashboard, as a panel
  that goes to zero when nothing is being scraped. A **traffic** panel next to
  an **error ratio** panel disambiguates every flat line: no traffic plus no
  errors is "not running"; traffic plus no errors is "healthy".
- Do not use `or vector(0)` to make the graph prettier. It makes "no data"
  render as a confident zero, which is exactly the ambiguity you are trying to
  remove.

## 5. The rules to add

**a. The metrics stopped being reported.**

    - alert: ApiMetricsAbsent
      expr: absent(http_requests_total{job="api"})
      for: 5m
      labels: {severity: page}
      annotations:
        summary: "no api request metrics for 5m -- the service or its exporter is gone"

`absent()` returns `1` when its argument matches nothing, and nothing when it
matches something. It is the inverse of a selector and the direct answer to
"alert me when this disappears". `absent_over_time(http_requests_total{job="api"}[10m])`
is the more robust form — it tolerates a single missed scrape, where plain
`absent()` plus a short `for:` can be noisy on a restart.

**b. The target is down, written so a rename cannot disable it.**

    - alert: ScrapeTargetDown
      expr: up == 0
      for: 5m
      labels: {severity: page}
      annotations:
        summary: "{{ $labels.job }}/{{ $labels.instance }} has been down for 5m"

`up == 0` with **no job selector** cannot be silently narrowed to nothing by a
rename — it covers every target Prometheus knows about, and the labels come
through in the annotation. This is the pattern: alert broadly on the generic
signal, and use labels for routing rather than for selection. Where you must
scope it, pair it with an `absent(up{job="api"})` so the scoping itself is
monitored.

**c. The alerting pipeline is alive.**

    - alert: Watchdog
      expr: vector(1)
      labels: {severity: none}
      annotations:
        summary: "this alert always fires; its absence is the alert"

## 6. The design gap

That is the **dead man's switch** (Prometheus's own bundled version is called
`Watchdog`). An alert that always fires, routed to a receiver that expects it
on a schedule — and raises an alarm when it **stops** arriving.

The key point, and the thing the question is really asking: **the evaluator has
to live outside Prometheus.** Prometheus cannot alert on its own death; nor can
Alertmanager alert on Prometheus's death, if the only path to Alertmanager is
through Prometheus. Something external must be the one waiting: Dead Man's
Snitch, healthchecks.io, Cronitor, a second independent Prometheus, or a cron
job somewhere else that pages if the heartbeat is late.

This closes the whole class of failure in this incident. Every other fix here
is specific — absent on this metric, up for this target. The dead man's switch
catches "we are not receiving anything", including the failures nobody
predicted: Prometheus OOM-killed, its disk full, the rules file failing to
load, a network partition, the config reloaded with a typo, the whole cluster
gone.

## 7. The `for:` interaction

An alert in Pending has its state discarded if its series stops being returned.
At 02:20 `ApiErrorRatioHigh` is four minutes into a ten-minute `for:`. At 02:28
the series goes stale, the expression returns nothing, the pending alert is
dropped, and the ten-minute clock is simply gone. It never fires and it never
resolves — it just stops existing.

Which gives the rule of thumb: **a long `for:` on a symptom alert is a
liability.** The longer the window, the larger the class of outages that are
over, or have escalated past the point of producing data, before the alert
matures. Use a short `for:` plus a short-and-long multi-window burn rate for
significance, rather than a single long `for:` for noise suppression.

## The summary worth being able to give

> Our alerts all described what "bad" looks like. None of them described what
> "nothing" looks like. When the service stopped entirely, every rule
> evaluated to an empty vector and fell silent — and a rule that selects
> nothing is indistinguishable from a rule that is simply not firing.

Three habits:

- For every alert, ask: **what does this do if the metric disappears?** If the
  answer is "nothing", pair it with an `absent()`.
- **Alert on the absence of good**, not only the presence of bad. "Requests per
  second is below X" catches outages that "error ratio above Y" cannot.
- **Test the alert, not the alerting.** A test notification proves the pager
  works. Firing a real rule — by breaking something in staging, or by
  temporarily inverting the threshold — proves the rule works. The second one
  is the one nobody does, and it is the only one that would have caught the
  `api-service` typo.
