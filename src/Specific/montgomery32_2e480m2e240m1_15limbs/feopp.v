Require Import Crypto.Arithmetic.PrimeFieldTheorems.
Require Import Crypto.Specific.montgomery32_2e480m2e240m1_15limbs.Synthesis.

(* TODO : change this to field once field isomorphism happens *)
Definition opp :
  { opp : feBW_small -> feBW_small
  | forall a, phiM_small (opp a) = F.opp (phiM_small a) }.
Proof.
  Set Ltac Profiling.
  Time synthesize_opp ().
  Show Ltac Profile.
Time Defined.

Print Assumptions opp.
