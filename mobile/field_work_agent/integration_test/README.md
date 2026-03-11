# Integration Test Surface

This directory is the reserved runtime-validation surface for launch and interaction checks that cannot be trusted to widget tests alone.

Keep this surface executable.

Current runtime-validation entrypoints:
- `integration_test/app_launch_flow_test.dart` boots the full shell and verifies cross-section navigation still works after refactors.
- `integration_test/export_bundle_flow_test.dart` generates a bundle through the live export screen and verifies export history reflects the mutation.
- `integration_test/task_creation_flow_test.dart` creates a task through the live shell flow and verifies the UI reflects the mutation.

macOS note:
- Keep harness execution on explicit per-file `flutter test -d macos integration_test/<file>.dart` invocations. Directory-wide integration runs were unstable in this repo even when individual tests were healthy.
