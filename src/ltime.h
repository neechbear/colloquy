/* a simple lua interface for fetching the UNIX time
 * it uses the process's alarm() to update the time, so
 * it's not especially accurate or nice, but it does
 * for our purposes, and it means we don't have to
 * faff around updating it all the time,
 */

#ifndef _header_ltime
#define _header_ltime

#include <lua.h>

void ltime_register(lua_State *L);

#endif
