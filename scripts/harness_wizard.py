#!/usr/bin/env python3
from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path


BASELINE_FILES = (
    "AGENTS.md",
    "PLANS.md",
    "docs/ARCHITECTURE.md",
    "docs/OBSERVABILITY.md",
    "docs/agent-task-contract.md",
    "Makefile.harness",
    "bin/check-task-contract",
    "scripts/audit_harness.sh",
    "scripts/harness/smoke.sh",
    "scripts/harness/test.sh",
    "scripts/harness/lint.sh",
    "scripts/harness/typecheck.sh",
    "scripts/harness/entropy_check.sh",
    "scripts/bootstrap_harness.sh",
    "scripts/harness_wizard.py",
    "scripts/validate_task_contract.py",
    "schemas/agent-task-contract.schema.json",
    "examples/agent-task-contract.json",
    ".github/workflows/harness.yml",
    ".github/workflows/nightly-harness-audit.yml",
)

PRIMITIVE_FILES = {
    "loop": ("docs/control/CONTROL_SYSTEM.md",),
    "setpoint": ("docs/control/SETPOINTS.md", "evals/control-loop-metrics.yaml"),
    "sensors": ("docs/control/SENSORS.md",),
    "controller": ("docs/control/CONTROLLER.md",),
    "actuators": ("docs/control/ACTUATORS.md",),
    "feedback": ("docs/control/FEEDBACK_LOOP.md",),
    "stability": ("docs/control/STABILITY.md",),
    "entropy": (
        "docs/control/ENTROPY.md",
        "scripts/harness/entropy_check.sh",
        ".github/workflows/nightly-harness-audit.yml",
    ),
}

CONTROL_PROFILE = ("loop", "setpoint", "sensors", "controller", "actuators", "feedback", "stability")
FULL_PROFILE = CONTROL_PROFILE + ("entropy",)


def resolve_repo(repo_arg: str) -> Path:
    repo = Path(repo_arg).expanduser().resolve()
    if not repo.exists() or not repo.is_dir():
        print(f"error: repo path does not exist: {repo}", file=sys.stderr)
        raise SystemExit(2)
    return repo


def run_audit(repo: Path) -> int:
    script = repo / "scripts" / "audit_harness.sh"
    if not script.exists():
      print(f"error: missing audit script: {script}", file=sys.stderr)
      return 2
    return subprocess.run([str(script), str(repo)], check=False).returncode


def show_status(repo: Path) -> int:
    present = 0
    total = len(BASELINE_FILES)
    print(f"Harness status for {repo}")
    print()
    for rel in BASELINE_FILES:
        exists = (repo / rel).exists()
        present += 1 if exists else 0
        mark = "OK " if exists else "MISS"
        print(f"  [{mark}] {rel}")
    print()
    print(f"baseline: {present}/{total}")
    print()
    print("control primitives:")
    for primitive, files in PRIMITIVE_FILES.items():
        primitive_present = sum(1 for rel in files if (repo / rel).exists())
        primitive_total = len(files)
        mark = "OK " if primitive_present == primitive_total else "PARTIAL" if primitive_present > 0 else "MISS"
        print(f"  [{mark}] {primitive}: {primitive_present}/{primitive_total}")
    return 0 if present == total else 1


def cmd_init(repo: Path, profile: str, force: bool) -> int:
    script = repo / "scripts" / "bootstrap_harness.sh"
    if script.exists():
        subprocess.run([str(script), str(repo)], check=False)
    selected = CONTROL_PROFILE if profile == "control" else FULL_PROFILE if profile == "full" else ()
    if selected:
        print(f"Profile '{profile}' expects primitives: {', '.join(selected)}")
        if not force:
            print("Artifacts already exist in this repo; use --force only if you intend to replace managed files.")
    else:
        print(f"Baseline profile selected for {repo}")
    return 0


def primitive_list() -> int:
    for primitive, files in PRIMITIVE_FILES.items():
        print(primitive)
        for rel in files:
            print(f"  - {rel}")
    return 0


def primitive_add(repo: Path, primitives: list[str], force: bool) -> int:
    for primitive in primitives:
        if primitive not in PRIMITIVE_FILES:
            print(f"error: unknown primitive: {primitive}", file=sys.stderr)
            return 2
        print(f"[{primitive}]")
        for rel in PRIMITIVE_FILES[primitive]:
            target = repo / rel
            if target.exists() and not force:
                print(f"  [skip ] {rel}")
            else:
                print(f"  [write] {rel}")
    print("Primitive update complete.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Harness engineering wizard for this repository.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    init_parser = subparsers.add_parser("init", help="Validate or initialize harness artifacts.")
    init_parser.add_argument("repo_path")
    init_parser.add_argument("--profile", default="control")
    init_parser.add_argument("--force", action="store_true")

    status_parser = subparsers.add_parser("status", help="Show harness coverage status.")
    status_parser.add_argument("repo_path")

    audit_parser = subparsers.add_parser("audit", help="Run the harness audit.")
    audit_parser.add_argument("repo_path")

    primitive_parser = subparsers.add_parser("primitive", help="Inspect or add control primitives.")
    primitive_sub = primitive_parser.add_subparsers(dest="primitive_command", required=True)

    primitive_list_parser = primitive_sub.add_parser("list", help="List control primitives.")

    primitive_add_parser = primitive_sub.add_parser("add", help="Show control primitives to add.")
    primitive_add_parser.add_argument("primitives", nargs="+")
    primitive_add_parser.add_argument("--repo", required=True)
    primitive_add_parser.add_argument("--force", action="store_true")

    args = parser.parse_args()

    if args.command == "primitive":
        if args.primitive_command == "list":
            return primitive_list()
        if args.primitive_command == "add":
            repo = resolve_repo(args.repo)
            return primitive_add(repo, args.primitives, args.force)

    repo = resolve_repo(args.repo_path)

    if args.command == "init":
        return cmd_init(repo, args.profile, args.force)
    if args.command == "status":
        return show_status(repo)
    if args.command == "audit":
        return run_audit(repo)

    return 2


if __name__ == "__main__":
    raise SystemExit(main())