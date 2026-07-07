
-- Task 1: Propositional Logic Proofs in Lean 4

namespace Exercises

variable (A B C D I L M P Q R : Prop)

-- T51: Conjunction Introduction
-- Given P and P → Q, we can prove both P and Q hold together.

theorem T51 (h1 : P) (h2 : P → Q) : P ∧ Q := by
  constructor
  · exact h1        -- Left side: P holds by hypothesis
  · exact h2 h1     -- Right side: Q follows from applying h2 to h1


-- T52: Modus Ponens via Conjunction
-- Build P ∧ Q from Q (using h2) and Q (h3), then apply h1 to get R.

theorem T52 (h1 : P ∧ Q → R) (h2 : Q → P) (h3 : Q) : R := by
  apply h1
  constructor
  · exact h2 h3     -- P from h2 applied to Q
  · exact h3        -- Q from h3


-- T53: Implication Chain with Conjunction
-- Assuming P, derive Q (via h1) and R (via h2 chained), combine them.

theorem T53 (h1 : P → Q) (h2 : Q → R) : P → (Q ∧ R) := by
  intro hp
  constructor
  · exact h1 hp           -- Q from P
  · exact h2 (h1 hp)      -- R from Q from P


-- T54: Weakening (Constant Implication)
-- P is already true, so Q → P holds regardless of Q.

theorem T54 (h1 : P) : Q → P := by
  intro _           -- Assume Q (unused)
  exact h1          -- Return P directly

-- T55: Modus Tollens (Contrapositive)
-- If P → Q and ¬Q, then assuming P leads to contradiction.

theorem T55 (h1 : P → Q) (h2 : ¬Q) : ¬P := by
  intro hp
  exact h2 (h1 hp)  -- ¬Q applied to Q (from P via h1) gives False


-- T56: Argument Permutation
-- Swap the order in which P and Q are assumed.

theorem T56 (h1 : P → (Q → R)) : Q → (P → R) := by
  intro hq hp
  exact h1 hp hq    -- Provide P first, then Q


-- T57: Disjunction Weakening
-- P ∨ (Q ∧ R) → P ∨ Q by projecting Q from the right branch.

theorem T57 (h1 : P ∨ (Q ∧ R)) : P ∨ Q := by
  cases h1 with
  | inl hp  => exact Or.inl hp          -- Already have P
  | inr hqr => exact Or.inr hqr.left    -- Extract Q from Q ∧ R


-- T58: Complex Contradiction
-- Assume L, build L ∧ M, get ¬P, but I → P gives P — contradiction.

theorem T58 (h1 : (L ∧ M) → ¬P) (h2 : I → P) (h3 : M) (h4 : I) : ¬L := by
  intro hl
  exact h1 ⟨hl, h3⟩ (h2 h4)  -- h1(L ∧ M) gives ¬P; h2(I) gives P → False


-- T59: Identity
-- P implies itself — the simplest proof in logic.

theorem T59 : P → P := by
  intro hp
  exact hp

-- T510: Law of Non-Contradiction
-- P ∧ ¬P is always false — a proposition cannot be both true and false.

theorem T510 : ¬ (P ∧ ¬P) := by
  intro h
  exact h.2 h.1     -- Apply ¬P (h.2) to P (h.1) to get False

end Exercises
