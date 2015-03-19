#
# bind library by import string
#

eatws <- function(x) gsub("[ \n\t]*","",x)

bind1 <- function(symbol, signature, libh, callvm, envir=parent.frame() )
{
  funcptr <- rdcFind(libh, symbol)  
  f <- function(...) NULL
  body(f) <- substitute( dcCall( callvm, funcptr, signature, ... ), list(funcptr=funcptr, signature=signature) )  
  assign( symbol, f, envir=envir )
}

rdcBind <- function(libname, sigs, callvm, envir=parent.frame() )
{
  libh <- rdcLoad(libname)
  sigs <- eatws(sigs)
  sigs <- strsplit(sigs, ";")[[1]]
  sigs <- strsplit(sigs, "\\(")
  for (i in seq(along=sigs)) bind1(sigs[[i]][[1]], sigs[[i]][[2]], libh, callvm, envir )  
}
