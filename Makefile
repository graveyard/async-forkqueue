# usage:
# `make` or `make test` runs all the tests
# `make error` runs just that test

TESTS=$(shell cd test && ls *.coffee | sed s/\.coffee$$//)

test: $(TESTS)

$(TESTS):
	DEBUG=* NODE_ENV=test node_modules/mocha/bin/mocha --ignore-leaks --compilers coffee:coffee-script test/$@.coffee

.PHONY: test $(TESTS)
