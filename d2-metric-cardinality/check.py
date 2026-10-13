"""Grades the exposition format the exporter prints.

Counts series, bans the labels that cause the explosion, and -- the part that
stops you passing by deleting metrics -- checks the numbers still add up to
every request in the log.
"""
import os
import re
import subprocess
import sys
from collections import defaultdict

BUDGET = 200
BANNED = ["user_id", "request_id", "session_id", "trace_id", "span_id",
          "email", "ip", "client_ip", "uuid"]
LINE = re.compile(r'^([a-zA-Z_:][a-zA-Z0-9_:]*)(?:\{(.*)\})?\s+(-?[0-9.eE+naN]+)\s*$')
LABEL = re.compile(r'([a-zA-Z_][a-zA-Z0-9_]*)="((?:[^"\\]|\\.)*)"')
MANY_DIGITS = re.compile(r'\d{3,}')


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    os.chdir(here)

    if not os.path.exists("requests.log"):
        print("FAIL - requests.log is missing; run ./setup.sh")
        return 1
    with open("requests.log") as fh:
        expected = sum(1 for line in fh if line.strip())

    proc = subprocess.run([sys.executable, "-I", "exporter.py"],
                          capture_output=True, text=True)
    if proc.returncode != 0:
        print("FAIL - exporter.py exited %d:" % proc.returncode)
        print("".join("  %s\n" % l for l in proc.stderr.strip().splitlines()[-6:]))
        return 1

    series = []
    for raw in proc.stdout.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        m = LINE.match(line)
        if not m:
            print("FAIL - this line is not valid exposition format:\n  %s" % line)
            return 1
        name, labelstr, value = m.group(1), m.group(2) or "", m.group(3)
        labels = dict(LABEL.findall(labelstr))
        try:
            value = float(value)
        except ValueError:
            value = float("nan")
        series.append((name, labels, value))

    problems = []

    # --- 1. the budget ------------------------------------------------------
    n = len(series)
    if n > BUDGET:
        problems.append("%d time series, budget is %d" % (n, BUDGET))

    # --- 2. labels that make every request unique ---------------------------
    seen_labels = set()
    for _name, labels, _v in series:
        seen_labels.update(labels)
    for bad in BANNED:
        if bad in seen_labels:
            problems.append("the label %r is still present; it is unique per "
                            "request or per user" % bad)

    # --- 3. paths must be templated, not literal ---------------------------
    for key in ("path", "endpoint", "route", "uri"):
        values = {labels[key] for _n, labels, _v in series if key in labels}
        literal = sorted(v for v in values if MANY_DIGITS.search(v))
        if literal:
            problems.append("the %r label still carries literal ids, e.g. %s"
                            % (key, ", ".join(literal[:3])))

    # --- 4. the numbers must still account for every request ---------------
    def total(metric):
        return sum(v for name, _l, v in series if name == metric)

    counter = total("http_requests_total")
    if counter != expected:
        problems.append("http_requests_total sums to %g, but the log has %d "
                        "requests" % (counter, expected))

    hist_count = total("http_request_duration_seconds_count")
    if hist_count != expected:
        problems.append("http_request_duration_seconds_count sums to %g, but "
                        "the log has %d requests" % (hist_count, expected))

    # --- 5. the histogram must still be a histogram -------------------------
    buckets = [(l, v) for name, l, v in series
               if name == "http_request_duration_seconds_bucket"]
    if not buckets:
        problems.append("there is no http_request_duration_seconds_bucket; a "
                        "p99 per endpoint has to stay possible")
    else:
        if any("le" not in l for l, _v in buckets):
            problems.append("some bucket series have no le label")
        by_dim = defaultdict(set)
        for l, _v in buckets:
            for k in ("path", "endpoint", "route", "uri"):
                if k in l:
                    by_dim[k].add(l[k])
        if not by_dim:
            problems.append("the histogram has no per-endpoint dimension left, "
                            "so a p99 per endpoint cannot be computed")

    # --- 6. errors must still be distinguishable ---------------------------
    status_values = set()
    for _n, labels, _v in series:
        for k in ("status", "status_class", "code", "status_code"):
            if k in labels:
                status_values.add(labels[k])
    if len(status_values) < 2:
        problems.append("no status dimension with more than one value, so an "
                        "error ratio cannot be computed")

    if problems:
        print("FAIL - %d problem(s):" % len(problems))
        for p in problems:
            print("  - %s" % p)
        return 1

    print("PASS - %d series (budget %d); every request still accounted for, "
          "per-endpoint p99 and error ratio still answerable" % (n, BUDGET))
    return 0


if __name__ == "__main__":
    sys.exit(main())
