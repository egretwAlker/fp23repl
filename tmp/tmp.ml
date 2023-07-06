type element = B bool | N int | Dup | Drop | Swap | Rot | Add | INF | SUP | EQ

(* *********** Question 1.b *********** *)

let to_string (x:element) : string = 
  failwith "TODO"

let of_string (s:string) : element =
  failwith "TODO"


(* *********** Question 1.c *********** *)

(** fonction utilitaire : 
    [split s] découpe le texte [s] en une suite de mot. 
*)
let split (s:string) : string list =
  (* traite les tabulations et les sauts de lignes comme des espaces *)
  let normalize_s = String.map (function '\n' | '\t' | '\r' -> ' ' | c -> c) s in
  let split_s = String.split_on_char ' ' normalize_s in
  (* ignore les espaces successifs *)
  List.filter ((<>) "") split_s ;;

assert (split "  \t  \n " = []) ;;
assert (split " A     \n B\t C  " = ["A";"B";"C"]) ;;

(** transforme un texte (représentant un programme ou une pile)
    en une suite de symboles du langage (e.g., "42" et "DUP") 
*)
let parse (s:string) : element list =
  failwith "TODO"

(** transforme un suite de symbole du langage (représentant un programme 
    ou une pile) en un texte équivalent. 
    Par exemple : [text (parse "1 2 +")) = "1 2 +"].
*)
let text (p:element list) : string =
  failwith "TODO"

(* *********** Question 2 *********** *)

type prog = element list
type stack = element list

(* fonction auxiliaire : évaluation d'un opérateur binaire *)
let eval_binop op (e1:element) (e2:element) : element =
  failwith "TODO"


(* fonction auxiliaire : évaluation d'un opérateur binaire *)
let eval_stackop (stk:stack) op : stack = 
  failwith "TODO"

(* [step stk e] exécute l'élément [e] dans la pile [stk] 
   et retourne la pile résultante *)
let step (stk:stack) (e:element) : stack =
  failwith "TODO"

(* *********** Question 3 *********** *)

let rec calc (stk:stack) (p:prog) : stack =
  failwith "TODO"

(* *********** Question 4 *********** *)

type name = string
type dico = ..

(* let empty : dico = TODO, à décommenter *)
let add (x:name) (def:prog) (dico:dico) : dico =
  failwith "TODO"

let lookup (x:name) (dico:dico) : prog =
  failwith "TODO"

(* *********** Question 5 *********** *)

let rec eval (dico:dico) (stk:stack) (p:prog) : stack =
  failwith "TODO"
let jeux_de_test = [ (": fact dup 1 > if dup 1 - fact * then ; 6 fact", "720") ]


(* *********** Question 6 *********** *)

let carre n = 
  Printf.sprintf ": carre dup * ; %d carre" n

let fib n = 
  failwith "TODO" ;;

(* *********** Question 7 *********** *)

let jeux_de_test = [ ] ;;