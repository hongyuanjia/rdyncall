# Package: rdyncall
# File: R/utils.R
# Description: Low-level external pointer utility functions

is.nullptr     <- function(x)         .Call("isnullptr", x, PACKAGE = "rdyncall")
as.extptr      <- function(x)         .Call("asextptr", x, PACKAGE = "rdyncall")
offsetPtr      <- function(x, offset) .Call("offsetPtr", x, offset, PACKAGE = "rdyncall")
is.externalptr <- function(x)         (typeof(x) == "externalptr")
