# Package: rdyncall
# File: R/utils.R
# Description: Low-level external pointer utility functions

is.nullptr     <- function(x)         .Call("C_isnullptr", x, PACKAGE = "rdyncall")
as.externalptr <- function(x)         .Call("C_asexternalptr", x, PACKAGE = "rdyncall")
offset_ptr     <- function(x, offset) .Call("C_offsetptr", x, offset, PACKAGE = "rdyncall")
is.externalptr <- function(x)         typeof(x) == "externalptr"
