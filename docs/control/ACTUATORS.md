# Actuators

## Purpose

Actuators are the repo mechanisms that actually change system behavior.

## Current Actuators

- failure-ledger rules in [AGENTS.md](../../AGENTS.md)
- fast checks in `bin/`
- harness wrappers in `scripts/harness/`
- canonical docs under `docs/`
- CI workflow in [.github/workflows/harness.yml](../../.github/workflows/harness.yml)

## Expected Use

- prefer changing repo artifacts over relying on memory or ad-hoc verbal guidance
- keep command entrypoints stable while changing enforcement internals as needed