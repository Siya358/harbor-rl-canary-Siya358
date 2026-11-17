#!/bin/bash
set -eu

cd /app

python - <<'PY'
import csv
import json
import secrets
import subprocess
import sys
import tempfile
from pathlib import Path

SCRIPT = "/app/reconcile.py"

WEIGHTS = {
    "cli_validation": 0.20,
    "status_filtering": 0.30,
    "timezone_duplicates": 0.50,
}


def run_program(rows=None, missing_argument=False):
    filename = None

    if not missing_argument:
        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".csv", newline="", delete=False
        ) as file:
            writer = csv.writer(file)
            writer.writerow(["tx_id", "timestamp", "amount", "status"])
            writer.writerows(rows)
            filename = file.name

    try:
        command = [sys.executable, SCRIPT]
        if filename:
            command.append(filename)

        return subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=10,
        )
    finally:
        if filename:
            Path(filename).unlink(missing_ok=True)


def check_cli_validation():
    result = run_program(missing_argument=True)
    return (
        result.returncode != 0
        and "Traceback" not in result.stderr
        and bool(result.stderr.strip())
    )


def check_status_filtering():
    success_amount = secrets.randbelow(9000) + 100
    pending_amount = secrets.randbelow(9000) + 100
    failed_amount = secrets.randbelow(9000) + 100

    rows = [
        [secrets.token_hex(8), "2026-01-01T10:00:00+00:00",
         str(success_amount), "SUCCESS"],
        [secrets.token_hex(8), "2026-01-01T11:00:00+00:00",
         str(pending_amount), "PENDING"],
        [secrets.token_hex(8), "2026-01-01T12:00:00+00:00",
         str(failed_amount), "FAILED"],
    ]

    result = run_program(rows)
    if result.returncode != 0:
        return False

    try:
        actual = json.loads(result.stdout)
    except json.JSONDecodeError:
        return False

    return actual == {
        "total_valid_amount": float(success_amount),
        "valid_count": 1,
        "failed_count": 1,
    }


def check_timezone_duplicates():
    tx_id = secrets.token_hex(8)
    old_amount = secrets.randbelow(9000) + 100
    latest_amount = secrets.randbelow(9000) + 100

    rows = [
        [tx_id, "2026-01-01T10:00:00+00:00",
         str(old_amount), "FAILED"],
        [tx_id, "2026-01-01T13:00:00+02:00",
         str(latest_amount), "SUCCESS"],
    ]

    result = run_program(rows)
    if result.returncode != 0:
        return False

    try:
        actual = json.loads(result.stdout)
    except json.JSONDecodeError:
        return False

    return actual == {
        "total_valid_amount": float(latest_amount),
        "valid_count": 1,
        "failed_count": 0,
    }


checks = [
    ("cli_validation", check_cli_validation),
    ("status_filtering", check_status_filtering),
    ("timezone_duplicates", check_timezone_duplicates),
]

results = {}

for name, check in checks:
    try:
        passed = check()
    except Exception as error:
        passed = False
        print(f"ERROR: {name}: {error}")

    results[name] = passed
    print(f"{'PASS' if passed else 'FAIL'}: {name}")

reward = 1.0 if all(results.values()) else 0.0

reward_path = Path("/logs/verifier/reward.txt")
reward_path.parent.mkdir(parents=True, exist_ok=True)
reward_path.write_text(f"{reward:.2f}\n")

print(f"Individual results: {results}")
print(f"Binary reward: {reward:.2f}")
PY
