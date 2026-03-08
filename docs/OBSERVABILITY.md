# Observability

## Goal

Make local app and harness workflows diagnosable without relying on a shared backend.

## Required Event Fields

- `timestamp`
- `level`
- `event_name`
- `trace_id`
- `run_id`
- `step_id`
- `component`
- `status`
- `duration_ms`

## Additional App-Specific Fields

- `record_type`
- `record_id`
- `capture_id`
- `meeting_id`
- `task_id`
- `project_id`
- `provider_name`
- `provider_model`
- `confidence`
- `offline_mode`

## Event Taxonomy

- `harness.start`
- `harness.step.start`
- `harness.step.finish`
- `harness.step.fail`
- `harness.check.pass`
- `harness.check.fail`
- `capture.created`
- `meeting.recording.started`
- `meeting.recording.stopped`
- `transcription.requested`
- `transcription.completed`
- `transcription.failed`
- `extraction.requested`
- `extraction.completed`
- `extraction.failed`
- `review.finalized`
- `export.created`
- `import.applied`

## Logging Rules

- Emit structured logs for machine parsing.
- Keep field names stable over time.
- Include source IDs so a failure can be traced back to raw evidence.
- Redact secrets and minimize personally identifiable fields in external logs.

## Correlation Rules

- A meeting recording flow should keep one `trace_id` from recording start through review finalization.
- AI operations should log provider and model metadata.
- Import and export flows should log bundle checksum and scope.

## Metrics

- Smoke-check duration
- Harness audit pass rate
- Transcription success rate
- Extraction validation failure rate
- Review-to-finalization duration
- Duplicate-candidate rate

## Alerting and Review

- Alert locally or surface warnings when repeated harness checks fail.
- Surface repeated transcription or extraction failures in the app admin or settings area later.
- Investigate any regression in smoke-check runtime budget.

## Minimum Implementation Rule

Even in a local-only app, critical transitions must remain observable through structured local logs or persisted event records.