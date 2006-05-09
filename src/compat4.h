/* compat4.h -- compatibility hack for Lua 4.0 */

#ifdef luaL_openl

#include <stdarg.h>

#define lua_Number		double
#define lua_isnone(L,n)		(lua_type(L,n) == LUA_TNONE)
#define lua_pushboolean		lua_pushnumber
#define lua_toboolean		!!lua_tonumber
#define lua_isnoneornil(L, n)	(lua_isnone(L,n) || lua_isnil(L,n))
#define lua_replace(l,n)
#define lua_upvalueindex(n)	(-(n))
#define lua_pushlightuserdata	lua_pushuserdata
#define lua_pushliteral(L, s)	\
	lua_pushlstring(L, "" s, (sizeof(s)/sizeof(char))-1)

#define luaL_error		lua_error
#define luaL_checkint		luaL_check_int
#define luaL_checknumber	luaL_check_number
#define luaL_checkstring	luaL_check_string
#define luaL_checklstring	luaL_check_lstr
#define luaL_optint		luaL_opt_int
#define luaL_optnumber		luaL_opt_number
#define luaL_optstring		luaL_opt_string
#define luaL_openlib(L,name,x,n)	\
	(luaL_openlib)(L,x,(sizeof(x)/sizeof(x[0]))-1); lua_getglobals(L)

typedef struct luaL_reg luaL_reg;

static const char *lua_pushfstring (lua_State *L, const char *fmt, ...)
{
 static char buf[MYBUFSIZ]; 
 va_list argp;
 va_start(argp, fmt);
 vsprintf(buf,fmt,argp);
 va_end(argp);
 lua_pushstring(L,buf);
 return buf;
}

static int luaL_typerror (lua_State *L, int narg, const char *tname) {
  const char *msg = lua_pushfstring(L, "%s expected, got %s",
                                    tname, lua_typename(L, lua_type(L,narg)));
  luaL_argerror(L, narg, msg);
  return 0;
}

#endif

