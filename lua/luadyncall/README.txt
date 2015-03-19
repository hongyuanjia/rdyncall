luadyncall - lua dyncall bindings
== (C) 2010 Daniel Adler ========


Build
-----
./bootstrap
./configure
make
make install


Package contents
----------------

dynload   dynamic loading of code and resolving of symbols
dyncall   dynamic call to code
dynport   dynamic shared library linker
dynstruct C structure support (experimental) 
dyntype   C type information (experimental)
smartptr  smart pointer
int64     64-bit signed and unsigned integer data type
array     C arrays
path      search and open resources by name along a path
ldynguess system-information




Build with Makefile.custom
===========================
$EDITOR ./config
specify dyncall and lua prefix paths


Build with luarocks
===================
cd src
luarocks make


Build using GNU Make
====================
make


Build source package (maintainers only)
=======================================
make srcpkg


 
