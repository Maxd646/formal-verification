# Formal Verification with Lean 4

Testing tells you what **didn't fail**. Formal verification tells you what **can't fail**.

This project demonstrates the difference between traditional software testing
and formal verification using Lean 4 through two tasks:

- Propositional logic proofs
- A verified bank transfer case study comparing Python testing with Lean proofs

---

## Repository Structure

```
MyLeanProject/
├── README.md
├── task-1-logic-proofs/
│   └── Logic.lean
└── task-2-case-study/
    ├── python_impl.py
    ├── tests.py
    ├── LeanImpl.lean
    └── CASE_STUDY.md
```

---

## The Reliability Gap

### Why Testing Fails

Testing tells you what **didn't fail** under specific conditions. It is like
driving different size trucks across a bridge to check the bridge works fine —
it doesn't guarantee the bridge won't collapse under a different weight tomorrow.

```python
assert transfer(100, 50, 30) == True   # this truck crossed fine
assert transfer(20,  50, 30) == False  # this one too
# but infinitely many weights were never tried
```

### The Power of Proofs

Proofs tell you what **can't fail**. Instead of crossing our fingers and hoping
the code is safe, formal verification lets us write a mathematical proof that
the computer checks. By translating the specification into machine-checkable
logic, we eliminate the gap entirely.

```lean
theorem transfer_preserves_total (s r : Account) (amt : Nat) :
    match transfer s r amt with
    | some (s', r') => totalMoney s' r' = totalMoney s r
-- not a test — a proof, checked for every possible input
```

If the implementation violates the specification, the Lean file fails to compile.

---

## Quick Start

**Requirements:** Lean 4 · Python 3.x

Install Lean using [elan](https://github.com/leanprover/elan).

**Run Lean verification:**

```bash
lake env lean task-1-logic-proofs/Logic.lean
lake env lean task-2-case-study/LeanImpl.lean
```

**Run Python tests:**

```bash
python task-2-case-study/python_impl.py
python task-2-case-study/tests.py
```

**Or verify everything at once:**

```bash
.\verify.bat
```

---

## Task 1 — Propositional Logic Proofs

`task-1-logic-proofs/Logic.lean` contains ten propositional logic theorems
originally provided with `sorry`. Each theorem was completed with a valid Lean 4 proof.

| Theorem | Statement | Main Idea |
|---------|-----------|-----------|
| T51 | `P, P → Q ⊢ P ∧ Q` | Construct conjunction |
| T52 | `P∧Q→R, Q→P, Q ⊢ R` | Apply implications |
| T53 | `P→Q, Q→R ⊢ P→(Q∧R)` | Build two results |
| T54 | `P ⊢ Q→P` | Ignore unused assumption |
| T55 | `P→Q, ¬Q ⊢ ¬P` | Modus tollens |
| T56 | `P→(Q→R) ⊢ Q→(P→R)` | Rearrange arguments |
| T57 | `P∨(Q∧R) ⊢ P∨Q` | Case analysis |
| T58 | Complex hypotheses `⊢ ¬L` | Contradiction |
| T59 | `⊢ P→P` | Identity proof |
| T510 | `⊢ ¬(P∧¬P)` | Non-contradiction |

All proofs compile without `sorry`.

---

## Task 2 — Bank Transfer Case Study

`task-2-case-study/` compares a Python implementation tested with unit tests
against a formally verified Lean implementation.

### The Problem

A bank transfer system must preserve the total amount of money in the system.
The invariant is:

```
sender balance + receiver balance = original total
```

A transfer should move money, not create or destroy it.

### Python Implementation

The Python version contains a realistic bug:

```python
FEE = 2

def transfer_buggy(sender, receiver, amount):
    sender.balance -= amount + FEE
    receiver.balance += amount
```

The sender loses the transfer amount plus a fee, but the receiver only receives
the transfer amount. The missing fee disappears from the system.

### Testing Result

```
12 passed
```

The Python tests check several examples and all pass. However, the bug remains
because the tests only cover selected cases. Testing cannot prove that every
possible transfer preserves money.

### Lean Verification

The Lean implementation defines the same transfer logic and proves important properties.

The invariant is defined once:

```lean
def totalMoney (a b : Account) : Nat :=
  a.balance + b.balance
```

Lean proves `transfer_preserves_total` — meaning that every valid transfer keeps
the total amount unchanged. If the buggy implementation is used, Lean cannot prove
the theorem because the mathematical statement is false.

### Verified Properties

| Property | Meaning |
|---|---|
| `transfer_preserves_total` | Money is conserved after every transfer |
| `transfer_succeeds_iff` | Transfers succeed exactly when funds are available |
| `transfer_updates_correctly` | Balances change by the correct amount |
| `balance_nonnegative` | Balances cannot become negative |
| `zero_transfer_noop` | A zero transfer changes nothing |
| `sender_balance_decreases` | Sender cannot gain money from a transfer |

### Testing vs Formal Verification

| | Python Testing | Lean Verification |
|---|---|---|
| What it tells you | What **didn't fail** for these inputs | What **can't fail** for any input |
| Coverage | Selected examples | All inputs satisfying assumptions |
| Method | Execute test cases | Mathematical proof |
| Bug detection | During testing or production | Before compilation |
| Guarantee | Examples passed | Property always holds |

---

## Conclusion

The bank transfer example shows the reliability gap in practice. Python tests
demonstrated that 12 examples worked — but the bug survived, because testing
tells you what didn't fail, not what can't fail.

Lean 4 closes that gap for the properties it proves. If the program violates
the specification, the proof fails and the code cannot be accepted as verified.
Formal verification provides stronger guarantees for software where correctness
is critical.

---

## Lean Version

```
Lean 4.31.0 · Lake 5.0.0
```
