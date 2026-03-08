# Implementation Tickets

## Purpose

This document breaks the current app design into implementation-ready ticket groups.

Scope covered here:

- local-first app foundation
- project, task, and meeting records
- meeting capture and transcription
- meeting review flow
- import/export
- search and reports

## Ticket Group 1: Foundation

### T1. Create local database foundation

Goal:

- set up SQLite schema, migration system, and repository layer

Acceptance criteria:

- database initializes locally on first launch
- schema version table exists
- migrations can run incrementally
- repository layer supports projects, tasks, meetings, raw captures, and audit logs

### T2. Create local file storage service

Goal:

- define local directory structure for audio, attachments, reports, imports, and exports

Acceptance criteria:

- service creates and resolves expected local folders
- file references can be persisted safely
- checksum helper exists for attachments and bundles

### T3. Create audit logging service

Goal:

- make all critical changes traceable

Acceptance criteria:

- create, update, merge, AI extract, import, export, and finalize events can be logged

## Ticket Group 2: Core Records

### T4. Implement Project CRUD

Goal:

- create, edit, archive, and browse local project records

Acceptance criteria:

- project fields match design spec
- project list and detail view can read/write local data

### T5. Implement Task CRUD with provisional support

Goal:

- create and manage task records with review flags and dedup keys

Acceptance criteria:

- task records support finalized and provisional states
- dedup key is computed consistently
- task list filters work locally

### T6. Implement Person normalization layer

Goal:

- manage repeated contacts consistently

Acceptance criteria:

- people can be linked to projects
- person lookup supports suggestions by name and phone

## Ticket Group 3: Raw Capture Pipeline

### T7. Implement RawCapture storage

Goal:

- store all incoming text and audio as raw captures before extraction

Acceptance criteria:

- pasted text creates raw capture record
- manual form draft creates raw capture record when relevant
- audio meeting start creates raw capture record

### T8. Implement capture classification service

Goal:

- classify capture into task, project, meeting, mixed, or unknown

Acceptance criteria:

- classification result is stored with confidence and parse version
- fallback to unknown works without crash

### T9. Implement dedup service

Goal:

- find likely duplicate tasks, meetings, and projects

Acceptance criteria:

- task dedup uses canonical key logic
- duplicate candidates are surfaced to review UI

## Ticket Group 4: Meeting Capture and Transcription

### T10. Implement meeting recording flow

Goal:

- capture local audio safely and create draft meeting record on start

Acceptance criteria:

- meeting draft is created when recording starts
- pause and resume work
- recording survives interruptions without losing file

### T11. Implement meeting transcript storage

Goal:

- persist raw transcript, cleaned transcript, and provider metadata

Acceptance criteria:

- transcript data is linked to meeting and raw capture
- failed transcription states are preserved

### T12. Implement transcription provider abstraction

Goal:

- allow the app to request transcription from a selected AI or STT provider

Acceptance criteria:

- provider interface is isolated behind one service contract
- failed response does not break local meeting record

## Ticket Group 5: Meeting Extraction and Review

### T13. Implement extraction JSON contract validation

Goal:

- validate AI output before record mutation

Acceptance criteria:

- JSON response is checked against required contract
- invalid output is rejected safely

### T14. Implement meeting review state machine

Goal:

- enforce meeting lifecycle transitions consistently

Acceptance criteria:

- all states in review-state doc are supported
- invalid transitions are blocked

### T15. Implement meeting review screen

Goal:

- provide transcript, summary, minutes, and candidate task review UI

Acceptance criteria:

- user can accept, reject, edit, and link extracted items
- source snippets are visible for extracted items

### T16. Implement task candidate resolution flow

Goal:

- convert extracted task candidates into new tasks, merged tasks, or rejected items

Acceptance criteria:

- candidate substates are tracked
- user can save candidate as provisional task

## Ticket Group 6: Core UX Screens

### T17. Implement Home screen

### T18. Implement Inbox screen

### T19. Implement Inbox Review screen

### T20. Implement Project List and Project Detail screens

### T21. Implement Task List and Task Detail screens

### T22. Implement Meeting List, Capture, and Review screens

Acceptance criteria for this group:

- all screens read and write local records correctly
- low-confidence states are visible
- navigation supports core workflows without dead ends

## Ticket Group 7: Search and Reports

### T23. Implement full-text search indexing

Goal:

- support text search across projects, tasks, meetings, people, and raw captures

Acceptance criteria:

- FTS indices update when records change
- search returns grouped results with snippets

### T24. Implement structured filters

Goal:

- filter by project, OEM, worker, coordinator, project manager, task type, date range, and status

Acceptance criteria:

- filters combine correctly with search queries

### T25. Implement report generation

Goal:

- generate in-app summaries and exportable report files

Acceptance criteria:

- daily task list works
- project summary works
- meeting minutes pack works
- CSV and JSON outputs work

## Ticket Group 8: Import and Export

### T26. Implement export bundle creator

Goal:

- package records and attachments into a versioned portable bundle

Acceptance criteria:

- bundle manifest is valid JSON
- selected scope is respected
- checksums are generated

### T27. Implement import preview and merge flow

Goal:

- allow safe local import from another install

Acceptance criteria:

- duplicate candidates are shown before write
- merge or create decisions are captured
- import action is audited

## Ticket Group 9: Offline and Fallback Behavior

### T28. Implement offline-safe AI fallback states

Goal:

- preserve usability when transcription or extraction is unavailable

Acceptance criteria:

- meetings can remain manual-only
- pending AI states are visible
- user can continue manual editing

## Ticket Group 10: Validation and Polish

### T29. Seed validation data from current examples

Goal:

- use real examples for acceptance checks

Acceptance criteria:

- Pompallier Ponsonby task can be represented correctly
- one sample meeting scenario is available for testing

### T30. Run end-to-end acceptance checks

Goal:

- verify core workflows before broader implementation begins

Acceptance criteria:

- text capture to final task works
- meeting audio to reviewed meeting and task candidates works
- export then import round-trip works
- search and reports work on created records

## Suggested Implementation Order

1. T1-T3 foundation
2. T4-T9 records and raw capture
3. T10-T16 meeting and review pipeline
4. T17-T22 primary screens
5. T23-T25 search and reports
6. T26-T27 import and export
7. T28-T30 fallback and validation