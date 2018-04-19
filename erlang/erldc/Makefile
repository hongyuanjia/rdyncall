# Be sure to 'make clean' after changing the version
VERSION=1.0

OUTPUTS = priv/erldc.so ebin/dyncall.beam ebin/erldc.app

# Used by install target.  Default empty PREFIX is for a real install to root filesystem (/).
# Override PREFIX for testing or for a staged install
PREFIX=
ERLANG_INST_DIR=/usr/lib64/erlang

all: $(OUTPUTS)

priv/erldc.so: c_src/dyncallnif.c
	[ -d priv ] || mkdir priv
	$(CC) -o $@ -shared -fPIC $(CFLAGS) c_src/dyncallnif.c -ldyncall_s

priv/erldc_testtargets.so: c_src/erldctesttargets.c
	[ -d priv ] || mkdir priv
	$(CC) -o $@ -shared -fPIC c_src/erldctesttargets.c

ebin/dyncall.beam: src/dyncall.erl
	[ -d ebin ] || mkdir ebin
	erlc +debug_info -o ebin src/dyncall.erl

ebin/erldc.app: src/erldc.app.src
	[ -d ebin ] || mkdir ebin
	sed -e 's/---VERSION---/$(VERSION)/' src/erldc.app.src >$@

# Dialyzer, credit to erlang.mk 
DIALYZER_OPTS ?= -Werror_handling -Wrace_conditions \
	-Wunmatched_returns # -Wunderspecs

build-plt: 
	rm -f test/*.beam
	dialyzer --build_plt --output_plt dyncall.plt \
		--apps erts kernel stdlib .

dialyze: $(OUTPUTS)
	dialyzer --src src --plt dyncall.plt --no_native $(DIALYZER_OPTS)

tests: $(OUTPUTS) priv/erldc_testtargets.so
	mkdir -p log
	# Add priv to runtime ld path so we get test targets
	export LD_LIBRARY_PATH=$$(pwd)/priv:${LD_LIBRARY_PATH}; \
		ct_run -pa ebin -logdir log \
			-suite linkload_SUITE call_SUITE \
				misc_SUITE callf_SUITE
	rm -f test/*.beam

clean:
	rm -rf priv ebin test/*.beam log

# Convention appears to be install binaries and source, but not tests or build-related things
install: $(OUTPUTS)
	appdir=$(PREFIX)$(ERLANG_INST_DIR)/lib/erldc-$(VERSION); \
	install -d $$appdir $$appdir/ebin $$appdir/priv $$appdir/src $$appdir/c_src $$appdir/include; \
	install README.txt $$appdir; \
	install src/*.erl $$appdir/src; \
	install include/*.hrl $$appdir/include; \
	install c_src/*.c $$appdir/c_src; \
	install ebin/* $$appdir/ebin; \
	install priv/erldc.so $$appdir/priv

uninstall:
	appdir=$(PREFIX)$(ERLANG_INST_DIR)/lib/erldc-$(VERSION); \
	rm -rf $$appdir

.PHONY: clean all tests build-plt dialyze install uninstall

