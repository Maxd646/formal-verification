-- Bank Transfer System — Lean 4 Formal Verification
-- All theorems hold for ∀ (s r : Account) (amt : Nat)

structure Account where
  balance : Nat
  deriving Repr, BEq

-- Total money across two accounts. Used in all conservation proofs.
def totalMoney (a b : Account) : Nat := a.balance + b.balance

-- Transfer `amount` from sender to receiver.
-- Returns some (newSender, newReceiver) on success, none if insufficient funds.
def transfer (sender receiver : Account) (amount : Nat)
    : Option (Account × Account) :=
  if amount ≤ sender.balance then
    some ({ balance := sender.balance - amount },
          { balance := receiver.balance + amount })
  else
    none

-- totalMoney is unchanged by any transfer
theorem transfer_preserves_total (s r : Account) (amt : Nat) :
    match transfer s r amt with
    | none          => True
    | some (s', r') => totalMoney s' r' = totalMoney s r := by
  simp only [totalMoney, transfer]
  by_cases h : amt ≤ s.balance <;> simp [h]
  omega

-- Succeeds iff amount ≤ sender.balance
theorem transfer_succeeds_iff (s r : Account) (amt : Nat) :
    (transfer s r amt).isSome = true ↔ amt ≤ s.balance := by
  unfold transfer
  by_cases h : amt ≤ s.balance <;> simp [h] <;> omega

-- On success: sender loses exactly amount, receiver gains exactly amount
theorem transfer_updates_correctly (s r s' r' : Account) (amt : Nat)
    (h : transfer s r amt = some (s', r')) :
    s'.balance = s.balance - amt ∧ r'.balance = r.balance + amt := by
  unfold transfer at h
  by_cases hc : amt ≤ s.balance
  · simp [hc] at h
    obtain ⟨hs, hr⟩ := h
    exact ⟨by rw [← hs], by rw [← hr]⟩
  · simp [hc] at h

-- Nat is always ≥ 0 — negative balances are structurally impossible
theorem balance_nonnegative (a : Account) : 0 ≤ a.balance :=
  Nat.zero_le a.balance

-- Transferring zero leaves both accounts unchanged
theorem zero_transfer_noop (s r : Account) :
    transfer s r 0 = some ({ balance := s.balance }, { balance := r.balance }) := by
  simp [transfer]

-- Sender's balance after a successful transfer ≤ original balance
theorem sender_balance_decreases (s r s' r' : Account) (amt : Nat)
    (h : transfer s r amt = some (s', r')) : s'.balance ≤ s.balance := by
  have ⟨hs, _⟩ := transfer_updates_correctly s r s' r' amt h
  rw [hs]; exact Nat.sub_le s.balance amt

-- =============================================================================
-- Buggy version: sender charged amount + FEE, receiver gets only amount.
-- FEE vanishes — totalMoney decreases on every transfer.
-- All 12 Python tests pass. Lean refuses to prove transfer_preserves_total.
-- =============================================================================

def FEE : Nat := 2

def transfer_buggy (sender receiver : Account) (amount : Nat)
    : Option (Account × Account) :=
  if 0 < amount ∧ amount + FEE ≤ sender.balance then
    some ({ balance := sender.balance - (amount + FEE) },
          { balance := receiver.balance + amount })
  else
    none

-- Uncomment to see Lean reject this proof:
-- theorem buggy_preserves_total (s r : Account) (amt : Nat) :
--     match transfer_buggy s r amt with
--     | none          => True
--     | some (s', r') => totalMoney s' r' = totalMoney s r := by
--   simp only [totalMoney, FEE, transfer_buggy]
--   by_cases h : 0 < amt ∧ amt + 2 ≤ s.balance <;> simp [h]
--   omega  -- ✗ cannot prove (s-(amt+2)) + (r+amt) = s+r  (false: fee leaked)

-- =============================================================================
-- Examples
-- =============================================================================

#eval transfer { balance := 100 } { balance := 50 } 30
-- some ({ balance := 70 }, { balance := 80 })  total: 150 → 150 ✓

#eval transfer { balance := 20 } { balance := 50 } 30
-- none  (insufficient funds)

#eval transfer_buggy { balance := 100 } { balance := 50 } 30
-- some ({ balance := 68 }, { balance := 80 })  total: 150 → 148 ✗

#eval transfer_buggy { balance := 10 } { balance := 0 } 3
-- some ({ balance := 5 }, { balance := 3 })    total: 10 → 8   ✗
