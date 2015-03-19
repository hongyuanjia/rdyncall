
-- loading libraries and resolve symbols in lua

local path = "/usr/local/lua/lib/libluadc.so"
dclib = loadlib("luadc", "luaopen_dc")
dclib()


dc.load("bla")
dc.find("hallo")

callpad = dc.newcallvm(4096)
callpad.mode("__cdecl")
callpad(f,"iSSi)v",0,"hello","world",0)



