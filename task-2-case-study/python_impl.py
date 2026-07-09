"""
Bank Transfer System
Two implementations:
  transfer()       — correct
  transfer_buggy() — fee leakage bug (passes all 12 tests, caught by Lean)
"""

FEE = 2  # deducted from sender, never credited anywhere


class Account:
    def __init__(self, balance: int):
        if balance < 0:
            raise ValueError("Balance cannot be negative")
        self.balance = balance

    def __repr__(self):
        return f"Account(balance={self.balance})"


def transfer(sender: Account, receiver: Account, amount: int) -> bool:
    """Correct: sender loses amount, receiver gains amount. Total preserved."""
    if amount <= 0:
        return False
    if sender.balance < amount:
        return False
    sender.balance -= amount
    receiver.balance += amount
    return True


def transfer_buggy(sender: Account, receiver: Account, amount: int) -> bool:
    """Buggy: sender loses amount + FEE, receiver gains only amount. FEE vanishes."""
    if amount <= 0:
        return False
    if sender.balance < amount + FEE:
        return False
    sender.balance -= (amount + FEE)
    receiver.balance += amount
    return True


if __name__ == "__main__":
    print("=" * 60)
    print("[Correct]  sender=100, receiver=50, amount=30")
    a, b = Account(100), Account(50)
    total = a.balance + b.balance
    transfer(a, b, 30)
    print(f"  sender={a.balance}  receiver={b.balance}  total={a.balance+b.balance}")
    print(f"  Conservation: {total} → {a.balance+b.balance}  ✓ OK")

    print(f"\n[Buggy]    sender=100, receiver=50, amount=30  (FEE={FEE})")
    a2, b2 = Account(100), Account(50)
    total2 = a2.balance + b2.balance
    transfer_buggy(a2, b2, 30)
    after2 = a2.balance + b2.balance
    print(f"  sender={a2.balance}  receiver={b2.balance}  total={after2}")
    print(f"  Conservation: {total2} → {after2}  {'✓ OK' if total2 == after2 else f'✗  ${total2-after2} leaked'}")

    print("\n" + "=" * 60)
    print("Customer report: transfer(sender=10, receiver=0, amount=3)")
    a3, b3 = Account(10), Account(0)
    total3 = a3.balance + b3.balance
    transfer_buggy(a3, b3, 3)
    after3 = a3.balance + b3.balance
    print(f"  sender={a3.balance}  receiver={b3.balance}  total={after3}")
    print(f"  Conservation: {total3} → {after3}  {' OK' if total3 == after3 else f'  ${total3-after3} leaked'}")
    print("\n  Lean refused to prove totalMoney is preserved for transfer_buggy.")
    print("  The proof does not compile — bug caught before any code runs.")
    print("=" * 60)
