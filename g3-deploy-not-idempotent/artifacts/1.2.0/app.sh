#!/usr/bin/env bash
# 1.2.0 shipped with a bad config path. It exits non-zero on startup -- which
# is exactly what a health check is for.
echo "app 1.2.0: cannot open /etc/app/missing.conf" >&2
exit 1
