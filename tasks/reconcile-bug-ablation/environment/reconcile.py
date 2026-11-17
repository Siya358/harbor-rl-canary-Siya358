
import csv
import json
import sys


def reconcile(input_file):
    transactions = {}

    with open(input_file, "r", newline="") as file:
        reader = csv.DictReader(file)

        for row in reader:
            tx_id = row["tx_id"]
            status = row["status"].strip().upper()
            amount = float(row["amount"])

            if tx_id not in transactions:
                transactions[tx_id] = {
                    "timestamp": row["timestamp"],
                    "amount": amount,
                    "status": status
                }

    total_valid_amount = 0.0
    valid_count = 0
    failed_count = 0

    for tx in transactions.values():
        if tx["status"] in ("SUCCESS", "PENDING"):
            total_valid_amount += tx["amount"]
            valid_count += 1
        elif tx["status"] == "FAILED":
            failed_count += 1

    return {
        "total_valid_amount": round(total_valid_amount, 2),
        "valid_count": valid_count,
        "failed_count": failed_count
    }


if __name__ == "__main__":
    result = reconcile(sys.argv[1])
    print(json.dumps(result, indent=2))
