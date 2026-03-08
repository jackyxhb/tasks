# UX Screen Plan

## Overview

This app is designed for one operator: the agentee. The UX should optimize for fast capture, fast correction of extracted data, local browsing, and report output. The main workflows are:

- capture a task from text or message
- capture a meeting from audio
- correct AI-extracted project, task, and meeting data
- browse projects, tasks, and meetings
- query and report local records
- import or export data bundles

## Navigation Structure

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

## 1. Home

Purpose:

- fast launch point for daily use
- quick overview of what needs attention

Content:

- today task summary
- inbox pending count
- upcoming tasks
- recent meetings
- recent exports or imports

Quick actions:

- `Paste Text`
- `Record Meeting`
- `New Task`
- `New Project`
- `Import`
- `Search`

Design notes:

- keep actions reachable with one hand
- prioritize pending review items over passive statistics

## 2. Inbox

Purpose:

- review all incoming raw captures before final save

List item fields:

- source channel
- capture time
- detected type
- confidence score
- duplicate warning
- linked project guess

Actions:

- `Review`
- `Merge`
- `Create New`
- `Discard`
- `Mark Later`

Design notes:

- sort newest first by default
- highlight low-confidence items visually

## 3. Inbox Review

Purpose:

- correction screen for AI-extracted structured data

Layout:

- raw source text or transcript at top
- extracted cards underneath for Project, Task, and Meeting
- duplicate suggestions beside relevant cards

Actions:

- edit inline
- accept extracted cards
- reject extracted cards
- link to existing project
- save as provisional
- finalize records

Design notes:

- minimize navigation away from raw input
- show confidence indicators per field, not only per record

## 4. Project List

Purpose:

- browse local projects quickly

Filters:

- OEM
- coordinator
- project manager
- open tasks
- recent activity
- archived or active

List item fields:

- project name
- OEM
- location
- coordinator
- open task count
- last activity

## 5. Project Detail

Sections:

- Overview
- Contacts
- Tasks
- Meetings
- Notes
- Attachments
- Export

Overview fields:

- project name
- client OEM
- site location
- site contact name
- site contact phone
- coordinator
- project manager

Actions:

- `Add Task`
- `Link Meeting`
- `Edit Project`
- `Export Project`

Design notes:

- keep project summary visible near the top
- make related tasks and meetings easy to open

## 6. New Project / Edit Project

Fields:

- project name
- client OEM
- site location
- site contact name
- site contact phone
- coordinator name
- project manager name
- notes

Behavior:

- support manual entry
- support autofill from pasted text
- suggest known people and repeated values from local history

## 7. Task List

Purpose:

- browse by schedule and review status

Default tabs:

- Today
- Upcoming
- All
- Provisional

Filters:

- project
- worker
- task type
- status
- coordinator
- source channel

## 8. Task Detail

Sections:

- Core Fields
- Linked Project
- Source Capture
- Notes
- Attachments
- Audit History

Actions:

- `Edit`
- `Mark Complete`
- `Archive`
- `Export`
- `Convert Provisional`

Design notes:

- source traceability should be visible without clutter

## 9. New Task / Edit Task

Fields:

- project
- task type
- task title
- worker name
- worker phone
- coordinator name
- project manager name
- scheduled date
- start time
- duration
- location
- description
- status
- priority

Fast task type chips:

- `site survey`
- `installation`
- `tuning`
- `handover`
- `maintenance`

Design notes:

- date and time entry should be fast
- allow partial save when key data is missing

## 10. Meeting List

Purpose:

- browse meeting records and follow-up actions

List item fields:

- title
- date and time
- linked project count
- extracted task count
- review state

Filters:

- date
- project
- unresolved extracted tasks
- source type

## 11. Meeting Capture

Purpose:

- one-tap audio-first intake

Controls:

- start
- pause
- resume
- stop
- marker
- quick note

Behavior:

- always store audio locally first
- create meeting draft immediately on recording start
- allow manual notes during recording

## 12. Meeting Review

Sections:

- audio player
- transcript
- summary
- minutes table
- extracted tasks
- linked projects
- decisions

Actions:

- correct transcript
- split by project
- create tasks
- reject incorrect tasks
- finalize meeting minutes
- export minutes

Design notes:

- extracted tasks must be editable before save
- project linking must support multiple projects in one meeting

## 13. Search

Purpose:

- global discovery across local records

Search scope:

- projects
- tasks
- meetings
- raw captures
- people

Filters:

- date range
- project name
- OEM
- worker
- coordinator
- project manager
- task type
- source channel
- status

Result presentation:

- grouped by record type
- preview snippets for transcript and notes matches

## 14. Reports

Report types:

- daily task list
- by-project task list
- worker summary
- meeting minutes pack
- project summary
- custom filtered list

Output formats:

- in-app summary
- PDF
- CSV
- JSON

Design notes:

- report filters should be editable before generation
- report output should be reusable for export

## 15. Import

Flow:

- pick bundle
- parse manifest
- preview incoming records
- show duplicate candidates
- choose merge or create
- execute import
- show result summary

Design notes:

- do not write imported data before preview and confirmation

## 16. Export

Flow:

- choose scope
- choose formats
- include or exclude attachments
- generate bundle
- preview contents
- share or save locally

Export scope examples:

- selected project
- selected date range
- selected meeting
- filtered task result set

## 17. Settings

Fields:

- agentee name
- default timezone
- preferred date format
- preferred LLM provider and model
- transcription language mode
- export defaults
- data maintenance tools

## 18. Archive

Purpose:

- browse archived records without cluttering active workflows

Filters:

- archived date
- project
- record type

Design notes:

- archived content should stay searchable
- archive should be reversible

## UX Validation Checklist

- pasted task text can become a final task in minimal steps
- meeting recording can proceed without navigating away
- review screens clearly separate raw source from extracted data
- provisional items are easy to identify and resolve
- import/export flows prevent accidental duplication
- global search can surface relevant records quickly