open preamble initSemEnvTheory semanticsPropsTheory
     backendTheory
     source_to_modProofTheory
     mod_to_conProofTheory
     con_to_decProofTheory
     dec_to_exhProofTheory
     exh_to_patProofTheory
     pat_to_closProofTheory
     clos_to_bvlProofTheory
     bvl_to_bviProofTheory
     bvi_to_bvpProofTheory
     bvp_to_wordProofTheory
local open compilerComputeLib in end

(* TODO: move *)
fun Abbrev_intro th =
  EQ_MP (SYM(SPEC(concl th)markerTheory.Abbrev_def)) th
(* -- *)

val _ = new_theory"backendProof";

(* TODO: move *)

val pair_CASE_eq = Q.store_thm("pair_CASE_eq",
  `pair_CASE p f = a ⇔ ∃x y. p = (x,y) ∧ f x y = a`,
  Cases_on`p`>>rw[]);

(* -- *)

(* TODO: move *)
val get_exh_def = mod_to_conTheory.get_exh_def;
val alloc_tag_def = mod_to_conTheory.alloc_tag_def;
val alloc_tags_def = mod_to_conTheory.alloc_tags_def;
val compile_decs_def = mod_to_conTheory.compile_decs_def;
val compile_prompt_def = mod_to_conTheory.compile_prompt_def;
val compile_prog_def = mod_to_conTheory.compile_prog_def;
val prog_to_top_types_def = modSemTheory.prog_to_top_types_def;
val decs_to_types_def = modSemTheory.decs_to_types_def;
val prompt_mods_ok_def = modSemTheory.prompt_mods_ok_def;

val alloc_tags_exh_unchanged = Q.store_thm("alloc_tags_exh_unchanged",
  `∀c b a.
    ¬MEM (Short t) (MAP (λ(tvs,tn,ctors). mk_id a tn) c) ∧
    FLOOKUP (get_exh(FST b)) (Short t) = SOME v ⇒
    FLOOKUP (get_exh(FST(alloc_tags a b c))) (Short t) = SOME v`,
  Induct >> simp[alloc_tags_def] >>
  rw[] >> PairCases_on`h` >>
  simp[alloc_tags_def] >>
  first_x_assum match_mp_tac >> fs[] >>
  pop_assum mp_tac >>
  qid_spec_tac`b` >>
  Induct_on`h2`>>rw[] >>
  simp[UNCURRY] >>
  first_x_assum match_mp_tac >>
  PairCases_on`b` >>
  simp[alloc_tag_def] >>
  every_case_tac >> fs[get_exh_def] >>
  simp[FLOOKUP_UPDATE]);

val compile_decs_exh_unchanged = Q.store_thm("compile_decs_exh_unchanged",
  `∀ds a st sta st' ac b.
   EVERY (λd. case d of Dtype mn _ => mn = SOME x | Dexn mn _ _ => mn = SOME x | _ => T) ds ∧
   compile_decs sta ds = ((st',ac),b) ∧ st = FST sta ∧
   FLOOKUP (get_exh st) (Short t) = SOME v
   ⇒
   FLOOKUP (get_exh st') (Short t) = SOME v`,
  Induct >> simp[compile_decs_def] >> rw[] >> fs[] >>
  every_case_tac >> fs[] >>
  split_pair_tac >> fs[] >> rveq >>
  res_tac >> fs[] >>
  pop_assum kall_tac >>
  first_x_assum match_mp_tac >- (
    match_mp_tac alloc_tags_exh_unchanged >>
    simp[MEM_MAP,UNCURRY,astTheory.mk_id_def] ) >>
  PairCases_on`sta`>>simp[alloc_tag_def] >>
  fs[get_exh_def]);

val compile_prompt_exh_unchanged = Q.store_thm("compile_prompt_exh_unchanged",
  `(∀ds. p = Prompt NONE ds ⇒ ¬MEM t (decs_to_types ds)) ∧
   (∀mn ds. p = Prompt mn ds ⇒ prompt_mods_ok mn ds) ∧
   FLOOKUP (get_exh st) (Short t) = SOME v ⇒
   FLOOKUP (get_exh (FST (compile_prompt st p))) (Short t) = SOME v`,
  rw[compile_prompt_def] >>
  BasicProvers.TOP_CASE_TAC >> rw[] >> rw[get_exh_def] >>
  fs[prompt_mods_ok_def] >>
  every_case_tac >> fs[] >- (
    Cases_on`l`>>fs[compile_decs_def] >> rveq >- fs[get_exh_def] >>
    Cases_on`t'`>>fsrw_tac[ARITH_ss][]>>
    every_case_tac >> fs[LET_THM] >>
    split_pair_tac >> fs[] >> rveq >>
    fs[compile_decs_def] >> rveq >> fs[get_exh_def] >>
    PairCases_on`st`>>
    fs[decs_to_types_def,alloc_tag_def,LET_THM] >>
    rveq >> fs[get_exh_def] >> rw[] >>
    qmatch_assum_abbrev_tac`alloc_tags a b c = _` >>
    qispl_then[`c`,`b`,`a`]mp_tac alloc_tags_exh_unchanged >>
    simp[get_exh_def] >> disch_then match_mp_tac >>
    simp[Abbr`b`,get_exh_def,MEM_MAP,UNCURRY] >>
    Cases_on`a`>>simp[astTheory.mk_id_def,FORALL_PROD] >>
    fs[MEM_MAP,EXISTS_PROD] ) >>
  imp_res_tac compile_decs_exh_unchanged >> fs[get_exh_def]);

val compile_prog_exh_unchanged = Q.store_thm("compile_prog_exh_unchanged",
  `∀p st.
   ¬MEM t (prog_to_top_types p) ∧
   EVERY (λp. case p of Prompt mn ds => prompt_mods_ok mn ds) p ∧
   FLOOKUP (get_exh st) (Short t) = SOME v ∧
   exh' = get_exh (FST (compile_prog st p))
   ⇒
   FLOOKUP exh' (Short t) = SOME v`,
  Induct >> simp[compile_prog_def] >> rw[UNCURRY] >>
  `¬MEM t (prog_to_top_types p)` by (
    fs[prog_to_top_types_def] ) >> fs[] >>
  first_x_assum match_mp_tac >>
  fs[prog_to_top_types_def] >>
  match_mp_tac compile_prompt_exh_unchanged >>
  Cases_on`h`>>fs[]>>rw[]>>fs[]);

(* -- *)

val c = compilerComputeLib.the_compiler_compset
(* TODO: should add to compilerComputeLib *)
val () = computeLib.add_thms[source_to_modTheory.empty_config_def,mod_to_conTheory.empty_config_def] c
(* -- *)
val () = computeLib.add_thms[prim_config_def] c
val () = computeLib.add_thms[initialProgramTheory.prim_types_program_def] c

val prim_config_eq = save_thm("prim_config_eq",
  computeLib.CBV_CONV c ``prim_config``);

val id_CASE_eq_SOME = Q.prove(
  `id_CASE x f (λa b. NONE) = SOME z ⇔ ∃y. x = Short y ∧ f y = SOME z`,
  Cases_on`x`>>rw[])

val option_CASE_eq_SOME = Q.prove(
  `option_CASE x NONE z = SOME y ⇔ ∃a. x = SOME a ∧ z a = SOME y`,
  Cases_on`x`>>rw[]);

val else_NONE_eq_SOME = Q.store_thm("else_NONE_eq_SOME",
  `(((if t then y else NONE) = SOME z) ⇔ (t ∧ (y = SOME z)))`,
  rw[])

val COND_eq_SOME = Q.store_thm("COND_eq_SOME",
  `((if t then SOME a else b) = SOME x) ⇔ ((t ∧ (a = x)) ∨ (¬t ∧ b = SOME x))`,
  rw[])

val compile_correct = Q.store_thm("compile_correct",
  `let (s,env) = THE (prim_sem_env (ffi:'ffi ffi_state)) in
   (c:'a backend$config).source_conf = (prim_config:'a backend$config).source_conf ∧
   c.mod_conf = prim_config.mod_conf ∧ c.clos_conf = prim_config.clos_conf ∧
   good_dimindex (:α) ∧
   ¬semantics_prog s env prog Fail ∧
   compile c prog = SOME (bytes,c') ∧
   code_loaded bytes mc ms ⇒
     machine_sem mc ffi ms ⊆
       extend_with_resource_limit (semantics_prog s env prog)`,
  rw[compile_eq_from_source,from_source_def] >>
  drule(GEN_ALL(MATCH_MP SWAP_IMP source_to_modProofTheory.compile_correct)) >>
  fs[initSemEnvTheory.prim_sem_env_eq] >>
  qpat_assum`_ = s`(assume_tac o Abbrev_intro o SYM) >>
  qpat_assum`_ = env`(assume_tac o Abbrev_intro o SYM) >>
  `∃s2 env2 gtagenv.
     precondition s env c.source_conf s2 env2 ∧
     FST env2.c = [] ∧
     env2.globals = [] ∧
     s2.ffi = ffi ∧
     s2.refs = [] ∧
     s2.defined_types = s.defined_types ∧
     s2.defined_mods = s.defined_mods ∧
     envC_tagged env2.c prim_config.mod_conf.tag_env gtagenv ∧
     exhaustive_env_correct prim_config.mod_conf.exh_ctors_env gtagenv ∧
     gtagenv_wf gtagenv ∧
     next_inv (IMAGE (SND o SND) (FRANGE (SND( prim_config.mod_conf.tag_env))))
       prim_config.mod_conf.next_exception gtagenv` by (
    simp[source_to_modProofTheory.precondition_def] >>
    simp[Abbr`env`,Abbr`s`] >>
    srw_tac[QUANT_INST_ss[pair_default_qp,record_default_qp]][] >>
    rw[source_to_modProofTheory.invariant_def] >>
    rw[source_to_modProofTheory.s_rel_cases] >>
    rw[source_to_modProofTheory.v_rel_cases] >>
    rw[prim_config_eq] >>
    Cases_on`ffi`>>rw[ffiTheory.ffi_state_component_equality] >>
    CONV_TAC(PATH_CONV"brrrllr"(REWRITE_CONV[DOMSUB_FUPDATE_THM] THENC EVAL)) >>
    rpt(CHANGED_TAC(CONV_TAC(PATH_CONV"brrrllr"(REWRITE_CONV[FRANGE_FUPDATE,DRESTRICT_FUPDATE] THENC EVAL)))) >>
    rw[DRESTRICT_DRESTRICT] >>
    rw[envC_tagged_def,
       semanticPrimitivesTheory.lookup_alist_mod_env_def,
       mod_to_conTheory.lookup_tag_env_def,
       mod_to_conTheory.lookup_tag_flat_def,
       FLOOKUP_DEF] >>
    simp[id_CASE_eq_SOME,PULL_EXISTS] >>
    simp[option_CASE_eq_SOME] >>
    simp[astTheory.id_to_n_def] >>
    simp[FAPPLY_FUPDATE_THM] >>
    simp[pair_CASE_eq,PULL_EXISTS] >>
    simp[COND_eq_SOME] >>
    srw_tac[DNF_ss][] >>
    (fn g =>
       let
         val tms = g |> #2 |> dest_exists |> #2
                     |> dest_conj |> #1
                     |> strip_conj |> filter is_eq
         val fm = tms |> hd |> lhs |> rator |> rand
         val ps = map ((rand ## I) o dest_eq) tms
         val tm = finite_mapSyntax.list_mk_fupdate
                  (finite_mapSyntax.mk_fempty (finite_mapSyntax.dest_fmap_ty(type_of fm)),
                   map pairSyntax.mk_pair ps)
       in exists_tac tm end g) >>
    simp[FAPPLY_FUPDATE_THM] >>
    conj_tac >- (
      simp[exhaustive_env_correct_def,IN_FRANGE,FLOOKUP_UPDATE,PULL_EXISTS] >>
      srw_tac[DNF_ss][] >>
      EVAL_TAC >>
      pop_assum mp_tac >> rw[] >>
      EVAL_TAC >>
      simp[PULL_EXISTS]) >>
    conj_tac >- (
      EVAL_TAC >> rw[] >> fs[semanticPrimitivesTheory.same_tid_def] ) >>
    simp[next_inv_def,PULL_EXISTS] >>
    simp[FLOOKUP_UPDATE] >>
    rw[] >> EVAL_TAC >>
    srw_tac[QUANT_INST_ss[std_qp]][]) >>
  disch_then drule >> strip_tac >>
  rator_x_assum`from_mod`mp_tac >>
  rw[from_mod_def,Abbr`c'''`,mod_to_conTheory.compile_def] >>
  pop_assum mp_tac >> BasicProvers.LET_ELIM_TAC >>
  qmatch_assum_abbrev_tac`semantics_prog s env prog sem2` >>
  `sem2 ≠ Fail` by metis_tac[] >>
  `semantics_prog s env prog = { sem2 }` by (
    simp[EXTENSION,IN_DEF] >>
    metis_tac[semantics_prog_deterministic] ) >>
  qunabbrev_tac`sem2` >>
  drule (GEN_ALL mod_to_conProofTheory.compile_prog_semantics) >>
  fs[] >> rveq >>
  simp[AND_IMP_INTRO] >> simp[Once CONJ_COMM] >>
  disch_then drule >>
  simp[mod_to_conProofTheory.invariant_def,
       mod_to_conTheory.get_exh_def,
       mod_to_conTheory.get_tagenv_def] >>
  simp[mod_to_conProofTheory.s_rel_cases] >>
  CONV_TAC(LAND_CONV(SIMP_CONV(srw_ss()++QUANT_INST_ss[record_default_qp,pair_default_qp])[])) >>
  simp[mod_to_conProofTheory.cenv_inv_def] >>
  disch_then(qspec_then`gtagenv`mp_tac)>>
  discharge_hyps >- (
    rw[Abbr`s`,prim_config_eq] >>
    fs[prim_config_eq] >>
    rator_x_assum`next_inv`mp_tac >>
    rpt(pop_assum kall_tac) >>
    REWRITE_TAC[FRANGE_FUPDATE,DRESTRICT_FUPDATE,DOMSUB_FUPDATE_THM] >>
    EVAL_TAC >> rw[SUBSET_DEF] >> fs[PULL_EXISTS] >>
    res_tac >> fs[] >>
    pop_assum mp_tac >>
    rpt(CHANGED_TAC(REWRITE_TAC[FRANGE_FUPDATE,DRESTRICT_FUPDATE,DOMSUB_FUPDATE_THM] >> EVAL_TAC)) >>
    rw[DRESTRICT_DRESTRICT] >> rw[]) >>
  strip_tac >>
  pop_assum(assume_tac o SYM) >> simp[] >>
  qunabbrev_tac`c''''`>>
  rator_x_assum`from_con`mp_tac >>
  rw[from_con_def] >>
  pop_assum mp_tac >> BasicProvers.LET_ELIM_TAC >>
  rfs[] >> fs[] >>
  drule(GEN_ALL(MATCH_MP SWAP_IMP (REWRITE_RULE[GSYM AND_IMP_INTRO]con_to_decProofTheory.compile_semantics))) >>
  simp[] >>
  discharge_hyps >- (
    rator_x_assum`mod_to_con$compile_prog`mp_tac >>
    simp[prim_config_eq] >> EVAL_TAC >>
    `semantics env2 s2 p ≠ Fail` by simp[] >>
    pop_assum mp_tac >>
    simp_tac(srw_ss())[modSemTheory.semantics_def] >>
    IF_CASES_TAC >> simp[] >> disch_then kall_tac >>
    pop_assum mp_tac >>
    simp[modSemTheory.evaluate_prog_def] >>
    BasicProvers.TOP_CASE_TAC >> simp[] >> strip_tac >> fs[] >>
    `¬MEM "option" (prog_to_top_types p)` by (
      fs[modSemTheory.no_dup_top_types_def,IN_DISJOINT,MEM_MAP] >>
      fs[Abbr`s`] >> metis_tac[] ) >>
    strip_tac >>
    match_mp_tac compile_prog_exh_unchanged >>
    asm_exists_tac >> simp[] >>
    qmatch_assum_abbrev_tac`compile_prog st p = _` >>
    qexists_tac`st`>>simp[Abbr`st`,get_exh_def] >>
    simp[FLOOKUP_UPDATE]) >>
  disch_then(strip_assume_tac o SYM) >> fs[] >>
  rator_x_assum`from_dec`mp_tac >> rw[from_dec_def] >>
  pop_assum mp_tac >> BasicProvers.LET_ELIM_TAC >>
  rator_x_assum`con_to_dec$compile`mp_tac >>
  `c''.next_global = 0` by (
    fs[source_to_modTheory.compile_def,LET_THM] >>
    split_pair_tac >> fs[] >>
    split_pair_tac >> fs[] >>
    rveq >> simp[prim_config_eq] ) >> fs[] >>
  strip_tac >> fs[] >>
  qunabbrev_tac`c'''`>>fs[] >>
  qmatch_abbrev_tac`_ ⊆ _ { decSem$semantics env3 st3 es3 }` >>
  (dec_to_exhProofTheory.compile_exp_semantics
    |> Q.GENL[`sth`,`envh`,`es`,`st`,`env`]
    |> qispl_then[`env3`,`st3`,`es3`]mp_tac) >>
  simp[Abbr`env3`] >>
  simp[Once dec_to_exhProofTheory.v_rel_cases] >>
  simp[dec_to_exhProofTheory.state_rel_def] >>
  fs[Abbr`st3`,con_to_decProofTheory.compile_state_def] >>
  CONV_TAC(LAND_CONV(SIMP_CONV(srw_ss()++QUANT_INST_ss[record_default_qp,pair_default_qp])[])) >>
  simp[Abbr`es3`,dec_to_exhTheory.compile_exp_def] >>
  disch_then(strip_assume_tac o SYM) >> fs[] >>
  rator_x_assum`from_exh`mp_tac >>
  rw[from_exh_def] >>
  pop_assum mp_tac >> BasicProvers.LET_ELIM_TAC >>
  fs[exh_to_patTheory.compile_def] >>
  qmatch_abbrev_tac`_ ⊆ _ { exhSem$semantics env3 st3 es3 }` >>
  (exh_to_patProofTheory.compile_exp_semantics
   |> Q.GENL[`es`,`st`,`env`]
   |> qispl_then[`env3`,`st3`,`es3`]mp_tac) >>
  simp[Abbr`es3`,Abbr`env3`] >>
  fs[exh_to_patProofTheory.compile_state_def,Abbr`st3`] >>
  disch_then(strip_assume_tac o SYM) >> fs[] >>
  rator_x_assum`from_pat`mp_tac >>
  rw[from_pat_def] >>
  pop_assum mp_tac >> BasicProvers.LET_ELIM_TAC >>
  qmatch_abbrev_tac`_ ⊆ _ { patSem$semantics env3 st3 es3 }` >>
  (pat_to_closProofTheory.compile_semantics
   |> Q.GENL[`es`,`st`,`env`]
   |> qispl_then[`env3`,`st3`,`es3`]mp_tac) >>
  simp[Abbr`env3`,Abbr`es3`] >>
  fs[pat_to_closProofTheory.compile_state_def,Abbr`st3`] >>
  disch_then(strip_assume_tac o SYM) >> fs[] >>
  rator_x_assum`from_clos`mp_tac >>
  rw[from_clos_def] >>
  pop_assum mp_tac >> BasicProvers.LET_ELIM_TAC >>
  qmatch_abbrev_tac`_ ⊆ _ { closSem$semantics [] st3 [e3] }` >>
  (clos_to_bvlProofTheory.compile_semantics
   |> GEN_ALL
   |> CONV_RULE(RESORT_FORALL_CONV(sort_vars["s","e","c"]))
   |> qispl_then[`st3`,`e3`,`c.clos_conf`]mp_tac) >>
  simp[] >>
  discharge_hyps >- (
    simp[CONJ_ASSOC] >>
    conj_tac >- (
      unabbrev_all_tac >>
      simp[pat_to_closProofTheory.compile_contains_App_SOME] >>
      simp[pat_to_closProofTheory.compile_every_Fn_vs_NONE] >>
      simp[prim_config_eq] >> EVAL_TAC) >>
    simp[Abbr`st3`,clos_to_bvlProofTheory.full_state_rel_def] >>
    simp[Once clos_relationTheory.state_rel_rw] >>
    gen_tac >>
    qho_match_abbrev_tac`∃sa. P sa` >>
    srw_tac[QUANT_INST_ss[record_qp false (fn v => (K (type_of v = ``:'ffi closSem$state``))),pair_default_qp]][] >>
    simp[Abbr`P`] >>
    simp[clos_numberProofTheory.state_rel_def] >>
    qho_match_abbrev_tac`∃sa. P sa` >>
    srw_tac[QUANT_INST_ss[record_qp false (fn v => (K (type_of v = ``:'ffi closSem$state``))),pair_default_qp]][] >>
    simp[Abbr`P`] >>
    qho_match_abbrev_tac`∃sa. P sa` >>
    srw_tac[QUANT_INST_ss[record_qp false (fn v => (K (type_of v = ``:'ffi closSem$state``))),pair_default_qp]][] >>
    simp[Abbr`P`] >>
    simp[Once clos_relationTheory.state_rel_rw] >>
    simp[FEVERY_DEF] >>
    simp[clos_annotateProofTheory.state_rel_def] >>
    qho_match_abbrev_tac`∃sa. P sa` >>
    srw_tac[QUANT_INST_ss[record_qp false (fn v => (K (type_of v = ``:'ffi closSem$state``))),pair_default_qp]][] >>
    simp[Abbr`P`] >>
    qexists_tac`FEMPTY`>>simp[] >>
    simp[clos_to_bvlProofTheory.state_rel_def,FDOM_EQ_EMPTY] >>
    qexists_tac`FEMPTY`>>simp[] >>
    `∃c. p'' = toAList init_code ++ c` by (
      rator_x_assum`clos_to_bvl$compile`mp_tac >>
      rpt(pop_assum kall_tac) >>
      rw[clos_to_bvlTheory.compile_def] >>
      pop_assum mp_tac >> BasicProvers.LET_ELIM_TAC >>
      fs[] >> rveq >> rw[] ) >>
    rveq >>
    simp[lookup_fromAList,ALOOKUP_APPEND,ALOOKUP_toAList] >>
    strip_assume_tac init_code_ok >> simp[]) >>
  simp[Abbr`e3`] >>
  fs[Abbr`st3`] >>
  disch_then(strip_assume_tac o SYM) >> fs[] >>
  rator_x_assum`from_bvl`mp_tac >>
  rw[from_bvl_def] >>
  pop_assum mp_tac >> BasicProvers.LET_ELIM_TAC >>
  Q.ISPEC_THEN`s2.ffi`drule(Q.GEN`ffi0` bvl_to_bviProofTheory.compile_semantics) >>
  qunabbrev_tac`c''''`>>fs[] >>
  discharge_hyps >- (
    (clos_to_bvlProofTheory.compile_all_distinct_locs
     |> ONCE_REWRITE_RULE[CONJ_ASSOC,CONJ_COMM]
     |> ONCE_REWRITE_RULE[CONJ_COMM]
     |> drule) >>
    disch_then match_mp_tac >>
    simp[prim_config_eq] >>
    EVAL_TAC ) >>
  disch_then(SUBST_ALL_TAC o SYM) >>
  rator_x_assum`from_bvi`mp_tac >>
  rw[from_bvi_def] >>
  pop_assum mp_tac >> BasicProvers.LET_ELIM_TAC >>
  qmatch_abbrev_tac`_ ⊆ _ { bviSem$semantics ffi (fromAList p3) s3 }` >>
  (bvi_to_bvpProofTheory.compile_prog_semantics
   |> GEN_ALL
   |> CONV_RULE(RESORT_FORALL_CONV(sort_vars["prog","start"]))
   |> qispl_then[`p3`,`s3`,`ffi`]mp_tac) >>
  discharge_hyps >- simp[] >>
  disch_then (SUBST_ALL_TAC o SYM) >>
  rator_x_assum`from_bvp`mp_tac >>
  rw[from_bvp_def] >>
  pop_assum mp_tac >> BasicProvers.LET_ELIM_TAC >>
  map_every qunabbrev_tac[`p3`,`s3`] >>
  qmatch_abbrev_tac`_ ⊆ _ { bvpSem$semantics ffi (fromAList prg) start }` >>
  (bvp_to_wordProofTheory.compile_semantics
   |> GEN_ALL
   |> CONV_RULE(RESORT_FORALL_CONV(sort_vars["prog","start","ffi"]))
   |> qispl_then[`prg`,`start`,`ffi`]mp_tac) >>
  simp[FORALL_PROD] >>
  simp[bvp_to_wordProofTheory.state_rel_ext_def,PULL_EXISTS] >>
  simp[bvp_to_wordProofTheory.state_rel_def] >>
  simp[lookup_def] >>
  simp_tac(srw_ss()++(QUANT_INST_ss[record_qp false (fn v => (K (type_of v = ``:(α,'ffi) wordSem$state``))),pair_default_qp]))[] >>
  simp[bvpSemTheory.initial_state_def] >>
  simp[bvp_to_wordProofTheory.flat_def] >>
  simp[bvp_to_wordProofTheory.the_global_def,libTheory.the_def] >>
  simp[bvp_to_wordProofTheory.join_env_def] >>
  simp[PULL_EXISTS] >>
  CONV_TAC(LAND_CONV(RESORT_FORALL_CONV(sort_vars["fv_1"]))) >>
  disch_then(qspec_then`insert 0 (Loc 1 0) LN`mp_tac) >> simp[] >>
  simp[bvp_to_wordProofTheory.inter_insert] >> (* TODO: why is this theorem in that theory? it should be moved *)
  simp[EVAL``toAList (insert 0 x LN)``] >>
  simp[bvp_to_wordProofTheory.word_ml_inv_def,PULL_EXISTS] >>
  `small_int (:α) 0` by (
    fs[labPropsTheory.good_dimindex_def] >>
    EVAL_TAC >> simp[] ) >>
  simp[bvp_to_wordPropsTheory.abs_ml_inv_def] >>
  simp[bvp_to_wordPropsTheory.bc_stack_ref_inv_def,FDOM_EQ_EMPTY,
       bvp_to_wordPropsTheory.v_inv_def,
       bvp_to_wordPropsTheory.reachable_refs_def,
       bvp_to_wordPropsTheory.get_refs_def,
       bvp_to_wordPropsTheory.word_addr_def,
       copying_gcTheory.roots_ok_def] >>
  `(-2w && Smallnum 0) = 0w` by (
    fs[labPropsTheory.good_dimindex_def] >>
    EVAL_TAC >> simp[] ) >>
  simp[] >>
  cheat);

val _ = export_theory();