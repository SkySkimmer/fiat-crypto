Require Import Coq.ZArith.Zpower Coq.ZArith.ZArith.
Require Import Coq.Lists.List.
Require Import Crypto.Util.ListUtil Crypto.Util.CaseUtil Crypto.Util.ZUtil.
Require Import Crypto.ModularArithmetic.PrimeFieldTheorems.
Require Import Crypto.BaseSystem.
Require Import Crypto.ModularArithmetic.PseudoMersenneBaseParams.
Require Import Crypto.ModularArithmetic.ExtendedBaseVector.
Require Import Crypto.Tactics.VerdiTactics.
Require Import Crypto.Util.Notations.
Require Import Crypto.ModularArithmetic.Pow2Base.
Local Open Scope Z_scope.

Section Defs.
  Context `{prm :PseudoMersenneBaseParams} (modulus_multiple : digits).
  Local Notation base := (base_from_limb_widths limb_widths).
  Local Notation "u [ i ]" := (nth_default 0 u i) (at level 40).

  Definition decode (us : digits) : F modulus := ZToField (BaseSystem.decode base us).

  Definition encode (x : F modulus) := encodeZ limb_widths x.

  (* Converts from length of extended base to length of base by reduction modulo M.*)
  Definition reduce (us : digits) : digits :=
    let high := skipn (length limb_widths) us in
    let low := firstn (length limb_widths) us in
    let wrap := map (Z.mul c) high in
    BaseSystem.add low wrap.

  Definition mul (us vs : digits) := reduce (BaseSystem.mul (ext_base limb_widths) us vs).

  (* In order to subtract without underflowing, we add a multiple of the modulus first. *)
  Definition sub (us vs : digits) := BaseSystem.sub (add modulus_multiple us) vs.

  (*
  Definition carry_and_reduce :=
    carry_gen limb_widths (fun ci => c * ci).
   *)
  Definition carry_and_reduce i := fun us =>
    let di := us [i] in
    let us' := set_nth i (Z.pow2_mod di (limb_widths [i]))  us in
    add_to_nth   0  (c * (Z.shiftr   di (limb_widths [i]))) us'.

  Definition carry i : digits -> digits :=
    if eq_nat_dec i (pred (length base))
    then carry_and_reduce i
    else carry_simple limb_widths i.

  Definition modulus_digits := encodeZ limb_widths modulus.

  (* compute at compile time *)
  Definition max_ones := Z.ones (fold_right Z.max 0 limb_widths).

  (* Constant-time comparison with modulus; only works if all digits of [us]
    are less than 2 ^ their respective limb width. *)
  Fixpoint ge_modulus' us acc i :=
    match i with
    | O => andb (Z.ltb (modulus_digits [0]) (us [0])) acc
    | S i' => ge_modulus' us (andb (Z.eqb (modulus_digits [i]) (us [i])) acc) i'
    end.

  Definition ge_modulus us := ge_modulus' us true (length base - 1)%nat.

  Definition conditional_subtract_modulus (us : digits) (cond : bool) :=
     let and_term := if cond then max_ones else 0 in
    (* [and_term] is all ones if us' is full, so the subtractions subtract q overall.
       Otherwise, it's all zeroes, and the subtractions do nothing. *)
     map2 (fun x y => x - y) us (map (Z.land and_term) modulus_digits).

End Defs.