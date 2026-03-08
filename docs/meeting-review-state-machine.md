# Meeting Review State Machine

## Purpose

This document defines the review lifecycle for meeting capture, transcription, extraction, correction, and finalization.

The goal is to make meeting processing predictable, reviewable, and safe in a local-first app.

## Principles

- audio capture and raw storage happen before AI processing
- AI output creates candidates, not final truth
- the agentee controls every irreversible transition
- failed AI processing must not block manual completion

## Main States

### 1. `draft_recording`

Meaning:

- meeting draft exists
- audio recording is in progress or paused

Entry conditions:

- user starts meeting recording

Exit paths:

- `recorded_pending_transcription`
- `cancelled`

### 2. `recorded_pending_transcription`

Meaning:

- audio recording is saved locally
- transcription has not started or is queued

Entry conditions:

- user stops recording
- audio file is saved successfully

Exit paths:

- `transcribing`
- `manual_review_only`
- `cancelled`

### 3. `transcribing`

Meaning:

- audio is being processed by transcription service

Entry conditions:

- user initiates transcription
- required network or AI path is available

Exit paths:

- `transcribed_pending_extraction`
- `transcription_failed`

### 4. `transcription_failed`

Meaning:

- transcription attempt failed

Entry conditions:

- network error
- provider error
- invalid response
- unsupported audio

Exit paths:

- `transcribing`
- `manual_review_only`

### 5. `transcribed_pending_extraction`

Meaning:

- transcript exists
- extraction and summarization have not started or are queued

Entry conditions:

- transcription completed successfully

Exit paths:

- `extracting`
- `manual_review_only`

### 6. `extracting`

Meaning:

- transcript is being summarized and converted into candidate structured records

Entry conditions:

- user initiates extraction
- transcript is available

Exit paths:

- `review_required`
- `extraction_failed`

### 7. `extraction_failed`

Meaning:

- extraction request failed or returned unusable output

Entry conditions:

- invalid JSON
- low-quality provider result
- local schema validation failure

Exit paths:

- `extracting`
- `manual_review_only`

### 8. `manual_review_only`

Meaning:

- the meeting can still be reviewed and completed without successful AI output

Entry conditions:

- user chooses manual path
- transcription or extraction is unavailable or not trusted

Exit paths:

- `review_required`
- `finalized`

### 9. `review_required`

Meaning:

- transcript and or extraction results are available
- user review is required before final save

Entry conditions:

- extraction completed
- or manual data exists and needs confirmation

Exit paths:

- `review_in_progress`
- `finalized`
- `archived`

### 10. `review_in_progress`

Meaning:

- user is actively editing transcript, summary, project links, and task candidates

Entry conditions:

- user opens meeting review screen

Exit paths:

- `review_required`
- `task_candidate_resolution`
- `finalized`

### 11. `task_candidate_resolution`

Meaning:

- extracted tasks are being accepted, rejected, merged, or converted to provisional tasks

Entry conditions:

- one or more task candidates exist

Exit paths:

- `review_in_progress`
- `finalized`

### 12. `finalized`

Meaning:

- meeting record is accepted as final local record
- transcript, summary, minutes, links, and created tasks are saved

Entry conditions:

- user confirms finalization

Exit paths:

- `reopened`
- `archived`

### 13. `reopened`

Meaning:

- a finalized meeting was reopened for corrections

Entry conditions:

- user explicitly reopens finalized meeting

Exit paths:

- `review_in_progress`
- `finalized`

### 14. `archived`

Meaning:

- meeting is moved out of active lists but still preserved locally

Entry conditions:

- user archives meeting

Exit paths:

- `reopened`

### 15. `cancelled`

Meaning:

- meeting draft was abandoned before becoming a meaningful record

Entry conditions:

- user cancels recording or discards draft

Exit paths:

- none in normal flow

## State Transition Summary

```text
draft_recording
  -> recorded_pending_transcription
  -> cancelled

recorded_pending_transcription
  -> transcribing
  -> manual_review_only
  -> cancelled

transcribing
  -> transcribed_pending_extraction
  -> transcription_failed

transcription_failed
  -> transcribing
  -> manual_review_only

transcribed_pending_extraction
  -> extracting
  -> manual_review_only

extracting
  -> review_required
  -> extraction_failed

extraction_failed
  -> extracting
  -> manual_review_only

manual_review_only
  -> review_required
  -> finalized

review_required
  -> review_in_progress
  -> finalized
  -> archived

review_in_progress
  -> review_required
  -> task_candidate_resolution
  -> finalized

task_candidate_resolution
  -> review_in_progress
  -> finalized

finalized
  -> reopened
  -> archived

reopened
  -> review_in_progress
  -> finalized

archived
  -> reopened
```

## Candidate Task Substates

Each extracted task candidate should also have its own substate.

### Candidate States

- `new_candidate`
- `accepted_as_new_task`
- `merged_into_existing_task`
- `saved_as_provisional_task`
- `rejected`

These substates should not block meeting finalization if the user intentionally leaves some candidates rejected.

## Guard Conditions

The app should prevent direct finalization if:

- audio file is missing for an audio-origin meeting
- transcript save failed and no manual notes exist
- extraction output failed schema validation but is still being displayed as if valid

The app should warn, but still allow finalization, if:

- one or more task candidates remain unresolved
- multiple projects are linked with low confidence
- transcript confidence is low

## Manual Fallback Policy

If AI steps fail, the meeting should still be completable by:

- editing transcript manually
- entering manual minutes
- creating manual tasks
- linking projects manually

This is mandatory because the app is local-first and cannot depend entirely on AI availability.

## Audit Requirements Per Transition

The app should log audit events for:

- recording started
- recording stopped
- transcription requested
- transcription failed
- extraction requested
- extraction failed
- candidate accepted or rejected
- meeting finalized
- meeting reopened
- meeting archived

## UX Expectations By State

### In `draft_recording`

- show recording controls
- disable finalize actions

### In `recorded_pending_transcription`

- show audio playback
- show action to transcribe now or later

### In `transcription_failed`

- show failure reason
- offer retry and manual path

### In `review_required`

- highlight uncertain fields and extracted candidates
- show raw and cleaned transcript

### In `finalized`

- show read-focused detail screen
- allow explicit reopen action

## Recommended Version 1 Simplifications

- no automatic finalization
- no background auto-publishing of tasks
- no dependency on perfect diarization
- no dependency on real-time transcript streaming

These constraints reduce hidden failure risk in version 1.