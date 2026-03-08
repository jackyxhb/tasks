# Sensors

## Purpose

Sensors are the checks and observations that detect repo drift.

## Current Sensors

- `bin/check-docs` detects missing required docs and missing canonical links
- `bin/check-constraints` detects missing design invariants
- `bin/check-gc` detects stale doc linkage and lost tombstone markers
- `bin/check-local-only-code` detects future code patterns that would violate local-only v1 assumptions
- `bin/check-meeting-review-gate` detects missing review-gate signals or suspicious direct meeting-to-task finalization patterns
- `bin/check-bundle-schema` validates the canonical import/export schema and sample bundle
- `bin/check-harness` runs the repo harness bundle
- `scripts/audit_harness.sh` detects missing playbook baseline artifacts
- `scripts/harness/entropy_check.sh` detects stale placeholders and harness drift

## Future Sensors

- implementation-boundary checks for local-only storage
- import/export schema validation checks
- meeting-to-task promotion checks against implementation code