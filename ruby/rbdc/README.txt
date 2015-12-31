dyncall ruby bindings
Copyright 2007-2015 Tassilo Philipp


BUILD

  Build and install this gem with:
    (cd $DYNCALL_DIR; make distclean) || (gem build rbdc.gemspec && gem install ../../../rbdc-*.gem)


SIGNATURE FORMAT

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
