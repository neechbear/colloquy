commTable = {
  { pattern = "quit",         name = "Quit",         code = commandQuit,         allow = allowAll   }, 
  { pattern = "look",         name = "Look",         code = commandLook,         allow = allowConn  },
  { pattern = "shout",        name = "Shout",        code = commandShout,        allow = allowUsers },
  { pattern = "lua",          name = "Lua",          code = commandLua,          allow = allowL     },
  { pattern = "emote",        name = "Emote",        code = commandEmote,        allow = allowConn  },
  { pattern = "pemote",       name = "PEmote",       code = commandPemote,       allow = allowConn  },
  { pattern = "groups",       name = "Groups",       code = commandGroups,       allow = allowAll   },
  { pattern = "group",        name = "Group",        code = commandGroup,        allow = allowConn  },
  { pattern = "help",         name = "Help",         code = commandHelp,         allow = allowAll   },
  { pattern = "invite",       name = "Invite",       code = commandInvite,       allow = allowUsers },
  { pattern = "evict",        name = "Evict",        code = commandEvict,        allow = allowUsers },
  { pattern = "join",         name = "Join",         code = commandJoin,         allow = allowConn  },
  { pattern = "gname",        name = "GName",        code = commandGName,        allow = allowUsers },
  { pattern = "info",         name = "Info",         code = commandInfo,         allow = allowAll   },
  { pattern = "stats",        name = "Stats",        code = commandStats,        allow = allowAll   },
  { pattern = "set",          name = "Set",          code = commandSet,          allow = allowAll   },
  { pattern = "password",     name = "Password",     code = commandPassword,     allow = allowUsers },
  { pattern = "examine",      name = "Examine",      code = commandExamine,      allow = allowAll   },
  { pattern = "request",      name = "Request",      code = commandRequest,      allow = allowUsers },
  { pattern = "time",         name = "Time",         code = commandTime,         allow = allowAll   },
  { pattern = "date",         name = "Date",         code = commandTime,         allow = allowAll   },
  { pattern = "who",          name = "Who",          code = commandWho,          allow = allowAll   },
  { pattern = "gwho",         name = "GWho",         code = commandWho,          allow = allowAll   },
  { pattern = "lwho",         name = "LWho",         code = commandLWho,         allow = allowAll   },
  { pattern = "idlers",       name = "Idlers",       code = commandIdlers,       allow = allowAll   },
  { pattern = "nameself",     name = "NameSelf",     code = commandNameself,     allow = allowUsers },
  { pattern = "login",        name = "Login",        code = commandLogin,        allow = allowConn  },
  { pattern = "mark",         name = "Mark",         code = commandMark,         allow = allowConn  },
  { pattern = "xyzzy",        name = nil,            code = commandXyzzy,        allow = allowConn  },
  { pattern = "comments",     name = "Comments",     code = commandComments,     allow = allowAll   },
  { pattern = "comment",      name = "Comment",      code = commandComment,      allow = allowUsers },
  { pattern = "idle",         name = "Idle",         code = commandIdle,         allow = allowConn  },
  { pattern = "wake",         name = "Wake",         code = commandWake,         allow = allowUsers },
  { pattern = "lists",        name = "Lists",        code = commandLists,        allow = allowAll   },
  { pattern = "list",         name = "List",         code = commandList,         allow = allowUsers },
  { pattern = "motd",         name = "MOTD",         code = commandMOTD,         allow = allowAll   },
  { pattern = "ignore",       name = "Ignore",       code = commandIgnore,       allow = allowConn  },
  { pattern = "unignore",     name = "Unignore",     code = commandUnignore,     allow = allowConn  },
  { pattern = "whoami",       name = "WhoAmI",       code = commandWhoAmI,       allow = allowUsers },
  { pattern = "query",        name = "Query",        code = commandQuery,        allow = allowConn  },
  { pattern = "remote",       name = "REmote",       code = function(c, l, p)
                                                       p = gsub(p, "^%s+", "");
                                                       if (strsub(p, 1, 1) == "%") then
                                                         commandListEmote(c, l, strsub(p, 2));
                                                       else
                                                         commandRemote(c, l, p);
                                                       end;
                                                     end,                        allow = allowConn  }, 
  { pattern = "tell",         name = "Tell",        code = function(c, l, p)
                                                       p = gsub(p, "^%s+", "");
                                                       if (strsub(p, 1, 1) == "%") then
                                                         commandListTell(c, l, strsub(p, 2));
                                                       else
                                                        commandTell(c, l, p);
                                                       end;
                                                     end,                        allow = allowConn  },
  { pattern = "spy",          name = "Spy",          code = commandSpy,          allow = allowS     },
  { pattern = "inspect",      name = "Inspect",      code = commandInspect,      allow = allowS     },
  { pattern = "alert",        name = "Alert",        code = commandAlert,        allow = allowA     },
  { pattern = "closedown",    name = "Closedown",    code = commandClosedown,    allow = allowC     },
  { pattern = "force",        name = "Force",        code = commandForce,        allow = allowF     },
  { pattern = "savedata",     name = "SaveData",     code = commandSaveData,     allow = allowM     },
  { pattern = "newuser",      name = "NewUser",      code = commandNewUser,      allow = allowU     },
  { pattern = "deleteuser",   name = "DeleteUser",   code = commandDeleteUser,   allow = allowU     },
  { pattern = "userinfo",     name = "UserInfo",     code = commandUserInfo,     allow = allowU     },
  { pattern = "name",         name = "Name",         code = commandName,         allow = allowN     },
  { pattern = "warn",         name = "Warn",         code = commandWarn,         allow = allowW     },
  { pattern = "kick",         name = "Kick",         code = commandKick,         allow = allowK     },
  { pattern = "invis",        name = "Invis",        code = commandInvis,        allow = allowI     },
  { pattern = "vis",          name = "Vis",          code = commandVis,          allow = allowI     },
  { pattern = "gag",          name = "Gag",          code = commandGag,          allow = allowG     },
  { pattern = "ungag",        name = "Ungag",        code = commandUngag,        allow = allowG     },
  { pattern = "censor",       name = "Censor",       code = commandCensor,       allow = allowM     },
  { pattern = "uncensor",     name = "Uncensor",     code = commandUncensor,     allow = allowM     },
  { pattern = "banuser",      name = "BanUser",      code = commandBanUser,      allow = allowB     },
  { pattern = "unbanuser",    name = "UnbanUser",    code = commandUnbanUser,    allow = allowB     },
  { pattern = "ban",          name = "Ban",          code = commandBan,          allow = allowB     },
  { pattern = "unban",        name = "Unban",        code = commandUnban,        allow = allowB     },
  { pattern = "locktalker",   name = "LockTalker",   code = commandLockTalker,   allow = allowB     },
  { pattern = "unlocktalker", name = "UnlockTalker", code = commandUnlockTalker, allow = allowB     },
  { pattern = "showlog",      name = "ShowLog",      code = commandShowLog,      allow = allowM     },
  { pattern = "bot",          name = "Bot",          code = commandBot,          allow = allowM     },
  { pattern = "unbot",        name = "Unbot",        code = commandUnbot,        allow = allowM     },
  { pattern = "bots",         name = "Bots",         code = commandBots,         allow = allowAll   },
  { pattern = "lock",         name = "Lock",         code = commandLock,         allow = allowUsers },
  { pattern = "unlock",       name = "Unlock",       code = commandUnlock,       allow = allowUsers },
  { pattern = "laston",       name = "LastOn",       code = commandLaston,       allow = allowAll   },
  { pattern = "guest",        name = "Guest",        code = commandGuest,        allow = allowM     },
  { pattern = "helpuser",     name = "HelpUser",     code = commandHelpUser,     allow = allowH     },
  { pattern = "observe",      name = "Observe",      code = commandObserve,      allow = allowO     },
  { pattern = "disregard",    name = "Disregard",    code = commandDisregard,    allow = allowO     },
  { pattern = "swap",         name = "Swap",         code = commandSwap,         allow = allowAll   },
  { pattern = "-",            name = nil,            code = commandMark,         allow = allowConn  },
};

function parseInput(connection, string)
  local conn = colloquy.connections[connection];
  local matches = {};
  local lstring = strlen(string);
  string = gsub(string, "[%c\n]", "") -- remove control characters
  lastInput = string;

  if (lastConnection == conn) then
    -- the user really typed this - it's not automatic or a .force
    dataRead = dataRead + lstring;
    if ((secs - conn.idle) >= (5 * 60) and not conn.veryIdle) then
      -- this is the first time they've said something for 5 or more minutes - add it to their
      -- total idle time.
      conn.totalIdle = conn.totalIdle + (secs - conn.idle);
    end;
    if (conn.inspectors) then
      for i, v in conn.inspectors do
        if (type(v) == "table") then
          sendGM(v, S_DONE, "cinspectSend", conn.username, string);
        end
      end
    end
  end;

  if (conn.status == 0 and strsub(string, 1, 1) ~= ".") then
    -- they've not logged on yet, and this isn't a .command, so try to log them on.
    userLogon(connection, string);
  else
    -- first of all, let's find out what type of utterance this is...
    local t;
    local utterType = strsub(string, 1, 1);
    if (utterType == "!") then
      string = ".shout " .. strsub(string, 2, -1);
      utterType = ".";
    elseif (utterType == ">") then
      string, t = gsub(string, "^%>[%>%%]", "%.tell %%");
      if (t == 0) then
        string, t = gsub(string, "^%>", "%.tell ");
      end;
      if (t > 0) then
        utterType = ".";
      end;
    elseif (utterType == "<") then
      string, t = gsub(string, "^%<%<", "%.remote %% ");
      if (t == 0) then
        string, t = gsub(string, "^%<", "%.remote ");
      end;
      if (t > 0) then
        utterType = ".";
      end;
    elseif (utterType == ";" or utterType == ":") then
      string, t = gsub(string, "^[%;%:]([^%;%:])", ".emote %1");
      if (t == 0) then
        string, t = gsub(string, "^[%;%:][%;%:]", ".pemote ");
      end;
      if (t > 0) then
        utterType = ".";
      end;
    elseif (utterType == "." and strsub(string, 2, 2) == "." and conn.status > 0) then
      string = "'" .. string;
      utterType = "";
    end;
       
    local completeMatch;

    if (utterType == ".") then
      -- we've got ourselves a .command!
      -- check for strip and apply it if need be
      if (strfind(colloquy.connections[connection].flags, "D", 1, 1)) then
        string = gsub(string, "^(%S+) +", "%1 ");
      end;

      local p = split(string);
      local c = strlower(strsub(p[1], 2, -1));
      p = strsub(string, strlen(p[1]) + 2);
      local i, v, ca;
      lastInput = string;
      for i, v in commTable do
        if (strfind(v.pattern, c, 1, 1) == 1) then
          if (c == v.pattern) then
            completeMatch = v;
          else
            tinsert(matches, v);
          end
        end
      end
 
      if (not (matches.n) or matches.n == 0) and not completeMatch then
        send(format("Unknown command '.%s'", c), conn, S_ERROR);
        return nil;
      elseif not completeMatch then
        if matches.n > 1 then
          local ematches = ""
         for i, v in matches do
            if type(v) == "table" and v.name and v.name ~= "" then
               ematches = format("%s.%s, ", ematches, v.name)
            end
          end
          ematches = strsub(ematches, 1, -3) .. "."
          send(format(".%s is ambiguous - matches %s", c, ematches), conn, S_ERROR);
          return nil;
        end
      end
    
      local v = completeMatch or matches[1];
      if (lastConnection == conn and conn.veryIdle and v.pattern ~= "idle") then
        -- they've unidled!
        local birthday = ".";
        if (users[conn.realUser] ~= nil and users[conn.realUser].birthday ~= nil) then
          if (date("%m-%d") == strsub(users[conn.realUser].birthday, 6, -1)) then
            birthday = " - BIRTHDAY!";
          end;
        end;
        local listeners = idleListeners()

        sendTo(conn.username .. " returns from idling" .. birthday, listeners, S_IDLE);
        conn.idleReason = nil;
        conn.totalIdle = conn.totalIdle + conn.veryIdle;
        conn.veryIdle = nil;
      end;

      if (v.allow(connection)) then
        call(v.code, { connection, string, p or "" }, "x", HandleError);
        ca = 1;
      else
        send("You don't have sufficent privilege to do that.", conn, S_ERROR);
      end;
    else
      if (lastConnection == conn and conn.veryIdle) then
        -- they've unidled!
        local birthday = ".";
        if (users[conn.realUser] ~= nil and users[conn.realUser].birthday ~= nil) then
          if (date("%m-%d") == strsub(users[conn.realUser].birthday, 6, -1)) then
            birthday = " - BIRTHDAY!";
          end;
        end;
        local listeners = idleListeners()
        sendTo(conn.username .. " returns from idling" .. birthday, listeners, S_IDLE)
        conn.idleReason = nil;
        conn.totalIdle = conn.totalIdle + conn.veryIdle;
        conn.veryIdle = nil;
      end;
      commandSay(connection, string, string);
    end;
  end;

  if (conn.flags ~= nil and strfind(conn.flags, "P", 1, 1)) then
     local p = createPrompt(conn);
     conn.socket:send(p);
     dataSent = dataSent + strlen(p);
  end;

  conn.idle = secs;

end;
