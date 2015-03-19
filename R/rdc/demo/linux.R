l <- rdcLoad("libm.so.6")
f <- rdcFind(l,"sqrt")
rdcCall(f, "d)d", 144)


