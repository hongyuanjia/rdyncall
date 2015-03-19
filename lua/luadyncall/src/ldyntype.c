#include "lua.h"
#include "lauxlib.h"
#include "dyncall.h"
#include "dyncall_signature.h"

size_t dtSize(const char* signature)
{
  char ch = *signature;
  switch(ch)
  {
    case DC_SIGCHAR_BOOL: return sizeof(DCbool);
    case DC_SIGCHAR_CHAR: return sizeof(DCchar);
    case DC_SIGCHAR_UCHAR: return sizeof(DCuchar);
    case DC_SIGCHAR_SHORT: return sizeof(DCshort);
    case DC_SIGCHAR_USHORT: return sizeof(DCushort);
    case DC_SIGCHAR_INT: return sizeof(DCint);
    case DC_SIGCHAR_UINT: return sizeof(DCuint);
    case DC_SIGCHAR_LONG: return sizeof(DClong);
    case DC_SIGCHAR_ULONG: return sizeof(DCulong);
    case DC_SIGCHAR_LONGLONG: return sizeof(DClonglong);
    case DC_SIGCHAR_ULONGLONG: return sizeof(DCulonglong);
    case DC_SIGCHAR_FLOAT: return sizeof(DCfloat);
    case DC_SIGCHAR_DOUBLE: return sizeof(DCdouble);
    case DC_SIGCHAR_POINTER: return sizeof(DCpointer);
    case DC_SIGCHAR_STRING: return sizeof(DCstring);
    case DC_SIGCHAR_VOID: return sizeof(DCvoid);
    default: return 0;
  }
}

size_t dtAlign(const char* signature)
{
  return dtSize(signature);
}


int lua_dtSize(lua_State *L)
{ 
  const char* signature = luaL_checkstring(L, 1);
  lua_pushinteger(L, dtSize(signature));
  return 1;
}

int lua_dtAlign(lua_State *L)
{ 
  const char* signature = luaL_checkstring(L, 1);
  lua_pushinteger(L, dtAlign(signature));
  return 1;
}


static const struct luaL_Reg luareg_ldyntype[] =
{
  { "dtSize", lua_dtSize },
  { "dtAlign", lua_dtAlign },
  { NULL, NULL }
};

LUA_API int luaopen_ldyntype(lua_State *L)
{
  luaL_register(L, "ldyntype", luareg_ldyntype);
  return 1;
}

