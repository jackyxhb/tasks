# ADR 001: Local-Only Storage

**Status:** Accepted | **Date:** 2026-03-09

## Context
Users need a personal field work agent that stores all data locally. The agent does not need to sync across devices or support multi-user collaboration in v1.

## Decision
All data must remain local. Use SQLite + local file storage as the only source of truth.

## Sharing Mechanism
Import/export versioned JSON bundles instead of live sync.

## Consequences
- No network backend required for v1
- Exchange between installs happens via file transfer
- Conflict-resolution complexity deferred to future versions