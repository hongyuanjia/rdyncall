#
# GOAL:
# automatic unloading when all symbols from a library are free'ed.
#
# 
#
# loading a shared library

# low-level R
x <- dyn.load("/lib/libc.so.6")
handle <- x[["handle"]]




# high-level R in conjunction with R packages
library.dynam()

prot = library
R_MakeExternalPtr(addr, tag, prot)




x <- .dynload("/lib/libc.so.6")
y <- .dynsym(x, "glBegin")

