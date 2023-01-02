# Package: rdyncall 
# File: demo/R_malloc.R
# Description: using R's memory allocator directly in R

dynbind("R","R_chk_calloc(ii)p;R_chk_free(p)v;")
malloc <- function(size) 
{
  x <- R_chk_calloc(as.integer(size),1L)
  reg.finalizer(x, R_chk_free)
  return(x)
}

x <- malloc(1024)
x <- NULL
gc()

