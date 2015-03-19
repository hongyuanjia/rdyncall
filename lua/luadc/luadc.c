#include <lua.h>
#include <lauxlib.h>
#include <dyncall.h>
#include <dyncall_signature.h>
#include <dynload.h>

#define LUA_DCLIBNAME "dc"

DCCallVM* g_pCallVM;

int luaDC_load(lua_State* L)
{
  void* handle;
  if (lua_gettop(L) != 1) return luaL_error(L,"wrong number of arguments");
  handle = dlLoadLibrary( lua_tostring(L,1) );
  if (!handle) return luaL_error(L,"library not found");
  lua_pushlightuserdata(L, handle);
  return 1;
}

int luaDC_find(lua_State* L)
{
  void* h;
  const char* s;
  void* f;
  if (lua_gettop(L) != 2) return luaL_error(L,"wrong number of arguments");
  h = lua_touserdata(L, 1);
  s = lua_tostring(L, 2);
  f = dlFindSymbol(h, s);
  if (!f) return luaL_error(L,"symbol not found");
  lua_pushlightuserdata(L, f);
  return 1;
}

int luaDC_mode(lua_State* L)
{
  if (lua_gettop(L) < 1) return luaL_error(L,"missing arguments");
  dcMode(g_pCallVM, (DCint) lua_tonumber(L, 1) );
  return 0;
}

int luaDC_call(lua_State* L)
{
  void* f;
  const char* s;
  if (lua_gettop(L) < 2) return luaL_error(L,"missing arguments");
  
  if ( lua_iscfunction(L,1) ) 
    f = (void*) lua_tocfunction(L,1);    
  else if (lua_islightuserdata(L,1) ) 
    f = lua_touserdata(L, 1);
  else
    return luaL_error(L,"argument #1 mismatch: expected userdata");
 
  s = lua_tostring(L,2);
  
  // dcMode( g_pCallVM, DC_CALL_C_DEFAULT );
  dcReset( g_pCallVM );
 
  char ch;
  int p = 3;
  while ( (ch = *s++) != DC_SIGCHAR_ENDARG)
  {
    switch(ch)
    {
      case DC_SIGCHAR_BOOL:
        dcArgBool(g_pCallVM, (DCbool) lua_toboolean(L, p) );
        break;
      case DC_SIGCHAR_CHAR:
        dcArgChar(g_pCallVM, (DCchar) lua_tonumber(L, p) );
        break;
      case DC_SIGCHAR_SHORT:
        dcArgShort(g_pCallVM, (DCshort) lua_tonumber(L, p) );
        break;
      case DC_SIGCHAR_INT:
        dcArgInt(g_pCallVM, (DCint) lua_tonumber(L, p) );
        break;
      case DC_SIGCHAR_LONG:
        dcArgLong(g_pCallVM, (DClong) lua_tonumber(L, p) );
        break;
      case DC_SIGCHAR_LONGLONG:
        dcArgLongLong(g_pCallVM, (DClonglong) lua_tonumber(L, p) );
        break;
      case DC_SIGCHAR_FLOAT:
        dcArgFloat(g_pCallVM, (DCfloat) lua_tonumber(L, p) );
        break; 
      case DC_SIGCHAR_DOUBLE:
        dcArgDouble(g_pCallVM, (DCdouble) lua_tonumber(L, p) );
        break;
      case DC_SIGCHAR_POINTER:
        dcArgPointer(g_pCallVM, (DCpointer) lua_topointer(L, p) );
        break;
      case DC_SIGCHAR_STRING:
        dcArgPointer(g_pCallVM, (DCpointer) lua_tostring(L, p) );
        break; 
    }
    ++p;
  }

  switch(*s)
  {
    case DC_SIGCHAR_VOID:
      dcCallVoid(g_pCallVM, f);
      return 0;
    case DC_SIGCHAR_BOOL:   
      lua_pushboolean( L, (int) dcCallBool(g_pCallVM, f) ); 
      break;
    case DC_SIGCHAR_CHAR:
      lua_pushnumber( L, (lua_Number) ( dcCallChar(g_pCallVM,f) ) );
      break;
    case DC_SIGCHAR_SHORT:
      lua_pushnumber( L, (lua_Number)( dcCallShort(g_pCallVM, f) ) );
      break;
    case DC_SIGCHAR_INT:
      lua_pushnumber( L, (lua_Number)( dcCallInt(g_pCallVM, f) ) );
      break;
    case DC_SIGCHAR_LONG:
      lua_pushnumber( L, (lua_Number)( dcCallLong(g_pCallVM, f) ) );
      break;
    case DC_SIGCHAR_LONGLONG:
      lua_pushnumber( L, (lua_Number)( dcCallLongLong(g_pCallVM, f) ) );
      break;
    case DC_SIGCHAR_FLOAT:
      lua_pushnumber( L, (lua_Number) dcCallFloat(g_pCallVM, f) );
      break;
    case DC_SIGCHAR_DOUBLE:
      lua_pushnumber( L, (lua_Number) dcCallDouble(g_pCallVM, f) ); 
      break;
    case DC_SIGCHAR_STRING:
      lua_pushstring( L, (const char*) dcCallPointer(g_pCallVM, f) );
      break;
    case DC_SIGCHAR_POINTER:
      lua_pushlightuserdata( L, dcCallPointer(g_pCallVM, f) );
      break;
  }
  return 1;
}

static const luaL_Reg dclib[] = 
{
  {"load", luaDC_load},
  {"find", luaDC_find},
  {"mode", luaDC_mode},
  {"call", luaDC_call},
  {NULL,NULL}
};

typedef struct 
{
  const char* name;
  int value;
} ModeEnum;

ModeEnum gModeEnums[] = 
{
  "C_DEFAULT", DC_CALL_C_DEFAULT,
  "C_X86_CDECL", DC_CALL_C_X86_CDECL,
  "C_X86_WIN32_STD", DC_CALL_C_X86_WIN32_STD,
  "C_X86_FAST_MS", DC_CALL_C_X86_WIN32_FAST_MS,
  "C_X86_WIN32_THIS_MS", DC_CALL_C_X86_WIN32_THIS_MS,
  "C_X86_WIN32_THIS_GNU", DC_CALL_C_X86_WIN32_THIS_GNU,
  "C_X86_WIN32_FAST_GNU", DC_CALL_C_X86_WIN32_FAST_GNU,
  "C_X64_WIN64", DC_CALL_C_X64_WIN64,
  "C_PPC32_DARWIN", DC_CALL_C_PPC32_DARWIN,
  "C_ARM", DC_CALL_C_ARM,
  "C_MIPS_EABI", DC_CALL_C_MIPS32_EABI,
  "C_MIPS_PSPSDK", DC_CALL_C_MIPS32_PSPSDK
};

LUA_API int luadc_open (lua_State* L)
{
  int i = 0, n = sizeof(gModeEnums)/sizeof(ModeEnum);
  g_pCallVM = dcNewCallVM(256); 
  luaL_register(L, LUA_DCLIBNAME, dclib);

  for (i = 0; i < n ; ++i )
  {
    lua_pushnumber(L, gModeEnums[i].value);
    lua_setfield(L, -2, gModeEnums[i].name);
  
  }
  return 1; 
}

