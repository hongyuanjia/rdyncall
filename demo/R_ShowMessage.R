# Package: rdyncall
# File: demo/R_ShowMessage.R
# Description: Show an R dialog message through R's C API.

library(rdyncall)

# Bind one function from R's own shared library. Signature `Z` is a
# nul-terminated C string and `v` is a void return.
r_api <- new.env(parent = globalenv())
binding <- dynbind("R", "R_ShowMessage(Z)v;", envir = r_api)
stopifnot(!length(binding$unresolved.symbols))

# Call the C API directly through the generated R wrapper.
r_api$R_ShowMessage("hello from rdyncall")
