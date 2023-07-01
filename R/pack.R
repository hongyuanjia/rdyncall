#' Handling of foreign C fundamental data types
#'
#' @description
#' Functions to unpack/pack (read/write) foreign C data types from/to R atomic
#' vectors and C data objects such as arrays and pointers to structures.
#'
#' @details
#' The function `pack()` converts an R `value` into a C data type specified by
#' the [signature][type-signature] `sigchar` and it writes the raw C foreign
#' data value at byte position `offset` into the object `x`.
#'
#' The function `unpack()` extracts a C data type according to the
#' [signature][type-signature] `sigchar` at byte position `offset` from the
#' object `x` and converts the C value to an R value and returns it.
#'
#' Byte `offset` calculations start at 0 relative to the first byte in an atomic
#' vectors data area.
#'
#' If `x` is an atomic vector, a bound check is carried out before read/write
#' access.
#' Otherwise, if `x` is an external pointer, there is only a C NULL pointer
#' check.
#'
#' @param x atomic vector (logical, raw, integer or double) or external pointer.
#'
#' @param offset integer specifying _byte offset_ starting at 0.
#'
#' @param sigchar character string specifying the C data type by a
#'        [type signature][type-signature].
#'
#' @param value R object value to be coerced and packed to a foreign C data type.
#'
#' @return
#' `unpack()` returns a read C data type coerced to an R value.
#'
#' @seealso
#' [dyncall()] for details on type signatures.
#'
#' @examples
#' # transfer double to array of floats and back, compare precision:
#' n <- 6
#' input <- rnorm(n)
#' buf <- raw(n*4)
#' for (i in 1:n) {
#'     pack(buf, 4 * (i - 1), "f", input[i])
#' }
#'
#' output <- numeric(n)
#' for (i in 1:n) {
#'     output[i] <- unpack(buf, 4 * (i - 1), "f")
#' }
#' # difference between double and float
#' difference <- output - input
#' print(cbind(input, output, difference))
#' @rdname packing
#' @export
pack <- function(x, offset, sigchar, value) {
    char1 <- substr(sigchar, 1, 1)
    if (char1 == "*") char1 <- "p"
    .Call("C_pack", x, as.integer(offset), char1, value, PACKAGE = "rdyncall")
}

#' @rdname packing
#' @export
unpack <- function(x, offset, sigchar) {
    sigchar <- char1 <- substr(sigchar, 1, 1)
    if (char1 == "*") sigchar <- "p"
    x <- .Call("C_unpack", x, as.integer(offset), sigchar, PACKAGE = "rdyncall")
    if (char1 == "*") {
        attr(x, "basetype") <- substr(sigchar, 2, nchar(sigchar))
    }
    return(x)
}
