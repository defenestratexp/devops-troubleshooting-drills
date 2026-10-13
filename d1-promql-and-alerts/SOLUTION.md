# Solution: Observability: the alert that never fires and the one that always does

> Stop. Have you run `./verify.sh`?

RULE 1 - ServiceErrors. Two defects.
  a) `status="500"` matches ONLY 500. A 503 outage - which is what a load
     balancer returns when it has no healthy backends, and the single most
     likely shape of a real outage - matches nothing. Use a regex:
     `status=~"5.."`.
  b) `for: 30m` on a page is far too long. A 20-minute outage ends before the
     alert matures, so it never fires at all. This is the actual reason nobody
     got called.
  Corrected:
     expr: sum(rate(http_requests_total{status=~"5.."}[5m]))
           / sum(rate(http_requests_total[5m])) > 0.05
     for: 5m
  Note the move to a RATIO. An absolute rate of 0.05 errors/sec means something
  completely different at 10 rps than at 10,000 rps. Symptom-based, traffic-
  normalised alerting is the point.

RULE 2 - HighLatency. `http_request_duration_seconds{quantile="0.99"}` is
summary-metric syntax. If the metric is a HISTOGRAM there is no `quantile`
label, the selector matches nothing, and it would never fire - but as written it
pages constantly, which tells you it IS a summary and is being evaluated
per-series with no aggregation and no `for`. A single slow instance, or one
scrape blip, pages immediately.
  Corrected, for a histogram:
     expr: histogram_quantile(0.99,
             sum by (le) (rate(http_request_duration_seconds_bucket[5m]))) > 0.3
     for: 10m
  Aggregate THEN take the quantile; add a `for` so a single scrape cannot page.
  Also: averaging or quantiling across instances without `sum by (le)` is
  statistically meaningless - you cannot average percentiles.

RULE 3 - DiskWillFillSoon. It fires at a threshold, which means it pages when
the disk is ALREADY 90% full - possibly minutes from an outage - and it says
nothing about trend. A 90%-full disk that is stable is not an incident; a
40%-full disk filling fast is.
     expr: predict_linear(node_filesystem_avail_bytes[6h], 4*3600) < 0
     for: 15m
  This is precisely the Elasticsearch retention-job incident: the cluster
  reached 90% with nothing alerting. predict_linear would have caught it days
  earlier. Use that story here.

A. Availability SLI over 30 days:
     sum(rate(http_requests_total{service="api", status!~"5.."}[30d]))
     / sum(rate(http_requests_total{service="api"}[30d]))

B. Multi-window fast burn for 99.9% (burn rate 14.4):
     (
       sum(rate(http_requests_total{service="api", status=~"5.."}[1h]))
       / sum(rate(http_requests_total{service="api"}[1h])) > 14.4 * 0.001
     )
     and
     (
       sum(rate(http_requests_total{service="api", status=~"5.."}[5m]))
       / sum(rate(http_requests_total{service="api"}[5m])) > 14.4 * 0.001
     )
  The long window establishes significance; the short window makes it stop
  firing quickly once the burn stops. Without the short window the alert hangs
  around for an hour after recovery.

C. 30-day budget for 99.9%:
     30 days = 43,200 minutes
     0.1% of 43,200 = 43.2 minutes of allowed unavailability per 30 days.
  For 99.95% it is 21.6 minutes; for 99.99% it is 4.32 minutes. Being able to
  state 43.2 minutes without hesitating is the single highest-value fact to
  memorise for these interviews - it comes up constantly and it signals you
  think in budgets rather than percentages.

A burn rate of 14.4x means: at this rate the entire 30-day budget is gone in
30/14.4 = ~2 days. That is why 14.4 is the conventional fast-burn threshold.

