"""
Comprehensive Unit Tests for Bank Transfer System

Tests cover normal operations, edge cases, and invalid inputs.
"""

import unittest
from python_impl import Account, transfer


class TestBankTransfer(unittest.TestCase):
    
    def test_valid_transfer_basic(self):
        """Standard transfer between accounts"""
        alice = Account(100)
        bob = Account(50)
        total_before = alice.balance + bob.balance
        
        result = transfer(alice, bob, 30)
        
        self.assertTrue(result)
        self.assertEqual(alice.balance, 70)
        self.assertEqual(bob.balance, 80)
        self.assertEqual(alice.balance + bob.balance, total_before)
    
    def test_transfer_entire_balance(self):
        """Transfer exact balance (boundary case)"""
        alice = Account(100)
        bob = Account(0)
        
        result = transfer(alice, bob, 100)
        
        self.assertTrue(result)
        self.assertEqual(alice.balance, 0)
        self.assertEqual(bob.balance, 100)
    
    def test_insufficient_balance(self):
        """Transfer with insufficient funds should fail"""
        alice = Account(50)
        bob = Account(100)
        
        result = transfer(alice, bob, 75)
        
        self.assertFalse(result)
        self.assertEqual(alice.balance, 50)
        self.assertEqual(bob.balance, 100)
    
    def test_negative_amount(self):
        """Negative amount should be rejected"""
        alice = Account(100)
        bob = Account(50)
        
        result = transfer(alice, bob, -20)
        
        self.assertFalse(result)
        self.assertEqual(alice.balance, 100)
        self.assertEqual(bob.balance, 50)
    
    def test_zero_amount(self):
        """Zero transfer should succeed but change nothing"""
        alice = Account(100)
        bob = Account(50)
        
        result = transfer(alice, bob, 0)
        
        self.assertTrue(result)
        self.assertEqual(alice.balance, 100)
        self.assertEqual(bob.balance, 50)
    
    def test_large_balances(self):
        """System handles large values correctly"""
        alice = Account(1_000_000)
        bob = Account(500_000)
        total_before = alice.balance + bob.balance
        
        result = transfer(alice, bob, 250_000)
        
        self.assertTrue(result)
        self.assertEqual(alice.balance + bob.balance, total_before)
    
    def test_money_conservation_multiple(self):
        """Money conserved across multiple transfers"""
        alice = Account(100)
        bob = Account(50)
        charlie = Account(25)
        total_before = alice.balance + bob.balance + charlie.balance
        
        transfer(alice, bob, 20)
        transfer(bob, charlie, 30)
        transfer(charlie, alice, 10)
        
        total_after = alice.balance + bob.balance + charlie.balance
        self.assertEqual(total_before, total_after)
    
    def test_self_transfer(self):
        """Transfer to same account"""
        alice = Account(100)
        
        result = transfer(alice, alice, 50)
        
        self.assertTrue(result)
        self.assertEqual(alice.balance, 100)
    
    def test_transfer_to_empty(self):
        """Transfer to zero-balance account"""
        alice = Account(100)
        bob = Account(0)
        
        result = transfer(alice, bob, 50)
        
        self.assertTrue(result)
        self.assertEqual(alice.balance, 50)
        self.assertEqual(bob.balance, 50)
    
    def test_transfer_from_empty(self):
        """Cannot transfer from zero-balance account"""
        alice = Account(0)
        bob = Account(100)
        
        result = transfer(alice, bob, 50)
        
        self.assertFalse(result)
        self.assertEqual(alice.balance, 0)
        self.assertEqual(bob.balance, 100)
    
    def test_boundary_exact_balance(self):
        """Amount equals balance exactly"""
        alice = Account(75)
        bob = Account(25)
        
        result = transfer(alice, bob, 75)
        
        self.assertTrue(result)
        self.assertEqual(alice.balance, 0)
        self.assertEqual(bob.balance, 100)
    
    def test_boundary_one_over(self):
        """Amount is one more than balance"""
        alice = Account(75)
        bob = Account(25)
        
        result = transfer(alice, bob, 76)
        
        self.assertFalse(result)
        self.assertEqual(alice.balance, 75)
        self.assertEqual(bob.balance, 25)


if __name__ == "__main__":
    print("Running comprehensive test suite...")
    print("=" * 60)
    unittest.main(verbosity=2)
