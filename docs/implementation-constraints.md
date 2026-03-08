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

## Future Enforcement Strategy

Repo-local checks should enforce these constraints when implementation code exists:

- `bin/check-local-only-code`
- `bin/check-meeting-review-gate`
- `bin/check-bundle-schema`
- `bin/check-implementation-constraints`

## Rule

If future code violates these constraints, fix the repo harness and the code path together. Do not rely on verbal reminders alone.