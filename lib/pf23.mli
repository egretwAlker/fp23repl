type element
type prog = element list
type stack
type name
type sdico
type env = stack*sdico
val parse : string -> prog

(** transforme une suite de symboles du langage (représentant un programme ou une pile) en un texte équivalent. 
    Par exemple : [text (parse "1 2 +")) = "1 2 +"].
*)
val text : stack -> string

(** applique un programme à env et retourne le résultat *)
val eval_prog : env -> prog -> env

(** applique un element à env et retourne le résultat *)
val step : env -> element -> env

val empty_env : env

(** evalue un programme pf23 et renvoye le résultat *)
val interpret : string -> string