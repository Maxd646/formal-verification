-- ============================================================================
-- Bank Transfer System - Lean 4 Formal Verification
-- ============================================================================

/-!
# Verified Safe Bank Transfer

## Properties Proven:
1. **Total Money Preserved** — `totalMoney` is invariant across any transfer
2. **Transfer Success Condition** — succeeds iff sender has sufficient funds
3. **Correct Updates** — sender loses exactly `amount`, receiver gains exactly `amount`
4. **Non-negative Balances** — structurally impossible (`Nat` has no negatives)
5. **Zero Transfer is a No-op** — transferring zero changes nothing
6. **Sender Balance Decreases** — sender never gains from a transfer

All theorems hold for **every possible input** (∀ sender receiver amount : Nat).
-/

-- ============================================================================
-- Data Model
-- ============================================================================

/-- A bank account. Balance is `Nat` — negative values are not representable. -/
structure Account where
  balance : Nat
  deriving Repr, BEq

/--
The total money held across two accounts.
Defining this once makes all conservation theorems clear and uniform.
-/
def totalMoney (a b : Account) : Nat :=
  a.balance + b.balance

-- ============================================================================
-- Transfer Function
-- ============================================================================

/--
Transfer `amount` from `sender` to `receiver`.

Returns `some (newSender, newReceiver)` on success,
or `none` if sender has insufficient funds.

`Nat` subtraction is safe here: we guard with `amount ≤ sender.balance`
before subtracting, so no underflow is possible.
-/
def transfer (sender receiver : Account) (amount : Nat)
    : Option (Account × Account) :=
  if amount ≤ sender.balance then
    some ({ balance := sender.balance - amount },
          { balance := receiver.balance + amount })
  else
    none

-- ============================================================================
-- Formal Proofs — Correct Implementation
-- ============================================================================

/--
**Total Money is Preserved**

For every possible sender balance, receiver balance, and transfer amount:
- If the transfer fails: both accounts are unchanged (trivially preserved)
- If the transfer succeeds: `totalMoney` before = `totalMoney` after

This is proven for ALL inputs, not sampled from a finite test suite.
-/
theorem transfer_preserves_total (s r : Account) (amt : Nat) :
    match transfer s r amt with
    | none          => True
    | some (s', r') => totalMoney s' r' = totalMoney s r := by
  simp only [totalMoney, transfer]
  by_cases h : amt ≤ s.balance <;> simp [h]
  omega

/--
**Success Condition**

A transfer returns `some` if and only if the sender has enough funds.
No other condition affects success or failure.
-/
theorem transfer_succeeds_iff (s r : Account) (amt : Nat) :
    (transfer s r amt).isSome = true ↔ amt ≤ s.balance := by
  unfold transfer
  by_cases h : amt ≤ s.balance <;> simp [h] <;> omega

/--
**Correct Update Amounts**

On a successful transfer:
- Sender's new balance = original balance − amount
- Receiver's new balance = original balance + amount

Exactly right. Not approximately right.
-/
theorem transfer_updates_correctly (s r s' r' : Account) (amt : Nat)
    (h : transfer s r amt = some (s', r')) :
    s'.balance = s.balance - amt ∧ r'.balance = r.balance + amt := by
  unfold transfer at h
  by_cases hc : amt ≤ s.balance
  · simp [hc] at h
    obtain ⟨hs, hr⟩ := h
    exact ⟨by rw [← hs], by rw [← hr]⟩
  · simp [hc] at h

/--
**Non-negative Balances**

Every account balance satisfies `0 ≤ balance`.
This is not a runtime check — it is a structural fact.
`Nat` cannot represent negative numbers. There is no integer overflow.
No `ValueError` needed. The type itself is the guarantee.
-/
theorem balance_nonnegative (a : Account) : 0 ≤ a.balance :=
  Nat.zero_le a.balance

/--
**Zero Transfer is a No-op**

Transferring zero returns both accounts unchanged.
-/
theorem zero_transfer_noop (s r : Account) :
    transfer s r 0 =
    some ({ balance := s.balance }, { balance := r.balance }) := by
  simp [transfer]

/--
**Sender Balance Decreases**

After a successful transfer, the sender cannot have more than before.
Initiating a transfer never benefits the sender.
-/
theorem sender_balance_decreases (s r s' r' : Account) (amt : Nat)
    (h : transfer s r amt = some (s', r')) :
    s'.balance ≤ s.balance := by
  have ⟨hs, _⟩ := transfer_updates_correctly s r s' r' amt h
  rw [hs]
  exact Nat.sub_le s.balance amt

-- ============================================================================
-- The Buggy Version — Lean Catches What Tests Miss
-- ============================================================================

/-!
## Realistic Bug: Processing Fee Leakage

The Python `transfer_buggy()` represents a real class of bug:
a developer adds a processing fee that is deducted from the sender,
but the fee is not credited anywhere — it vanishes from the system.

```python
FEE = 2
def transfer_buggy(sender, receiver, amount):
    total_deduction = amount + FEE      # sender charged amount + fee
    sender.balance -= total_deduction
    receiver.balance += amount          # receiver gets amount, not amount + fee
    # FEE disappears on every transaction
```

All 12 standard unit tests pass against this function because:
- Guard clauses work correctly
- The receiver gets the right credit
- No test checks `total_before == total_after`

A customer eventually reports: `transfer(10, 0, 3)` — money missing.

Lean was already refusing to prove `transfer_preserves_total` for this function.
-/

def FEE : Nat := 2

/-- Buggy transfer: sender is charged amount + FEE, receiver gets only amount. -/
def transfer_buggy (sender receiver : Account) (amount : Nat)
    : Option (Account × Account) :=
  if 0 < amount ∧ amount + FEE ≤ sender.balance then
    some ({ balance := sender.balance - (amount + FEE) },  -- sender loses amount + fee
          { balance := receiver.balance + amount })         -- receiver gains only amount
  else
    none

/-!
### Attempting to Prove Conservation for transfer_buggy

The proof attempt below does NOT compile. Uncomment it to see Lean reject it.

```lean
theorem buggy_preserves_total (s r : Account) (amt : Nat) :
    match transfer_buggy s r amt with
    | none          => True
    | some (s', r') => totalMoney s' r' = totalMoney s r := by
  simp only [totalMoney, FEE, transfer_buggy]
  by_cases h : 0 < amt ∧ amt + 2 ≤ s.balance <;> simp [h]
  omega   -- ✗ COMPILE ERROR
          -- omega cannot prove:
          --   (s - (amt + 2)) + (r + amt) = s + r
          -- because this simplifies to:
          --   s + r - 2 = s + r
          -- which is false (2 ≠ 0)
          -- Lean found the fee leak without running a single test.
```

The correct version compiles immediately:

```lean
  omega   -- ✓ proves (s - amt) + (r + amt) = s + r
          -- because this is arithmetically true for all Nat values
```

The mechanism: Lean's kernel checks every logical step.
`(s - (amt + 2)) + (r + amt) = s + r` is false.
The kernel rejects it. The file refuses to compile.
The bug cannot reach production.
-/

-- ============================================================================
-- Verified Examples
-- ============================================================================

#eval transfer { balance := 100 } { balance := 50 } 30
-- some ({ balance := 70 }, { balance := 80 })  — total: 150 → 150 ✓

#eval transfer { balance := 20 } { balance := 50 } 30
-- none  (insufficient funds)

#eval transfer_buggy { balance := 100 } { balance := 50 } 30
-- some ({ balance := 68 }, { balance := 80 })  — total: 150 → 148  ✗ $2 leaked

#eval transfer_buggy { balance := 10 } { balance := 0 } 3
-- some ({ balance := 5 }, { balance := 3 })    — total: 10 → 8    ✗ $2 leaked

/-!
## The Difference

```
Testing proves:       These specific inputs worked correctly.
Lean proves:          ∀ (s r : Account) (amt : Nat), totalMoney is preserved.
                      — for every natural number, without exception.

transfer_buggy:       Passes all 12 tests.
                      Lean refuses to prove totalMoney invariant.
                      Bug is caught at compile time, before any code runs.

transfer (correct):   Passes all 12 tests.
                      Lean proves totalMoney invariant for all inputs.
                      Correctness is guaranteed, not approximated.
```
-/
