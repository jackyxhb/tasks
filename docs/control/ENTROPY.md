# Entropy

## Purpose

Entropy control prevents the planning repo from accumulating misleading files, stale scripts, and conflicting guidance.

## Current Entropy Risks

- unlinked docs under `docs/`
- legacy root notes regaining active-spec status
- new harness files appearing without audit coverage
- command drift between scripts, CI, and docs

## Current Controls

- `bin/check-gc`
- `scripts/harness/entropy_check.sh`
- `scripts/audit_harness.sh`
- `make ci`

## Future Controls

- stale artifact detection once implementation files exist
- detection for obsolete JSON contracts or mismatched schema versions
- periodic cleanup of draft planning branches and unused examples