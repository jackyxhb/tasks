# Architecture Overview

## Stack
- **Mobile:** Flutter (iOS + macOS target) under `mobile/field_work_agent/`
- **Harness:** Shell/Python scripts under `bin/`, `scripts/harness/`
- **Docs:** Planning docs under `docs/`, canonical source: `docs/app-design-spec.md`

## Data Model
- **Project:** worker, coordinator, project_manager are data fields, not roles
- **Task:** Separate from Meeting; assigned to a project
- **Meeting:** Separate from Task; emits task candidates, decisions, project links

## Storage
- SQLite + local files; no sync backend
- Exchange via versioned JSON bundles (`schemas/`)

## Harness Layers
1. **Constraint checks** (`bin/check-*`): fast-fail validators
2. **Make targets** (`make ci`, `make check`, etc.): entrypoints
3. **GitHub Actions** (`.github/workflows/`): CI + scheduled audits
4. **Execution plans** (`PLANS.md`): durable multi-step context
