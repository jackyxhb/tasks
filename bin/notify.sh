#!/bin/sh
set -eu

METHOD="${1:-stdout}"
MESSAGE="${2:-}"

case "$METHOD" in
  stdout)
    echo "NOTIFY: $MESSAGE"
    ;;
  file)
    log="${3:-/tmp/harness-notify.log}"
    echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] $MESSAGE" >> "$log"
    ;;
  webhook)
    url="${3:-}"
    if [ -n "$url" ]; then
      curl -s -X POST "$url" -H "Content-Type: text/plain" -d "$MESSAGE" 2>/dev/null || echo "webhook_post_failed"
    fi
    ;;
  escalate)
    echo ""
    echo "=========================================="
    echo "ESCALATION: $MESSAGE"
    echo "=========================================="
    echo "The agent is blocked. Please review and respond."
    echo ""
    ;;
esac
