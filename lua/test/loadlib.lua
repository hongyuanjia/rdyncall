require"package"
msgbox = package.loadlib("user32","MessageBoxA")
print(msgbox)
dcCall(msgbox,"iSSi)v",0,"hello","world",0)
sqrt = package.loadlib("msvcrt","sqrt")
print(sqrt)
x = dcCall(sqrt,"d)d",144)
-- print(x)

