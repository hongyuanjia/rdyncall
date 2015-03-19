require "smartptr"

local dl = require "ldynload"

--- load library given by name using operating-system level service.
-- @return smartptr that will free library if the object gets garbage collected.

function loadlib(name)
  local handle = dl.dlLoadLibrary(name)
  if handle then return smartptr.new( handle, dl.dlFreeLibrary ) end
end

--- resolve symbols
-- @param lib smartptr 
-- @param name symbol to resolve to address
-- @return address light userpointer
function dynsym(lib, name)
  local handle = lib()
  return dl.dlFindSymbol( handle, name )
end

--- load shared library code
-- This mechanism uses a platform-independent interface to search for
-- the libraries.
-- On Linux, BSD, UNIX and Mac OS X the standard places such as "/", "/lib" are searched.
-- @param libnames a string separated by '|' (pipe) for the pure library name without prefix/suffixes.


function dynload(libnames)
  
  local lib

  if libnames == "" then
    return loadlib(nil)
  end

  -- Unix search paths

  local paths    = { "", "./", "/lib/", "/usr/lib/", "/usr/local/lib/", "/opt/lib/", "/opt/local/lib/" }
  local prefixes = { "", "lib" }
  local suffixes = { "", ".dylib", ".so", ".so.0", ".dll" }

  -- Mac OS X Framework search paths
  -- local fwpaths  = { "", "/System" }

  for libname in libnames:gmatch("[^|]+") do

    for k,path in pairs(paths) do
      for k,prefix in pairs(prefixes) do
        for k,suffix in pairs(suffixes) do
          local libpath = path .. prefix .. libname .. suffix
	  lib = loadlib(libpath)
          if lib then return lib end
        end
      end
    end

  -- search Mac OS X frameworks:

    lib = loadlib( libname .. ".framework/" .. libname )

  --[[
    for k,fwpath in pairs(fwpaths) do
      local libpath = fwpath .. "/Library/Frameworks/" .. libname .. ".framework/" .. libname
      lib = ldynload.dlLoadLibrary(libpath)
      if libhandle then break end
    end
  ]]

    if lib then return lib end

  end

  if not lib then error("unable to locate library "..libnames) end

end

