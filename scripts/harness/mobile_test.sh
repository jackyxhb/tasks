#!/usr/bin/env bash
set -euo pipefail

root_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
package_dir="$root_dir/mobile/field_work_agent"

cd "$root_dir"
./bin/check-mobile-toolchain

cd "$package_dir"
flutter test \
	test/acceptance_workflows_test.dart \
	test/meeting_fallback_shell_test.dart \
	test/review_workflow_shell_test.dart \
	test/database_migrator_test.dart \
	test/smoke_test.dart