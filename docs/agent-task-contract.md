# Agent Task Contract

## Purpose

This document defines the machine-readable task contract used to let an agent run substantial work without repeated manual clarification.

The contract is not a product requirement. It is a harness artifact that turns a user request into deterministic scope, validation, and stop conditions.

## Rule

Non-trivial autonomous runs should start from a validated JSON task contract.

The contract should answer these questions up front:

- what outcome is required
- which paths are in scope
- which paths are forbidden
- which environment prerequisites must already exist
- which preflight commands must pass before implementation starts
- which commands must pass before the task is complete
- which situations require the agent to stop and ask for approval

## Required Fields

- `task_id`: stable identifier for the run or work item
- `objective`: one-sentence desired outcome
- `workspace_root`: repo-relative or absolute workspace root
- `mode`: expected execution mode; use `autonomous` for hands-off runs
- `scope.allowed_paths`: files or directories the agent may edit
- `scope.forbidden_paths`: files or directories the agent must not edit
- `scope.max_files_to_edit`: hard ceiling for broad edits without explicit scope change
- `required_commands`: deterministic verification commands the agent must run
- `success_criteria`: concrete completion conditions
- `stop_conditions`: situations that force escalation instead of guessing
- `approval_gates`: actions that still require user approval

## Recommended Fields

- `environment_prerequisites`: required tools, SDKs, services, or local state that must exist before work can proceed normally
- `preflight_commands`: deterministic commands that confirm the environment is ready for the task before broader edits begin
- `deliverables`: expected outputs for the run
- `notes`: short durable context that should survive across retries

## Usage

Validate a contract directly:

```sh
python3 scripts/validate_task_contract.py examples/agent-task-contract.json
```

Validate through the stable harness entrypoint:

```sh
make task-contract CONTRACT=examples/agent-task-contract.json
```

Use the contract before the agent begins broad edits, especially when:

- the task spans multiple files
- the task has explicit non-goals
- the task must remain inside strict boundaries
- the task has approval edges such as deletion, publishing, or scope expansion

## Design Guidance

- Keep contracts short and binary.
- Prefer explicit preflight commands over assuming toolchains are installed.
- Prefer explicit commands over prose such as "run normal checks".
- Prefer explicit paths over vague scope like "backend files".
- Put human judgment only in `approval_gates` and `stop_conditions`.
- If a repeated failure pattern appears, add or tighten a contract field instead of relying on memory.

## Environment Guidance

Use `environment_prerequisites` and `preflight_commands` whenever the task depends on external tooling.

Examples:

- Flutter UI work should declare the Flutter SDK as a prerequisite.
- Flutter UI or platform-runner setup should prefer the stable repo-local command `./bin/check-mobile-toolchain`.
- Platform-runner setup may still include checks such as `flutter --version` and `flutter doctor -v` when more detail is needed.
- Runtime-specific work should declare the relevant SDK or package manager when the task cannot proceed meaningfully without it.

If a required tool is unavailable and the contract did not declare it, treat that as a harness gap and tighten the contract pattern rather than silently assuming the environment.

## Schema

Canonical schema artifact:

- [../schemas/agent-task-contract.schema.json](../schemas/agent-task-contract.schema.json)

Example contract:

- [../examples/agent-task-contract.json](../examples/agent-task-contract.json)