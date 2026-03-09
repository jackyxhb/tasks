#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path


def fail(message: str) -> int:
    print(f"ERROR: {message}", file=sys.stderr)
    return 1


def require_non_empty_string(data: dict, key: str) -> str:
    value = data.get(key)
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"'{key}' must be a non-empty string")
    return value


def require_string_list(data: dict, key: str, minimum: int = 1) -> list[str]:
    value = data.get(key)
    if not isinstance(value, list) or len(value) < minimum:
        raise ValueError(f"'{key}' must be a list with at least {minimum} item(s)")
    if any(not isinstance(item, str) or not item.strip() for item in value):
        raise ValueError(f"'{key}' must contain only non-empty strings")
    return value


def validate_contract(path: Path) -> None:
    try:
      contract = json.loads(path.read_text())
    except FileNotFoundError as exc:
      raise ValueError(f"missing contract file: {path}") from exc
    except json.JSONDecodeError as exc:
      raise ValueError(f"invalid JSON in {path}: {exc}") from exc

    if not isinstance(contract, dict):
        raise ValueError("top-level contract value must be an object")

    allowed_top_level = {
        "task_id",
        "objective",
        "workspace_root",
        "mode",
        "scope",
        "environment_prerequisites",
        "preflight_commands",
        "required_commands",
        "success_criteria",
        "stop_conditions",
        "approval_gates",
        "deliverables",
        "notes",
    }
    unknown = sorted(set(contract) - allowed_top_level)
    if unknown:
        raise ValueError(f"unknown top-level key(s): {', '.join(unknown)}")

    require_non_empty_string(contract, "task_id")
    require_non_empty_string(contract, "objective")
    require_non_empty_string(contract, "workspace_root")
    mode = require_non_empty_string(contract, "mode")
    if mode not in {"autonomous", "interactive"}:
        raise ValueError("'mode' must be 'autonomous' or 'interactive'")

    scope = contract.get("scope")
    if not isinstance(scope, dict):
        raise ValueError("'scope' must be an object")
    scope_unknown = sorted(set(scope) - {"allowed_paths", "forbidden_paths", "max_files_to_edit"})
    if scope_unknown:
        raise ValueError(f"unknown scope key(s): {', '.join(scope_unknown)}")

    allowed_paths = require_string_list(scope, "allowed_paths")
    forbidden_paths = scope.get("forbidden_paths", [])
    if not isinstance(forbidden_paths, list):
        raise ValueError("'scope.forbidden_paths' must be a list")
    if any(not isinstance(item, str) or not item.strip() for item in forbidden_paths):
        raise ValueError("'scope.forbidden_paths' must contain only non-empty strings")

    max_files_to_edit = scope.get("max_files_to_edit")
    if not isinstance(max_files_to_edit, int) or max_files_to_edit < 1:
        raise ValueError("'scope.max_files_to_edit' must be an integer >= 1")

    overlap = sorted(set(allowed_paths) & set(forbidden_paths))
    if overlap:
        raise ValueError(f"allowed and forbidden paths overlap: {', '.join(overlap)}")

    if "environment_prerequisites" in contract:
        require_string_list(contract, "environment_prerequisites", minimum=0)
    if "preflight_commands" in contract:
        require_string_list(contract, "preflight_commands", minimum=0)

    require_string_list(contract, "required_commands")
    require_string_list(contract, "success_criteria")
    require_string_list(contract, "stop_conditions")
    require_string_list(contract, "approval_gates")

    optional_lists = ("deliverables", "notes")
    for key in optional_lists:
        if key in contract:
            require_string_list(contract, key, minimum=0)


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: python3 scripts/validate_task_contract.py <contract.json>", file=sys.stderr)
        return 2

    path = Path(sys.argv[1])
    try:
        validate_contract(path)
    except ValueError as exc:
        return fail(str(exc))

    print(f"OK: task contract is valid: {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())