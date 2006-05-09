-- command table for colloquy

function commandQuit(connection, line, message)
   local conn = colloquy.connections[connection];
   if (message == "") then
      message = "";
   else
      message = "(" .. message .. ")";
   end;
   sendGM(conn, S_QUIT, "cquitBye");
   disconnectUser(connection, message);
end;

function commandShout(connection, line, message)
   local tmp;
   local conn = colloquy.connections[connection];

   if (not message or message == "") then
     sendGM(conn, S_ERROR, "cshoutUsage");
     return nil;
   end;

   if (strfind(conn.restrict, "G", 1, 1) or strfind(conn.restrict, "B", 1, 1)) then
      sendGM(conn, S_ERROR, "cshoutGagged");
      return nil;
   end;

   if (message ~= "") then
    if (strfind(conn.restrict, "C", 1, 1)) then
      message = censor(message);
    end;

    if (strsub(message, 1, 1) == ":" or strsub(message, 1, 1) == ";") then
      tmp = "! " .. conn.username;
      if (strsub(message, 2, 2) == ":") then
        if (strlower(strsub(conn.username, -1, -1)) == "s") then
          tmp = tmp .. "' " .. strsub(message, 3, -1);
        else
          tmp = tmp .. "'s " .. strsub(message, 3, -1);
        end;
      else
        tmp = tmp .. " " .. strsub(message, 2, -1);
      end;
    else
      tmp = conn.username;
      tmp = tmp .. strrep(" ", 11);
      tmp = strsub(tmp, 1, 12) .. "!" .. message;
    end;
    conn.talkBytes = conn.talkBytes + strlen(message);
    sendToAll(tmp, S_SHOUT);
  end;
end;

function commandSay(connection, line, message, esc)
   local conn = colloquy.connections[connection];
 
   if (message ~= "") then
      if (strsub(message, 1, 1) == "'") then
        -- ah, they want to escape this...
        message = strsub(message, 2);
      end;

      if (not esc and conn.query) then
        local type = strsub(conn.query.format, 1, 1);
        if (type == ">") then
          -- turn this into a whisper..
          local params = format("%s %s", conn.query.data.username, message);
          commandTell(connection, ".tell " .. params, params);
          return nil;
        elseif (type == "@") then
          -- turn into another whisper...
          local params = format("@%s %s", conn.query.data, message);
          commandTell(connection, ".tell " .. params, params);
          return nil;
        elseif (type == "%") then
          -- turn into a list whisper...
          local params = format("%s %s", conn.query.data.listname, message);
          commandListTell(connection, ">>" .. params, params);
          return nil;
        end;
      end;  
      if (strfind(conn.restrict, "C", 1, 1)) then
        message = censor(message);
      end;
      conn.talkBytes = conn.talkBytes + strlen(message);
      sendToGroup(format("%-11.11s :%s", conn.username, message), conn.group, S_TALK);
      sendToObservers(format("%-11.11s @%s {@%s}", conn.username, message, conn.group), conn.group, S_TALK);
   end;
end;

function commandLook(connection, line, params)
   local t, i, v;
   local conn = colloquy.connections[connection];
   local sorted = {};
   local p = split(params or "");
   local g = conn.group;
   local lsort = function(a, b) return (strlower(a) < strlower(b)) end;
   
   if (p[1]) then
     local err;
     g, err = groupByName(p[1]);
     if (not g) then
       send(err, conn, S_ERROR);
       return nil;
     end;
   end;

   local lg = strlower(g);

   for i, v in colloquy.connections do
     if (strlower(v.group) == lg and not v.veryIdle) then
       local m = v.username;

       if (v.privs and strfind(v.privs, "M")) then
         m = m .. "(M)";
       elseif (v.privs and v.privs ~= "") then
         m = m .. "(P)";
       elseif (v.status > 1) then
         m = m .. "(U)";
       end;

       if (not v.invis) then
         tinsert(sorted, m);
       end;
     end;
   end;

   if (getn(sorted) > 0) then
     sendGM(conn, S_LOOKHDR, "clookActive", g);
     sort(sorted, lsort);
     local rl = columns(sorted, (conn.width - 19) / 14, 13);
     for i = 1, getn(rl) do
       send("  " .. rl[i], conn, S_LOOK);
     end;
   end;
    
   sorted = {}
   
   for i, v in colloquy.connections do
     if (strlower(v.group) == lg and v.veryIdle) then
       local m = v.username;

       if (v.privs and strfind(v.privs, "M")) then
         m = m .. "(M)";
       elseif (v.privs and v.privs ~= "") then
         m = m .. "(P)";
       elseif (v.status > 1) then
         m = m .. "(U)";
       end;

       if (not v.invis) then
         tinsert(sorted, m);
       end;
     end;
   end;

   if (getn(sorted) > 0) then
     sendGM(conn, S_LOOKHDR, "clookIdle", g);
     sort(sorted, lsort);
     local rl = columns(sorted, (conn.width - 19) / 14, 13);
     for i = 1, getn(rl) do
       send("  " .. rl[i], conn, S_LOOK);
     end;
   end;
end;

function commandEmote(connection, line, message, esc)
   local tmp;
   local conn = colloquy.connections[connection];

   if (message == "") then
     sendGM(conn, S_ERROR, "cemoteUsage");
     return nil;
   end;

   if (message ~= "") then
    if (not esc and conn.query) then
      local type = strsub(conn.query.format, 1, 1);
      if (type == ">") then
        -- turn this into a whisper..
        local params = format("%s %s", conn.query.data.username, message);
        commandRemote(connection, "<" .. params, params);
        return nil;
      elseif (type == "@") then
        -- turn into another whisper...
        local params = format("@%s %s", conn.query.data, message);
        commandRemote(connection, "<" .. params, params);
        return nil;
      elseif (type == "%") then
        -- turn into a list whisper...
        local params = format("%s %s", conn.query.data.listname, message);
        commandListEmote(connection, "<<" .. params, params);
        return nil;
      end;
     end;  
     
     if (strfind(conn.restrict, "C", 1, 1)) then
       message = censor(message);
     end;
     tmp = conn.username;
     if (strfind(punctuation, strsub(message, 1, 1), 1, 1)) then
       tmp = tmp .. message;
     else
       tmp = tmp .. " " .. message;
     end;
     conn.talkBytes = conn.talkBytes + strlen(message);

     sendToGroup(tmp, conn.group, S_EMOTE);
     sendToObservers(format("@ %s {@%s}", tmp, conn.group), conn.group, S_EMOTE);
   end;
end;

function commandPemote(connection, line, message, esc)
  local tmp;
  local conn = colloquy.connections[connection];

  if (message == "") then
    sendGM(conn, S_ERROR, "cpemoteUsage");
    return nil;
  else
    if (not esc and conn.query) then
      local type = strsub(conn.query.format, 1, 1);
      local s = "'s ";
      if (strlower(strsub(conn.username, -1, -1)) == "s") then
        s = "' ";
      end;

      if (type == ">") then
        -- turn this into a remote...
        local params = format("%s %s%s", conn.query.data.username, s, message);
        commandRemote(connection, ".remote " .. params, params);
        return nil;
      elseif (type == "@") then
        -- turn this into a group whisper...
        local params = format("@%s %s%s", conn.query.data, s, message);
        commandRemote(connection, ".remote " .. params, params);
        return nil;
      elseif (type == "%") then
        -- turn this into a list whisper...
        local params = format("%s %s%s", conn.query.data.listname, s, message);
        commandListEmote(connection, ".remote " .. params, params);
        return nil;
      end;
    end;

    if (strfind(conn.restrict, "C", 1, 1)) then
      message = censor(message);
    end;

    tmp = conn.username;
    if (strlower(strsub(tmp, -1, -1))) == "s" then
      tmp = tmp .. "' ";
    else
      tmp = tmp .. "'s ";
    end;
    tmp = tmp .. message;
    conn.talkBytes = conn.talkBytes + strlen(message);
    sendToGroup(tmp, conn.group, S_EMOTE);
    sendToObservers(format("@ %s {@%s}", tmp, conn.group), conn.group, S_EMOTE);
  end;
end;

function commandMark(connection, line)
   local t = date("%H:%M");
   send(strrep("-", colloquy.connections[connection].width - 4 - strlen(t) - 1) .. " " .. t, colloquy.connections[connection], S_MARK);
end;

function commandHelp(connection, line, thing)
   local t, i, v = " "; 
   local c = {};
   local conn = colloquy.connections[connection];

   if (thing == "") then
     thing = gm(conn, "chelpGeneral");
   end;

   if (thing == gm(conn, "chelpCommands")) then
      local longest = 0;

      for i, v in commTable do
        if (i ~= "n") then
          if (v.name ~= nil and v.name ~= "" and v.allow(connection)) then --t = t .. v.name .. " " end;
            tinsert(c, v.name);
            if (strlen(v.name) > longest) then
              longest = strlen(v.name);
            end;
          end;
        end;
      end;

      sort(c);
      local rl = columns(c, floor((conn.width-6 - longest) / (longest + 1)) + 1, longest)

      sendGM(conn, S_HELP, "chelpAvailable");
      for i=1,getn(rl) do
        send("  " .. rl[i], conn, S_HELP);
      end;
   else
      thing = strlower(thing);
      thing = gsub(thing, "[%.%/]", "");
      thing = gsub(thing, "%s+", " ");
      if thing == "" then
        sendGM(conn, S_ERROR, "chelpNoHelp");
        return nil;
      end;
      local ht = getHelp(conn, thing)
      if (not ht) then
        sendGM(conn, S_ERROR, "chelpNoHelp");
        return nil;
      end;
      for i = 1, ht.n do
        send(ht[i], conn, S_HELP);
      end
   end;
end;

function commandGroup(connection, line, groupname)
   local tmp;
   local conn = colloquy.connections[connection];

   if (isBot(connection)) then
     sendGM(conn, S_ERROR, "cgroupBot");
     return nil;
   end;

   if (groupname == "" or groupname == nil) then groupname = gm(conn, "PublicGroup") end;

   groupname = gsub(groupname, "[%c ]", "");
   if (strlen(groupname) > 15) then
      groupname = strsub(groupname, 1, 15);
   end;

   if (strupper(groupname) == strupper(conn.group)) then
      sendGM(conn, S_ERROR, "cgroupAlready", groupname);
      return nil;
   end;

   if (colloquy.lockedGroups[strlower(groupname)] and not checkInvitation(conn, "@" .. strlower(groupname))) then
     sendGM(conn, S_ERROR, "cgroupLocked", groupname);
     return nil;
   end;

   if (strfind(groupname, "[%s,@%%]")) then
     sendGM(conn, S_ERROR, "cgroupInvalid", groupname);
     return nil;
   end;


   local oldGroup = conn.group;

   conn.group = "";

   if (not conn.invis) then
      sendGMGroup(oldGroup, S_GROUP, "cgroupHasMoved", conn.username, groupname);
      sendGMGroup(groupname, S_GROUP, "cgroupEnters", conn.username);
      sendToObservers(format("%s moves to group '%s' from group '%s'.", conn.username, groupname, oldGroup), oldGroup, S_GROUP)
      sendToObservers(format("%s moves to group '%s' from group '%s'.", conn.username, groupname, oldGroup), groupname, S_GROUP)
   end;

   conn.group = groupname;
   checkGroupToUnlock(oldGroup);

   sendGM(conn, S_GROUP, "cgroupYouEnter", groupname);
   commandLook(connection, ".look", "");
   removeInvitation(conn, "@" .. strlower(groupname));

end;

function commandSpy(connection, line, groupname)
   local tmp;
   local conn = colloquy.connections[connection];

   if (groupname == "" or groupname == nil) then groupname = "Public" end;

   groupname = gsub(groupname, "[%c ]", "");
   if (strlen(groupname) > 15) then
      groupname = strsub(groupname, 1, 15);
   end;

   if (strupper(groupname) == strupper(conn.group)) then
      sendGM(conn, S_ERROR, "cspyAlready", groupname);
      return nil;
   end;

   local oldGroup = conn.group;
   
   conn.group = "";

   if (not conn.invis) then
      sendGMGroup(oldGroup, S_GROUP, "cspyHasMoved", conn.username, groupname);
      sendGMGroup(groupname, S_GROUP, "cspyEnters", conn.username);
   end;

   conn.group = groupname;

   log(format("S  %s[%s] spies on group %s", conn.username, conn.realUser, groupname));
   
   sendGM(conn, S_GROUP, "cspyYouEnter", groupname);
   commandLook(connection, ".look");
   removeInvitation(conn, "@" .. strlower(groupname));
end;

function commandInspect(connection, line, param)
  local conn = colloquy.connections[connection];
  local allowed = nil
   
  if(not(strfind(conn.privs or "", "L", 1, 1))) then
    sendGM(conn, S_ERROR, "NoPriv");
  end;

  if(type(colloquy.inspectors) == "table") then
    for i, v in colloquy.inspectors do
      if(strlower(v) == strlower(conn.realUser)) then
        allowed = i
        break;
      end;
    end;
  end;

  if(not allowed) then
    sendGM(conn, S_ERROR, "NoPriv");
    return nil;
  end;

  if(param == "" or param == nil) then
    local inspecting = "";
    local t = 0;

    for i, v in colloquy.connections do
      if v.inspectors then
        for j, k in v.inspectors do
          if k == conn then
            inspecting = inspecting .. v.username .. " ";
            t = t + 1;
          end
        end
      end
    end

    if(t == 0) then inspecting = "Nobody" end;
    sendGM(conn, S_DONE, "cinspectCurrent", inspecting);

    return nil;
  end;

  local user = userByName(param);
  
  if(user == nil) then
    sendGM(conn, S_ERROR, "cinspectNoUser", param);
    return nil;
  elseif(type(user) == "string") then
    send(user, conn, S_ERROR);
    return nil;
  elseif(strfind(user.privs or "", "Z", 1, 1)) then
    sendGM(conn, S_ERROR, "Immune", user.username);
    return nil;
  end;

  user.inspectors = user.inspectors or {};
  
  local already = nil

  for i, v in user.inspectors do
    if v == conn then
      already = i
      break;
    end
  end

  if already then
    log(format("SI- %s[%s] stops inspecting %s[%s]\n", conn.username, conn.realUser, user.username, user.realUser));
    tremove(user.inspectors, already);
    if(user.inspectors.n == 0) then
      user.inspectors = nil;
    end;
    sendGM(conn, S_DONE, "cinspectStop", user.username);
    return nil;
  end

  log(format("SI %s[%s] inspects %s[%s]\n", conn.username, conn.realUser, user.username, user.realUser));
  tinsert(user.inspectors, conn);
  sendGM(conn, S_DONE, "cinspectStart", user.username);
end

function commandJoin(connection, line, username)
   local tmp, i, v;
   local conn = colloquy.connections[connection];
   
   if (username == "") then
      sendGM(conn, S_ERROR, "cjoinUsage");
      return nil;
   end;

   username = gsub(username, "[%c ]", "");
   if (strlen(username) > 10) then
      username = strsub(username, 1, 10);
   end;

   local expansion = userByName(username);
   if (expansion == nil) then
      sendGM(conn, S_ERROR, "cjoinNoUser", username);
      return nil;
   elseif (type(expansion) == "string") then
      send(expansion, conn, S_ERROR);
      return nil;
   end;

   commandGroup(connection, ".group " .. expansion.group, expansion.group);

end;

function commandUnknown(connection, line, command)
   send("Unknown command.", colloquy.connections[connection], S_ERROR);
end;

function commandGroups(connection, line)
   local groups = {};
   local i, v, r;
   local conn = colloquy.connections[connection];
   local alreadyExists = function(name, table)
     local i, v, n;
   
     n = strlower(name);
     for i, v in table do
       if (strlower(i) == n) then
         return v;
       end;
    end;
  end;
   
  for i, v in colloquy.connections do
    local t = alreadyExists(v.group, groups);
    if (t == nil and not v.invis and not (v.restrict and strfind(v.restrict, "B", 1, 1)) and v.group ~= "") then
      groups[v.group] = {};
      t = groups[v.group];
    end;
    
    local m;
    if (v.group ~= "") then
      m = v.username;
      if (not v.invis and not (v.restrict and strfind(v.restrict, "B", 1, 1))) then tinsert(t, m); end;
    end;
  end;

  sendGM(conn, S_GROUPSHDR, "cgroupCurrent");

  for i, v in groups do
    local j, g;
    r = " " .. i; 
    if (colloquy.lockedGroups[strlower(i)]) then
      r = r .. " (L)";
    end;
    r = r .. strrep(" ", 21);
    r = (strsub(r, 1, 21));
    for j, g in v do
      if (j ~= "n") then
      r = r .. g .. " "
    end;
   end;
   send(r, conn, S_GROUPS);
 end;
end;

function commandGName(connection, line, new)
   local tmp, i, v;
   local conn = colloquy.connections[connection];
   
   if (new == "") then
      sendGM(conn, S_ERROR, "cgnameUsage");
      return nil;
   end;

   if (isBot(connection)) then
     sendGM(conn, S_ERROR, "cgnameBot");
     return nil;
   end;

   if (strlower(conn.group) == "public" and not allowM(connection)) then
      sendGM(conn, S_ERROR, "cgnamePublic");
      return nil;
   end;

   if (strfind(new, "[%s,@%%]")) then
     sendGM(conn, S_ERROR, "cgnameInvalid");
     return nil;
   end;

   new = gsub(new, "[%c ]", "");
   if (strlen(new) > 15) then
      new = strsub(new, 1, 15);
   end;

   tmp = strlower(new);
   local old = conn.group;

   -- check if this groupname is already in use...
   local merging = nil;
   for i, v in colloquy.connections do
      if (i ~= "n") then
        if (strlower(v.group) == tmp and not allowM(connection)) then
          sendGM(conn, S_ERROR, "cgnameAlready");
          return nil;
        elseif (strlower(v.group) == tmp and allowM(connection)) then
          merging = v.group;
        end;
      end;
   end;

   tmp = strlower(conn.group);

   for i, v in colloquy.connections do
      if (i ~= "n") then
        if (strlower(v.group) == tmp) then
           v.group = new;
        end;
      end;
   end;

   sendToObservers(format("%s changed the name of group '%s' to '%s'.", conn.username, old, new), tmp, S_GNAME);
   observeUpdate(tmp, new);

   if (merging) then
     sendGMGroup(new, S_GNAME, "cgnameMerge", conn.username, old, merging);
   else
     sendGMGroup(new, S_GNAME, "cgnameChange", conn.username, new);
   end;

   log(format("GN %s[%s] changes group %s name to %s", conn.username, conn.realUser, old, new));
   updateInvitations("@" .. old, "@" .. new)
   if (colloquy.lockedGroups[old]) then
     colloquy.lockedGroups[old] = nil;
     colloquy.lockedGroups[new] = 1;
   end;

end;

function commandInfo(connection, line, user)
  local i, v, t;
  local conn = colloquy.connections[connection];
  local guest, master;
  
  if conn.status < 2 then
    guest = 1
  end;

  master = allowM(conn.socket.socket);
   
  t = " ";

  if (user == "") then
    -- list all the users...
    local u = {}
    for i, v in users do
      if (i ~= "n") then
        tinsert(u, i);
      end;
    end;

    sort(u);

    sendGM(conn, S_INFOHDR, "cinfoAvailable");
    local l = {};

    for i = 1, getn(u) do
      tinsert(l, u[i]);
    end;

    local r = columns(l, ((conn.width-6)/18), 17);

    for i=1, getn(r) do
      send("  " .. r[i], conn, S_INFOLIST);
    end;
  else
    -- info one just one user...
    i = strlower(user);
    if (users[i] == nil) then
      sendGM(conn, S_ERROR, "cinfoNoUser", user);
      return nil;
    end;
      
    -- let's work out what lists they are on...
    local sublists, st = "", {};
    do
      local o, v;
      local j, k;
      for o, v in lists do
        if (type(v) == "table" and not strfind(v.flags or "", "A", 1, 1)) then
          for j, k in v.members do
            if (type(k) == "string" and k == i) then
              tinsert(st, o);
            end;
          end;
        end;
      end;
      sort(st);
      if (getn(st) > 0) then
        for o=1,getn(st) do
          sublists = sublists .. lists[st[o]].listname .. " ";
        end;
      end;
    end;
  
    local field = function(n, v, conn, removeStar)
      if removeStar then
        v = gsub(v, "^%*", "")
        v = gsub(v, "^%!", "")
      end
      send(format("%-14.14s %s", n .. ":", v), conn, S_INFO);
    end
    
    local showable = function(v)
      if not v then return nil end;
      if %guest and strfind(v, "^[%*]") then return nil end
      if not %master and strfind(v, "^[%!]") then return nil end
      return 1;
    end

    local f = function(f)
      return gm(%conn, "cinfo" .. f);
    end;

    local ud = users[i];

    field(f "User", i, conn);
    if showable(ud.name) then field(f "RealName", ud.name, conn, 1) end;
    if ud.banned then field(f "Banned", ud.banned, conn) end;
    if ud.aliases then field(f "Aliases", ud.aliases, conn) end;
    if allowM(conn.socket.socket) and ud.authenticator then
      field(f "Authenticator", ud.authenticator, conn);
    end
    if ud.privs then field(f "Privs", ud.privs, conn) end;
    if showable(ud.sex) then field(f "Sex", ud.sex, conn, 1) end;
    if showable(ud.birthday) then
      field(f "Birthday", ud.birthday, conn, 1);
      field(f "Age", calculateAge(ud.birthday), conn);
    end
    if showable(ud.email) then field(f "Email", ud.email, conn, 1) end;
    if showable(ud.homepage) then field(f "Homepage", ud.homepage, conn, 1) end;
    if showable(ud.occupation) then field(f "Occupation", ud.occupation, conn, 1) end;
    if showable(ud.location) then field(f "Location", ud.location, conn, 1) end;
    if showable(ud.interests) then field(f "Interests", ud.interests, conn, 1) end;
    if showable(ud.comments) then field(f "Comments", ud.comments, conn, 1) end;
    if showable(ud.around) then field(f "NextAround", ud.around, conn, 1) end;
    if sublists ~= "" then field(f "OnLists", sublists, conn) end;
    if ud.created then field(f "Created", ud.created, conn) end;
    if ud.lastSite then field(f "LastSite", ud.lastSite, conn) end;
    if ud.lastLogon then field(f "LastLogon", ud.lastLogon, conn) end;
    if (ud.lastQuit and ud.lastQuit ~= "") then field(f "LastQuit", ud.lastQuit, conn) end;
    if ud.quitmsg and master then field(f "QuitMsg", ud.quitmsg, conn) end;
    if ud.talkBytes then field(f "TalkBytes", prettyBytes(ud.talkBytes), conn) end;
    if ud.timeon then field(f "TimeOn", timeToString(ud.timeon), conn) end;
  end;
end;

function commandStats(connection, line, user)
  local conn = colloquy.connections[connection];
  local of = format;
 
  local format = function(field, value)
    local t = gm(%conn, "cstats" .. field) .. ":" .. strrep(" ", 24);
    t = strsub(t, 1, 24);
    return t .. value;
  end;

  local averageAge = function(s)
    -- returns the average age of all users, and of connected users
    local ages, total = 0, 0
    
    if s == "conn" then
      for i, v in colloquy.connections do
        local u = users[strlower(v.realUser or "")]
        if u and u.birthday and (not strfind(u.restrict or "", "B", 1, 1)) then
         -- calculate their age, add it to 'ages' and increment 'total'
          ages = ages + tonumber(calculateAge(u.birthday))
          total = total + 1
        end
      end

      if total == 0 then total = 1 end;
      return tonumber(%of("%d", ages / total))
    elseif s == "all" then
      for i, v in users do
        if type(v) == "table" then
          if v.birthday and (not strfind(v.restrict or "", "B", 1, 1)) then
            ages = ages + tonumber(calculateAge(v.birthday))
            total = total + 1
          end
        end
      end

      if total == 0 then total = 1 end;
      return tonumber(%of("%.2f", ages / total))
    end
  end

  send(format("TalkerName", colloquy.talkerName), conn, S_STATS);
  send(format("Version", colloquy.version .. " (" .. colloquy.date .. ") (c) Rob Kendrick (" .. _VERSION .. ")"), conn, S_STATS);
  send(format("Compiled", __DATE__ .. " (" .. colloquy.os .. ")"), conn, S_STATS);
  send(format("Started", colloquy.startTime), conn, S_STATS);
  send(format("UpFor", timeToString(secs - colloquy.startClock)), conn, S_STATS);
  send(format("Daytime", colloquy.daytime), conn, S_STATS);
  send(format("MaxDayUsers", colloquy.daytimeMax or gm(conn, "cstatsNone")), conn, S_STATS);
  send(format("MaxNightUsers", colloquy.nighttimeMax or gm(conn, "cstatsNone")), conn, S_STATS);
  send(format("MaxIdle", gm(conn, "cstatsMinutes", colloquy.maxIdle)), conn, S_STATS);
  send(format("MaxGuests", colloquy.maxGuests or gm(conn, "cstatsNone")), conn, S_STATS);
  if colloquy.guestTimeout then
    send(format("GuestTimeout", gm(conn, "cstatsSeconds", colloquy.guestTimeout)), conn, S_STATS);
  else
    send(format("GuestTimeout", gm(conn, "cstatsNone")), conn, S_STATS);
  end;
  send(format("AverageAge", gm(conn, "cstatsAges", averageAge("all"), averageAge("conn"))), conn, S_STATS);
  send(format("CacheStats", of("%d/%d %s, %d %s, %d%% %s.", msgCacheSize, msgCacheMax, gm(conn, "cstatsUsed"),
                                                        msgCacheLastRemoved, gm(conn, "cstatsRemoved"),
                                                        (msgCacheHits * 100)/(msgCacheHits+msgCacheMisses), gm(conn, "cstatsHits")
                                                        )), conn, S_STATS);
  local round = function(a)
    if (strfind(a, ".", 1, 1)) then
      return strsub(a, 1, strfind(a, ".", 1, 1) + 3);
    end;
    return a;
  end;
   
  local cpuUsage = clock() / ( (secs - colloquy.startClock) / ( 60 * 60 * 24) );
  if (cpuUsage < 1 or ((secs - colloquy.startClock) / (60 * 60 * 24) < 1)) then
    cpuUsage = round(clock()) .. " seconds, ";
    send(format("ResUsage", gm(conn, "cstatsUsage1", round(clock()), tostring(gcinfo()))), conn, S_STATS);
  else
    cpuUsage = round(cpuUsage) .. " secs/day, ";
    send(format("ResUsage", gm(conn, "cstatsUsage2", round(cpuUsage), tostring(gcinfo()))), conn, S_STATS);
  end;
 
  send(format("DataSent", prettyBytes(dataSent)), conn, S_STATS);
  send(format("DataRead", prettyBytes(dataRead)), conn, S_STATS);
  send(format("Bandwidth", round(dataSent / (secs - colloquy.startClock)) .. " bytes/sec out, " .. round(dataRead / (secs - colloquy.startClock)) .. " bytes/sec in."), conn, S_STATS);
end;

function commandSet(connection, line, params)
   local i, v;
   local p = split(params);
   local conn = colloquy.connections[connection];
   if (not p[1]) then
     tmp = gm(conn, "csetOptions");
     tmp = tmp .. format("%s%s%s%s%s%s%s%s%s",
                         gm(conn, "csetOptBeep", y(strfind(conn.flags, "B", 1, 1), gm(conn, "csetOn"), gm(conn, "csetOff"))),
                         gm(conn, "csetOptCR", y(strfind(conn.flags, "C", 1, 1), gm(conn, "csetOn"), gm(conn, "csetOff"))),
                         gm(conn, "csetOptEcho", y(strfind(conn.flags, "E", 1, 1), gm(conn, "csetOn"), gm(conn, "csetOff"))),
                         gm(conn, "csetOptStrip", y(strfind(conn.flags, "D", 1, 1), gm(conn, "csetOn"), gm(conn, "csetOff"))),
                         gm(conn, "csetOptPrompts", y(strfind(conn.flags, "P", 1, 1), gm(conn, "csetOn"), gm(conn, "csetOff"))),
                         gm(conn, "csetOptShouts", y(strfind(conn.flags, "S", 1, 1), gm(conn, "csetOn"), gm(conn, "csetOff"))),
                         gm(conn, "csetOptMessages", y(strfind(conn.flags, "M", 1, 1), gm(conn, "csetOn"), gm(conn, "csetOff"))),
                         gm(conn, "csetOptLists", y(strfind(conn.flags, "L", 1, 1), gm(conn, "csetOn"), gm(conn, "csetOff"))),
                         gm(conn, "csetOptIdling", y(strfind(conn.flags, "I", 1, 1), gm(conn, "csetOn"), gm(conn, "csetOff"))));

     if (conn.status >= 2 and users[strlower(conn.realUser)].idlePrompt) then
       tmp = tmp .. gm(conn, "csetOptIdlePrompt", users[strlower(conn.realUser)].idlePrompt)
     end

     if (conn.termType == "dumb") then
       tmp = tmp .. gm(conn, "csetOptTerminal", gm(conn, "csetOptTermDumb"));
     elseif (conn.termType == "colour") then
       tmp = tmp .. gm(conn, "csetOptTerminal", gm(conn, "csetOptTermColour"));
     elseif (conn.termType == "client") then
       tmp = tmp .. gm(conn, "csetOptTerminal", gm(conn, "csetOptTermClient"));
     end;

     if (strfind(conn.flags, "W")) then
       tmp = tmp .. gm(conn, "csetOptWidth", gm(conn, "csetOptWidthAuto", conn.width + 1));
     elseif (conn.noWrap) then
       tmp = tmp .. gm(conn, "csetOptWidth", gm(conn, "csetOptWidthZero"));
     else
       tmp = tmp .. gm(conn, "csetOptWidth", gm(conn, "csetOptWidthOther", conn.width));
     end;

     tmp = tmp .. gm(conn, "csetOptLanguage", conn.lang.NAME);

     send(tmp, conn, S_DONE);

     return nil;
   end;

   for i = 1, getn(setCommands) do
     v = setCommands[i];
     if (strlower(p[1]) == v.name) then
       v.code(connection, line, params)
       return nil;
     end;
   end;

   sendGM(conn, S_ERROR, "csetUnknown", p[1]);
end;

function setLanguage(connection, line, params)
  local p = split(params);
  local conn = colloquy.connections[connection];
  
  if (p[2] == nil) then
    -- get a list of current languages
    local languages = pdir(colloquy.langs)
    languages.lf = ""
    foreachi(languages, function(i,v)
                          if strsub(v, 1, 1) == "." then return end
                          if strsub(v, -4, -1) ~= ".lua" then return end
                          %languages.lf = %languages.lf .. gsub(v, "%.lua$", "") .. " "
                        end)
    send(gm(conn, "csetlanguageUsage"), conn, S_ERROR)
    send(gm(conn, "csetlanguageAvailable", languages.lf), conn, S_ERROR);
    return nil;
  end;

  if (getlang(p[2])) then
    conn.lang = getlang(p[2]);
    send(gm(conn, "csetlanguageChanged"), conn, S_DONE);
    return nil;
  end

  send(gm(conn, "csetlanguageUnknown", p[2]), conn, S_ERROR);

end

function setStrip(connection, line, params)

  local p = split(params);
  local conn = colloquy.connections[connection];

  if (p[2] == nil) then
     sendGM(conn, S_ERROR, "csetstripUsage");
     return nil;
  end

  if (strlower(p[2]) == gm(conn, "On")) then
     conn.flags = gsub(conn.flags, "d", "D");
     if (strfind(conn.flags, "D", 1, 1) == nil) then
       conn.flags = conn.flags .. "D";
     end
     sendGM(conn, S_DONE, "csetstripOn");
  else
     conn.flags = gsub(conn.flags, "D", "d");
     sendGM(conn, S_DONE, "csetstripOff");
  end;

end;

function setEcho(connection, line, params)
  local p = split(params);
  local conn = colloquy.connections[connection];

  if (p[2] == nil) then
    sendGM(conn, S_ERROR, "csetechoUsage");
    return nil;
  end;

  if (strfind(conn.flags, "e", 1, 1) == nil and strfind(conn.flags, "E", 1, 1) == nil) then
    conn.flags = conn.flags .. "e";
  end;

  if (strlower(p[2]) == gm(conn, "On")) then
    conn.flags = gsub(conn.flags, "e", "E");
    sendGM(conn, S_DONE, "csetechoOn");
    conn.socket.echo = 1;
  else
    conn.flags = gsub(conn.flags, "E", "e");
    sendGM(conn, S_DONE, "csetechoOff");
    conn.socket.echo = nil;
  end;
end;

function setWidth(connection, line, params)
   local p = split(params);
   local conn = colloquy.connections[connection];

   if (p[2] == nil or (tonumber(p[2]) == nil) and p[2] ~= "auto") then
     sendGM(conn, S_ERROR, "csetwidthUsage");
     return nil;
   end;

   if (strlower(p[2]) == gm(conn, "csetwidthAuto")) then
     if (conn.termType == "colour") then
        -- ask the terminal to let us autonegotiate screen size
        send(gm(conn, "csetwidthDoneAuto") .. "\255\253\31", conn, S_DONE);
        conn.flags = gsub(conn.flags, "w", "W");
        conn.noWrap = nil;
     else
       sendGM(conn, S_ERROR, "csetwidthNoColour");
       return nil;
     end;
   elseif (tonumber(p[2]) < 79 and tonumber(p[2]) > 0) then
     sendGM(conn, S_ERROR, "csetwidthTooSmall");
     return nil;
   else
     conn.flags = gsub(conn.flags, "W", "w");
     if (tonumber(p[2]) == 0) then
       -- they don't want wrapping, but some functions need to know how
       -- to format tables, so set it to eight, and set the conn.noWrap
       -- flag.
       conn.width = 79;
       conn.noWrap = 1;
       sendGM(conn, S_DONE, "csetwidthDoneNone");
     else
       conn.width = p[2];
       conn.noWrap = nil;
       sendGM(conn, S_DONE, "csetwidthDone", conn.width);
     end;
   end;
end;

function setPrompts(connection, line, params)
   local p = split(params);
   local conn = colloquy.connections[connection];
   
   if (p[2] == nil) then
     sendGM(conn, S_ERROR, "csetpromptsUsage");
     return nil
   end;

   if (strfind(conn.flags, "p", 1, 1) == nil and strfind(conn.flags, "P", 1, 1) == nil) then
     conn.flags = conn.flags .. "p";
   end;

   if (strlower(p[2]) == gm(conn, "On")) then
      conn.flags = gsub(conn.flags, "p", "P");
      sendGM(conn, S_DONE, "csetpromptsOn");
   else
      conn.flags = gsub(conn.flags, "P", "p");
      sendGM(conn, S_DONE, "csetpromptsOff");
   end;
end;

function setIdlePrompt(connection, line, params)
  local p = split(params);
  local conn = colloquy.connections[connection];
  params = strsub(params, 12, -1); -- get rid of "idleprompts"

  if conn.status < 2 then
    sendGM(conn, S_ERROR, "NoPriv");
    return nil
  end

  if (p[2] == nil) then
    sendGM(conn, S_ERROR, "csetidlepromptUsage");
    return nil
  end;

  if (p[2] == "-") then
    -- they want to remove the idle prompt.
    users[strlower(conn.realUser)].idlePrompt = nil
    sendGM(conn, S_DONE, "csetidlepromptUnset");
    return nil
  end

  if (strlen(params) > 10) then
    sendGM(conn, S_ERROR, "csetidlepromptTooLong", params);
    return nil
  end

  users[strlower(conn.realUser)].idlePrompt = params
  sendGM(conn, S_DONE, "csetidlepromptSet", params);

end

function setPrivs(connection, line, params)
  local conn = colloquy.connections[connection];
   
  if (strfind(conn.privs or "", "P", 1, 1) == nil) then
    sendGM(conn, S_ERROR, "NoPriv");
    return nil;
  else
    local p = split(params);
    if (p[3] == nil or p[2] == nil) then
      sendGM(conn, S_ERROR, "csetprivsUsage");
      return nil;
    end;

    local u = strlower(p[2]);
    local i, v;
    
    for i, v in colloquy.connections do
      if (i ~= "n" and strlower(v.username) == u) then
        -- right, found the user...
        if (v.privs and strfind(v.privs, "Z", 1, 1)) then
          sendGM(conn, S_ERROR, "Immune", v.username);
          return nil;
        end;
        
        v.privs = "";
        v.status = 2;
        if (p[3] ~= "-") then
          local j, k, m;
          m = strlower(conn.realUser);
          for j, k in users do
            if (j == m) then
              local n;
              for n = 1, strlen(p[3]) do
                if (strfind(k.privs, strsub(p[3], n, n), 1, 1)) then
                  v.privs = v.privs .. strsub(p[3], n, n);
                end;
              end;
            end;
          end;
        end;
        log(format("P  %s[%s] sets %s[%s] privs to %s", conn.username, conn.realUser, v.username, v.realUser, p[3]));
        sendGM(conn, S_DONE, "csetprivsChanged", v.username, v.privs);
        return nil;
      end;
    end;
    sendGM(conn, S_ERROR, "UnknownUser", p[2]);
   end;
end;

function setTimewarn(connection, line, params)
   local conn = colloquy.connections[connection];
   
   local p = split(params);

   if (p[2] == nil) then
      sendGM(conn, S_ERROR, "csettimeUsage");
      return nil;
   end;

   local n = tonumber(p[2]);
   if (type(n) ~= "number") then
      sendGM(conn, S_ERROR, "csettimeUsage");
      return nil;
   end;

   if (n > 0 and n < 1) then n = 1 end;

   n = floor(n);

   conn.timeWarn = n;
   conn.timeTick = secs;

   if (n > 0) then
      sendGM(conn, S_DONE, "csettimeDone", n);
   else
      sendGM(conn, S_DONE, "csettimeNone");
   end;
end;

function setCR(connection, line, params)
   local p = split(params);
   local conn = colloquy.connections[connection];

   if (p[2] == nil) then
     sendGM(conn, S_ERROR, "csetcrUsage");
     return nil;
   end;

   if (strlower(p[2]) == gm(conn, "On")) then
      conn.flags = gsub(conn.flags, "c", "C");
      sendGM(conn, S_DONE, "csetcrOn");
  else
      conn.flags = gsub(conn.flags, "C", "c");
      sendGM(conn, S_DONE, "csetcrOff");
   end;
end;

function setTerm(connection, line, params)
   local p = split(params);
   local conn = colloquy.connections[connection];
   
   if (p[2] == nil) then
      sendGM(conn, S_ERROR, "csettermUsage");
      return nil;
   end;

   local t = strlower(p[2]);

   if (t == strlower(gm(conn, "csetOptTermDumb"))) then
      conn.termType = "dumb";
      sendGM(conn, S_DONE, "csettermDone", gm(conn, "csetOptTermDumb"));
   elseif (t == strlower(gm(conn, "csetOptTermColour"))) then
      conn.termType = "colour";
      sendGM(conn, S_DONE, "csettermDone", gm(conn, "csetOptTermColour"));
   elseif (t == strlower(gm(conn, "csetOptTermClient"))) then
      conn.termType = "client";
      sendGM(conn, S_DONE, "csettermDone", gm(conn, "csetOptTermClient"));
   else
     sendGM(conn, S_ERROR, "csettermUnknown", p[2]);
   end;

end;

function setColour(connection, line, params)
   local p = split(params);
   local conn = colloquy.connections[connection];
   local col = function(t)
      local f, b = getColouringName(%conn, t)
      return f .. " on " .. b
   end;
   
   if (p[2] == nil or p[3] == nil or p[4] == nil) then
     send("Current colour settings: ", conn, S_DONE);
     send(" Talk:        " .. col("talk"), conn, S_DONE);

     send(" Tell:        " .. col("tell"), conn, S_DONE);

     send(" List:        " .. col("list"), conn, S_DONE);
     
     send(" ListName:    " .. col("listname"), conn, S_DONE);

     send(" Shout:       " .. col("shout"), conn, S_DONE);

     send(" Message:     " .. col("message"), conn, S_DONE);

     send(" Nick:        " .. col("nick"), conn, S_DONE);

     send(" Me:          " .. col("me"), conn, S_DONE);
     
     send("Use .Set Colour <Type> <Foreground> <Background> to change them.", conn, S_DONE);

     return nil;
   end;

   local t = strlower(p[2]);
   local c = strlower(p[3]);
   local bc = strlower(p[4]);
   local br, brb;

   if (strsub(c, 1, 2) == "br") then
      br = 1;
      c = strsub(c, 3, -1);
   end;

   if (strsub(bc, 1, 2) == "br") then
     brb = 1;
     bc = strsub(bc, 3, -1);
   end
      
   if (not equal(t, { "talk", "tell", "list", "listname", "shout", "message", "nick", "me", "talkback", "tellback", "listback", "listnameback", "shoutback", "messageback", "nickback", "meback" })) then
      send("Unknown type.  Valid types are: talk, tell, list, listname, shout, message, nick, me.", conn, S_ERROR);
      return nil;
   end;

   if (not equal(c, { "black", "red", "green", "yellow", "blue", "magenta", "cyan", "white", "none" } )) then
      send("Unknown colour.  Valid colours are: BrBlack, BrRed, BrGreen, BrYellow, BrBlue, BrMagenta, BrCyan, BrWhite, Black, Red, Green, Yellow, Blue, Magenta, Cyan, White.",  conn, S_ERROR);
      return nil;
   end;

   if (not equal(bc, { "black", "red", "green", "yellow", "blue", "magenta", "cyan", "white", "none" } )) then
      send("Unknown colour.  Valid colours are: BrBlack, BrRed, BrGreen, BrYellow, BrBlue, BrMagenta, BrCyan, BrWhite, Black, Red, Green, Yellow, Blue, Magenta, Cyan, White.",  conn, S_ERROR);
      return nil;
   end;
   setColouring(conn, t, strlower(p[3]), strlower(p[4]));

   send("Colour changed.", conn, S_DONE);

   saveOneUser(conn.realUser);
end;

function setBeep(connection, line, params)
   local p = split(params);
   local conn = colloquy.connections[connection];

   if (p[2] == nil) then
     sendGM(conn, S_ERROR, "csetbeepUsage");
     return nil;
   end;

   if (strlower(p[2]) == gm(conn, "On")) then
      conn.flags = gsub(conn.flags, "b", "B");
      sendGM(conn, S_DONE, "csetbeepOn");
  else
      conn.flags = gsub(conn.flags, "B", "b");
      sendGM(conn, S_DONE, "csetbeepOff");
   end;

   saveOneUser(conn.realUser);
end;

function setInfo(connection, line, params)
   local p = split(params);
   local conn = colloquy.connections[connection];

   if (conn.status < 2) then
     sendGM(conn, S_ERROR, "csetinfoGuest");
     return nil;
   end;

   if (p[2] == nil) then
      sendGM(conn, S_ERROR, "csetinfoUsage");
      return nil;
   end;

   local t = strlower(p[2]);

   local f = function(a) return gm(%conn, "csetinfoF" .. a) end;

   if (not equal(t, {f"location", f"occupation", f"interests", f"comments", f"around", f"email", f"homepage"}) ) then
      sendGM(conn, S_ERROR, "csetinfoInvalid", p[2]);
      return nil;
   end;

   local u = users[strlower(conn.realUser)];
   if (not u) then
     send("Sorry, I havn't a clue who you are.", conn, S_ERROR);
     return nil;
   end;

   local v;
   if (p[3]) then
     v = strsub(line, strfind(line, p[2], 1, 1) + strlen(p[2]) + 1, -1);
   end;

   if (t == f"location") then
     u.location = v;
   elseif (t == f"occupation") then
     u.occupation = v;
   elseif (t == f"interests") then
     u.interests = v;
   elseif (t == f"comments") then
     u.comments = v;
   elseif (t == f"around") then
     u.around = v;
   elseif (t == f"email") then
     u.email = v;
   elseif (t == f"homepage") then
     u.homepage = v;
   end;
   
   saveOneUser(conn.realUser);

   if (v) then
     sendGM(conn, S_DONE, "csetinfoChanged", t, v);
   else
     sendGM(conn, S_DONE, "csetinfoUnset", t);
   end;

end;

function setHeard(connection, line, params)
  local p = split(params);
  local f = strlower(p[1]);
  local conn = colloquy.connections[connection];

  if (f == gm(conn, "csetheardShouts")) then
    if (not p[2]) then
      if (strfind(conn.flags, "S", 1, 1)) then
        sendGM(conn, S_DONE, "csetheardShoutsOn");
      else
        sendGM(conn, S_DONE, "csetheardShoutsOff");
      end;
      return nil;
    end;

    local s = strlower(p[2]);
    if (s == gm(conn, "Off")) then
      conn.flags = exchange(conn.flags, "S", "s");
      sendGM(conn, S_DONE, "csetheardShoutsOff");
    else
      conn.flags = exchange(conn.flags, "s", "S");
      sendGM(conn, S_DONE, "csetheardShoutsOn");
    end;
    return nil;
  
  elseif (f == gm(conn, "csetheardMessages")) then
    if (not p[2]) then
      if (strfind(conn.flags, "M", 1, 1)) then
        sendGM(conn, S_DONE, "csetheardMessagesOn");
      else
        sendGM(conn, S_DONE, "csetheardMessagesOff");
      end;
      return nil;
    end;
    local s = strlower(p[2]);
    if (s == gm(conn, "Off")) then
      conn.flags = exchange(conn.flags, "M", "m");
      sendGM(conn, S_DONE, "csetheardMessagesOff");
    else
      conn.flags = exchange(conn.flags, "m", "M");
      sendGM(conn, S_DONE, "csetheardMessagesOn");
    end;
    return nil;
  elseif (f == gm(conn, "csetheardLists")) then
    if (not p[2]) then
      if (strfind(conn.flags, "L", 1, 1)) then
        sendGM(conn, S_DONE, "csetheardListsOn");
      else
        sendGM(conn, S_DONE, "csetheardListsOff");
      end;
      return nil;
    end;
    local s = strlower(p[2]);
    if (s == gm(conn, "Off")) then
      conn.flags = exchange(conn.flags, "L", "l");
      sendGM(conn, S_DONE, "csetheardListsOff");
    else
      conn.flags = exchange(conn.flags, "m", "M");
      sendGM(conn, S_DONE, "csetheardListsOn");
    end;
    return nil;
  elseif (f == gm(conn, "csetheardIdling")) then
    if (not p[2]) then
      if (strfind(conn.flags, "I", 1, 1)) then
        sendGM(conn, S_DONE, "csetheardIdlingOn");
      else
        sendGM(conn, S_DONE, "csetheardIdlingOff");
      end;
      return nil;
    end;
    local s = strlower(p[2]);
    if (s == gm(conn, "Off")) then
      conn.flags = exchange(conn.flags, "I", "i");
      sendGM(conn, S_DONE, "csetheardIdlingOff");
    else
      conn.flags = exchange(conn.flags, "i", "I");
      sendGM(conn, S_DONE, "csetheardIdlingOn");
    end;
    return nil;
  end;
end;

function commandClosedown(connection, line)
    log(format("C  %s[%s] closed the talker down.", colloquy.connections[connection].username, colloquy.connections[connection].realUser));
    local i, v;

    for i, v in colloquy.connections do
      if (i ~= "n") then
        send("Talker closed down by " .. colloquy.connections[connection].username .. ".", v, S_DISCONNECT);
        disconnectUser(i, " - Closedown");
      end;
    end;
    colloquy.quit = 1;
end;

function commandForce(connection, line, thing)
   local username, command;
   local conn = colloquy.connections[connection];
   
      if (strfind(thing, " ") ~= nil) then
        username = strsub(thing, 1, strfind(thing, " ") - 1);
        command = strsub(thing, strfind(thing, " ") + 1, strlen(thing));
      else
        username, command = "", "";
      end;

      if (username == "" or command == "") then
        sendGM(conn, S_ERROR, "cforceUsage");
        return nil;
      end;

      local u, i, v = strlower(username);

      for i, v in colloquy.connections do
        if (i ~= "n") then
          if (u == strlower(v.username)) then
            if (allowZ(i)) then
              send(colloquy.connections[i].username .. " has immunity.", conn, S_ERROR);
              return nil;
            end;

            log(format("F  %s[%s] forces %s[%s]: %s", conn.username, conn.realUser, v.username, v.realUser, command));
            parseInput(i, command)
            sendGM(conn, S_DONE, "cforceDone", v.username, command);
            return nil;
          end;
        end;
      end;
      sendGM(conn, S_ERROR, "UnknownUser", username);
end;

function commandHelpUser(connection, line, thing)
  local username, command;
  local conn = colloquy.connections[connection];

  if (strfind(thing, " ") ~= nil) then
    username = strsub(thing, 1, strfind(thing, " ") - 1);
    command = strsub(thing, strfind(thing, " ") + 1, strlen(thing));
  else
    username, command = "", "";
  end

  if (username == "" or command == "") then
    sendGM(conn, S_ERROR, "chelpuserUsage");
    return nil;
  end

  local u, i, v = strlower(username);

  for i, v in colloquy.connections do
    if (i ~= "n") then
      if (u == strlower(v.username)) then
        log(format("H  %s[%s] helps %s[%s]: %s", conn.username, conn.realUser, v.username, v.realUser, command));
        parseInput(i, ".help " .. command)
        sendGM(conn, S_DONE, "chelpuserDone", v.username, command);
        return nil;
      end;
    end;
  end;
  sendGM(conn, S_ERROR, "UnknownUser", username);
end;

function commandSaveData(connection, line, file)
   if (file == "") then file = colloquy.users end;
   saveUsers(file);
   sendGM(colloquy.connections[connection], S_DONE, "csavedataDone", file);
   log(format("SD %s[%s] saves data to %s", colloquy.connections[connection].username, colloquy.connections[connection].realUser, file));
end;

function commandPassword(connection, line, params)
   local old, new, cold;
   local conn = colloquy.connections[connection];

   if (conn.status < 2) then
      sendGM(conn, S_ERROR, "cpasswordGuest");
      return nil;
   end;

   if (strfind(params, " ") ~= nil) then
      old = strsub(params, 1, strfind(params, " ") - 1);
      new = strsub(params, strfind(params, " ") + 1, strlen(params));
   else
      old, new = "", "";
   end;

   if (old == "" or new == "") then
      sendGM(conn, S_ERROR, "cpasswordUsage");
      return nil;
   end;

   local pr, message = changePassword(conn.realUser, old, new);
   if (not pr) then
     sendGM(conn, S_ERROR, "cpasswordFail");
   else
     sendGM(conn, S_DONE, "cpasswordDone");
   end;
end;

function commandLua(connection, line, command)
      log(format("L  %s[%s] executes %s", colloquy.connections[connection].username, colloquy.connections[connection].realUser, command));
      if (strsub(command, 1, 1) == "=") then
        -- they just want to view a variable
        local s = strsub(command, 2, -1);
        send(format("%s = %s", s, tostring(dostring("return " .. s))), colloquy.connections[connection], S_DONE);
      else
        dostring(command);
        sendGM(colloquy.connections[connection], S_DONE, "cluaDone", command);
      end;
end;

function commandNewUser(connection, line, params)
      local conn = colloquy.connections[connection];
      local p = split(params);
      if (p[1] == nil or p[2] == nil) then
        sendGM(conn, S_ERROR, "cnewuserUsage");
        return nil;
      end;

      if (users[strlower(p[1])]) then
        sendGM(conn, S_ERROR, "cnewuserAlready", p[1]);
        return nil;
      end;

      log(format("U  %s[%s] creates '%s' with password '%s'", colloquy.connections[connection].username, colloquy.connections[connection].realUser, p[1], p[2]));
      users[strlower(p[1])] = {
        password = crypt(strlower(p[1]) .. p[2]),
        created = date() .. " by " .. colloquy.connections[connection].username,
        flags = "",
        restrict = "",
      };
      saveOneUser(p[1]);
      sendGM(conn, S_DONE, "cnewuserDone", strlower(p[1]));
end;

function commandDeleteUser(connection, line, params)
      local p = split(params);
      local conn = colloquy.connections[connection];
      if (p[1] == nil) then
        sendGM(conn, S_ERROR, "cdeleteuserUsage");
        return nil;
      end;
      if (users[strlower(p[1])] == nil) then
        sendGM(conn, S_ERROR, "UnknownUser", p[1]);
        return nil;
      end;

      if (users[strlower(p[1])].privs ~= nil and strfind(users[strlower(p[1])].privs, "Z", 1, 1)) then
        sendGM(conn, S_ERROR, "Immune", strlower(p[1]));
        return nil;
      end;
      log(format("U  %s[%s] deletes %s", colloquy.connections[connection].username, colloquy.connections[connection].realUser, params));
      users[strlower(p[1])] = nil;
      remove(colloquy.users .. "/" .. strlower(p[1]));
      sendGM(conn, S_DONE, "cdeleteuserDone", strlower(p[1]));
end;

function commandTell(connection, line, text)
   -- new .tell command!  Can take lists of people to send a message to... for example:
   -- >bob,gavin,rick Ogg smells.
   -- <@public,-ogg thinks Ogg smells.
   -- etc...

   local p = split(text);               -- split words into a table, so we have who to whisper to as p[1]...
   local dest = {};                     -- table of connection tables that this will be sent to (for normal tells, just one, multitells, multiple.)
   local whoAdd = {};                   -- table of people to add (later intergrated into dest{})
   local whoSub = {};                   -- table of people to subtract (later intergrated into dest{})
   local who = {};                      -- table used for extracting the entries out of p[1]
   local conn = colloquy.connections[connection];
   local sep = ">"                      -- seperator to use... > for tells, ] for a tell to a group, | for a multitell.
   local tmp;
   local i, v;
   local destString = " <";              -- string that contains a pretty list of who a multitell was sent to.
   local namedGroups = "";              -- string containing a space seperated list of named lists.
    
   if (p[2] == nil and (p[1] == nil)) then
     sendGM(conn, S_ERROR, "ctellUsage");
     return nil;
   end;

   -- is this a reply, rather than a new tell?
   if (strsub(p[1], 1, 1) == "!" or strsub(p[1], 1, 1) == "|") then
     if (not conn.replyTo) then
       sendGM(conn, S_ERROR, "ctellNone");
       return nil;
     end;
     p[1] = strsub(p[1], 2, -1);
     tinsert(p, 1, conn.replyTo);
     if (strfind(conn.flags, "D", 1, 1)) then  -- is this user a dunce?
       text = conn.replyTo .. " " .. gsub(strsub(text, 2, -1), "^(%s+)", "");
     else
       text = conn.replyTo .. " " .. strsub(text, 2, -1);
     end;
     p = split(text);
   else
     -- it's not - let's check to see if the last character of p[1] is , and if it is, strip the following
     -- space, to allow ">bob, @public, -gavin Hello!"
     while (strsub(p[1], -1, -1) == ",") do
       local commapos = strfind(text, ", ", 1, 1);
       if( not commapos ) then
          sendGM(conn, S_ERROR, "cremoteUsage");
          return nil;
       end
       local notspace = strfind(text, "%S", commapos + 1);
       local lComma = strsub(text, 1, commapos);
       local rComma = strsub(text, notspace, -1);
       text = lComma .. rComma;
       p = split(text);
     end;
   end;

   if (p[2] == nil or p[1] == nil) then
     sendGM(conn, S_ERROR, "ctellUsage");
     return nil;
   end;

   -- extract the entries out of p[1] into who{}
   tmp = p[1];
   if (strfind(tmp, ",", 1, 1)) then
     -- there are multiple things here, extract them.
     -- here's a quick bodge. :)
     if (strsub(tmp, -1, -1) ~= ",") then tmp = tmp .. "," end;
     sep = "|";
     repeat
       local n = strsub(tmp, 1, strfind(tmp, ",", 1, 1) - 1);
       tinsert(who, n);
       tmp = strsub(tmp, strfind(tmp, ",", 1, 1) + 1, -1);
     until (not strfind(tmp, ",", 1, 1));
   else
     -- there aren't multiple things in this list - just do a vanilla tell.
     who[1] = tmp;
     if (strsub(tmp, 1, 1) == "@") then
       -- they only want to whisper to one group - do a group tell...
       local groupExists = nil;
       local group = strlower(strsub(tmp, 2, -1));
       local err;
       if (strlen(group) == 0) then
         -- There's no group name - this means they want to say something to their current group.
         commandSay(connection, "", strsub(text, strfind(text, " ", 1, 1) + 1, -1), "escape!");
         return nil;
       end; 
       
       group, err = groupByName(group);

       if (not group) then  -- changed from groupExists, and err
         send(err, conn, S_ERROR);
         return nil;
       end;
           
       sep = "]";
       local s = strsub(text, strfind(text, " ", 1, 1) + 1, -1)
       local message = strsub(conn.username .. strrep(" ", 11), 1, 12) .. sep .. s;
       
       sendToGroup(message, group, S_TELL);
       sendToObservers(format("%-11.11s @%s {@%s}", conn.username, s, group), group, S_TALK); 
       if not (conn.observing and conn.observing[strlower(group)]) then
         sendGM(conn, S_DONETELL, "ctellToGroup", group, strsub(text, strfind(text, " ", 1, 1) + 1, -1));
       end

       -- now update everybody in the target group's replyTo.
       for i, v in colloquy.connections do
         if (i ~= "n" and strlower(v.group) == group) then v.replyTo = conn.username end;
       end;

       return nil;
     end;
   end;
   
   -- now work through the list, inserting entries into dest{}, raising an error if something can't be done.
   for i, v in who do
     if (i ~= "n") then
       local t = whoAdd;
       if (strsub(v, 1, 1) == "-") then
         t = whoSub;
         v = strsub(v, 2, -1);
       end;
       
       if (strsub(v, 1, 1) == "@") then
         -- right, they've supplied a group name - add everybody in that group to the current table...
         local group, err = groupByName(strlower(strsub(v, 2, -1)));

         if (not group) then
           if (err == "No such group.") then err = gm(conn, "UnknownGroup", strsub(v, 2, -1)) end;
           send(err, conn, S_ERROR);
           return nil;
         end;

         -- check to see if they've already mentioned this group...
         if (strfind(namedGroups, group .. " ", 1, 1)) then
           sendGM(conn, S_ERROR, "ctellMultipleGroup", group);
           return nil;
         end;

         namedGroups = namedGroups .. group .. " ";

         if (t == whoSub) then
           destString = destString .. "-";
         end;

         destString = destString .. "@" .. group .. ", ";

         group = strlower(group);
          
         local i, v;
         for i, v in colloquy.connections do
           if (i ~= "n" and strlower(v.group) == group) then
             tinsert(t, v);
           end;
         end;
       
       else

         local expansion = userByName(v);
         if (expansion == nil) then
           sendGM(conn, S_ERROR, "ctellNoUser", v);
           return nil;
         end;

         if (type(expansion) == "string") then
           send(expansion, conn, S_ERROR);
           return nil;

         end;
         if (in(expansion, t)) then
           sendGM(conn, S_ERROR, "ctellMultipleUser", v);
           return nil;
         end;
         tinsert(t, expansion);
         if (t == whoSub) then
           destString = destString .. "-";
         end;
         destString = destString .. expansion.username .. ", ";
       end;
     end;
   end;

   dest = whoAdd;

   destString = strsub(destString, 1, -3) .. ">";

   -- now go though whoSub, and remove them from dest{}
   for i, v in whoSub do
     if (i ~= "n") then
       local where = in(v, dest);
       if (where) then
         tremove(dest, where);
       else
         sendGM(conn, S_ERROR, "ctellNoRemove", v.username);
         return nil;
       end;
     end;
   end;

   local message = strsub(conn.username .. strrep(" ", 11), 1, 12) .. sep .. strsub(text, strfind(text, " ", 1, 1) + 1, -1);
   if (sep == "|") then
     sendTo(message .. destString, dest, S_MULTITELL);
     if (not in(conn, dest)) then
       destString = gsub(destString, "^%s+", "");
       sendGM(conn, S_DONETELL, "ctellDone", destString, strsub(text, strfind(text, " ", 1, 1) + 1, -1));
     end;
     local replyTo = gsub(destString, "[ %>%<]", "");
     if (not in(conn, dest)) then
       replyTo = replyTo .. "," .. conn.username;
     end;
     for i, v in dest do
       if (i ~= "n") then v.replyTo = replyTo; end;
     end;

   elseif (sep == ">") then
     sendTo(message, dest, S_TELL);
     sendGM(conn, S_DONETELL, "ctellDone", dest[1].username,strsub(text, strfind(text, " ", 1, 1) + 1, -1));
     dest[1].replyTo = conn.username;
   end;
end;

function commandRemote(connection, line, text)
   local p = split(text);               -- split words into a table, so we have who to whisper to as p[1]...
   local dest = {};                     -- table of connection tables that this will be sent to (for normal tells, just one, multitells, multiple.)
   local whoAdd = {};                   -- table of people to add (later intergrated into dest{})
   local whoSub = {};                   -- table of people to subtract (later intergrated into dest{})
   local who = {};                      -- table used for extracting the entries out of p[1]
   local conn = colloquy.connections[connection];
   local sep = ">"                      -- seperator to use... > for tells, ] for a tell to a group, | for a multitell.
   local tmp;
   local i, v;
   local destString = " <";              -- string that contains a pretty list of who a multitell was sent to.
   local namedGroups = "";              -- string containing a space seperated list of named lists.

   if (p[2] == nil and p[1] == nil) then
     sendGM(conn, S_ERROR, "cremoteUsage");
     return nil;
   end;

   -- is this a reply, rather than a new tell?
   if (strsub(p[1], 1, 1) == "!" or strsub(p[1], 1, 1) == "|") then
     if (not conn.replyTo) then
       sendGM(conn, S_ERROR, "cremoteNone");
       return nil;
     end;
     p[1] = strsub(p[1], 2, -1);
     tinsert(p, 1, conn.replyTo);
     if (strfind(conn.flags, "D", 1, 1)) then  -- is this user a dunce?
       text = conn.replyTo .. " " .. gsub(strsub(text, 2, -1), "^(%s+)", "");
     else
       text = conn.replyTo .. " " .. strsub(text, 2, -1);
     end;
   else
     -- it's not - let's check to see if the last character of p[1] is , and if it is, strip the following
     -- space, to allow ">bob, @public, -gavin Hello!"
     while (strsub(p[1], -1, -1) == ",") do
       local commapos = strfind(text, ", ", 1, 1);
       if( not commapos ) then
         sendGM(conn, S_ERROR, "cremoteUsage");
         return nil;
       end
       local notspace = strfind(text, "%S", commapos + 1);
       local lComma = strsub(text, 1, commapos);
       local rComma = strsub(text, notspace, -1);
       text = lComma .. rComma;
       p = split(text);
     end;
   end;
   
   if (p[2] == nil) then
     sendGM(conn, S_ERROR, "cremoteUsage");
     return nil;
   end;

   -- extract the entries out of p[1] into who{}
   tmp = p[1];
   if (strfind(tmp, ",", 1, 1)) then
     -- there are multiple things here, extract them.
     -- here's a quick bodge. :)
     if (strsub(tmp, -1, -1) ~= ",") then tmp = tmp .. "," end;
     sep = "|";
     repeat
       local n = strsub(tmp, 1, strfind(tmp, ",", 1, 1) - 1);
       tinsert(who, n);
       tmp = strsub(tmp, strfind(tmp, ",", 1, 1) + 1, -1);
     until (not strfind(tmp, ",", 1, 1));
   else
     who[1] = tmp;
     if (strsub(tmp, 1, 1) == "@") then
       -- they only want to whisper to one group - do a group tell...
       local groupExists = nil;
       local group = strlower(strsub(tmp, 2, -1));
       local err;

       if (strlen(group) == 0) then
         commandEmote(connection, "", strsub(text, strfind(text, " ", 1, 1) + 1, -1), "escape!");
         return nil;
       end; 
       
       group, err = groupByName(group);

       if (not group) then
         send(err, conn, S_ERROR);
         return nil;
       end;
           
       sep = "]";
       local message = sep .. " " .. conn.username;
       local t = strsub(text, strfind(text, " ", 1, 1) + 1, -1);
       if (strfind(punctuation, strsub(t, 1, 1), 1, 1)) then
         message = message .. t;
       else
         message = message .. " " .. t;
         t = " " .. t;
       end;

       sendToGroup(message, group, S_REMOTE);
       sendToObservers(format("@%s {@%s}", strsub(message, 2, -1), group), group, S_REMOTE);
       
       if not (conn.observing and conn.observing[strlower(group)]) then
         sendGM(conn, S_DONETELL, "cremoteToGroup", group, conn.username .. t);
       end
       
       for i, v in colloquy.connections do
         if (i ~= "n" and strlower(v.group) == group) then v.replyTo = conn.username end;
       end;

       return nil;
     end;
   end;
   
   -- now work through the list, inserting entries into dest{}, raising an error if something can't be done.
   for i, v in who do
     if (i ~= "n") then
       local t = whoAdd;
       if (strsub(v, 1, 1) == "-") then
         t = whoSub;
         v = strsub(v, 2, -1);
       end;
       
       if (strsub(v, 1, 1) == "@") then
         -- right, they've supplied a group name - add everybody in that group to the current table...
         local group, err = groupByName(strlower(strsub(v, 2, -1)));

         if (not group) then
           if (err == "No such group.") then err = gm(conn, "UnknownGroup", strsub(v, 2, -1)) end;
           send(err, conn, S_ERROR);
           return nil;
         end;  

         -- check to see if they've already mentioned this group...
         if (strfind(namedGroups, group .. " ", 1, 1)) then
           sendGM(conn, S_ERROR, "cremoteMultipleGroup", group);
           return nil;
         end;

         namedGroups = namedGroups .. group .. " ";

         if (t == whoSub) then
           destString = destString .. "-";
         end;

         destString = destString .. "@" .. group .. ", ";

         group = strlower(group);

         local i, v;
         for i, v in colloquy.connections do
           if (i ~= "n" and strlower(v.group) == group) then
             tinsert(t, v);
           end;
         end;
       
       else

         local expansion = userByName(v);
         if (expansion == nil) then
           sendGM(conn, S_ERROR, "cremoteNoUser", v);
           return nil;
         end;

         if (type(expansion) == "string") then
           send(expansion, conn, S_ERROR);
           return nil;

         end;
         if (in(expansion, t)) then
           sendGM(conn, S_ERROR, "cremoteNoUser", v);
           return nil;
         end;
         tinsert(t, expansion);
         if (t == whoSub) then
           destString = destString .. "-";
         end;
         destString = destString .. expansion.username .. ", ";
       end;
     end;
   end;

   dest = whoAdd;

   destString = strsub(destString, 1, -3) .. ">";

   -- now go though whoSub, and remove them from dest{}
   for i, v in whoSub do
     if (i ~= "n") then
       local where = in(v, dest);
       if (where) then
         tremove(dest, where);
       else
         sendGM(conn, S_ERROR, "cremoteNoRemove", v.username);
         return nil;
       end;
     end;
   end;

   local message = sep .. " " .. conn.username;
   local t = strsub(text, strfind(text, " ", 1, 1) + 1, -1);
   if (strfind(punctuation, strsub(t, 1, 1), 1, 1)) then
     message = message .. t;
   else
     message = message .. " " .. t;
     t = " " .. t;
   end;
   
   if (sep == "|") then
     sendTo(message .. destString, dest, S_MULTITELL);
     if (not in(conn, dest)) then
       sendGM(conn, S_DONETELL, "cremoteDone", gsub(destString, "^%s+", ""), conn.username .. t);
     end;
     local replyTo = gsub(destString, "[ %>%<]", "");
     if (not in(conn, dest)) then
       replyTo = replyTo .. "," .. conn.username;
     end;
     for i, v in dest do
       if (i ~= "n") then v.replyTo = replyTo; end;
     end;

   elseif (sep == ">") then
     sendTo(message, dest, S_REMOTE);
     sendGM(conn, S_DONETELL, "cremoteDone", dest[1].username, conn.username .. t);
     dest[1].replyTo = conn.username;
   end;
end;

function commandUserInfo(connection, line, params)
   local conn = colloquy.connections[connection];
      local p = split(params);
      if (p[1] == nil or p[2] == nil or p[3] == nil) then
        sendGM(conn, S_ERROR, "cuserinfoUsage");
        return nil;
      end;

      local u = strlower(p[1]);
      local i, v, s, c;
      s = strsub(params, strfind(params, p[2] .. " ") + strlen(p[2]) + 1, strlen(params));
      c = strlower(p[2]);
      if (p[3] == "-") then
        s = nil;
      end;

      local f = function(n) return gm(%conn, "cuserinfoCat" .. n) end;
      local unset = gm(conn, "cuserinfoUnset");

      for i, v in users do
        if (i == u) then
          if (c == f "username") then
            if (users[strlower(p[3])]) then
              sendGM(conn, S_ERROR, "cuserinfoAlready", strlower(p[3]));
              return nil;
            end;
            users[strlower(p[3])] = v;
            users[u] = nil;
            -- now work though all the lists, changing their name over
            for i, v in lists do
              if (v.owner == u) then
                v.owner = strlower(p[3]);
              end;
              for j, k in v.members do
                if (k == u) then
                  v.members[j] = strlower(p[3]);
                  break;
                end;
              end;
            end;
            sendGM(conn, S_DONE, "cuserinfoDone", f "username", s or unset);

            saveOneUser(u);
          elseif (c == f "password") then
            v.password = nil
            v.password2 = crypt(strlower(p[1])..p[3]);
            saveOneUser(u);
            sendGM(conn, S_DONE, "cuserinfoDone", f "password", s or unset);
          elseif (c == f "name") then
            v.name = s;
            saveOneUser(u);
            sendGM(conn, S_DONE, "cuserinfoDone", f "name", s or unset);
          elseif (c == f "birthday") then
            v.birthday = s;
            saveOneUser(u);
            sendGM(conn, S_DONE, "cuserinfoDone", f "birthday", s or unset);
          elseif (c == f "location") then
            v.location = s;
            saveOneUser(u);
            sendGM(conn, S_DONE, "cuserinfoDone", f "location", s or unset);
          elseif (c == f "occupation") then
            v.occupation = s;
            saveOneUser(u);
            sendGM(conn, S_DONE, "cuserinfoDone", f "occupation", s or unset);
          elseif (c == f "interests") then
            v.interests = s;
            saveOneUser(u);
            sendGM(conn, S_DONE, "cuserinfoDone", f "interests", s or unset);
          elseif (c == f "comments") then
            v.comments = s;
            saveOneUser(u);
            sendGM(conn, S_DONE, "cuserinfoDone", f "comments", s or unset);
          elseif (c == f "around") then
            v.around = s;
            saveOneUser(u);
            sendGM(conn, S_DONE, "cuserinfoDone", f "around", s or unset);
          elseif (c == f "homepage") then
            v.homepage = s;
            saveOneUser(u);
            sendGM(conn, S_DONE, "cuserinfoDone", f "homepage", s or unset);
          elseif (c == f "email") then
            v.email = s;
            saveOneUser(u);
            sendGM(conn, S_DONE, "cuserinfoDone", f "email", s or unset);
          elseif (c == f "sex") then
            v.sex = s;
            saveOneUser(u);
            sendGM(conn, S_DONE, "cuserinfoDone", f "sex", s or unset);
          elseif (c == f "aliases") then
            v.aliases = s;
            saveOneUser(u);
            sendGM(conn, S_DONE, "cuserinfoDone", f "aliases", s or unset);
          elseif (c == f "privs") then
            -- this is a complex one -- only allow somebody to set privs they've got.
            local j;
            v.privs = "";
            if (s ~= nil) then
              for j = 1, strlen(s) do
                local k = strsub(s, j, j);
                if (strfind(colloquy.connections[connection].privs, k) ~= nil) then
                  v.privs = v.privs .. k;
                end;
              end;
            else
              v.privs = nil;
            end;
            saveOneUser(u);
            sendGM(conn, S_DONE, "cuserinfoDone", f "privs", s or unset);
          elseif (c == f "auth") then
            v.authenticator = s;
            saveOneUser(u);
            sendGM(conn, S_DONE, "cuserinfoDone", f "auth", s or unset);
          elseif (c == f "quitmsg") then
            v.quitmsg = s;
            saveOneUser(u);
            sendGM(conn, S_DONE, "cuserinfoDone", f "quitmsg", s or unset);
          else
            sendGM(conn, S_ERROR, "cuserinfoCatunknown", c);
            return nil;
          end;
          log(format("U  %s[%s] changes %s for %s to '%s'", colloquy.connections[connection].username, colloquy.connections[connection].realUser, c, i, s or "(nil)"));
          return nil;
         end;
      end;

      sendGM(conn, S_ERROR, "UnknownUser", u);
end;

function commandExamine(connection, line, user)
   local conn = colloquy.connections[connection];
   if (user == nil or user == "") then
      sendGM(conn, S_ERROR, "cexamineUsage");
      return nil;
   end;

   local expansion = userByName(user);
   if (expansion == nil) then
      sendGM(conn, S_ERROR, "UnknownUser", user);
      return nil;
   elseif (type(expansion) == "string") then
      send(expansion, colloquy.connections[connection], S_ERROR);
      return nil;
   end;
   
   local i, v, u, tmp;
   local format = function(field, value)
     local t = gm(%conn, "cexamineF" .. field) .. ":" .. strrep(" ", 15);
     t = strsub(t, 1, 15);
     return t .. value .. "";
   end;
   
   v = expansion;
   
   if (not expansion.invis) then
      
      tmp = v.username;
      if (strlower(v.username) ~= strlower(v.realUser)) then
        tmp = tmp .. gm(conn, "cexamineOnAs", v.realUser);
      end;

      send(format("User", tmp), colloquy.connections[connection], S_EXAMINE);
      
      local j, k;
      for j, k in users do
        if (j ~= "n" and j == strlower(v.realUser)) then
          if (k.name) then
            send(format("Name", k.name), colloquy.connections[connection], S_EXAMINE);
          end;
        end;
      end;


      tmp = "";
      if (v.privs ~= nil and strfind(v.privs, "M")) then
        tmp = gm(conn, "cexamineMaster", v.privs);
      elseif (v.privs ~= nil and v.privs ~= "") then
        tmp = gm(conn, "cexaminePrived", v.privs);
      elseif (v.status == 2) then
        tmp = gm(conn, "cexamineNormal");
      else
        tmp = gm(conn, "cexamineGuest");
      end;
      send(format("Status", tmp), colloquy.connections[connection], S_EXAMINE);
      
      if (v.restrict ~= nil and v.restrict ~= "") then
        local e = v.restrict;
         e = gsub(e, "G", gm(conn, "cexamineGagged"));
         e = gsub(e, "C", gm(conn, "cexamineCensored"));
         e = gsub(e, "B", gm(conn, "cexamineBot"));
         send(format("Restrictions", e), colloquy.connections[connection], S_EXAMINE);
      end;
      send(format("Group", v.group), colloquy.connections[connection], S_EXAMINE);
      if (colloquy.connections[connection].privs and strfind(colloquy.connections[connection].privs, "M", 1, 1) and v.invitations) then 
        local t, j, k = "";
        for j, k in v.invitations do
          t = t .. j .. " ";
        end; 
        send(format("Invitations", t), colloquy.connections[connection], S_EXAMINE)
      end;
      if (v.pausedLists) then
        send(format("PausedLists", v.pausedLists), colloquy.connections[connection], S_EXAMINE);
      end;
      send(format("Site", v.site), colloquy.connections[connection], S_EXAMINE);
      if (v.via) then send(format("Via", v.via), colloquy.connections[connection], S_EXAMINE); end;
      send(format("OnSince", v.onSince), colloquy.connections[connection], S_EXAMINE);
      send(format("OnFor", timeToString(floor(secs - v.conTime))), colloquy.connections[connection], S_EXAMINE);
      send(format("TalkBytes", prettyBytes(v.talkBytes or 0)), colloquy.connections[connection], S_EXAMINE);
      send(format("IdleFor", timeToString(floor(secs - v.idle))), colloquy.connections[connection], S_EXAMINE);
      if (v.idleReason) then
        send(format("Idle", v.idleReason), colloquy.connections[connection], S_EXAMINE);
      end;
      send(format("TotalIdle", timeToString(floor(v.totalIdle))), colloquy.connections[connection], S_EXAMINE);
   end;
end;

function commandIdle(connection, line, params)
  local conn = colloquy.connections[connection];
  local tmp;
  local listeners = idleListeners()

  if (params ~= nil and params ~= "") then
    tmp =  " (" .. params .. ")";
    conn.idleReason = params;
  else
    tmp = "";
    conn.idleReason = "";
  end;

  if (conn.veryIdle) then
    sendGMList(listeners, S_IDLE, "cidleReidle", conn.username, tmp);
    conn.veryIdle = 0;
  else
    sendGMList(listeners, S_IDLE, "cidleIdle", conn.username, tmp);
    conn.veryIdle = getSecs();
  end

  if not strfind(conn.flags, "I", 1, 1) then 
    if conn.veryIdle then 
      sendGM(conn, S_IDLE, "cidleYouReidle", tmp);
      conn.veryIdle = 0
    else 
      sendGM(conn, S_IDLE, "cidleYouIdle", tmp);
      conn.veryIdle = getSecs();
    end
  end

end;

function commandName(connection, line, params)
   local p = split(params);
   local conn = colloquy.connections[connection];
      if (p[1] == nil or p[2] == nil) then
        sendGM(conn, S_ERROR, "cnameUsage");
        return nil;
      end;
      
      local i, v, u, nu;
      u = strlower(p[1]);
      nu = p[2];
      if (strlen(nu) > 10) then nu = strsub(nu, 1, 10) end;
      
      if (strlen(gsub(nu, "%w", "")) > 0 or (strlen(nu) > 10)) then
        sendGM(conn, S_ERROR, "cnameInvalid");
        return nil;
      end;

      for i, v in colloquy.connections do
        if (i ~= "n" and u == strlower(v.username)) then
          -- we've found the user to be renamed... check if it's already in use...
          local j, k;
            for j, k in colloquy.connections do
              if (j ~= "n" and (strlower(p[1]) ~= strlower(p[2])) and strlower(k.username) == strlower(nu)) then
                sendGM(conn, S_ERROR, "cnameAlready");
                return nil;
              end;
            end;
    
            local tmp = "";
    
            if (i == connection) then
              sendGMAll(S_NAME, "cnameMyNameDone", v.username, nu);
            else
              if (allowZ(i)) then
                sendGM(conn, S_ERROR, "Immune", v.username);
                return nil;
              end;
             sendGMAll(S_NAME, "cnameDone", conn.username, v.username, nu);
           end;
    
           log(format("N  %s[%s] changed name of %s[%s] to %s", colloquy.connections[connection].username, colloquy.connections[connection].realUser, v.username, v.realUser, nu));
           v.username = nu;

           return nil;
         end;
       end;
      sendGM(conn, S_ERROR, "UnknownUser", p[1]);
end;

function commandNameself(connection, line, params)
   local conn = colloquy.connections[connection];
   if (conn.status < 2) then
     sendGM(conn, S_ERROR, "cnameselfGuest");
     return nil;
   end;
   local p = split(params);

   if (p[1] ~= nil and strlower(p[1]) == strlower(conn.username)) then
     if (strlower(p[1]) == strlower(conn.realUser)) then
       -- they're the same username at least...
       if (p[1] == conn.username) then
         sendGM(conn, S_ERROR, "cnameselfAlreadyNamed", conn.username);
         return nil;
       else
         for i, v in colloquy.connections do
           if (i ~= "n" and strlower(v.username) == strlower(conn.realUser) and v.realUser ~= conn.realUser) then
             sendGM(conn, S_ERROR, "cnameselfAlready");
             return nil;
           end;
         end;
         conn.username = p[1];
         conn.realUser = p[1];
         sendGM(conn, S_DONE, "cnameselfChanged", conn.username);
         return nil;
       end;
     else
       sendGM(conn, S_ERROR, "cnameselfNotSame", p[1], conn.realUser);
       return nil;
     end;
   else
     if (conn.username == conn.realUser) then
       sendGM(conn, S_ERROR, "cnameselfAlreadyNamed", conn.username);
       return nil;
     end;
     for i, v in colloquy.connections do
       if (i ~= "n" and strlower(v.username) == strlower(conn.realUser) and v.realUser ~= conn.realUser) then
         sendGM(conn, S_ERROR, "cnameselfAlready");
         return nil;
       end;
     end;
     sendGMAll(S_NAME, "cnameselfAllChange", conn.username, conn.realUser);
     log(format("N  %s changed name back to %s", conn.username, conn.realUser));
     conn.username = conn.realUser;
   end;
end;

function commandWarn(connection, line, params)
   local p = split(params);
   local conn = colloquy.connections[connection];
      if (p[1] == nil or p[2] == nil) then
        sendGM(conn, S_ERROR, "cwarnUsage");
        return nil;
      end;
      
      local i, v, u, m;
      u = strlower(p[1]);

      if (p[2] ~= nil) then
        m = strsub(params, strfind(params, " ") + 1, strlen(params));
      end;


      for i,v in colloquy.connections do
        if (i ~="n" and u == strlower(v.username)) then
          log(format("W  %s[%s] warns %s[%s]: %s", colloquy.connections[connection].username, colloquy.connections[connection].realUser, v.username, v.realUser, m));
          sendGMAll(S_WARN, "cwarnDone", conn.username, v.username, m);
          return nil;
        end;
      end;

      sendGM(conn, S_ERROR, "UnknownUser", p[1]);
end;

function commandKick(connection, line, params)
   local p = split(params);
   local conn = colloquy.connections[connection];
      if (p[1] == nil) then
        sendGM(conn, S_ERROR, "chickUsage");
        return nil;
      end;
      
      local i, v, u, m;
      u = strlower(p[1]);
      
      if (p[2] ~= nil) then
        m = strsub(params, strfind(params, " ") + 1, strlen(params));
      end;

      for i,v in colloquy.connections do
        if (i ~="n" and u == strlower(v.username)) then
          if (allowZ(i)) then
            sendGM(conn, S_ERROR, "Immune", v.username);
            return nil;
          end;

          local tmp = "K " .. colloquy.connections[connection].username .. " " .. p[1];
          if (p[2] ~= nil) then
            tmp = tmp .. " " .. m;
          end;
          log(format("K  %s[%s] kicks %s[%s]: %s", colloquy.connections[connection].username, colloquy.connections[connection].realUser, v.username, v.realUser, p[2] or "(no reason)"));

          tmp = "- Kicked by " .. colloquy.connections[connection].username;
          if (p[2] ~= nil) then
            tmp = tmp .. " (" .. m .. ")";
          end;

          if (p[2] ~= nil) then
            sendGM(colloquy.connections[i], S_ERROR, "ckickMessage", "(" .. m .. ")");
          else
            sendGM(colloquy.connections[i], S_ERROR, "ckickMessage", gm(colloquy.connections[i], "ckickDefault"));
          end;

          disconnectUser(i, tmp);
          return nil;
        end;
      end;
      sendGM(conn, S_ERROR, "UnknownUser", p[1]);
end;

function commandInvis(connection, line)
   colloquy.connections[connection].invis = 1;
   sendGM(colloquy.connections[connection], S_DONE, "cinvisDone");
   log(format("I  %s[%s]", colloquy.connections[connection].username, colloquy.connections[connection].realUser));
end;

function commandVis(connection, line)
   colloquy.connections[connection].invis = nil;
   sendGM(colloquy.connections[connection], S_DONE, "cvisDone");
   log(format("i  %s[%s]", colloquy.connections[connection].username, colloquy.connections[connection].realUser));
end;

function commandRequest(connection, line, params)
   local conn = colloquy.connections[connection];
   if (params == "" or params == nil) then
      sendGM(conn, S_ERROR, "crequestUsage");
      return nil;
   end;

   if colloquy.noFork then
     sendGM(conn, S_ERROR, "crequestNoFork");
     return nil;
   end

   local headers = {
     to = colloquy.email,
     subject = "[colloquy] Request from " .. colloquy.connections[connection].realUser,
   }

   local e = SMTP.mail {
     from = colloquy.email, 
     rcpt = headers.to, 
     headers = headers, 
     body = params, 
     server = colloquy.smtpserver
   }

   if not e then 
     sendGM(conn, S_DONE, "crequestDone");
   else
     sendGM(conn, S_ERROR, "crequestError", e);
   end
end;

function commandTime(connection, line)
   sendGM(colloquy.connections[connection], S_TIME, "ctimeDone", date("%a %b %e %H:%M:%S %Y"));
end;

function commandWho(connection, line, params)
   local i, v, l, count, idling;
   local p = split(params);
   local conn = colloquy.connections[connection];
   
   if (p[1]) then
     sendGM(conn, S_WHOHDR, "cwhoGroup", p[1]);
   else
     sendGM(conn, S_WHOHDR, "cwhoAll", colloquy.talkerName);
   end;
   sendGM(conn, S_WHOHDR, "cwhoColumns");

   local sorted = {};
   local lg;
   for i, v in colloquy.connections do
     if (type(v) == "table") then tinsert(sorted, v) end;
   end;

   sort(sorted, function(a, b)
                  if (not b) then return 1 end;

                  local la, lb = strlower(a.group), strlower(b.group);

                  if (la == lb) then
                    return (strlower(a.username) < strlower(b.username));
                  elseif (la == "public") then
                    return 1;
                  elseif (lb == "public") then
                    return nil;
                  elseif (la == "bots-r-us") then
                    return nil;
                  elseif (lb == "bots-r-us") then
                    return 1;
                  else
                    return (strlower(a.group) < strlower(b.group));
                  end;
                end);

   count = 0;
   idling = 0;
   for i=1,getn(sorted) do
      v=sorted[i];
      
      if (i ~= "n") then
        if (v.status == 0) then
          l = "--- Still connecting ---              "
        else
           if (not (v.invis or (v.restrict and strfind(v.restrict, "B", 1, 1))) or (conn.privs and strfind(conn.privs, "M"))) and (p[1] == nil or (strlower(v.group) == strlower(p[1]))) then
              local flags = "";
            
              if (v.privs and strfind(v.privs, "M", 1, 1)) then flags = "M"
              elseif (v.restrict and strfind(v.restrict, "B", 1, 1)) then flags = "B"
              elseif (v.privs ~= "" and v.privs ~= nil) then flags = "P"
              elseif (v.status > 1) then flags = "U" end;

              if (v.invis) then flags = flags .. "I" end;
              if (v.restrict ~= "" and v.restrict ~= nil) then flags = flags .. gsub(v.restrict, "B", "") end;

              local idle;

              if (v.veryIdle) then
                idle = gm(conn, "cwhoIdle");
                idling = idling + 1;
              else
                if (v.idle) then
                  idle = timeToWhoString(secs - v.idle);
                else
                  idle = "00:00";
                end;
              end;

              local locked = colloquy.lockedGroups[strlower(v.group)];
              if (locked) then locked = " (L)" else locked = "" end;
              send(format("%-10.10s %-1.1s %-19.19s %-6.6s %-5.5s %-27.27s", v.username, y(strlower(v.username) == strlower(v.realUser), "", "*"), v.group .. locked, flags, idle, v.site), conn, S_WHO);
              count = count + 1;
           end;
        end;
      end;
   end;
   sendGM(conn, S_WHOHDR, "cwhoTotal", count, count - idling, idling);
end;

function commandLWho(connection, line, params)
   local i, v, l, count, idling;
   local p = split(params);
   local conn = colloquy.connections[connection];
   local lname;

   if (p[1]) then
     lname, l = listByName(conn, p[1]);
     if (not lname) then
       send(l, conn, S_ERROR);
       return nil;
     end;
       
     sendGM(conn, S_WHOHDR, "clwhoList", lname);
   else
     sendGM(conn, S_ERROR, "clwhoUsage");
     return nil;
   end;
   sendGM(conn, S_WHOHDR, "clwhoColumns");

   local sorted = {};
   local lg;
   for i, v in colloquy.connections do
     if (type(v) == "table") then tinsert(sorted, v) end;
   end;

   sort(sorted, function(a, b)
                  if (not b) then return 1 end;
                  
                  local la, lb = strlower(a.group), strlower(b.group);

                  if (la == lb) then
                    return (strlower(a.username) < strlower(b.username));
                  elseif (la == "public") then
                    return 1;
                  elseif (lb == "public") then
                    return nil;
                  elseif (la == "bots-r-us") then
                    return nil;
                  elseif (lb == "bots-r-us") then
                    return 1;
                  else
                    return (strlower(a.group) < strlower(b.group));
                  end;
                end);

   count = 0;
   idling = 0;
   for i=1,getn(sorted) do
      v=sorted[i];
      
      if (i ~= "n") then
        if (v.status == 0) then
          l = "--- Still connecting ---              "
        else
           if (not (v.invis or (v.restrict and strfind(v.restrict, "B", 1, 1))) or (conn.privs and strfind(conn.privs, "M"))) and (listIsMember(v.realUser, lname, 1)) then
              local flags = "";
            
              if (v.privs and strfind(v.privs, "M", 1, 1)) then flags = "M"
              elseif (v.restrict and strfind(v.restrict, "B", 1, 1)) then flags = "B"
              elseif (v.privs ~= "" and v.privs ~= nil) then flags = "P"
              elseif (v.status > 1) then flags = "U" end;

              if (v.invis) then flags = flags .. "I" end;
              if (v.restrict ~= "" and v.restrict ~= nil) then flags = flags .. gsub(v.restrict, "B", "") end;

              local idle;

              if (v.veryIdle) then
                idle = "IDLE";
                idling = idling + 1;
              else
                if (v.idle) then
                  idle = timeToWhoString(secs - v.idle);
                else
                  idle = "00:00";
                end;
              end;

              local locked = colloquy.lockedGroups[strlower(v.group)];
              if (locked) then locked = " (L)" else locked = "" end;
              send(format("%-10.10s %-1.1s %-19.19s %-6.6s %-5.5s %-27.27s", v.username, y(strlower(v.username) == strlower(v.realUser), "", "*"), v.group .. locked, flags, idle, v.site), conn, S_WHO);
              count = count + 1;
           end;
        end;
      end;
   end;
   sendGM(conn, S_WHOHDR, "clwhoTotal", count, count - idling, idling);
end;

function commandGag(connection, line, params)
   local p = split(params);
   local conn = colloquy.connections[connection];

   if (p[1] == nil) then
      sendGM(conn, S_ERROR, "cgagUsage");
      return nil;
   end;

   local u = strlower(p[1]);
   local i, v;
   
   for i, v in colloquy.connections do
      if (i ~= "n") then
        if (strlower(v.username) == u) then
          if (allowZ(i)) then
            sendGM(conn, S_ERROR, "Immune", v.username);
            return nil;
          end;

          if (strfind(v.restrict, "G", 1, 1)) then
            sendGM(conn, S_ERROR, "cgagAlready", v.username);
            return nil;
          end;
          v.restrict = v.restrict .. "G";
          sendGMAll(S_GAG, "cgagGag", v.username, conn.username);
          log(format("G  %s[%s] gagged %s[%s]", colloquy.connections[connection].username, colloquy.connections[connection].realUser, v.username, v.realUser));
          return nil;
         end;
      end;
   end;

   sendGM(conn, S_ERROR, "UnknownUser", p[1]);

end;

function commandCensor(connection, line, params)
   local p = split(params);
   local conn = colloquy.connections[connection];

   if (p[1] == nil) then
      sendGM(conn, S_ERROR, "ccensorUsage");
      return nil;
   end;

   local u = strlower(p[1]);
   local i, v;
   
   for i, v in colloquy.connections do
      if (i ~= "n") then
        if (strlower(v.username) == u) then
          if (allowZ(i)) then
            sendGM(conn, S_ERROR, "Immune", v.username);
            return nil;
          end;

          if (strfind(v.restrict, "C", 1, 1)) then
            sendGM(conn, S_ERROR, "ccensorAlready", v.username);
            return nil;
          end;
          v.restrict = v.restrict .. "C";
          sendGMAll(S_GAG, "ccensorCensor", v.username, conn.username);
          log(format("MC %s[%s] censors %s[%s]", colloquy.connections[connection].username, colloquy.connections[connection].realUser, v.username, v.realUser));
         return nil;
        end;
      end;
   end;

   sendGM(conn, S_ERROR, "UnknownUser", p[1]);
end;

function commandUngag(connection, line, params)
   local p = split(params);
   local conn = colloquy.connections[connection];

   if (p[1] == nil) then
      sendGM(conn, S_ERROR, "cungagUsage");
      return nil;
   end;

   local u = userByName(p[1]);

   if (not u) then
     sendGM(conn, S_ERROR, "UnknownUser", p[1]);
     return nil;
   elseif (type(u) == "string") then
     send(u, conn, S_ERROR);
     return nil;
   elseif (u.realUser == conn.realUser) then
     sendGM(conn, S_ERROR, "cungagSelf");
     return nil;
   end;

   if (not strfind(u.restrict, "G", 1, 1)) then
     sendGM(conn, S_ERROR, "cungagAlready", u.username);
     return nil;
   end;

   u.restrict = gsub(u.restrict, "G", "");
   sendGMAll(S_UNGAG, "cungagUngag", u.username, conn.username);
   log(format("g  %s[%s] ungags %s[%s]", conn.username, conn.realUser, u.username, u.realUser));
end;

function commandUncensor(connection, line, params)
   local p = split(params);
   local conn = colloquy.connections[connection];
   
   if (p[1] == nil) then
      sendGM(conn, S_ERROR, "cuncensorUsage");
      return nil;
   end;

   local u = strlower(p[1]);

   if (u == strlower(colloquy.connections[connection].username)) then
      sendGM(conn, S_ERROR, "cuncensorSelf");
      return nil;
   end;

   local i, v;
   
   for i, v in colloquy.connections do
      if (i ~= "n") then
        if (strlower(v.username) == u) then
          if (strfind(v.restrict, "C", 1, 1) == nil) then
            sendGM(conn, S_ERROR, "cuncensorAlready", v.username);
            return nil;
          end;
          v.restrict = gsub(v.restrict, "C", "")
          sendGMAll(S_UNGAG, "cuncensorUncensor", v.username, conn.username);
          log(format("mc %s[%s] uncensors %s[%s]", colloquy.connections[connection].username, colloquy.connections[connection].realUser, v.username, v.realUser));
          return nil;
        end;
      end;
   end;

   sendGM(conn, S_ERROR, "UnknownUser", p[1]);
end;

function commandBanUser(connection, line, params)
   local p = split(params);
   local conn = colloquy.connections[connection];

   if (p[1] == nil or p[2] == nil) then
      sendGM(conn, S_ERROR, "cbanuserUsage");
      return nil;
   end;

   local i, v, u;
   u = strlower(p[1]);

   for i, v in users do
      if (i ~= "n") then
        if (i == u) then
          if (v.privs ~= nil and strfind(v.privs, "Z", 1, 1)) then
            sendGM(conn, S_ERROR, "Immune", i);
            return nil;
          end;
          v.banned = strsub(params, strfind(params, p[1]) + strlen(p[1]) + 1, -1) .. " [" .. colloquy.connections[connection].realUser .. "]";
          sendGM(conn, S_DONE, "cbanuserDone", i);
          log(format("B  %s[%s] bans %s: %s", colloquy.connections[connection].username, colloquy.connections[connection].realUser, u, v.banned));
          saveOneUser(u);
          return nil;
        end;
      end;
   end;

   sendGM(conn, S_ERROR, "UnknownUser", p[1]);
end;

function commandUnbanUser(connection, line, params)
   local p = split(params);
   local conn = colloquy.connections[connection];

   if (p[1] == nil) then
      sendGM(conn, S_ERROR, "cunbanuserUsage");
      return nil;
   end;

   local i, v, u;
   u = strlower(p[1]);

   for i, v in users do
      if (i ~= "n") then
        if (i == u) then
          if (v.banned ~= nil and v.banned ~= "") then
            v.banned = "";
            sendGM(conn, S_DONE, "cunbanuserDone", i);
            log(format("b  %s[%s] unbans %s", colloquy.connections[connection].username, colloquy.connections[connection].realUser, u));
            saveOneUser(u);
          else
            sendGM(conn, S_ERROR, "cunbanuserAlready", i);
          end;
          return nil;
        end;
      end;
   end;

   sendGM(conn, S_ERROR, "UnknownUser", p[1]);
end;

function commandLockTalker(connection, line, params)
   local conn = colloquy.connections[connection];
   
   sendGMAll(S_TALKERLOCK, "clocktalkerDone", conn.username);
   log(format("B  %s[%s] locked the talker", conn.username, conn.realUser));
   colloquy.locked = 1;
end;

function commandUnlockTalker(connection, line, params)
   local conn = colloquy.connections[connection];

   sendGMAll(S_TALKERUNLOCK, "cunlocktalkerDone", conn.username);
   log(format("b  %s[%s] unlocked the talker", conn.username, conn.realUser));   
   colloquy.locked = nil;
end;

function commandAlert(connection, line, params)
   local p = split(params);
   local conn = colloquy.connections[connection];
   
   if (p[1] == nil) then
      sendGM(conn, S_ERROR, "calertUsage");
      return nil;
   end;

   log(format("A  %s[%s] %s", conn.username, conn.realUser, params));
   sendGMAll(S_ALERT, "calertDone", params);
end;

function commandLogin(connection, line, params)
   local p = split(params);
   local c = colloquy.connections[connection];
  
   if (p[2] == nil) then
     sendGM(c, S_ERROR, "cloginUsage");
     return nil;
   end;

   local user = strlower(p[1]);

   if (users[user] == nil) then
     sendGM(c, S_ERROR, "UnknownUser", p[1]);
     return nil;
   end;

   local u = users[user];

   local i, v;
  
  for i, v in colloquy.connections do
     if (i ~= "n" and strlower(c.username) ~= user) then
       if (strlower(v.username) == user) then
         sendGM(c, S_ERROR, "cloginAlready", v.username);
         return nil;
       end;
     end;
   end;

   local pr, message = checkPassword(user, p[2]);
   if (not pr) then
     u.failed = (u.failed or 0) + 1;
     send(message or gm(c, "cloginPassword"), c, S_ERROR);
     log(format("!+ Authentication for %s failed (%s) by %s[%s].", p[1], message or "incorrect password", c.username, c.realUser));
     return nil;
   end;

   if u.banned and u.banned ~= "" then
     sendGM(c, S_ERROR, "cloginBanned", p[1], u.banned);
     log(format("!+ Banned user %s tried to logon from %s[%s].", p[1], c.username, c.realUser));
     return nil;
   end
 
   if (u.timeon == nil) then
      sendGM(c, S_ERROR, "cloginNoNormal", p[1]);
      return nil;
   end;

   disconnectUser(c.socket.socket, "Logged on as " .. p[1], 1);
 
   log(format("-  %s[%s] logged on as...", c.username, c.realUser));
   log(format("+  %s", p[1]));

   local oldName = c.username;
   
   c.username = p[1];
   c.realUser = p[1];
   c.status = 2;
   c.privs = u.privs;
   c.flags = u.flags;
   c.termType = u.termType;
   c.colours = u.colours;
   c.restrict = u.restrict;
   c.timeWarn = u.timeWarn;
   c.aliases = u.aliases;
   u.connected = secs;

   if (u.termType == "colour" and strfind(c.flags, "W")) then
     send("\255\253\31", c, S_RAW);
   end;

   commandSet(connection, ".set", "");

   sendGMAll(S_LOGIN, "cloginDone", oldName, p[1]);
   if (u.failed and u.failed > 0) then
     sendGM(c, S_DONE, "cloginFailures", u.failed);
     u.failed = 0;
   end;

end;

function commandComment(connection, line, params)
  local conn = colloquy.connections[connection];
  if (params == nil or params == "") then
    if (conn.comment) then
      conn.comment = nil;
      sendGM(conn, S_DONE, "ccommentRemove");
    else
      sendGM(conn, S_ERROR, "ccommentNone");
    end;
    return nil;
  else
   sendGM(conn, S_DONE, "ccommentSet", params);
   conn.comment = params;
  end;
end;

function commandComments(connection, line, params)
  local i, v, p;
  local conn = colloquy.connections[connection];
  p = 0;
  for i, v in colloquy.connections do
    if (i ~= "n" and v.comment ~= nil) then
      send(v.username .. ": " .. v.comment, conn, S_COMMENT);
      p = p + 1;
    end;
  end;
  if (p == 0) then
   sendGM(conn, S_COMMENT, "ccommentsNone");
  end;
end;

function commandWake(connection, line, params)
  local p = split(params);
  local conn = colloquy.connections[connection];

  if (p[1] == nil) then
    sendGM(conn, S_ERROR, "cwakeUsage");
    return nil;
  end;

  local u = userByName(p[1]);
  if (u == nil) then
    sendGM(conn, S_ERROR, "UnknownUser", p[1]);
    return nil;
  end;

  if (type(u) == "string") then
    send(u, conn, S_ERROR);
    return nil;
  end;

  sendGM(u, S_WAKE, "cwakeAttempts", conn.username);
  sendGM(conn, S_DONE, "cwakeDone", u.username);

end;

function commandShowLog(connection, line, params)
  local conn = colloquy.connections[connection];
  local t = {};
  local f = openfile(colloquy.logName, "r");
  local l;
  
  if not f then
    sendGM(conn, S_ERROR, "NotAvail");
    return nil;
  end;

  seek(f, "end", -1024);
  
  repeat
    l = read(f);
    if l then
      tinsert(t, l);
    end;
  until not l;

  closefile(f);

  for i = getn(t) - 10, getn(t) do
    if t[i] then
      send(t[i], conn, S_LOOK);
    end;
  end;

end;

function commandLock(connection, line, params)
  local conn = colloquy.connections[connection];

  if (strlower(conn.group) == "public") then
    sendGM(conn, S_ERROR, "clockPublic");
    return nil;
  end;

  if (colloquy.lockedGroups[strlower(conn.group)]) then
    sendGM(conn, S_ERROR, "clockAlready");
    return nil;
  end;

  colloquy.lockedGroups[strlower(conn.group)] = 1;
  sendGMGroup(conn.group, S_DONE, "clockDone", conn.username);
  sendToObservers(format("%s has locked group '%s'.", conn.username, conn.group), conn.group, S_DONE)
end;

function commandUnlock(connection, line, params)
  local conn = colloquy.connections[connection];

  if (strlower(conn.group) == "public") then
    sendGM(conn, S_ERROR, "cunlockPublic");
    return nil;
  end;

  if (not colloquy.lockedGroups[strlower(conn.group)]) then
    sendGM(conn, S_ERROR, "cunlockAlready");
    return nil;
  end;

  colloquy.lockedGroups[strlower(conn.group)] = nil;
  updateInvitations("@" .. strlower(conn.group), "");
  sendGMGroup(conn.group, S_DONE, "cunlockDone", conn.username);
  sendToObservers(format("%s has unlocked group '%s'.", conn.username, conn.group), conn.group, S_DONE)
end;

function commandInvite(connection, line, params)

  local conn = colloquy.connections[connection];
  local p = split(params);

  if (not p[1]) then
    sendGM(conn, S_ERROR, "cinviteUsage");
    return nil;
  end;

  local u, spec = getUserMultiple(params);
  if (u == nil) then
    send(spec, conn, S_ERROR);
    return nil;
  end;
 
  -- check if everybody in the spec isn't already in this group.
  local g = strlower(conn.group);
  for i, v in u do
    if (i ~= "n") then
      if (g == strlower(v.group)) then
        sendGM(conn, S_ERROR, "cinviteAlready", v.username);
        return nil;
      end;
    end;
  end;

  sendGMGroup(conn.group, S_INVITE, "cinviteDone", conn.username, spec);
  for i, v in u do
    if (i ~= "n") then
      addInvitation(v, "@" .. strlower(conn.group));
      sendGM(v, S_INVITE, "cinviteUser", conn.username, conn.group, conn.username);
    end;
  end;
end;

function commandIdlers(connection, line, params)
   local i, v, l, count;
   local p = split(params);
   local conn = colloquy.connections[connection];
   
   if (p[1]) then
     sendGM(conn, S_WHOHDR, "cidlersGroup", p[1]);
   else
     sendGM(conn, S_WHOHDR, "cidlersAll", colloquy.talkerName);
   end;
   sendGM(conn, S_WHOHDR, "cidlersHeader")

   local sorted = {};
   local lg;
   for i, v in colloquy.connections do
     if (type(v) == "table" and v.veryIdle) then tinsert(sorted, v) end;
   
    end;

   sort(sorted, function(a, b)
                  if (not b) then return 1 end;
                  
                  local la, lb = strlower(a.group), strlower(b.group);

                  if (la == lb) then
                    return (strlower(a.username) < strlower(b.username));
                  elseif (la == "public") then
                    return 1;
                  elseif (lb == "public") then
                    return nil;
                  elseif (la == "bots-r-us") then
                    return nil;
                  elseif (lb == "bots-r-us") then
                    return 1;
                  else
                    return (la < lb);
                  end;
                end);

   count = 0;
   for i=1,getn(sorted) do
      v=sorted[i];
      
      if (i ~= "n") then
        if (v.status == 0) then
          l = "--- Still connecting ---              "
        else
           if (not v.invis or (conn.privs and strfind(conn.privs, "M"))) and (p[1] == nil or (strlower(v.group) == strlower(p[1]))) then
             send(format("%-10.10s %-8.8s %-55.55s", v.username, timeToShortString(secs - v.idle), v.idleReason),
                  conn, S_WHO);
             count = count + 1;        
           end;
         end;
      end;
   end;
   sendGM(conn, S_WHOHDR, "cidlersTotal", count);
end;

function commandEvict(connection, line, params)

  local conn = colloquy.connections[connection];
  local p = split(params);

  if (not p[1]) then
    sendGM(conn, S_ERROR, "cevictUsage");
    return nil;
  end;

  local ruser = userByName(p[1]);
  if (type(ruser) == "nil") then
    sendGM(conn, S_ERROR, "UnknownUser", p[1]);
    return nil;
  elseif (type(ruser) == "string") then
    send(ruser, conn, S_ERROR);
    return nil;
  end;

  if (ruser.username == conn.username) then
    sendGM(conn, S_ERROR, "cevictSelf");
    return nil;
  end;

  if (strlower(ruser.group) == "public" and (not conn.privs or not strfind(conn.privs, "E", 1, 1))) then
    sendGM(conn, S_ERROR, "cevictPublic");
    return nil;
  elseif (strlower(ruser.group) == "public" and (conn.privs and strfind(conn.privs, "E", 1, 1))) then
    sendGM(ruser, S_EVICT, "cevictEvictee", conn.username);
    ruser.group = "";
    sendGMGroup("limbo", S_EVICT, "cevictOthers", ruser.username, conn.username);
    ruser.group = "Limbo";
    commandLook(ruser.socket.socket);
    sendGMGroup("public", S_EVICT, "cevictDone", conn.username, ruser.username);
    log(format("E  %s[%s] evicts %s[%s] from %s", conn.username, conn.realUser, ruser.username, ruser.realUser, "public"));
    return nil;
  end;

  if (strlower(conn.group) ~= strlower(ruser.group)) then
    if (conn.privs and strfind(conn.privs, "E", 1, 1)) then
      local o = ruser.group;
      sendGM(ruser, S_EVICT, "cevictEvictee", conn.username);
      ruser.group = "";
      sendGMGroup("public", S_EVICT, "cevictOthers", ruser.username, conn.username);
      ruser.group = "Public";
      commandLook(ruser.socket.socket);
      sendGMGroup(o, S_EVICT, "cevictDone", conn.username, ruser.username);
      sendGM(conn, S_DONE, "Done");
      log(format("E  %s[%s] evicts %s[%s] from %s", conn.username, conn.realUser, ruser.username, ruser.realUser, o));
      return nil;
    else
      sendGM(conn, S_ERROR, "cevictGroup");
      return nil;
    end;
  end;

  sendGM(ruser, S_EVICT, "cevictEvictee", conn.username);
  ruser.group = "";
  sendGMGroup("public", S_EVICT, "cevictOthers", ruser.username, conn.username);
  ruser.group = "Public";
  commandLook(ruser.socket.socket);
  sendGMGroup(o, S_EVICT, "cevictDone", conn.username, ruser.username);
end;

function commandQuery(connection, line, params)
  local p = split(params);
  local conn = colloquy.connections[connection];

  if (not p[1]) then
    if (conn.query) then
      sendGM(conn, S_DONE, "cqueryEnd")
      conn.query = nil;
    else
      sendGM(conn, S_ERROR, "cqueryNone");
    end;
    return nil;
  end;

  local t = strsub(p[1], 1, 1);
  local u;
  if (t == "%") then
    -- they want to query a list...
    local ll = strlower(strsub(p[1], 2, -1));
    local l, err = listByName(conn, ll, 1);
    
    if (l == nil) then
      send(err, conn, S_ERROR);
      return nil;
    end;
    
    if (lists[l] == nil) then
      sendGM(conn, S_ERROR, "UnknownList", l);
      return nil;
    end;
 
    if (not listIsMember(conn.realUser, l)) then
      sendGM(conn, S_ERROR, "cqueryNoList");
      return nil;
    end;

    conn.query = { format = "%" .. lists[l].listname, data = lists[l] };
    sendGM(conn, S_DONE, "cqueryList", lists[l].listname);
    return nil;
  elseif (t == "@") then
    -- They want to query a group...
    -- Also, perhaps write a groupByName to handle contractions?
    local group, err = groupByName(strsub(p[1], 2, -1));
    if (not group) then
      send(err, conn, S_ERROR);
      return nil;
    end;
    conn.query = { format = "@" .. group, data = group };
    sendGM(conn, S_DONE, "cqueryGroup", group);
    return nil;
  else
    -- is it a user?
    u = userByName(p[1]);
    if (type(u) == "string") then
      send(u, conn, S_ERROR);
      return nil;
    elseif (u == nil) then
      sendGM(conn, S_ERROR, "UnknownUser", p[1]);
      return nil;
    end;
    conn.query = { format = ">" .. u.username, data = u };
    sendGM(conn, S_DONE, "cqueryUser", u.username);
  end;
  
end;  

function commandBan(connection, line, params)
  local conn = colloquy.connections[connection];
  local p = split(params);
  
  if (p[1] ~= nil and p[2] == nil) then
    sendCM(conn, S_ERROR, "cbanUsage");
    return nil;
  end;

  if (p[1] == nil and p[2] == nil) then
    sendGM(conn, S_INFO, "cbanHeader");
    local i, v;
    for i, v in colloquy.banMasks do
      if (type(v) == "table") then
        send(format(" %s (%s)", v.mask, v.reason), conn, S_INFO);
      end;
    end;
    return nil;
  end;

  tinsert(colloquy.banMasks, { mask = p[1], reason = strsub(params, strfind(params, p[2], 1, 1), -1) .. " [" .. conn.realUser .. "]" } );
  log(format("B  %s[%s] bans %s : %s", conn.username, conn.realUser, p[1], strsub(params, strfind(params, p[2], 1, 1), -1)));
  saveBans(colloquy.banFile);
  sendGM(conn, S_DONE, "cbanDone", p[1]);
end;

function commandUnban(connection, line, params)
  local conn = colloquy.connections[connection];
  local p = split(params);
  
  if (p[1] == nil) then
    sendGM(conn, S_ERROR, "cunbanUsage");
    return nil;
  end;

  local i, v;
  for i, v in colloquy.banMasks do
    if (type(v) == "table" and v.mask == p[1]) then
      tremove(colloquy.banMasks, i);
      log(format("b  %s[%s] unbans %s : %s", conn.username, conn.realUser, p[1], v.reason));
      saveBans(colloquy.banFile);
      sendGM(conn, S_DONE, "cunbanDone", p[1]);
      return nil;
    end;
  end;
  
  sendGM(conn, S_ERROR, "cunbanNone", p[1]);
end;

function commandMOTD(connection, line, params)
  sendFile("data/misc/motd", {colloquy.connections[connection]});
end;

function commandIgnore(connection, line, params)
  local p = split(params);
  local conn = colloquy.connections[connection];
  local silent = (strlower(p[2] or "")) == gm(conn, "cignoreSilently");

  if (p[1] == nil) then
    -- no parameters - print out who they're ignoring
    sendGM(conn, S_DONE, "cignoreIgnoring");
    if (conn.ignoring) then
      local t = {};
      foreach(conn.ignoring, function(i, v) tinsert(%t, i.username) end);
      sort(t);
      foreachi(t, function(i, v) send(" " .. v, %conn, S_DONE) end);
    else
      sendGM(conn, S_DONE, "cignoreNobody");
    end;
    local t, i, v = {};
    for i, v in colloquy.connections do
      if (v.ignoring and v.ignoring[conn]) then
        tinsert(t, v.username);
      end;
    end;
    sort(t);
    sendGM(conn, S_DONE, "cignoreIgnored");
    if (getn(t) > 0) then
      foreachi(t, function(i, v) send(" " .. v, %conn, S_DONE) end);
    else
      sendGM(conn, S_DONE, "cignoreNobody");
    end;
    return nil;
  end;

  local u = userByName(p[1]);
  if (not u) then
    sendGM(conn, S_ERROR, "UnknownUser", p[1]);
    return nil;
  end;

  if (type(u) == "string") then
    send(u, conn, S_ERROR);
    return nil;
  end;

  if (u == conn) then
    sendGM(conn, S_ERROR, "cignoreSelf");
    return nil;
  end;

  if (conn.ignoring and conn.ignoring[u]) then
    sendGM(conn, S_ERROR, "cignoreAlready", u.username);
    return nil;
  end;

  if (not conn.ignoring) then
    conn.ignoring = {};
  end;

  conn.ignoring[u] = 1;

  sendGM(conn, S_DONE, "cignoreDone", u.username);
  local suffix = "";
  if (silent and u.privs and strfind(u.privs, "M", 1, 1)) then silent = nil; suffix = format(" (%s)", gm(u, "cignoreSilently")) end;
  if (not silent) then
    sendGM(u, S_DONE, "cignoreIgnoree", conn.username, suffix);
  end;
end;

function commandUnignore(connection, line, params)
  local p = split(params);
  local conn = colloquy.connections[connection];
  local silent = (strlower(p[2] or "")) == gm(conn, "cingoreSilently");
  
  if (not p[1]) then
    sendGM(conn, S_ERROR, "cunignoreUsage");
    return nil;
  end;

  local u = userByName(p[1]);
  if (not u) then
    sendGM(conn, S_ERROR, "UnknownUser", p[1]);
    return nil;
  end;

  if (type(u) == "string") then
    send(u, conn, S_ERROR);
    return nil;
  end;

  if (not conn.ignoring or not conn.ignoring[u]) then
    sendGM(conn, S_ERROR, "cunignoreAlready", u.username);
    return nil;
  end;

  conn.ignoring[u] = nil;
  if (empty(conn.ignoring)) then
    conn.ignoring = nil;
  end;

  sendGM(conn, S_DONE, "cunignoreDone", u.username);
  local suffix = "";
  if (silent and u.privs and strfind(u.privs, "M", 1, 1)) then silent = nil; suffix = format(" (%s)", gm(u, "cignoreSilently")) end;
  if (not silent) then
    sendGM(u, S_DONE, "cunignoreIgnoree", conn.username, suffix);
  end;
end;

function commandWhoAmI(connection, line, params)
  local conn = colloquy.connections[connection];
  
  if (conn.realUser ~= conn.username) then
    sendGM(conn, S_DONE, "cwhoamiOther", conn.realUser, conn.username);
  else
    sendGM(conn, S_DONE, "cwhoamiNormal", conn.realUser);
  end;
end;

function commandBot(connection, line, params)
   local p = split(params);
   local conn = colloquy.connections[connection];
   
   if (p[1] == nil) then
      sendGM(conn, S_ERROR, "cbotUsage");
      return nil;
   end;

   local u = strlower(p[1]);
   local i, v;

   if (strsub(u, -3, -1) ~= "bot") then
     sendGM(conn, S_ERROR, "cbotNot", p[1]);
     return nil;
   end;
   
   for i, v in colloquy.connections do
      if (i ~= "n") then
        if (strlower(v.username) == u) then
          if (allowZ(i)) then
            sendGM(conn, S_ERROR, "Immune", v.username);
            return nil;
          end;

          if (strfind(v.restrict, "B", 1, 1)) then
            sendGM(conn, S_ERROR, "cbotAlready", v.username);
            return nil;
          end;
          v.restrict = v.restrict .. "B";
          sendGMAll(S_GAG, "cbotDone", v.username, conn.username);
          log(format("MB %s[%s] bots %s[%s]", colloquy.connections[connection].username, colloquy.connections[connection].realUser, v.username, v.realUser));
         return nil;
        end;
      end;
   end;

   sendGM(conn, S_ERROR, "UnknownUser", p[1]);
end;

function commandUnbot(connection, line, params)
   local p = split(params);
   local conn = colloquy.connections[connection];

   if (p[1] == nil) then
      sendGM(conn, S_ERROR, "cunbotUsage");
      return nil;
   end;

   local u = strlower(p[1]);
 
   if (strsub(u, -3, -1) ~= "bot") then
     sendGM(conn, S_ERROR, "cbotNot", p[1]);
     return nil;
   end;
 
   local i, v;
   
   for i, v in colloquy.connections do
      if (i ~= "n") then
        if (strlower(v.username) == u) then
          if (strfind(v.restrict, "B", 1, 1) == nil) then
            sendGM(conn, S_ERROR, "cunbotAlready", v.username);
            return nil;
          end;
          v.restrict = gsub(v.restrict, "B", "")
          sendGMAll(S_UNGAG, "cunbotDone", v.username, conn.username);
          log(format("mb %s[%s] has been unmade a bot by %s[%s]", colloquy.connections[connection].username, colloquy.connections[connection].realUser, v.username, v.realUser));
          return nil;
        end;
      end;
   end;

   sendGM(conn, S_ERROR, "UnknownUser", p[1]);
end;

function commandBots(connection, line, params)
  local total = 0;
  local occ;
  local conn = colloquy.connections[connection];
  for i, v in colloquy.connections do
    if (v.restrict and strfind(v.restrict, "B", 1, 1)) then
      if (total == 0) then
        send(format("%-15.15s %s", gm(conn, "cbotsName"), gm(conn, "cbotsUse")), conn, S_BOTHDR);
      end;
      if (users[strlower(v.realUser)] and users[strlower(v.realUser)].occupation) then
        occ = users[strlower(v.realUser)].occupation;
      else
        occ = gm(conn, "cbotsUseless");
      end;
      send(format("%-15.15s %s", v.username, occ), colloquy.connections[connection], S_BOT);
      total = total + 1;
    end;
  end;
  if (total > 0) then
    sendGM(conn, S_DONE, "cbotsTotal", total);
  else
    sendGM(conn, S_ERROR, "cbotsNone");
  end;
end;

function commandLaston(connection, line, params)
  local conn = colloquy.connections[connection];
  local p = split(params);
  local i;

  if (p[1] == nil) then
    sendGM(conn, S_ERROR, "clastonUsage");
    return nil;
  end;

  if (strsub(p[1], 1, 1) == "%") then
    -- they want to know about a list
    i = listByName(conn, strlower(strsub(p[1], 2, -1)));
    -- OK - first of all, we get the list of realUsers who are on a list.
    -- Then, one by one, go through and see if a user who is connected has
    -- the same realUser.  When we find one, print out a match, and remove
    -- it from the list.  After we've examined all active connections, look
    -- up the remaining entries in the list members in the users table to
    -- find out when they last connected.
    -- User       * Last on
    local members = {};
    local count = 0;
    
    if (i == nil) then
      sendGM(conn, S_ERROR, "UnknownList", p[1]);
      return nil;
    end;

    for i, v in lists[i].members do
      if (type(i) == "number") then tinsert(members, v) end;
    end;

    sendGM(conn, S_DONE, "clastonHeader");

    for i = 1, getn(members) do
      for k, j in colloquy.connections do
        if (strlower(j.realUser) == members[i]) then
          local u = strlower(j.realUser);
          local tmp;
          tmp = gm(conn, "clastonConnected", j.group, timeToShortString(floor(secs - j.idle)));
          send(format("%-10.10s %-1.1s %s", j.username, y(strlower(j.username) == strlower(j.realUser), "", "*"), tmp), conn, S_DONE);
          count = count + 1;
          members[i] = nil;
        end
      end;
    end;

    -- right, we've dumped out the stuff for currently connected
    -- users, and removed them from the table.  Now look up the remaining
    -- in the users table.
    
    for i = 1, getn(members) do
      if (members[i]) then
        local tmp;
        if (not users[members[i]]) then
          tmp = gm(conn, "clastonNoExist");
        elseif (not users[members[i]].lastLogon) then
          tmp = gm(conn, "clastonNever");
        else
          tmp = users[members[i]].lastLogon;
        end;
        send(format("%-10.10s %-1.1s %s", members[i], "", tmp), conn, S_DONE);
        count = count + 1;
      end;
    end;

    sendGM(conn, S_DONE, "clastonTotal", count);

    return nil;
  else
    -- they want to know about a single user
    i = strlower(p[1]);
    if (users[i] == nil) then
      sendGM(conn, S_ERROR, "UnknownUser", i);
      return nil;
    end;
    if (users[i].connected) then
      i = userByName(i);
      sendGM(conn, S_DONE, "clastonUser", i.username, i.group, timeToShortString(floor(secs - i.idle)));
    else
      if not users[i].lastLogon then
        sendGM(conn, S_DONE, "clastonUserNever", i);
      else
        sendGM(conn, S_DONE, "clastonUserConn", i, users[i].lastLogon);
      end;
    end;
  end;

end;

function commandGuest(connection, line, params)
   local p = split(params);
   local conn = colloquy.connections[connection];

   if (p[1] == nil) then
      sendGM(conn, S_ERROR, "cguestUsage");
      return nil;
   end;

   local u = userByName(p[1]);
   if (type(u) == "string") then
     send(u, conn, S_ERROR);
     return nil;
   end;

   if (u == nil) then
     sendGM(conn, S_ERROR, "UnknownUser", p[1]);
     return nil;
   end;

   if (u.status ~= 1) then
     sendGM(conn, S_ERROR, "cguestAlready", u.username);
     return nil;
   end;

   if (users.guest == nil) then
     sendGM(conn, S_ERROR, "cguestNoGuest");
     return nil;
   end;

   u.status = 2;
   u.realUser = "guest"

   sendGMAll(S_LOGIN, "cguestDone", u.username, conn.username);
   log(format("MG %s[%s] guests %s[%s]", conn.username, conn.realUser, u.username, u.realUser));
end;

function commandObserve(connection, line, params)
  local p = split(params);
  local conn = colloquy.connections[connection];

  if not p[1] then
    -- emit a list of groups they're observing.
    if not conn.observing then
      sendGM(conn, S_ERROR, "cobserveNone")
    else
      sendGM(conn, S_DONE, "cobserveList", observedGet(conn))
    end
    return
  end

  local g, e = groupByName(p[1])

  if not g then
    send(e, conn, S_ERROR)
    return
  end

  local o = conn.observing
  if o and o[strlower(g)] then
    sendGM(conn, S_ERROR, "cobserveAlready", g)
    return
  end

  if (colloquy.lockedGroups[strlower(g)]) then
    if not (checkInvitation(conn, "@" .. strlower(g))) then
      if not strfind(conn.privs or "", "M", 1, 1) then
        sendGM(conn, S_ERROR, "cgroupLocked", g)
        return
      end
    end
  end

  observingStart(conn, g)
  sendGM(conn, S_DONE, "cobserveStart", g)

  if p[2] == "silently" and strfind(conn.privs or "", "M", 1, 1) then
    return
  end

  sendGMGroup(g, S_DONE, "cobserveDone", conn.username)

end;

function commandDisregard(connection, line, params)
  local p = split(params)
  local conn = colloquy.connections[connection]

  if not p[1] then
    sendGM(conn, S_ERROR, "cdisregardUsage")
    return
  end

  local g, e = groupByName(p[1])

  if not g then
    send(e, conn, S_ERROR)
    return
  end

  local o = conn.observing
  if not (o and o[strlower(g)]) then
    sendGM(conn, S_ERROR, "cdisregardAlready", g)
    return
  end

  observingStop(conn, g)
  sendGM(conn, S_DONE, "cdisregardFinished", g)

  if p[2] == "silently" and strfind(conn.privs or "", "M", 1, 1) then
    return
  end

  sendGMGroup(g, S_DONE, "cdisregardDone", conn.username)

end

function commandSwap(connection, line, params)
  local p = split(params)
  local conn = colloquy.connections[connection]

  if not p[1] or not p[2] then
    sendGM(conn, S_ERROR, "cswapUsage")
    return
  end

  local u = userByName(p[1])
  if (u == nil) then
    sendGM(conn, S_ERROR, "cswapNoUser", p[1])
    return
  elseif (type(u) == "string") then
    send(u, conn, S_ERROR)
    return
  elseif (u.status < 2) then
    sendGM(conn, S_ERROR, "cswapNoPassword")
    return
  end

  local pr, message = checkPassword(strlower(u.realUser), p[2])
  if (not pr) then
    send(message or "Incorrect password.", conn, S_ERROR)
    log(format("!S Incorrect password by %s[%s] for swapping to %s[%s].", conn.username, conn.realUser or "guest", u.username, u.realUser))
    return
  end

  conn.socket, u.socket = u.socket, conn.socket
  colloquy.connections[conn.socket.socket], colloquy.connections[u.socket.socket] = conn, u

  conn.site, u.site = u.site, conn.site
  conn.via, u.via = u.via, conn.via

  local swapper = conn.username

  if not swapper or swapper == "" then
    swapper = "user at login prompt"
  end

  lastUser = conn.username
  lastConnection = conn
  
  sendGM(conn, S_DONE, "cswapSwapped", swapper)
  sendGM(u, S_DONE, "cswapSwapped", u.username or "(guest)")

end

function commandXyzzy(connection, line, params)
   send("Nothing happens.", colloquy.connections[connection], S_ERROR);
end;

--------------------------------------------------------------------------------------------------------------------------
function allowAll(connection)
   return 1;
end;

function allowConn(connection)
  return colloquy.connections[connection].status > 0;
end;

function allow(connection, p)
   if (colloquy.connections[connection].privs == nil) then return nil end;
   return strfind(colloquy.connections[connection].privs, p, 1, 1);
end;

function allowUsers(connection)
   return colloquy.connections[connection].status > 1;
end;

function allowA(connection)
   return allow(connection, "A");
end;

function allowB(connection)
   return allow(connection, "B");
end;

function allowC(connection)
   return allow(connection, "C");
end;

function allowF(connection)
   return allow(connection, "F");
end;

function allowG(connection)
   return allow(connection, "G");
end;

function allowH(connection)
   return allow(connection, "H");
end;

function allowI(connection)
   return allow(connection, "I");
end;

function allowK(connection)
   return allow(connection, "K");
end;

function allowL(connection)
   return allow(connection, "L");
end;

function allowM(connection)
   return allow(connection, "M");
end;

function allowN(connection)
   return allow(connection, "N");
end;

function allowO(connection)
   return allow(connection, "O");
end;

function allowS(connection)
   return allow(connection, "S");
end;

function allowU(connection)
   return allow(connection, "U");
end;

function allowW(connection)
   return allow(connection, "W");
end;

function allowZ(connection)
   return allow(connection, "Z");
end;

function isBot(connection)
  if (not colloquy.connections[connection].restrict) then return nil end;
  return strfind(colloquy.connections[connection].restrict, "B", 1, 1);
end;

setCommands = {};
tinsert(setCommands, { name = "cr", code = setCR });
tinsert(setCommands, { name = "beep", code = setBeep });
tinsert(setCommands, { name = "timewarn", code = setTimewarn });
tinsert(setCommands, { name = "prompts", code = setPrompts });
tinsert(setCommands, { name = "privs", code = setPrivs });
tinsert(setCommands, { name = "term", code = setTerm });
tinsert(setCommands, { name = "echo", code = setEcho });
tinsert(setCommands, { name = "colour", code = setColour });
tinsert(setCommands, { name = "info", code = setInfo });
tinsert(setCommands, { name = "shouts", code = setHeard });
tinsert(setCommands, { name = "messages", code = setHeard });
tinsert(setCommands, { name = "lists", code = setHeard });
tinsert(setCommands, { name = "idling", code = setHeard });
tinsert(setCommands, { name = "idleprompt", code = setIdlePrompt });
tinsert(setCommands, { name = "width", code = setWidth });
tinsert(setCommands, { name = "strip", code = setStrip });
tinsert(setCommands, { name = "language", code = setLanguage });
