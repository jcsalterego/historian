.PHONY: test
all:
test:
	@cd test && make --no-print-directory env test
