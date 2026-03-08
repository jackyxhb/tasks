# Architecture

## Purpose

Describe the personal field work agent app's main boundaries so future implementation stays aligned with the local-only product shape.

## System Shape

The app is a local-first mobile product with one operator per install. Version 1 stores all primary data on device and uses the internet only for optional LLM transcription or extraction.

## Boundaries

| Boundary | Input | Output | Owner |
|---|---|---|---|
| Capture Boundary | pasted text, manual entry, shared message, audio recording | `raw_capture` record | capture module |
| Parsing Boundary | raw capture and local context | structured candidate JSON | parser module |
| Review Boundary | structured candidates and local matches | finalized or provisional records | review module |
| Storage Boundary | validated internal records | SQLite rows and local files | store module |
| Reporting Boundary | filtered local records | in-app summaries, JSON, CSV, PDF | report module |
| Exchange Boundary | selected local records and attachments | versioned import/export bundle | exchange module |

## Data Shape Contracts

- Parse and validate external data at the boundary.
- Preserve raw source before normalization.
- Convert AI output into structured candidate objects before review.
- Final records are written only after local validation.
- Meeting records stay separate from task records.

## Module Ownership Rules

- `capture` owns raw text and audio intake.
- `parser` owns classification, extraction, and JSON contract handling.
- `review` owns candidate confirmation, dedup decisions, and promotion to final records.
- `store` owns SQLite and file persistence.
- `report` owns deterministic summaries and export formatting.
- `exchange` owns import/export bundle creation and ingestion.

## Architectural Invariants

- Local SQLite plus local file storage is the source of truth.
- Worker, coordinator, and project manager are record fields only.
- Meetings are separate entities that can emit task candidates.
- AI output is never silently accepted as final truth when ambiguity exists.
- Canonical exchange format is versioned JSON plus attachment manifest and checksums.

## Execution Flow

1. Entry: user captures text, message, or audio.
2. Boundary parse/validate: create `raw_capture`, optionally transcribe and extract.
3. Core execution: compute matches, candidates, and review states.
4. Persistence/output: write finalized or provisional records locally.
5. Event/log emission: record audit entries and observability events.

## Refactor Checklist

- [ ] Boundary contracts unchanged or explicitly versioned.
- [ ] Local-only data ownership still holds.
- [ ] Meeting-to-task review gating still exists.
- [ ] Import/export format changes are documented and versioned.
- [ ] Documentation updated in the same change.