#!/usr/bin/env bash
cd "$(dirname "$0")"
kubectl apply -f manifest.yaml >/dev/null 2>&1
sleep 50
ready=$(kubectl -n practice get pods -l app=slowstart -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
restarts=$(kubectl -n practice get pods -l app=slowstart -o jsonpath='{.items[0].status.containerStatuses[0].restartCount}' 2>/dev/null)
if [ "$ready" = "true" ] && [ "${restarts:-9}" -le 1 ]; then echo "PASS - Ready, $restarts restart(s)"; exit 0; fi
echo "FAIL - ready=$ready restarts=$restarts"; exit 1
