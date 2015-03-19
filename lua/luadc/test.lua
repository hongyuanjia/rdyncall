require "package"
pf = package.loadlib("luadc","luadc_open")
pf()

print(dc.C_DEFAULT)
print(dc.C_X86_WIN32_STD)

dc.mode(dc.C_DEFAULT)

clib = dc.load("msvcrt")
f = dc.find(clib,"sqrt")
x = dc.call(f,"d)d",144)
print(x)


dc.mode(dc.C_X86_WIN32_STD)

user32 = dc.load("user32")
f = dc.find(user32,"MessageBoxA")
x = dc.call(f,"iSSi)v", 0, "Hello", "World", 0)


