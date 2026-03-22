#!/bin/sh
set -eu

root_dir=$(cd "$(dirname "$0")/.." && pwd)
state_file="${HARNESS_STATE_FILE:-/tmp/harness-state.json}"

last_cmd="${LAST_CMD:-$(fc -ln -1 2>/dev/null | xargs || echo 'unknown')}"
pwd_info="${PWD:-unknown}"
timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

mkdir -p "$(dirname "$state_file")"

cat > "$state_file" <<EOF
{
  "timestamp": "$timestamp",
  "last_command": "$(printf '%s' "$last_cmd" | tr '"' "'")",
  "working_directory": "$pwd_info",
  "git_branch": "$(git branch --show-current 2>/dev/null || echo 'unknown')",
  "git_status": "$(git status --porcelain 2>/dev/null | head -3 | tr '\n' ';' || echo 'unknown')"
}
EOF
