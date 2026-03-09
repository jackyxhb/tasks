# Flutter Project Structure

## Purpose

This document defines the first Flutter project structure for the personal field work agent app.

The goal is to start implementation with boundaries that match the design docs and the harness checks already present in this repo.

## Recommended Top-Level Repo Layout

Use a dedicated mobile app folder under the current planning repo.

```text
tasks/
├── docs/
├── schemas/
├── examples/
├── mobile/
│   └── field_work_agent/
│       ├── pubspec.yaml
│       ├── analysis_options.yaml
│       ├── lib/
│       ├── test/
│       ├── integration_test/
│       ├── assets/
│       ├── android/
│       ├── ios/
│       └── tool/
└── ...
```

Why `mobile/field_work_agent/`:

- keeps implementation code clearly separate from planning and harness docs
- fits the existing harness checks, which already watch `mobile/` as a future implementation root
- leaves room for future companion tools without polluting the repo root

## Environment Prerequisites

This structure assumes Flutter tooling is available when the task includes UI execution, platform-runner generation, or package resolution.

Required for normal Flutter app work:

- Flutter SDK installed and available on `PATH`
- Dart SDK available through the Flutter installation
- Xcode command-line tools available on macOS when iOS tooling is needed

Recommended preflight checks before starting mobile UI work:

```sh
./bin/check-mobile-toolchain
```

For deeper diagnosis after the repo-local preflight passes, use:

```sh
flutter --version
flutter doctor -v
dart --version
```

If these checks fail, the agent should treat that as an environment blocker or fall back to limited file-only scaffolding instead of assuming generated runners or runtime validation are possible.

## Flutter App Layout

Inside `mobile/field_work_agent/lib/`, use this structure:

```text
lib/
├── main.dart
├── bootstrap/
├── app/
├── core/
├── features/
│   ├── capture/
│   ├── inbox/
│   ├── projects/
│   ├── tasks/
│   ├── meetings/
│   ├── search/
│   ├── reports/
│   ├── exchange/
│   └── settings/
├── data/
├── domain/
└── shared/
```

This keeps two dimensions clear:

- product features
- technical layers

## Directory Responsibilities

### `main.dart`

Purpose:

- Flutter entry point
- minimal wiring only
- no business logic

### `bootstrap/`

Purpose:

- initialize SQLite
- initialize file storage paths
- initialize logging and trace IDs
- initialize AI provider configuration
- initialize dependency injection or service registry

Suggested files:

```text
bootstrap/
├── app_bootstrap.dart
├── app_environment.dart
└── dependency_container.dart
```

### `app/`

Purpose:

- application shell
- router
- theme
- navigation scaffolding

Suggested files:

```text
app/
├── app.dart
├── router.dart
├── theme/
└── navigation/
```

### `core/`

Purpose:

- cross-cutting primitives used by many features

Suggested contents:

- result and failure types
- date and time normalization
- phone normalization
- UUID generation
- app constants
- low-level validation helpers

Suggested structure:

```text
core/
├── constants/
├── errors/
├── logging/
├── types/
├── utils/
└── validation/
```

### `features/`

Purpose:

- feature-oriented implementation modules
- each feature owns its screens, controllers, state, and feature-local widgets

Each feature should follow a repeated internal structure where useful.

Suggested per-feature shape:

```text
features/<feature>/
├── application/
├── domain/
├── infrastructure/
├── presentation/
└── widgets/
```

Not every feature needs every folder on day one, but the ownership model should stay consistent.

## Feature Modules

### `features/capture/`

Purpose:

- paste text capture
- shared message intake
- manual form draft creation
- audio capture entry
- raw capture creation

Key responsibilities:

- create `raw_capture` first
- hand off to parser or meeting services later

### `features/inbox/`

Purpose:

- review unstructured captures
- show confidence, duplicates, and extracted candidates

Key responsibilities:

- review workflow
- provisional save
- finalize reviewed records

### `features/projects/`

Purpose:

- project list
- project detail
- create and edit project
- project contact linking

### `features/tasks/`

Purpose:

- task list
- task detail
- task create and edit
- provisional and final task handling

### `features/meetings/`

Purpose:

- meeting list
- meeting capture
- transcript review
- task candidate resolution

This feature is especially important because the harness already enforces meeting-to-task review separation.

### `features/search/`

Purpose:

- structured filters
- full-text search UI
- grouped result presentation

### `features/reports/`

Purpose:

- report selection
- filter editing
- summary rendering
- PDF and CSV export initiation

### `features/exchange/`

Purpose:

- import bundle preview
- duplicate resolution during import
- export scope selection
- bundle generation

### `features/settings/`

Purpose:

- agentee profile
- timezone and format preferences
- AI provider settings
- maintenance tools and diagnostics

## Layered Technical Modules

### `data/`

Purpose:

- implementation of storage and serialization details shared across features

Suggested contents:

```text
data/
├── database/
│   ├── app_database.dart
│   ├── migrations/
│   ├── tables/
│   └── daos/
├── files/
├── models/
├── repositories/
└── serializers/
```

Responsibilities:

- SQLite integration
- file metadata persistence
- import/export serialization
- repository implementations

### `domain/`

Purpose:

- stable business entities and use-case contracts shared across features

Suggested contents:

```text
domain/
├── entities/
├── enums/
├── repositories/
└── use_cases/
```

Responsibilities:

- define `Project`, `Task`, `Meeting`, `RawCapture`, `Person`, `Attachment`
- define lifecycle enums like meeting review states and task candidate states
- define repository interfaces, not storage details

### `shared/`

Purpose:

- reusable UI components and app-wide helpers that are not feature-owned

Suggested contents:

```text
shared/
├── widgets/
├── forms/
├── formatters/
└── extensions/
```

## Suggested Initial File Tree

For the first implementation slice, start with this minimal shape:

```text
mobile/field_work_agent/
├── pubspec.yaml
├── analysis_options.yaml
├── lib/
│   ├── main.dart
│   ├── bootstrap/
│   │   └── app_bootstrap.dart
│   ├── app/
│   │   ├── app.dart
│   │   └── router.dart
│   ├── core/
│   │   ├── logging/
│   │   ├── utils/
│   │   └── validation/
│   ├── data/
│   │   ├── database/
│   │   ├── files/
│   │   └── repositories/
│   ├── domain/
│   │   ├── entities/
│   │   ├── enums/
│   │   └── repositories/
│   ├── features/
│   │   ├── capture/
│   │   ├── inbox/
│   │   ├── projects/
│   │   ├── tasks/
│   │   ├── meetings/
│   │   ├── search/
│   │   ├── reports/
│   │   ├── exchange/
│   │   └── settings/
│   └── shared/
│       └── widgets/
├── test/
└── integration_test/
```

## First Vertical Slice Recommendation

The first coded slice should be text capture, not meeting audio.

Recommended first implementation path:

1. `features/capture` creates a `raw_capture` from pasted text.
2. parser logic creates candidate task and project data.
3. `features/inbox` renders review UI.
4. reviewed results are saved through repository interfaces into SQLite.
5. `features/tasks` and `features/projects` display saved results.

This validates the architecture before taking on audio complexity.

## Second Vertical Slice Recommendation

The second slice should be meeting audio flow.

Recommended second implementation path:

1. local meeting draft creation
2. local audio recording
3. transcript persistence
4. extraction to task candidates
5. meeting review state transitions
6. candidate promotion into provisional or final tasks

## Naming and Boundary Rules

- keep raw capture logic out of project and task screens
- keep meeting extraction inside the meetings feature boundary
- do not let storage code leak directly into presentation widgets
- keep import/export code inside `features/exchange` and `data/serializers`
- keep lifecycle enums in `domain/enums`

## Dependency Direction

Preferred direction:

```text
presentation -> application -> domain -> data
```

More specifically:

- `features/*/presentation` can depend on feature application logic and shared widgets
- application code can depend on domain contracts
- data implementations can depend on domain contracts
- domain must not depend on Flutter UI or SQLite details

## Harness Compatibility Notes

This structure is chosen to work with the repo harness already present.

- implementation under `mobile/` will be visible to the future code-facing checks
- meeting review-gate enforcement maps naturally to `features/meetings`
- local-only storage enforcement maps naturally to `data/database` and `data/files`
- bundle schema validation maps naturally to `features/exchange` and `data/serializers`

## Recommended Next Step After Structure

Once this structure is accepted, the next concrete artifact should be one of:

1. SQLite table and migration files for the initial entities
2. Dart domain entities and enums
3. the first text-capture vertical slice scaffold