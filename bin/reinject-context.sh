#!/bin/bash
# reinject-context — Restore PLANS.md and state into context for long-running tasks.
# CLUE-F4-002
# Usage: eval "$(bin/reinject-context.sh)"

set -euo pipefail

PLANS="PLANS.md"
EXIT_STATE=".harness/last-exit.json"

echo "# === REINJECT CONTEXT ==="

if [[ -f "$PLANS" ]]; then
  echo "# PLANS.md ($(wc -l < "$PLANS") lines):"
  echo "# $(head -5 "$PLANS" | tail -4 | tr '\n' ' ')"
  echo ""
fi

if [[ -f "$EXIT_STATE" ]]; then
  echo "# Last exit state:"
  python3 -c "
import json
with open('$EXIT_STATE') as f:
    d = json.load(f)
for k, v in d.items():
    print(f'#   {k}: {v}')
" 2>/dev/null || echo "#   (unreadable)"
  echo ""
fi

echo "# === END REINJECT ==="
