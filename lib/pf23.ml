type element = B of bool | N of int | Dup | Drop | Swap | Rot | Add | Sub | Mul | Div | Inf | Sup | Eq | Neq | Id of string
             | If | Then | Else | Endif | Colon | Semic
type name = string
type scope = Cond of bool option | Def of name option*int*element list | Call
type prog = element list
type stack = element list
type dico = (name*prog) list
type sdico = (scope*dico) list
type env = stack*sdico

let option_not = function None -> None | Some x -> Some (not x)

let is_binop e = List.mem e [Add; Sub; Mul; Div; Inf; Sup; Eq; Neq]
let is_stackop e = List.mem e [Dup; Drop; Swap; Rot]

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

let fail_at e = failwith ("Failed at element \""^to_string e^"\"")
let expect s = failwith ("\""^s^"\" expected")
let not_expected s = failwith ("\""^s^"\" not expected")

(** fonction utilitaire : 
    [split s] découpe le texte [s] en une suite de mot. 
*)
let split (s:string) : string list =
  (* traite les tabulations et les sauts de lignes comme des espaces *)
  let normalize_s = String.map (function '\n' | '\t' | '\r' -> ' ' | c -> c) s in
  let split_s = String.split_on_char ' ' normalize_s in
  (* ignore les espaces successifs *)
  List.filter ((<>) "") split_s ;;

(** transforme un texte (représentant un programme ou une pile)
    en une suite de symboles du langage (e.g., "42" et "DUP") 
*)
let parse (s:string) : element list = List.map of_string (split s)

(** transforme une suite de symboles du langage (représentant un programme ou une pile) en un texte équivalent. 
    Par exemple : [text (parse "1 2 +")) = "1 2 +"].
*)
let rec text (p:element list) : string = match p with [] -> "" | e::[] -> to_string e | e::p -> to_string e^" "^text p

(* fonction auxiliaire : évaluation d'un opérateur binaire *)
let eval_binop op (e1:element) (e2:element) : element = match (e1, e2) with (N x, N y) -> (
    match op with Add -> N (y+x) | Sub -> N (y-x) | Mul -> N (y*x) | Div -> N (y/x)
                | Inf -> B (y < x) | Sup -> B (x < y)
                | Eq -> B (y=x) | Neq -> B (y <> x)
                | _ -> expect "binop"
  ) | _ -> fail_at op

(* fonction auxiliaire : évaluation d'un opérateur binaire *)
let eval_stackop (stk:stack) op : stack =
  match op with Dup -> (match stk with e::l -> e::e::l | _ -> fail_at op)
              | Drop -> (match stk with _::l -> l | _ -> fail_at op)
              | Swap -> (match stk with a::b::l -> b::a::l | _ -> fail_at op)
              | Rot -> (match stk with a::b::c::l -> b::c::a::l | _ -> fail_at op)
              | _ -> expect "stackop"

(* [step stk e] exécute l'élément [e] dans la pile [stk] 
   et retourne la pile résultante *)
let eval_basic (stk:stack) (e:element) : stack =
  if is_basic e then
    if is_binop e then match stk with e1::e2::l -> eval_binop e e1 e2::l | _ -> fail_at e
    else if is_stackop e then eval_stackop stk e
    else e::stk (* it must be N or B *)
  else expect "basic"

let unpack (env:env) = 
  match env with (stk, (sp, dico)::l) -> (stk, sp, dico, l, (sp, dico)::l)
               | _ -> failwith "No dico found, bad env"

let rec find (sdico:sdico) (name:name) : prog =
  match sdico with [] -> failwith "Find failed"
                 | (_, [])::l -> find l name
                 | (sp, (name', prog)::d)::l -> if name=name' then prog else find ((sp, d)::l) name

let effective env =
  let (_, sp, _, _, _) = unpack env in
  match sp with Cond (Some true) -> true | Call -> true | _ -> false

let get_stk = function (stk, _) -> stk

let rec eval_prog env prog = 
  let (stk, _, _, l, sdico) = unpack env in
  let make_env sp sdico = (stk, (sp, [])::sdico) in

  match prog with [] -> env | e::progl ->
    if not (effective env) then eval_prog (step env e) progl else
      match e with
        Id s -> eval_prog (get_stk (eval_prog (make_env Call sdico) (find sdico s)), sdico) progl
      | Colon -> eval_prog (make_env (Def (None, 0, [])) sdico) progl
      | If -> (match stk with (B b)::stkl -> eval_prog (stkl, (Cond (Some b), [])::sdico) progl | _ -> failwith "If failed because stack empty or top non boolean")
      | Then -> (stk, l)
      | _ -> if is_basic e then eval_prog (eval_basic stk e, sdico) progl
        else fail_at e

and step env e =
  if effective env then eval_prog env [e;] else

    let end_def (env:env) =
      match env with (stk, (Def (Some name, _, reg), _)::(sp, dico)::l) -> (stk, (sp, (name, List.rev reg)::dico)::l) | _ -> failwith "Can not end_def, no outter dico" in

    let (stk, sp, _, l, sdico) = unpack env in
    let make_env sp sdico = (stk, (sp, [])::sdico) in

    match sp with
    | Cond c -> (match e with If -> make_env (Cond None) sdico | Then -> (stk, l) | Endif -> (stk, l) | Else -> make_env (Cond (option_not c)) l | _ -> env)
    | Def (name, cnt, reg) ->
      if name = None then
        (match e with Id s -> make_env (Def (Some s, cnt, reg)) l | _ -> expect "Id")
      else begin
        match e with Colon -> make_env (Def (name, cnt+1, e::reg)) l
                   | Semic -> if cnt = 0 then end_def env
                     else make_env (Def (name, cnt-1, e::reg)) l
                   | _ -> make_env (Def (name, cnt, e::reg)) l
      end
    | Call -> failwith "Unkonwn error"

let empty_env = ([], [(Call, []);])

let interpret s = s |> parse |> eval_prog empty_env |> get_stk |> text