user32 = dcLoad("user32")
msgbox = dcFind(user32,"MessageBoxA")
print(msgbox)
dcCall(msgbox, "iSSi)v", 0, "hello", "world", 0)

dcCall(msgbox, "iSSi)v", 0, "hello", "world2", 0)


