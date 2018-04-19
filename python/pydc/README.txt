dyncall python bindings
(C) 2007-2016 Daniel Adler
Dec 4, 2007: initial
Mar 22,2016: update to dyncall 0.9, includes breaking sig char changes
Apr 19,2018: update to dyncall 1.0


BUILD/INSTALLATION
==================

1) make sure dyncall is built and libraries/headers are in include paths or
   CFLAGS points to them, etc.

2) Build and install this extension with:

     python setup.py install

Building an egg isn't supported, currently.


API
===

libhandle = load(libpath)
funcptr   = find(libhandle, symbolname)
call(funcptr, signature, ...)


SIGNATURE FORMAT
================

  is a formated string

  format: "xxxxx)y"

    x is positional parameter-type charcode, y is result-type charcode

  SIG | FROM PYTHON                        | C/C++              | TO PYTHON
  ----+------------------------------------+--------------------+-----------------------------------
  'v' |                                    | void               |
  'B' | PyBool                             | bool               | PyBool
  'c' | PyInt (range checked)              | char               | PyInt
  'C' | PyInt (range checked)              | unsigned char      | PyInt
  's' | PyInt (range checked)              | short              | PyInt
  'S' | PyInt (range checked)              | unsigned short     | PyInt
  'i' | PyInt                              | int                | PyInt
  'I' | PyInt                              | unsigned int       | PyInt
  'j' | PyLong                             | long               | PyLong
  'J' | PyLong                             | unsigned long      | PyLong
  'l' | PyLongLong                         | long long          | PyLongLong
  'L' | PyLongLong                         | unsigned long long | PyLongLong
  'f' | PyFloat (cast to single precision) | float              | PyFloat (cast to double precision)
  'd' | PyFloat                            | double             | PyFloat
  'p' | PyCObject                          | void*              | PyCObject encapsulating a void*
  'Z' | PyString                           | const char*        | PyString


TODO
====

- support signature suffixes used to indicate calling conventions, are not supported yet!
- not sure if returning 'p' is working, creating PyCObject, check and write test code


BUGS
====

* build on osx/ppc - link error i386 something...  [MacPython 2.4]

  solution:
  installation of latest python for os x (MacPython 2.5)  

  build log:

  python setup.py install
  running install
  running build
  running build_py
  creating build
  creating build/lib.macosx-10.3-fat-2.4
  copying pydc.py -> build/lib.macosx-10.3-fat-2.4
  running build_ext
  building 'pydcext' extension
  creating build/temp.macosx-10.3-fat-2.4
  gcc -arch ppc -arch i386 -isysroot /Developer/SDKs/MacOSX10.4u.sdk -fno-strict-aliasing -Wno-long-double -no-cpp-precomp -mno-fused-madd -fno-common -dynamic -DNDEBUG -g -O3 -I../../../dyncall -I../../../dynload -I/Library/Frameworks/Python.framework/Versions/2.4/include/python2.4 -c pydcext.c -o build/temp.macosx-10.3-fat-2.4/pydcext.o
  gcc -arch i386 -arch ppc -isysroot /Developer/SDKs/MacOSX10.4u.sdk -g -bundle -undefined dynamic_lookup build/temp.macosx-10.3-fat-2.4/pydcext.o -L../../../dyncall -L../../../dynload -ldyncall_s -ldynload_s -lstdc++ -o build/lib.macosx-10.3-fat-2.4/pydcext.so
  /usr/bin/ld: for architecture i386
  /usr/bin/ld: warning ../../../dyncall/libdyncall_s.a archive's cputype (18, architecture ppc) does not match cputype (7) for specified -arch flag: i386 (can't load from it)
  /usr/bin/ld: warning ../../../dynload/libdynload_s.a archive's cputype (18, architecture ppc) does not match cputype (7) for specified -arch flag: i386 (can't load from it)
  running install_lib
  copying build/lib.macosx-10.3-fat-2.4/pydcext.so -> /Library/Frameworks/Python.framework/Versions/2.4/lib/python2.4/site-packages

