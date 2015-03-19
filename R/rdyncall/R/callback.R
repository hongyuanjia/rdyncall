# Package: rdyncall
# File: R/callback.R
# Description: R Callbacks

new.callback <- function(signature, fun, envir=new.env())
{
  stopifnot( is.character(signature) )
  stopifnot( is.function(fun) )
  stopifnot( is.environment(envir) )
  .Call("new_callback", signature, fun, envir, PACKAGE="rdyncall")
}
