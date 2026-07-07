# Case Study: Verified Safe Bank Transfer System

## 1. Problem Statement

Bank transfers are a critical financial operation where correctness is non-negotiable.
A single bug can cause:

- Money to disappear (sender loses funds, receiver never receives)
- Money to be created (receiver gains more than sender lost)
- Negative balances (account goes below zero)

Traditional testing can catch specific known bugs, but cannot guarantee
these properties hold for *every* possible input. Formal verification can.

## 2. Python Implementation

The Python implementation (`python_impl.py`) defines an `Account` class and
a `transfer` function with the following business rules:

1. Amount must be non-negative
2. Sender must have sufficient balance
3. On success: `sender.balance -= amount`, `receiver.balance += amount`

```python
def transfer(sender: Account, receiver: Account, amount: int) -> bool:
    if amount < 0:
        return False
    if sender.balance < amount:
        return False
    sender.balance -= amount
    receiver.balance += amount
    return True
```

## 3. Python Testing (tests.py)

The test suite covers 12 scenarios including:

- Normal transfers
- Transfer of entire balance (boundary)
- Insufficient funds
- Negative amounts
- Zero amounts
- Large balances
- Multiple chained transfers
- Self-transfer
- Empty account edge cases

All 12 tests pass. Yet this only demonstrates the function works for 12 inputs.

## 4. What Python Tests Miss

No matter how many tests we write, we cannot verify all inputs:

```
int in Python can be any integer (2^∞ possibilities)
Two accounts = 2^∞ × 2^∞ combinations
With an amount = 2^∞ × 2^∞ × 2^∞ total cases
```

Specific gaps that tests alone cannot close:

- There is no test for balance = `2^63 - 1` (max int64)
- No test proves every possible balance pair conserves money
- Runtime crashes (e.g., integer overflow in other languages) are not ruled out
- A refactoring that introduces a subtle arithmetic bug may pass all 12 tests

## 5. Lean 4 Formal Verification

The Lean implementation (`LeanImpl.lean`) uses `Nat` (natural numbers) for balances.
This makes negative balances **structurally impossible** — not just checked at runtime.

```lean
structure Account where
  balance : Nat   -- Nat = {0, 1, 2, 3, ...}, can never be negative
```

### Key Theorems Proven

**Money Conservation** — proven for all inputs:
```lean
theorem transfer_conserves_money (s r : Account) (amt : Nat) :
    match transfer s r amt with
    | none          => True
    | some (s', r') => s'.balance + r'.balance = s.balance + r.balance
```

**Success Condition** — no guessing, mathematically exact:
```lean
theorem transfer_succeeds_iff (s r : Account) (amt : Nat) :
    (transfer s r amt).isSome = true ↔ amt ≤ s.balance
```

**Correct Update Amounts** — sender and receiver changes are exact:
```lean
theorem transfer_updates_correctly ... :
    s'.balance = s.balance - amt ∧ r'.balance = r.balance + amt
```

## 6. Proof Strategy

The `transfer_conserves_money` proof works by:

1. Unfolding the definition of `transfer`
2. Splitting into two cases: success (`amount ≤ balance`) and failure
3. In the success case, using `omega` — Lean's arithmetic solver — to verify:
   `(s - amt) + (r + amt) = s + r`
4. In the failure case, nothing changes so the property is trivially true

The `omega` tactic checks the arithmetic identity over *all* natural numbers,
which is what makes this a proof rather than a test.

## 7. Comparison

| Scenario | Python Testing | Lean Verification |
|----------|---------------|-------------------|
| transfer(100, 50, 30) | ✓ Tested | ✓ Proven |
| transfer(2^63, 0, 1) | ✗ Not tested | ✓ Proven |
| All possible inputs | ✗ Impossible | ✓ Proven |
| Negative balance | Runtime check | Type-level impossible |
| Refactoring safety | Re-run tests | Proof still compiles |
| Mathematical certainty | No | Yes |

## 8. Real-World Impact

Formal verification is used in:

- **Banking and payments** (Visa, Swift) — transaction correctness
- **Aerospace** (NASA, Airbus) — flight control software
- **Operating systems** (seL4) — kernel correctness
- **Compilers** (CompCert) — code generation correctness
- **Cryptography** — protocol security proofs

In all these domains, a single bug can be catastrophic or irreversible.
Testing reduces risk; formal verification eliminates it for the proven properties.

## 9. Conclusion

Python tests gave us confidence in 12 specific scenarios.
Lean proofs gave us certainty across all possible inputs.

The key insight: **testing is empirical; verification is mathematical**.
When the Lean file compiles, the properties are guaranteed —
not by running code, but by checking a logical proof.

For financial systems, safety-critical software, or any domain where
correctness is non-negotiable, formal verification provides guarantees
that no amount of testing can match.
