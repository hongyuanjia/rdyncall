dyncall ruby bindings
Copyright 2007-2016 Tassilo Philipp


BUILD/INSTALLATION
------------------

1) The extension isn't built here, but its code along with dyncall's source is bundled
   in a .gem file to then be built and installed on the target platform.
   So, you need dyncall's full source code to be included. Unfortunately, the .gemspec isn't
   flexible enough to pull from different paths, so building the .gem file requires dyncall
   to be found next to rbdc.c and extconf.rb. This means either copy dyncall's base directory
   do ./dyncall or create a symlink ./dyncall, that points to it.

2) Then, build this gem with:
   gem build rbdc.gemspec

3) On the target platform, install the gem with:
   gem install ../../../rbdc-*.gem


API
---

l = Dyncall::ExtLib.new
l.load(libpath)
l.syms_init(libpath)
l.syms_count
l.syms_each { |sym_name| ... }
l.exists?(:symbolname)
l.call(:symbolname, sigstring, ...)


SIGNATURE FORMAT
----------------

format: "xxxxx)y"

  x is positional parameter-type charcode

  'B' C++: bool             <- Ruby: TrueClass, FalseClass, NilClass, Fixnum
  'c' C: char               <- Ruby: Fixnum
  'C' C: unsigned char      <- Ruby: Fixnum
  's' C: short              <- Ruby: Fixnum
  'S' C: unsigned short     <- Ruby: Fixnum
  'i' C: int                <- Ruby: Fixnum
  'I' C: unsigned int       <- Ruby: Fixnum
  'j' C: long               <- Ruby: Fixnum
  'J' C: unsigned long      <- Ruby: Fixnum
  'l' C: long long          <- Ruby: Fixnum
  'L' C: unsigned long long <- Ruby: Fixnum
  'f' C: float              <- Ruby: Float
  'd' C: double             <- Ruby: Float
  'p' C: void*              <- Ruby: String (check if there are other pointer-convertible ruby types @@@)
  'Z' C: void*              <- Ruby: String

  y is result-type charcode  

  'v' C: void               -> Ruby: NilClass
  'B' C: bool               -> Ruby: TrueClass, FalseClass
  'c' C: char               -> Ruby: Fixnum
  'C' C: unsigned char      -> Ruby: Fixnum
  's' C: short              -> Ruby: Fixnum
  'S' C: unsigned short     -> Ruby: Fixnum
  'i' C: int                -> Ruby: Fixnum
  'I' C: unsigned int       -> Ruby: Fixnum
  'j' C: long               -> Ruby: Fixnum
  'J' C: unsigned long      -> Ruby: Fixnum
  'l' C: long long          -> Ruby: Fixnum
  'L' C: unsigned long long -> Ruby: Fixnum
  'f' C: float              -> Ruby: Float
  'd' C: double             -> Ruby: Float
  'p' C: void*              -> unsupported at the moment @@@
  'Z' C: void*              -> Ruby: String


-> Note that signature suffixes used to indicate calling
-> conventions, are not supported yet! @@@

