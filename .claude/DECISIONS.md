# Key Architectural Decisions

## Local-Only Storage (2026-03-09)
- **Decision:** All data must remain local. SQLite + local file storage as the only source of truth.
- **Rationale:** Personal field work agent; no sync or multi-user infrastructure in v1.
- **Sharing:** Import/export JSON bundles only.

## Meeting/Task Separation (2026-03-09)
- **Decision:** Meeting is a separate entity from Task. Meetings can emit task candidates, project links, and decisions — all reviewable.
- **Rationale:** Multi-project discussions would be lost or duplicated if flattened into tasks.

## AI Extraction Review Gate (2026-03-09)
- **Decision:** AI extraction output creates reviewable candidates, never auto-final records.
- **Rationale:** Mixed-language audio and repeated action items make silent automation unsafe.

## Import/Export Over Sync (2026-03-09)
- **Decision:** Sharing between installs happens through versioned JSON bundles, not live sync.
- **Rationale:** Users exchange information between separate local installs.

## App Shell Boundaries (2026-03-10)
- **Decision:** Shell code lives in `mobile/field_work_agent/lib/app/`. Feature code goes in feature folders. Runtime validation in `integration_test/`.
- **Rationale:** Structural ownership and validation surface must stay explicit.
