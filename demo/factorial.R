# Package: rdyncall
# File: demo/factorial.R
# Description: Recursive factorial using a callback object.

library(rdyncall)

factorial_callback <- function(x, fun) {
    if (x > 1L) {
        x * dyncall(fun, "ip)i", x - 1L, fun)
    } else {
        x
    }
}

cb <- ccallback("ip)i", factorial_callback)
result <- dyncall(cb, "ip)i", 10L, cb)
print(result)
stopifnot(identical(result, 3628800L))
