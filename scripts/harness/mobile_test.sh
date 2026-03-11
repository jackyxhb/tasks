#!/usr/bin/env bash
set -euo pipefail

root_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
package_dir="$root_dir/mobile/field_work_agent"

cd "$root_dir"
./bin/check-mobile-toolchain

cd "$package_dir"
flutter test -d macos integration_test/app_launch_flow_test.dart
flutter test -d macos integration_test/export_bundle_flow_test.dart
flutter test -d macos integration_test/task_creation_flow_test.dart
flutter test -d macos integration_test/text_capture_flow_test.dart

flutter test \
	test/acceptance_workflows_test.dart \
	test/meeting_fallback_shell_test.dart \
	test/review_workflow_shell_test.dart \
	test/database_migrator_test.dart \
	test/smoke_test.dart