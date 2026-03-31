# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Pre-commit hooks (`.pre-commit-config.yaml`, `.git-hooks/pre-commit`)
- CI permissions scoping (`.github/workflows/*.yml`)
- Weekly cleanup workflow (`.github/workflows/weekly-cleanup.yml`)
- Context management guidance to AGENTS.md
- Tool offloading and summarization stubs
- Exit hooks (`bin/on-exit-hook.sh`), resume script (`bin/resume.sh`)
- Notification script (`bin/notify.sh`)
- MCP configuration stub (`.mcp.json`)
- Claude context anchors (`.claude/DECISIONS.md`, `.claude/ARCHITECTURE.md`, `.claude/ACTIVE_TASKS.md`)
- ADR directory (`docs/adr/`)
- CI status tracking (`scripts/.ci_status.json`)
- Doc freshness warnings in checks
- Stale task contract detection (`bin/check-stale-contracts`)
- Dart import graph + circular dependency detection (`bin/check-dart-imports`)
- Session startup script for PLANS.md injection (`bin/session-startup.sh`)
- Prompt reinjection for long tasks (`bin/reinject-context.sh`)
- Performance tracking (`bin/check-perf`)
- Metrics auto-collection (`bin/check-metrics`)
- Python linting with ruff config (`pyproject.toml`, `bin/check-python-lint`)
- Changelog check (`bin/check-changelog`)
- Pub outdated check (`bin/check-pub-outdated`)
- Machine-readable pattern registry (`schemas/pattern-registry.json`)
- ADR-002: Multi-Agent Orchestration decision (rejected for v1)

### Changed
- `bin/check-gc` now warns on stale docs vs code
- `bin/check-docs` now warns on stale docs vs code  
- `scripts/harness/mobile_test.sh` now has timeout guards
- Pre-commit hooks now include stale contracts, import graph, Python lint, changelog checks
- Makefile.harness now includes `harness-extensions`, `perf`, and `metrics` targets

### Fixed
- Legacy doc (ARCHIVE_FORMAT.md, WORK_HOURS_RECORD_FORMAT.md) properly handled
- Removed empty `.agent/` and `.agents/` directories

---

## [0.1.0] - 2026-03-09

### Added
- Initial harness setup with AGENTS.md, PLANS.md
- Core constraint checks (`bin/check-*`)
- Makefile.harness targets
- GitHub Actions CI workflows
- Control system docs
- Observability design
- Task contract schema
- Import/export bundle schema