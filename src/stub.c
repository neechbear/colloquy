#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "lua.h"
#include "luadebug.h"
#include "lualib.h"
#include "luasocket.h"
#include "md5.h"
#include "ltime.h"
#include "dirent.h"
#include "drop.h"

#ifdef COLLOQUY_ZLIB
#include <zlib.h>
#endif

static lua_State *L = NULL;
extern void wrap_register(lua_State*);
extern void luaopen_posix (lua_State *L);

static void startLibs( ) {
  lua_baselibopen(L);
  lua_iolibopen(L);
  lua_strlibopen(L);
  lua_mathlibopen(L);
  lua_dblibopen(L);
  lua_socketlibopen(L);
  md5lib_open(L);
  wrap_register(L);
  ltime_register(L);
  luaopen_posix(L);
  drop_register(L);
}

int
main( int argc, char** argv ) {
  int i;

  L = lua_open( 0 );
  startLibs( );

  lua_newtable( L );
  for( i = 0; argv[i]; i++ ) {
    lua_pushnumber( L, i );
    lua_pushstring( L, argv[i] );
    lua_settable( L, -3 );
  }
  lua_pushstring( L, "n" );
  lua_pushnumber( L, i - 1 );
  lua_settable( L, -3 );
  lua_setglobal( L, "arg" );

#include LUABYTECODE

  lua_dostring( L, "ColloquyEntry()" );
  return 0;
}
