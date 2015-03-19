dynbind(c("msvcrt","c","c.so.6"), "qsort(piip)v;")
cb <- new.callback("pp)i",function(px,py){  
  x <- .unpack(px, 0, "d")
  y <- .unpack(py, 0, "d")
  if (x >  y) return(1) else if (x == y) return(0) else return(-1)
})
x <- rnorm(100)
qsort(x,length(x),8,cb)


