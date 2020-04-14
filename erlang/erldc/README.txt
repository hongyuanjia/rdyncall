dyncall erlang bindings (NIF)


BUILD/INSTALLATION
==================

1) make sure dyncall is built and libraries/headers are in include paths or
   CFLAGS points to them, etc.. Same goes for erlang headers/libs.

2) Build this erlang NIF:

     make

3) To install, pick correct install paths by defining PREFIX (if needed, e.g.
   for stage dir) and ERLANG_INST_DIR (e.g. /usr/lib64/erlang,
   /usr/local/lib/erlang, ...):

      make ERLANG_INST_DIR=/erlang/in/this/dir install

Erlang doesn't use pkg-config, so it's up to you to point to set the flags to
point to correct paths at build and install-time.

The makefile is meant to be portable, at least across *nix.


RUNNING TESTS
=============

Unit tests (via common test):

    make tests

Static analysis (via dialyzer):

    make build-plt
    make dialyze


USING
=====

Examine the test suites for several examples.

Dyncall is built as an OTP library application, so there's nothing
to start or stop.


TODO
====
- signature chars used to indicate calling conventions are not supported yet!
- callback support


AUTHORS
=======
Erik Mackdanz <erikmack@gmail.com>

