#!/usr/bin/env bash
set -euo pipefail

target_path="${1:-.}"
if [ ! -d "$target_path" ]; then
  echo "error: target path does not exist: $target_path" >&2
  exit 1
fi

target_path=$(cd "$target_path" && pwd)
echo "Harness artifacts are already managed directly in: $target_path"
echo "Use 'python3 scripts/harness_wizard.py audit $target_path' to validate current coverage."