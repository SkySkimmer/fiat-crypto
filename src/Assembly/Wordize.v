
Require Export Bedrock.Word Bedrock.Nomega.
Require Import NArith PArith Ndigits Nnat NPow NPeano Ndec.
Require Import Compare_dec Omega.
Require Import FunctionalExtensionality ProofIrrelevance.
Require Import QhasmUtil QhasmEvalCommon.
Require Import WordizeUtil.

Hint Rewrite wordToN_nat Nat2N.inj_add N2Nat.inj_add
             Nat2N.inj_mul N2Nat.inj_mul Npow2_nat : N.

Open Scope nword_scope.

Section Wordization.
  Lemma wordize_plus': forall {n} (x y: word n) (b: N),
      (b <= Npow2 n)%N
    -> (&x < b)%N
    -> (&y < (Npow2 n - b))%N
    -> (&x + &y)%N = & (x ^+ y).
  Proof.
    intros.
    unfold wplus, wordBin.
    rewrite wordToN_NToWord; intuition.
    apply (N.lt_le_trans _ (b + &y)%N _).

    - apply N.add_lt_le_mono; try assumption; intuition.

    - replace (Npow2 n) with (b + Npow2 n - b)%N by nomega.
        replace (b + Npow2 n - b)%N with (b + (Npow2 n - b))%N by (
        replace (b + (Npow2 n - b))%N with ((Npow2 n - b) + b)%N by nomega;
        rewrite (N.sub_add b (Npow2 n)) by assumption;
        nomega).

        apply N.add_le_mono_l; try nomega.
        apply N.lt_le_incl; assumption.
  Qed.

  Lemma wordize_plus: forall {n} (x y: word n),
    if (overflows n (&x + &y)%N)
    then (&x + &y)%N = (& (x ^+ y) + Npow2 n)%N
    else (&x + &y)%N = & (x ^+ y).
  Proof. Admitted.

  Lemma wordize_awc: forall {n} (x y: word n) (c: bool),
    if (overflows n (&x + &y + (if c then 1 else 0))%N)
    then (&x + &y + (if c then 1 else 0))%N = (&(addWithCarry x y c) + Npow2 n)%N
    else (&x + &y + (if c then 1 else 0))%N = &(addWithCarry x y c).
  Proof. Admitted.

  Lemma wordize_mult': forall {n} (x y: word n) (b: N),
      (1 < n)%nat -> (0 < b)%N
    -> (&x < b)%N
    -> (&y < (Npow2 n) / b)%N
    -> (&x * &y)%N = & (x ^* y).
  Proof.
    intros; unfold wmult, wordBin.
    rewrite wordToN_NToWord; intuition.
    apply (N.lt_le_trans _ (b * ((Npow2 n) / b))%N _).

    - apply N.mul_lt_mono; assumption.

    - apply N.mul_div_le; nomega.
  Qed.

  Lemma wordize_mult: forall {n} (x y: word n) (b: N),
    (&x * &y)%N = (&(x ^* y) +
      &((EvalUtil.highBits (n/2) x) ^* (EvalUtil.highBits (n/2) y)) * Npow2 n)%N.
  Proof. intros. Admitted.

  Lemma wordize_and: forall {n} (x y: word n),
    N.land (&x) (&y) = & (x ^& y).
  Proof.
    intros; pose proof (Npow2_gt0 n).
    pose proof (word_size_bound x).
    pose proof (word_size_bound y).

    induction n.

    - rewrite (shatter_word_0 x) in *.
        rewrite (shatter_word_0 y) in *.
        simpl; intuition.

    - rewrite (shatter_word x) in *.
        rewrite (shatter_word y) in *.
        induction (whd x), (whd y).

        + admit.
        + admit.
        + admit.
        + admit.
  Admitted.

  Lemma wordize_shiftr: forall {n} (x: word n) (k: nat),
    (N.shiftr_nat (&x) k) = & (shiftr x k).
  Proof. Admitted.

End Wordization.

Section Bounds.

  Theorem constant_bound_N : forall {n} (k: word n),
    (& k < & k + 1)%N.
  Proof. intros; nomega. Qed.

  Theorem constant_bound_nat : forall (n k: nat),
      (N.of_nat k < Npow2 n)%N
    -> (& (@natToWord n k) < (N.of_nat k) + 1)%N.
  Proof.
    intros.
    rewrite wordToN_nat.
    rewrite wordToNat_natToWord_idempotent;
      try assumption; nomega.
  Qed.

  Lemma let_bound : forall {n} (x: word n) (f: word n -> word n) xb fb,
      (& x < xb)%N
    -> (forall x', & x' < xb -> & (f x') < fb)%N
    -> ((let k := x in &(f k)) < fb)%N.
  Proof. intros; eauto. Qed.

  Definition Nlt_dec (x y: N): {(x < y)%N} + {(x >= y)%N}.
    refine (
      let c := N.compare x y in
      match c as c' return c = c' -> _ with
      | Lt => fun _ => left _
      | _ => fun _ => right _
      end eq_refl);
    abstract (
      unfold c, N.ge, N.lt in *; intuition; subst;
      match goal with
      | [H0: ?x = _, H1: ?x = _ |- _] =>
        rewrite H0 in H1; inversion H1
      end).
  Defined.

  Theorem wplus_bound : forall {n} (w1 w2 : word n) b1 b2,
      (&w1 < b1)%N
    -> (&w2 < b2)%N
    -> (&(w1 ^+ w2) < b1 + b2)%N.
  Proof.
    intros.

    destruct (Nlt_dec (b1 + b2)%N (Npow2 n));
      rewrite <- wordize_plus' with (b := b1);
      try apply N.add_lt_mono;
      try assumption.

    (* A couple inequality subgoals *)
  Admitted.

  Theorem wmult_bound : forall {n} (w1 w2 : word n) b1 b2,
      (1 < n)%nat
    -> (&w1 < b1)%N
    -> (&w2 < b2)%N
    -> (&(w1 ^* w2) < b1 * b2)%N.
  Proof.
    intros.
    destruct (Nlt_dec (b1 * b2)%N (Npow2 n));
      rewrite <- wordize_mult' with (b := b1);
      try apply N.mul_lt_mono;
      try assumption;
      try nomega.

    (* A couple inequality subgoals *)
  Admitted.

  Theorem shiftr_bound : forall {n} (w : word n) b bits,
      (&w < b)%N
    -> (&(shiftr w bits) < N.succ (N.shiftr_nat b bits))%N.
  Proof.
    intros.
    assert (& shiftr w bits <= N.shiftr_nat b bits)%N. {
      rewrite <- wordize_shiftr.
      induction bits; unfold N.shiftr_nat in *; simpl; intuition.

      - unfold N.le, N.lt in *; rewrite H; intuition; inversion H0.

      - revert IHbits;

       admit. (* Monotonicity of N.div2 *)
    }

    apply N.le_lteq in H0; destruct H0; nomega.
  Admitted.

  Theorem mask_bound : forall {n} (w : word n) m,
    (n > 1)%nat ->
    (&(mask m w) < Npow2 m)%N.
  Proof.
    intros.
    unfold mask in *; destruct (le_dec m n); simpl;
      try apply extend_bound.

    pose proof (word_size_bound w).
    apply (N.le_lt_trans _ (Npow2 n) _).

    - unfold N.le, N.lt in *; rewrite H0; intuition; inversion H1.

    - clear H H0.
      replace m with ((m - n) + n) by nomega.
      replace (Npow2 n) with (1 * (Npow2 n))%N
        by (rewrite N.mul_comm; nomega).
      rewrite Npow2_split.
      apply N.mul_lt_mono_pos_r.

      + apply Npow2_gt0.

      + assert (0 < m - n)%nat by omega.
        induction (m - n); try inversion H; try abstract (
          simpl; replace 2 with (S 1) by omega;
          apply N.lt_1_2).

        assert (0 < n1)%nat as Z by omega; apply IHn1 in Z.
        apply (N.le_lt_trans _ (Npow2 n1) _).

        * admit.
        * admit.
  Admitted.

  Theorem mask_update_bound : forall {n} (w : word n) b m,
      (n > 1)%nat
    -> (&w < b)%N
    -> (&(mask m w) < (N.min b (Npow2 m)))%N.
  Proof.
    intros; unfold mask, N.min;
      destruct (le_dec m n),
               (N.compare b (Npow2 m));
      simpl; try assumption.

  Admitted.

End Bounds.

(** Wordization Tactics **)

Ltac wordize_ast :=
  repeat match goal with
  | [ H: (& ?x < ?b)%N |- context[((& ?x) + (& ?y))%N] ] => rewrite (wordize_plus' x y b)
  | [ H: (& ?x < ?b)%N |- context[((& ?x) * (& ?y))%N] ] => rewrite (wordize_mult' x y b)
  | [ |- context[N.land (& ?x) (& ?y)] ] => rewrite (wordize_and x y)
  | [ |- context[N.shiftr (& ?x) ?k] ] => rewrite (wordize_shiftr x k)
  | [ |- (_ < _ / _)%N ] => unfold N.div; simpl
  | [ |- context[Npow2 _] ] => simpl
  | [ |- (?x < ?c)%N ] => assumption
  | [ |- _ = _ ] => reflexivity
  end.

Ltac lt_crush := try abstract (clear; vm_compute; intuition).

(** Bounding Tactics **)

Ltac multi_apply0 A L := pose proof (L A).

Ltac multi_apply1 A L :=
  match goal with
  | [ H: A < ?b |- _] => pose proof (L A b H)
  end.

Ltac multi_apply2 A B L :=
  match goal with
  | [ H1: A < ?b1, H2: B < ?b2 |- _] => pose proof (L A B b1 b2 H1 H2)
  end.

Ltac multi_recurse n T :=
  match goal with
  | [ H: (T < _)%N |- _] => idtac
  | _ =>
    is_var T;
    let T' := (eval cbv delta [T] in T) in multi_recurse n T';
    match goal with
    | [ H : T' < ?x |- _ ] =>
      pose proof (H : T < x)
    end

  | _ =>
    match T with
    | ?W1 ^+ ?W2 =>
      multi_recurse n W1; multi_recurse n W2;
      multi_apply2 W1 W2 (@wplus_bound n)

    | ?W1 ^* ?W2 =>
      multi_recurse n W1; multi_recurse n W2;
      multi_apply2 W1 W2 (@wmult_bound n)

    | mask ?m ?w =>
      multi_recurse n w;
      multi_apply1 w (fun b => @mask_update_bound n w b)

    | mask ?m ?w =>
      multi_recurse n w;
      pose proof (@mask_bound n w m)

    | ?x ^& (@NToWord _ (N.ones ?m)) =>
      multi_recurse n (mask (N.to_nat m) x);
      match goal with
      | [ H: (& (mask (N.to_nat m) x) < ?b)%N |- _] =>
        pose proof (@mask_wand n x m b H)
      end

    | shiftr ?w ?bits =>
      multi_recurse n w;
      match goal with
      | [ H: (w < ?b)%N |- _] =>
        pose proof (@shiftr_bound n w b bits H)
      end

    | NToWord _ ?k => pose proof (@constant_bound_N n k)
    | natToWord _ ?k => pose proof (@constant_bound_nat n k)
    | _ => pose proof (@word_size_bound n T)
    end
  end.

Lemma unwrap_let: forall {n} (y: word n) (f: word n -> word n) (b: N),
    (&(let x := y in f x) < b)%N <-> let x := y in (&(f x) < b)%N.
Proof. intuition. Qed.

Ltac multi_bound n :=
  match goal with
  | [|- let A := ?B in _] =>
    multi_recurse n B; intro; multi_bound n
  | [|- ((let A := _ in _) < _)%N] =>
    apply unwrap_let; multi_bound n
  | [|- (?W < _)%N ] =>
    multi_recurse n W
  end.

(** Examples **)

Module WordizationExamples.

  Lemma wordize_example0: forall (x y z: word 16),
    (wordToN x < 10)%N ->
    (wordToN y < 10)%N ->
    (wordToN z < 10)%N ->
    & (x ^* y) = (&x * &y)%N.
  Proof.
    intros.
    wordize_ast; lt_crush.
    transitivity 10%N; try assumption; lt_crush.
  Qed.

End WordizationExamples.

Close Scope nword_scope.
