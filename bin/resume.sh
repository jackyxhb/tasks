#!/bin/sh
set -eu

state_file="${HARNESS_STATE_FILE:-/tmp/harness-state.json}"

if [ ! -f "$state_file" ]; then
  echo "No checkpoint found. Start a fresh session."
  exit 1
fi

echo "=== Last Session Checkpoint ==="
cat "$state_file"
echo ""
echo "=== Resume Instructions ==="
echo "Last working directory: $(cat "$state_file" | sed -n 's/.*"working_directory": "\([^"]*\)".*/\1/p')"
echo "Last command: $(cat "$state_file" | sed -n 's/.*"last_command": "\([^"]*\)".*/\1/p')"
echo "Git branch: $(cat "$state_file" | sed -n 's/.*"git_branch": "\([^"]*\)".*/\1/p')"
echo ""
echo "Copy the checkpoint info above and resume your task from the last working directory."
