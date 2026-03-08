# Stability

## Purpose

Stability in this repo means agent runs reach the same conclusions from the same docs and command surface.

## Stability Risks

- multiple sources of truth
- interactive-only workflows
- hidden manual steps
- advisory warnings instead of binary checks
- stale planning artifacts

## Stability Rules

- keep canonical docs compact and linked
- keep validation commands deterministic
- keep smoke and check workflows cheap enough for repeated runs
- promote repeated failures into enforced constraints