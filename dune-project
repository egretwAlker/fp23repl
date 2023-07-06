(lang dune 3.8)

(name pf23)

(generate_opam_files true)

(source
 (github egretwalker/pf23))

(authors "XIA Tianxiang")

(maintainers "XIA Tianxiang")

(license LICENSE)

(documentation https://url/to/documentation)

(package
 (name pf23)
 (synopsis "A short synopsis")
 (description "A longer description")
 (depends ocaml dune (ounit2 (= :2.2.7)))
 (tags
  (topics "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
