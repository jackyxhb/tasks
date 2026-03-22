# PLANS.md

Use this file for multi-step work where durable context matters.

## Objective

- Outcome: Build a local-first personal field work agent app for elevator service project records, tasks, meetings, search, reporting, and import/export.
- Why it matters: The repo needs durable planning context so agent runs do not drift into the wrong product scope.
- Non-goals: Shared backend, sync, cross-device collaboration, multi-user permissions in version 1.

## Constraints

- Runtime/tooling constraints: This repo now contains planning artifacts, harness checks, and an in-progress mobile app under `mobile/field_work_agent/`. Deterministic repo-local checks remain preferred, and Flutter-dependent work should declare SDK/toolchain preflight explicitly.
- Security/compliance constraints: All app data in v1 is local-only; internet use is limited to optional LLM transcription or extraction.
- Performance/reliability constraints: Harness checks should stay fast enough for agent feedback loops.

## Context Snapshot

- Relevant files/modules: `AGENTS.md`, `docs/app-design-spec.md`, linked docs under `docs/`, `bin/check-*`, `scripts/harness/*`, `mobile/field_work_agent/`
- Existing commands/workflows: `make smoke`, `make check`, `make ci`, `python3 scripts/harness_wizard.py audit .`
- Known risks: legacy root docs competing with canonical docs, role-model drift, sync assumptions, meeting/task boundary regressions, AI over-automation.
- Implemented app slices as of 2026-03-09: T1-T12 application-layer foundations including local database bootstrap, local file storage, audit logging, project/task CRUD flows, people normalization, raw capture intake/classification, dedup candidates, meeting recording flow, and transcript storage plus provider abstraction.
- Immediate continuation target: keep implementation and harness metadata aligned as the mobile app grows.

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
- [x] Foundation slices T1-T12 implemented at application-layer scope
- [ ] Meeting extraction/review slices T13-T16 implemented
- [x] Harness audit completed (2026-03-23)
- [x] Tier 1 improvements deployed
- [ ] Tier 2 improvements deployed
- [ ] Tier 3 improvements deployed

## Decision Log

- Date: 2026-03-09
  - Decision: Treat `docs/` as canonical and root archive/work-hours files as legacy tombstones.
  - Reason: Earlier planning drift came from treating unrelated root notes as app constraints.
  - Alternatives considered: keep multiple design sources active

- Date: 2026-03-09
  - Decision: Use import/export rather than sync for v1 exchange.
  - Reason: The app is personal and local-only in the first version.
  - Alternatives considered: shared backend, live sync, collaboration features

- Date: 2026-03-23
  - Decision: Implement harness audit recommendations (Tier 1-3).
  - Reason: 38 gaps identified across Foundation, P1, P2, P3 areas.
  - Alternatives considered: defer to future iteration

## Final Verification

- Commands run: `make smoke`, `make check`, `make ci`, `python3 scripts/harness_wizard.py audit .`
- Key outputs: harness commands and docs checks pass.
- Follow-up tasks: continue with T13-T14 using the next task contract under `examples/task-contracts/` and keep the no-wait autonomous flow unless a real approval boundary appears.