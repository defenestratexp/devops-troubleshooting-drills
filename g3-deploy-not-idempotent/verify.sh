#!/usr/bin/env bash
# Replays both incidents and checks the end state after each.
cd "$(dirname "$0")"
fails=0
# releases/.keep is tracked so the directory exists on a fresh clone; put it
# back or running the grader leaves the repository dirty.
reset() { rm -rf releases current; mkdir -p releases; touch releases/.keep; }

note() { echo "FAIL - $1"; fails=$((fails+1)); }

# --- a clean first deploy still has to work ---------------------------------
reset
./deploy.sh 1.0.0 >/dev/null 2>&1 || note "a clean deploy of 1.0.0 failed"
[ "$(readlink current)" = "releases/1.0.0" ] || note "current is $(readlink current 2>/dev/null || echo unset), expected releases/1.0.0"
./healthcheck.sh >/dev/null 2>&1 || note "1.0.0 is not healthy after deploy"

# --- Tuesday: the retry ----------------------------------------------------
if ! ./deploy.sh 1.0.0 >/dev/null 2>&1; then
  note "redeploying 1.0.0 failed; the deploy is not idempotent"
fi
[ "$(readlink current)" = "releases/1.0.0" ] || note "after the retry current is $(readlink current 2>/dev/null || echo unset)"
./healthcheck.sh >/dev/null 2>&1 || note "not healthy after the retry"

# --- a real upgrade --------------------------------------------------------
./deploy.sh 1.1.0 >/dev/null 2>&1 || note "deploying 1.1.0 failed"
[ "$(readlink current)" = "releases/1.1.0" ] || note "current did not move to 1.1.0"
./healthcheck.sh >/dev/null 2>&1 || note "1.1.0 is not healthy after deploy"

# --- Thursday: the bad release ---------------------------------------------
if ./deploy.sh 1.2.0 >/dev/null 2>&1; then
  note "deploying the broken 1.2.0 reported SUCCESS"
fi
cur=$(readlink current 2>/dev/null)
[ -n "$cur" ]            || note "current is missing entirely after the failed deploy"
[ -e current/app.sh ]    || note "current is dangling after the failed deploy"
[ "$cur" = "releases/1.1.0" ] || note "current is '$cur' after the failed deploy; 1.1.0 was the last healthy release"
./healthcheck.sh >/dev/null 2>&1 || note "the site is not healthy after the failed deploy -- this is the Thursday outage"

# --- and it must still be possible to move on ------------------------------
./deploy.sh 1.0.0 >/dev/null 2>&1 || note "could not deploy again after a failed deploy"
[ "$(readlink current)" = "releases/1.0.0" ] || note "could not get back to 1.0.0 after a failed deploy"

# --- the fixture must not have been doctored -------------------------------
# Checked by behaviour rather than by diffing the files: the broken release has
# to still be broken, and the health check has to still be able to tell.
./artifacts/1.2.0/app.sh >/dev/null 2>&1 \
  && note "artifacts/1.2.0 no longer fails; you fixed the release instead of the deploy"
./healthcheck.sh artifacts/1.2.0 >/dev/null 2>&1 \
  && note "healthcheck.sh now passes the broken release"
./healthcheck.sh artifacts/1.0.0 >/dev/null 2>&1 \
  || note "healthcheck.sh now fails a good release"

reset
[ "$fails" -eq 0 ] && { echo "PASS - idempotent, health-gated, rolls back, and current is always valid"; exit 0; }
echo "-- $fails problem(s) remaining"
exit 1
