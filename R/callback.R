# Package: rdyncall
# File: R/callback.R
# Description: R Callbacks

ccallback <- function(signature, fun, envir = new.env()) {
    stopifnot(is.character(signature))
    stopifnot(is.function(fun))
    stopifnot(is.environment(envir))

    .Call("C_callback", signature, fun, envir, PACKAGE = "rdyncall")
}
