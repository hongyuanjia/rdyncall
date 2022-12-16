# Package: rdyncall
# File: R/pack.R
# Description: (un-)packing functions for access to C aggregate (struct/union) data types.

.pack <- function(x, offset, sigchar, value) {
    char1 <- substr(sigchar, 1, 1)
    if (char1 == "*") char1 <- "p"
    .Call("pack", x, as.integer(offset), char1, value, PACKAGE = "rdyncall")
}

.unpack <- function(x, offset, sigchar) {
    sigchar <- char1 <- substr(sigchar, 1, 1)
    if (char1 == "*") sigchar <- "p"
    x <- .Call("unpack", x, as.integer(offset), sigchar, PACKAGE = "rdyncall")
    if (char1 == "*") {
        attr(x, "basetype") <- substr(sigchar, 2, nchar(sigchar))
    }
    return(x)
}
