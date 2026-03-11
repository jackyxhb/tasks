# AGENTS.md

This repo is the harness for the personal field work agent app. If an agent produces the wrong plan, the harness must be tightened so the same failure becomes harder or impossible to repeat.

## Failure Ledger

```yaml
- rule: docs/ is the canonical source of truth for the app design; legacy root notes must not be treated as requirements.
  context: Planning drift happened on 2026-03-09 when ARCHIVE_FORMAT.md and WORK_HOURS_RECORD_FORMAT.md were initially treated as app constraints even after the user said they were unrelated.
  consequence: The app model was pulled toward the wrong archive format.
  fix: Use docs/app-design-spec.md and linked docs/* plans as the design source. Treat ARCHIVE_FORMAT.md and WORK_HOURS_RECORD_FORMAT.md as legacy-only unless explicitly replaced.

- rule: Worker, coordinator, and project manager are record fields, not application permission roles.
  context: Role-model confusion happened on 2026-03-09 when the plan initially described multi-user role workflows for the app.
  consequence: The architecture drifted toward a shared system instead of a personal local agent.
  fix: The only operator in v1 is the agentee. Store worker/coordinator/project_manager only as data fields on project, task, and meeting records.

- rule: Version 1 is local-only; do not introduce sync, shared backend, or cross-device collaboration unless the user explicitly changes scope.
  context: Sync assumptions appeared on 2026-03-09 before the user clarified that all data must remain local and only LLM access may use the internet.
  consequence: Unnecessary backend and conflict-resolution complexity entered the design.
  fix: Use SQLite plus local file storage as the only source of truth. Sharing happens through import/export bundles only.

- rule: Meeting records must remain separate from task records.
  context: Planning pressure on 2026-03-09 exposed the risk that meetings could be flattened directly into tasks.
  consequence: Multi-project discussions, decisions, and unresolved questions would be lost or duplicated as noisy tasks.
  fix: Model Meeting as a separate entity that can emit task candidates, project links, and decisions, all subject to review.

- rule: AI extraction output must create reviewable candidates, not auto-final records.
  context: Meeting transcription design on 2026-03-09 showed that mixed-language audio and repeated action items make silent automation unsafe.
  consequence: Wrong project links, wrong assignees, and duplicate tasks become likely.
  fix: Preserve raw source, require structured JSON output, validate locally, and force review when confidence is low or ambiguity exists.

- rule: Import/export is the exchange mechanism in v1; CSV and PDF are secondary outputs, not canonical re-import formats.
  context: The user clarified on 2026-03-09 that people exchange information between separate local installs rather than syncing live state.
  consequence: Without a canonical bundle format, exchange becomes lossy and hard to merge.
  fix: Use versioned JSON bundles plus attachment manifests and checksums for portable exchange.

- rule: Non-trivial autonomous runs must start from a machine-readable task contract.
  context: On 2026-03-09 the repo could validate global design constraints, but an agent still needed the user to restate task scope, success checks, and approval edges for each substantial run.
  consequence: Autonomous runs can overshoot scope, stop for avoidable clarification, or miss required verification.
  fix: Define a JSON task contract and validate it with bin/check-task-contract before major autonomous work.

- rule: Canonical repo validation must compile and test the mobile package once implementation exists.
  context: On 2026-03-09 the repo-level harness passed while the Flutter package still contained compile-time and integration regressions that only surfaced when the new acceptance suite ran.
  consequence: make ci could report green even when the shipped mobile app was broken.
  fix: Keep repo-local mobile analyze and focused mobile test wrappers under scripts/harness/ and run them from the canonical validation path.

- rule: Mobile app-shell boundaries must stay explicit and enforceable.
  context: On 2026-03-10 the Flutter package accumulated shell and section code under a generic lib/src/ bucket, while launch-surface usability failures still passed the harness.
  consequence: Structural ownership became ambiguous, runtime-validation expansion had no clear home, and agents could keep adding UI into a catch-all shell file without tripping a guard.
  fix: Keep shell and top-level composition under mobile/field_work_agent/lib/app/, reserve feature code for feature folders, and maintain mobile/field_work_agent/integration_test/ as the runtime-validation surface.

- rule: macOS runtime-validation must run integration tests as explicit per-file invocations.
  context: On 2026-03-11 a directory-wide `flutter test -d macos integration_test` run produced app startup and debug-connection failures even though the individual integration tests passed in isolation.
  consequence: The harness can report false negatives and destabilize the canonical mobile validation path.
  fix: Keep macOS integration coverage executable through `mobile/field_work_agent/integration_test/`, but run those tests one file at a time from `scripts/harness/mobile_test.sh`.

- rule: Home quick actions declared in docs must map to real user-completable flows, not navigation stubs.
  context: On 2026-03-11 the UX listed `Paste Text` as a capture action, but the app only navigated to Inbox and exposed no text-entry capture flow.
  consequence: The harness can report green while a documented core workflow is unavailable to users.
  fix: Keep a runtime-validation test for each documented Home quick action that mutates state, and fail planning/harness reviews when an action is only a section redirect.

- rule: Mobile runtime-validation must include iOS launch-surface checks, not macOS-only coverage.
  context: On 2026-03-11 the app launched under macOS validation but showed a blank white screen on iPhone.
  consequence: Platform-specific startup failures can ship while canonical validation still passes.
  fix: Keep macOS as the default stable suite, and add an explicit iOS smoke validation path (manual gate or device-targeted automation) in the harness contract.
```

## Available Tools

- `bin/check-docs` - Validate required app design docs exist and are linked from docs/app-design-spec.md.
- `bin/check-constraints` - Validate design invariants for local-only v1, meeting/task separation, AI review gating, and canonical import/export format.
- `bin/check-gc` - Detect stale planning docs, unlinked focused docs, and legacy root docs that lost their tombstone markers.
- `bin/check-local-only-code` - Detect code patterns that would introduce non-local storage or sync assumptions in v1.
- `bin/check-meeting-review-gate` - Detect missing meeting review-gate signals or suspicious direct final-task promotion patterns.
- `bin/check-bundle-schema` - Validate the canonical import/export schema and sample bundle.
- `bin/check-mobile-project-structure` - Validate explicit Flutter app-shell boundaries and the runtime-validation surface.
- `bin/check-home-quick-actions` - Detect documented Home quick actions that are implemented as navigation stubs instead of user-completable flows.
- `bin/check-implementation-constraints` - Run all implementation-aware constraint checks together.
- `bin/check-mobile-toolchain` - Fail fast when Flutter-dependent work is requested but the Flutter/Dart toolchain is not available.
- `bin/check-task-contract [path]` - Validate a machine-readable task contract for autonomous runs.
- `bin/check-harness` - Run the lightweight harness checks for this repo.
- `make smoke` - Run the fastest repo smoke checks.
- `make check` - Run lint-like and type-like harness verification commands.
- `make task-contract CONTRACT=<path>` - Validate the current task contract before an autonomous run.
- `make mobile-preflight` - Run the stable mobile toolchain preflight for Flutter-dependent work.
- `make mobile-run` - Launch the Flutter app locally from the repo root. Override the target with `DEVICE=<flutter-device-id>` when needed.
- `make mobile-ios-smoke` - Run the iOS app-launch smoke validation test using a connected iOS device or simulator (`DEVICE=<flutter-device-id>` required).
- `make mobile-typecheck` - Run the repo-local Flutter analyze wrapper for the mobile package.
- `make mobile-test` - Run the focused repo-local Flutter test batch for the mobile package.
- `make audit` - Run the harness audit entrypoint.
- `make ci` - Run the full local harness pipeline.
- `python3 scripts/harness_wizard.py status .` - Show harness artifact coverage.
- `python3 scripts/harness_wizard.py audit .` - Audit harness readiness and fail on missing artifacts.
- `python3 scripts/validate_task_contract.py <contract.json>` - Validate task-contract structure directly.
- `find`, `grep`, `sed`, `awk` - Preferred built-in shell tools for this repo because ripgrep is not available in the current environment.

## Do Not Use

- Do not treat ARCHIVE_FORMAT.md as the app schema source.
- Do not treat WORK_HOURS_RECORD_FORMAT.md as the app schema source.
- Do not add backend, sync, or multi-user auth plans to v1 unless the user explicitly asks.
- Do not auto-create final tasks directly from meeting extraction.
- Do not use destructive cleanup commands such as `rm -rf` in this repo.

## Repo Rules

- `docs/` is the canonical source of truth for the app design.
- `docs/app-design-spec.md` must link to every focused planning document under `docs/`.
- If a new planning document changes the source of truth, update `docs/app-design-spec.md` in the same change.
- Non-trivial autonomous runs should start from a validated task contract that defines scope, verification commands, and stop conditions.
- If a new failure pattern is discovered, add it here as a failure-ledger entry, not as generic advice.

## Harness Commands

- `make smoke` must stay cheap and deterministic.
- `make check` must run fast-fail harness verification before any longer workflow exists.
- `make mobile-preflight` should remain the stable explicit preflight for Flutter-dependent work and repo-local mobile wrappers should call it before Flutter commands.
- `make mobile-run` should remain the canonical local app-launch entrypoint from the repo root and default to `DEVICE=macos` unless explicitly overridden.
- iOS runtime smoke validation should be runnable as an explicit harness step when a device is available, and platform gaps should be recorded when iOS validation is skipped.
- `make ci` must remain the canonical single-command validation entrypoint.
- Repo-local wrapper scripts under `scripts/harness/` are preferred over ad-hoc manual command sequences.

## Execution Plans

- Use [PLANS.md](/Users/macbook1/work/Asoon/tasks/PLANS.md) for multi-step work where durable context matters.
- Record objective, constraints, current command surface, and checkpoints before major implementation starts.
- Keep plans aligned with the canonical docs under `docs/`.

## Enforcement

- Run `bin/check-docs` after changing design docs.
- Run `bin/check-constraints` after changing design assumptions or planning docs.
- Run `bin/check-gc` when cleaning planning artifacts or after adding new focused docs.
- Run `bin/check-implementation-constraints` after changing future implementation code or import/export contracts.
- Run `bin/check-mobile-project-structure` after changing Flutter app layout, top-level shell wiring, or runtime-validation folders.
- Run `bin/check-home-quick-actions` after changing Home quick actions or capture/create entrypoints.
- Run `bin/check-mobile-toolchain` before Flutter UI work, platform-runner generation, or mobile contracts that require runtime validation.
- Run `bin/check-task-contract <path>` before substantial autonomous work when a task-specific contract exists.
- Run `bin/check-harness` after changing harness files.
- Run `make mobile-typecheck` and `make mobile-test` when changing the repo harness or mobile validation path.
- Run `make mobile-ios-smoke` when launch-surface behavior changes and an iOS device/simulator is available.
- Run `python3 scripts/harness_wizard.py audit .` after changing core harness artifacts.
- If a rule here matters and is not checkable yet, add a follow-up check or document the gap in docs/harness-assessment.md.