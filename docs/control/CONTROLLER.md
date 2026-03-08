# Controller

## Purpose

The controller is the set of repo rules and repair actions that respond to detected drift.

## Controller Inputs

- failed harness checks
- doc drift
- repeated agent planning mistakes
- audit failures

## Controller Outputs

- updated [AGENTS.md](../../AGENTS.md)
- new or tightened checks
- updated canonical docs
- removal or tombstoning of stale artifacts

## Control Policy

- if the failure is undocumented, add it to the failure ledger
- if the failure is documented but unchecked, add a deterministic check
- if the check fails without clear remediation, improve the check message