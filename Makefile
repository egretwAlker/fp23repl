.PHONY: build test run
build:
	dune build
release:
	dune build --release
test:
	dune test
run:
	dune exec pf23