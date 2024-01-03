all: env test
env:
	uname -a
	@echo
	@sqlite3 --version
	@echo
	@which gawk > /dev/null && gawk --version || awk --version
	@echo
test:
	@./run.sh
