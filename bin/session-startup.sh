#!/bin/bash
# session-startup — Print PLANS.md summary for session context.
# CLUE-P1-004
# Usage: source bin/session-startup.sh  (or: bash bin/session-startup.sh)

set -euo pipefail

PLANS="PLANS.md"
STATE=""

if [[ -f "$PLANS" ]]; then
  ts=$(date -r "$PLANS" +%Y-%m-%d)
  headline=$(sed -n '/^## /{s/^## //;p;q}' "$PLANS" 2>/dev/null || echo "")
  echo "[HARNESS] $PLANS last modified: $ts"
  if [[ -n "$headline" ]]; then
    echo "[HARNESS] Current session focus: $headline"
  fi
  lines=$(wc -l < "$PLANS")
  echo "[HARNESS] PLANS.md is $lines lines — review before starting new work"
else
  echo "[HARNESS] No PLANS.md found — this is a fresh session"
fi

if [[ -f ".harness/last-exit.json" ]]; then
  state=$(cat .harness/last-exit.json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('exit_reason','unknown')+' | last='+d.get('timestamp','?')[:19])" 2>/dev/null || echo "unreadable")
  echo "[HARNESS] Last exit: $state"
fi
