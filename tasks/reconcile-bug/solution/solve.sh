
#!/bin/bash
set -e

cat > /app/reconcile.py <<'PY'
import csv
import json
import sys
from datetime import datetime, timezone


def reconcile(input_file):
    transactions = {}

    with open(input_file, "r", newline="") as file:
        reader = csv.DictReader(file)

        for row in reader:
            tx_id = row["tx_id"]
            timestamp = datetime.fromisoformat(
                row["timestamp"].replace("Z", "+00:00")
            )
            amount = float(row["amount"])
            status = row["status"].strip().upper()

            if timestamp.tzinfo is None:
                timestamp = timestamp.replace(tzinfo=timezone.utc)

            timestamp = timestamp.astimezone(timezone.utc)

            if (
                tx_id not in transactions
                or timestamp > transactions[tx_id]["timestamp"]
            ):
                transactions[tx_id] = {
                    "timestamp": timestamp,
                    "amount": amount,
                    "status": status,
                }

    total_valid_amount = 0.0
    valid_count = 0
    failed_count = 0

    for tx in transactions.values():
        if tx["status"] == "SUCCESS":
            total_valid_amount += tx["amount"]
            valid_count += 1
        elif tx["status"] == "FAILED":
            failed_count += 1

    return {
        "total_valid_amount": round(total_valid_amount, 2),
        "valid_count": valid_count,
        "failed_count": failed_count,
    }


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(
            "Usage: python /app/reconcile.py <input.csv>",
            file=sys.stderr,
        )
        sys.exit(1)

    try:
        result = reconcile(sys.argv[1])
        print(json.dumps(result, indent=2))
    except (OSError, ValueError, KeyError) as error:
        print(f"Error: {error}", file=sys.stderr)
        sys.exit(1)
PY

chmod +x /app/reconcile.py
