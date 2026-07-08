# Formal Verification with Lean 4

> Testing proves that specific inputs worked.
> Formal verification proves that every possible input works.

This project demonstrates that difference through two tasks: propositional logic
proofs and a verified bank transfer system — including a realistic bug that
passes all 12 unit tests but is caught by Lean before a single line executes.

---

## Repository Structure

```
MyLeanProject/
├── task-1-logic-proofs/
│   └── Logic.lean           
└── task-2-case-study/
    ├── python_impl.py         
    ├── tests.py               
    ├── LeanImpl.lean          
    └── CASE_STUDY.md          
```

---

## The Core Idea

Traditional testing:

```python
assert transfer(100, 50, 30) == True    # one case checked
assert transfer(20,  50, 30) == False   # another case checked
# ... but infinitely many cases remain unchecked
```

Formal verification in Lean 4:

```lean
theorem transfer_preserves_total (s r : Account) (amt : Nat) :
    match transfer s r amt with
    | none          => True
    | some (s', r') => totalMoney s' r' = totalMoney s r
-- proven for ∀ s r amt : Nat — every possible input, simultaneously
```

The theorem is not run against inputs. It is proven. The Lean kernel checks
every logical step and either accepts the proof or rejects the file.
If the implementation violates the property, the file does not compile.

---

## Quick Start

**Prerequisites:** [Lean 4 via elan](https://github.com/leanprover/elan) · Python 3.x

**Verify everything at once:**
```bash
.\verify.bat          # Windows
```

**Or individually:**
```bash
# Lean proofs
lake build
lake env lean task-1-logic-proofs/Logic.lean
lake env lean task-2-case-study/LeanImpl.lean

# Python
python task-2-case-study/python_impl.py     # run demo
python task-2-case-study/tests.py           # run 12 tests
```

---

## Task 1 — Propositional Logic Proofs

Ten theorems proven in Lean 4 using tactics such as `intro`, `exact`,
`constructor`, `cases`, and `omega`. Each proof is commented to show the
reasoning strategy.

| Theorem | Statement | Key Tactic |
|---------|-----------|------------|
| T51 | `P, P→Q ⊢ P∧Q` | `constructor` |
| T52 | `P∧Q→R, Q→P, Q ⊢ R` | `apply` + `constructor` |
| T53 | `P→Q, Q→R ⊢ P→(Q∧R)` | `intro` + `constructor` |
| T54 | `P ⊢ Q→P` | weakening via `intro _` |
| T55 | `P→Q, ¬Q ⊢ ¬P` | modus tollens |
| T56 | `P→(Q→R) ⊢ Q→(P→R)` | argument permutation |
| T57 | `P∨(Q∧R) ⊢ P∨Q` | `cases` + projection |
| T58 | complex hypotheses `⊢ ¬L` | contradiction via `have` |
| T59 | `⊢ P→P` | identity |
| T510 | `⊢ ¬(P∧¬P)` | law of non-contradiction |

All 10 compile with zero `sorry` placeholders and zero warnings.

---

## Task 2 — Bank Transfer Case Study

### The Bug

`transfer_buggy()` in `python_impl.py` contains a realistic logic error:
a processing fee is deducted from the sender but not credited anywhere,
so money leaks from the system on every transaction.

```python
FEE = 2
def transfer_buggy(sender, receiver, amount):
    sender.balance -= (amount + FEE)   # sender charged amount + fee
    receiver.balance += amount          # receiver gets only amount
    # FEE is gone
```

### What Testing Says

```
python tests.py

  test_basic_transfer               ok
  test_boundary_exact_balance       ok
  test_boundary_one_under           ok
  test_insufficient_balance         ok
  test_large_transfer               ok
  test_multiple_transfers_receiver  ok
  test_negative_amount_rejected     ok
  test_receiver_credited            ok
  test_return_value_on_success      ok
  test_sender_sufficient            ok
  test_transfer_from_empty          ok
  test_zero_amount_rejected         ok

  12 passed — OK
```

Every test passes. The bug is invisible.

### What Lean Says

The `totalMoney` invariant is defined once and referenced by all proofs:

```lean
def totalMoney (a b : Account) : Nat := a.balance + b.balance
```

Attempting to prove `transfer_preserves_total` for `transfer_buggy`:

```lean
omega   -- ✗  must prove (s - (amt + 2)) + (r + amt) = s + r
        --     simplifies to s + r - 2 = s + r  — false
        --     Lean's kernel rejects this step
        --     file does not compile
```

Proving it for the correct `transfer`:

```lean
omega   -- ✓  proves (s - amt) + (r + amt) = s + r
        --     arithmetically true for all Nat
        --     proof accepted
```

As long as the project requires `transfer_preserves_total` to be proved,
`transfer_buggy` cannot satisfy the specification.
The customer later reports `transfer(10, 0, 3)` — total drops from 10 to 8.
Lean already knew.

### Properties Proven (correct implementation)

All six theorems hold for `∀ (s r : Account) (amt : Nat)`:

| Theorem | What it guarantees |
|---|---|
| `transfer_preserves_total` | `totalMoney` is unchanged by any transfer |
| `transfer_succeeds_iff` | Succeeds iff `amount ≤ sender.balance` — no ambiguity |
| `transfer_updates_correctly` | Sender loses exactly `amount`, receiver gains exactly `amount` |
| `balance_nonnegative` | All balances `≥ 0` — structural fact, not a runtime check |
| `zero_transfer_noop` | Transferring zero leaves both accounts unchanged |
| `sender_balance_decreases` | Sender cannot gain money by initiating a transfer |

### Testing vs. Verification

| | Python (12 tests) | Lean 4 (6 theorems) |
|---|---|---|
| Input coverage | 12 specific values | ∀ natural number |
| Conservation property | Not tested — bug survives | Proven — buggy code rejected |
| Negative balances | Runtime `ValueError` | Impossible by type (`Nat`) |
| Bug detection timing | After customer reports it | At compile time |
| Guarantee | "These inputs worked" | "Every input works" |

---

## Key Takeaway

The processing fee bug survived 12 carefully written tests. Lean refused to
prove the conservation property for it because the implementation deducts more
than it credits — violating the stated specification.

That is the difference between testing and verification:
testing checks examples, verification proves properties.

---

## Lean 4 Version

```
Lean 4.31.0 · Lake 5.0.0
```
