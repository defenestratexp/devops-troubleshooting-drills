#!/usr/bin/env bash
# Reasoning drill: scored on whether your answers name the specific mechanisms,
# not on prose. Read SOLUTION.md afterwards either way -- a high score with a
# wrong story is worth less than a low score with the right one.
cd "$(dirname "$0")"
[ -f ANSWERS.md ] || { echo "FAIL - write ANSWERS.md first (see TASK.md)"; exit 1; }

score=0
hit() { printf '  %-4s %s\n' "$1" "$2"; }

check() { # marker-description regex
  if grep -qiE "$2" ANSWERS.md; then score=$((score+1)); hit "ok" "$1"; else hit "--" "$1"; fi
}

check "kms:Decrypt named as the missing action"        'kms:decrypt'
check "the key policy identified as the place to fix"  'key polic|kms (key )?polic'
check "object ownership / the uploader owns the object" 'object ?owner|bucket-owner|objectwriter|owned by the (vendor|uploader|writer)|acl'
check "bucket-owner-enforced as the permanent fix"     'bucket.owner.enforced|disable (object )?acl|acls? disabled'
check "both identity and resource policy must allow"   'both|identity (policy )?and (the )?(bucket|resource)|two polic'
check "ListBucket is on the bucket ARN, GetObject on the object ARN" \
      'listbucket.*bucket arn|bucket arn.*listbucket|/\*|object arn'
check "CloudTrail named as the diagnostic"             'cloudtrail'

echo
echo "self-check score: $score/7"
[ "$score" -ge 6 ] && { echo "PASS"; exit 0; }
echo "Below 6 - re-read your answers against SOLUTION.md"
exit 1
