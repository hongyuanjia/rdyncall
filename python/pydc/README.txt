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
free(libhandle)


SIGNATURE FORMAT
================

  is a formated string

  format: "xxxxx)y"

    x is positional parameter-type charcode, y is result-type charcode

  SIG | FROM PYTHON 2                                        | FROM PYTHON 3                            | C/C++                           | TO PYTHON 2                          | TO PYTHON 3
  ----+------------------------------------------------------+------------------------------------------+---------------------------------+--------------------------------------+-------------------------------------
  'v' |                                                      |                                          | void                            | None (Py_None) (e.g. ret of "...)v") | None (Py_None) (e.g. ret of "...)v")
  'B' | bool (PyBool)                                        | bool (PyBool)#                           | int/bool                        | bool (PyBool)                        | bool (PyBool)@
  'c' | int (PyLong)%, str (single char)%                    | int (PyLong)%, str (single char)%        | char                            | int (PyInt)                          | int (PyLong)
  'C' | int (PyLong)%, str (single char)%                    | int (PyLong)%, str (single char)%        | unsigned char                   | int (PyInt)                          | int (PyLong)
  's' | int (PyInt)%                                         | int (PyLong)%                            | short                           | int (PyInt)                          | int (PyLong)
  'S' | int (PyInt)%                                         | int (PyLong)%                            | unsigned short                  | int (PyInt)                          | int (PyLong)
  'i' | int (PyInt)                                          | int (PyLong)                             | int                             | int (PyInt)                          | int (PyLong)
  'I' | int (PyInt)                                          | int (PyLong)                             | unsigned int                    | int (PyInt)                          | int (PyLong)
  'j' | int (PyInt)                                          | int (PyLong)                             | long                            | int (PyInt)                          | int (PyLong)
  'J' | int (PyInt)                                          | int (PyLong)                             | unsigned long                   | int (PyInt)                          | int (PyLong)
  'l' | int (PyInt), long (PyLong)                           | int (PyLongLong)                         | long long                       | long (PyLong)                        | int (PyLong)
  'L' | int (PyInt), long (PyLong)                           | int (PyLongLong)                         | unsigned long long              | long (PyLong)                        | int (PyLong)
  'f' | float (PyFloat)$                                     | float (PyFloat)$                         | float                           | float (PyFloat)^                     | float (PyFloat)^
  'd' | float (PyFloat)                                      | float (PyFloat)                          | double                          | float (PyFloat)                      | float (PyFloat)
  'p' | str (PyUnicode/PyString), int (PyInt), long (PyLong) | str (PyUnicode), int (PyLong), (PyBytes) | void*                           | int,long (Py_ssize_t)                | int (Py_ssize_t)
  'Z' | str (PyUnicode/PyString)                             | str (PyUnicode), (PyBytes)               | const char* (UTF-8 for unicode) | int (PyString)                       | str (PyUnicode)

# converted to 1 if True and 0 otherwise
@ converted to False if 0 and True otherwise
% range checked
$ cast to single precision
^ cast to double precision

TODO
====

- signature suffixes used to indicate calling conventions are not supported yet!
- callback support

