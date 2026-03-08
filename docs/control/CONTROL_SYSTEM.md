# Control System

## Purpose

This repo uses a control-system framing for harness engineering so repeated agent runs stay inside the intended product and repo boundaries.

## Control Loop

1. Set scope and constraints in [PLANS.md](../../PLANS.md).
2. Constrain execution with [AGENTS.md](../../AGENTS.md) and repo-local commands.
3. Detect drift with `bin/check-*`, `scripts/audit_harness.sh`, and `scripts/harness/entropy_check.sh`.
4. Repair the harness when an agent makes a repeatable mistake.

## Controlled Variables

- Canonical design source remains `docs/`
- Version 1 stays local-only
- Meetings remain separate from tasks
- AI extraction stays review-gated
- Import/export remains the exchange mechanism

## Disturbances

- legacy root docs competing with canonical docs
- planning drift toward sync/shared backend
- role confusion between record fields and app permissions
- overconfident AI extraction assumptions
- stale or unlinked docs

## Control Actions

- tighten failure-ledger entries in [AGENTS.md](../../AGENTS.md)
- add or update repo-local checks under `bin/` and `scripts/harness/`
- update canonical docs under `docs/`
- remove or tombstone stale artifacts