dyncall ruby bindings
Copyright 2007-2018 Tassilo Philipp


BUILD/INSTALLATION
==================

1) The extension isn't built here, but its code along with dyncall's source is bundled
   in a .gem file to then be built and installed on the target platform.
   So, you need dyncall's full source code to be included. Unfortunately, the .gemspec isn't
   flexible enough to pull from different paths, so building the .gem file requires dyncall
   to be found next to rbdc.c and extconf.rb. This means either copy dyncall's base directory
   to ./dyncall or create a symlink ./dyncall, that points to it.

2) Then, build this gem with:

     gem build rbdc.gemspec

3) On the target platform, install the gem with:

     gem install rbdc-*.gem


API
===

l = Dyncall::ExtLib.new
l.load(libpath)
l.syms_init(libpath)
l.syms_count
l.syms_each { |sym_name| ... }
l.exists?(:symbolname)
l.call(:symbolname, sigstring, ...)


SIGNATURE FORMAT
================

format: "xxxxx)y"

  x is positional parameter-type charcode, y is result-type charcode  

  SIG | FROM RUBY                               | C/C++              | TO RUBY
  ----+-----------------------------------------+--------------------+-----------------------------------
  'v' |                                         | void               | NilClass
  'B' | TrueClass, FalseClass, NilClass, Fixnum | bool               | TrueClass, FalseClass
  'c' | Fixnum                                  | char               | Fixnum
  'C' | Fixnum                                  | unsigned char      | Fixnum
  's' | Fixnum                                  | short              | Fixnum
  'S' | Fixnum                                  | unsigned short     | Fixnum
  'i' | Fixnum                                  | int                | Fixnum
  'I' | Fixnum                                  | unsigned int       | Fixnum
  'j' | Fixnum                                  | long               | Fixnum
  'J' | Fixnum                                  | unsigned long      | Fixnum
  'l' | Fixnum                                  | long long          | Fixnum
  'L' | Fixnum                                  | unsigned long long | Fixnum
  'f' | Float                                   | float              | Float
  'd' | Float                                   | double             | Float
  'p' | String (other ruby types? @@@)          | void*              | unsupported at the moment @@@
  'Z' | String                                  | void*              | String


TODO
====

- signature suffixes used to indicate calling conventions are not supported yet!
- C pointer -> ruby... array?
- callback support

