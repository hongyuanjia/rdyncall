# File: rdc/demo/sqrt.R
# Description: call sqrt

if (.Platform$OS.type == "unix") {
  dyn.load("/lib/libc.so.6")
} else {
  dyn.load("/windows/system32/msvcrt")
}

sym.sqrt <- getNativeSymbolInfo("sqrt")

x <- 144.0
rdcCall( sym.sqrt$address, "d)d", x)

