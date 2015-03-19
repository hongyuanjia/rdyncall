/* intutils lua library to support various types such as i64 and u64 */
/* critical to dyncall: needed to interact with C systems using long long */

#include "lua.hpp"
#include <cstdlib> 
#include <cstdio>

typedef long long          i64;
typedef unsigned long long u64;

template<typename T> const char* get_typename();

template<> inline const char* get_typename<u64>() { return "u64"; }
template<> inline const char* get_typename<i64>() { return "i64"; }

template<typename T> inline void lua_push(lua_State *L, T x)
{
  T *ptr = (T*) lua_newuserdata(L, sizeof(T));
  * ptr = x;
  luaL_getmetatable(L, get_typename<T>() );
  lua_setmetatable(L, -2);
}

template<typename T> int tostring(lua_State *L);

template<> int tostring<u64>(lua_State *L)
{
  char buf[1024];
  u64 v = * (u64*) lua_topointer(L, 1);
  sprintf(buf, "%016llx", v);
  lua_pushstring(L, buf);
  return 1;
}

template<> int tostring<i64>(lua_State *L)
{
  char buf[1024];
  i64 v = * (i64*) lua_topointer(L, 1);
  sprintf(buf, "%016llx", v);
  lua_pushstring(L, buf);
  return 1;
}

template<typename T>
struct lua_ops
{
  template<typename OP>
  static int binop(lua_State *L)
  {
    T op1;
    switch( lua_type(L, 1) ) {
      case LUA_TNUMBER: op1 = (T) lua_tonumber(L, 1); break;
      case LUA_TUSERDATA: op1 = * (T*) lua_touserdata(L, 1); break;
      default: luaL_error(L, "invalid left-hand side operand");
    }
    T op2;
    switch( lua_type(L, 2) ) {
      case LUA_TNUMBER: op2 = (T) lua_tonumber(L, 2); break;
      case LUA_TUSERDATA: op2 = * (T*) lua_touserdata(L, 2); break;
      default: luaL_error(L, "invalid right-hand side operand");
    }
    lua_push(L, OP(op1,op2) );
  }
  static T   add1(T op1, T op2) { return op1 + op2 ; }
  static int add(lua_State *L)
  {
    T op1;
    switch( lua_type(L, 1) ) {
      case LUA_TNUMBER: op1 = (T) lua_tonumber(L, 1); break;
      case LUA_TUSERDATA: op1 = * (T*) lua_touserdata(L, 1); break;
      default: luaL_error(L, "invalid left-hand side operand");
    }
    T op2;
    switch( lua_type(L, 2) ) {
      case LUA_TNUMBER: op2 = (T) lua_tonumber(L, 2); break;
      case LUA_TUSERDATA: op2 = * (T*) lua_touserdata(L, 2); break;
      default: luaL_error(L, "invalid right-hand side operand");
    }
    lua_push(L, op1 + op2);
    return 1;
  }
  static int sub(lua_State *L)
  {
    T op1 = * (T*) lua_topointer(L, 1);
    T op2 = * (T*) lua_topointer(L, 2);
    lua_push(L, op1 - op2);
    return 1;
  }
};
#define OPS(X) lua_ops<X>
template<typename T>
void register_type(lua_State *L, const char *tname)
{
  luaL_newmetatable(L, tname);
  const char* names[] = {
    "__add", "__sub", "__tostring" // , "__mul", "__div", "__mod", "__unm", "__eq", "__lt"
  };
  lua_CFunction funs[] = {
     OPS(T)::add, OPS(T)::sub, tostring<T> // ,  T::mul,  T::div,  T::mod,  T::unm,  T::eq,  T::lt 
  };
  size_t n = sizeof(names)/sizeof(const char*);
  for (int i = 0; i < n ; ++i ) {
    lua_pushstring(L, names[i]);
    lua_pushcfunction(L, funs[i]);
    lua_settable(L, -3);
  }
}

// conversion utilities: l_to*

template<typename T> T to_string(const char* s);

int l_u64(lua_State *L)
{
  switch( lua_type(L, 1) ) {
    case LUA_TNIL: lua_push(L, (u64) 0 ); break;
    case LUA_TNUMBER: lua_push(L, (u64) lua_tonumber(L, 1) ); break;
    case LUA_TBOOLEAN: lua_push(L, (u64) lua_toboolean(L,1) ); break;
    case LUA_TLIGHTUSERDATA: lua_push(L, (u64) lua_topointer(L, 1) ); break;
    case LUA_TSTRING: 
    {
      const char* ptr = lua_tostring(L, 1);
      int base = 10;
      if ( ptr[0] == '0' && ptr[1] == 'x' ) { 
        base = 16; 
        ptr += 2; 
      }
      lua_push(L, (u64) strtoull( lua_tostring(L, 1), NULL, base ) ); 
      break;
    }
    case LUA_TTABLE:
    case LUA_TFUNCTION:
    case LUA_TUSERDATA: 
    case LUA_TTHREAD:
      return 0;
  }
  return 1;
}

int l_i64(lua_State *L)
{
  switch( lua_type(L, 1) ) {
    case LUA_TNIL: lua_push(L, (i64) 0 ); break;
    case LUA_TNUMBER: lua_push(L, (i64) lua_tonumber(L, 1) ); break;
    case LUA_TBOOLEAN: lua_push(L, (i64) lua_toboolean(L,1) ); break;
    case LUA_TLIGHTUSERDATA: lua_push(L, (i64) lua_topointer(L, 1) ); break;
    case LUA_TSTRING: 
    {
      const char* ptr = lua_tostring(L, 1);
      int base = 10;
      if ( ptr[0] == '0' && ptr[1] == 'x' ) { 
        base = 16; 
        ptr += 2; 
      }
      lua_push(L, (i64) strtoll( lua_tostring(L, 1), NULL, base ) ); 
      break;
    }
    case LUA_TTABLE:
    case LUA_TFUNCTION:
    case LUA_TUSERDATA: 
    case LUA_TTHREAD:
      return 0;
  }
  return 1;
}

extern "C" int luaopen_intutils(lua_State *L)
{
  static luaL_Reg intutils[] = {
    { "u64", l_u64 },
    { "i64", l_i64 },
    { NULL, NULL }
  };
  register_type<u64>(L, "u64");
  register_type<i64>(L, "i64");
  luaL_register(L, "intutils", intutils);
  return 0;
}
