#!/usr/bin/env bash
cd "$(dirname "$0")"
kubectl apply -f manifest.yaml >/dev/null 2>&1
for i in $(seq 1 20); do
  phase=$(kubectl -n practice get pod -l app=hungry -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
  [ "$phase" = "Running" ] && { echo "PASS - pod Running"; exit 0; }
  sleep 3
done
echo "FAIL - still $phase"
kubectl -n practice describe pod -l app=hungry 2>&1 | grep -iA2 "events\|insufficient" | tail -6 | sed 's/^/  /'
exit 1
