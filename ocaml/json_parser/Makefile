.PHONY: run
run: a.out
	OCAMLRUNPARAM=b ./a.out

a.out: main.ml
	ocamlc -g -warn-error +A main.ml
