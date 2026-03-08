# Setpoints

## Purpose

Setpoints define the operational targets for the repo harness.

## Repo Setpoints

- `canonical_docs_integrity`: all focused docs remain linked from [app-design-spec.md](../app-design-spec.md)
- `local_only_scope_integrity`: version 1 docs and future code do not introduce sync or shared backend assumptions
- `meeting_task_boundary_integrity`: meeting records and task records remain separate
- `ai_review_gate_integrity`: AI extraction remains candidate-based and review-gated
- `harness_command_integrity`: `make smoke`, `make check`, `make ci`, and `python3 scripts/harness_wizard.py audit .` stay valid

## Alert Conditions

- a focused doc is added without canonical linkage
- a design doc reintroduces sync or app-level role assumptions
- a harness script stops passing in local validation
- legacy tombstone docs lose their warning markers