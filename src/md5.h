/**
*  $Id: md5.h,v 1.1 2000/11/09 19:19:59 roberto Exp $
*  Cryptographic module for Lua.
*  @author  Roberto Ierusalimschy
*/


#ifndef md5_h
#define md5_h

#include <lua.h>


#define HASHSIZE       16

void md5 (const char *message, long len, char *output);
void md5lib_open (lua_State *L);


#endif
