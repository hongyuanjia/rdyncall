# Package: rdyncall
# File: R/utils_float.R
# Description: Support for C float vectors in R

as.floatraw <- function(x) 
{
  x <- .Call("r_as_floatraw", as.numeric(x), PACKAGE="rdyncall")
  class(x) <- "floatraw"
  x
}

floatraw2numeric <- function(x) 
{
  stopifnot(is.raw(x))
  stopifnot(class(x) == "floatraw")
  stopifnot(length(x) >= 4)
  .Call("r_floatraw2numeric", x, PACKAGE="rdyncall")
}

floatraw <- function(n)
{
  x <- raw(n*4)
  class(x) <- "floatraw"
  x
}
