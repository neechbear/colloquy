/* a simple lua interface for fetching the UNIX time
 * it uses the process's alarm() to update the time, so
 * it's not especially accurate or nice, but it does
 * for our purposes, and it means we don't have to
 * faff around updating it all the time,
 */

#include <stdlib.h>
#include <lua.h>
#include <lauxlib.h>
#include <sys/time.h>
#include <time.h>
#include <unistd.h>

static time_t ourTime = -1;

#ifdef SIGNALTIME
#include <signal.h>

static void signalHandler(int signo) {
  if (signo == SIGALRM) {
    ourTime = time(NULL);
    alarm(2);
  }
}

#endif

static int lua_epoch_time(lua_State *L) {
#ifndef SIGNALTIME
   if( lua_gettop(L) != 0 ) ourTime = -1;
   else if( ourTime == -1 ) time(&ourTime);
#endif
   lua_settop(L, 0);
   lua_pushnumber(L, ourTime);
   return 1;
}

/* Mostly cribbed from io_date in liolib.c of Lua4.0 */
static int ltime_date(lua_State *L) {
  char b[256];
  const char *s = luaL_opt_string(L, 1, "%c");
  struct tm *stm;
#ifndef SIGNALTIME
  if (ourTime == -1) time(&ourTime);
#endif
  stm = localtime(&ourTime);
  if (strftime(b, sizeof(b), s, stm))
    lua_pushstring(L, b);
  else
    lua_error(L, "invalid `date' format");
  return 1;
}

void ltime_register(lua_State *L) {
#ifdef SIGNALTIME
  struct sigaction sa_new;

  sa_new.sa_handler = signalHandler;
  sigemptyset(&sa_new.sa_mask);
  sigaddset(&sa_new.sa_mask, SIGALRM);
  sa_new.sa_flags = 0;

  sigaction(SIGALRM, &sa_new, 0);
  
  signalHandler(SIGALRM);

  alarm(2);
#endif
  lua_pushcclosure(L, lua_epoch_time, 0);
  lua_setglobal(L, "getSecs");
  lua_pushcclosure(L, ltime_date, 0);
  lua_setglobal(L, "safeDate" );
}

