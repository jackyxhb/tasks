# ADR-002: Multi-Agent Orchestration

**Status:** Rejected for v1  
**Date:** 2026-04-01  
**Deciders:** jackyxhb

## Context

The HE-CLUES re-audit (2026-04-01) flagged CLUE-F5-001: `.agent/` and `.agents/` directories existed but were empty, indicating no multi-agent coordination infrastructure.

The original intent of these directories was to support potential future multi-agent orchestration (MAS) — e.g., supervisor/subordinate patterns, agent handoffs, or shared state coordination.

For v1, the app is a single-agent personal field work harness with local-only storage.

## Decision

Remove the empty `.agent/` and `.agents/` directories. Do not implement multi-agent orchestration in v1.

## Rationale

1. **Scope clarity:** v1 is a single-user, single-agent local app. The failure ledger already enforces this via rule: "Version 1 is local-only; do not introduce sync, shared backend, or cross-device collaboration."

2. **Complexity vs value:** MAS infrastructure (coordination protocols, shared state, handoff contracts, deadlock prevention) adds substantial complexity with no clear v1 use case.

3. **Future option preserved:** This decision does not preclude future MAS. If multi-agent workflows become necessary, the ADR process will evaluate it based on actual need.

## Consequences

- Removed: `.agent/`, `.agents/` (empty directories)
- Future multi-agent work requires a new ADR and explicit scope change approval.
