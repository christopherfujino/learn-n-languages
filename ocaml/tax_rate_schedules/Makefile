PROJ_NAME = tax_rate_schedules

.PHONY: run
run: build
	dune exec $(PROJ_NAME)

# This is phony because let dune determine how to build
.PHONY: build
build:
	dune build
