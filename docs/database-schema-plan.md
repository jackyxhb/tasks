# Database Schema Plan

## Overview

This app uses a local-first database design for a single agentee. All operational data is stored on-device. There is no shared backend in version 1. The database must support project records, task records, meeting capture, raw intake, query, reporting, import/export, and audit history.

Primary storage choice:

- SQLite as the structured source of truth
- Local app file storage for audio, attachments, exports, and generated reports

## Design Principles

- Keep one source of truth on device
- Preserve raw input before extraction or normalization
- Support provisional records when extracted data is incomplete
- Keep duplicate detection explicit and reviewable
- Store both original values and normalized values when matching matters
- Use soft archive instead of hard delete by default

## Core Tables

### `projects`

Purpose: store master project information.

Fields:

- `id` - UUID primary key
- `project_name` - required display name
- `project_name_normalized` - normalized for matching and search
- `client_oem`
- `site_location`
- `site_location_normalized`
- `site_contact_name`
- `site_contact_phone`
- `coordinator_name`
- `project_manager_name`
- `status`
- `notes`
- `created_at`
- `updated_at`
- `archived_at`

Indexes:

- `project_name_normalized`
- `client_oem`
- `updated_at`

Constraints:

- `project_name` is required

### `tasks`

Purpose: store actionable work records for elevator service work.

Fields:

- `id` - UUID primary key
- `project_id` - foreign key to `projects.id`
- `task_type` - examples: `site survey`, `installation`, `tuning`, `handover`, `maintenance`
- `task_title`
- `task_title_normalized`
- `description`
- `scheduled_date`
- `start_time_local`
- `time_bucket`
- `duration_minutes`
- `location_snapshot`
- `worker_name`
- `worker_phone`
- `coordinator_name`
- `project_manager_name`
- `agentee_name`
- `status`
- `priority`
- `source_capture_id` - foreign key to `raw_captures.id`
- `dedup_key`
- `is_provisional`
- `needs_review`
- `created_at`
- `updated_at`
- `archived_at`

Indexes:

- `project_id`
- `scheduled_date`
- `task_type`
- `worker_name`
- `dedup_key`
- `needs_review`

Constraints:

- `task_type` is required
- `agentee_name` is required
- finalized tasks must have a unique `dedup_key`

### `meetings`

Purpose: store meeting records, transcript content, minutes, and extracted action context.

Fields:

- `id` - UUID primary key
- `title`
- `meeting_datetime`
- `meeting_timezone`
- `location_text`
- `summary`
- `minutes_markdown`
- `transcript_text`
- `source_capture_id` - foreign key to `raw_captures.id`
- `source_hash`
- `needs_review`
- `created_at`
- `updated_at`
- `archived_at`

Indexes:

- `meeting_datetime`
- `source_hash`
- `needs_review`

### `meeting_projects`

Purpose: link one meeting to multiple projects.

Fields:

- `meeting_id`
- `project_id`

Composite key:

- `meeting_id`, `project_id`

### `meeting_tasks`

Purpose: link one meeting to multiple extracted or related tasks.

Fields:

- `meeting_id`
- `task_id`
- `extraction_confidence`

Composite key:

- `meeting_id`, `task_id`

### `people`

Purpose: normalize repeated contacts such as workers, coordinators, project managers, and site contacts.

Fields:

- `id` - UUID primary key
- `name`
- `name_normalized`
- `phone`
- `role_hint`
- `company`
- `notes`
- `created_at`
- `updated_at`

Indexes:

- `name_normalized`
- `phone`

### `project_people`

Purpose: associate projects with people in known relationships.

Fields:

- `project_id`
- `person_id`
- `relation_type`

Relation examples:

- `worker`
- `site_contact`
- `coordinator`
- `project_manager`

Composite key:

- `project_id`, `person_id`, `relation_type`

### `raw_captures`

Purpose: persist every incoming unstructured source before parsing or review.

Fields:

- `id` - UUID primary key
- `channel` - examples: `manual_text`, `wechat_text`, `sms_text`, `audio`, `manual_form`
- `raw_text`
- `transcript_text`
- `audio_file_path`
- `attachment_group_id`
- `capture_time`
- `capture_timezone`
- `captured_by_agentee_name`
- `classification_type` - `task`, `project`, `meeting`, `mixed`, `unknown`
- `classification_confidence`
- `parse_status` - `new`, `parsed`, `reviewed`, `failed`
- `parse_version`
- `source_hash`
- `created_at`

Indexes:

- `channel`
- `capture_time`
- `classification_type`
- `parse_status`
- `source_hash`

### `attachments`

Purpose: store file metadata for local files linked to records.

Fields:

- `id` - UUID primary key
- `owner_record_type`
- `owner_record_id`
- `file_path`
- `mime_type`
- `file_size`
- `checksum`
- `created_at`

Owner record types:

- `raw_capture`
- `task`
- `meeting`
- `project`
- `export_bundle`

### `imports`

Purpose: keep provenance and decisions for incoming exchange bundles.

Fields:

- `id` - UUID primary key
- `bundle_name`
- `bundle_path`
- `bundle_checksum`
- `import_time`
- `preview_summary_json`
- `decision_summary_json`
- `status`

### `exports`

Purpose: track generated exchange bundles.

Fields:

- `id` - UUID primary key
- `bundle_name`
- `bundle_path`
- `bundle_checksum`
- `export_scope_type`
- `export_scope_value`
- `created_at`

### `audit_logs`

Purpose: preserve traceability for all critical data changes.

Fields:

- `id` - UUID primary key
- `record_type`
- `record_id`
- `action_type`
- `before_json`
- `after_json`
- `source_capture_id`
- `actor_name`
- `created_at`

Action examples:

- `create`
- `update`
- `merge`
- `dedup_reject`
- `import_apply`
- `export_create`
- `ai_extract`

### `report_runs`

Purpose: track generated reports and their filters.

Fields:

- `id` - UUID primary key
- `report_type`
- `filter_json`
- `output_format`
- `output_path`
- `created_at`

## Deduplication Strategy

### Project Dedup

Project records use:

- internal UUID as canonical identity
- normalized `project_name` as the main human matching field

### Task Dedup

Task records use a dedup key derived from:

- normalized local date
- normalized time bucket
- normalized `project_name`
- normalized `agentee_name`
- normalized `task_type` when available

If one of those fields is missing, the task remains provisional and does not enforce final uniqueness yet.

### Meeting Dedup

Meeting records use:

- internal UUID
- `meeting_datetime`
- `source_hash`

### Raw Capture Dedup

Raw capture identity uses:

- channel
- capture timestamp
- `source_hash`

## Provisional and Review States

Use the following fields for incomplete AI or partial manual records:

- `is_provisional = true`
- `needs_review = true`

Examples:

- task missing project confirmation
- message missing exact date
- meeting transcript extracted but tasks not yet confirmed

## Normalization Rules

- Keep original source value and normalized comparison value for names, project names, phones, dates, and locations
- Normalize phone numbers to E.164 when possible
- Preserve original phone string exactly as received
- Store all timestamps in ISO 8601 format
- Preserve local timezone explicitly

## Search Strategy

Use SQLite full-text search for:

- project names
- task titles
- task descriptions
- meeting summaries
- meeting minutes
- meeting transcripts
- raw capture text
- people names

Suggested implementation:

- one or more FTS virtual tables
- triggers to keep search indices synchronized with source tables

## Archive Strategy

- Use `archived_at` for soft archive
- Archived records stay searchable unless specifically filtered out
- Do not hard-delete by default
- Provide maintenance tools later for explicit cleanup

## Migration Strategy

- Add schema migration support from version 1
- Keep database schema version separate from import/export bundle version
- Make import/export format explicitly versioned

## Validation Checklist

- one direct task message can map cleanly into `projects`, `tasks`, `people`, and `raw_captures`
- one meeting can link to multiple projects and tasks
- provisional records can exist without breaking uniqueness constraints
- import/export history is fully traceable
- audit history preserves before and after states
- search can cover both structured and transcript-derived text