/* lua smart pointers - version 0.2 (C only version) */
/* (C) 2010 Daniel Adler */

#include "lua.h"
#include "lauxlib.h"

#define LUA_SMARTPTR_LIBNAME "smartptr"
#define LUA_SMARTPTR_TNAME   "SmartPtr"

/*
** lua smart pointer
**
** DESCRIPTION
** the smart pointer wraps lightuserdata (lua's object type for carrying raw pointer values)
** into a userdata structure where it also references a finalizer function, which will be called
** with the lightuserdata (not the userdata!) as an argument.
** 
** 
** LUA INTERFACE
** smartptr = newsmartptr(lightuserdata, function)
** setfinalizer(smartptr, function)
** lightuserdata = tolightuserdata(integer)
**
*/
 
typedef struct 
{
  const void* pointer;
  int   finalizer; /* lua reference */
} lua_SmartPtr;

/*
** constructs a SmartPtr userdata lua object.
**
** smartptr.new( pointer, finalizer )
**
** @param pointer
** @param finalizer function ( to be called with pointer ) or nil
** @return SmartPtr userdata object
*/

int lua_smartptr_new(lua_State *L)
{
  const void   *ptr;
  int           ref; 
  lua_SmartPtr *sptr; 
  
  if (lua_gettop(L) != 2)
    luaL_error(L, "argument mismatch, usage:\n\tnewsmartptr( lightuserdata [, finalizer] )");
 
  ptr  = lua_topointer(L, 1);
  luaL_argcheck(L, lua_isfunction(L, 2), 2, "must be a finalizer function");
  
  ref = luaL_ref(L, LUA_REGISTRYINDEX);

  sptr = (lua_SmartPtr*) lua_newuserdata(L, sizeof(lua_SmartPtr) );
  
  sptr->pointer   = ptr;
  sptr->finalizer = ref;
  
  luaL_getmetatable(L, LUA_SMARTPTR_TNAME);
  lua_setmetatable(L, -2);
  
  return 1;
}

/*
** update finalizer value on SmartPtr object
**
** smartptr.setfinalizer(smartptr, newfinalizer)
**
** @param smartptr object
** @param newfinalizer function or nil
*/ 

int lua_smartptr_setfinalizer(lua_State *L)
{
  lua_SmartPtr* sptr = (lua_SmartPtr*) luaL_checkudata(L, 1, LUA_SMARTPTR_TNAME);
  if (lua_isnil(L, 2)) sptr->finalizer = LUA_REFNIL;
  lua_rawseti(L, LUA_REGISTRYINDEX, sptr->finalizer);
  return 0;
}

/*
** call finalizer (internal through __gc event)
**
*/

int lua_smartptr_callfinalizer(lua_State *L)
{
  lua_SmartPtr* sptr = (lua_SmartPtr*) lua_topointer(L,1);
  int r = sptr->finalizer;
  if (r != LUA_REFNIL) {
    lua_rawgeti(L, LUA_REGISTRYINDEX, r);
    lua_pushlightuserdata(L, (void*) sptr->pointer);
    lua_call(L, 1, 0);
    luaL_unref(L, LUA_REGISTRYINDEX, r);
  }
}

/*
** get pointer value
**
** lua_smartptr_get(smartptr)
**
** @return lightuserdata
**
*/

int lua_smartptr_get(lua_State *L)
{
  lua_SmartPtr* sptr = (lua_SmartPtr*) lua_topointer(L,1);
  lua_pushlightuserdata(L, (void*) sptr->pointer);
  return 1;
}

/*
** lua c function tolightuserdata(integer)
**
** @return lightuserdata 
**
*/

int lua_tolightuserdata(lua_State *L)
{
  lua_Number number = lua_tonumber(L, 1);
  lua_pushlightuserdata(L,  (void*) ( (unsigned long) number ) );
  return 1;
}

void lua_smartptr_installmetatable(lua_State *L)
{
  if ( luaL_newmetatable(L,LUA_SMARTPTR_TNAME) ) {
    lua_pushliteral(L, "__gc");
    lua_pushcfunction(L, lua_smartptr_callfinalizer);
    lua_settable(L, -3);
    lua_pushliteral(L, "__call");
    lua_pushcfunction(L, lua_smartptr_get);
    lua_settable(L, -3);
    lua_pop(L,1);
  }
}
  
static const struct luaL_Reg luareg_smartptr[] = 
{
  { "new", lua_smartptr_new },
  { "setfinalizer", lua_smartptr_setfinalizer },
  { "tolightuserdata", lua_tolightuserdata },
  { NULL, NULL }
};

LUALIB_API int luaopen_smartptr(lua_State *L)
{
  lua_smartptr_installmetatable(L);
  luaL_register(L, LUA_SMARTPTR_LIBNAME, luareg_smartptr);
  return 0;
}

