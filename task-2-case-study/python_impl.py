"""
Demonstrates traditional testing for critical financial operations.
While tests are comprehensive, they only verify specific cases.
"""

class Account:
    
    def __init__(self, balance: int):
        if balance < 0:
            raise ValueError("Balance cannot be negative")
        self.balance = balance
    
    def __repr__(self):
        return f"Account(balance={self.balance})"


def transfer(sender: Account, receiver: Account, amount: int) -> bool:
    """
    Transfer money from sender to receiver.
    
    Returns True if successful, False otherwise.
    Ensures: sender_loss = receiver_gain (money conservation)
    """
    if amount < 0:
        return False
    
    if sender.balance < amount:
        return False
    
    sender.balance -= amount
    receiver.balance += amount
    return True


if __name__ == "__main__":
    print("=" * 60)
    print("Bank Transfer System - Python Demo")
    print("=" * 60)
    
    # Demo 1: Successful transfer
    print("\n Scenario 1: Alice transfers $30 to Bob")
    alice = Account(100)
    bob = Account(50)
    total_before = alice.balance + bob.balance
    print(f"Before: {alice}, {bob} | Total: ${total_before}")
    
    transfer(alice, bob, 30)
    total_after = alice.balance + bob.balance
    print(f"After:  {alice}, {bob} | Total: ${total_after}")
    print(f" Money conserved: {total_before == total_after}")
    
    # Demo 2: Insufficient funds
    print("\n Scenario 2: Charlie tries $100 transfer (insufficient)")
    charlie = Account(50)
    dave = Account(25)
    print(f"Before: {charlie}, {dave}")
    
    success = transfer(charlie, dave, 100)
    print(f"After:  {charlie}, {dave}")
    print(f"Result: {' Failed (as expected)' if not success else ' Success'}")
    
    print("\n" + "=" * 60)
    print("Note: Tests verify specific cases.")
    print("They cannot prove correctness for ALL inputs.")
    print("=" * 60)
