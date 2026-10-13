#!/usr/bin/env bash
cd "$(dirname "$0")"
command -v python3 >/dev/null || { echo "SKIP - python3 not installed"; exit 0; }
exec python3 -I check.py
