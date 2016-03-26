dyncall python bindings
(C) 2007-2016 Daniel Adler.
Dec 4, 2007: initial
Mar 22,2016: brought up to dyncall 0.9


BUILD/INSTALLATION
------------------

1) make sure dyncall is built and libraries/headers are in include paths or
   CFLAGS points to them, etc.

2) Build and install this extension with:
   python setup.py install


API
---

libhandle = load(libpath)
funcptr   = find(libhandle, symbolname)
call(funcptr, signature, ...)


SIGNATURE FORMAT
----------------

  is a formated string

  format: "xxxxx)y"

    x is positional parameter-type charcode

    'B' C++: bool         <- Python: PyBool
    'c' C: char           <- Python: PyInt (range checked)
    's' C: short          <- Python: PyInt (range checked)
    'i' C: int            <- Python: PyInt
    'j' C: long           <- Python: PyLong
    'l' C: long long      <- Python: PyLongLong
    'f' C: float          <- Python: PyFloat (cast to single precision)
    'd' C: double         <- Python: PyFloat
    'p' C: void*          <- Python: PyCObject
    'Z' C: const char*    <- Python: PyString

    y is result-type charcode  

    'v' C: void
    'B' C++: bool         -> Python: PyBool
    'c' C: char           -> Python: PyInt
    's' C: short          -> Python: PyInt
    'i' C: int            -> Python: PyInt
    'j' C: long           -> Python: PyLong
    'l' C: long long      -> Python: PyLongLong
    'f' C: float          -> Python: PyFloat (cast to double precision)
    'd' C: double         -> Python: PyFloat
    'p' C: ptr            -> Python: PyCObject encapsulating a void*
    'Z' C: const char*    -> Python: PyString


BUGS
----

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

