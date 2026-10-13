"""Emits the Prometheus exposition format for the request log on stdout.

In a real exporter this is what GET /metrics would return; printing it keeps
the drill to one file and makes the output countable.

Log format, one request per line:

    <epoch> <method> <path> <status> <duration_ms> <user_id> <request_id>
"""
import os
import sys
from collections import defaultdict

BUCKETS = [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0]


def read_log(path="requests.log"):
    with open(path) as fh:
        for line in fh:
            parts = line.split()
            if len(parts) != 7:
                continue
            ts, method, p, status, dur, user, req = parts
            yield {
                "method": method,
                "path": p,
                "status": status,
                "seconds": int(dur) / 1000.0,
                "user_id": user,
                "request_id": req,
            }


def main():
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    if not os.path.exists("requests.log"):
        print("# requests.log is missing -- run ./setup.sh", file=sys.stderr)
        return 1

    counts = defaultdict(int)
    buckets = defaultdict(lambda: defaultdict(int))
    sums = defaultdict(float)
    totals = defaultdict(int)

    for r in read_log():
        key = (r["method"], r["path"], r["status"], r["user_id"], r["request_id"])
        counts[key] += 1

        bkey = (r["path"], r["user_id"])
        for b in BUCKETS:
            if r["seconds"] <= b:
                buckets[bkey][b] += 1
        sums[bkey] += r["seconds"]
        totals[bkey] += 1

    out = []
    out.append("# HELP http_requests_total Total HTTP requests.")
    out.append("# TYPE http_requests_total counter")
    for (method, path, status, user, req), n in sorted(counts.items()):
        out.append('http_requests_total{method="%s",path="%s",status="%s",'
                   'user_id="%s",request_id="%s"} %d'
                   % (method, path, status, user, req, n))

    out.append("# HELP http_request_duration_seconds Request duration.")
    out.append("# TYPE http_request_duration_seconds histogram")
    for (path, user) in sorted(buckets):
        for b in BUCKETS:
            out.append('http_request_duration_seconds_bucket{path="%s",user_id="%s",'
                       'le="%s"} %d' % (path, user, b, buckets[(path, user)][b]))
        out.append('http_request_duration_seconds_bucket{path="%s",user_id="%s",'
                   'le="+Inf"} %d' % (path, user, totals[(path, user)]))
        out.append('http_request_duration_seconds_sum{path="%s",user_id="%s"} %.3f'
                   % (path, user, sums[(path, user)]))
        out.append('http_request_duration_seconds_count{path="%s",user_id="%s"} %d'
                   % (path, user, totals[(path, user)]))

    print("\n".join(out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
