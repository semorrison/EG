import EuclideanGeometry.Foundation.Axiom.Linear.Colinear
import EuclideanGeometry.Foundation.Axiom.Linear.Ray
import EuclideanGeometry.Foundation.Axiom.Linear.Ray_ex

noncomputable section
namespace EuclidGeom

section setoid

variable {P : Type _} [EuclideanPlane P]

def same_extn_line : Ray P → Ray P → Prop := fun r r' => r.toProj = r'.toProj ∧ (r'.source LiesOn r ∨ r'.source LiesOn r.reverse)

namespace same_extn_line

theorem dir_eq_or_eq_neg {r r' : Ray P} (h : same_extn_line r r') : (r.toDir = r'.toDir ∨ r.toDir = - r'.toDir) := (Dir.eq_toProj_iff _ _).mp h.1

theorem vec_parallel_of_same_extn_line {r r' : Ray P} (h : same_extn_line r r') : ∃t : ℝ, r'.toDir.toVec = t • r.toDir.toVec := by
  rcases (Dir.eq_toProj_iff _ _).mp h.1 with rr' | rr'
  · use 1
    rw [one_smul, rr']
  · use -1
    rw [rr', Dir.toVec_neg_eq_neg_toVec, smul_neg, neg_smul, one_smul, neg_neg]

protected theorem refl (r : Ray P) : same_extn_line r r := ⟨rfl, Or.inl (Ray.source_lies_on)⟩

protected theorem symm {r r' : Ray P} (h : same_extn_line r r') : same_extn_line r' r := by
  constructor
  · exact h.1.symm
  · have g := dir_eq_or_eq_neg h
    cases g with
    | inl h₁ => sorry
    | inr h₂ => sorry


protected theorem trans {r r' r'' : Ray P} (h₁ : same_extn_line r r') (h₂ : same_extn_line r' r'') : same_extn_line r r'' where
  left := Eq.trans h₁.1 h₂.1
  right := by
    rcases pt_lies_on_line_from_ray_iff_vec_parallel.mp h₁.2 with ⟨a, dr'r⟩
    rcases pt_lies_on_line_from_ray_iff_vec_parallel.mp h₂.2 with ⟨b, dr''r'⟩
    apply pt_lies_on_line_from_ray_iff_vec_parallel.mpr
    let ⟨t, rparr'⟩ := vec_parallel_of_same_extn_line h₁
    use a + b * t
    rw [rparr'] at dr''r'
    rw [(vec_add_vec _ _ _).symm, dr'r, dr''r']
    simp only [Complex.real_smul, Complex.ofReal_mul, Complex.ofReal_add]
    ring_nf

protected def setoid : Setoid (Ray P) where
  r := same_extn_line
  iseqv := {
    refl := same_extn_line.refl
    symm := same_extn_line.symm
    trans := same_extn_line.trans
  }

instance : Setoid (Ray P) := same_extn_line.setoid

end same_extn_line

theorem same_extn_line_of_PM (A : P) (x y : Dir) (h : PM x y) : same_extn_line (Ray.mk A x) (Ray.mk A y) := by
  constructor
  · simp only [Ray.toProj, Dir.eq_toProj_iff', h]
  · exact Or.inl Ray.source_lies_on


theorem same_extn_line.eq_carrier_union_rev_carrier (r r' : Ray P) (h : same_extn_line r r') : r.carrier ∪ r.reverse.carrier = r'.carrier ∪ r'.reverse.carrier := by 
  ext p
  simp only [Set.mem_union, Ray.in_carrier_iff_lies_on, pt_lies_on_line_from_ray_iff_vec_parallel]
  constructor
  · rintro ⟨c, hc⟩
    let ⟨a, ha⟩ := pt_lies_on_line_from_ray_iff_vec_parallel.mp h.symm.2
    let ⟨b, hb⟩ := dir_parallel_of_same_proj h.symm.1
    use a + c * b
    calc
      VEC r'.source p = VEC r'.source r.source + VEC r.source p := (vec_add_vec _ _ _).symm
      _ = a • r'.toDir.toVec + c • r.toDir.toVec := by rw [ha, hc]
      _ = a • r'.toDir.toVec + (c * b) • r'.toDir.toVec := by
        simp only [hb, Complex.real_smul, Complex.ofReal_mul, add_right_inj]
        ring_nf
      _ = (a + c * b) • r'.toDir.toVec := (add_smul _ _ _).symm
  · rintro ⟨c, hc⟩
    let ⟨a, ha⟩ := pt_lies_on_line_from_ray_iff_vec_parallel.mp h.2
    let ⟨b, hb⟩ := dir_parallel_of_same_proj h.1
    use a + c * b
    calc
      VEC r.source p = VEC r.source r'.source + VEC r'.source p := (vec_add_vec _ _ _).symm
      _ = a • r.toDir.toVec + c • r'.toDir.toVec := by rw [ha, hc]
      _ = a • r.toDir.toVec + (c * b) • r.toDir.toVec := by
        simp only [hb, Complex.real_smul, Complex.ofReal_mul, add_right_inj]
        ring_nf
      _ = (a + c * b) • r.toDir.toVec := (add_smul _ _ _).symm

end setoid

def Line (P : Type _) [EuclideanPlane P] := Quotient (@same_extn_line.setoid P _)

variable {P : Type _} [EuclideanPlane P]

section make

namespace Line

-- define a line from two points
def mk_pt_pt (A B : P) (h : B ≠ A) : Line P := ⟦RAY A B h⟧

-- define a line from a point and a proj
def mk_pt_proj (A : P) (proj : Proj) : Line P := Quotient.map (sa := PM.con.toSetoid) (fun x : Dir => Ray.mk A x) (same_extn_line_of_PM A) proj

-- define a line from a point and a direction
def mk_pt_dir (A : P) (dir : Dir) : Line P := mk_pt_proj A dir.toProj

-- define a line from a point and a nondegenerate vector
def mk_pt_vec_nd (A : P) (vec_nd : Vec_nd) : Line P := mk_pt_proj A vec_nd.toProj

end Line

scoped notation "LIN" => Line.mk_pt_pt

end make

section coercion

def Line.toProj (l : Line P) : Proj := Quotient.lift (fun ray : Ray P => ray.toProj) (fun _ _ h => And.left h) l

def Ray.toLine (ray : Ray P) : Line P := ⟦ray⟧

theorem ray_toLine_eq_of_same_extn_line {r₁ r₂ : Ray P} (h : same_extn_line r₁ r₂) : r₁.toLine = r₂.toLine := Quotient.eq.mpr h

theorem ray_rev_of_same_extn_line {r : Ray P} : same_extn_line r r.reverse := by 
  constructor
  · simp [Ray.toProj_of_rev_eq_toProj]
  · right
    apply Ray.source_lies_on

theorem ray_rev_toLine_eq_ray {r : Ray P} : r.toLine = r.reverse.toLine := ray_toLine_eq_of_same_extn_line ray_rev_of_same_extn_line

def Seg_nd.toLine (seg_nd : Seg_nd P) : Line P := ⟦seg_nd.toRay⟧

instance : Coe (Ray P) (Line P) where
  coe := Ray.toLine

section carrier

namespace Line

protected def carrier (l : Line P) : Set P := Quotient.lift (fun ray : Ray P => ray.carrier ∪ ray.reverse.carrier) (same_extn_line.eq_carrier_union_rev_carrier) l

/- Def of point lies on a line, LiesInt is not defined -/
protected def IsOn (A : P) (l : Line P) : Prop :=
  A ∈ l.carrier

instance : Carrier P (Line P) where
  carrier := fun l => l.carrier

end Line

theorem Ray.toLine_carrier_eq_ray_carrier_union_rev_carrier (r : Ray P) : r.toLine.carrier = r.carrier ∪ r.reverse.carrier := rfl

theorem Ray.subset_toLine {r : Ray P} : r.carrier ⊆ r.toLine.carrier := by
  rw [toLine_carrier_eq_ray_carrier_union_rev_carrier]
  exact Set.subset_union_left _ _

namespace Line

theorem ray_subset_line {r : Ray P} {l : Line P} (h : r.toLine = l) : r.carrier ⊆ l.carrier := by
  rw [← h]
  exact r.subset_toLine

theorem seg_lies_on_Line {s : Seg_nd P}{A : P}(h : A LiesOn s.1) : A LiesOn s.toLine := by 
  have g : A ∈ s.toRay.carrier := Seg_nd.lies_on_toRay_of_lies_on h
  have h : s.toRay.toLine = s.toLine := rfl
  apply Set.mem_of_subset_of_mem (ray_subset_line h) g

theorem seg_subset_line {s : Seg_nd P} {l : Line P} (h : s.toLine = l) : s.1.carrier ⊆ l.carrier := by
  intro A Ain
  rw [← h]
  apply seg_lies_on_Line Ain

theorem pt_pt_lies_on_iff_seg_toLine {A B : P}{l : Line P}(h : B ≠ A) : A LiesOn l ∧ B LiesOn l  ↔ (Seg_nd.mk A B h).toLine = l := by 
  constructor
  · sorry
  · intro hl
    constructor
    · rw [← hl]
      apply seg_lies_on_Line Seg.source_lies_on 
    · rw [← hl]
      apply seg_lies_on_Line Seg.target_lies_on
  

theorem linear {l : Line P} {A B C : P} (h₁ : A LiesOn l) (h₂ : B LiesOn l) (h₃ : C LiesOn l) : colinear A B C := by
  unfold Line at l
  revert l
  rw [Quotient.forall (p := fun k : Line P => A LiesOn k → B LiesOn k → C LiesOn k → colinear A B C)]
  unfold lies_on instCarrierLine Carrier.carrier Line.carrier at *
  simp only
  intro ray a b c
  rw [@Quotient.lift_mk _ _ same_extn_line.setoid _ _ _] at *
  cases a with
  | inl a =>
    cases b with
    | inl b =>
      cases c with
      | inl c =>
        exact Ray.colinear_of_lies_on a b c
      | inr c =>
        let ray' := Ray.mk C ray.toDir
        have a' : A ∈ ray'.carrier := lies_on_pt_toDir_of_pt_lies_on_rev a c
        have b' : B ∈ ray'.carrier := lies_on_pt_toDir_of_pt_lies_on_rev b c
        exact Ray.colinear_of_lies_on a' b' (Ray.source_lies_on)
    | inr b =>
      cases c with
      | inl c => sorry
      | inr c => sorry
  | inr a =>
    cases b with
    | inl b =>
      cases c with
      | inl c => sorry
      | inr c => sorry
    | inr b =>
      cases c with
      | inl c => sorry
      | inr c => sorry

theorem maximal' {l : Line P} {A B : P} (h₁ : A LiesOn l) (h₂ : B LiesOn l) (h : B ≠ A) : (∀ (C : P), colinear A B C → (C LiesOn l)) := by 
  intro C Co
  sorry

theorem nontriv (l : Line P) : ∃ (A B : P), (A ∈ l.carrier) ∧ (B ∈ l.carrier) ∧ (B ≠ A) := by
  let ⟨r, h⟩ := l.exists_rep
  rcases r.nontriv with ⟨A, B, g⟩
  have : r.carrier ⊆ l.carrier := ray_subset_line h
  exact ⟨A, B, ⟨this g.1, this g.2.1, g.2.2⟩⟩

end Line

-- A point lies on a line associated to a ray if and only if it lies on the ray or the reverse of the ray

theorem Ray.lies_on_toLine_iff_lies_on_or_lies_on_rev (A : P) (r : Ray P) : (A LiesOn r.toLine) ↔ (A LiesOn r) ∨ (A LiesOn r.reverse) := by
  simp only [lies_on]
  rw [← Set.mem_union]
  revert A
  rw [← Set.ext_iff]
  exact Ray.toLine_carrier_eq_ray_carrier_union_rev_carrier r

theorem Ray.in_toLine_iff_in_or_in_rev {r : Ray P}{A : P} : (A ∈ r.toLine.carrier) ↔ ((A ∈ r.carrier) ∨ (A ∈ r.reverse.carrier)) := by rfl

theorem Line.in_carrier_iff_lies_on {l : Line P}{A : P} : A LiesOn l ↔ A ∈ l.carrier := by rfl
  
theorem Ray.lies_on_toLine_iff_lies_int_or_lies_int_rev_or_eq_source (A : P) (r : Ray P) : (A LiesOn r.toLine) ↔ (A LiesInt r) ∨ (A LiesInt r.reverse) ∨ (A = r.source) := by
  rw [Ray.lies_int_def, Ray.lies_int_def, Ray.source_of_rev_eq_source]
  have : A LiesOn r ∧ A ≠ r.source ∨ A LiesOn r.reverse ∧ A ≠ r.source ∨ A = r.source ↔ A LiesOn r ∨ A LiesOn r.reverse := by 
    constructor
    · exact fun
      | .inl h => Or.inl h.1
      | .inr h => by
        rcases h with h | h
        · exact Or.inr h.1
        · right
          rw [h]
          exact Ray.source_lies_on
    · exact fun
      | .inl h => by
        by_cases g : A = source
        · exact Or.inr (Or.inr g)
        · exact Or.inl ⟨h, g⟩
      | .inr h => by
        by_cases g : A = source
        · exact Or.inr (Or.inr g)
        · exact Or.inr (Or.inl ⟨h, g⟩)
  rw [this, Ray.lies_on_toLine_iff_lies_on_or_lies_on_rev]

end carrier

namespace Line

theorem maximal {l : Line P} {A B : P} (h₁ : A ∈ l.carrier) (h₂ : B ∈ l.carrier) (h : B ≠ A) : (∀ (C : P), colinear A B C → (C ∈ l.carrier)) := by 
  intro C Co
  have hl : C LiesOn l := by
    apply maximal' _ _ h C Co  
    · apply Line.in_carrier_iff_lies_on.mpr h₁
    · apply Line.in_carrier_iff_lies_on.mpr h₂
  exact Line.in_carrier_iff_lies_on.mp hl
    
end Line

end coercion

end EuclidGeom