# DynCall R bindings
# Copyright (C) 2007-2009 Daniel Adler
# TODO:
# - pointer arithmetic: == or identical, is.NULL or is.nil
# - pointer arrays

rdcLoad    <- function (libpath) 
{  
  .Call("rdcLoad", as.character(libpath) , PACKAGE="rdc") 
}

rdcFree <- function (libhandle) 
{
  .Call("rdcFree", libhandle, PACKAGE="rdc") 
}

rdcFind    <- function (libhandle, symbol) 
{
  .Call("rdcFind", libhandle, as.character(symbol) )
}

rdcCall    <- function (funcptr, signature, ...) 
{
  .Call("rdcCall", funcptr, signature, list(...) ) 
}

rdcPath    <- function (addpath)
{
  path <- Sys.getenv("PATH")
  path <- paste(addpath,path,sep=.Platform$path.sep)
  Sys.setenv(PATH=path)
}

rdcUnpath <- function(delpath)
{
  path <- Sys.getenv("PATH")
  path <- sub( paste(delpath,.Platform$path.sep,sep=""), "", path )  
  Sys.setenv(PATH=path)  
}

rdcShowPath <- function()
{
  Sys.getenv("PATH")
}
  
rdcUnpack1 <- function(ptr, offset, sigchar)
{
  .Call("rdcUnpack1", ptr, as.integer(offset), as.character(sigchar) )
}

rdcDataPtr <- function(data, offset=0L)
{
  .Call("rdcDataPtr", data, as.integer(offset) )
}

cleanup <- function()
{
  unloadNamespace("rdc")  
}

.sizes <- c(
  logical=4L,
  integer=4L,
  double=8L,
  complex=16L,
  character=1L,
  raw=1L,
  externalptr=.Machine$sizeof.pointer
)

rdcSizeOf <- function(x)
{
  .sizes[[ as.character(x) ]]  
}

DC_CALL_C_DEFAULT              =  0
DC_CALL_C_X86_CDECL            = 1
DC_CALL_C_X86_WIN32_STD        = 2
DC_CALL_C_X86_WIN32_FAST_MS    = 3
DC_CALL_C_X86_WIN32_FAST_GNU   = 4
DC_CALL_C_X86_WIN32_THIS_MS    = 5
DC_CALL_C_X86_WIN32_THIS_GNU   = 6
DC_CALL_C_X64_WIN64            = 7
DC_CALL_C_X64_SYSV             = 8
DC_CALL_C_PPC32_DARWIN         = 9
DC_CALL_C_PPC32_OSX            = 9
DC_CALL_C_ARM_ARM              =10
DC_CALL_C_ARM_THUMB            =11
DC_CALL_C_MIPS32_EABI          =12
DC_CALL_C_MIPS32_PSPSDK        =12
DC_CALL_C_PPC32_SYSV           =13
DC_CALL_C_PPC32_LINUX          =13

rdcMode  <- function (mode)
{
  .Call("rdcMode", as.integer(mode), PACKAGE="rdc" )
}

dcFree <- function(callvm)
{
  .Call("dcFree", callvm, PACKAGE="rdc")
}

dcNewCallVM <- function(size=1024L)
{
  x <- .Call("dcNewCallVM", as.integer(size), PACKAGE="rdc")
  reg.finalizer(x, dcFree)
  class(x) <- "dyncallvm"
  return(x)
}

dcMode <- function(callvm, mode)
{
  .Call("dcMode", callvm, as.integer(mode) )
}

dcCall <- function(callvm, funcptr, signature, ...)
{
  .Call("dcCall", callvm, funcptr, signature, list(...) )
} 

