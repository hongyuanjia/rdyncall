#' Utility functions for working with foreign C data types
#'
#' @description
#' Functions for low-level operations on C pointers as well as helper functions
#' and objects to handle C `float` arrays and strings.
#'
#' @details
#' `is.nullptr()` tests if the external pointer given by \code{x} represents a C
#' `NULL` pointer.
#'
#' `as.externalptr()` returns an external pointer to the data area of atomic
#' vector given by `x`.
#' The external pointer holds an additional reference to the `x` R object to
#' prevent it from garbage collection.
#'
#' `is.externalptr()` tests if the object given by `x` is an external pointer.
#'
#' `floatraw()` creates an array with a capacity to store `n` single-precision C
#' `float` values.
#' The array is implemented via a [base::raw()] vector.
#'
#' `as.floatraw()` coerces a numeric vector into a single-precision C `float`
#' vector.
#' Values given by `x` are converted to C `float` values and stored in the R raw
#' vector via `pack()`.
#' This function is useful when calling foreign functions that expect a C
#' `float` pointer via [dyncall()].
#'
#' `floatraw2numeric()` coerces a C `float` (raw) vector to a numeric vector.
#'
#' `ptr2str()`, `strarrayptr()`, `strptr()` are currently experimental.
#'
#' `offset_ptr()` creates a new external pointer pointing to `x` plus
#' the byte `offset`.
#' If `x` is given as an external pointer, the address is increased by the
#' `offset`, or, if `x` is given as a atomic vector, the address of the data
#' (pointing to offset zero) is taken as basis and increased by the `offset`.
#' The returned external pointer is protected (as offered by the C function `R_MakeExternalPtr`) by the
#' external pointer `x`.
#'
#' @return
#' A logical value is returned by `is.nullptr()` and `is.externalptr()`.
#' `as.externalptr()` and `offset_ptr()` returns an external pointer value.
#' `floatraw()` and `as.floatraw()` return an atomic vector of type `raw` tagged
#' with class `floatraw`.
#' `floatraw2numeric` returns a `numeric` atomic vector.
#'
#' @examples
#' is.nullptr(NULL)
#'
#' one <- as.externalptr(1)
#' is.externalptr(one)
#'
#' floatraw(1)
#'
#' floats <- as.floatraw(1:10)
#' all.equal(floatraw2numeric(floats), 1:10)
#' @keywords programming interface
#' @rdname utils
#' @export
is.nullptr     <- function(x)         .Call("C_isnullptr", x, PACKAGE = "rdyncall")

#' @rdname utils
#' @export
as.externalptr <- function(x)         .Call("C_asexternalptr", x, PACKAGE = "rdyncall")

#' @rdname utils
#' @export
offset_ptr     <- function(x, offset) .Call("C_offsetptr", x, offset, PACKAGE = "rdyncall")

#' @rdname utils
#' @export
is.externalptr <- function(x)         typeof(x) == "externalptr"

#' @rdname utils
#' @export
as.floatraw <- function(x) {
    x <- .Call("C_as_floatraw", as.numeric(x), PACKAGE = "rdyncall")
    class(x) <- "floatraw"
    x
}

#' @rdname utils
#' @export
floatraw2numeric <- function(x) {
    stopifnot(is.raw(x))
    stopifnot(class(x) == "floatraw")
    stopifnot(length(x) >= 4)
    .Call("C_floatraw2numeric", x, PACKAGE = "rdyncall")
}

#' @rdname utils
#' @export
floatraw <- function(n) {
    x <- raw(n * 4)
    class(x) <- "floatraw"
    x
}
#' @rdname utils
#' @export
ptr2str     <- function(x) .Call("C_ptr2str", x, PACKAGE = "rdyncall")
#' @rdname utils
#' @export
strarrayptr <- function(x) .Call("C_strarrayptr", x, PACKAGE = "rdyncall")
#' @rdname utils
#' @export
strptr      <- function(x) .Call("C_strptr", x, PACKAGE = "rdyncall")
