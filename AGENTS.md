# AGENTS.md

This repo is the harness for the personal field work agent app. If an agent produces the wrong plan, the harness must be tightened so the same failure becomes harder or impossible to repeat.

## Failure Ledger

```yaml
- rule: docs/ is the canonical source of truth for the app design; legacy root notes must not be treated as requirements.
  fix: Use docs/app-design-spec.md and linked docs/* plans as the design source.

- rule: Worker, coordinator, and project manager are record fields, not application permission roles.
  fix: The only operator in v1 is the agentee. Store roles only as data fields.

- rule: Version 1 is local-only; do not introduce sync, shared backend, or cross-device collaboration.
  fix: Use SQLite plus local file storage. Sharing happens through import/export bundles only.

- rule: Meeting records must remain separate from task records.
  fix: Model Meeting as a separate entity that can emit task candidates, subject to review.

- rule: AI extraction output must create reviewable candidates, not auto-final records.
  fix: Preserve raw source, require structured JSON output, validate locally, force review on low confidence.

- rule: Non-trivial autonomous runs must start from a machine-readable task contract.
  fix: Validate with bin/check-task-contract before major autonomous work.

- rule: Mobile app-shell boundaries must stay explicit and enforceable.
  fix: Shell code in lib/app/, feature code in feature folders, tests in integration_test/.

- rule: macOS integration tests must run one file at a time.
  fix: Use scripts/harness/mobile_test.sh, never flutter test -d macos integration_test/*.
```

## Build / Lint / Test Commands

### Repo-level (run from root)
- `make ci` — Full validation pipeline (smoke + check + test)
- `make check` — Lint + typecheck (fast)
- `make smoke` — Fastest repo smoke checks
- `make mobile-preflight` — Flutter toolchain check
- `make mobile-typecheck` — Flutter analyze for mobile package
- `make mobile-test` — Run mobile tests via wrapper
- `make mobile-run` — Launch app locally (DEVICE=macos default)
- `make mobile-ios-smoke` — iOS launch smoke (DEVICE=<id> required)
- `make audit` — Harness audit via `python3 scripts/harness_wizard.py audit .`

### Mobile package (run from mobile/field_work_agent/)
- `flutter analyze` — Static analysis (lints + type check)
- `flutter test` — Run all unit tests
- `flutter test test/smoke_test.dart` — Run a single unit test
- `flutter test integration_test/app_launch_flow_test.dart -d macos` — Run a single integration test
- `flutter test integration_test/ -d macos` — Run all integration tests (may fail; use wrapper instead)
- `flutter build web` — Build for web platform

### Harness extensions
- `make harness-extensions` — Stale contracts, import graph, Python lint, changelog, pub outdated
- `make perf` — Performance tracking across harness checks
- `make metrics` — Auto-collect control-loop metrics

### Pre-commit hooks
- Installed via `git config core.hooksPath .git-hooks`
- Runs: make check, check-gc, check-stale-contracts, check-dart-imports, check-python-lint, check-changelog
- Bypass with `GIT_HOOKS_ENABLED=0` or `git config core.hooksPath /dev/null`

## Code Style Guidelines

### Imports
- Sort: dart: → package: → relative imports
- Use `package:field_work_agent/` for internal cross-package imports
- Feature folders may import core/data/domain/models but NOT app/
- Remove unused imports (flutter analyze will flag them)

### Formatting
- Line length: 80 chars (default Dart)
- Single quotes preferred (`prefer_single_quotes` in analysis_options.yaml)
- Trailing commas on multi-line collections and widget constructors
- Use `const` constructors wherever possible
- Explicit type annotations on public APIs and top-level declarations

### Naming
- Files: snake_case (`app_shell.dart`, `project_crud_service.dart`)
- Classes: PascalCase (`FieldWorkAgentApp`, `ProjectCrudService`)
- Methods/variables: camelCase (`loadData`, `projectById`)
- Constants: camelCase with `static const` or `kPascalCase` for global constants
- Private members: leading underscore (`_LocalAppRuntime`, `_dataFuture`)
- Test files: `<feature>_test.dart` or `<feature>_flow_test.dart`

### Types
- Use explicit nullable types (`String?`) over `dynamic`
- Prefer `Future<T>` over `Future` for async returns
- Use sealed classes or enums for state machines (e.g., `TaskStatus`, `TaskPriority`)
- Entity classes are immutable with `const` constructors where possible

### Error Handling
- Throw `StateError` for invalid application state
- Use `try/catch` with specific exception types at boundaries
- Never swallow exceptions — log or rethrow
- UI errors display via `_ErrorBody` widget with retry callback
- Database errors propagate; do not catch and ignore at repository level

### Architecture
- `lib/app/` — App shell, runtime, UI components, section wiring
- `lib/core/` — Cross-cutting concerns (storage, audit, utils)
- `lib/data/` — Data access layer (database, repositories)
- `lib/domain/` — Business entities and enums
- `lib/features/` — Feature-specific application logic (capture, exchange, meetings, projects, reports, search, tasks)
- `lib/bootstrap/` — Platform initialization (database, storage)

### Testing
- Unit tests in `test/`, integration tests in `integration_test/`
- Use `flutter_test` for widget tests, `integration_test` package for E2E
- Integration tests run per-file on macOS: `flutter test <file> -d macos`
- Test names describe behavior: `'creates a task from capture input'`

## Context Management
- **Token budget:** Below ~30%, compact into PLANS.md. Offload large outputs to temp files.
- **Stuck detection:** Same check fails 3x → `bin/notify.sh escalate "stuck on repeated failure"`.
- **Exit hooks:** After each significant step, call `bin/on-exit-hook.sh`.
- **Session startup:** Run `bin/session-startup.sh` to inject PLANS.md context.

## Do Not Use
- Do not treat ARCHIVE_FORMAT.md or WORK_HOURS_RECORD_FORMAT.md as app schema sources.
- Do not add backend, sync, or multi-user auth to v1.
- Do not auto-create final tasks from meeting extraction.
- Do not use `rm -rf` in this repo.
- Do not run `flutter test -d macos integration_test/` (directory-wide); run per-file.

## Repo Rules
- `docs/` is the canonical source of truth for app design.
- `docs/app-design-spec.md` must link to every focused planning document.
- Non-trivial autonomous runs start from a validated task contract.
- New failure patterns → add to Failure Ledger here, not as generic advice.

## Enforcement
- Run `bin/check-docs` after changing design docs.
- Run `bin/check-constraints` after changing design assumptions.
- Run `bin/check-gc` when cleaning planning artifacts.
- Run `bin/check-mobile-project-structure` after changing Flutter layout.
- Run `bin/check-task-contract <path>` before autonomous work.
- If a rule matters and is not checkable, document the gap in docs/harness-assessment.md.
