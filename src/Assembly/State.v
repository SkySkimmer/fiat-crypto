Require Export Coq.Strings.String Coq.Lists.List Coq.Init.Logic.
Require Export Bedrock.Word.

Require Import Coq.ZArith.ZArith Coq.NArith.NArith Coq.Numbers.Natural.Peano.NPeano Coq.NArith.Ndec.
Require Import Coq.Arith.Compare_dec Coq.omega.Omega.
Require Import Coq.Structures.OrderedType Coq.Structures.OrderedTypeEx.
Require Import Coq.FSets.FMapPositive Coq.FSets.FMapFullAVL Coq.Logic.JMeq.

Require Import Crypto.Assembly.QhasmUtil Crypto.Assembly.QhasmCommon.

Require Export Crypto.Util.FixCoqMistakes.

(* We want to use pairs and triples as map keys: *)

Module Pair_as_OT <: UsualOrderedType.
  Definition t := (nat * nat)%type.

  Definition eq := @eq t.
  Definition eq_refl := @eq_refl t.
  Definition eq_sym := @eq_sym t.
  Definition eq_trans := @eq_trans t.

  Definition lt (a b: t) :=
    if (Nat.eq_dec (fst a) (fst b))
    then lt (snd a) (snd b)
    else lt (fst a) (fst b).

  Lemma conv: forall {x0 x1 y0 y1: nat},
    (x0 = y0 /\ x1 = y1) <-> (x0, x1) = (y0, y1).
  Proof.
    intros; split; intros.
  - destruct H; destruct H0; subst; intuition.
  - inversion_clear H; intuition.
  Qed.

  Lemma lt_trans : forall x y z : t, lt x y -> lt y z -> lt x z.
    intros; destruct x as [x0 x1], y as [y0 y1], z as [z0 z1];
      unfold lt in *; simpl in *;
      destruct (Nat.eq_dec x0 y0), (Nat.eq_dec y0 z0), (Nat.eq_dec x0 z0);
      omega.
  Qed.

  Lemma lt_not_eq : forall x y : t, lt x y -> ~ eq x y.
    intros; destruct x as [x0 x1], y as [y0 y1];
      unfold lt, eq in *; simpl in *;
      destruct (Nat.eq_dec x0 y0); subst; intuition;
      inversion H0; subst; omega.
  Qed.

  Definition compare x y : Compare lt eq x y.
    destruct x as [x0 x1], y as [y0 y1];
      destruct (Nat_as_OT.compare x0 y0);
      unfold Nat_as_OT.lt, Nat_as_OT.eq in *.

    - apply LT; abstract (unfold lt; simpl; destruct (Nat.eq_dec x0 y0); intuition auto with zarith).

    - destruct (Nat_as_OT.compare x1 y1);
        unfold Nat_as_OT.lt, Nat_as_OT.eq in *.

      + apply LT; abstract (unfold lt; simpl; destruct (Nat.eq_dec x0 y0); intuition).
      + apply EQ; abstract (unfold lt; simpl; subst; intuition auto with relations).
      + apply GT; abstract (unfold lt; simpl; destruct (Nat.eq_dec y0 x0); intuition auto with zarith).

    - apply GT; abstract (unfold lt; simpl; destruct (Nat.eq_dec y0 x0); intuition auto with zarith).
  Defined.

  Definition eq_dec (a b: t): {a = b} + {a <> b}.
    destruct (compare a b);
      destruct a as [a0 a1], b as [b0 b1].

    - right; abstract (
        unfold lt in *; simpl in *;
        destruct (Nat.eq_dec a0 b0); intuition;
        inversion H; intuition auto with zarith).

    - left; abstract (inversion e; intuition).

    - right; abstract (
        unfold lt in *; simpl in *;
        destruct (Nat.eq_dec b0 a0); intuition;
        inversion H; intuition auto with zarith).
  Defined.
End Pair_as_OT.

Module Triple_as_OT <: UsualOrderedType.
  Definition t := (nat * nat * nat)%type.

  Definition get0 (x: t) := fst (fst x).
  Definition get1 (x: t) := snd (fst x).
  Definition get2 (x: t) := snd x.

  Definition eq := @eq t.
  Definition eq_refl := @eq_refl t.
  Definition eq_sym := @eq_sym t.
  Definition eq_trans := @eq_trans t.

  Definition lt (a b: t) :=
    if (Nat.eq_dec (get0 a) (get0 b))
    then
      if (Nat.eq_dec (get1 a) (get1 b))
      then lt (get2 a) (get2 b)
      else lt (get1 a) (get1 b)
    else lt (get0 a) (get0 b).

  Lemma conv: forall {x0 x1 x2 y0 y1 y2: nat},
      (x0 = y0 /\ x1 = y1 /\ x2 = y2) <-> (x0, x1, x2) = (y0, y1, y2).
  Proof.
    intros; split; intros.
    - destruct H; destruct H0; subst; intuition.
    - inversion_clear H; intuition.
  Qed.

  Lemma lt_trans : forall x y z : t, lt x y -> lt y z -> lt x z.
    intros; unfold lt in *;
    destruct (Nat.eq_dec (get0 x) (get0 y)),
             (Nat.eq_dec (get1 x) (get1 y)),
             (Nat.eq_dec (get0 y) (get0 z)),
             (Nat.eq_dec (get1 y) (get1 z)),
             (Nat.eq_dec (get0 x) (get0 z)),
             (Nat.eq_dec (get1 x) (get1 z));
      omega.
  Qed.

  Lemma lt_not_eq : forall x y : t, lt x y -> ~ eq x y.
    intros; unfold lt, eq in *;
      destruct (Nat.eq_dec (get0 x) (get0 y)),
               (Nat.eq_dec (get1 x) (get1 y));
      subst; intuition;
      inversion H0; subst; omega.
  Qed.

  Ltac compare_tmp x y :=
    abstract (
      unfold Nat_as_OT.lt, Nat_as_OT.eq, lt, eq in *;
      destruct (Nat.eq_dec (get0 x) (get0 y));
      destruct (Nat.eq_dec (get1 x) (get1 y));
      simpl; intuition auto with zarith).

  Ltac compare_eq x y :=
    abstract (
      unfold Nat_as_OT.lt, Nat_as_OT.eq, lt, eq, get0, get1 in *;
      destruct x as [x x2], y as [y y2];
      destruct x as [x0 x1], y as [y0 y1];
      simpl in *; subst; intuition).

  Definition compare x y : Compare lt eq x y.
    destruct (Nat_as_OT.compare (get0 x) (get0 y)).

    - apply LT; compare_tmp x y.
    - destruct (Nat_as_OT.compare (get1 x) (get1 y)).
      + apply LT; compare_tmp x y.
      + destruct (Nat_as_OT.compare (get2 x) (get2 y)).
        * apply LT; compare_tmp x y.
        * apply EQ; compare_eq x y.
        * apply GT; compare_tmp y x.
      + apply GT; compare_tmp y x.
    - apply GT; compare_tmp y x.
  Defined.

  Definition eq_dec (a b: t): {a = b} + {a <> b}.
    destruct (compare a b);
      destruct a as [a a2], b as [b b2];
      destruct a as [a0 a1], b as [b0 b1].

    - right; abstract (
        unfold lt, get0, get1, get2 in *; simpl in *;
        destruct (Nat.eq_dec a0 b0), (Nat.eq_dec a1 b1);
        intuition; inversion H; intuition auto with zarith).

    - left; abstract (inversion e; intuition).

    - right; abstract (
        unfold lt, get0, get1, get2 in *; simpl in *;
        destruct (Nat.eq_dec b0 a0), (Nat.eq_dec b1 a1);
        intuition; inversion H; intuition auto with zarith).
  Defined.
End Triple_as_OT.

Module StateCommon.
  Export ListNotations.

  Module NatM := FMapFullAVL.Make(Nat_as_OT).
  Module PairM := FMapFullAVL.Make(Pair_as_OT).
  Module TripleM := FMapFullAVL.Make(Triple_as_OT).

  Definition NatNMap: Type := NatM.t N.
  Definition PairNMap: Type := PairM.t N.
  Definition TripleNMap: Type := TripleM.t N.
  Definition LabelMap: Type := NatM.t nat.
End StateCommon.

Module ListState.
  Export StateCommon.

  Definition ListState (n: nat) := ((list (word n)) * TripleNMap * (option bool))%type.

  Definition emptyState {n}: ListState n := ([], TripleM.empty N, None).

  Definition getVar {n: nat} (name: nat) (st: ListState n): option (word n) :=
    nth_error (fst (fst st)) name.

  Definition getList {n: nat} (st: ListState n): list (word n) :=
    fst (fst st).

  Definition setList {n: nat} (lst: list (word n)) (st: ListState n): ListState n :=
    (lst, snd (fst st), snd st).

  Definition getMem {n: nat} (name index: nat) (st: ListState n): option (word n) :=
    omap (TripleM.find (n, name, index) (snd (fst st))) (fun v => Some (NToWord n v)).

  Definition setMem {n: nat} (name index: nat) (v: word n) (st: ListState n): ListState n :=
    (fst (fst st), TripleM.add (n, name, index) (wordToN v) (snd (fst st)), snd st).

  Definition getCarry {n: nat} (st: ListState n): option bool := (snd st).

  Definition setCarry {n: nat} (v: bool) (st: ListState n): ListState n :=
    (fst st, Some v).

  Definition setCarryOpt {n: nat} (v: option bool) (st: ListState n): ListState n :=
    match v with
    | Some v' => (fst st, v)
    | None => st
    end.

End ListState.

Module FullState.
  Export StateCommon.

  (* The Big Definition *)

  Inductive State :=
    | fullState (regState: PairNMap)
                (stackState: PairNMap)
                (memState: TripleNMap)
                (retState: list nat)
                (carry: Carry): State.

  Definition emptyState: State :=
    fullState (PairM.empty N) (PairM.empty N) (TripleM.empty N) [] None.

  (* Register *)

  Definition getReg {n} (r: Reg n) (state: State): option (word n) :=
    match state with
    | fullState regS _ _ _ _ =>
      match (PairM.find (n, regName r) regS) with
      | Some v => Some (NToWord n v)
      | None => None
      end
    end.

  Definition setReg {n} (r: Reg n) (value: word n) (state: State): State :=
    match state with
    | fullState regS stackS memS retS carry =>
      fullState (PairM.add (n, regName r) (wordToN value) regS)
                stackS memS retS carry
    end.

  (* Stack *)

  Definition getStack {n} (s: Stack n) (state: State): option (word n) :=
    match state with
    | fullState _ stackS _ _ _ =>
      match (PairM.find (n, stackName s) stackS) with
      | Some v => Some (NToWord n v)
      | None => None
      end
    end.

  Definition setStack {n} (s: Stack n) (value: word n) (state: State): State :=
    match state with
    | fullState regS stackS memS retS carry =>
      fullState regS
                (PairM.add (n, stackName s) (wordToN value) stackS)
                memS retS carry
    end.

  (* Memory *)

  Definition getMem {n m} (x: Mem n m) (i: Index m) (state: State): option (word n) :=
    match state with
    | fullState _ _ memS _ _ =>
      match (TripleM.find (n, memName x, proj1_sig i) memS) with
      | Some v => Some (NToWord n v)
      | None => None
      end
    end.

  Definition setMem {n m} (x: Mem n m) (i: Index m) (value: word n) (state: State): State :=
    match state with
    | fullState regS stackS memS retS carry =>
      fullState regS stackS
                (TripleM.add (n, memName x, proj1_sig i) (wordToN value) memS)
                retS carry
    end.

  (* Return Pointers *)

  Definition pushRet (x: nat) (state: State): State :=
    match state with
    | fullState regS stackS memS retS carry =>
      fullState regS stackS memS (cons x retS) carry
    end.

  Definition popRet (state: State): option (State * nat) :=
    match state with
    | fullState regS stackS memS [] carry => None
    | fullState regS stackS memS (r :: rs) carry =>
      Some (fullState regS stackS memS rs carry, r)
    end.

  (* Carry State Manipulations *)

  Definition getCarry (state: State): Carry :=
    match state with
    | fullState _ _ _ _ b => b
    end.

  Definition setCarry (value: bool) (state: State): State :=
    match state with
    | fullState regS stackS memS retS carry =>
      fullState regS stackS memS retS (Some value)
    end.

  Definition setCarryOpt (value: option bool) (state: State): State :=
    match value with
    | Some c' => setCarry c' state
    | _ => state
    end.
End FullState.
