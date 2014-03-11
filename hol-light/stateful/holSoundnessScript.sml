open HolKernel boolLib bossLib lcsymtacs listTheory finite_mapTheory alistTheory pred_setTheory pairTheory
open miscLib setSpecTheory holSyntaxTheory holSyntaxExtraTheory holSemanticsTheory holSemanticsExtraTheory
val _ = temp_tight_equality()
val _ = new_theory"holSoundness"

val mem = ``mem:'U->'U-> bool``

val binary_inference_rule = store_thm("binary_inference_rule",
  ``is_set_theory ^mem ⇒
    ∀thy h1 h2 p1 p2 q.
    q has_type Bool ∧ term_ok (sigof thy) q ∧
    (∀i v. is_structure (sigof thy) i v ∧
           termsem (sigof thy) i v p1 = True ∧
           termsem (sigof thy) i v p2 = True ⇒
           termsem (sigof thy) i v q = True) ∧
    (thy,h1) |= p1 ∧ (thy,h2) |= p2
    ⇒ (thy, TERM_UNION h1 h2) |= q``,
  strip_tac >>
  rpt gen_tac >> strip_tac >>
  fs[entails_def,EVERY_TERM_UNION] >> rw[] >>
  rpt (first_x_assum(qspec_then`i`mp_tac)>>rw[]) >>
  fs[satisfies_def,EVERY_TERM_UNION] >> rw[] >>
  first_x_assum match_mp_tac >>
  conj_tac >- ( rw[is_structure_def] >> Cases_on`thy` >> fs[models_def,theory_ok_def] ) >>
  rw[] >> first_x_assum match_mp_tac >> rw[] >>
  fs[EVERY_MEM] >>
  metis_tac[TERM_UNION_NONEW,TERM_UNION_THM,termsem_aconv,welltyped_def])

val ABS_correct = store_thm("ABS_correct",
  ``is_set_theory ^mem ⇒
    ∀thy x ty h l r.
    ¬EXISTS (VFREE_IN (Var x ty)) h ∧ type_ok (tysof thy) ty ∧
    (thy,h) |= l === r
    ⇒ (thy,h) |= Abs x ty l === Abs x ty r``,
  rw[] >> fs[entails_def] >>
  imp_res_tac theory_ok_sig >>
  conj_asm1_tac >- fs[term_ok_equation,term_ok_def] >>
  conj_asm1_tac >- fs[EQUATION_HAS_TYPE_BOOL] >> rw[] >>
  fs[satisfies_def] >> rw[] >>
  `is_structure (sigof thy) i v` by (
    fs[models_def,is_structure_def] ) >>
  imp_res_tac termsem_equation >>
  rw[boolean_eq_true,termsem_def] >>
  match_mp_tac (UNDISCH abstract_eq) >>
  qx_gen_tac`m` >> strip_tac >> simp[] >>
  Q.PAT_ABBREV_TAC`vv = (X:'U valuation)` >>
  `is_valuation (tysof thy) (FST i) vv` by (
    Cases_on`v`>>
    fs[is_valuation_def,Abbr`vv`,is_term_valuation_def] >>
    rw[combinTheory.APPLY_UPDATE_THM] >> rw[]) >>
  simp[CONJ_ASSOC] >>
  conj_tac >- (
    fs[is_structure_def] >>
    metis_tac[termsem_typesem,is_std_interpretation_is_type
             ,pairTheory.FST,term_ok_equation]) >>
  first_x_assum(qspec_then`i`mp_tac) >> simp[] >>
  disch_then(qspec_then`vv`mp_tac) >> simp[] >>
  `is_structure (sigof thy) i vv` by (
    fs[is_structure_def] ) >>
  imp_res_tac (UNDISCH termsem_equation) >>
  simp[boolean_eq_true] >> disch_then match_mp_tac >>
  fs[EVERY_MEM] >> rw[] >>
  qsuff_tac`termsem (sigof thy) i vv t = termsem (sigof thy) i v t`>-metis_tac[] >>
  match_mp_tac termsem_frees >>
  simp[Abbr`vv`,combinTheory.APPLY_UPDATE_THM] >>
  rw[] >> metis_tac[])

val ASSUME_correct = store_thm("ASSUME_correct",
  ``∀thy p.
      theory_ok thy ∧ p has_type Bool ∧ term_ok (sigof thy) p
      ⇒ (thy,[p]) |= p``,
  rw[entails_def,satisfies_def])

val BETA_correct = store_thm("BETA_correct",
  ``is_set_theory ^mem ⇒
    ∀thy x ty t.
      theory_ok thy ∧ type_ok (tysof thy) ty ∧ term_ok (sigof thy) t ⇒
      (thy,[]) |= Comb (Abs x ty t) (Var x ty) === t``,
  rw[] >> simp[entails_def] >>
  imp_res_tac theory_ok_sig >>
  imp_res_tac term_ok_welltyped >>
  conj_asm1_tac >- ( simp[term_ok_equation,term_ok_def] ) >>
  conj_asm1_tac >- ( simp[EQUATION_HAS_TYPE_BOOL] ) >>
  rw[satisfies_def] >>
  `is_structure (sigof thy) i v` by (
    rw[is_structure_def] >> fs[models_def] ) >>
  imp_res_tac (UNDISCH termsem_equation) >>
  rw[boolean_eq_true,termsem_def] >>
  qmatch_abbrev_tac`(Abstract mty mtyb f ' e) = termsem Γ i v τ` >>
  `Abstract mty mtyb f ' e = f e` by (
    match_mp_tac (MP_CANON apply_abstract) >>
    simp[Abbr`f`,Abbr`e`] >>
    conj_tac >- (
      Cases_on`v`>>
      fs[is_valuation_def,is_term_valuation_def,Abbr`mty`]) >>
    simp[Abbr`mtyb`] >>
    match_mp_tac (UNDISCH termsem_typesem) >>
    fs[is_structure_def] >>
    imp_res_tac is_std_interpretation_is_type >>
    Cases_on`v`>>
    fs[is_valuation_def,is_term_valuation_def] >>
    rw[combinTheory.APPLY_UPDATE_THM]) >>
  simp[Abbr`f`,Abbr`e`] >>
  rw[combinTheory.APPLY_UPDATE_ID])

val DEDUCT_ANTISYM_correct = store_thm("DEDUCT_ANTISYM_correct",
  ``is_set_theory ^mem ⇒
    ∀thy h1 p1 h2 p2.
      (thy,h1) |= p1 ∧ (thy,h2) |= p2 ⇒
      (thy,
       TERM_UNION (FILTER ($~ o ACONV p2) h1)
                  (FILTER ($~ o ACONV p1) h2))
      |= p1 === p2``,
  rw[] >> fs[entails_def] >>
  imp_res_tac theory_ok_sig >>
  conj_asm1_tac >- (
    simp[term_ok_equation] >>
    imp_res_tac WELLTYPED_LEMMA >> simp[] >>
    match_mp_tac EVERY_TERM_UNION >>
    fs[EVERY_MEM,MEM_FILTER] ) >>
  conj_asm1_tac >- (
    simp[EQUATION_HAS_TYPE_BOOL] >>
    imp_res_tac WELLTYPED_LEMMA >> simp[WELLTYPED] >>
    match_mp_tac EVERY_TERM_UNION >>
    fs[EVERY_MEM,MEM_FILTER] ) >>
  rw[satisfies_def] >>
  `is_structure (sigof thy) i v` by (
    fs[models_def,is_structure_def] ) >>
  imp_res_tac (UNDISCH termsem_equation) >>
  simp[boolean_eq_true] >>
  rpt(first_x_assum(qspec_then`i`mp_tac)>>rw[]) >>
  fs[satisfies_def] >>
  rpt(first_x_assum(qspec_then`v`mp_tac)>>rw[]) >>
  fs[EVERY_MEM] >>
  ntac 2 (pop_assum mp_tac) >>
  `∀x y ls. MEM x (FILTER ($~ o ACONV y) ls) ⇔ ¬ACONV y x ∧ MEM x ls` by simp[MEM_FILTER] >>
  qmatch_abbrev_tac`(a ⇒ b) ⇒ (c ⇒ d) ⇒ e` >>
  `d ⇒ a` by (
    unabbrev_all_tac >> rw[] >>
    metis_tac[TERM_UNION_THM,termsem_aconv,welltyped_def] ) >>
  `b ⇒ c` by (
    unabbrev_all_tac >> rw[] >>
    metis_tac[TERM_UNION_THM,termsem_aconv,welltyped_def] ) >>
  `termsem (sigof thy) i v p1 <: boolset ∧
   termsem (sigof thy) i v p2 <: boolset` by (
    fs[is_structure_def] >>
    imp_res_tac is_std_interpretation_is_type >>
    imp_res_tac termsem_typesem >>
    imp_res_tac WELLTYPED_LEMMA >>
    metis_tac[typesem_Bool]) >>
  metis_tac[mem_boolset])

val EQ_MP_correct = store_thm("EQ_MP_correct",
  ``is_set_theory ^mem ⇒
    ∀thy h1 h2 p q p'.
      (thy,h1) |= p === q ∧ (thy,h2) |= p' ∧ ACONV p p' ⇒
      (thy,TERM_UNION h1 h2) |= q``,
  rw[] >>
  match_mp_tac (UNDISCH binary_inference_rule) >>
  map_every qexists_tac[`p === q`,`p'`] >>
  fs[entails_def,EQUATION_HAS_TYPE_BOOL] >>
  imp_res_tac theory_ok_sig >>
  fs[term_ok_equation] >>
  conj_asm1_tac >- metis_tac[ACONV_TYPE,WELLTYPED,WELLTYPED_LEMMA] >> rw[] >>
  `term_ok (sigof thy) (p === q)` by metis_tac[term_ok_equation] >>
  imp_res_tac (UNDISCH termsem_equation) >> rfs[boolean_eq_true] >>
  metis_tac[termsem_aconv])

val INST_correct = store_thm("INST_correct",
  ``is_set_theory ^mem ⇒
    ∀thy h c.
      (∀s s'. MEM (s',s) ilist ⇒
              ∃x ty. (s = Var x ty) ∧ s' has_type ty ∧ term_ok (sigof thy) s') ∧
      (thy, h) |= c
    ⇒ (thy, MAP (VSUBST ilist) h) |= VSUBST ilist c``,
  rw[entails_def,EVERY_MAP,EVERY_MEM,satisfies_def] >>
  TRY ( match_mp_tac term_ok_VSUBST >> metis_tac[] ) >>
  TRY ( match_mp_tac VSUBST_HAS_TYPE >> metis_tac[] ) >>
  qspecl_then[`c`,`ilist`]mp_tac termsem_VSUBST >>
  discharge_hyps >- metis_tac[welltyped_def] >>
  disch_then(qspecl_then[`sigof thy`,`i`,`v`]SUBST1_TAC) >>
  first_x_assum(qspec_then`i`mp_tac) >> rw[] >>
  first_x_assum(match_mp_tac o MP_CANON) >>
  conj_tac >- (
    fs[is_valuation_def] >>
    fs[is_term_valuation_def,APPLY_UPDATE_LIST_ALOOKUP,rich_listTheory.MAP_REVERSE] >>
    rw[] >>
    BasicProvers.CASE_TAC >- metis_tac[] >>
    imp_res_tac ALOOKUP_MEM >>
    fs[MEM_MAP,UNCURRY,EXISTS_PROD] >>
    res_tac >> imp_res_tac WELLTYPED_LEMMA >> fs[] >>
    rpt BasicProvers.VAR_EQ_TAC >>
    match_mp_tac (UNDISCH termsem_typesem) >>
    rw[is_valuation_def,is_term_valuation_def] >>
    fs[models_def] >> metis_tac[is_std_interpretation_is_type] ) >>
  fs[EVERY_MAP,EVERY_MEM] >>
  metis_tac[termsem_VSUBST,welltyped_def])

val INST_TYPE_correct = store_thm("INST_TYPE_correct",
  ``is_set_theory ^mem ⇒
    ∀thy h c.
      EVERY (type_ok (tysof thy)) (MAP FST tyin) ∧
      (thy, h) |= c
    ⇒ (thy, MAP (INST tyin) h) |= INST tyin c``,
  rw[entails_def,EVERY_MAP,EVERY_MEM,satisfies_def] >>
  TRY ( match_mp_tac term_ok_INST >> fs[EVERY_MAP,EVERY_MEM] >> metis_tac[] ) >>
  TRY ( match_mp_tac INST_HAS_TYPE >> metis_tac[TYPE_SUBST_Bool] ) >>
  qspecl_then[`sigof thy`,`c`,`tyin`]mp_tac termsem_INST >>
  discharge_hyps >- metis_tac[welltyped_def] >>
  disch_then(qspecl_then[`i`,`v`]SUBST1_TAC) >>
  first_x_assum(qspec_then`i`mp_tac)>>rw[]>>
  first_x_assum(match_mp_tac o MP_CANON) >>
  conj_tac >- (
    fs[is_valuation_def] >>
    conj_tac >- (
      fs[is_type_valuation_def] >> rw[] >>
      match_mp_tac (UNDISCH typesem_inhabited) >>
      Cases_on`i`>>fs[models_def,is_interpretation_def] >>
      qexists_tac`tysof thy` >> simp[is_type_valuation_def] >>
      fs[FORALL_PROD] >>
      metis_tac[holSyntaxLibTheory.REV_ASSOCD_MEM,type_ok_def] ) >>
    fs[is_term_valuation_def,APPLY_UPDATE_LIST_ALOOKUP,rich_listTheory.MAP_REVERSE] >>
    rw[] >>
    simp[Once (typesem_TYPE_SUBST |> SIMP_RULE(srw_ss())[] |> GSYM)] >>
    metis_tac[type_ok_TYPE_SUBST |> SIMP_RULE(srw_ss())[EVERY_MAP,EVERY_MEM]]) >>
  fs[EVERY_MAP,EVERY_MEM] >>
  metis_tac[SIMP_RULE(srw_ss())[]termsem_INST,welltyped_def])

val MK_COMB_correct = store_thm("MK_COMB_correct",
  ``is_set_theory ^mem ⇒
    ∀thy h1 h2 l1 r1 l2 r2.
      (thy,h1) |= l1 === r1 ∧ (thy,h2) |= l2 === r2 ∧
      welltyped (Comb l1 l2)
      ⇒ (thy,TERM_UNION h1 h2) |= Comb l1 l2 === Comb r1 r2``,
  rw[] >>
  match_mp_tac (UNDISCH binary_inference_rule) >>
  map_every qexists_tac[`l1 === r1`,`l2 === r2`] >>
  fs[entails_def] >>
  imp_res_tac theory_ok_sig >>
  conj_asm1_tac >- (
    fs[EQUATION_HAS_TYPE_BOOL,term_ok_equation] >>
    metis_tac[] ) >>
  conj_asm1_tac >- (
    fs[term_ok_equation,term_ok_def,EQUATION_HAS_TYPE_BOOL] ) >>
  rw[] >>
  imp_res_tac (UNDISCH termsem_equation) >>
  rfs[boolean_eq_true] >>
  rw[termsem_def])

val REFL_correct = store_thm("REFL_correct",
  ``is_set_theory ^mem ⇒
    ∀thy t.
      theory_ok thy ∧ term_ok (sigof thy) t ⇒
      (thy,[]) |= t === t``,
  rw[] >>
  simp[entails_def,EQUATION_HAS_TYPE_BOOL] >>
  imp_res_tac theory_ok_sig >>
  imp_res_tac term_ok_welltyped >>
  conj_asm1_tac >- rw[term_ok_equation] >>
  rw[satisfies_def] >>
  `is_structure (sigof thy) i v` by (
    rw[is_structure_def] >> fs[models_def] ) >>
  imp_res_tac termsem_equation >>
  rw[boolean_def])

val TRANS_correct = store_thm("TRANS_correct",
  ``is_set_theory ^mem ⇒
    ∀thy h1 h2 l m1 m2 r.
      (thy,h1) |= l === m1 ∧ (thy,h2) |= m2 === r ∧ ACONV m1 m2
      ⇒ (thy,TERM_UNION h1 h2) |= l === r``,
  strip_tac >>
  rw[] >> match_mp_tac (UNDISCH binary_inference_rule) >>
  map_every qexists_tac[`l === m1`,`m2 === r`] >>
  fs[entails_def] >>
  imp_res_tac theory_ok_sig >>
  conj_asm1_tac >- (
    fs[EQUATION_HAS_TYPE_BOOL] >>
    metis_tac[ACONV_TYPE] ) >>
  conj_asm1_tac >- (
    fs[term_ok_equation,EQUATION_HAS_TYPE_BOOL] ) >>
  rw[] >>
  imp_res_tac termsem_equation >>
  rfs[boolean_eq_true] >> fs[term_ok_equation] >>
  metis_tac[termsem_aconv,ACONV_SYM,term_ok_welltyped])

val proves_sound = store_thm("proves_sound",
  ``is_set_theory ^mem ⇒ ∀thyh c. thyh |- c ⇒ thyh |= c``,
  strip_tac >> match_mp_tac proves_ind >>
  conj_tac >- metis_tac[ABS_correct] >>
  conj_tac >- metis_tac[ASSUME_correct] >>
  conj_tac >- metis_tac[BETA_correct] >>
  conj_tac >- metis_tac[DEDUCT_ANTISYM_correct] >>
  conj_tac >- metis_tac[EQ_MP_correct] >>
  conj_tac >- metis_tac[INST_correct] >>
  conj_tac >- metis_tac[INST_TYPE_correct] >>
  conj_tac >- metis_tac[MK_COMB_correct] >>
  conj_tac >- metis_tac[REFL_correct] >>
  conj_tac >- metis_tac[TRANS_correct] >>
  rw[entails_def,theory_ok_def,models_def])

val proves_consistent = store_thm("proves_consistent",
  ``is_set_theory ^mem ⇒
    ∀ctxt. theory_ok (thyof ctxt) ∧ (∃i. i models (thyof ctxt)) ⇒
      (thyof ctxt,[]) |- (Var "x" Bool === Var "x" Bool) ∧
      ¬((thyof ctxt,[]) |- (Var "x" Bool === Var "y" Bool))``,
  rw[] >- (
    match_mp_tac (List.nth(CONJUNCTS proves_rules,8)) >>
    simp[term_ok_def,type_ok_def] >>
    imp_res_tac theory_ok_sig >>
    fs[is_std_sig_def] ) >>
  spose_not_then strip_assume_tac >>
  imp_res_tac proves_sound >>
  fs[entails_def] >>
  first_x_assum(qspec_then`i`mp_tac) >>
  simp[satisfies_def] >>
  qexists_tac`(K boolset),
              λ(x,ty). if (x,ty) = ("x",Bool) then True else
                       if (x,ty) = ("y",Bool) then False else
                       @v. v <: typesem (tyaof i) (K boolset) ty` >>
  conj_asm1_tac >- (
    simp[is_valuation_def] >>
    conj_asm1_tac >- (simp[is_type_valuation_def,mem_boolset] >> PROVE_TAC[]) >>
    fs[models_def,is_term_valuation_def,is_interpretation_def] >>
    imp_res_tac is_std_interpretation_is_type >>
    imp_res_tac typesem_Bool >>
    rw[mem_boolset] >>
    metis_tac[typesem_inhabited] ) >>
  qmatch_abbrev_tac`termsem sig i v (s === t) ≠ True` >>
  qspecl_then[`sig`,`i`,`v`,`s`,`t`]mp_tac(UNDISCH termsem_equation) >>
  discharge_hyps >- (
    simp[term_ok_equation,is_structure_def] >>
    fs[models_def,Abbr`sig`,theory_ok_def] ) >>
  simp[Abbr`s`,Abbr`t`,termsem_def,boolean_eq_true,Abbr`v`,true_neq_false])

val init_ctxt_has_model = store_thm("init_ctxt_has_model",
  ``is_set_theory ^mem ⇒ ∃i. i models (thyof init_ctxt)``,
  rw[models_def,init_ctxt_def,conexts_of_upd_def] >>
  rw[is_std_interpretation_def,is_std_type_assignment_def,EXISTS_PROD] >>
  qho_match_abbrev_tac`∃f g. P f g ∧ (f x1 = y1 ∧ f x2 = y2) ∧ (g x3 = y3)` >>
  qexists_tac`λx. if x = x1 then y1 else if x = x2 then y2 else ARB` >>
  qexists_tac`K y3` >>
  rw[Abbr`x1`,Abbr`x2`,Abbr`P`] >>
  rw[is_interpretation_def,is_type_assignment_def,is_term_assignment_def] >>
  rw[FEVERY_FUPDATE,Abbr`y2`,Abbr`y1`,Abbr`y3`,FEVERY_FEMPTY] >>
  rw[typesem_def,tyvars_def] >>
  TRY (
    match_mp_tac (UNDISCH abstract_in_funspace) >> rw[] >>
    match_mp_tac (UNDISCH abstract_in_funspace) >> rw[boolean_in_boolset] ) >>
  BasicProvers.CASE_TAC >> fs[] >- metis_tac[boolean_in_boolset] >>
  BasicProvers.CASE_TAC >> fs[] >>
  BasicProvers.CASE_TAC >> fs[] >>
  match_mp_tac (UNDISCH funspace_inhabited) >>
  metis_tac[])

(*
val new_axiom_correct = store_thm("new_axiom_correct",
  ``∀ctxt p h c.
    p has_type Bool ∧ term_ok (sigof ctxt) p ∧
    ((ctxt,h) |= c ∨
     (h = [] ∧ context_ok ctxt ∧
      MEM c (axioms_of_upd (NewAxiom p))))
    ⇒ ((NewAxiom p)::ctxt, h) |= c``,
  simp[entails_def,conexts_of_upd_def] >>
  rpt gen_tac >> strip_tac >> simp[] >>
  (conj_tac >- (
     fs[context_ok_def,linear_context_def,conexts_of_upd_def] >>
     metis_tac[IS_SUFFIX_CONS])) >>
  rw[] >- (
    first_x_assum match_mp_tac >>
    match_mp_tac is_model_reduce >>
    metis_tac[rich_listTheory.CONS_APPEND,SUBMAP_REFL,context_ok_axioms_ok] ) >>
  fs[is_model_def,conexts_of_upd_def])

val new_constant_correct = store_thm("new_constant_correct",
  ``∀ctxt h c name ty.
      name ∉ (FDOM (consts ctxt)) ∧
      type_ok (types ctxt) ty ∧
      ((ctxt,h) |= c ∨
       (h = [] ∧ context_ok ctxt ∧
        MEM c (axioms_of_upd (NewConst name ty))))
      ⇒ ((NewConst name ty)::ctxt,h) |= c``,
  simp[entails_def,conexts_of_upd_def] >>
  rpt gen_tac >> strip_tac >>
  conj_asm1_tac >- (
    fs[context_ok_def,conexts_of_upd_def] >>
    fs[linear_context_def,ALL_DISTINCT_APPEND,IS_SUFFIX_CONS] ) >>
  `consts ctxt ⊑ consts ctxt |+ (name,ty)` by simp[] >>
  `EVERY (term_ok (sigof ctxt)) (c::h)` by ( fs[EVERY_MEM,satisfies_def] ) >>
  conj_asm1_tac >- (
    rw[EVERY_MEM] >> metis_tac[term_ok_extend,SUBMAP_REFL,EVERY_MEM]) >>
  rw[] >>
  `is_model (sigof ctxt,axioms ctxt) i` by (
    match_mp_tac is_model_reduce >>
    qmatch_assum_abbrev_tac`is_model ((tt,cc),aa) i` >>
    map_every qexists_tac[`tt`,`cc`,`aa`] >> simp[Abbr`cc`] >>
    imp_res_tac context_ok_axioms_ok >>
    fs[EVERY_MEM,Abbr`tt`] ) >>
  metis_tac[satisfies_extend,SUBMAP_REFL])

val new_specification_correct = store_thm("new_specification_correct",
  ``is_set_theory ^mem ⇒
    ∀ctxt eqs prop asl p.
    (ctxt, MAP (λ(s,t). Var s (typeof t) === t) eqs) |= prop ∧
    EVERY
      (λt. CLOSED t ∧
           (∀v. MEM v (tvars t) ⇒ MEM v (tyvars (typeof t))))
      (MAP SND eqs) ∧
    (∀x ty. VFREE_IN (Var x ty) prop ⇒
              MEM (x,ty) (MAP (λ(s,t). (s,typeof t)) eqs)) ∧
    (∀s. MEM s (MAP FST eqs) ⇒ s ∉ (FDOM (consts ctxt))) ∧
    ALL_DISTINCT (MAP FST eqs) ∧
    ((ctxt, asl) |= p ∨
     (asl = [] ∧ MEM p (axioms_of_upd (ConstSpec eqs prop))))
    ⇒ ((ConstSpec eqs prop)::ctxt,asl) |= p``,
  strip_tac >> rpt gen_tac >>
  Q.PAT_ABBREV_TAC`D ⇔ A ∨ B` >>
  simp[entails_def] >>
  strip_tac >>
  Q.PAT_ABBREV_TAC`cs:(string |-> type) = alist_to_fmap Z` >>
  `consts ctxt ⊑ cs ⊌ consts ctxt` by (
    match_mp_tac SUBMAP_FUNION >>
    simp[Abbr`cs`,IN_DISJOINT] >>
    fs[MEM_MAP,FORALL_PROD,EXISTS_PROD] >>
    metis_tac[] ) >>
  imp_res_tac context_ok_sig >>
  conj_asm1_tac >- (
    fs[context_ok_def,IS_SUFFIX_CONS,conexts_of_upd_def,LET_THM,ALL_DISTINCT_APPEND] >>
    simp[MAP_MAP_o,combinTheory.o_DEF,ETA_AX,UNCURRY] >>
    conj_tac >- (
      match_mp_tac VSUBST_HAS_TYPE >>
      simp[MEM_MAP,PULL_EXISTS,FORALL_PROD] >>
      simp[Once has_type_cases] ) >>
    fs[linear_context_def,ALL_DISTINCT_APPEND,MAP_MAP_o,combinTheory.o_DEF,UNCURRY] >>
    asm_simp_tac(srw_ss()++boolSimps.ETA_ss)[] >>
    fs[EVERY_MAP,term_ok_equation,EVERY_MEM,UNCURRY] ) >>
  conj_asm1_tac >- (
    fs[Abbr`D`,EVERY_MEM,entails_def,LET_THM,conexts_of_upd_def] >> rw[] >>
    TRY (match_mp_tac term_ok_VSUBST >> conj_tac) >>
    TRY (
      match_mp_tac term_ok_extend >>
      map_every qexists_tac[`types ctxt`,`consts ctxt`] >>
      simp[] >> NO_TAC) >>
    rw[MEM_MAP,EXISTS_PROD,term_ok_def,Abbr`cs`,FLOOKUP_FUNION] >>
    rw[Once has_type_cases] >>
    rw[ALOOKUP_MAP] >>
    imp_res_tac ALOOKUP_ALL_DISTINCT_MEM >>
    rw[] >>
    fs[MEM_MAP,PULL_EXISTS] >>
    qmatch_assum_abbrev_tac`MEM eq eqs` >>
    last_x_assum(qspec_then`eq`mp_tac) >>
    simp[Abbr`eq`,term_ok_equation,term_ok_def] ) >>
  conj_asm1_tac >- (
    fs[Abbr`D`,entails_def,LET_THM,conexts_of_upd_def] >>
    match_mp_tac VSUBST_HAS_TYPE >>
    simp[MEM_MAP,PULL_EXISTS,FORALL_PROD] >>
    rw[Once has_type_cases] ) >>
  rpt strip_tac >>
  `is_model (sigof ctxt,axioms ctxt) i` by (
    match_mp_tac is_model_reduce >>
    metis_tac[APPEND,SUBMAP_REFL,context_ok_axioms_ok] ) >>
  fs[Abbr`D`,LET_THM,entails_def] >- (
    metis_tac[satisfies_extend,SUBMAP_REFL,EVERY_DEF] ) >>
  fs[is_model_def,EVERY_MEM])

val new_type_correct = store_thm("new_type_correct",
  ``∀ctxt h c name arity.
      name ∉ (FDOM (types ctxt)) ∧
      ((ctxt,h) |= c ∨
       (h = [] ∧ context_ok ctxt ∧
        MEM c (axioms_of_upd (NewType name arity))))
      ⇒ ((NewType name arity)::ctxt,h) |= c``,
  simp[entails_def,conexts_of_upd_def] >>
  rpt gen_tac >> strip_tac >>
  conj_asm1_tac >- (
    fs[context_ok_def,conexts_of_upd_def,linear_context_def] >>
    metis_tac[IS_SUFFIX_CONS]) >>
  conj_asm1_tac >- (
    fs[EVERY_MEM] >> rw[] >>
    match_mp_tac term_ok_extend >>
    map_every qexists_tac[`types ctxt`,`consts ctxt`] >>
    simp[] ) >>
  rw[] >>
  `EVERY (term_ok (sigof ctxt)) (c::h)` by (
    fs[EVERY_MEM] ) >>
  `types ctxt ⊑ types ctxt |+ (name,arity)` by simp[] >>
  qsuff_tac`(sigof ctxt,i) satisfies (h,c)` >- (
    metis_tac[satisfies_extend,SUBMAP_REFL] ) >>
  first_x_assum match_mp_tac >>
  match_mp_tac is_model_reduce >>
  qmatch_assum_abbrev_tac`is_model ((tyenv,tmenv),axs) i` >>
  map_every qexists_tac[`tyenv`,`tmenv`,`axs`] >>
  simp[Abbr`tyenv`,Abbr`tmenv`] >>
  imp_res_tac context_ok_axioms_ok >>
  fs[Abbr`axs`] >> fsrw_tac[boolSimps.ETA_ss][])

val new_type_definition_correct = store_thm("new_type_definition_correct",
  ``∀ctxt h c name pred abs rep rep_type witness.
    (ctxt,[]) |= Comb pred witness ∧
    CLOSED pred ∧ pred has_type (Fun rep_type Bool) ∧
    name ∉ (FDOM (types ctxt)) ∧
    abs ∉ (FDOM (consts ctxt)) ∧
    rep ∉ (FDOM (consts ctxt)) ∧
    abs ≠ rep ∧
    ((ctxt, h) |= c ∨
     (h = [] ∧ MEM c (axioms_of_upd (TypeDefn name pred abs rep))))
    ⇒ ((TypeDefn name pred abs rep)::ctxt, h) |= c``,
  strip_tac >> rpt gen_tac >>
  Q.PAT_ABBREV_TAC`D ⇔ A ∨ B` >>
  simp[entails_def] >>
  strip_tac >>
  Q.PAT_ABBREV_TAC`ts:(string |-> num) = Z` >>
  Q.PAT_ABBREV_TAC`cs:(string |-> type) = Z` >>
  `consts ctxt ⊑ cs ∧ types ctxt ⊑ ts` by (
    rw[Abbr`cs`,Abbr`ts`] >>
    rw[SUBMAP_DEF,FAPPLY_FUPDATE_THM] >>
    rw[] >> fs[] >> NO_TAC) >>
  imp_res_tac context_ok_sig >>
  `welltyped pred` by metis_tac[welltyped_def] >>
  imp_res_tac WELLTYPED_LEMMA >>
  conj_asm1_tac >- (
    fs[context_ok_def,IS_SUFFIX_CONS,conexts_of_upd_def,LET_THM,ALL_DISTINCT_APPEND] >>
    simp[EQUATION_HAS_TYPE_BOOL] >>
    conj_tac >- (
      qmatch_abbrev_tac`welltyped e ∧ Z` >>
      qsuff_tac`e has_type Bool` >- metis_tac[WELLTYPED_LEMMA,welltyped_def] >>
      simp[Abbr`e`,EQUATION_HAS_TYPE_BOOL] ) >>
    fs[linear_context_def,ALL_DISTINCT_APPEND,MAP_MAP_o,combinTheory.o_DEF,UNCURRY] >>
    fs[term_ok_def]) >>
  `name ∉ {"fun";"bool"} ∧ abs ≠ "=" ∧ rep ≠ "="` by (
    rfs[context_ok_def,rich_listTheory.IS_SUFFIX_APPEND,init_ctxt_def] >>
    rw[] >> fs[] ) >>
  `is_std_sig (ts,cs)` by (
    fs[is_std_sig_def,Abbr`cs`,Abbr`ts`,FLOOKUP_UPDATE] ) >>
  conj_asm1_tac >- (
    `term_ok (ts,cs) pred` by (
      fs[term_ok_def] >>
      match_mp_tac term_ok_extend >>
      metis_tac[] ) >>
    `type_ok ts rep_type` by (
      fs[term_ok_def] >>
      imp_res_tac term_ok_type_ok >>
      match_mp_tac type_ok_extend >>
      metis_tac[FST] ) >>
    fs[Abbr`D`,EVERY_MEM,entails_def,LET_THM,conexts_of_upd_def] >> rw[] >>
    TRY (
      match_mp_tac term_ok_extend >>
      map_every qexists_tac[`types ctxt`,`consts ctxt`] >>
      simp[] >> NO_TAC)
    >- (
      simp[term_ok_equation,term_ok_def] >>
      simp[Abbr`cs`,FLOOKUP_UPDATE,type_ok_def,Abbr`ts`,EVERY_MAP] >>
      fs[is_std_sig_def] ) >>
    simp[term_ok_equation,term_ok_def,Abbr`cs`,FLOOKUP_UPDATE,type_ok_def,Abbr`ts`,EVERY_MAP] >>
    fs[is_std_sig_def] >>
    qmatch_abbrev_tac`typeof e = Bool` >>
    (qsuff_tac`e has_type Bool` >- metis_tac[WELLTYPED_LEMMA]) >>
    simp[Abbr`e`,EQUATION_HAS_TYPE_BOOL] ) >>
  conj_asm1_tac >- (
    fs[Abbr`D`,entails_def,context_ok_def,EVERY_MEM] ) >>
  rw[Abbr`D`] >>
  `is_model (sigof ctxt,axioms ctxt) i` by (
    match_mp_tac is_model_reduce >>
    metis_tac[APPEND,SUBMAP_REFL,context_ok_axioms_ok] ) >>
  fs[entails_def] >- (
      metis_tac[satisfies_extend,SUBMAP_REFL,EVERY_DEF] ) >>
  fs[is_model_def,EVERY_MEM])
*)

val _ = export_theory()
