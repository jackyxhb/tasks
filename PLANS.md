# PLANS.md

Use this file for multi-step work where durable context matters.

## Objective

- Outcome: Build a local-first personal field work agent app for elevator service project records, tasks, meetings, search, reporting, and import/export.
- Why it matters: The repo needs durable planning context so agent runs do not drift into the wrong product scope.
- Non-goals: Shared backend, sync, cross-device collaboration, multi-user permissions in version 1.

## Constraints

- Runtime/tooling constraints: This repo currently contains planning and harness artifacts only. Prefer shell, Markdown, and deterministic repo-local checks.
- Security/compliance constraints: All app data in v1 is local-only; internet use is limited to optional LLM transcription or extraction.
- Performance/reliability constraints: Harness checks should stay fast enough for agent feedback loops.

## Context Snapshot

- Relevant files/modules: `AGENTS.md`, `docs/app-design-spec.md`, linked docs under `docs/`, `bin/check-*`, `scripts/harness/*`
- Existing commands/workflows: `make smoke`, `make check`, `make ci`, `python3 scripts/harness_wizard.py audit .`
- Known risks: legacy root docs competing with canonical docs, role-model drift, sync assumptions, meeting/task boundary regressions, AI over-automation.

## Execution Plan

1. Step: Keep the app design and harness docs aligned.
   - Expected output: canonical docs remain linked and validated.
   - Verification: `bin/check-docs`, `bin/check-constraints`
2. Step: Add implementation-aware checks when code exists.
   - Expected output: local-only, meeting review, and import/export invariants become structural checks.
   - Verification: repo-local scripts and harness audit pass.
3. Step: Remove stale planning artifacts when replaced.
   - Expected output: legacy notes no longer compete with canonical docs.
   - Verification: `bin/check-gc`, `bin/check-harness`

## Checkpoints

- [x] Baseline captured
- [ ] Implementation complete
- [x] Static checks passed
- [ ] Tests passed
- [x] Docs updated

## Decision Log

- Date: 2026-03-09
  - Decision: Treat `docs/` as canonical and root archive/work-hours files as legacy tombstones.
  - Reason: Earlier planning drift came from treating unrelated root notes as app constraints.
  - Alternatives considered: keep multiple design sources active

- Date: 2026-03-09
  - Decision: Use import/export rather than sync for v1 exchange.
  - Reason: The app is personal and local-only in the first version.
  - Alternatives considered: shared backend, live sync, collaboration features

## Final Verification

- Commands run: `make smoke`, `make check`, `make ci`, `python3 scripts/harness_wizard.py audit .`
- Key outputs: harness commands and docs checks pass.
- Follow-up tasks: add implementation-aware structural checks once app code exists.