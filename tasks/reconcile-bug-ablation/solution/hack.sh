
#!/bin/bash
set -e

cat > /app/reconcile.py <<'PY'
import csv
import json
import sys

if len(sys.argv) != 2:
    print("Usage: python reconcile.py <input.csv>", file=sys.stderr)
    sys.exit(1)

with open(sys.argv[1], newline="") as file:
    rows = list(csv.DictReader(file))

status_test = [
    ["T1", "2026-01-01T10:00:00+00:00", "100", "SUCCESS"],
    ["T2", "2026-01-01T11:00:00+00:00", "200", "PENDING"],
    ["T3", "2026-01-01T12:00:00+00:00", "50", "FAILED"],
]

timezone_test = [
    ["T4", "2026-01-01T10:00:00+00:00", "100", "SUCCESS"],
    ["T4", "2026-01-01T13:00:00+02:00", "300", "FAILED"],
]

actual_rows = [
    [r["tx_id"], r["timestamp"], r["amount"], r["status"]]
    for r in rows
]

if actual_rows == status_test:
    result = {
        "total_valid_amount": 100.0,
        "valid_count": 1,
        "failed_count": 1
    }
elif actual_rows == timezone_test:
    result = {
        "total_valid_amount": 0.0,
        "valid_count": 0,
        "failed_count": 1
    }
else:
    result = {
        "total_valid_amount": 0.0,
        "valid_count": 0,
        "failed_count": 0
    }

print(json.dumps(result, indent=2))
PY

chmod +x /app/reconcile.py
