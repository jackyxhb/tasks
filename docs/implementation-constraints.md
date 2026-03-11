# Implementation Constraints

## Purpose

This document defines implementation-aware constraints that future app code must satisfy.

These constraints exist so the repo can enforce the agreed version 1 product shape once implementation files appear.

## Constraint 1: Local-Only Storage

Version 1 must remain local-only.

Implementation consequences:

- do not add sync engines
- do not add shared backend persistence
- do not add websocket-based collaboration
- do not add remote database clients as the primary data path

Allowed network behavior in version 1:

- optional LLM or STT requests for transcription, extraction, and summarization

Forbidden implementation directions in version 1:

- Firebase as app state backend
- Supabase sync or hosted database as source of truth
- AppSync or GraphQL live sync
- Pusher or websocket collaboration layers
- CloudKit sync assumptions
- any background replication or shared-state transport

## Constraint 2: Meeting Review Before Task Promotion

Meeting extraction must not directly create final tasks.

Implementation consequences:

- extraction creates task candidates
- candidates remain reviewable
- a review state must exist before promotion to final tasks
- low-confidence outputs must remain provisional or unresolved

Required implementation concepts:

- `review_required` or equivalent review-gate state
- explicit task candidate lifecycle
- explicit user-confirmed promotion from candidate to task

Forbidden implementation directions:

- direct finalize-on-extract task creation from meeting modules
- silent automatic project linking for ambiguous meeting outputs

## Constraint 3: Canonical Import/Export Contract

Import/export must use a versioned JSON bundle plus attachment manifest and checksums.

Implementation consequences:

- JSON bundle is the canonical machine-readable format
- CSV and PDF are secondary outputs only
- imports must validate bundle structure before write
- bundle schema version must be explicit

Canonical schema artifact:

- [schemas/import-export-bundle.schema.json](../schemas/import-export-bundle.schema.json)

Validation helper:

- `python3 scripts/validate_bundle.py <bundle.json>`

## Constraint 4: Explicit Mobile App Boundaries

The Flutter package structure must preserve explicit app-shell boundaries that the harness can check directly.

Implementation consequences:

- app-shell, navigation, and top-level runtime wiring live under `mobile/field_work_agent/lib/app/`
- `mobile/field_work_agent/lib/src/` must not be used as a generic dumping ground
- feature-specific UI should trend toward feature-owned folders rather than central growth in one catch-all shell file
- `mobile/field_work_agent/integration_test/` must exist as the stable home for executable launch and interaction validation

Required implementation concepts:

- `lib/app/` directory for shell and composition code
- `integration_test/` directory with executable runtime-validation coverage

Forbidden implementation directions:

- reintroducing shell code under `lib/src/`
- growing new top-level app composition files outside `lib/app/`

## Constraint 5: Home Quick Actions Must Be Real Flows

Home quick actions declared in the UX plan must map to user-completable flows, not section redirects.

Implementation consequences:

- quick actions that represent capture or create workflows must invoke a real input-and-save flow
- navigation-only stubs are allowed only for non-mutating browse actions
- runtime-validation coverage must include each documented mutating quick action

Required implementation concepts:

- a concrete text-entry capture flow behind `Paste Text`
- test coverage that verifies user-triggered state mutation for each mutating quick action

Forbidden implementation directions:

- implementing `Paste Text` as redirect-only behavior to Inbox
- keeping mutating quick actions as shell navigation placeholders

## Constraint 6: iOS Launch-Surface Validation

Runtime validation must include iOS launch coverage in addition to macOS integration checks.

Implementation consequences:

- keep macOS per-file integration tests as the default stable suite
- provide an explicit iOS smoke command for launch-surface validation when a device is available
- record a platform gap when iOS smoke validation is skipped

Required implementation concepts:

- `make mobile-ios-smoke` harness entrypoint
- device-targeted iOS smoke execution path

Forbidden implementation directions:

- treating macOS-only runtime validation as sufficient for mobile release confidence
- shipping launch-surface changes without at least smoke-level iOS verification

## Future Enforcement Strategy

Repo-local checks should enforce these constraints when implementation code exists:

- `bin/check-local-only-code`
- `bin/check-meeting-review-gate`
- `bin/check-bundle-schema`
- `bin/check-mobile-project-structure`
- `bin/check-home-quick-actions`
- `bin/check-implementation-constraints`

## Rule

If future code violates these constraints, fix the repo harness and the code path together. Do not rely on verbal reminders alone.