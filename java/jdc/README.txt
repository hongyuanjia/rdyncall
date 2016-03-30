BUILD
=====

1) make sure dyncall is built and libraries/headers are in include paths or
   CFLAGS points to them, etc.

2) Build with:

     make


RUNNING EXAMPLES
================

For example, having build jdc, build and run UnixMathExample from this folder:

     javac -d . examples/UnixMathExample.java
     java -Djava.library.path=. UnixMathExample

