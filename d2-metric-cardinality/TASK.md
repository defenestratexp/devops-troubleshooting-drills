Measure before you change anything:

    ./setup.sh
    python3 exporter.py | grep -vc '^#'              # total series
    python3 exporter.py | grep http_requests_total | head -3

Then work out where the number comes from. The rule is worth deriving rather
than memorising:

    a metric's series count = the product of the number of distinct values
    of each of its labels

So for each label on each metric, ask: **how many distinct values can this
have, and is that number bounded?** Write the answer down for every label in
the exporter — `method`, `path`, `status`, `user_id`, `request_id`, `le`.

Two of them have no bound at all. One of them is bounded in principle and
unbounded in practice. And one metric multiplies whatever it is given by the
number of histogram buckets, which is why it is the expensive one.

    python3 exporter.py | grep -c duration_seconds_bucket

Questions to answer out loud:

  1. What question would `user_id` on a counter let you answer, and is a
     metrics system the right place to answer it?
  2. `path` looks bounded — there are only a handful of routes. Why is it not?
     What is the difference between a path and a route?
  3. `status` has three values here. Would you keep it as-is, or collapse it,
     and what do you lose either way?
  4. A request arrives for an endpoint you have never seen. How many new
     series does that create under the current code, and how many under yours?

Then fix the instrumentation, keeping requirements 2 and 3 in mind.
