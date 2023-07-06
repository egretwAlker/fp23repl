open OUnit2
open Pf23

let t_to_string _ = assert_equal (Pf23.to_string (N 1)) "1"
let t_of_string _ = assert_equal (Pf23.of_string "-1") (N (-1))
let t_split _ = assert_equal (split "  \t  \n ") []; assert_equal (split " A     \n B\t C  ") ["A"; "B"; "C"]

let t_parser =
  "parser" >::: [
    "to_string" >:: t_to_string;
    "of_string" >:: t_of_string;
    "split" >:: t_split;
  ]

let t_eval =
  "eval" >::: [
    "test1" >:: (fun _ -> assert_equal (interpret "1 2 +") "3");
    "factorial" >:: (fun _ -> assert_equal (interpret ": FACTORIELLE DUP 1 > IF DUP 1 - FACTORIELLE * THEN ; 6 FACTORIELLE") "720");
  ]

let () =
  run_test_tt_main t_parser;
  run_test_tt_main t_eval;