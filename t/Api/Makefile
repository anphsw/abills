.SILENT: all
.SILENT: user
.SILENT: admin

# base params
PERL          := /usr/bin/perl
SEARCH_DIR    := ../../Abills
EXECUTE_DIR   := $(shell pwd)/
TESTS         := $(shell find $(SEARCH_DIR) -name "Api.t")
KEY           := $(shell cat .KEY)
$(eval ARRAY  := $(ARRAY) 'Global.t SKIP_OWN_TESTS=1 ')

# arguments
KEY		?= null

all:
	$(foreach test, $(TESTS), \
		echo $(test); perl $(test) KEY=${KEY} DEBUG=$(DEBUG); )

user:
	$(foreach test, $(TESTS), \
		perl $(test) USER='1';)

admin:
	$(foreach test, $(TESTS), \
		perl $(test) ADMIN='1' KEY=${KEY};)


help:
	@echo "ABillS RESTFul JSON API tests"
	@echo "Usage: make [target] [variable=value]"
	@echo ""
	@echo "Targets:"
	@echo "  all            Execute all tests (default target)"
	@echo "  admin          Execute admin tests"
	@echo "  user           Execute user tests"
	@echo "  help           Display this help message"
	@echo ""
	@echo "Variables:"
	@echo "  KEY      ADMIN API KEY required for admin tests"
	@echo ""
	@echo "Examples:"
	@echo "  make                 Run with default all target"
	@echo "  make KEY=TEST_KEY    Execute admin paths with key"
