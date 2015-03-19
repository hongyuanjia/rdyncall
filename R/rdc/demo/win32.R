# example: message box on windows

h <- rdcLoad("user32")
f <- rdcFind(h,"MessageBoxA")
rdcCall(f,"ippi)v",0,"hallo","welt",0)
rdcFree(h)

