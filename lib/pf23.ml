type name = string
type element = B of bool | N of int | Dup | Drop | Swap | Rot | Add | Sub | Mul | Div | Inf | Sup | Eq | Neq | Id of name
             | If | Then | Else | Endif | Colon | Semic

(** Cond - conditionnel, Def - définition de fonction, Call - état d'exécution (dans un appel de fonction ou l'exécution globale) *)
type scope = Cond of bool option | Def of name option*int*element list | Call

(** liste d'éléments qui peuvent s'appliquer à un stack *)
type prog = element list

(** stack sur lequel on opère *)
type stack = element list

(** dictionnaire réalisé par arbre lexical
*)
module Dico :
sig
  exception Request_dico_failed of name
  type dico
  val empty_dico : dico
  val insert : dico -> name * prog -> dico
  val request : dico -> name -> prog
end
=
struct
exception Request_dico_failed of string
type dico = Node of prog option * (char*dico) list
let empty_dico = Node (None, [])

(** supprime le premier char *)
let tail s = String.sub s 1 (String.length s - 1)

let%test _ = tail "123" = "23"

let rec insert dico p = let Node (q, l) = dico in
  match p with
  | ("", prog) -> Node (Some prog, l)
  | (s, prog) ->
    let (s0, sl) = (s.[0], tail s) in
    match l with
    | [] -> Node (q, [(s0, insert (Node (None, [])) (sl, prog));])
    | (c, d)::l ->
      if s0 = c then
        Node (q, (c, insert d (sl, prog))::l)
      else
        let Node (q, l) = insert (Node (q, l)) p in Node (q, (c, d)::l)

let rec request dico s =
  let Node (q, l) = dico in
  let fail () = raise (Request_dico_failed s) in
  match s with
  | "" -> (match q with Some prog -> prog | None -> fail ())
  | _ ->
    let (s0, sl) = (s.[0], tail s) in
    match l with
    | [] -> fail ()
    | (c, d)::l ->
      if s0 = c then request d sl
      else request (Node (q, l)) s
  
  let%test _ = request (insert (insert empty_dico ("name", [N 1])) ("name", [B false])) "name" = [B false]
  let%test _ = request (insert (insert empty_dico ("name", [N 1])) ("namee", [B false])) "name" = [N 1]
end

open Dico

(** stack de dictionnaires, chaque élémenet d'un stack correspond à un scope *)
type sdico = (scope*dico) list

type env = stack*sdico

let option_not = function None -> None | Some x -> Some (not x)

(** est opérateur binaire *)
let is_binop e = List.mem e [Add; Sub; Mul; Div; Inf; Sup; Eq; Neq]

(** est stack opérateur *)
let is_stackop e = List.mem e [Dup; Drop; Swap; Rot]

(** les éléments basiques sont ceux qui s'appliquenent directement sur un stack sans étape intermédiare *)
let is_basic = function Id _ -> false | If -> false | Then -> false | Else -> false | Colon -> false | Semic -> false | _ -> true

let to_string : element -> string = function B true -> "TRUE" | B false -> "FALSE" | N x -> string_of_int x
                                           | Dup -> "DUP" | Drop -> "DROP" | Swap -> "SWAP" | Rot -> "ROT"
                                           | Add -> "+" |  Sub -> "-" | Mul -> "*" | Div -> "/" | Inf -> "<" | Sup -> ">" | Eq -> "=" | Neq -> "<>"
                                           | Id s -> s | If -> "IF" | Then -> "THEN" | Else -> "ELSE" | Endif -> "ENDIF" | Colon -> ":" | Semic -> ";"

let of_string = function "TRUE" -> B true | "FALSE" -> B false
                       | "DUP" -> Dup | "DROP" -> Drop | "SWAP" -> Swap | "ROT" -> Rot
                       | "+" -> Add | "-" -> Sub | "*" -> Mul | "/" -> Div | "<" -> Inf | ">" -> Sup | "=" -> Eq | "<>" -> Neq
                       | "IF" -> If | "THEN" -> Then | "ELSE" -> Else | "ENDIF" -> Endif | ":" -> Colon | ";" -> Semic
                       | s -> try N (int_of_string s) with Failure _ -> Id s

let%test _ = to_string (N 1) = "1"
let%test _ = of_string "-1" = N (-1)

let fail_at e = failwith ("Failed at element \""^to_string e^"\"")
let expect s = failwith ("\""^s^"\" expected")

(** fonction utilitaire : 
    [split s] découpe le texte [s] en une suite de mot. 
*)
let split (s:string) : string list =
  (* traite les tabulations et les sauts de lignes comme des espaces *)
  let normalize_s = String.map (function '\n' | '\t' | '\r' -> ' ' | c -> c) s in
  let split_s = String.split_on_char ' ' normalize_s in
  (* ignore les espaces successifs *)
  List.filter ((<>) "") split_s ;;

let%test _ = split "A \n B   C" = ["A";"B";"C"]

(** transforme un texte (représentant un programme ou une pile)
    en une suite de symboles du langage (e.g., "42" et "DUP") 
*)
let parse (s:string) : prog = List.map of_string (split s)

let rec text (p:prog) : string = match p with [] -> "" | e::[] -> to_string e | e::p -> to_string e^" "^text p

(** fonction auxiliaire : évaluation d'un opérateur binaire *)
let eval_binop op (e1:element) (e2:element) : element = match (e1, e2) with (N x, N y) -> (
    match op with Add -> N (y+x) | Sub -> N (y-x) | Mul -> N (y*x) | Div -> N (y/x)
                | Inf -> B (y < x) | Sup -> B (x < y)
              | Eq -> B (y=x) | Neq -> B (y <> x)
              | _ -> expect "binop"
  ) | _ -> fail_at op

(** fonction auxiliaire : évaluation d'un opérateur pile *)
let eval_stackop (stk:stack) op : stack =
  match op with Dup -> (match stk with e::l -> e::e::l | _ -> fail_at op)
              | Drop -> (match stk with _::l -> l | _ -> fail_at op)
              | Swap -> (match stk with a::b::l -> b::a::l | _ -> fail_at op)
              | Rot -> (match stk with a::b::c::l -> b::c::a::l | _ -> fail_at op)
              | _ -> expect "stackop"

(** fonction auxiliaire :  évaluation des opérateurs basiques (non appel de fonction, c.f. [is_basic]) *)
let eval_basic (stk:stack) (e:element) : stack =
  if is_basic e then
    if is_binop e then match stk with e1::e2::l -> eval_binop e e1 e2::l | _ -> fail_at e
    else if is_stackop e then eval_stackop stk e
    else e::stk (* it must be N or B *)
  else expect "basic"

(** fonction auxiliaire : shorthand pour prendre des valeurs d'un env *)
let unpack (env : env) = 
  match env with (stk, (sp, dico)::l) -> (stk, sp, dico, l, (sp, dico)::l)
               | _ -> failwith "No dico found, bad env"

(** si l'env est en état effectif
  état effectif : en scope de Call ou Cond (Some true), i.e. on peut affecter le stack
*)
let effective env =
  let (_, sp, _, _, _) = unpack env in
  match sp with Cond (Some true) -> true | Call -> true | _ -> false

(** obtient le stack d'un env *)
let get_stk : env -> stack = function (stk, _) -> stk

(** trouve un prog correspondant à name dans sdico *)
let rec find (sdico:sdico) (name:name) : prog =
  match sdico with
  | [] -> failwith ("\""^name^"\" not found in sdico")
  | (_, dico)::l -> (try request dico name with Request_dico_failed _ -> find l name)

(* Les 2 fonctions suivantes sont essentielles. c.f. README.md/Implémenntation, algorithme *)

let rec eval_prog env prog = 
  match prog with
    [] -> env
    | e::progl ->
      if not (effective env) then eval_prog (step env e) progl else
        let (stk, _, _, l, sdico) = unpack env in
        let make_env ?(stk=stk) ?(sdico=sdico) sp  = (stk, (sp, empty_dico)::sdico) in

        match e with
          Id s -> eval_prog (get_stk (eval_prog (make_env Call) (find sdico s)), sdico) progl
        | Colon -> eval_prog (make_env (Def (None, 0, []))) progl
        | If -> (match stk with (B b)::stkl -> eval_prog (make_env ~stk:stkl (Cond (Some b))) progl | _ -> failwith "If failed because stack empty or top non boolean")
        | Then -> eval_prog (stk, l) progl
        | Endif -> eval_prog (stk, l) progl
        | Else -> eval_prog (make_env ~sdico:l (Cond (Some false))) progl
        | _ -> if is_basic e then eval_prog (eval_basic stk e, sdico) progl
                             else fail_at e

and step env e =
  if effective env then eval_prog env [e;] else

  let end_def (env:env) =
    match env with
    | (stk, (Def (Some name, _, reg), _)::(sp, dico)::l)
      -> (stk, (sp, insert dico (name, List.rev reg))::l)
    | _ -> failwith "Can not end_def, no outter dico" in

  let (stk, sp, _, l, sdico) = unpack env in
  let make_env sp sdico = (stk, (sp, empty_dico)::sdico) in

  match sp with
  | Cond c -> begin
    match e with
    | If -> make_env (Cond None) sdico
    | Then -> (stk, l)
    | Endif -> (stk, l)
    | Else -> make_env (Cond (option_not c)) l
    | _ -> env
  end
  | Def (name, cnt, reg) ->
    if name = None then begin
      match e with Id s -> make_env (Def (Some s, cnt, reg)) l | _ -> expect "Id"
    end else begin
      match e with Colon -> make_env (Def (name, cnt+1, e::reg)) l
                 | Semic -> if cnt = 0 then end_def env
                                       else make_env (Def (name, cnt-1, e::reg)) l
                 | _ -> make_env (Def (name, cnt, e::reg)) l
    end
  | Call -> failwith "Unkonwn error"

let empty_env = ([], [(Call, empty_dico);])

let interpret s = s |> parse |> eval_prog empty_env |> get_stk |> text

let%test _ = (interpret "1 2 +") = "3"

let%test "factorial" = (interpret ": FACTORIELLE DUP 1 > IF DUP 1 - FACTORIELLE * THEN ; 6 FACTORIELLE") = "720"

let%test "non-mod-add" = interpret ": $+ DUP ROT ROT DUP ROT + ROT SWAP ROT ROT ; 1 2 $+" = "3 2 1"

let%test "fibonacci" = (interpret ": $+ DUP ROT ROT DUP ROT + ROT SWAP ROT ROT ;
                                   : FIB 0 1 : FIB ROT ROT DUP 0 = IF DROP DROP ELSE 1 - ROT $+ ROT ROT DROP FIB ENDIF ; FIB ;
                                   7 FIB FIB") = "233"
let%test "fibonacci_bis" = (interpret ": FIB : $+ DUP ROT ROT DUP ROT + ROT SWAP ROT ROT ; 0 1 : FIB ROT ROT DUP 0 = IF DROP DROP ELSE 1 - ROT $+ ROT ROT DROP FIB ENDIF ; FIB ;
                                      7 FIB FIB") = "233"
let%test "grammar" = (interpret "TRUE IF 2 ELSE 3 ELSE 4") = "4 2"

(* the preparational layout *)
let%test "prime_prepa" = (interpret ": $+ DUP ROT ROT DUP ROT + ROT SWAP ROT ROT ;
                               : $- DUP ROT ROT DUP ROT - ROT SWAP ROT ROT ;
                               : #+ $+ SWAP DROP ;
                               : #- $- SWAP DROP ;
                               : $= DUP ROT ROT DUP ROT = ROT SWAP ROT ROT ;
                               : DDUP $+ $- SWAP $- SWAP DROP ;
                               : PM 1 : AUX $= IF DROP DROP ELSE DDUP 1 + AUX THEN ; AUX ; 6 PM") = "5 6 4 6 3 6 2 6 1 6"

(* test if a number >= 3 is a prime number *)
let%test "prime" = (interpret ": $+ DUP ROT ROT DUP ROT + ROT SWAP ROT ROT ;
                               : $- DUP ROT ROT DUP ROT - ROT SWAP ROT ROT ;
                               : #+ $+ SWAP DROP ;
                               : #- $- SWAP DROP ;
                               : $= DUP ROT ROT DUP ROT = ROT SWAP ROT ROT ;
                               : #= $= SWAP DROP ;
                               : DDUP $+ $- SWAP $- SWAP DROP ;
                               : PM 1
                                : AUX $= IF DROP DROP ELSE DDUP 1 + AUX THEN ; AUX
                                : AUX DUP ROT ROT DUP ROT SWAP / ROT ROT * = IF : CLR 1 = IF DROP ELSE DROP CLR THEN ; CLR FALSE ELSE 1 #= IF DROP DROP TRUE ELSE AUX THEN ;
                                AUX ;
                                1237 PM 1234 PM 123 PM 13 PM 7 PM 6 PM 5 PM") = "TRUE FALSE TRUE TRUE FALSE FALSE TRUE"