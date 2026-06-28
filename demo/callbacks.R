# Package: rdyncall
# File: demo/callbacks.R
# Description: Create callbacks and call them through dyncall.

library(rdyncall)

# This R function will be exposed as a C-callable callback.
add <- function(x, y) {
    x + y
}

# Signature `ii)i` means two C int arguments returning a C int.
add_callback <- ccallback("ii)i", add)
result <- dyncall(add_callback, "ii)i", 20L, 3L)
print(result)
stopifnot(identical(result, 23L))

# This callback demonstrates that a callback can receive its own function
# pointer and call it recursively through `dyncall()`.
recursive_add <- function(x, y, fun, n) {
    if (n > 1L) {
        # Signature `iipi)i` passes int, int, pointer, int and returns int.
        dyncall(fun, "iipi)i", x, y, fun, n - 1L)
    }
    x + y
}

# Convert the R closure to a native callback pointer and invoke it like C code.
recursive_callback <- ccallback("iipi)i", recursive_add)
result <- dyncall(recursive_callback, "iipi)i", 20L, 3L, recursive_callback, 100L)
print(result)
stopifnot(identical(result, 23L))
