#!/usr/bin/env bash
cd "$(dirname "$0")"
docker compose up -d >/dev/null 2>&1
sleep 11
running=$(docker compose ps --status running --services 2>/dev/null | grep -c worker)
beats=$(docker compose logs worker 2>&1 | grep -c heartbeat)
docker compose down -v >/dev/null 2>&1
if [ "$running" -ge 1 ] && [ "$beats" -ge 3 ]; then echo "PASS ($beats heartbeats)"; exit 0; fi
echo "FAIL - running=$running heartbeats=$beats"; exit 1
