"""
Bank Transfer Tests — 12 tests, all pass against transfer_buggy().
The fee leakage bug is invisible: no test checks total money conservation.
Lean catches it at compile time without needing any test input.
"""

import unittest
from python_impl import Account, transfer, transfer_buggy, FEE


def make(b): return Account(b)


class TestTransfer(unittest.TestCase):
    # Swap to `transfer` to run against the correct implementation
    impl = staticmethod(transfer_buggy)

    def test_basic_transfer_succeeds(self):
        a, b = make(100), make(50)
        self.assertTrue(self.impl(a, b, 30))

    def test_receiver_credited_correctly(self):
        a, b = make(100), make(10)
        self.impl(a, b, 20)
        self.assertEqual(b.balance, 30)

    def test_sender_has_less_after_transfer(self):
        a, b = make(100), make(0)
        self.impl(a, b, 30)
        self.assertLess(a.balance, 100)

    def test_insufficient_balance_rejected(self):
        a, b = make(10), make(100)
        self.assertFalse(self.impl(a, b, 50))
        self.assertEqual(b.balance, 100)

    def test_negative_amount_rejected(self):
        a, b = make(100), make(50)
        self.assertFalse(self.impl(a, b, -10))
        self.assertEqual(a.balance, 100)

    def test_zero_amount_rejected(self):
        a, b = make(100), make(50)
        self.assertFalse(self.impl(a, b, 0))

    def test_transfer_from_empty_rejected(self):
        a, b = make(0), make(100)
        self.assertFalse(self.impl(a, b, 1))

    def test_large_transfer(self):
        a, b = make(1_000_000), make(0)
        self.assertTrue(self.impl(a, b, 500_000))
        self.assertEqual(b.balance, 500_000)

    def test_multiple_transfers_receiver_accumulates(self):
        a, b = make(1000), make(0)
        self.impl(a, b, 10)
        self.impl(a, b, 10)
        self.impl(a, b, 10)
        self.assertEqual(b.balance, 30)

    def test_receiver_independent_of_sender_state(self):
        a, b = make(200), make(5)
        self.impl(a, b, 50)
        self.assertEqual(b.balance, 55)

    def test_exact_sufficient_balance(self):
        a, b = make(30 + FEE), make(0)
        self.assertTrue(self.impl(a, b, 30))
        self.assertEqual(b.balance, 30)

    def test_return_value_on_success(self):
        a, b = make(100), make(0)
        self.assertTrue(self.impl(a, b, 10))


if __name__ == "__main__":
    import sys
    print("=" * 60)
    print("12 tests against transfer_buggy() — expected: ALL PASS")
    print("=" * 60)
    suite = unittest.TestLoader().loadTestsFromTestCase(TestTransfer)
    runner = unittest.TextTestRunner(verbosity=2, stream=sys.stdout)
    result = runner.run(suite)
    if result.wasSuccessful():
        print("\n All 12 passed — bug is invisible to these tests.")
        print("  Testing proved: these inputs worked.")
        print("  Lean proves:    every input works — or the code doesn't compile.")
    print("=" * 60)
