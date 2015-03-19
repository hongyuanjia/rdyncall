BUILDING
========

To build erldc:

    make DYNCALL_SRC_PATH=../dyncall ERLANG_INST_DIR=/erlang/in/this/dir all
    sudo make ERLANG_INST_DIR=/erlang/in/this/dir install

Erlang doesn't use pkg-config, so you must specify ERLANG_INC (and
ERLANG_INST_DIR at install-time).

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


AUTHORS
=======
Erik Mackdanz <erikmack@gmail.com>
