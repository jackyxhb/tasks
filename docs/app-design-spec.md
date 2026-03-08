# Personal Field Work Agent App Design Spec

## Overview

This document combines the concrete database schema plan, screen-by-screen UX plan, and technical architecture plan for a personal field work agent app. The app is designed for elevator service project work and is operated by one agentee per install.

Version 1 constraints:

- local-only data storage
- no sync and no shared backend
- import and export for exchange between separate installs
- meeting capture, transcription, and extraction are included
- internet access is only needed for optional LLM-assisted features

## Design Invariants

These invariants are intentionally phrased so the repo harness can check them directly.

- Invariant: Version 1 is local-only.
- Invariant: Do not introduce sync, shared backend, or cross-device collaboration unless scope changes explicitly.
- Invariant: Worker, coordinator, and project manager are record fields, not app permission roles.
- Invariant: Meeting records remain separate from task records.
- Invariant: AI extraction creates reviewable candidates, not auto-final records.
- Invariant: Canonical exchange format is a versioned JSON bundle with attachment manifest and checksums.

## Product Model

- one app install has one operator
- worker, coordinator, and project manager are record fields, not app roles
- projects, tasks, meetings, and raw captures are separate entities
- all incoming unstructured content is preserved before parsing

## Core Entities

- Project
- Task
- Meeting
- RawCapture
- Person
- Attachment
- ImportJob
- ExportBundle
- AuditLog
- ReportRun

## Database Schema Summary

### Core storage

- SQLite for structured data
- local file storage for audio, attachments, reports, and exchange bundles

### Main tables

- `projects`
- `tasks`
- `meetings`
- `meeting_projects`
- `meeting_tasks`
- `people`
- `project_people`
- `raw_captures`
- `attachments`
- `imports`
- `exports`
- `audit_logs`
- `report_runs`

### Key rules

- preserve both original and normalized values where matching matters
- task dedup key is based on normalized date, normalized time bucket, normalized project name, normalized agentee name, and normalized task type when available
- incomplete extracted records are stored as provisional or review-needed
- archive is soft archive using `archived_at`

## UX Structure Summary

Primary screens:

- Home
- Inbox
- Inbox Review
- Project List
- Project Detail
- New Project / Edit Project
- Task List
- Task Detail
- New Task / Edit Task
- Meeting List
- Meeting Capture
- Meeting Review
- Search
- Reports
- Import
- Export
- Settings
- Archive

Main UX goals:

- fastest possible capture from pasted text or audio
- minimal correction effort for extracted fields
- strong traceability from final record back to raw source
- simple local browsing and reporting

## Technical Architecture Summary

### Storage

- SQLite as source of truth
- app sandbox file storage for binary files and generated outputs

### Core modules

- `CaptureService`
- `ParserService`
- `DedupService`
- `MeetingService`
- `ReportService`
- `ImportExportService`
- `SearchService`
- `AuditService`

### AI policy

- AI is optional and assistive
- all raw sources are preserved locally
- structured AI output is validated before save
- low-confidence output requires manual confirmation

### Exchange model

- explicit import and export replace sync
- canonical exchange format is versioned JSON plus attachment manifest

## Recommended Implementation Sequence

1. Implement local database schema and migration system.
2. Implement raw capture pipeline and inbox review flow.
3. Implement project and task CRUD screens.
4. Implement audio meeting capture and meeting review.
5. Implement search and report generation.
6. Implement import and export bundle handling.
7. Add optional AI enhancement for extraction, transcription, and summaries.

## Detailed References

See the focused documents for full details:

- [ARCHITECTURE.md](./ARCHITECTURE.md)
- [OBSERVABILITY.md](./OBSERVABILITY.md)
- [agent-task-contract.md](./agent-task-contract.md)
- [implementation-constraints.md](./implementation-constraints.md)
- [flutter-project-structure.md](./flutter-project-structure.md)
- [control/CONTROL_SYSTEM.md](./control/CONTROL_SYSTEM.md)
- [control/SETPOINTS.md](./control/SETPOINTS.md)
- [control/SENSORS.md](./control/SENSORS.md)
- [control/CONTROLLER.md](./control/CONTROLLER.md)
- [control/ACTUATORS.md](./control/ACTUATORS.md)
- [control/FEEDBACK_LOOP.md](./control/FEEDBACK_LOOP.md)
- [control/STABILITY.md](./control/STABILITY.md)
- [control/ENTROPY.md](./control/ENTROPY.md)
- [database-schema-plan.md](./database-schema-plan.md)
- [ux-screen-plan.md](./ux-screen-plan.md)
- [technical-architecture-plan.md](./technical-architecture-plan.md)
- [meeting-capture-design.md](./meeting-capture-design.md)
- [meeting-transcription-json-contract.md](./meeting-transcription-json-contract.md)
- [meeting-review-state-machine.md](./meeting-review-state-machine.md)
- [implementation-tickets.md](./implementation-tickets.md)

## Validation Goals

- direct task text can become a reviewed project and task record
- meeting audio can become transcript, minutes, and extracted tasks
- all core app behavior works offline except optional AI calls
- export and import can exchange records across separate installs
- search and reports work across projects, tasks, meetings, people, and transcripts