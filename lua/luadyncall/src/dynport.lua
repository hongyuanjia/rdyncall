require "dynload"
require "dyncall"
require "path"

local function makewrapper(addr, signature)
  return function(...) return dyncall(addr, signature, ...) end
end

loaded = { }

--- The dynport path is initialized by LDP_PATH environment.
-- @usage Defaults to dynport_syspath.
dynport_path = pathinit("LDP_PATH","?.dynport;/usr/local/share/dynport/?.dynport;/opt/local/share/dynport/?.dynport")

local function find(name)
  return pathfind( dynport_path, name, io.open )
end

--[[ 
local LDP_PATH = "?.dynport;/usr/local/share/dynport/?.dynport;/opt/local/share/dynport/?.dynport"
local path = os.getenv("LDP_PATH") or LDP_PATH

local function find(name)  
  local replaced = path:gsub("?", name)
  local f = nil
  local hist = {}
  for filename in replaced:gmatch("([^;]+)") do
    f = io.open(filename)
    if f then break else
      table.insert(hist, "\tno file '")
      table.insert(hist, filename)
      table.insert(hist, "'\n")
    end
  end
  if f then
    return f
  else
    error("dynport '"..name.."' not found:\n"..table.concat(hist), 3)
  end
end
]]


--- Process dynport files.
-- Files will be opened and processed according to the dynport format.
-- Function wrappers and constants will be installed.
-- Structure/Union type information have not been implemented yet.
-- @param name dynport name to lookup. 
-- @unit table to use for import.
-- @field _dynport_libs contains.
-- @return unit table with imports.

function dynport_NEW(portname, t)
  local t = t or _G
  local port = loaded[portname]
  if port then return port end
  local file, errmsg = searchpath(portname, path)
  if not file then error(errmsg) end
end

function dynportImport(name, unit)

  local file = find(name)

  if not unit._dynport_libs then
    unit._dynport_libs = { }
  end

  local cached = unit._dynport_libs[name]
  if cached then return unit end
 
  if not file then
    error("dynport "..name.. " not found")
  end

  local iter = file:lines()
  
  local libs = { }
  
  function dolib()
    local libnames = ""
    for line in iter do
      if line == "." then break end
      libnames = line
    end
    libs[#libs+1] = dynload(libnames)
  end

  function dofun()
    local index = 1
    local unresolved = {}
    for line in iter do

      if line == "." then break end

      local pos       = line:find("[(]")
      local symbol    = line:sub(1, pos-1)
      local stop      = line:find("[;]", pos+1)
      local signature = line:sub(pos+1,stop-1)

      local addr      = dynsym(libs[#libs], symbol)

      if type(addr) == "userdata" then
        rawset(unit, symbol, makewrapper(addr, signature) )
        -- module[symbol] = makewrapper(addr, signature)
      else
        unresolved[#unresolved] = symbol
      end

    end

    if #unresolved ~= 0 then
      print("unresolved symbols:")
      print(table.concat(unresolved,"\n"))
    end
  end

  function doconst() 
    for line in iter do
      if line == "." then break end
      local pos = line:find("=")
      local key = line:sub(1, pos-1)
      local value = line:sub(pos+1)
      -- module[key] = tonumber(value)
      rawset( unit, key, tonumber(value) )
    end
  end

  function dostruct()
    for line in iter do
      if line == "." then break end
    end
  end

  function dounion()
    for line in iter do
      if line == "." then break end
    end
  end
  
  for line in iter do
    if line == "." then break 
    elseif line == ":lib" then dolib() 
    elseif line == ":fun" then dofun() 
    elseif line == ":const" then doconst() 
    elseif line == ":struct" then dostruct()
    elseif line == ":union" then dounion()
    end
  end
  
  unit._dynport_libs[name] = libs

  return unit

end

--- Dynamic bind C library Interfaces.
-- @param name dynport name which will be searched by
function dynport(portname)
  return dynportImport(portname, _G)
end


