package = "luadyncall"
version = "0.1-1"
source = {
  url = "http://..."
}
description = {
  summary = "Lua DynCall Bindings variant 2.",
  detailed = [[
    Foreign Function Interface - variant 2 (built-in rock)
  ]],
  homepage = "http://dyncall.org",
  license = "ISC"
}
dependencies = {
  "lua >= 5.1"
}
external_dependencies = {
  DYNCALL = {
    header = "dyncall.h"
  }
}
build = {
  type = "builtin",
  modules = {
    ldynload = {
      sources = "src/ldynload.c",
      libraries = {"dynload_s"},
      libdirs = {"$(DYNCALL_LIBDIR)"},
      incdirs = {"$(DYNCALL_INCDIR)"}
    },
    ldyncall = {
      sources = "src/ldyncall.c",
      libraries = {"dyncall_s"},
      libdirs = {"$(DYNCALL_LIBDIR)"},
      incdirs = {"$(DYNCALL_INCDIR)"}
    },
    larray = {
      sources = "src/larray.c",
      incdirs = {"$(DYNCALL_INCDIR)"}
    },
    dynload = "src/dynload.lua",
    dyncall = "src/dyncall.lua",
    dynport = "src/dynport.lua",
    smartptr= "src/smartptr.lua",
    path    = "src/path.lua",
    array   = "src/array.c",
    intutils= "src/intutils.lua"
  }
}

