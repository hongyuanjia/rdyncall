# Package: rdyncall
# File: demo/R_ShowMessage.R
# Description: Show an R dialog message through R's C API.

library(rdyncall)

r_api <- new.env(parent = globalenv())
binding <- dynbind("R", "R_ShowMessage(Z)v;", envir = r_api)
stopifnot(!length(binding$unresolved.symbols))

r_api$R_ShowMessage("hello from rdyncall")
