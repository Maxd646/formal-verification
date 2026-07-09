# Case Study: Verified Safe Bank Transfer System

## 1. Why Formal Verification Is Necessary Here

For this simplified bank transfer model, the critical correctness property is
that the total amount of money is preserved by every successful transfer.
This model uses `Nat` (natural numbers) for balances — it does not model
currencies, cents, multiple accounts, or rounding. What it does model is
sufficient to illustrate a fundamental limitation of testing.

The problem with testing in this domain is not effort — it is *fundamental
incompleteness*. A bank account balance is a natural number. Two accounts and
one transfer amount means the input space is infinite:

```
∀ (sender receiver : Account) (amount : Nat)
```

You can write 12 tests. You can write 1,000. You cannot test them all.
The gap between "inputs I tested" and "inputs that will ever occur" is where
financial bugs live.

Formal verification closes that gap for the properties it proves. Lean 4 does
not sample inputs — it proves properties for every natural number simultaneously.
The theorem:

```lean
theorem transfer_preserves_total (s r : Account) (amt : Nat) :
    match transfer s r amt with
    | some (s', r') => totalMoney s' r' = totalMoney s r
```

holds unconditionally for all `s`, `r`, `amt` — not because we ran the function,
but because we constructed a logical proof that the Lean kernel verified.

---

## 2. The Implementation

### Correct Version

```python
def transfer(sender, receiver, amount):
    if amount <= 0:          return False
    if sender.balance < amount: return False
    sender.balance -= amount
    receiver.balance += amount
    return True
```

Sender loses exactly `amount`. Receiver gains exactly `amount`. Total conserved.

### Buggy Version — Realistic Fee Leakage

```python
FEE = 2

def transfer_buggy(sender, receiver, amount):
    if amount <= 0:                        return False
    if sender.balance < amount + FEE:      return False
    sender.balance -= (amount + FEE)   # sender charged amount + fee
    receiver.balance += amount         # receiver gets only amount
    return True                        # FEE disappeared from the system
```

This represents a real class of bug: a developer adds a processing fee, correctly
deducts it from the sender, but forgets that this breaks the conservation invariant.
The fee is not credited anywhere. Money leaks on every single transaction.

This is not a typo. It is the kind of logic error that happens in real codebases
when features are added incrementally.

---

## 3. The Testing Story

Run `python tests.py` against `transfer_buggy()`:

```
test_basic_transfer_succeeds      ok
test_receiver_credited_correctly  ok
test_sender_has_less_after        ok
test_insufficient_balance         ok
test_negative_amount_rejected     ok
test_zero_amount_rejected         ok
test_transfer_from_empty          ok
test_large_transfer               ok
test_multiple_transfers           ok
test_receiver_independent         ok
test_exact_sufficient_balance     ok
test_return_value_on_success      ok

Ran 12 tests — OK
```

All 12 pass. The bug is completely invisible.

Why? Because the tests check:
- Guard clauses (do invalid inputs get rejected?) — fee doesn't affect this
- Receiver credit (does receiver get the right amount?) — receiver is correct
- Return value (does it return True on success?) — it does

No test checks: **does the total money in the system stay the same?**

It is easy for developers to focus tests on expected behaviors — successful
transfers, rejected inputs, return values — while overlooking global invariants
such as conservation of money. The 12 tests here are not poorly written; they
check exactly what most developers would think to check. The invariant simply
did not appear as a test case.

---

## 4. The Customer Report

A customer reports: `transfer(sender=10, receiver=0, amount=3)` — money is missing.

```
Before:  sender=10,  receiver=0   total=10
After:   sender=5,   receiver=3   total=8

$2 vanished.
```

The bug is now visible — but only after real money was affected.
The 12 tests all said the system was correct.

---

## 5. How Lean Catches It Before Any Code Runs

### Step 1: Define the invariant precisely

```lean
def totalMoney (a b : Account) : Nat :=
  a.balance + b.balance
```

This makes the conservation property explicit and testable as a proof obligation.

### Step 2: State the theorem

```lean
theorem transfer_preserves_total (s r : Account) (amt : Nat) :
    match transfer s r amt with
    | none          => True
    | some (s', r') => totalMoney s' r' = totalMoney s r
```

### Step 3: Prove it for the correct implementation

```lean
  by_cases h : amt ≤ s.balance <;> simp [h]
  omega   -- ✓  proves (s - amt) + (r + amt) = s + r
          --    arithmetically true for all Nat — compiles
```

### Step 4: Attempt to prove it for transfer_buggy

```lean
  by_cases h : ... <;> simp [h]
  omega   -- ✗  COMPILE ERROR
          --    must prove (s - (amt + 2)) + (r + amt) = s + r
          --    simplifies to: s + r - 2 = s + r
          --    which is false (2 ≠ 0)
          --    Lean's kernel rejects this step
```

As long as the project requires `transfer_preserves_total` to be proved,
`transfer_buggy` cannot satisfy the specification. The proof obligation makes
the conservation property a hard requirement rather than an assumed one.

### The mechanism

Lean does not run the function. It checks a logical argument step by step.
When `omega` is asked to verify `s + r - 2 = s + r`, it detects this is false
and rejects the proof. The file does not compile. No binary is produced.
The bug cannot be deployed because deployment requires compilation.

This is not "Lean found the bug." This is "the bug makes compilation impossible."

---

## 6. Testing Proves vs. Lean Proves

| | Python Tests | Lean 4 |
|---|---|---|
| What is checked | 12 specific input values | ∀ sender receiver amount : Nat |
| Conservation property | Not checked (no test for it) | Proven for all inputs |
| Fee leakage bug | Invisible — 12 tests pass | Compilation fails |
| Negative balances | Runtime ValueError | Impossible by type (Nat) |
| When bug is caught | After customer reports it | Before compilation succeeds |
| Guarantee | "These inputs worked" | "Every input works" |

The critical row: **testing proves "these inputs worked."
Lean proves "every possible input works."**

That sentence is the entire reason formal verification exists.

---

## 7. Real-World Relevance

Fee leakage bugs are not hypothetical. In high-frequency trading systems, a
fee calculation error that loses $0.001 per transaction is invisible in testing
but accumulates to millions of dollars across billions of transactions.

The 2012 Knight Capital Group incident illustrates how software defects in
financial systems can have catastrophic consequences — $440 million lost in
45 minutes from a bug that passed all testing. It motivates the use of stronger
correctness techniques such as formal verification, where critical invariants
are proven rather than assumed.

---

## 8. Conclusion

```
Testing asks:   "Did this work for the cases I tried?"
Lean answers:   "Does this work for every case that exists?"
```

For software that handles money, the second question is the only acceptable one.

The processing fee bug in this case study survived 12 carefully written tests.
Lean refused to prove the conservation property for it from the first attempt.
No inputs required. No test cases required. The failed proof shows that
`transfer_buggy` does not satisfy the stated correctness property — because
the implementation deducts more than it credits, violating conservation.
