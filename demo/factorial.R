f <- function(i,fun)
{
  if (i > 1) i * dyncall(fun,"ip)i",i-1,fun) else i
}
e <- new.env()
cb <- new.callback("ip)i", f,e)
e <- NULL
f <- NULL
gc()
r <- dyncall(cb,"ip)i",12,cb)
r == factorial(12)
cb <- NULL
gc()
