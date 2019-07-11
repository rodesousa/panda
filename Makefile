.PHONY: deps
deps:
	mix deps.get

.PHONY: repl
repl:
	iex -S mix
