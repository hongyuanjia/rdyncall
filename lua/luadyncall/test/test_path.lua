require "path"
require "dynload"

function init(env,syspath)
  local env = env or "LIBPATH"
  local syspath = syspath or ";?.framework/?;lib?.dylib;"
  print("env\t="..env)
  print("syspath\t="..syspath)
  local path = pathinit(env,syspath)
  print("path\t="..path)
  return(path)
end

local mypath = init()

function findlib(name)
  local found, location = pathfind(mypath, name, loadlib)
  if found then 
    print("found at " .. location .. " ( object= " .. tostring(found) .. " )" ) 
  else
    print("FAILED: findlib('"..name.."'). tried:\n - " .. table.concat(location,"\n - ") .. "\n" )
  end
end

function trylib(name)
  print("trylib",name)
  local status, msg = pcall( findlib, name )
  print(status,msg)
end

trylib("GL")
trylib("OpenGL")
trylib("SDL")
trylib("Bla")


