# Formal Verification with Lean 4

An assignment demonstrating formal verification — the practice of mathematically
proving that code is correct for *all* possible inputs, not just tested ones.

## Repository Structure

```
MyLeanProject/
├── task-1-logic-proofs/
│   └── Logic.lean          # 10 propositional logic proofs
└── task-2-case-study/
    ├── LeanImpl.lean        # Formally verified bank transfer
    ├── python_impl.py       # Python implementation
    ├── tests.py             # 12 unit tests (pytest/unittest)
    └── CASE_STUDY.md        # Analysis and comparison
```

## What is Formal Verification?

Traditional testing checks a finite number of examples:

```python
assert transfer(100, 50, 30) == True   # one case
assert transfer(20, 50, 30)  == False  # another case
```

Formal verification proves correctness mathematically for *every* possible input:

```lean
theorem transfer_conserves_money (s r : Account) (amt : Nat) : ...
-- holds for all 2^64 × 2^64 × 2^64 possible combinations
```

## Quick Start

### Lean 4

Install Lean 4 via [elan](https://github.com/leanprover/elan):

```bash
curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh
```

Verify the proofs:

```bash
lake build
```

Or open any `.lean` file in VS Code with the Lean 4 extension installed.

### Python

```bash
python task-2-case-study/python_impl.py   # run demo
python -m pytest task-2-case-study/tests.py -v  # run tests
```

## Task 1: Logic Proofs

Ten propositional logic theorems proven in Lean 4, covering:

| Theorem | Concept |
|---------|---------|
| T51 | Conjunction introduction |
| T52 | Modus ponens via conjunction |
| T53 | Implication chain |
| T54 | Weakening |
| T55 | Modus tollens |
| T56 | Argument permutation |
| T57 | Disjunction weakening |
| T58 | Complex contradiction |
| T59 | Identity |
| T510 | Law of non-contradiction |

## Task 2: Bank Transfer Case Study

A bank transfer system verified in both Python and Lean 4.

### The Demonstration: Testing vs. Verification

**Key files:**
- `python_impl.py` — contains `transfer()` (correct) and `transfer_buggy()` (buggy)
- `tests.py` — shows tests passing on buggy code
- `LeanImpl.lean` — shows Lean refusing to prove buggy code

#### Run the demonstration:

```bash
# Show the bug visually (money disappearing)
python task-2-case-study/python_impl.py

# Run tests — see transfer_buggy() pass 5 tests, fail only the specific exposure test
python task-2-case-study/tests.py

# Verify Lean catches it at compile time
lake env lean task-2-case-study/LeanImpl.lean
```

### What the Bug Does

`transfer_buggy()` uses integer division (`//`) instead of subtraction (`-=`):

```python
sender.balance = sender.balance // amount   # BUG
```

**Example:** transfer(sender=10, receiver=0, amount=3)
- Buggy version: sender becomes 10÷3=3, receiver becomes 3 → total=6 (lost $4)
- Tests pass: only fails on inputs developers don't typically test

**Lean catches it:** The proof of money conservation fails to compile because
`s / amt + (r + amt) ≠ s + r` mathematically.

### Properties Proven in Lean

| Property | Guarantee |
|----------|-----------|
| Money conservation | Total balance never changes |
| Non-negative balances | Structurally impossible to go negative |
| Success condition | Succeeds iff `amount ≤ sender.balance` |
| Correct updates | Sender loses and receiver gains exactly `amount` |
| Safe failure | Failed transfers have no side effects |

### Testing vs. Verification

| | Python Testing | Lean Verification |
|---|---|---|
| Coverage | 12 specific cases | All possible inputs |
| Guarantee | Confidence | Mathematical proof |
| Runtime bugs | Possible | Proven absent |
| Negative balances | Caught at runtime | Impossible by type |

## Key Takeaway

Python tests are valuable but incomplete. Lean proofs are exhaustive by
construction — if the proof compiles, the property holds unconditionally.
