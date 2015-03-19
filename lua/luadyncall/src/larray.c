#include "lua.h"
#include "lauxlib.h"
#include "dyncall.h"
#include "dyncall_signature.h"
#include "dyntype.h"

int newudata(lua_State* L)
{
  size_t size    = luaL_checkint(L, 1);
  void * pointer = lua_newuserdata(L, size);
  return 1;
}

int newudata2(lua_State* L)
{
  size_t size    = luaL_checkint(L, 1);
  void * pointer = lua_newuserdata(L, size);
  lua_pushvalue(L,-2);
  lua_setmetatable(L,-2);
  return 1;
}


int peek(lua_State* L)
{
  char* pointer  = (char*) lua_topointer(L, 1);
  int   offset   = luaL_checkint(L, 2);
  const char* typeinfo = luaL_checkstring(L, 3);
  pointer += offset;
  switch( *typeinfo )
  {
    case DC_SIGCHAR_BOOL:   lua_pushboolean(L, (int) * ( (DCbool*) pointer ) ); break;
    case DC_SIGCHAR_CHAR:   lua_pushnumber(L, (lua_Number) * ( (DCchar*) pointer ) ); break;
    case DC_SIGCHAR_UCHAR:  lua_pushnumber(L, (lua_Number) * ( (DCuchar*) pointer ) ); break;
    case DC_SIGCHAR_SHORT:  lua_pushnumber(L, (lua_Number) * ( (DCshort*) pointer ) ); break;
    case DC_SIGCHAR_USHORT: lua_pushnumber(L, (lua_Number) * ( (DCushort*) pointer ) ); break;
    case DC_SIGCHAR_INT:    lua_pushnumber(L, (lua_Number) * ( (DCint*) pointer ) ); break;
    case DC_SIGCHAR_UINT:   lua_pushnumber(L, (lua_Number) * ( (DCuint*) pointer ) ); break;
    case DC_SIGCHAR_LONG:   lua_pushnumber(L, (lua_Number) * ( (DClong*) pointer ) ); break;
    case DC_SIGCHAR_ULONG:  lua_pushnumber(L, (lua_Number) * ( (DCulong*) pointer ) ); break;
    case DC_SIGCHAR_LONGLONG: lua_pushnumber(L, (lua_Number) * ( (DClonglong*) pointer ) ); break;
    case DC_SIGCHAR_ULONGLONG: lua_pushnumber(L, (lua_Number) * ( (DCulonglong*) pointer ) ); break;
    case DC_SIGCHAR_FLOAT: lua_pushnumber(L, (lua_Number) * ( (DCfloat*) pointer ) ); break;
    case DC_SIGCHAR_DOUBLE: lua_pushnumber(L, (lua_Number) * ( (DCdouble*) pointer ) ); break;
    case DC_SIGCHAR_POINTER: lua_pushlightuserdata(L, * ( (DCpointer*) pointer ) ); break;
    default: luaL_error(L, "invalid type signature: %s\n", typeinfo); break;
  }
  return 1; 
}

int poke(lua_State* L)
{
  char* pointer        = (char*) lua_topointer(L, 1);
  int   offset         = luaL_checkint(L, 2);
  const char* typeinfo = luaL_checkstring(L, 3);
  pointer += offset;
  switch( *typeinfo )
  {
    case DC_SIGCHAR_BOOL:   * ( (DCbool*) pointer ) = lua_toboolean(L, 4); break;
    case DC_SIGCHAR_CHAR:   * ( (DCchar*) pointer ) = (DCchar) luaL_checkint(L, 4); break;
    case DC_SIGCHAR_UCHAR:  * ( (DCuchar*) pointer ) = (DCuchar) luaL_checkint(L, 4); break;
    case DC_SIGCHAR_SHORT:  * ( (DCshort*) pointer ) = (DCshort) luaL_checkint(L, 4); break;
    case DC_SIGCHAR_USHORT: * ( (DCushort*) pointer ) = (DCushort) luaL_checkint(L, 4); break;
    case DC_SIGCHAR_INT:    * ( (DCint*) pointer ) = (DCint) luaL_checkint(L, 4); break;
    case DC_SIGCHAR_UINT:   * ( (DCuint*) pointer ) = (DCuint) luaL_checknumber(L, 4); break;
    case DC_SIGCHAR_LONG:   * ( (DClong*) pointer ) = (DClong) luaL_checknumber(L, 4); break;
    case DC_SIGCHAR_ULONG:  * ( (DCulong*) pointer ) = (DCulong) luaL_checknumber(L, 4); break;
    case DC_SIGCHAR_LONGLONG: * ( (DClonglong*) pointer ) = (DClonglong) luaL_checknumber(L,4); break;
    case DC_SIGCHAR_ULONGLONG:  * ( (DCulonglong*) pointer ) = (DCulonglong) luaL_checknumber(L,4); break;
    case DC_SIGCHAR_FLOAT: * ( (DCfloat*) pointer ) = (DCfloat) luaL_checknumber(L,4); break;
    case DC_SIGCHAR_DOUBLE: * ( (DCdouble*) pointer ) = (DCdouble) luaL_checknumber(L,4); break;
    case DC_SIGCHAR_POINTER: 
      {
        switch(lua_type(L,4)) {
          case LUA_TUSERDATA:
          case LUA_TLIGHTUSERDATA:
            * ( (DCpointer*) pointer ) = (DCpointer) lua_topointer(L,4); break;
          case LUA_TSTRING:
            * ( (DCpointer*) pointer ) = (DCpointer) lua_tostring(L,4); break;
          default:
            luaL_error(L, "invalid argument for signature : %s\n", typeinfo); break;
        }
        break;
      }
    default: luaL_error(L, "invalid type signature: %s\n", typeinfo); break;
  }
  return 0; 
}

int lua_sizeof(lua_State *L)
{
  const char* typeinfo = luaL_checkstring(L, 1);
  lua_pushinteger(L, dtSize(typeinfo) );
  return 1;
}

int copy(lua_State *L)
{
  char* dstptr         = (char*) lua_topointer(L, 1);
  int   dstoffset      = luaL_checkint(L, 2);
  const char* srcptr   = lua_topointer(L, 3);
  int   srcoffset      = luaL_checkint(L, 4);
  int   copysize       = luaL_checkint(L, 5);
  dstptr += dstoffset;
  srcptr += srcoffset;
  int   i;
  for(i=0;i<copysize;++i)
  {
    *dstptr++ = *srcptr++;
  }
  return 0;
}

static const struct luaL_Reg luareg_larray[] = 
{
  {"newudata" ,newudata},
  {"newudata2", newudata2},
  {"peek"     ,peek},
  {"poke"     ,poke},
  {"sizeof"   ,lua_sizeof},
  {"copy"     ,copy},
  {NULL       ,NULL}
};

LUA_API int luaopen_larray(lua_State* L)
{
  luaL_register(L, "larray", luareg_larray);
  return 0;
}
