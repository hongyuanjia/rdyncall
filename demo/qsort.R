# Package: rdyncall
# File: demo/qsort.R
# Description: Sort an R numeric vector through C qsort and a callback comparator.

library(rdyncall)

# Bind the C standard library `qsort` function. The last argument is a callback
# pointer with the comparator signature expected by qsort.
libc <- new.env(parent = globalenv())
binding <- dynbind(c("msvcrt", "c", "c.so.6"), "qsort(piip)v;", envir = libc)
stopifnot(!length(binding$unresolved.symbols))

# Compare two memory locations that each point to one C double.
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
# Signature `pp)i` is qsort's comparator shape: pointer, pointer -> int.
compare_callback <- ccallback("pp)i", compare_double)

# `x` is modified in place by C qsort through its underlying memory buffer.
libc$qsort(x, length(x), 8L, compare_callback)
print(x)
stopifnot(isTRUE(all.equal(x, expected)))
