# Technical Architecture Plan

## Overview

This app is a local-first personal work agent. It has no shared backend in version 1. All business data is stored on device. Internet access is used only for optional LLM-powered transcription, classification, extraction, and summarization.

## Architecture Goals

- local-only source of truth
- reliable audio and text capture
- deterministic local storage and querying
- optional AI augmentation with graceful fallback
- explicit import and export in place of sync
- strong traceability through audit logs

## App Shape

Recommended app shape:

- one cross-platform mobile app
- no backend dependency for normal operation
- no cross-device sync in version 1

Recommended implementation direction:

- React Native or Flutter

Framework selection should be driven by:

- SQLite quality
- audio recording APIs
- local file handling
- PDF and CSV generation capability

## Local Storage Architecture

Structured storage:

- SQLite database as the source of truth

File storage:

- audio files
- images and other attachments
- JSON export bundles
- PDF reports
- CSV reports

Suggested local folder layout:

- `audio/`
- `attachments/`
- `exports/`
- `imports/`
- `reports/`
- `temp/`

## Core Service Modules

### `CaptureService`

Responsibilities:

- intake pasted text
- intake shared messages
- save manual form drafts
- create raw capture records
- hand off audio files for processing

### `ParserService`

Responsibilities:

- classify incoming capture as task, project, meeting, mixed, or unknown
- extract structured entities from text or transcript
- return structured JSON candidates

### `DedupService`

Responsibilities:

- compute dedup keys
- find existing match candidates
- mark provisional records when key data is missing

### `MeetingService`

Responsibilities:

- manage meeting drafts
- bind audio and transcript to meeting records
- extract minutes, decisions, and tasks

### `ReportService`

Responsibilities:

- build deterministic summaries from structured data
- generate in-app summaries
- generate PDF, CSV, and JSON outputs

### `ImportExportService`

Responsibilities:

- create versioned export bundles
- parse incoming bundles
- preview duplicate candidates and merge decisions

### `SearchService`

Responsibilities:

- execute structured filters
- run full-text search across indexed text
- prepare grouped search results with snippets

### `AuditService`

Responsibilities:

- log create, update, merge, import, export, and AI extraction events
- preserve before and after states

## Audio Capture Architecture

Requirements:

- audio must be stored locally first
- meeting draft should be created when recording starts
- interruptions should not lose the recording
- metadata such as duration, file path, and checksum should be saved

Recommended flow:

1. User starts meeting recording.
2. App creates `raw_capture` and draft `meeting` records.
3. Audio stream is saved locally.
4. User can pause, resume, or stop.
5. When recording ends, the meeting stays local and can later be transcribed.

## Transcription Architecture

Two supported paths:

- online transcription when network and LLM or STT service are available
- manual review and manual note entry when offline or AI is unavailable

Transcription output should include:

- transcript text
- detected language or language mode
- model/provider metadata
- parse confidence when available

## LLM Integration Architecture

Use a provider abstraction layer so the app can switch models or providers later.

Core AI operations:

- classify capture
- extract project and task fields from text
- transcribe audio
- summarize meeting
- extract tasks from meeting transcript
- generate optional summary text for reports

Recommended prompt families:

- `classify_capture`
- `extract_task_project_fields`
- `transcribe_meeting_audio`
- `summarize_meeting`
- `extract_meeting_tasks`
- `generate_report_summary`

## AI Guardrails

- always preserve raw source text and raw transcript
- store model name and parse version with every AI result
- prefer structured JSON outputs from the model
- validate model output locally before writing records
- require review for low-confidence extraction
- never auto-commit ambiguous multi-project or multi-assignee results without confirmation

## Offline Behavior

Must work offline:

- text capture
- manual entry
- audio recording
- local browsing
- local search
- local archive browsing
- report generation from existing structured data
- export bundle creation

May require internet:

- transcription
- AI extraction
- AI summary generation

Fallback behavior:

- mark AI jobs as pending
- allow manual correction or full manual entry

## Import and Export Architecture

Canonical exchange format:

- versioned JSON manifest
- attachment file references
- checksums for integrity

Bundle contents:

- schema version
- export metadata
- projects
- tasks
- meetings
- people
- attachments manifest
- checksums

Secondary export formats:

- CSV
- PDF

Import flow requirements:

- preview before write
- duplicate detection before write
- explicit merge or create decisions
- audit trail after write

## Query and Search Architecture

Structured querying:

- SQLite indexed queries for field filters

Text querying:

- SQLite FTS for project names, task descriptions, raw capture text, meeting summaries, minutes, and transcripts

Result handling:

- group by record type
- show snippets for text matches
- support combined filter plus text search

## Reporting Architecture

Reports should be built from deterministic local aggregation first.

Base report outputs:

- daily task list
- by-project task list
- worker summary
- meeting minutes pack
- project summary
- custom filtered list

Output formats:

- in-app summary views
- PDF
- CSV
- JSON

Optional enhancement:

- LLM-generated narrative summary layered on top of deterministic report data

## Migration Architecture

- database schema versioning from version 1
- incremental local migrations
- import/export bundle schema versioning independent from DB schema version

## Recovery and Observability

Local logging should cover:

- failed import attempts
- failed export attempts
- failed AI extraction
- failed transcription
- failed report generation

Because there is no backend, the app should emphasize:

- backup reminders
- export reminders
- recoverable draft states

## Performance Considerations

Target local dataset scale:

- thousands of tasks
- hundreds of meetings
- long transcripts

Recommended practices:

- lazy attachment loading
- virtualized transcript rendering
- paginated or incremental search result loading

## Security and Privacy

- keep business data local by default
- use secure local file handling where platform APIs allow it
- make external AI submission explicit and user-controlled
- avoid sending more metadata than necessary with AI requests

## Implementation Validation Checklist

- local database can operate without any network dependency
- audio recording survives interruptions and keeps file integrity
- AI output is validated before save
- import and export bundles round-trip correctly
- search works for both structured fields and transcript phrases
- reports can be generated fully from local data