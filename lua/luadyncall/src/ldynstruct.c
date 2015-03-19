#include "lua.h"
#include "lauxlib.h"
#include "dyncall.h"
#include "dyncall_signature.h"
#include <stddef.h>

static int lua_newstruct(lua_State *L)
{
  size_t size;
  void  *addr;
  size = (size_t) luaL_checkinteger(L, 1);
  addr = lua_newuserdata(L, size);
  return 1; 
}

static int lua_aslightuserdata(lua_State *L)
{
  lua_pushlightuserdata(L, (void*) (ptrdiff_t) luaL_checkinteger(L, 1) );
  return 1;
}

/*
static int lua_newdynstruct(lua_State *L)
{
  size_t size;
  void  *addr;
  size = (size_t) luaL_checkinteger(L, 1);
  luaL_checktype(L, 2, LUA_TTABLE);
  addr = lua_newuserdata(L, size);
  lua_pushvalue(L, 2);
  lua_setmetatable(L, 3);
  return 1; 
}
*/

int lua_dynpoke(lua_State *L)
{ 
  const char *ptr     = (const char *) lua_touserdata(L, 1);
  size_t      offset  = (ptrdiff_t) lua_tointeger(L, 2);
  const char *typesig = (const char*) lua_tostring(L, 3);
  const char *sig     = typesig;
  char ch;
  ptr += offset;
  while ((ch=*sig++) != '\0') {
    switch(ch) {
      case DC_SIGCHAR_BOOL:   *((int*)ptr) = lua_toboolean(L, 4); break;
      case DC_SIGCHAR_CHAR:   *((char*)ptr) = (char) lua_tointeger(L, 4); break;
      case DC_SIGCHAR_UCHAR:  *((unsigned char*)ptr) = (unsigned char) lua_tointeger(L, 4); break;
      case DC_SIGCHAR_SHORT:  *((short*)ptr) = (short) lua_tointeger(L, 4); break;
      case DC_SIGCHAR_USHORT: *((unsigned short*)ptr) = (unsigned short) lua_tointeger(L, 4); break;
      case DC_SIGCHAR_INT:    *((int*)ptr) = lua_tointeger(L, 4); break;
      case DC_SIGCHAR_UINT:   *((unsigned int*)ptr) = (unsigned int) lua_tonumber(L, 4); break;
      case DC_SIGCHAR_LONG:   *((long*)ptr) = (long) lua_tonumber(L, 4); break;
      case DC_SIGCHAR_ULONG:  *((unsigned long*)ptr) = (unsigned long) lua_tonumber(L, 4); break;
      case DC_SIGCHAR_LONGLONG: *((DClonglong*)ptr) = (long long) lua_tonumber(L, 4); break;
      case DC_SIGCHAR_ULONGLONG: *((DCulonglong*)ptr) = (unsigned long long) lua_tonumber(L, 4); break;
      case DC_SIGCHAR_FLOAT: *((float*)ptr) = (float) lua_tonumber(L, 4); break;
      case DC_SIGCHAR_DOUBLE: *((double*)ptr) = (double) lua_tonumber(L, 4); break;
      case DC_SIGCHAR_POINTER: *((const void**)ptr) = lua_topointer(L, 4); break;
      case DC_SIGCHAR_STRING: *((const char**)ptr) = lua_topointer(L, 4); break;
      default: luaL_error(L, "invalid type signature %s", typesig); return 0;
    }
  }
  return 0;
}

int lua_dynpeek(lua_State *L)
{
  const char *ptr     = (const char *) lua_touserdata(L, 1);
  size_t      offset  = (ptrdiff_t) lua_tointeger(L, 2);
  const char *typesig = (const char*) lua_tostring(L, 3);
  const char* sig = typesig;
  char ch;
  ptr += offset;
  while ((ch = *sig++) != '\0') {
    switch(ch) {
      case DC_SIGCHAR_BOOL:   lua_pushboolean(L,       *((int*)ptr)); break;
      case DC_SIGCHAR_CHAR:   lua_pushinteger(L, (int) *((char*)ptr)); break;
      case DC_SIGCHAR_UCHAR:  lua_pushinteger(L, (int) *((unsigned char*)ptr)); break;
      case DC_SIGCHAR_SHORT:  lua_pushinteger(L, (int) *((short*)ptr)); break;
      case DC_SIGCHAR_USHORT: lua_pushinteger(L, (int) *((unsigned short*)ptr)); break;
      case DC_SIGCHAR_INT:    lua_pushinteger(L,       *((int*)ptr)); break;
      case DC_SIGCHAR_UINT:   lua_pushnumber(L, (lua_Number) *((unsigned int*)ptr)); break;
      case DC_SIGCHAR_LONG:   lua_pushnumber(L, (lua_Number) *((long*)ptr)); break;
      case DC_SIGCHAR_ULONG:  lua_pushnumber(L, (lua_Number) *((unsigned long*)ptr)); break;
      case DC_SIGCHAR_LONGLONG: lua_pushnumber(L, (lua_Number) *((DClonglong*)ptr)); break;
      case DC_SIGCHAR_ULONGLONG: lua_pushnumber(L, (lua_Number) *((DCulonglong*)ptr)); break;
      case DC_SIGCHAR_FLOAT: lua_pushnumber(L, (lua_Number) *((float*)ptr)); break;
      case DC_SIGCHAR_DOUBLE: lua_pushnumber(L, (lua_Number) *((double*)ptr)); break;
      case DC_SIGCHAR_POINTER: lua_pushlightuserdata(L, *((void**)ptr) ); break;
      case DC_SIGCHAR_STRING: lua_pushstring(L, (const char*)ptr); break;
      default: luaL_error(L, "invalid type signature %s", typesig); return 0;
    }
  }
  return 1;
}

static const struct luaL_Reg luareg_dynstruct[] = 
{
  { "newstruct",    lua_newstruct },
  { "aslightuserdata", lua_aslightuserdata },
  { "dynpoke",      lua_dynpoke },
  { "dynpeek",      lua_dynpeek },
  { NULL, NULL }
};

LUA_API int luaopen_ldynstruct(lua_State *L)
{
  luaL_register(L, "ldynstruct", luareg_dynstruct);
  return 1;
}
