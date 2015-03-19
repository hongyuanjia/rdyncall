require "dynload"

x = dynload("GL|OpenGL")
print( dynsym(x, "glClear") )

