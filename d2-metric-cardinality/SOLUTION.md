# Solution: Metrics: 2,000 requests, 27,857 time series

> Stop. Have you run `./verify.sh`?

## Where 27,857 comes from

A metric's series count is the **product** of the distinct values of its
labels. Taking the counter:

    http_requests_total{method, path, status, user_id, request_id}

- `method` — 2 values. Bounded.
- `status` — 3 values. Bounded.
- `path` — `/orders/83921`, `/orders/12004`, … **one value per order id.**
- `user_id` — one per user. Thousands, growing forever.
- `request_id` — **one value per request.**

`request_id` alone guarantees one series per request, so the counter can never
be anything other than the size of the log. Every other label is then free,
because the damage is already total.

The histogram is worse per series:

    http_request_duration_seconds_bucket{path, user_id, le}

`le` has 11 values, so every distinct `(path, user_id)` pair costs 11 bucket
series plus `_sum` and `_count` — 13 series per pair. **Histograms multiply.**
That is why the expensive metric in a cardinality incident is almost always a
histogram, and why adding one label to a histogram is a bigger decision than
adding one to a counter.

## The fix

**Delete `request_id` and `user_id`.** They are per-request and per-user
identifiers. A counter labelled with a unique id is not a counter — it is a
log line in a format that cannot be searched, stored in a system that keeps
every series in memory. If you want to answer "what happened to this
particular request", that is tracing or logging, which are built for high
cardinality. Metrics are built for aggregates.

**Template the path into a route.** The path is unbounded because it contains
identifiers; the route is bounded because it is a property of the code:

    /orders/83921        ->  /orders/{id}
    /users/5512/profile  ->  /users/{id}/profile

Six routes instead of thousands of paths. Every web framework can give you the
matched route — in Flask it is `request.url_rule`, in Django
`request.resolver_match.route`, in Express `req.route.path`. Reaching for
`request.path` is the mistake, and it is the default thing to hand.

This also answers the "new endpoint" question: a path you have never seen
creates a new series forever under the old code. Under a route label it
creates one series, bounded by the number of routes in the application.

**Keep `status`, or collapse it to a class.** Three values is cheap, and you
need it for the error ratio. `status_class` (`2xx`/`4xx`/`5xx`) is the usual
compromise — it is enough for alerting and SLOs, and it stays bounded if
someone starts returning 418s. You lose the ability to distinguish 401 from
403 in metrics, which is a logging question anyway.

**Drop the extra dimension from the histogram.** Keep `endpoint` and `le`, and
nothing else. A p99 per endpoint is a real requirement; a p99 per user is not,
and it costs 13 series per user.

The result is 81 series instead of 27,857, from the same data, answering the
same three questions.

## What "cardinality" costs, concretely

Worth being able to say why anyone cares:

- Prometheus holds an **index entry and an in-memory chunk per active
  series**. The usual rule of thumb is a few kilobytes of resident memory per
  series, so a million series is gigabytes before any queries run. That is the
  OOM.
- The scrape itself grows: two megabytes of text every 15 seconds, parsed
  every time.
- Queries scan matching series. `sum(rate(http_requests_total[5m]))` over
  27,857 series is slow; over 16 it is instant. The dashboard timeouts and the
  OOM are the same root cause.
- Series are **not** freed when they stop being reported — they stay queryable
  for the retention period. So a one-off deploy that emitted a bad label leaves
  the cost behind for weeks.

## The habits

- **Before adding a label, state its cardinality out loud.** If the answer is
  "it depends on the data" rather than a number you could write down, it does
  not belong on a metric. The test: can you name every value it will ever have?
- **Never label a metric with anything derived from a request or a user**: ids,
  emails, IPs, URLs with parameters, user agents, error messages, SQL
  statements, trace ids. Error *messages* are a particularly common one, and
  they are unbounded by construction.
- **Treat a histogram's labels as 13x more expensive** than a counter's, or
  whatever your bucket count is.
- Metrics, logs and traces answer different questions. "How often, how slow,
  how many" is metrics. "What happened to this one request" is tracing.
  Cardinality explosions are almost always someone trying to answer the second
  question with the first tool.

If you inherit a Prometheus and want to know where its memory went, the
query is

    topk(10, count by (__name__)({__name__=~".+"}))

and `prometheus_tsdb_symbol_table_size_bytes` plus the `/api/v1/status/tsdb`
endpoint give you the same answer with less effort.
