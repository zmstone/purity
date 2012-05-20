# vim: set noet ts=8 sw=8:

.PHONY: compille units clean count build_tests tests dialyzer_plt dialyzer docs

ERLC ?= erlc
DIALYZER ?= dialyzer

EFLAGS += -DVSN='"$(VSN)"' +debug_info +warn_exported_vars +warn_unused_vars +warn_unused_import +warn_missing_spec
DFLAGS += -n -Wunmatched_returns -Wunderspecs -Wrace_conditions -Wbehaviours

ESRC ?= src
EBIN ?= ebin
TEST ?= test
SCRIPTS ?= scripts

include vsn.mk
VSN := $(PURITY_VSN)

FILES := purity purity_collect purity_analyse \
	 purity_cli purity_plt \
	 purity_utils purity_stats purity_bifs \
	 cl_parser core_aliases runtest

SRC   := $(addsuffix .erl, $(FILES))
BIN   := $(addprefix $(EBIN)/, $(addsuffix .beam, $(FILES)))
CHEATS := predef/cheats predef/bifs predef/primops

GENERATED := $(ESRC)/purity_bifs.erl

TEST_SRC := $(wildcard $(TEST)/*.erl)
TEST_BIN := $(patsubst %.erl, %.beam, $(TEST_SRC))


all: $(EBIN) $(BIN)
	./rebar skip_deps=true escriptize

## Dependencies ##

$(EBIN): compile

## Generic rules ##

$(TEST)/%.beam: $(TEST)/%.erl
	@echo "T  ERLC $<"
	@$(ERLC) $(EFLAGS) -o $(dir $<) $<

%.html: %.txt
	asciidoc $<

$(GENERATED): $(CHEATS)
	@$(SCRIPTS)/purity_bifs $^ > $@

## Specific rules ##

build_tests: $(TEST_BIN)
	@echo "Done building test files."

tests: $(BIN) build_tests
	$(SCRIPTS)/runtests $(TEST_BIN)

units:
	EFLAGS=-DTEST $(MAKE)
	@./scripts/utests `echo src/*_tests.hrl | sed 's/_tests//g'`


dialyzer: $(EBIN) $(BIN)
	$(DIALYZER) $(DFLAGS) -c $(BIN)

dialyzer_plt:
	$(DIALYZER) --build_plt --apps erts compiler dialyzer hipe kernel stdlib syntax_tools


README.html: README.asciidoc TODO changelog
	asciidoc -a numbered $<

# eDoc related stuff:
APP_NAME = purity
DOCOPTS = [{def,{vsn,"$(VSN)"}},{stylesheet,"style.css"},todo]

DOCFILES := $(addsuffix .html, $(FILES) index overview-summary modules-frame packages-frame)\
            erlang.png edoc-info

docs:
	erl -noshell -run edoc_run application "'$(APP_NAME)'" '"."' '$(DOCOPTS)'


clean:
	./rebar clean

distclean: clean
	$(RM) $(TEST_BIN) README.html $(addprefix doc/,$(DOCFILES))

count:
	@sloccount . | awk '/^SLOC\t/,/^Total Physical/ { print }' | grep -v '^$$'

compile: $(GENERATED)
	./rebar compile

