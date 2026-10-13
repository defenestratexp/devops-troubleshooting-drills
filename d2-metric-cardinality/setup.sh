#!/usr/bin/env bash
# Generates the request log the exporter reads. Deterministic -- fixed seed --
# so the series counts in the README are the counts you will see.
set -euo pipefail
cd "$(dirname "$0")"
python3 -I - <<'PY'
import random

random.seed(20261013)

ENDPOINTS = [
    ("GET",  "/orders/%d",          lambda r: r.randint(10000, 99999)),
    ("GET",  "/users/%d/profile",   lambda r: r.randint(1000, 9999)),
    ("POST", "/orders/%d",          lambda r: r.randint(10000, 99999)),
    ("GET",  "/api/v1/items/%d",    lambda r: r.randint(100, 999)),
    ("GET",  "/search",             None),
    ("GET",  "/health",             None),
]

rows = []
t = 1760000000
for i in range(2000):
    method, template, idgen = random.choice(ENDPOINTS)
    path = template % idgen(random) if idgen else template
    if path == "/health":
        status, dur = 200, random.randint(1, 4)
    else:
        roll = random.random()
        status = 200 if roll < 0.93 else (404 if roll < 0.97 else 500)
        dur = random.randint(5, 900)
    t += random.randint(0, 3)
    rows.append("%d %s %s %d %d u-%d %s" % (
        t, method, path, status, dur,
        random.randint(1000, 8000),
        "".join(random.choice("0123456789abcdef") for _ in range(16)),
    ))

with open("requests.log", "w") as fh:
    fh.write("\n".join(rows) + "\n")
print("wrote requests.log: %d requests" % len(rows))
PY
