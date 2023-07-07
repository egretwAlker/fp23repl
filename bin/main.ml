open Pf23

let show (env : env) : env = match env with (stk, _) -> print_endline (text stk); env

let main () =
  let rec repl env =
    print_string "pf23> ";
    repl (read_line () |> parse |> eval_prog env |> show)
  in repl empty_env;;

main ();;