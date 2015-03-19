#include "dynguess.h"
#include "lua.h"
#include "lauxlib.h"

int luaopen_ldynguess(lua_State *L)
{
  lua_newtable(L);
  lua_pushliteral(L, "arch");
  lua_pushliteral(L, DG_ARCH);
  lua_settable(L, -3);
  lua_pushliteral(L, "os");
  lua_pushliteral(L, DG_OS);
  lua_settable(L, -3);
  lua_pushliteral(L, "cc");
  lua_pushliteral(L, DG_CC);
  lua_settable(L, -3);
  return 1;
}

