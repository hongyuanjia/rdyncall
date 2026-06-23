# Package: rdyncall
# File: demo/callbacks.R
# Description: Create callbacks and call them through dyncall.

library(rdyncall)

# A callback is represented as a C-callable function pointer.
add <- function(x, y) {
    x + y
}

add_callback <- ccallback("ii)i", add)
result <- dyncall(add_callback, "ii)i", 20L, 3L)
print(result)
stopifnot(identical(result, 23L))

# A callback can receive its own function pointer and call it recursively.
recursive_add <- function(x, y, fun, n) {
    if (n > 1L) {
        dyncall(fun, "iipi)i", x, y, fun, n - 1L)
    }
    x + y
}

recursive_callback <- ccallback("iipi)i", recursive_add)
result <- dyncall(recursive_callback, "iipi)i", 20L, 3L, recursive_callback, 100L)
print(result)
stopifnot(identical(result, 23L))
