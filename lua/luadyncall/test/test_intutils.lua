require "intutils"
u64 = intutils.u64
i64 = intutils.i64
local _print = print

local function print(x)
  local mt = getmetatable(x)
  local tostring = mt.__tostring
  if tostring then
    _print( tostring(x) )
  else
    _print(x)
  end
end

x = u64("0x00FFFFFFFFFFFF00")
y = u64("0xCA000000000000FE")
z = x + y
print(x)
print(y)
print(z)

x = i64("0x00FFFFFFFFFFFF00")
y = i64("0xCA000000000000FE")
z = x + y
print(x)
print(y)
print(z)

