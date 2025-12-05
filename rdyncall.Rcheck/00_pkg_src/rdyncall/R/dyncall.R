# Package: rdyncall
# File: R/dyncall.R
# Description: dyncall bindings for R

# ----------------------------------------------------------------------------
# call vm alloc/free (internal)

callvm_new <- function(
    callmode = c("cdecl", "stdcall", "thiscall", "thiscall.gcc", "thiscall.msvc",
                 "fastcall", "fastcall.gcc", "fastcall.msvc"),
    size = 4096)
{
    callmode <- match.arg(callmode)
    x <- .Call("C_callvm_new", callmode, as.integer(size), PACKAGE = "rdyncall")
    reg.finalizer(x, callvm_free)
    return(x)
}

callvm_free <- function(x) {
    .Call("C_callvm_free", x, PACKAGE = "rdyncall")
}

# ----------------------------------------------------------------------------
# CallVM's for calling conventions - will be initialized .onLoad

callvm.default       <- NULL
callvm.cdecl         <- NULL
callvm.stdcall       <- NULL
callvm.thiscall      <- NULL
callvm.thiscall.gcc  <- NULL
callvm.thiscall.msvc <- NULL
callvm.fastcall      <- NULL
callvm.fastcall.gcc  <- NULL
callvm.fastcall.msvc <- NULL

# ----------------------------------------------------------------------------
# public interface

dyncall <- function(address, signature, ..., callmode = "default") {
    callvm <- switch(callmode,
        default       = callvm.default,
        cdecl         = callvm.cdecl,
        stdcall       = callvm.stdcall,
        thiscall      = ,
        thiscall.gcc  = callvm.thiscall.gcc,
        thiscall.msvc = callvm.thiscall.msvc,
        fastcall      = ,
        fastcall.gcc  = callvm.fastcall.gcc,
        fastcall.msvc = callvm.fastcall.msvc
    )
    .External("C_dyncall", callvm, address, signature, ..., PACKAGE = "rdyncall")
}

dyncall.cdecl         <- function(address, signature, ...) .External("C_dyncall", callvm.cdecl,         address, signature, ..., PACKAGE = "rdyncall")
dyncall.default       <- function(address, signature, ...) .External("C_dyncall", callvm.default,       address, signature, ..., PACKAGE = "rdyncall")
dyncall.stdcall       <- function(address, signature, ...) .External("C_dyncall", callvm.stdcall,       address, signature, ..., PACKAGE = "rdyncall")
dyncall.thiscall.gcc  <- function(address, signature, ...) .External("C_dyncall", callvm.thiscall.gcc,  address, signature, ..., PACKAGE = "rdyncall")
dyncall.thiscall.msvc <- function(address, signature, ...) .External("C_dyncall", callvm.thiscall.msvc, address, signature, ..., PACKAGE = "rdyncall")
dyncall.fastcall.gcc  <- function(address, signature, ...) .External("C_dyncall", callvm.fastcall.gcc,  address, signature, ..., PACKAGE = "rdyncall")
dyncall.fastcall.msvc <- function(address, signature, ...) .External("C_dyncall", callvm.fastcall.msvc, address, signature, ..., PACKAGE = "rdyncall")
dyncall.thiscall      <- dyncall.thiscall.gcc
dyncall.fastcall      <- dyncall.fastcall.gcc

# ----------------------------------------------------------------------------
# initialize callvm's on load

.onLoad <- function(libname, pkgname) {
    callvm.cdecl         <<- callvm_new("cdecl")
    callvm.default       <<- callvm.cdecl
    callvm.stdcall       <<- callvm_new("stdcall")
    callvm.thiscall      <<- callvm_new("thiscall")
    callvm.thiscall.gcc  <<- callvm_new("thiscall.gcc")
    callvm.thiscall.msvc <<- callvm_new("thiscall.msvc")
    callvm.fastcall      <<- callvm_new("fastcall")
    callvm.fastcall.gcc  <<- callvm_new("fastcall.gcc")
    callvm.fastcall.msvc <<- callvm_new("fastcall.msvc")
}
