type element
type prog
type stack
type name
type sdico
type env = stack*sdico
val parse : string -> prog
val text : stack -> string
val eval_prog : env -> prog -> env
val step : env -> element -> env
val empty_env : env
val interpret : string -> string