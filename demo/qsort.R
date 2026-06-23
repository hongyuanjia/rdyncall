# Package: rdyncall
# File: demo/qsort.R
# Description: Sort an R numeric vector through C qsort and a callback comparator.

library(rdyncall)

libc <- new.env(parent = globalenv())
binding <- dynbind(c("msvcrt", "c", "c.so.6"), "qsort(piip)v;", envir = libc)
stopifnot(!length(binding$unresolved.symbols))

compare_double <- function(px, py) {
    x <- unpack(px, 0L, "d")
    y <- unpack(py, 0L, "d")
    if (x < y) {
        -1L
    } else if (x > y) {
        1L
    } else {
        0L
    }
}

set.seed(42)
x <- rnorm(20L)
expected <- sort(x)
compare_callback <- ccallback("pp)i", compare_double)

libc$qsort(x, length(x), 8L, compare_callback)
print(x)
stopifnot(isTRUE(all.equal(x, expected)))
