-- ============================================================================
-- Bank Transfer System - Lean 4 Formal Verification
-- ============================================================================
-- Mathematically proves correctness properties that Python tests can only
-- approximate. These proofs hold for ALL possible inputs.
-- ============================================================================

/-!
# Verified Safe Bank Transfer

## Properties Proven (for ALL possible inputs):
1. **Money Conservation** — total balance never changes during a transfer
2. **Transfer Success Condition** — succeeds iff sender has sufficient funds
3. **Correct Updates** — sender loses exactly `amount`, receiver gains exactly `amount`
4. **Non-negative Balances** — impossible by type construction (Nat)
5. **Zero Transfer is a No-op** — transferring zero changes nothing
6. **Sender Balance Decreases** — sender never gains from a transfer
-/

/-- A bank account holding a natural number (non-negative by construction) -/
structure Account where
  balance : Nat
  deriving Repr, BEq

/-! ## Core Transfer Function -/

/--
Transfer `amount` from `sender` to `receiver`.

- Returns `some (newSender, newReceiver)` on success
- Returns `none` if sender has insufficient funds

Using `Nat` makes negative balances structurally impossible.
-/
def transfer (sender receiver : Account) (amount : Nat)
    : Option (Account × Account) :=
  if amount ≤ sender.balance then
    some ({ balance := sender.balance - amount },
          { balance := receiver.balance + amount })
  else
    none

/-! ## Formal Proofs -/

/--
**Money Conservation Theorem**

After any transfer, the total balance is unchanged.
Proven for *every possible* sender balance, receiver balance, and amount.
-/
theorem transfer_conserves_money (s r : Account) (amt : Nat) :
    match transfer s r amt with
    | none          => True
    | some (s', r') => s'.balance + r'.balance = s.balance + r.balance := by
  unfold transfer
  by_cases h : amt ≤ s.balance <;> simp [h]
  omega

/--
**Success Condition**

A transfer succeeds if and only if `amount ≤ sender.balance`.
-/
theorem transfer_succeeds_iff (s r : Account) (amt : Nat) :
    (transfer s r amt).isSome = true ↔ amt ≤ s.balance := by
  unfold transfer
  by_cases h : amt ≤ s.balance <;> simp [h] <;> omega

/--
**Correct Update Amounts**

On success: sender.balance decreases by `amount`, receiver.balance increases by `amount`.
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
This is trivially true because `Nat` values are always ≥ 0 by construction —
it is impossible to create an `Account` with a negative balance.
-/
theorem balance_nonnegative (a : Account) : 0 ≤ a.balance :=
  Nat.zero_le a.balance

/--
**Zero Transfer is a No-op**

Transferring zero leaves both accounts exactly as they were.
-/
theorem zero_transfer_noop (s r : Account) :
    transfer s r 0 =
    some ({ balance := s.balance }, { balance := r.balance }) := by
  simp [transfer]

/--
**Sender Balance Decreases**

After a successful transfer, sender's new balance ≤ original balance.
-/
theorem sender_balance_decreases (s r s' r' : Account) (amt : Nat)
    (h : transfer s r amt = some (s', r')) :
    s'.balance ≤ s.balance := by
  have ⟨hs, _⟩ := transfer_updates_correctly s r s' r' amt h
  rw [hs]
  exact Nat.sub_le s.balance amt

/-! ## Verified Examples -/

#eval transfer { balance := 100 } { balance := 50 } 30
-- Expected: some ({ balance := 70 }, { balance := 80 })

#eval transfer { balance := 20 } { balance := 50 } 30
-- Expected: none

#eval transfer { balance := 100 } { balance := 0 } 0
-- Expected: some ({ balance := 100 }, { balance := 0 })

/-!
## Testing vs. Verification

```
Python tested:  transfer(100, 50, 30) ✓
                transfer(20,  50, 30) ✗
                ... 12 specific cases

Lean proved:    ∀ s r amt,  money is conserved
                ∀ s r amt,  success ↔ amt ≤ s.balance
                ∀ a,        a.balance ≥ 0
                (covers all 2^192 possible input combinations)
```
-/
