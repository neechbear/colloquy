#include <unistd.h>
#include <sys/types.h>
#include <pwd.h>
#include <grp.h>
#include <errno.h>
#include <lua.h>

#include <stdio.h>

static int drop(lua_State *L, const char* root, const char* user, const char* group) {
  const int am_root = ((geteuid() ==0) || (getuid() == 0)) ? 1 : 0;

  struct passwd *u;
  struct group *g;

  if (!am_root) {
    /* generate error about not being root */
    lua_error(L, "Can't chroot when non-root");
    return 0;
  }

  errno = 0;
  u = getpwnam(user);
  if (u == NULL) {
    /* generate error about invalid user */
    lua_error(L, "Unknown user to change to");
    return 0;
  }

  errno = 0;
  g = getgrnam(group);
  if (g == NULL) {
    /* generate error about invalid group */
    lua_error(L, "Unknown group to change to");
    return 0;
  }

  chroot(root);
  chdir(root);
  seteuid(0);
  setuid(0);
  setuid(u->pw_uid);
  setgid(g->gr_gid);

  return 0;
}

static int lua_drop(lua_State *L) {
  drop(L, lua_tostring(L,1), lua_tostring(L,2), lua_tostring(L,3));
  return 0;
}

void drop_register(lua_State *L) {
  lua_pushcclosure(L, lua_drop, 0); 
  lua_setglobal(L, "drop");
}
