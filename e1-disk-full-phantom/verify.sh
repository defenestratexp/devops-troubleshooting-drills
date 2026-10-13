#!/usr/bin/env bash
MNT=/tmp/practice-disk
mountpoint -q "$MNT" 2>/dev/null || { echo "SKIP - run ./setup.sh first"; exit 0; }
used=$(df --output=pcent "$MNT" | tail -1 | tr -dc '0-9')
if [ "${used:-100}" -lt 30 ]; then echo "PASS - filesystem now ${used}% used"; exit 0; fi
echo "FAIL - still ${used}% used; the space has not been reclaimed"; exit 1
