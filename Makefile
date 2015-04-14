all:
	ocamlc -ccopt -O3 -c inline_option_runtime.c
	ocamlopt -c inline_option.mli
	ocamlopt -c inline_option.ml
	ocamlopt -c test.ml
	ocamlopt -cclib inline_option_runtime.o -o test.exe inline_option.cmx test.cmx
	time -f "%U user" ./test.exe
