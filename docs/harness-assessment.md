# Harness Assessment

## Scope

This assessment applies the harness-engineering lens to the current repo as of 2026-03-09.

## Summary

The repo has useful planning docs, but before this assessment it lacked a working harness. The main failures were not code bugs. They were design-harness failures: wrong source-of-truth assumptions, ambiguous role modeling, and scope drift toward sync and shared-backend behavior.

## Pillar 1: Context Engineering

Status: improved, but still partial.

Passing:

- root [AGENTS.md](/Users/macbook1/work/Asoon/tasks/AGENTS.md) now exists
- failure-ledger entries reference concrete planning failures from 2026-03-09
- available tools and forbidden operations are explicitly listed
- `docs/` is declared as the canonical design source
- legacy root docs are now tombstoned and redirect readers to [docs/app-design-spec.md](/Users/macbook1/work/Asoon/tasks/docs/app-design-spec.md)

Gaps:

- no semantic validation beyond the current design invariants

Score:

- 5/5

## Pillar 2: Architectural Constraints

Status: minimal initial enforcement only.

Passing:

- binary pass/fail doc checks exist in [bin/check-docs](/Users/macbook1/work/Asoon/tasks/bin/check-docs)
- binary pass/fail design-invariant checks exist in [bin/check-constraints](/Users/macbook1/work/Asoon/tasks/bin/check-constraints)
- binary pass/fail garbage-collection checks exist in [bin/check-gc](/Users/macbook1/work/Asoon/tasks/bin/check-gc)
- binary pass/fail harness check exists in [bin/check-harness](/Users/macbook1/work/Asoon/tasks/bin/check-harness)

Gaps:

- implementation-boundary checks are still missing for the current app code

Score:

- 4/5

## Pillar 3: Garbage Collection

Status: weak.

Passing:

- harness gaps are now explicitly documented
- stale focused docs not linked from [docs/app-design-spec.md](/Users/macbook1/work/Asoon/tasks/docs/app-design-spec.md) are now detected automatically
- legacy root docs losing their tombstone markers are now detected automatically

Gaps:

- no scheduled cleanup workflow
- no repo-specific GC scripts for dead docs, stale exports, or unused planning artifacts

Score:

- 3/5

## Current Failure Ledger Themes

The harness is currently focused on preventing these already-observed failures:

- treating legacy archive docs as app requirements
- confusing record fields with app permission roles
- drifting from local-only architecture into sync architecture
- flattening meetings directly into tasks
- over-trusting AI extraction output
- lacking a canonical import/export exchange format

## Immediate Recommendations

1. Add implementation-aware structural checks once app code exists, especially for local-only storage, import/export format, and meeting-to-task review boundaries.
2. Expand implementation-aware checks later beyond compile-and-test coverage into more structural assertions over the mobile codebase.
	Current state: repo-local Flutter analyze and focused Flutter test wrappers now run from the canonical validation path, and they call `bin/check-mobile-toolchain` before Flutter commands.
3. Expand GC checks later to include stale exports, unused example artifacts, and obsolete planning branches.
4. Replace the legacy root tombstones with full deletion once no external references remain.

## Fast Checks

Run:

```sh
bin/check-docs
bin/check-constraints
bin/check-gc
bin/check-harness
```

Expected result:

- required docs exist
- app design spec links to focused docs
- AGENTS.md carries the current critical harness rules