l <- rdcLoad("libc.dylib")
f <- rdcFind(l,"sqrt")
rdcCall(f, "d)d", 144)

