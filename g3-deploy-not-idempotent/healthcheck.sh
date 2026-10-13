#!/usr/bin/env bash
# Stands in for a real readiness probe: starts the app in the given release
# directory and reports whether it came up.
#
#   ./healthcheck.sh                  # checks whatever `current` points at
#   ./healthcheck.sh releases/1.1.0   # checks one specific release
#
# The optional argument is the whole reason you can check a release before you
# send traffic to it.
cd "$(dirname "$0")"
target="${1:-current}"

if [ ! -e "$target/app.sh" ]; then
  echo "healthcheck: nothing to check at $target" >&2
  exit 1
fi
if "$target/app.sh" >/dev/null 2>&1; then
  echo "healthcheck: $target ok"
  exit 0
fi
echo "healthcheck: $target FAILED" >&2
exit 1
