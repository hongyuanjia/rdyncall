from pydc import *

""" show message box on windows """

user32 = load("user32")
fpMessageBoxA = find(user32,"MessageBoxA")
def showMessage(name,title="dyncall demo",type=0):
  call(fpMessageBoxA,"ippi)v",0,name,title,type)

showMessage("hello")

