-- colloquy, a simple talker.
-- copyright (c) Rob Kendrick, 2002 - 2005

function ColloquyEntry(...)

if not arg or arg.n == 0 then
  config = "config.lua";
else
  config = arg[1];
end

date = safeDate; -- Override the Lua date() function with our own
                 -- This reduces calls to time()

colloquy = {
   version = "1.41.94.arwen-1",
   date = "09 May 2006",
   startTime = date("%a %b %d %H:%M:%S %Z %Y"),
   startClock = nil, --tonumber(date("%s")),
   connections = {},   -- this table is keyed on the LuaSocket handle.
                       -- .socket    = clientSocket table
                       -- .username  = name of user on this connection
                       -- .group     = current group
                       -- .observing = table of groups being observed.
                       -- .status    = connection status.  (0 not logged on, 1 logged on, 2 registered user logged on)
                       -- .site      = ip or hostname where they're connecting from.
                       -- .privs     = priviledges
                       -- .restrict  = restrictions, G = Gagged, C = Censored, B = Bot
                       -- .flags     = C - use carrage returns, c - don't use carrage returns.
                       -- .idle      = number of seconds since they last did something.
                       -- .onSince   = string saying what time they connected
                       -- .conTime   = seconds from the epoch of their connection
                       -- .termType  = terminal type - "dumb" or "colour"
                       -- .realUser  = real user name
                       -- .colours   = comma seperated colour name list
                       -- .timeWarn  = number of minutes to do a .-
                       -- .timeTick  = what time to next do a .-
                       -- .totalIdle = total number of seconds idle (when they do something, if they've been idle 5 minutes
                       --              or more, it is added to this value.
                       -- .aliases   = space seperated list of user's aliases
                       -- .invitations = space-seperated list of objects this user has an inviration to.  "@PiersCult %privatepepper" etc
                       -- .ignoring  = table of connections to ignore, or nil for no ignores
                       -- .talkBytes = number of spoken characters to people other than themselves and bots.
                       -- .via       = machine they're connecting via
                       -- .lang      = table with prefered language
   server = 0,
   logfile = nil,
   resolver = nil,
   quit = nil,
   atQuit = {},
   talkerName = "the talker",
   lockedGroups = {}, -- table of group names that are locked...
   banMasks = {}, -- list of banned host masks
};

print("+++ Colloquy " .. colloquy.version .. " [" .. colloquy.date .. "] - Copyright (c) 2002-2005 Pepperfish Ltd.");

colloquy.os = (UNAME_SYSTEM or "Unknown") .. " " .. (UNAME_MACHINE or "");

print("+++ Reading configuration from " .. config);

dofile(config)

write("+++ Initializing: ");

secs = getSecs();
colloquy.startClock = secs;

-- fill in some defaults...
do
  local d = function(i, v) if (not colloquy[i]) then colloquy[i] = v end end;
  d("base", "")
  d("port", 1234);
  d("ip", "127.0.0.1");
  d("botPort", nil);
  d("botIP", nil);
  d("metaPort", nil);
  d("metaIP", nil);
  d("metaPassword", "proxy");
  d("metaOK", "127.0.0.1");
  d("welcome", colloquy.base .. "data/misc/welcome");
  d("users", colloquy.base .. "data/users");
  d("help", colloquy.base .. "data/help/");
  d("birthday", colloquy.base .. "data/misc/birthday");
  d("motd", colloquy.base .. "data/misc/motd");
  d("resolverIP", "127.0.0.1");
  d("resolverPort", 1235);
  d("email", "admin@talker.moo.com");
  d("maxIdle", 90);
  d("lists", colloquy.base .. "data/lists");
  d("listQuota", 5);
  d("listExpiry", 14);
  d("listExpirey", colloquy.listExpiry);
  d("banFile", colloquy.base .. "data/bans");
  d("talkerName", "the talker");
  d("logName", colloquy.base .. "logfile.txt");
  d("logRotate", "cp " .. colloquy.base .. "logfile.txt " .. colloquy.base .. "logfile.%Y%m%d.txt");
  d("daytime", "0800-1800");
  d("language", "en-gb");
  d("langs", "data/langs/");
  d("smtpserver", "localhost");
  d("inspectors", nil);
end;

dataSent = 0;
dataRead = 0;

if (colloquy.maxIdle == nil or colloquy.maxIdle < 1) then
   colloquy.maxIdle = 90;
end;

-- make sure we can resolve things before we chroot
toip "www.pepperfish.net"
tohostname "62.197.40.9"

if colloquy.chroot and colloquy.becomeUser and colloquy.becomeGroup then
  drop(colloquy.chroot, colloquy.becomeUser, colloquy.becomeGroup);
end

write("users"); flush();
loadUsers(colloquy.users);
write(". "); flush();

write("bindings"); flush();
colloquy.server, err = bind(colloquy.ip, colloquy.port);
if (err ~= nil) then
   log("Unable to bind server - " .. err);
   print("\n+++ Failed to bind to " .. colloquy.ip .. ":" .. colloquy.port .. " because " .. err);
   exit(1);
end;
colloquy.server:timeout(0, "b");

if (colloquy.botIP and colloquy.botPort) then
  colloquy.botServer, err = bind(colloquy.botIP, colloquy.botPort);
  if (err ~= nil) then
    log("Unable to bind bot server - " .. err);
    print("\n+++ Failed to bind to " .. colloquy.botIP .. ":" .. colloquy.botPort .. " because " .. err);
    exit(1);
  end;
  colloquy.botServer:timeout(0, "b");
end;

if (colloquy.metaIP and colloquy.metaPort) then
  colloquy.metaServer, err = bind(colloquy.metaIP, colloquy.metaPort);
  if (err ~= nil) then
    log("Unable to bind meta server - " .. err);
    print("\n+++ Failed to bind to " .. colloquy.botIP .. ":" .. colloquy.botPort .. " because " .. err);
    exit(1);
  end;
  colloquy.metaServer:timeout(0, "b");
end;
write(". "); flush();

write("lists"); flush();
loadLists(colloquy.lists);
write(". "); flush();

write("bans"); flush();
loadBans(colloquy.banFile);
write(". "); flush();

write("swears"); flush();
if colloquy.swears then
  loadSwearWords(colloquy.swears)
end
write(". "); flush();

secs = getSecs();

write("bots"); flush();
-- let's try firing up the bots and such
if colloquy.exec then
  foreachi(colloquy.exec, function(i, v)
                            if(pfork() == 0) then
                              -- lposix doesn't provide a way of creating
                              -- signal handlers, so we can't reap these
                              -- processes.  So we fudge and create a new
                              -- process tree.
                              psetsid()
                              call(pexec, v)
                            end
                          end)
end

write(". "); flush();

write("resolver"); flush();
if not colloquy.noFork then
  -- if you can't fork, you'll have to run the resolver from somewhere else (like the !Run file
  -- under RISC OS)
  colloquy.resolverPID = pfork()
  if (colloquy.resolverPID == 0) then
    Resolver()
  end
end

select({}, {}, 2); -- give resolver a couple of seconds to start - the connection waits a while too,
                   -- but it spins until it can connect.

colloquy.resolver = clientSocket:new(colloquy.resolverIP, colloquy.resolverPort);
write("(", colloquy.resolverPID, "). "); flush();

write("\n");

colloquy.logfile = openfile(colloquy.logName, "a");

log "Talker started.";

print("+++ Main server bound to " .. colloquy.ip .. ":" .. colloquy.port .. ".");
if (colloquy.botServer) then
  print("+++ Bot server bound to ".. colloquy.botIP .. ":" .. colloquy.botPort .. ".");
end;
if (colloquy.metaServer) then
  print("+++ Meta server bound to " .. colloquy.metaIP .. ":" .. colloquy.metaPort .. ".");
 end;

print("+++ Talker started OK.");
lastHousekeep = 0;

if colloquy.detach then
  if pfork() == 0 then
    pclose(0)
    pclose(1)
    pclose(2)
    print = log
  else
    print("+++ Detached.")
    exit(0)
  end
end

repeat
  selectery();
until colloquy.quit ~= nil and empty(colloquy.connections) ~= nil;

if (colloquy.lists) then
  print("+++ Saving list data to " .. colloquy.lists);
  saveLists();
end;

print("+++ Saving user data to " .. colloquy.users);
saveUsers(colloquy.users);

log("Talker stopped.");
print("+++ Colloquy stopped.");

exit(0);

end;
