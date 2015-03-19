require"larray"
-- typesignature = require"typesignature"
local array_mt = {
  __index = function(t,i) 
    if type(i) == "number" then
      return larray.peek( t.pointer, t.typesize * (i-1), t.typeinfo ) 
    else 
      local result = rawget(t,i)
      if not result then
        return getmetatable(t)[i]
      end
    end
  end,
  __newindex = function(t,i,v) 
    if type(i) == "number" then
      return larray.poke( t.pointer, t.typesize * (i-1), t.typeinfo, v) 
    else
      return rawset(t,i,v)
    end
  end,
  copy = function(array,src,nelements) 
    return larray.copy( array.pointer, 0, src, 0, array.typesize * nelements)
  end
}

--- Get type information from type signature.
--
-- @param signature string representing type informations. Fundamental type signatures are represented by characters such as 'c' for C char, 's' for C short, 'i' for C int, 'j' for C long
-- 'l' for C long long, 'f' for C float, 'd' for C double, 'p' for C pointer,
-- 'B' for ISO C99 _Bool_t/C++ bool, 'v' for C void. Upper-case characters 'CSIJL' refer to the corresponding unsigned C type.
-- Function signature syntax: 'name(argtypes..)resulttypes..;'
-- Structure signature syntax: 'name{fieldtypes..)fieldnames..;' the fieldnames are space separated text tokens.
-- Named objects can be refered using '<name>' syntax.
-- pointer types can be specified by prefixing multiple '*'.
-- function typesignature(signature)
-- end

--- Get size of fundamental C types.
-- @param typeinfo a simple C type signature string.
-- @see typesignature
function typesize(typesignature)
  return typesizes[typesignature]
end

--- Create a lua-memory managed C array.
-- Arrays are represented as a table with fields.
-- @field pointer holds the address represented by a lua userdata object.
-- @return array object
function array(typeinfo, length)
  local typesize = larray.sizeof(typeinfo)
  local size     = typesize * length
  local pointer  = larray.newudata(size)
  local o = { 
    pointer   = pointer, 
    size      = size, 
    length    = length, 
    typesize  = typesize, 
    typeinfo  = typeinfo,
  }
  setmetatable(o, array_mt)
  return o
end


