#!/usr/bin/env bash
# Exercises each failure mode separately, because fixing one masking mechanism
# leaves the others, and a partial fix must not pass.
cd "$(dirname "$0")"
fails=0

check_fails_and_no_deploy() {
  local label="$1"; shift
  rm -rf build
  env "$@" ./pipeline.sh >/dev/null 2>&1
  local rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "FAIL - $label: pipeline exited 0"
    fails=$((fails+1))
  fi
  if [ -f build/deployed.txt ]; then
    echo "FAIL - $label: deployed anyway (build/deployed.txt was written)"
    fails=$((fails+1))
  fi
}

check_fails_and_no_deploy "failing unit tests"        FAIL_SUITES=unit
check_fails_and_no_deploy "failing integration tests" FAIL_SUITES=integration

# A failing deploy must fail the pipeline. It legitimately may have written
# nothing, so only the exit code is checked here.
rm -rf build
FAIL_DEPLOY=1 ./pipeline.sh >/dev/null 2>&1
[ $? -eq 0 ] && { echo "FAIL - failing deploy: pipeline exited 0"; fails=$((fails+1)); }

# The happy path must still work, and must still produce its artifacts.
rm -rf build
out=$(./pipeline.sh 2>&1)
rc=$?
[ "$rc" -ne 0 ] && { echo "FAIL - clean run exited $rc; you made it fail unconditionally"; fails=$((fails+1)); }
[ -f build/deployed.txt ] || { echo "FAIL - clean run did not deploy"; fails=$((fails+1)); }
[ -f build/app.tar ]     || { echo "FAIL - clean run did not package"; fails=$((fails+1)); }
grep -q 'unit' build/unit.log 2>/dev/null \
  || { echo "FAIL - build/unit.log is missing or empty; keep the tee, do not delete it"; fails=$((fails+1)); }
grep -q 'running the unit suite' <<<"$out" \
  || { echo "FAIL - unit test output no longer reaches the console; keep the tee"; fails=$((fails+1)); }

rm -rf build
[ "$fails" -eq 0 ] && { echo "PASS - every failing stage fails the pipeline and blocks the deploy; clean run still works"; exit 0; }
echo "-- $fails problem(s) remaining"
exit 1
