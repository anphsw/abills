.SILENT: all
.SILENT: user
.SILENT: admin

# base params
PERL          := /usr/bin/perl
SEARCH_DIR    := ../../Abills

ifneq ($(MODULE), "")
   #$(info Copying custom header)
   SEARCH_DIR := ../../Abills/modules/$(MODULE)
endif

EXECUTE_DIR   := $(shell pwd)/
TESTS         := $(shell find $(SEARCH_DIR) -name "Api.t")
KEY           := $(shell cat .KEY)
$(eval ARRAY  := $(ARRAY) 'Global.t SKIP_OWN_TESTS=1 ')


# arguments
KEY		?= null



all:
	$(foreach test, $(TESTS), \
		echo "TEST: " $(test); perl $(test) KEY=${KEY} URL=$(URL) EXECUTABLE_TESTS=$(EXECUTABLE_TESTS) DEBUG=$(DEBUG); )

direct:
	$(foreach test, $(TESTS), \
		echo "DIRECT: "; perl $(test) KEY=${KEY} URL=$(URL) EXECUTABLE_TESTS=$(EXECUTABLE_TESTS) DIRECT=1 DEBUG=$(DEBUG); )

user:
	$(foreach test, $(TESTS), \
		perl $(test) USER='1';)

admin:
	$(foreach test, $(TESTS), \
		perl $(test) ADMIN='1' KEY=${KEY};)

custom:
	$(foreach test,$(shell find Custom/ -name "Api.t"), \
		perl $(test) KEY=${KEY} URL=$(URL) EXECUTABLE_TESTS=$(EXECUTABLE_TESTS) DIRECT=1 DEBUG=$(DEBUG);)


help:
	@echo "ABillS RESTFul JSON API tests"
	@echo "Usage: make [target] [variable=value]"
	@echo ""
	@echo "Targets:"
	@echo "  all            Execute all tests (default target)"
	@echo "  direct         Execute direct calls of tests"
	@echo "  admin          Execute admin tests"
	@echo "  user           Execute user tests"
	@echo "  help           Display this help message"
	@echo ""
	@echo "Variables:"
	@echo "  KEY      ADMIN API KEY required for admin tests"
	@echo "  DEBUG    Debug mode. LVL 5 Debug is direct calls and SQL requests"
	@echo "  DIRECT   Executes tests with direct calls of functions"
	@echo "  URL      Test system URL"
	@echo "  MODULE   Tst only module"
	@echo "  EXECUTABLE_TESTS Test only one route  (Example: get/user/internet/session/active/) "
	@echo ""
	@echo "Examples:"
	@echo "  make                 Run with default all target"
	@echo "  make KEY=TEST_KEY    Execute admin paths with key"
