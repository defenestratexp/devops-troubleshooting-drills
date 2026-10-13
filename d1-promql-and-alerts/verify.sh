#!/usr/bin/env bash
cd "$(dirname "$0")"
[ -f ANSWERS.md ] || { echo "FAIL - write ANSWERS.md first"; exit 1; }
score=0
grep -qiE 'status=~|5\.\.|5xx|=~"5' ANSWERS.md && score=$((score+1))
grep -qiE 'histogram_quantile' ANSWERS.md && score=$((score+1))
grep -qiE '\bfor\b.*(5m|10m|2m)|for: *[0-9]+m' ANSWERS.md && score=$((score+1))
grep -qiE '43\.2|43 ?min' ANSWERS.md && score=$((score+1))
grep -qiE '14\.4' ANSWERS.md && score=$((score+1))
grep -qiE 'predict_linear' ANSWERS.md && score=$((score+1))
echo "self-check score: $score/6 keyword markers found in ANSWERS.md"
[ "$score" -ge 5 ] && { echo "PASS"; exit 0; }
echo "Below 5 - re-read your answers against SOLUTION.md"; exit 1
