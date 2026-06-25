# Package: rdyncall
# File: demo/factorial.R
# Description: Recursive factorial using a callback object.

library(rdyncall)

# Compute factorial through a self-recursive native callback pointer.
factorial_callback <- function(x, fun) {
    if (x > 1L) {
        # `fun` is the callback pointer passed back into R from the C call.
        x * dyncall(fun, "ip)i", x - 1L, fun)
    } else {
        x
    }
}

# Signature `ip)i` means int and pointer arguments returning int.
cb <- ccallback("ip)i", factorial_callback)
result <- dyncall(cb, "ip)i", 10L, cb)
print(result)
stopifnot(identical(result, 3628800L))
