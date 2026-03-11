#!/usr/bin/env bash
set -euo pipefail

root_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
package_dir="$root_dir/mobile/field_work_agent"
device_id="${DEVICE:-}"

cd "$root_dir"
./bin/check-mobile-toolchain

if [[ -z "$device_id" ]]; then
  echo "ERROR: DEVICE is required for iOS smoke validation"
  echo "  -> example: DEVICE=00008140-000654E61107001C make mobile-ios-smoke"
  exit 1
fi

cd "$package_dir"
flutter test -d "$device_id" integration_test/app_launch_flow_test.dart
