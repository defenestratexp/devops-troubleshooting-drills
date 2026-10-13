#!/usr/bin/env bash
# Writes build/deployed.txt on success. That file is the evidence of what the
# pipeline pushed, and the grader checks it: a failed build must not deploy.
mkdir -p build
if [ "${FAIL_DEPLOY:-0}" = "1" ]; then
  echo "deploy: could not reach the target host" >&2
  exit 1
fi
printf 'deployed %s\n' "$(date -u +%FT%TZ)" > build/deployed.txt
echo "deploy: ok"
