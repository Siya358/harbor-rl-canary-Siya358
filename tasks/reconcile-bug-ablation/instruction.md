

# Transaction Reconciliation Task

Create a reliable transaction reconciliation program.

## Input

The program receives a CSV file with these columns:

- `tx_id`: Unique transaction identifier
- `timestamp`: ISO 8601 timestamp, including timezone information
- `amount`: Transaction amount
- `status`: Transaction status

## Output

The program must print a JSON object containing:

- `total_valid_amount`: Sum of valid transaction amounts, rounded to two decimal places
- `valid_count`: Number of valid transactions
- `failed_count`: Number of failed transactions

## Business Rules

1. Only transactions with status `SUCCESS` are valid.
2. Transactions with status `FAILED` must contribute to the failed count.
3. Transactions with status `PENDING` must not contribute to either count or the valid amount.
4. Each transaction ID must be represented only once. If multiple records have the same transaction ID, use the record with the latest timestamp.
5. Timestamps may contain different timezone offsets. Compare their actual points in time, not their displayed local clock values.
6. The program must handle missing command-line arguments gracefully and display a useful error message instead of crashing.

## Execution

The program must be executable using:

`python /app/reconcile.py /app/input.csv`

Print the JSON result to standard output.
