-- Task 1: Propositional Logic Proofs in Lean 4

namespace Exercises

variable (A B C D I L M P Q R : Prop)

theorem T51 (h1 : P) (h2 : P → Q) : P ∧ Q := by
  constructor
  · exact h1
  · exact h2 h1

theorem T52 (h1 : P ∧ Q → R) (h2 : Q → P) (h3 : Q) : R := by
  apply h1
  constructor
  · exact h2 h3
  · exact h3

theorem T53 (h1 : P → Q) (h2 : Q → R) : P → (Q ∧ R) := by
  intro hp
  constructor
  · exact h1 hp
  · exact h2 (h1 hp)

theorem T54 (h1 : P) : Q → P := by
  intro _
  exact h1

theorem T55 (h1 : P → Q) (h2 : ¬Q) : ¬P := by
  intro hp
  exact h2 (h1 hp)

theorem T56 (h1 : P → (Q → R)) : Q → (P → R) := by
  intro hq hp
  exact h1 hp hq

theorem T57 (h1 : P ∨ (Q ∧ R)) : P ∨ Q := by
  cases h1 with
  | inl hp  => exact Or.inl hp
  | inr hqr => exact Or.inr hqr.left

theorem T58 (h1 : (L ∧ M) → ¬P) (h2 : I → P) (h3 : M) (h4 : I) : ¬L := by
  intro hl
  exact h1 ⟨hl, h3⟩ (h2 h4)

theorem T59 : P → P := by
  intro hp
  exact hp

theorem T510 : ¬ (P ∧ ¬P) := by
  intro h
  exact h.2 h.1

end Exercises
