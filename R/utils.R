# Package: rdyncall
# File: R/utils.R
# Description: Low-level external pointer utility functions

is.nullptr     <- function(x)         .Call("C_isnullptr", x, PACKAGE = "rdyncall")
as.extptr      <- function(x)         .Call("C_asextptr", x, PACKAGE = "rdyncall")
offsetPtr      <- function(x, offset) .Call("C_offsetPtr", x, offset, PACKAGE = "rdyncall")
is.externalptr <- function(x)         typeof(x) == "externalptr"
