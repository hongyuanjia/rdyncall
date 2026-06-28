# Package: rdyncall
# File: demo/sqrt.R
# Description: Bind the C math library sqrt function.

library(rdyncall)

# Bind `sqrt(double) -> double` from the platform C math library.
math <- new.env(parent = globalenv())
binding <- dynbind(c("msvcrt", "m", "m.so.6"), "sqrt(d)d;", envir = math)
stopifnot(!length(binding$unresolved.symbols))

# Call the generated wrapper exactly like an ordinary R function.
result <- math$sqrt(144)
print(result)
stopifnot(isTRUE(all.equal(result, 12)))
