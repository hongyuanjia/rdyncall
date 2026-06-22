# Package: rdyncall
# File: demo/sqrt.R
# Description: Bind the C math library sqrt function.

library(rdyncall)

math <- new.env(parent = globalenv())
binding <- dynbind(c("msvcrt", "m", "m.so.6"), "sqrt(d)d;", envir = math)
stopifnot(!length(binding$unresolved.symbols))

result <- math$sqrt(144)
print(result)
stopifnot(isTRUE(all.equal(result, 12)))
