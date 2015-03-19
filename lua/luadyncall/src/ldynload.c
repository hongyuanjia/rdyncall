#include "lua.h"
#include "lauxlib.h"
#include "dynload.h"

int lua_dlLoadLibrary(lua_State *L)
{
  const char* libpath;
  if ( lua_isnoneornil(L, 1) ) 
    libpath = NULL;
  else
    libpath = lua_tostring(L, 1);
  DLLib* pLib;
  pLib = dlLoadLibrary(libpath);
  if (pLib == NULL) return 0; 
  lua_pushlightuserdata(L, pLib);
  return 1;
}

int lua_dlFreeLibrary(lua_State *L)
{
  DLLib* pLib = (DLLib*) lua_touserdata(L, 1);
  dlFreeLibrary(pLib);
  return 0;
}

int lua_dlFindSymbol(lua_State *L)
{
  DLLib* pLib = (void*) lua_touserdata(L, 1);
  const char* pSymbolName = (const char*) lua_tostring(L, 2);
  void* addr = dlFindSymbol(pLib, pSymbolName);
  if (addr == NULL) return 0;
  lua_pushlightuserdata(L, addr);
  return 1;
}

static const struct luaL_Reg luareg_dynload[] = 
{
  { "dlLoadLibrary", lua_dlLoadLibrary },
  { "dlFreeLibrary", lua_dlFreeLibrary },
  { "dlFindSymbol",  lua_dlFindSymbol  },
  { NULL, NULL }
};

// LUALIB_API 
int luaopen_ldynload(lua_State *L)
{
  lua_createtable(L, 0, 0);
  luaL_register(L, NULL, luareg_dynload);
  return 1;
}

