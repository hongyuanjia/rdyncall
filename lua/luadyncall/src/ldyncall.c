#include <stddef.h>
#include "lua.h"
#include "lauxlib.h"
#include "dyncall.h"
#include "dyncall_signature.h"

DCCallVM* g_pCallVM = NULL;

/**
 * lua syntax:
 *
 * dodyncall( address, signature, ... )
 *
 **/

int lua_dodyncall(lua_State *L)
{
  void* f;
  const char *callsignature, *s;
  int top = lua_gettop(L);
  if (top < 2) return luaL_error(L,"missing arguments #1 'addr' and #2 'signature'");
  
  if ( lua_iscfunction(L,1) )           f = (void*) lua_tocfunction(L, 1);    
  else if (lua_islightuserdata(L,1) )   f =         lua_touserdata(L, 1);
  else if (lua_isnumber(L,1) )          f = (void*) lua_tointeger(L, 1);
  else return luaL_argerror(L, 1, "expected a cfunction, userdata or number");

  s = callsignature = luaL_checkstring(L,2);

  /* parse mode */
 
  // dcMode( g_pCallVM, DC_CALL_C_DEFAULT );
  dcReset( g_pCallVM );

  char ch;
  int p = 3;
  int ptr = 0;
  while ( (ch = *s++) != DC_SIGCHAR_ENDARG)
  {
    if (p > top) return luaL_error(L,"need more arguments (call signature is '%s')", callsignature );
    if (ptr == 0) {
      switch(ch)
      {
        case '*': 
          ptr++; 
          continue;
        case DC_SIGCHAR_BOOL:
          dcArgBool(g_pCallVM, (DCbool) luaL_checkint(L, p) );
          break;
        case DC_SIGCHAR_CHAR:
        case DC_SIGCHAR_UCHAR:
          dcArgChar(g_pCallVM, (DCchar) luaL_checkint(L, p) );
          break;
        case DC_SIGCHAR_SHORT:
        case DC_SIGCHAR_USHORT:
          dcArgShort(g_pCallVM, (DCshort) luaL_checkint(L, p) );
          break;
        case DC_SIGCHAR_INT:
        case DC_SIGCHAR_UINT:
          dcArgInt(g_pCallVM, (DCint) luaL_checknumber(L, p) );
          break;
        case DC_SIGCHAR_LONG:
        case DC_SIGCHAR_ULONG:
          dcArgLong(g_pCallVM, (DClong) luaL_checknumber(L, p) );
          break;
        case DC_SIGCHAR_LONGLONG:
        case DC_SIGCHAR_ULONGLONG:
          dcArgLongLong(g_pCallVM, (DClonglong) luaL_checknumber(L, p) );
          break;
        case DC_SIGCHAR_FLOAT:
          dcArgFloat(g_pCallVM, (DCfloat) luaL_checknumber(L, p) );
          break; 
        case DC_SIGCHAR_DOUBLE:
          dcArgDouble(g_pCallVM, (DCdouble) luaL_checknumber(L, p) );
          break;
        case DC_SIGCHAR_POINTER:
          dcArgPointer(g_pCallVM, (DCpointer) lua_topointer(L, p) );
          break;
        case DC_SIGCHAR_STRING:
          dcArgPointer(g_pCallVM, (DCpointer) lua_tostring(L, p) );
          break; 
        default:
          return luaL_error(L, "invalid typecode '%c' in call signature '%s'", s[0], callsignature);
      }
    } else { /* pointer types */
      switch(ch)
      {
        case '*':
          ptr++; 
          continue;
        case '<':
          {
            const char* begin = s;
            while ( (ch = *s++) != '>' ) ;
            const char* end = s;
            switch( lua_type(L,p) ) {
              case LUA_TNUMBER:
                dcArgPointer(g_pCallVM, (DCpointer) (ptrdiff_t) lua_tonumber(L, p) );
                break;
              case LUA_TTABLE:
                lua_pushvalue(L, p);        // 1
                lua_pushliteral(L, "pointer");
                lua_gettable(L, -2);        // 2
                if ( !lua_isuserdata(L, -1) ) 
                  luaL_error(L, "pointer type mismatch at argument #%d", p);
                dcArgPointer(g_pCallVM, (DCpointer) lua_touserdata(L, -1) );
                lua_pop(L, 2);
                break;
              case LUA_TLIGHTUSERDATA:
              case LUA_TUSERDATA:
                dcArgPointer(g_pCallVM, (DCpointer) lua_topointer(L, p) );
                break;    
              default:
                luaL_error(L, "pointer type mismatch at argument #%d", p);
                break;
            } 
          }
          break;
        case DC_SIGCHAR_BOOL:
        case DC_SIGCHAR_CHAR:
          if ( lua_isstring(L, p) ) {
            dcArgPointer(g_pCallVM, (DCpointer) lua_tostring(L, p) );
            break;
          }
        case DC_SIGCHAR_UCHAR:
        case DC_SIGCHAR_SHORT:
        case DC_SIGCHAR_USHORT:
        case DC_SIGCHAR_INT:
        case DC_SIGCHAR_UINT:
        case DC_SIGCHAR_LONG:
        case DC_SIGCHAR_ULONG:
        case DC_SIGCHAR_LONGLONG:
        case DC_SIGCHAR_ULONGLONG:
        case DC_SIGCHAR_FLOAT:
        case DC_SIGCHAR_DOUBLE:
        case DC_SIGCHAR_POINTER:
        case DC_SIGCHAR_STRING:
        case DC_SIGCHAR_VOID:
          if ( lua_istable(L, p) ) {
            lua_pushvalue(L, p);        // 1
            lua_pushliteral(L, "pointer");
            lua_gettable(L, -2);        // 2
            if ( !lua_isuserdata(L, -1) ) 
              luaL_error(L, "pointer type mismatch at argument #%d", p);
            dcArgPointer(g_pCallVM, (DCpointer) lua_touserdata(L, -1) );
            lua_pop(L, 2);
          } else 
            dcArgPointer(g_pCallVM, (DCpointer) lua_topointer(L, p) );
          ptr = 0;
          break;
        default:
          return luaL_error(L, "invalid signature");
      }
    }
    
    ++p;
  }

  if (top >= p) 
    luaL_error(L,"too many arguments for given signature, expected %d but received %d" , p-3, top-2 );

  switch(*s++)
  {
    case DC_SIGCHAR_VOID:
      dcCallVoid(g_pCallVM, f);
      return 0;
    case DC_SIGCHAR_BOOL:   
      lua_pushboolean( L, (int) dcCallBool(g_pCallVM, f) ); 
      break;
    case DC_SIGCHAR_CHAR:
    case DC_SIGCHAR_UCHAR:
      lua_pushnumber( L, (lua_Number) ( dcCallChar(g_pCallVM,f) ) );
      break;
    case DC_SIGCHAR_SHORT:
    case DC_SIGCHAR_USHORT:
      lua_pushnumber( L, (lua_Number)( dcCallShort(g_pCallVM, f) ) );
      break;
    case DC_SIGCHAR_INT:
    case DC_SIGCHAR_UINT:
      lua_pushnumber( L, (lua_Number)( dcCallInt(g_pCallVM, f) ) );
      break;
    case DC_SIGCHAR_LONG:
    case DC_SIGCHAR_ULONG:
      lua_pushnumber( L, (lua_Number)( dcCallLong(g_pCallVM, f) ) );
      break;
    case DC_SIGCHAR_LONGLONG:
    case DC_SIGCHAR_ULONGLONG:
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
    case '*':
      switch(*s++) {
        case DC_SIGCHAR_UCHAR:
        case DC_SIGCHAR_CHAR:
          lua_pushstring( L, dcCallPointer(g_pCallVM, f) );
          break;
        default:
          lua_pushlightuserdata( L, dcCallPointer(g_pCallVM, f) );
          break;
      }
      break;
    default:
      return luaL_error(L, "invalid signature");
  }
  return 1;
}

int topointer(lua_State* L)
{
  lua_pushlightuserdata(L, (void*) (ptrdiff_t) luaL_checkint(L, 1) );
  return 1;
}

static const struct luaL_Reg luareg_dyncall[] = 
{
  { "dodyncall", lua_dodyncall },
  { "topointer", topointer },
  { NULL, NULL }
/*
  { "NewCallVM", lua_dcNewCallVM },
  { "Mode", lua_dcMode },
  { "Reset", lua_dcReset },
  { "ArgBool", lua_dcBool },
  { "ArgChar", lua_dcChar },
  { "ArgShort", lua_dcShort },
  { "ArgInt", lua_dcInt },
  { "ArgLong", lua_dcLong },
  { "ArgLongLong", lua_dcLongLong },
*/
};

void lua_setmetainfo(lua_State *L)
{
  lua_pushliteral(L, "_COPYRIGHT");
  lua_pushliteral(L, "Copyright (C) 2010 Dyncall Project");
  lua_settable(L, -3);
  lua_pushliteral(L, "_DESCRIPTION");
  lua_pushliteral(L, "lua bindings for dyncall libraries");
  lua_settable(L, -3);
  lua_pushliteral(L, "_VERSION");
  lua_pushliteral(L, "0.1");
  lua_settable(L, -3);
}

LUA_API int luaopen_ldyncall(lua_State* L)
{
  g_pCallVM = dcNewCallVM(4096);
  luaL_register(L, "ldyncall", luareg_dyncall); 
  lua_setmetainfo(L);
  return 1;
}

