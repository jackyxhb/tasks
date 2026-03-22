# Product Requirements Document (PRD)

## Product

Personal Field Work Agent v1

## Document Status

- status: proposed for implementation and promotion alignment
- date: 2026-03-13
- owner: product and engineering
- source alignment: derived from the canonical docs under `docs/`

## 1) Executive Summary

Personal Field Work Agent v1 is a local-first mobile app for one operator (the agentee) to capture, review, and manage elevator field work records quickly and safely.

The product combines fast intake (text and audio), structured review, traceable record keeping, and portable import/export bundles. AI is optional and assistive only. Final records are always controlled by human review.

This PRD is designed to support both implementation and promotion of the new agent by providing:

- product intent and differentiators
- strict scope and constraints for v1
- end-to-end functional requirements
- measurable success criteria
- release and validation gates

## 2) Problem Statement

Field coordination information is scattered across messages, calls, and ad-hoc notes. This causes:

- slow conversion from raw communication to clean records
- duplicate or conflicting tasks
- weak traceability from final tasks back to source evidence
- reporting friction when exporting information to others

Meetings are especially risky due to mixed languages, repeated action items, and multi-project context. Without a review-gated workflow, extraction mistakes can become operational errors.

## 3) Target User and Operating Model

Primary user:

- one agentee per install

Operational model:

- worker, coordinator, and project manager are data fields, not app permission roles
- no multi-user auth model in v1
- no shared backend in v1

## 4) Product Vision and Positioning

### Vision

Deliver a dependable personal field-work operating system that turns raw daily communication into reviewable, searchable, and exportable local records.

### Positioning for Promotion

Personal Field Work Agent v1 should be promoted as:

- local-first and privacy-respecting by default
- AI-assisted but human-controlled
- purpose-built for fast field task and meeting workflows
- practical for real-world handoff through import/export bundles instead of fragile sync assumptions

### Core Differentiators

- local-only source of truth in SQLite and local files
- strict meeting-to-task review gate
- evidence-preserving pipeline (audio/text -> transcript/extraction -> candidate review -> final record)
- deterministic portable exchange format with checksums

## 5) Goals and Non-Goals

### Goals (v1)

- capture text and meeting audio with minimal friction
- preserve all raw sources before parsing
- convert extraction output into reviewable candidates
- support project, task, and meeting records with clear traceability
- provide local search, reporting, archive, and import/export
- remain usable offline except optional AI/STT features

### Non-Goals (v1)

- sync engine or shared backend
- multi-user collaboration and role-based permissions
- auto-finalization of ambiguous extracted tasks
- CSV or PDF as canonical re-import format

## 6) Success Metrics

Product metrics:

- high completion rate for text capture -> finalized task workflow
- high completion rate for audio capture -> review-required meeting workflow
- reduced duplicate-task incidence through dedup + review
- reduced time from capture to finalization

System and quality metrics:

- transcription success rate
- extraction validation failure rate
- review-to-finalization duration
- duplicate-candidate rate
- harness check pass rate and smoke runtime stability

## 7) Scope

### In Scope

- local database foundation and migrations
- local file storage for audio, attachments, reports, imports, exports
- project/task/meeting/person/raw-capture data model
- capture classification, extraction candidate handling, dedup service
- meeting recording, transcription pipeline, extraction validation, review state machine
- Home, Inbox, review, project/task/meeting management, search, reports, import, export, archive, settings
- canonical versioned JSON bundle import/export with preview and merge decisions
- audit logging and core observability events

### Out of Scope

- shared cloud data model
- cross-device conflict resolution
- live collaboration/websocket workflows
- background replication

## 8) Product Requirements

### 8.1 Capture and Intake

The app must:

- support text intake and audio recording intake
- create raw capture records before extraction/finalization
- store source metadata including channel, timestamps, and confidence/classification metadata

Meeting capture must:

- create draft meeting and raw capture on recording start
- support start/pause/resume/stop
- save audio locally first and preserve interruptions safely
- keep marker and quick note context for review

### 8.2 Parsing and Candidate Creation

The app must:

- classify captures into task/project/meeting/mixed/unknown
- validate extraction/transcription JSON before record mutation
- store provider/model metadata and parse versions for traceability
- keep invalid or low-confidence output in review-needed states

### 8.3 Review and Promotion Gate

The app must enforce:

- meeting records remain separate from tasks
- extraction creates candidates, not final tasks
- explicit user confirmation for candidate promotion
- visible source snippets for extracted decisions/items/tasks
- provisional task support when information is incomplete

### 8.4 Record Management

Project requirements:

- create/edit/archive/browse project records with required fields and local suggestions

Task requirements:

- create/edit/archive/complete/convert provisional tasks
- compute and persist dedup keys for final tasks
- support filters and status views (today/upcoming/all/provisional)

Meeting requirements:

- preserve transcript and minutes layers
- support multi-project linking and extracted-task resolution
- support reopen and archive lifecycle states

### 8.5 Search and Reports

Search requirements:

- structured filters and full-text discovery across projects, tasks, meetings, raw captures, and people
- grouped result presentation with snippets

Report requirements:

- deterministic local aggregation
- in-app summaries and exportable PDF/CSV/JSON outputs
- report run traceability

### 8.6 Import and Export

Export requirements:

- generate versioned JSON bundle with attachment manifest and checksums
- allow scope selection and optional attachments

Import requirements:

- parse and validate before write
- preview incoming records and duplicate candidates before confirmation
- force explicit merge/create decisions
- persist audited import outcomes

## 9) UX Requirements

Primary sections:

- Home
- Inbox
- Projects
- Tasks
- Meetings
- Search
- Reports
- Import
- Export
- Settings
- Archive

Mandatory UX behaviors:

- Home quick actions for mutating flows must map to real completable flows
- low-confidence extraction states must be visually explicit
- review screens must keep raw source and extracted data visible together
- provisional items must be easy to identify and resolve

## 10) Data and Schema Requirements

Structured source of truth:

- SQLite tables for projects, tasks, meetings, links, people, raw captures, attachments, imports, exports, audit logs, and report runs

Schema requirements:

- preserve both original and normalized values where matching/searching matters
- use soft archive (`archived_at`) rather than hard-delete by default
- enforce task dedup key behavior and review flags

## 11) AI and Trust Requirements

AI policy:

- optional, assistive, and replaceable via provider abstraction
- never sole authority for final record truth

Guardrails:

- preserve raw source data
- validate structured output locally
- require review for ambiguity/low confidence
- do not auto-link ambiguous multi-project or multi-assignee outputs

Confidence handling:

- confidence scores must be captured and shown
- warnings must be surfaced in review workflows

## 12) Offline, Reliability, and Platform Requirements

Must work offline:

- text capture
- manual entry and correction
- audio recording
- local browse/search/archive/report and export bundle creation

May require internet:

- transcription
- extraction
- summary generation

Fallback requirements:

- pending/failure states must not block manual completion
- manual-review-only path must remain available

Runtime validation requirements:

- stable macOS integration suite (per-file execution)
- explicit iOS launch smoke path when device/simulator is available

## 13) Security and Privacy Requirements

- local storage is default data ownership model
- minimize sensitive fields in external logs
- redact secrets where relevant
- maintain record-level traceability for audit and correction

## 14) Observability Requirements

The app and harness must emit structured events for key lifecycle transitions, including:

- capture creation
- meeting recording start/stop
- transcription and extraction requested/completed/failed
- review finalization
- import/export creation and apply events

Events should include stable correlation identifiers for end-to-end tracing.

## 15) Release Plan and Milestones

Implementation milestone sequence:

1. Foundation: T1-T3
2. Core records and raw capture: T4-T9
3. Meeting pipeline and review gate: T10-T16
4. Core screens: T17-T22
5. Search and reports: T23-T25
6. Import/export: T26-T27
7. Offline fallback and end-to-end validation: T28-T30

## 16) Acceptance Criteria

The release candidate must demonstrate:

- text capture can become a reviewed/finalized task
- meeting audio can become transcript + reviewed meeting + task candidates
- task candidates are never silently auto-finalized from extraction
- export/import round-trip works with canonical JSON bundle validation
- search and reports operate on local structured data
- harness checks for architecture constraints and project boundaries pass

## 17) Risks and Mitigations

Key risks:

- project linkage errors in multi-project meetings
- assignee extraction errors in mixed-language transcripts
- repeated action items creating duplicate task candidates
- platform-specific launch regressions not visible in one platform suite

Mitigations:

- source-snippet-backed review UI with confidence indicators
- explicit review state machine and task candidate resolution states
- dedup + merge decision flow before final creation
- explicit iOS smoke validation path in addition to macOS defaults

## 18) Promotion-Ready Messaging Inputs

For launch and stakeholder promotion, communications should emphasize:

- Local-first by design: one operator, one source of truth on device
- AI that assists, not overrides: every ambiguous extraction is review-gated
- Built for real field coordination: fast capture, evidence traceability, practical reports
- Portable collaboration without shared backend: versioned import/export bundles

Suggested one-line positioning:

"A local-first field work agent that turns raw messages and meetings into reviewable, reliable records you can act on and share safely."

## 19) Dependency References

This PRD is aligned to:

- app design specification
- architecture and observability docs
- database schema and UX screen plan
- meeting capture design, review state machine, and transcription JSON contract
- implementation constraints and implementation tickets
