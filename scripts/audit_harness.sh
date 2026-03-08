#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/audit_harness.sh [repo_path]

Audit this repository for baseline harness engineering artifacts.
EOF
}

target_path="${1:-.}"
if [[ "$target_path" == "-h" || "$target_path" == "--help" ]]; then
  usage
  exit 0
fi

if [[ ! -d "$target_path" ]]; then
  echo "error: target path does not exist: $target_path" >&2
  exit 1
fi

target_path=$(cd "$target_path" && pwd)
failures=0

ok() {
  echo "[ok]      $1"
}

fail() {
  echo "[missing] $1"
  failures=$((failures + 1))
}

check_file() {
  local relative="$1"
  if [[ -f "$target_path/$relative" ]]; then
    ok "$relative"
  else
    fail "$relative"
  fi
}

check_contains() {
  local relative="$1"
  local pattern="$2"
  local label="$3"
  local full="$target_path/$relative"

  if [[ ! -f "$full" ]]; then
    fail "$label (file missing: $relative)"
    return
  fi

  if grep -Eq "$pattern" "$full"; then
    ok "$label"
  else
    fail "$label"
  fi
}

echo "Auditing harness artifacts in: $target_path"
echo

check_file "AGENTS.md"
check_file "PLANS.md"
check_file "docs/ARCHITECTURE.md"
check_file "docs/OBSERVABILITY.md"
check_file "Makefile.harness"
check_file "scripts/audit_harness.sh"
check_file "scripts/harness/smoke.sh"
check_file "scripts/harness/test.sh"
check_file "scripts/harness/lint.sh"
check_file "scripts/harness/typecheck.sh"
check_file "scripts/harness/entropy_check.sh"
check_file "scripts/harness_wizard.py"
check_file "scripts/bootstrap_harness.sh"
check_file "scripts/validate_bundle.py"
check_file "scripts/validate_task_contract.py"
check_file ".github/workflows/harness.yml"
check_file ".github/workflows/nightly-harness-audit.yml"
check_file "docs/implementation-constraints.md"
check_file "docs/agent-task-contract.md"
check_file "docs/control/CONTROL_SYSTEM.md"
check_file "docs/control/SETPOINTS.md"
check_file "docs/control/SENSORS.md"
check_file "docs/control/CONTROLLER.md"
check_file "docs/control/ACTUATORS.md"
check_file "docs/control/FEEDBACK_LOOP.md"
check_file "docs/control/STABILITY.md"
check_file "docs/control/ENTROPY.md"
check_file "evals/control-loop-metrics.yaml"
check_file "schemas/agent-task-contract.schema.json"
check_file "schemas/import-export-bundle.schema.json"
check_file "examples/agent-task-contract.json"
check_file "examples/import-export/sample-bundle.json"
check_file "bin/check-task-contract"

echo
check_contains "AGENTS.md" "Harness Commands" "AGENTS.md: Harness Commands section"
check_contains "AGENTS.md" "Execution Plans" "AGENTS.md: Execution Plans section"
check_contains "AGENTS.md" "machine-readable task contract" "AGENTS.md: autonomous task contract rule"
check_contains "docs/ARCHITECTURE.md" "Boundaries" "ARCHITECTURE.md: boundary guidance"
check_contains "docs/OBSERVABILITY.md" "Required Event Fields" "OBSERVABILITY.md: required fields"
check_contains "docs/agent-task-contract.md" "Required Fields" "agent-task-contract.md: required fields guidance"
check_contains "Makefile.harness" "^smoke:" "Makefile.harness: smoke target"
check_contains "Makefile.harness" "^test:" "Makefile.harness: test target"
check_contains "Makefile.harness" "^lint:" "Makefile.harness: lint target"
check_contains "Makefile.harness" "^typecheck:" "Makefile.harness: typecheck target"
check_contains "Makefile.harness" "^task-contract:" "Makefile.harness: task-contract target"
check_contains "Makefile.harness" "^audit:" "Makefile.harness: audit target"
check_contains "Makefile.harness" "^ci:" "Makefile.harness: ci target"
check_contains ".github/workflows/harness.yml" "make ci" "CI workflow executes make ci"
check_contains ".github/workflows/nightly-harness-audit.yml" "entropy_check.sh" "Nightly workflow executes entropy check"
check_contains "docs/implementation-constraints.md" "Constraint 1: Local-Only Storage" "implementation-constraints.md: local-only constraint"
check_contains "docs/control/CONTROL_SYSTEM.md" "Control Loop" "CONTROL_SYSTEM.md: control loop guidance"
check_contains "docs/control/SETPOINTS.md" "Setpoints" "SETPOINTS.md: setpoint guidance"
check_contains "docs/control/SENSORS.md" "Current Sensors" "SENSORS.md: sensor guidance"
check_contains "docs/control/ENTROPY.md" "Current Controls" "ENTROPY.md: entropy guidance"

echo
if [[ "$failures" -gt 0 ]]; then
  echo "Harness audit failed: $failures issue(s) detected."
  exit 1
fi

echo "Harness audit passed."