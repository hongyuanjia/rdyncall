require "ldynstruct"
require "dyntype"

dynstruct_metatable = {
  __index = function(s, f)
    local typeinfo = rawget(s, "typeinfo")
    local fieldinfo = typeinfo.fields[f]
    if not fieldinfo then error("unknown field "..f.." for type "..typeinfo.name) end
    return ldynstruct.dynpeek( rawget(s, "pointer"), fieldinfo.offset, fieldinfo.typeinfo.signature )
  end,
  __newindex = function(s, f, v)
    local typeinfo = rawget(s, "typeinfo")
    local fieldinfo = typeinfo.fields[f]
    if not fieldinfo then error("unknown field "..f.." for type "..typeinfo.name) end
    ldynstruct.dynpoke( rawget(s, "pointer"), fieldinfo.offset, fieldinfo.typeinfo.signature, v )
  end
}

function newdynstruct(typename)
  local typeinfo = gettypeinfo(typename)
  local object = { pointer = ldynstruct.newstruct( typeinfo.size ), typeinfo = typeinfo }
  setmetatable(object, dynstruct_metatable)
  return object
end

function dyncast(object, typeinfo)
  local pointer
  if type(object) == "userdata" then
    pointer = object
  elseif type(object) == "table" then
    pointer = rawgeti(object, "pointer")
  end
  local object = { pointer = pointer, typeinfo = gettypeinfo(typeinfo) }
  setmetatable(object, dynstruct_metatable)
  return object
end

