# Package: rdyncall
# File: R/utils_str.R
# Description: Support for (arrays of) C strings

ptr2str     <- function(x) .Call("C_ptr2str", x, PACKAGE = "rdyncall")
strarrayptr <- function(x) .Call("C_strarrayptr", x, PACKAGE = "rdyncall")
strptr      <- function(x) .Call("C_strptr", x, PACKAGE = "rdyncall")
