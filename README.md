# Harbor RL Environment: Transaction Reconciliation

## Overview

This project implements a debugging and agent-evaluation task using Harbor. The task evaluates whether an agent can identify and fix three intentional bugs in a Python transaction reconciliation program.

## Task Design

The program processes CSV transaction records containing:
- Transaction ID
- ISO 8601 timestamp with timezone information
- Amount
- Transaction status

The expected output is a JSON summary containing the total valid amount, valid transaction count, and failed transaction count.

### Intentional Bugs

1. **CLI validation:** Missing command-line arguments should produce a useful error instead of an unhandled exception.
2. **Status filtering:** Only `SUCCESS` transactions are valid. `PENDING` transactions must not be counted.
3. **Duplicate and timezone handling:** Each transaction ID must use its latest record, comparing timestamps by their actual instant rather than their displayed local time.

## Implementation

- Python 3.12
- Docker-based task environment
- Harbor task configuration
- Bash solution and verifier scripts
- Randomized test inputs

The reference solution:
- Parses ISO 8601 timestamps.
- Normalizes timestamps to UTC.
- Selects the latest record per transaction ID.
- Counts only successful and failed transactions according to the specification.
- Handles missing arguments and common input errors.

## Reward Design

The verifier uses a weighted dense reward:

| Check | Weight |
|---|---:|
| CLI validation | 0.20 |
| Status filtering | 0.30 |
| Timezone-aware duplicate handling | 0.50 |
| **Total** | **1.00** |

The reward is the sum of the weights of the checks passed.

Random transaction IDs and amounts are generated during verification to reduce the effectiveness of hardcoded outputs.

## Evaluation Results

### Reference and negative-control tests

| Evaluation | Reward | Result |
|---|---:|---|
| Oracle with randomized verifier | 1.00 | Passed |
| Nop baseline | 0.00 | Failed as expected |
| Hardcoded hack test | 0.20 | Only CLI check passed |

The hardcoded hack did not pass the randomized status-filtering and timezone-duplicate checks.

### LLM Agent Baseline

Agent: `terminus-2`
Model: `openrouter/nvidia/nemotron-3.5-super-vl:free`
Trials: 3
Exceptions: 0
Mean reward: **1.000**
Pass@2: **1.000**
Runtime: 5 minutes 56 seconds

**Status:** Completed successfully. All 3 trials achieved a reward of 1.0.

The earlier Gemini 2.5 Flash attempt encountered a model availability error. Gemini 3.8 Flash attempts encountered provider availability and API quota errors. These unsuccessful attempts are documented separately and are not included in the OpenRouter baseline results.

### Ablation Study

**Objective:** Compare weighted dense rewards with binary all-or-nothing rewards.

**Controlled change:** The ablation variant changes only the reward calculation. The three randomized verification checks and their test logic remain unchanged.

| Check | Dense reward | Binary reward |
|---|---:|---:|
| CLI validation | 0.20 | All-or-nothing |
| Status filtering | 0.30 | All-or-nothing |
| Timezone duplicates | 0.50 | All-or-nothing |
| Total | 1.00 | 1.00 |

**Binary reward rule:**
- 1.00 when all three checks pass.
- 0.00 when any check fails.

**Oracle validation:** Passed (1 trial, reward 1.00, zero exceptions).

**LLM ablation evaluation:** In progress. Results will be added after all three trials finish.

### Experimental Methodology

- The baseline uses the weighted dense reward verifier.
- The ablation uses binary rewards with identical verification checks.
- Both evaluations use Harbor's `terminus-2` agent and the same OpenRouter model.
- Three trials are used for each LLM evaluation.
- Oracle and negative-control runs validate the task and verifier behavior.

### Reward Design: Interpretation

Dense rewards provide partial credit and indicate which parts of a task an agent successfully completed. Binary rewards provide a simpler success signal but do not distinguish partial progress from complete failure.

The ablation experiment investigates how this reward-design change affects agent performance. Conclusions will be based on the recorded trial results rather than assumptions.

## Repository Structure

```text
.
├── tasks/
│   ├── reconcile-bug/
│       ├── task.toml
│       ├── instruction.md
│       ├── environment/
│       │   ├── Dockerfile
│       │   └── reconcile.py
│       ├── solution/
│       │   ├── solve.sh
│       │   └── hack.sh
│       └── tests/
│           └── test.sh
├── jobs_summary/
├── ai_transcripts/
├── README.md
└── .gitignore
