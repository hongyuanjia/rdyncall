clib = dcLoad("msvcrt")
f = dcFind(clib,"sqrt")

x = dcCall(f,"d)d",144)
io.write("result ",x,"\n")

x = dcCall(f,"d)d",225)
io.write("result ",x,"\n")


f = dc("msvcrt:sqrt(d)d")
f()



