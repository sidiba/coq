(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2012     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

open Util
open Pp
open Names
open Term
open Sign
open Environ
open Locus

(** Universes *)
val new_univ_level : unit -> Univ.universe_level
val new_univ : unit -> Univ.universe
val new_sort_in_family : sorts_family -> sorts
val new_Type : unit -> types
val new_Type_sort : unit -> sorts
val refresh_universes : types -> types
val refresh_universes_strict : types -> types

(** printers *)
val print_sort : sorts -> std_ppcmds
val pr_sort_family : sorts_family -> std_ppcmds

(** debug printer: do not use to display terms to the casual user... *)
val set_print_constr : (env -> constr -> std_ppcmds) -> unit
val print_constr     : constr -> std_ppcmds
val print_constr_env : env -> constr -> std_ppcmds
val print_named_context : env -> std_ppcmds
val pr_rel_decl : env -> rel_declaration -> std_ppcmds
val print_rel_context : env -> std_ppcmds
val print_env : env -> std_ppcmds

(** about contexts *)
val push_rel_assum : Name.t * types -> env -> env
val push_rels_assum : (Name.t * types) list -> env -> env
val push_named_rec_types : Name.t array * types array * 'a -> env -> env

val lookup_rel_id : Id.t -> rel_context -> int * constr option * types
(** Associates the contents of an identifier in a [rel_context]. Raise
    [Not_found] if there is no such identifier. *)

(** builds argument lists matching a block of binders or a context *)
val rel_vect : int -> int -> constr array
val rel_list : int -> int -> constr list
val extended_rel_list : int -> rel_context -> constr list
val extended_rel_vect : int -> rel_context -> constr array

(** iterators/destructors on terms *)
val mkProd_or_LetIn : rel_declaration -> types -> types
val mkProd_wo_LetIn : rel_declaration -> types -> types
val it_mkProd : types -> (Name.t * types) list -> types
val it_mkLambda : constr -> (Name.t * types) list -> constr
val it_mkProd_or_LetIn : types -> rel_context -> types
val it_mkProd_wo_LetIn : types -> rel_context -> types
val it_mkLambda_or_LetIn : constr -> rel_context -> constr
val it_mkNamedProd_or_LetIn : types -> named_context -> types
val it_mkNamedProd_wo_LetIn : types -> named_context -> types
val it_mkNamedLambda_or_LetIn : constr -> named_context -> constr

val it_named_context_quantifier :
  (named_declaration -> 'a -> 'a) -> init:'a -> named_context -> 'a

(** {6 Generic iterators on constr} *)

val map_constr_with_named_binders :
  (Name.t -> 'a -> 'a) ->
  ('a -> constr -> constr) -> 'a -> constr -> constr
val map_constr_with_binders_left_to_right :
  (rel_declaration -> 'a -> 'a) ->
  ('a -> constr -> constr) ->
    'a -> constr -> constr
val map_constr_with_full_binders :
  (rel_declaration -> 'a -> 'a) ->
  ('a -> constr -> constr) -> 'a -> constr -> constr

(** [fold_constr_with_binders g f n acc c] folds [f n] on the immediate
   subterms of [c] starting from [acc] and proceeding from left to
   right according to the usual representation of the constructions as
   [fold_constr] but it carries an extra data [n] (typically a lift
   index) which is processed by [g] (which typically add 1 to [n]) at
   each binder traversal; it is not recursive *)

val fold_constr_with_binders :
  ('a -> 'a) -> ('a -> 'b -> constr -> 'b) -> 'a -> 'b -> constr -> 'b

val iter_constr_with_full_binders :
  (rel_declaration -> 'a -> 'a) -> ('a -> constr -> unit) -> 'a ->
    constr -> unit

(**********************************************************************)

val strip_head_cast : constr -> constr
val drop_extra_implicit_args : constr -> constr

(** occur checks *)
exception Occur
val occur_meta : types -> bool
val occur_existential : types -> bool
val occur_meta_or_existential : types -> bool
val occur_evar : existential_key -> types -> bool
val occur_var : env -> Id.t -> types -> bool
val occur_var_in_decl :
  env ->
  Id.t -> 'a * types option * types -> bool
val free_rels : constr -> Int.Set.t
val dependent : constr -> constr -> bool
val dependent_no_evar : constr -> constr -> bool
val count_occurrences : constr -> constr -> int
val collect_metas : constr -> int list
val collect_vars : constr -> Id.Set.t (** for visible vars only *)
val occur_term : constr -> constr -> bool (** Synonymous
 of dependent 
   Substitution of metavariables *)
type meta_value_map = (metavariable * constr) list
val subst_meta : meta_value_map -> constr -> constr

(** Type assignment for metavariables *)
type meta_type_map = (metavariable * types) list

(** [pop c] lifts by -1 the positive indexes in [c] *)
val pop : constr -> constr

(** {6 ... } *)
(** Substitution of an arbitrary large term. Uses equality modulo
   reduction of let *)

(** [subst_term_gen eq d c] replaces [Rel 1] by [d] in [c] using [eq]
   as equality *)
val subst_term_gen :
  (constr -> constr -> bool) -> constr -> constr -> constr

(** [replace_term_gen eq d e c] replaces [d] by [e] in [c] using [eq]
   as equality *)
val replace_term_gen :
  (constr -> constr -> bool) ->
    constr -> constr -> constr -> constr

(** [subst_term d c] replaces [Rel 1] by [d] in [c] *)
val subst_term : constr -> constr -> constr

(** [replace_term d e c] replaces [d] by [e] in [c] *)
val replace_term : constr -> constr -> constr -> constr

(** [subst_closed_term_occ_gen occl n c d] replaces occurrences of closed [c] at
   positions [occl], counting from [n], by [Rel 1] in [d] *)
val subst_closed_term_occ_gen :
  occurrences -> int -> constr -> types -> int * types

(** [subst_closed_term_occ_modulo] looks for subterm modulo a
    testing function returning a substitution of type ['a] (or failing
    with NotUnifiable); a function for merging substitution (possibly
    failing with NotUnifiable) and an initial substitution are
    required too *)

type 'a testing_function = {
  match_fun : constr -> 'a;
  merge_fun : 'a -> 'a -> 'a;
  mutable testing_state : 'a;
  mutable last_found : ((Id.t * hyp_location_flag) option * int * constr) option
}

val make_eq_test : constr -> unit testing_function

exception NotUnifiable

val subst_closed_term_occ_modulo :
  occurrences -> 'a testing_function -> (Id.t * hyp_location_flag) option
  -> constr -> types

(** [subst_closed_term_occ occl c d] replaces occurrences of closed [c] at
   positions [occl] by [Rel 1] in [d] (see also Note OCC) *)
val subst_closed_term_occ : occurrences -> constr -> constr -> constr

(** [subst_closed_term_occ_decl occl c decl] replaces occurrences of closed [c]
   at positions [occl] by [Rel 1] in [decl] *)

val subst_closed_term_occ_decl :
  occurrences * hyp_location_flag -> constr -> named_declaration ->
      named_declaration

val subst_closed_term_occ_decl_modulo :
  occurrences * hyp_location_flag -> 'a testing_function ->
  named_declaration -> named_declaration

val error_invalid_occurrence : int list -> 'a

(** Alternative term equalities *)
val base_sort_cmp : Reduction.conv_pb -> sorts -> sorts -> bool
val compare_constr_univ : (Reduction.conv_pb -> constr -> constr -> bool) ->
  Reduction.conv_pb -> constr -> constr -> bool
val constr_cmp : Reduction.conv_pb -> constr -> constr -> bool
val eq_constr : constr -> constr -> bool

val eta_reduce_head : constr -> constr

exception CannotFilter

(** Lightweight first-order filtering procedure. Unification
   variables ar represented by (untyped) Evars.
   [filtering c1 c2] returns the substitution n'th evar ->
   (context,term), or raises [CannotFilter].
   Warning: Outer-kernel sort subtyping are taken into account: c1 has
   to be smaller than c2 wrt. sorts. *)
type subst = (rel_context*constr) Int.Map.t
val filtering : rel_context -> Reduction.conv_pb -> constr -> constr -> subst

val decompose_prod_letin : constr -> int * rel_context * constr
val align_prod_letin : constr -> constr -> rel_context * constr

(** Get the last arg of a constr intended to be an application *)
val last_arg : constr -> constr

(** Force the decomposition of a term as an applicative one *)
val decompose_app_vect : constr -> constr * constr array

val adjust_app_list_size : constr -> constr list -> constr -> constr list ->
  (constr * constr list * constr * constr list)
val adjust_app_array_size : constr -> constr array -> constr -> constr array ->
  (constr * constr array * constr * constr array)

(** name contexts *)
type names_context = Name.t list
val add_name : Name.t -> names_context -> names_context
val lookup_name_of_rel : int -> names_context -> Name.t
val lookup_rel_of_name : Id.t -> names_context -> int
val empty_names_context : names_context
val ids_of_rel_context : rel_context -> Id.t list
val ids_of_named_context : named_context -> Id.t list
val ids_of_context : env -> Id.t list
val names_of_rel_context : env -> names_context

val context_chop : int -> rel_context -> rel_context * rel_context
val env_rel_context_chop : int -> env -> env * rel_context

(** Set of local names *)
val vars_of_env: env -> Id.Set.t
val add_vname : Id.Set.t -> Name.t -> Id.Set.t

(** other signature iterators *)
val process_rel_context : (rel_declaration -> env -> env) -> env -> env
val assums_of_rel_context : rel_context -> (Name.t * constr) list
val lift_rel_context : int -> rel_context -> rel_context
val substl_rel_context : constr list -> rel_context -> rel_context
val smash_rel_context : rel_context -> rel_context (** expand lets in context *)
val adjust_subst_to_rel_context : rel_context -> constr list -> constr list
val map_rel_context_in_env :
  (env -> constr -> constr) -> env -> rel_context -> rel_context
val map_rel_context_with_binders :
  (int -> constr -> constr) -> rel_context -> rel_context
val fold_named_context_both_sides :
  ('a -> named_declaration -> named_declaration list -> 'a) ->
    named_context -> init:'a -> 'a
val mem_named_context : Id.t -> named_context -> bool

val clear_named_body : Id.t -> env -> env

val global_vars : env -> constr -> Id.t list
val global_vars_set_of_decl : env -> named_declaration -> Id.Set.t

(** Gives an ordered list of hypotheses, closed by dependencies,
   containing a given set *)
val dependency_closure : env -> named_context -> Id.Set.t -> Id.t list

(** Test if an identifier is the basename of a global reference *)
val is_section_variable : Id.t -> bool

val isGlobalRef : constr -> bool

val has_polymorphic_type : constant -> bool

(** Combinators on judgments *)

val on_judgment       : (types -> types) -> unsafe_judgment -> unsafe_judgment
val on_judgment_value : (types -> types) -> unsafe_judgment -> unsafe_judgment
val on_judgment_type  : (types -> types) -> unsafe_judgment -> unsafe_judgment

(** {6 Functions to deal with impossible cases } *)
val set_impossible_default_clause : constr * types -> unit
val coq_unit_judge : unit -> unsafe_judgment
