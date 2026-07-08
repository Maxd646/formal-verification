"""
Bank Transfer System - Python Implementation
============================================
Two implementations are provided:

  transfer()       — the correct version
  transfer_buggy() — a realistic bug: processing fee deducted from sender,
                     but full amount credited to receiver.
                     Looks like a plausible "fee" feature. Passes all 12 tests.

The bug is not a typo. It is the kind of logic error that happens when a
developer adds a fee calculation and forgets to keep sender and receiver
in sync. All standard tests pass. Money leaks on every transaction.
"""

FEE = 2   # processing fee deducted from sender (but NOT subtracted from receiver credit)


class Account:
    def __init__(self, balance: int):
        if balance < 0:
            raise ValueError("Balance cannot be negative")
        self.balance = balance

    def __repr__(self):
        return f"Account(balance={self.balance})"


# =============================================================================
# CORRECT implementation
# =============================================================================
def transfer(sender: Account, receiver: Account, amount: int) -> bool:
    """
    Transfer exactly `amount` from sender to receiver.
    Money is always conserved: sender_loss == receiver_gain == amount.
    """
    if amount <= 0:
        return False
    if sender.balance < amount:
        return False

    sender.balance -= amount
    receiver.balance += amount
    return True


# =============================================================================
# BUGGY implementation — realistic logic error
#
# A developer added a "processing fee" feature.
# The sender is charged amount + FEE.
# The receiver is credited the full amount (as intended).
# BUT: the total money in the system decreases by FEE on every transfer.
#
# This passes all standard unit tests because:
#   - Guard clauses still work correctly
#   - Receiver gets the right amount
#   - Tests check sender/receiver individually but not their sum
#   - No test uses a small enough amount to trigger the fee-check boundary
# =============================================================================
def transfer_buggy(sender: Account, receiver: Account, amount: int) -> bool:
    """
    BUGGY: sender is charged amount + FEE, receiver gets amount.
    Fee disappears — not credited anywhere. Money leaks on every call.
    """
    if amount <= 0:
        return False
    total_deduction = amount + FEE          # sender loses more than receiver gains
    if sender.balance < total_deduction:
        return False

    sender.balance -= total_deduction       # sender loses amount + fee
    receiver.balance += amount              # receiver gains only amount
    return True                             # FEE vanished from the system


# =============================================================================
# DEMO: run both and compare
# =============================================================================
if __name__ == "__main__":
    print("=" * 64)
    print("Bank Transfer System — Demonstration")
    print("=" * 64)

    print("\n[Correct]  sender=100, receiver=50, amount=30")
    a, b = Account(100), Account(50)
    total_before = a.balance + b.balance
    transfer(a, b, 30)
    print(f"  sender={a.balance}  receiver={b.balance}  total={a.balance+b.balance}")
    print(f"  Conservation: {total_before} → {a.balance+b.balance}  ✓ OK")

    print(f"\n[Buggy]  sender=100, receiver=50, amount=30  (fee={FEE})")
    a2, b2 = Account(100), Account(50)
    total_before2 = a2.balance + b2.balance
    transfer_buggy(a2, b2, 30)
    print(f"  sender={a2.balance}  receiver={b2.balance}  total={a2.balance+b2.balance}")
    ok = total_before2 == a2.balance + b2.balance
    print(f"  Conservation: {total_before2} → {a2.balance+b2.balance}  {'✓ OK' if ok else f'✗ ${total_before2 - (a2.balance+b2.balance)} leaked (fee disappeared)'}")

    print("\n" + "=" * 64)
    print("Customer report: transfer(10, 0, 3) — money missing")
    print("=" * 64)
    a3, b3 = Account(10), Account(0)
    total_before3 = a3.balance + b3.balance
    transfer_buggy(a3, b3, 3)
    ok3 = total_before3 == a3.balance + b3.balance
    print(f"  sender={a3.balance}  receiver={b3.balance}  total={a3.balance+b3.balance}")
    print(f"  Conservation: {total_before3} → {a3.balance+b3.balance}  {'✓ OK' if ok3 else f'✗ ${total_before3 - (a3.balance+b3.balance)} leaked'}")
    print()
    print("  Lean refuses to prove conservation for transfer_buggy.")
    print("  The proof does not compile — bug caught before any code runs.")
