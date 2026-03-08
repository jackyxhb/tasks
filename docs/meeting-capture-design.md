# Meeting Capture and Transcription Design

## Purpose

This document defines the version 1 design for meeting capture, transcription, extraction, review, and record creation in the personal field work agent app.

Meeting capture is treated as a staged evidence pipeline:

`audio -> transcript -> meeting summary/minutes -> extracted candidate records -> human confirmation`

The app must never treat AI output as final truth by itself. The final truth is the reviewed record saved by the agentee.

## Why This Feature Is High Risk

Meeting capture is more complex than normal task capture because:

- one meeting may cover multiple projects
- one meeting may assign multiple tasks
- one meeting may mention multiple people and roles
- dates and times may be implied instead of explicit
- speech may mix Chinese and English
- people may repeat the same action item several times
- some outcomes are decisions or notes, not tasks

Because of that, meeting records must stay separate from task records.

## Core Design Principles

- audio is the primary evidence
- raw source must always be preserved
- transcript is a transformation, not the truth
- extracted tasks must be candidates, not automatic final records
- ambiguity must be exposed to the user instead of hidden
- review must be faster than manual reconstruction from scratch

## Meeting Record Model

A meeting record should contain separate layers of information.

### Layer 1: Raw Evidence

- audio file
- recording metadata
- raw transcript

### Layer 2: Human-Readable Interpretation

- cleaned transcript
- short summary
- meeting minutes

### Layer 3: Structured Candidate Outputs

- related project candidates
- task candidates
- decision items
- unresolved questions
- people mentions
- date and time references

### Layer 4: Final Reviewed Records

- finalized meeting record
- created tasks
- linked projects
- optional project updates

## Separation Between Meeting and Task

Meeting must remain its own entity because one meeting can produce:

- zero tasks
- one task
- many tasks
- project metadata updates
- no action, but useful history

The app should not auto-convert every meeting into tasks. Instead, it should create extracted task candidates that the agentee can confirm, edit, merge, or reject.

## Capture Modes

Version 1 should support two related but distinct capture modes.

### Full Meeting Recording

Use when:

- multiple topics are discussed
- multiple projects may be involved
- multiple assignees may be mentioned

### Voice Memo Capture

Use when:

- one person is recording a follow-up note
- one issue or project is being summarized
- the capture is short and narrow in scope

These two modes may share the same audio engine, but they should remain distinct in UX and later review behavior.

## Capture UX Requirements

The meeting capture screen should include:

- start button
- pause button
- resume button
- stop button
- elapsed timer
- marker button for important moments
- quick note input for manual highlights
- visible recording state
- visible offline state

### Marker Function

Markers are valuable because the agentee often knows that a moment is important before the system does. Markers should be saved with timestamps and displayed again during transcript review.

### Recording Start Behavior

When recording starts, the app should immediately:

1. create a draft `meeting` record
2. create a linked `raw_capture` record
3. begin saving audio locally
4. store start time and timezone

This avoids losing context if the app is interrupted.

## Audio Storage Requirements

- audio must be stored locally first
- interrupted recordings must remain recoverable
- file path and checksum should be saved
- audio duration should be stored when recording ends
- the original recording should not be overwritten by cleanup or enhancement steps

## Transcription Strategy

Version 1 should use a hybrid pipeline.

### Recommended Pipeline

1. record audio locally
2. generate transcript using STT or multimodal transcription service when available
3. save transcript as raw transcript
4. optionally generate cleaned transcript
5. run extraction and summarization using LLM
6. store outputs as candidate data for review

### Why Hybrid Is Recommended

Hybrid is easier to debug because it separates:

- speech recognition quality
- reasoning and extraction quality

If transcription and extraction are done in one opaque call, it becomes harder to understand failure causes.

## Language Requirements

Version 1 should assume bilingual meeting content.

Minimum expectation:

- English support
- Chinese support
- mixed-language sentence tolerance

Important fields that must survive language mixing:

- project names
- people names
- addresses
- phone numbers
- dates
- times
- task types

## Speaker Handling

Speaker attribution is useful but should not be required for version 1.

Recommended policy:

- use diarization when available
- do not block extraction if diarization is poor or unavailable
- allow the agentee to manually relabel important statements during review

This avoids making the whole feature dependent on perfect speaker separation.

## Extraction Outputs

From one meeting transcript, the app should attempt to derive:

- meeting summary
- meeting minutes
- decisions list
- task candidates
- related project candidates
- related people candidates
- unresolved questions

These outputs must remain separate. They should not be collapsed into one summary blob.

## Task Candidate Rules

Each extracted task candidate should have:

- candidate title
- candidate task type
- linked project guess
- worker guess
- coordinator guess
- proposed date or time if available
- confidence score
- supporting source snippet

The supporting source snippet is important so the agentee can see why the app thinks the task exists.

## Meeting Review UX

The meeting review screen should contain:

- audio player
- markers timeline
- raw transcript
- cleaned transcript or formatted transcript
- summary tab
- minutes tab
- extracted tasks tab
- project links tab
- decisions tab

### Required Actions

- correct transcript text
- accept or reject task candidates
- merge with existing project
- create new project from meeting context
- convert task candidate into provisional task
- finalize meeting minutes
- export meeting output

### Review Philosophy

The review screen should optimize for low-friction correction. The agentee should not need to reconstruct the meeting manually unless the transcript is unusable.

## Handling Multi-Project Meetings

One meeting may reference multiple projects. The design must support:

- one meeting linked to many projects
- one project linked to many meetings
- extracted tasks grouped by project

The review UI should let the agentee split extracted content by project context without splitting the original recording.

## Handling Duplicate or Repeated Action Items

Meetings often repeat the same action item in different wording. The extraction layer should:

- group similar task candidates
- show possible duplicates before task creation
- avoid auto-creating multiple tasks from one repeated point

The agentee should decide whether duplicates are real duplicates or separate tasks.

## Failure Modes To Design For

### Wrong Project Linkage

Risk: project history is contaminated.

Mitigation:

- show project confidence
- show matching project suggestions
- require confirmation when the link is weak

### Wrong Assignee

Risk: task becomes operationally misleading.

Mitigation:

- highlight assignee uncertainty
- allow save without assignee when needed
- let task remain provisional

### Relative Time Misinterpretation

Examples:

- tomorrow morning
- next Monday
- after handover

Mitigation:

- normalize relative date using meeting timestamp
- preserve original phrase
- require confirmation for converted dates

### Number Corruption

Examples:

- phone numbers
- addresses
- unit numbers
- times

Mitigation:

- preserve raw transcript
- store source snippets
- highlight extracted number fields for review

### Overconfident Summary

Risk: polished summary hides unresolved ambiguity.

Mitigation:

- keep unresolved questions as a separate section
- preserve raw and cleaned transcript side by side

## AI Output Requirements

The AI layer should return structured JSON, not only free text.

Suggested output groups:

- `meeting_summary`
- `minutes_items`
- `decision_items`
- `task_candidates`
- `project_candidates`
- `people_mentions`
- `open_questions`
- `confidence_overall`

Each task candidate should include a supporting snippet or transcript reference.

## Confidence and Review Policy

High-confidence output may be prefilled aggressively, but not auto-finalized.

The app should require explicit review when:

- multiple projects are detected
- multiple assignees are detected
- date or time is inferred rather than stated
- confidence is low
- duplicate candidates are found

## Offline and Fallback Behavior

If internet is unavailable:

- recording still works
- meeting draft still works
- manual notes still work
- transcript can be requested later
- extracted tasks can be created manually

Fallback is mandatory because the app is local-first.

## Recommended Version 1 Scope

Include:

- local audio recording
- bilingual transcription support
- raw and cleaned transcript storage
- meeting summary generation
- task candidate extraction
- multi-project linking
- manual review and confirmation

Do not require in version 1:

- perfect speaker diarization
- real-time live transcription during recording
- real-time collaborative note editing
- automatic final task creation without review

## Validation Scenarios

### Scenario 1: Simple Single-Project Meeting

- one project mentioned
- one worker assigned
- one clear task created

### Scenario 2: Multi-Project Coordination Meeting

- multiple projects discussed
- multiple assignees mentioned
- extracted tasks grouped correctly by project

### Scenario 3: Mixed-Language Meeting

- Chinese and English mixed in one recording
- names, times, and project references survive transcription

### Scenario 4: Offline Recording

- audio is captured with no network
- meeting draft is preserved
- transcription happens later

### Scenario 5: Duplicate Action Mention

- same task is discussed multiple times
- app proposes one candidate or flags duplicates instead of creating noise

## Implementation Recommendation

For version 1, the most defensible implementation path is:

1. record locally first
2. transcribe second
3. extract structured outputs third
4. review candidate records fourth
5. finalize meeting and related tasks last

This sequence is safer, easier to debug, and more aligned with the app's local-first design.