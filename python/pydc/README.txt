dyncall python bindings
Copyright 2007-2016 Daniel Adler
          2018-2020 Tassilo Philipp

Dec  4, 2007: initial
Mar 22, 2016: update to dyncall 0.9, includes breaking sig char changes
Apr 19, 2018: update to dyncall 1.0
Apr  7, 2020: update to dyncall 1.1, Python 3 support, using the Capsule
              API, as well as support for python unicode strings
Apr 11, 2020: support for getting loaded library path
Apr 12, 2020: breaking change: restrict 'Z' conversions to immutable types
              and 'p' to mutable types (and handles)
Apr 13, 2020: added signature char support to specify calling conventions
Oct 27, 2020: allowing 'None' for 'p' params, always passing NULL
Nov 13, 2020: removed pydc.py wrapper overhead (which only called pydcext.so
              functions; implies renaming pydcext.* to pydc.*), added type stub
              as package_data


BUILD/INSTALLATION
==================

1) make sure dyncall is built and libraries/headers are in include paths or
   CFLAGS points to them, etc.

2) Build and install this extension with:

     python setup.py install

Building a wheel package isn't supported, currently.


API
===

In a nutshell:

libhandle = load(libpath)               # if path == None => handle to running process
libpath   = get_path(libhandle)         # if handle == None => path to executable
funcptr   = find(libhandle, symbolname)
call(funcptr, signature, ...)
free(libhandle)

Notes:
- a pydc.pyi stub file with the precise interface description is available
- there are no functions to set the calling convention mode, however, it can be
  set using the signature
- not specifying any calling convention in the signature string will use the
  platform's default one


SIGNATURE FORMAT
================

  ignoring calling convention mode switching for simplicity, the signature is
  a string with the following format (using * as regex-like repetition):

    "x*)y"

  where x is positional parameter-type charcode (per argument), y is result-type charcode


  SIG | FROM PYTHON 2                   | FROM PYTHON 3                   | C/C++                           | TO PYTHON 2                          | TO PYTHON 3
  ----+---------------------------------+---------------------------------+---------------------------------+--------------------------------------+---------------------------------------
  'v' |                                 |                                 | void                            | None (Py_None) (e.g. ret of "...)v") | None (Py_None) (e.g. ret of "...)v")
  'B' | bool (PyBool)                   | bool (PyBool)                 # | int/bool                        | bool (PyBool)                        | bool (PyBool)                        @
  'c' | int (PyInt)                   % | int (PyLong)                  % | char                            | int (PyInt)                          | int (PyLong)
      | str (with only a single char) % | str (with only a single char) % | char                            | int (PyInt)                          | int (PyLong)
  'C' | int (PyInt)                   % | int (PyLong)                  % | unsigned char                   | int (PyInt)                          | int (PyLong)
      | str (with only a single char) % | str (with only a single char) % | unsigned char                   | int (PyInt)                          | int (PyLong)
  's' | int (PyInt)                   % | int (PyLong)                  % | short                           | int (PyInt)                          | int (PyLong)
  'S' | int (PyInt)                   % | int (PyLong)                  % | unsigned short                  | int (PyInt)                          | int (PyLong)
  'i' | int (PyInt)                     | int (PyLong)                    | int                             | int (PyInt)                          | int (PyLong)
  'I' | int (PyInt)                     | int (PyLong)                    | unsigned int                    | int (PyInt)                          | int (PyLong)
  'j' | int (PyInt)                     | int (PyLong)                    | long                            | int (PyInt)                          | int (PyLong)
  'J' | int (PyInt)                     | int (PyLong)                    | unsigned long                   | int (PyInt)                          | int (PyLong)
  'l' | int (PyInt)                     | int (PyLongLong)                | long long                       | long (PyLong)                        | int (PyLong)
      | long (PyLong)                   | -                               | long long                       | long (PyLong)                        | int (PyLong)
  'L' | int (PyInt)                     | int (PyLongLong)                | unsigned long long              | long (PyLong)                        | int (PyLong)
      | long (PyLong)                   | -                               | unsigned long long              | long (PyLong)                        | int (PyLong)
  'f' | float (PyFloat)               $ | float (PyFloat)               $ | float                           | float (PyFloat)                    ^ | float (PyFloat)                      ^
  'd' | float (PyFloat)                 | float (PyFloat)                 | double                          | float (PyFloat)                      | float (PyFloat)
  'p' | bytearray (PyByteArray)       & | bytearray (PyByteArray)       & | void*                           | int,long (Py_ssize_t)                | int (Py_ssize_t)
      | int (PyInt)                     | int (PyLong)                    | void*                           | int,long (Py_ssize_t)                | int (Py_ssize_t)
      | long (PyLong)                   | -                               | void*                           | int,long (Py_ssize_t)                | int (Py_ssize_t)
      | None (Py_None)                  | None (Py_None)                  | void* (always NULL)             | int,long (Py_ssize_t)                | int (Py_ssize_t)
  'Z' | str (PyString)                ! | str (PyUnicode)               ! | const char* (UTF-8 for unicode) | int (PyString)                       | str (PyUnicode)
      | unicode (PyUnicode)           ! | -                               | const char* (UTF-8 for unicode) | int (PyString)                       | str (PyUnicode)
      | -                               | bytes (PyBytes)               ! | const char* (UTF-8 for unicode) | int (PyString)                       | str (PyUnicode)
      | bytearray (PyByteArray)       ! | bytearray (PyByteArray)       ! | const char* (UTF-8 for unicode) | int (PyString)                       | str (PyUnicode)

  Annotations:
  # converted to 1 if True and 0 otherwise
  @ converted to False if 0 and True otherwise
  % range/length checked
  $ cast to single precision
  ^ cast to double precision
  & mutable buffer when passed to C
  ! immutable buffer when passed to C, as strings (in any form) are considered objects, not buffers


  Also supported are specifying calling convention switches using '_'-prefixed
  signature characters:

  SIG | DESCRIPTION
  ----+-----------------------------------------------------------------------------------------------------------
  '_' | prefix indicating that next signature character specifies calling convention; char is one of the following
  ':' | platform's default calling convention
  'e' | vararg function
  '.' | vararg function's variadic/ellipsis part (...), to be specified before first vararg
  'c' | only on x86: cdecl
  's' | only on x86: stdcall
  'F' | only on x86: fastcall (MS)
  'f' | only on x86: fastcall (GNU)
  '+' | only on x86: thiscall (MS)
  '#' | only on x86: thiscall (GNU)
  'A' | only on ARM: ARM mode
  'a' | only on ARM: THUMB mode
  '$' | syscall


TODO
====

- callback support
- pydoc "man page"
- stub location: the pydc-stubs folder isn't picked up by mypy, so I question why this is the suggested way
- get into freebsd ports


BUGS
====

- when using Python 2, the dyncall call vm object is never dcFree'd, as there
  is no way to call a "freefunc" as introduced with Python 3 module definitions
  (see PEP 3121 for details)

