#!/usr/bin/env bash
# Stands in for the real test runner. Fails whichever suites are named in
# FAIL_SUITES, so the drill can reproduce each failure on demand.
suite="${1:-unit}"
echo "running the $suite suite"
case " ${FAIL_SUITES:-} " in
  *" $suite "*)
    echo "FAILED: 2 assertions in $suite"
    exit 1
    ;;
esac
echo "ok: 0 failures in $suite"
