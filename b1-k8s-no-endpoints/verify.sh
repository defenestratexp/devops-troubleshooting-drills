#!/usr/bin/env bash
cd "$(dirname "$0")"
kubectl apply -f manifest.yaml >/dev/null 2>&1
kubectl -n practice rollout status deploy/web --timeout=60s >/dev/null 2>&1
n=$(kubectl -n practice get endpoints web -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null | wc -w)
if [ "$n" -ge 1 ]; then echo "PASS - Service has $n endpoint(s)"; exit 0; fi
echo "FAIL - Service web has no endpoints"
kubectl -n practice get svc web -o jsonpath='{.spec.selector}'; echo
exit 1
