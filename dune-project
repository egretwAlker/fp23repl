(lang dune 3.8)

(name pf23)

(generate_opam_files true)

(authors "XIA Tianxiang")

(maintainers "XIA Tianxiang")

(license MIT)

(version 0.2)

(package
 (name pf23)
 (synopsis "REPL for Pf23")
 (depends ocaml dune (ppx_inline_test (= v0.14.1))))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
