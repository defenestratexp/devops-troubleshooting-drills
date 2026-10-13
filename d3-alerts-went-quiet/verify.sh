#!/usr/bin/env bash
# Reasoning drill: scored on whether your answers name the specific mechanisms.
# Read SOLUTION.md afterwards either way.
cd "$(dirname "$0")"
[ -f ANSWERS.md ] || { echo "FAIL - write ANSWERS.md first (see TASK.md)"; exit 1; }

score=0
check() {
  if grep -qiE "$2" ANSWERS.md; then score=$((score+1)); printf '  ok   %s\n' "$1"
  else printf '  --   %s\n' "$1"; fi
}

check "no data / empty result, not a false comparison"  'no data|empty (result|vector)|returns nothing|not exist|absent'
check "absent() or absent_over_time() named"            'absent(_over_time)?\('
check "the job label mismatch (api vs api-service)"     'api-service|job (name|label) (was )?(changed|renamed|mismatch)|wrong job'
check "up{} with a nonexistent job matches no series"   'matches no series|no series|never (returns|produces)|vector selector matches nothing|cannot be 0|no time series'
check "the 5m lookback / staleness window"              '5 ?m(in)?|lookback|stale'
check "a dead man s switch / watchdog"                  'dead ?man|watchdog|heartbeat'
check "the watchdog must be evaluated outside Prometheus" \
      'outside|external|alertmanager|dead ?man ?snitch|cronitor|healthchecks\.io|third.?party|another system'
check "a pending alert is discarded when its series goes away" \
      'pending|resolve|discard|resets|disappears'
check "the flat-line / no-data ambiguity on the dashboard" \
      'flat|gap|null|connect|no.?data'

echo
echo "self-check score: $score/9"
[ "$score" -ge 7 ] && { echo "PASS"; exit 0; }
echo "Below 7 - re-read your answers against SOLUTION.md"
exit 1
