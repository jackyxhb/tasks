#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path


REQUIRED_TOP_LEVEL = {
    "schema_version",
    "bundle_id",
    "exported_at",
    "source_app",
    "scope",
    "records",
    "attachments_manifest",
}

REQUIRED_RECORD_COLLECTIONS = {"projects", "tasks", "meetings", "people"}
ALLOWED_SCOPE_TYPES = {"project", "meeting", "date_range", "task_filter", "full_export"}
ALLOWED_OWNER_TYPES = {"project", "task", "meeting", "raw_capture", "export_bundle"}


def fail(message: str) -> int:
    print(f"ERROR: {message}", file=sys.stderr)
    return 1


def load_json(path: Path):
    try:
        return json.loads(path.read_text())
    except FileNotFoundError:
        raise SystemExit(fail(f"missing file: {path}"))
    except json.JSONDecodeError as exc:
        raise SystemExit(fail(f"invalid JSON in {path}: {exc}"))


def validate_bundle(bundle: dict) -> int:
    missing = REQUIRED_TOP_LEVEL - bundle.keys()
    if missing:
        return fail(f"bundle is missing top-level keys: {sorted(missing)}")

    if not isinstance(bundle["schema_version"], str) or not bundle["schema_version"].startswith("v"):
        return fail("schema_version must be a string like 'v1'")

    if not isinstance(bundle["source_app"], dict):
        return fail("source_app must be an object")
    if not isinstance(bundle["scope"], dict):
        return fail("scope must be an object")
    if bundle["scope"].get("type") not in ALLOWED_SCOPE_TYPES:
        return fail(f"scope.type must be one of {sorted(ALLOWED_SCOPE_TYPES)}")

    records = bundle["records"]
    if not isinstance(records, dict):
        return fail("records must be an object")
    missing_collections = REQUIRED_RECORD_COLLECTIONS - records.keys()
    if missing_collections:
        return fail(f"records is missing collections: {sorted(missing_collections)}")
    for name in REQUIRED_RECORD_COLLECTIONS:
        if not isinstance(records[name], list):
            return fail(f"records.{name} must be an array")

    attachments = bundle["attachments_manifest"]
    if not isinstance(attachments, list):
        return fail("attachments_manifest must be an array")
    for index, item in enumerate(attachments):
        if not isinstance(item, dict):
            return fail(f"attachments_manifest[{index}] must be an object")
        for key in ("attachment_id", "owner_record_type", "owner_record_id", "relative_path", "checksum"):
            if key not in item:
                return fail(f"attachments_manifest[{index}] is missing '{key}'")
        if item["owner_record_type"] not in ALLOWED_OWNER_TYPES:
            return fail(
                f"attachments_manifest[{index}].owner_record_type must be one of {sorted(ALLOWED_OWNER_TYPES)}"
            )

    return 0


def main() -> int:
    if len(sys.argv) != 2:
        return fail("usage: python3 scripts/validate_bundle.py <bundle.json>")

    path = Path(sys.argv[1]).resolve()
    bundle = load_json(path)
    result = validate_bundle(bundle)
    if result == 0:
        print(f"OK: bundle is valid: {path}")
    return result


if __name__ == "__main__":
    raise SystemExit(main())