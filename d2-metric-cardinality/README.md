# Metrics: 2,000 requests, 27,857 time series

**Budget:** ~35 minutes

## The report

Prometheus was OOM-killed twice overnight. Its memory had been climbing for a
week and `/metrics` on one service now takes four seconds to scrape and
returns about two megabytes. Grafana dashboards for that service time out.

The service handles a modest 2,000 requests in the sample window.

    ./setup.sh
    python3 exporter.py | grep -vc '^#'      # how many series that is

`exporter.py` is the instrumentation. Fix it so that:

1. It emits **at most 200** time series.
2. Every request in `requests.log` is still counted — the counter and the
   histogram must both still add up to 2,000.
3. These three questions must still be answerable from the metrics:
   - total requests, broken down by endpoint and method
   - the **error ratio** per endpoint
   - the **p99 latency** per endpoint

Requirement 2 and 3 exist because the easy way to hit a cardinality budget is
to delete metrics, and that is not instrumentation, it is silence.

Needs only python3.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
