(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2012     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(*i*)
open Errors
open Util
open Pp
open Names
open Term
open Declarations
(*i*)

let error_not_a_constant l =
  error ("\""^(Label.to_string l)^"\" is not a constant")

let error_not_a_functor _ = error "Application of not a functor"

let error_incompatible_modtypes _ _ = error "Incompatible module types"

let error_not_match l _ =
  error ("Signature components for label "^Label.to_string l^" do not match")

let error_no_such_label l = error ("No such label "^Label.to_string l)

let error_no_such_label_sub l l1 =
  let l1 = string_of_mp l1 in
  error ("The field "^
         Label.to_string l^" is missing in "^l1^".")

let error_not_a_module_loc loc s =
  user_err_loc (loc,"",str ("\""^Label.to_string s^"\" is not a module"))

let error_not_a_module s = error_not_a_module_loc Loc.ghost s

let error_with_incorrect l =
  error ("Incorrect constraint for label \""^(Label.to_string l)^"\"")

let error_a_generative_module_expected l =
  error ("The module " ^ Label.to_string l ^ " is not generative. Only " ^
         "component of generative modules can be changed using the \"with\" " ^
         "construct.")

let error_signature_expected mtb =
  error "Signature expected"

let error_application_to_not_path _ = error "Application to not path"

let destr_functor env mtb =
  match mtb with
  | SEBfunctor (arg_id,arg_t,body_t) ->
      	    (arg_id,arg_t,body_t)
  | _ -> error_not_a_functor mtb

let module_body_of_type mp mtb = 
  { mod_mp = mp;
    mod_type = mtb.typ_expr;
    mod_type_alg = mtb.typ_expr_alg;
    mod_expr = None;
    mod_constraints = mtb.typ_constraints;
    mod_delta = mtb.typ_delta;
    mod_retroknowledge = []}

let rec add_signature mp sign resolver env = 
  let add_one env (l,elem) =
    let kn = KerName.make2 mp l in
    let con = Constant.make1 kn in
    let mind = mind_of_delta resolver (MutInd.make1 kn) in
      match elem with
	| SFBconst cb -> 
	   (* let con =  constant_of_delta resolver con in*)
	      Environ.add_constant con cb env
	| SFBmind mib -> 
	   (* let mind =  mind_of_delta resolver mind in*)
	    Environ.add_mind mind mib env
	| SFBmodule mb -> add_module mb env
	      (* adds components as well *)
	| SFBmodtype mtb -> Environ.add_modtype mtb.typ_mp mtb env
  in
    List.fold_left add_one env sign

and add_module mb env = 
  let mp = mb.mod_mp in
  let env = Environ.shallow_add_module mp mb env in
    match mb.mod_type with
      | SEBstruct (sign) -> 
	    add_signature mp sign mb.mod_delta env
      | SEBfunctor _ -> env
      | _ -> anomaly ~label:"Modops" (Pp.str "the evaluation of the structure failed ")


let strengthen_const mp_from l cb resolver =
  match cb.const_body with
    | Def _ -> cb
    | _ ->
      let con = Constant.make2 mp_from l in
      (* let con =  constant_of_delta resolver con in*)
      { cb with const_body = Def (Declarations.from_val (Const con)) }

let rec strengthen_mod mp_from mp_to mb =
  if Declarations.mp_in_delta mb.mod_mp mb.mod_delta then
    mb
  else
    match mb.mod_type with
     | SEBstruct (sign) -> 
	 let resolve_out,sign_out = 
	   strengthen_sig mp_from sign mp_to mb.mod_delta in
	   { mb with
	       mod_expr = Some (SEBident mp_to);
	       mod_type = SEBstruct(sign_out);
	       mod_type_alg = mb.mod_type_alg;
	       mod_constraints = mb.mod_constraints;
	       mod_delta = resolve_out(*add_mp_delta_resolver mp_from mp_to 
	       (add_delta_resolver mb.mod_delta resolve_out)*);
	       mod_retroknowledge = mb.mod_retroknowledge}
     | SEBfunctor _ -> mb
     | _ -> anomaly ~label:"Modops" (Pp.str "the evaluation of the structure failed ")
	 
and strengthen_sig mp_from sign mp_to resolver =
  match sign with
    | [] -> empty_delta_resolver,[]
    | (l,SFBconst cb) :: rest ->
	let item' = l,SFBconst (strengthen_const mp_from l cb resolver) in
	let resolve_out,rest' = strengthen_sig mp_from rest mp_to resolver in
	resolve_out,item'::rest'
    | (_,SFBmind _ as item):: rest ->
	let resolve_out,rest' = strengthen_sig mp_from rest mp_to resolver in
	  resolve_out,item::rest'
    | (l,SFBmodule mb) :: rest ->
	let mp_from' = MPdot (mp_from,l) in
	let mp_to' = MPdot(mp_to,l) in
	let mb_out = strengthen_mod mp_from' mp_to' mb in
	let item' = l,SFBmodule (mb_out) in
	let resolve_out,rest' = strengthen_sig mp_from rest mp_to resolver in
	resolve_out (*add_delta_resolver resolve_out mb.mod_delta*),
	item':: rest'
    | (l,SFBmodtype mty as item) :: rest -> 
	let resolve_out,rest' = strengthen_sig mp_from rest mp_to resolver in
	resolve_out,item::rest'

let strengthen mtb mp =
    match mtb.typ_expr with
      | SEBstruct (sign) -> 
	  let resolve_out,sign_out =
	    strengthen_sig mtb.typ_mp sign mp mtb.typ_delta in
	    {mtb with
	       typ_expr = SEBstruct(sign_out);
	       typ_delta = resolve_out(*add_delta_resolver mtb.typ_delta
		(add_mp_delta_resolver mtb.typ_mp mp resolve_out)*)}
      | SEBfunctor _ -> mtb
      | _ -> anomaly ~label:"Modops" (Pp.str "the evaluation of the structure failed ")

let subst_and_strengthen mb mp =
  strengthen_mod mb.mod_mp mp (subst_module (map_mp mb.mod_mp mp) mb)


let module_type_of_module mp mb =
  match mp with
      Some mp ->
	strengthen {
	  typ_mp = mp;
	  typ_expr = mb.mod_type;
	  typ_expr_alg = None;
	  typ_constraints = mb.mod_constraints;
	  typ_delta = mb.mod_delta} mp
	  
    | None ->
	{typ_mp = mb.mod_mp;
	 typ_expr = mb.mod_type;
	 typ_expr_alg = None;
	 typ_constraints = mb.mod_constraints;
	 typ_delta = mb.mod_delta}
