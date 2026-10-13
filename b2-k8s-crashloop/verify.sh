#!/usr/bin/env bash
cd "$(dirname "$0")"
kubectl apply -f manifest.yaml >/dev/null 2>&1
for i in $(seq 1 20); do
  phase=$(kubectl -n practice get pods -l app=cfgapp -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
  ready=$(kubectl -n practice get pods -l app=cfgapp -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
  [ "$phase" = "Running" ] && [ "$ready" = "true" ] && { echo "PASS - pod Running and Ready"; exit 0; }
  sleep 3
done
echo "FAIL - pod never became Running+Ready"
kubectl -n practice get pods -l app=cfgapp 2>&1 | sed 's/^/  /'
kubectl -n practice describe pod -l app=cfgapp 2>&1 | grep -A3 -iE "events|warning" | tail -8 | sed 's/^/  /'
exit 1
