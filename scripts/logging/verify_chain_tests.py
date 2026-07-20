#!/usr/bin/env python3
"""Verify JSONL from --production-chain-test or --milestone-chain-test harness runs."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def load_events(path: Path) -> list[dict]:
    events: list[dict] = []
    with path.open(encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                events.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    return events


def verify_production(events: list[dict]) -> list[str]:
    errors: list[str] = []
    if not any(e.get("evt") == "production_chain_test_pass" for e in events):
        errors.append("missing production_chain_test_pass event")
    bread_done = [
        e
        for e in events
        if e.get("evt") == "work_request_completed" and e.get("chain_id") == "bread"
    ]
    leather_done = [
        e
        for e in events
        if e.get("evt") == "work_request_completed" and e.get("chain_id") == "leather"
    ]
    if not bread_done:
        errors.append("no work_request_completed for chain_id=bread")
    if not leather_done:
        errors.append("no work_request_completed for chain_id=leather")
    expired = [e for e in events if e.get("evt") == "work_request_expired"]
    if expired:
        errors.append(f"work_request_expired count={len(expired)}")
    return errors


def verify_milestone(events: list[dict]) -> list[str]:
    errors: list[str] = []
    if not any(e.get("evt") == "milestone_chain_test_pass" for e in events):
        errors.append("missing milestone_chain_test_pass event")
    completed = [e for e in events if e.get("evt") == "build_milestone_completed"]
    if len(completed) < 2:
        errors.append(f"build_milestone_completed count={len(completed)} (need >=2 oven+rack)")
    aborted = [e for e in events if e.get("evt") == "build_milestone_aborted"]
    if aborted:
        reasons = [str(e.get("reason", "?")) for e in aborted[:5]]
        errors.append(f"build_milestone_aborted count={len(aborted)} reasons={reasons}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("jsonl", type=Path)
    parser.add_argument(
        "--expect",
        choices=("production", "milestone"),
        required=True,
    )
    args = parser.parse_args()
    if not args.jsonl.is_file():
        print(f"verify_chain_tests: file not found {args.jsonl}", file=sys.stderr)
        return 1
    events = load_events(args.jsonl)
    if args.expect == "production":
        errors = verify_production(events)
        label = "PRODUCTION_CHAIN"
    else:
        errors = verify_milestone(events)
        label = "MILESTONE_CHAIN"
    if errors:
        print(f"{label} JSONL verify FAIL:")
        for err in errors:
            print(f"  - {err}")
        return 1
    print(f"{label} JSONL verify OK ({len(events)} events)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
