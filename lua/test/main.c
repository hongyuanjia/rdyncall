#include <lua.h>
#include <assert.h>
#include <dynload.h>
#include <dyncall.h>
#include <dyncall_signature.h>

int lua_dcload(lua_State* L)
{
  void* handle;
  if (lua_gettop(L) != 1) return luaL_error(L,"wrong number of arguments");
  handle = dlLoadLibrary( lua_tostring(L,1) );
  if (!handle) return luaL_error(L,"library not found");
  lua_pushlightuserdata(L, handle);
  return 1;
}

int lua_dcfind(lua_State* L)
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

DCCallVM* g_pCallVM;

int lua_dccall(lua_State* L)
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

  // dcMode( g_pCallVM, DC_CALL_C_X86_WIN32_STD );
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

int main(int argc, char* argv[])
{
  lua_State* L;
  lua_Debug  d;
  int status;
  const char* scriptFilename = argv[1];
  
  L = lua_open();
  assert(L);
  luaL_openlibs(L);
  luaopen_base(L);
  
  g_pCallVM = dcNewCallVM(256); 
  
  lua_register(L, "dcLoad", lua_dcload);
  lua_register(L, "dcFind", lua_dcfind);
  lua_register(L, "dcCall", lua_dccall);

  status = luaL_loadfile(L, scriptFilename);
  
  if (status == 0)
  {    
    status = lua_pcall(L, 0, LUA_MULTRET, 0);
  }
  if (status)
  {    
    printf("error: %s\n", lua_tostring(L,-1));
    lua_pop(L, 1);
  }

  dcFree(g_pCallVM);
   
  lua_close(L);
}
