dyncall python bindings
Copyright 2007-2016 Daniel Adler
          2018-2020 Tassilo Philipp

Dec  4, 2007: initial
Mar 22, 2016: update to dyncall 0.9, includes breaking sig char changes
Apr 19, 2018: update to dyncall 1.0
Apr  7, 2020: update to dyncall 1.1, Python 3 support, using the Capsule
              API, as well as support for python unicode strings


BUILD/INSTALLATION
==================

1) make sure dyncall is built and libraries/headers are in include paths or
   CFLAGS points to them, etc.

2) Build and install this extension with:

     python setup.py install

Building a wheel package isn't supported, currently.


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

  SIG | FROM PYTHON 2                      | FROM PYTHON 3 @@@                  | C/C++                           | TO PYTHON 2                        | TO PYTHON 3 @@@
  ----+------------------------------------+------------------------------------+---------------------------------+------------------------------------+-----------------------------------
  'v' |                                    |                                    | void                            |                                    |
  'B' | PyBool                             | PyBool                             | bool                            | PyBool                             | PyBool
  'c' | PyInt (range checked)              | PyInt (range checked)              | char                            | PyInt                              | PyInt
  'C' | PyInt (range checked)              | PyInt (range checked)              | unsigned char                   | PyInt                              | PyInt
  's' | PyInt (range checked)              | PyInt (range checked)              | short                           | PyInt                              | PyInt
  'S' | PyInt (range checked)              | PyInt (range checked)              | unsigned short                  | PyInt                              | PyInt
  'i' | PyInt                              | PyInt                              | int                             | PyInt                              | PyInt
  'I' | PyInt                              | PyInt                              | unsigned int                    | PyInt                              | PyInt
  'j' | PyLong                             | PyLong                             | long                            | PyLong                             | PyLong
  'J' | PyLong                             | PyLong                             | unsigned long                   | PyLong                             | PyLong
  'l' | PyLongLong                         | PyLongLong                         | long long                       | PyLongLong                         | PyLongLong
  'L' | PyLongLong                         | PyLongLong                         | unsigned long long              | PyLongLong                         | PyLongLong
  'f' | PyFloat (cast to single precision) | PyFloat (cast to single precision) | float                           | PyFloat (cast to double precision) | PyFloat (cast to double precision)
  'd' | PyFloat                            | PyFloat                            | double                          | PyFloat                            | PyFloat
  'p' | PyUnicode/PyString/PyLong          | PyUnicode/PyBytes/PyLong           | void*                           | Py_ssize_t                         | Py_ssize_t
  'Z' | PyUnicode/PyString                 | PyUnicode/PyBytes                  | const char* (UTF-8 for unicode) | PyString                           | PyUnicode


TODO
====

- signature suffixes used to indicate calling conventions are not supported yet!
- not sure if returning 'p' is working, creating PyCObject, check and write test code @@@
- callback support


BUGS
====

* build on osx/ppc - link error i386 something...  [MacPython 2.4]

  solution:
  installation of latest python for os x (MacPython 2.5)  


EXAMPLE BUILD
=============

  $ python setup.py install
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

