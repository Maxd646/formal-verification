"""
Bank Transfer Tests
===================
All 12 tests below run against transfer_buggy() and ALL PASS.

This is the core demonstration: a comprehensive test suite gives a false
sense of correctness. The bug (fee leakage) is invisible to these tests
because no test checks that total money is conserved across both accounts.

The same 12 tests also pass against transfer() (the correct version).

Lean 4 catches the bug at compile time by refusing to prove:
    ∀ s r amt,  s'.balance + r'.balance = s.balance + r.balance
for transfer_buggy — because it is mathematically false.
"""

import unittest
from python_impl import Account, transfer, transfer_buggy


def make(b): return Account(b)


# =============================================================================
# 12 standard tests — run against the BUGGY implementation, ALL PASS
# =============================================================================
class TestTransfer(unittest.TestCase):
    """
    Standard test suite. Written as any developer would write them.
    All 12 pass against transfer_buggy() — the bug is completely hidden.
    Change `transfer_buggy` to `transfer` to run against the correct version.
    """

    # --- use whichever implementation you want to test ---
    impl = staticmethod(transfer_buggy)   # swap to `transfer` to test correct version

    def test_basic_transfer(self):
        """Normal transfer succeeds"""
        a, b = make(100), make(50)
        self.assertTrue(self.impl(a, b, 30))
        self.assertEqual(b.balance, 80)   # receiver got 30 ✓

    def test_sender_sufficient(self):
        """Sender has enough — transfer proceeds"""
        a, b = make(200), make(0)
        self.assertTrue(self.impl(a, b, 50))

    def test_receiver_credited(self):
        """Receiver balance increases by amount"""
        a, b = make(100), make(10)
        self.impl(a, b, 20)
        self.assertEqual(b.balance, 30)   # 10 + 20 = 30 ✓

    def test_insufficient_balance(self):
        """Transfer rejected when sender cannot cover amount"""
        a, b = make(50), make(100)
        self.assertFalse(self.impl(a, b, 75))
        self.assertEqual(a.balance, 50)   # unchanged ✓
        self.assertEqual(b.balance, 100)  # unchanged ✓

    def test_zero_amount_rejected(self):
        """Zero-amount transfer is rejected"""
        a, b = make(100), make(50)
        self.assertFalse(self.impl(a, b, 0))

    def test_negative_amount_rejected(self):
        """Negative amount is rejected"""
        a, b = make(100), make(50)
        self.assertFalse(self.impl(a, b, -10))
        self.assertEqual(a.balance, 100)

    def test_transfer_from_empty(self):
        """Empty account cannot send"""
        a, b = make(0), make(100)
        self.assertFalse(self.impl(a, b, 1))

    def test_large_transfer(self):
        """Large amounts handled"""
        a, b = make(1_000_000), make(0)
        self.assertTrue(self.impl(a, b, 500_000))
        self.assertEqual(b.balance, 500_000)  # receiver got 500k ✓

    def test_multiple_transfers_receiver(self):
        """Receiver accumulates correctly over multiple transfers"""
        a, b = make(200), make(0)
        self.impl(a, b, 10)
        self.impl(a, b, 10)
        self.impl(a, b, 10)
        self.assertEqual(b.balance, 30)   # received 3 × 10 ✓

    def test_boundary_exact_balance(self):
        """Transfer of exact available balance"""
        a, b = make(52), make(0)   # 52 covers amount=50 + fee=2
        self.assertTrue(self.impl(a, b, 50))
        self.assertEqual(b.balance, 50)   # receiver got 50 ✓

    def test_boundary_one_under(self):
        """One unit under exact balance is rejected"""
        a, b = make(51), make(0)   # only 51, needs 52
        self.assertFalse(self.impl(a, b, 50))
        self.assertEqual(a.balance, 51)   # unchanged ✓

    def test_return_value_on_success(self):
        """Successful transfer returns True"""
        a, b = make(100), make(0)
        result = self.impl(a, b, 10)
        self.assertTrue(result)


# =============================================================================
# Run report
# =============================================================================
if __name__ == "__main__":
    import sys

    print("=" * 64)
    print("Running 12 tests against transfer_buggy()...")
    print("Expected: ALL PASS  (bug is invisible to these tests)")
    print("=" * 64)
    suite = unittest.TestLoader().loadTestsFromTestCase(TestTransfer)
    runner = unittest.TextTestRunner(verbosity=2, stream=sys.stdout)
    result = runner.run(suite)

    print()
    if result.wasSuccessful():
        print("✓ All 12 tests passed against transfer_buggy()")
        print()
        print("  Yet a customer later reported: transfer(10, 0, 3) destroys money.")
        print("  Lean refused to prove conservation for this function.")
        print("  The proof does not compile — bug exists, proof impossible.")
        print()
        print("  This is what testing cannot guarantee.")
        print("  This is what Lean can.")
    print("=" * 64)
