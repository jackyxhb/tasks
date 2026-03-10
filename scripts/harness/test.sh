#!/usr/bin/env bash
set -euo pipefail

root_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

cd "$root_dir"
./bin/check-harness
./scripts/harness/mobile_test.sh