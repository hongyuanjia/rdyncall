require "smartptr"

-- test tolightuserdata

x = smartptr.tolightuserdata(0xCAFEbabe)
print(x)

-- test newsmartptr and finalizer

function finalizer(x)
  print("finalizer:"..tostring(x) )
end

y = smartptr.new(x, finalizer)
print("dump smartptr : ".. tostring(y) )
print("dump address  : " .. tostring(y()))
y = nil -- should print FINALIZER
collectgarbage("collect")
-- test setfinalizer

y = smartptr.new( smartptr.tolightuserdata(0xdeadc0de), finalizer)
print("smartptr : ".. tostring(y) )
print("address  : " .. tostring(y()))
function newfinalizer(x)
  print("newfinalizer:"..tostring(x))
end
smartptr.setfinalizer(y, newfinalizer)
y = nil

