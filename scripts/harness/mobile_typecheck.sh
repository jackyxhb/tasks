#!/usr/bin/env bash
set -euo pipefail

root_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
package_dir="$root_dir/mobile/field_work_agent"

cd "$root_dir"
./bin/check-mobile-toolchain

cd "$package_dir"
flutter analyze --no-fatal-warnings --no-fatal-infos