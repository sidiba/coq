(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2013     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)
open Term
open Names
open Declarations
open Pre_env
open Nativelambda

(** This file defines the mllambda code generation phase of the native
compiler. mllambda represents a fragment of ML, and can easily be printed
to OCaml code. *)

type mllambda
type global

val pp_global : Format.formatter -> global -> unit

val mk_open : string -> global

type symbol

val get_value : symbol array -> int -> Nativevalues.t

val get_sort : symbol array -> int -> sorts

val get_name : symbol array -> int -> name

val get_const : symbol array -> int -> constant

val get_match : symbol array -> int -> Nativevalues.annot_sw

val get_ind : symbol array -> int -> inductive

val get_symbols_tbl : unit -> symbol array

type code_location_update
type code_location_updates
type linkable_code = global list * code_location_updates

val empty_updates : code_location_updates

val register_native_file : string -> unit

val compile_constant_field : env -> string -> constant ->
  global list * symbol list * code_location_updates ->
  constant_body ->
    global list * symbol list * code_location_updates

val compile_mind_field : string -> module_path -> label ->
  global list * symbol list * code_location_updates ->
  mutual_inductive_body ->
    global list * symbol list * code_location_updates

val mk_conv_code : env -> string -> constr -> constr -> linkable_code
val mk_norm_code : env -> string -> constr -> linkable_code

val mk_library_header : dir_path -> global list

val mod_uid_of_dirpath : dir_path -> string

val update_locations : code_location_updates -> unit
