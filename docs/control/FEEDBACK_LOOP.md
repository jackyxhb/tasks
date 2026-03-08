# Feedback Loop

## Purpose

Define how real agent failures feed back into the harness.

## Loop

1. Agent run fails or drifts.
2. Identify whether the failure came from missing context, missing constraint, or stale artifact.
3. Update [AGENTS.md](../../AGENTS.md), docs, or checks.
4. Re-run `make ci` and `python3 scripts/harness_wizard.py audit .`.
5. Keep the repair if the failure is now machine-visible.

## Rule

Do not stop at describing the failure. Convert it into a repo artifact or deterministic check.