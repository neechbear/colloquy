-- handles connections (searches, removes, adds etc)

connections = 1;

function dumpString(s)
  local c, cb;
  for i = 1, strlen(s) do
    c = strsub(s, i, i)
    cb = strbyte(c)
    if(cb < 32 or cb > 126) then
      write("(" .. cb .. ")")
    else
      write(c)
    end
  end
  write("\n");
end

function daytime()
  local void, void, dtStart, dtEnd = strfind(colloquy.daytime, "(%d+)%D+(%d+)")
  if not dtStart then
    return nil
  end

  dtStart, dtEnd = tonumber(dtStart), tonumber(dtEnd);
  local ct = tonumber(date("%H%M"))
  if ct >= dtStart and ct <= dtEnd then
    return 1;
  else
    return nil;
  end;
end

function enum(s)
   for i, v in s do
      setglobal(i, v);
   end;
end;

function connection(v)
   if (type(v) == "string") then
      local u, i, v = strlower(v);
      for i, v in colloquy.connections do
        if (i ~= "n" and strlower(v.username) == u) then return v end;
      end;
      return nil;
   elseif (type(v) == "table") then
      return colloquy.connections[v];
   end;
end;

function allowed(v, thing)
   local t = type(thing);
   if (t == "string" or t == "number" or t == "table") then
      return thing;
   elseif (t == "function") then
      thing(v);
   end;
end;

function equal(s, t)
   for i, v in t do
     if (v == s and i ~= "n") then return 1 end;
   end;
end;

function buildSocketReaders()
  local n, i, v, r = 3;
  r = { colloquy.server, colloquy.resolver.socket };
  
  if (colloquy.botServer) then tinsert(r, colloquy.botServer); n = n + 1; end;
  if (colloquy.metaServer) then tinsert(r, colloquy.metaServer); n = n + 1; end;

  for i, v in colloquy.connections do
    if (not v.socket.toClose) then r[n] = i; n = n + 1 end;
  end;
  colloquy.readingSockets = r;
end;

function parseTelnetOpts(line, conn)
  local r;
  local index;
  index = 1;
  repeat
    if (strlen(line) < index) then
      -- something's gone wrong.  Return nothing.
      return "";
    end
    if (strbyte(line, index) == 255) then
      index = index + 1;
      if (strbyte(line, index) == 251) then
        -- client WILL
      elseif (strbyte(line, index) == 253) then
        -- client DO
        index = index + 2;
        if (index <= strlen(line) and strbyte(line, index) ~= 255) then
          return strsub(line, index, -1);
        end;
      elseif (strbyte(line, index) == 240) then
        -- client SE (Send END ?)
        index = index + 2;
        if (index <= strlen(line) and strbyte(line, index) ~= 255) then
          return strsub(line, index, -1);
        end;
      elseif (strbyte(line, index) == 250) then
        index = index + 1;
        -- client SB
        if (strbyte(line, index) == 31) then
          index = index + 1;
          if (strfind(conn.flags, "W") and (conn.termType == "colour")) then
            -- client sent us the screen size
            local newWidth =  strbyte(line, index) * 256 + strbyte(line, index+1)-1;
            if (conn.width ~= newWidth) then
              conn.width = newWidth;
            end;
            index = index + 4;
          end;
        end;
      end;
    else
      return line;
    end;

    while (index <= strlen(line) and strbyte(line, index) ~= 255) do
      index = index + 1;
    end; 
  until (index >= strlen(line));

  return "";
end;

function createPrompt(connection)
  local colour, thing, suffix;
  if (connection.query) then
    thing = strsub(connection.query.format, 2, -1);
    suffix = strsub(connection.query.format, 1, 1);
  else
    thing = connection.username;
    suffix = ":";
  end;

  if connection.status > 1 then
    local idlePrompt = users[strlower(connection.realUser)].idlePrompt
    if (connection.veryIdle and idlePrompt) then
      thing = idlePrompt;
    end
  end

  if (connection.termType == "colour") then
    if (suffix == ">" or suffix == "@") then
      colour = getColour(connection, "tell");
      suffix = suffix .. attrib(chattr.reset);
    elseif (suffix == "%") then
      colour = getColour(connection, "list");
      suffix = suffix .. attrib(chattr.reset);
    else 
      colour = attrib(chattr.reset);
      suffix = suffix .. attrib(chattr.reset);
    end;  
  else
    colour = "";
  end;
  return colour .. strsub(thing .. strrep(" ", 11), 1, 12) .. suffix .. "\255\239"
end;

function makeHashKey(t)
  local r = {}
  for i, v in t do
    r[v] = v
  end
  return r
end

local mLists = makeHashKey {
  S_LISTTALK, S_LISTEMOTE, S_LISTINFO, S_LISTDELETE, S_LISTJOIN, S_LISTLEAVE, S_LISTINVITE,
  S_LISTOWNER, S_LISTLOCK, S_LISTUNLOCK }

local mTalk = makeHashKey {
  S_TALK, S_EMOTE, S_PEMOTE, S_TELL, S_SHOUT, S_MULTITELL, S_REMOTE, S_LISTTALK, S_LISTEMOTE }
  
local mGeneral = makeHashKey {
   S_ERROR, S_EXAMINE, S_INFO, S_INFOHDR, S_INFOLIST, S_DONE, S_MARK, S_NAME, S_TALKERLOCK,
   S_TALKERUNLOCK, S_DISCONNECT, S_CONNECTWARN, S_GAG, S_UNGAG, S_ALERT, S_WARN, S_DONETELL,
   S_COMMENT, S_IDLE, S_LOOK, S_WAKE, S_EVICT, S_LISTINFO, S_LISTDELETE, S_LISTJOIN,
   S_LISTLEAVE, S_LISTINVITE, S_LISTOWNER, S_LISTS,  S_LISTSHDR, S_LISTDESC, S_QUIT,
   S_LISTLOCK, S_LISTUNLOCK, S_LISTOPEN, S_LISTCLOSE, S_LISTEVICT, S_LISTPERM, S_LISTUNPERM,
   S_LISTRENAME, S_LISTANON, S_LISTUNANON, S_LISTREAD, S_LISTUNREAD, S_LISTMASTER,
   S_LISTUNMASTER, S_INVITE, S_BOTHDR, S_BOT, S_GROUPGONE }

local mGeneral2 = makeHashKey {
  S_GROUPLIST, S_GROUPS, S_LOOK, S_HELP, S_CONNECT, S_DISCONNECT, S_LOGIN }

function formatMessage(connection, message, type, observeGroup)
  local equal = equal

  if (type == S_SHOUT and strfind(connection.flags, "s", 1, 1)) then
    return nil; -- don't want to hear shouting
  end;

  if (!{type S_CONNECT S_DISCONNECT S_CONNECTWARN}) and strfind(connection.flags, "m", 1, 1) then
    return nil; -- don't want to hear connection/disconnection messages
  end;

  if (%mLists[type]) and strfind(connection.flags, "l", 1, 1) then
    return nil; -- don't want to hear lists
  end;

  if (type == S_RAW) then
    if (connection.termType == "client") then
      return S_RAW .. " " .. message;
    else
      return message;
    end;
  end;

  local c = "";
  local f = "";

  local name, tmp;
  tmp, tmp, name = strfind(message, "^(%w*)");

  if (connection.termType == "colour") then
    f = attrib(chattr.reset);
    if (type == S_SHOUT) then
      c = getColour(connection, "shout");
    elseif (type == S_TALK or type == S_EMOTE) then
      c = getColour(connection, "talk");
    elseif (type == S_TELL or type == S_DONETELL or type == S_MULTITELL or type == "REMOTE") then
      c = getColour(connection, "tell");
    elseif (type == S_LISTTALK or type == S_LISTEMOTE) then
      c = getColour(connection, "list");
    else
      c = getColour(connection, "message");
    end;
  end;
  if (connection.termType == "client") then
    message = type .. " " .. message;
    if (observeGroup) then
      message = "OBSERVED " .. observeGroup .. " " .. message;
    end
  else
    if (type == S_SHOUT or type == S_WAKE or type == S_CONNECT) and strfind(connection.flags, "B") then
      message = format("\a") .. message;
    end;

    if (%mTalk[type]) then
      if (connection.noWrap == nil) then
        message = (WordWrap(message, indents[type], "", connection.width, (connection.width - indents[type]) / 2 ))
      else
        message = strchar(13) .. message;
      end
    elseif (!{type S_LOOKHDR S_GROUP S_GNAME S_GROUPSHDR S_STATS S_TIME S_WHO S_WHOHDR}) then
      if (connection.noWrap) then
        message = "+++ " .. message;
      else
         message = (WordWrap("+++ " .. message, indents[type], "", connection.width, (connection.width - indents[type] / 2)))
      end;
    elseif (%mGeneral[type]) then
      if (connection.noWrap) then
        message = "+++ " .. message;
      else
        message = (WordWrap("" .. message, indents[type], "+++", connection.width, (connection.width - indents[type]) / 2))
      end;

    elseif (%mGeneral2[type]) then
      if (connection.noWrap) then
        message = "+++ " .. message;
      else
        message = (WordWrap("" .. message, indents[type], "+++", connection.width, (connection.width - indents[type]) / 2))
      end;
    end;
  end;

  if ( connection.termType == "colour" and (connection.username == name) and (!{type S_TALK S_EMOTE S_PEMOTE})) then
    message = getColour(connection, "me") .. name .. getColour(connection, "talk") .. strsub(message, strlen(name) + 2, -1);
  end

  if ( connection.termType == "colour" and (connection.username ~= name) and (!{type S_TALK S_EMOTE S_PEMOTE})) then
    local n = {};
    local m = strlower(message);
    if (connection.aliases ~= nil and connection.aliases ~= "") then
      n = split(connection.aliases);
    end;

    tinsert(n, strlower(connection.username));
    if (connection.realuser ~= nil and (strlower(connection.username) ~= strlower(connection.realUser))) then
      tinsert(n, strlower(connection.realuser));
    end;

    local i, v;
    for i, v in n do
      if (i ~= "n") then
        if (strfind(m .. " ", "%W" .. v .. "%W")) then
          message = getColour(connection, "nick") .. name .. getColour(connection, "talk") .. strsub(message, strlen(name) + 2, -1);
          break;
        end;
      end;
    end;
  end;
  
  if ( connection.termType == "colour" and (connection.username ~= lastUser) and (type == S_LISTTALK or type == S_LISTEMOTE)) then
    local n = {};
    local m = strlower(message);
    if (connection.aliases ~= nil and connection.aliases ~= "") then
      n = split(connection.aliases);
    end;

    tinsert(n, strlower(connection.username));
    if (connection.realuser ~= nil and (strlower(connection.username) ~= strlower(connection.realUser))) then
      tinsert(n, strlower(connection.realuser));
    end;

    local i, v;
    for i, v in n do
      if (i ~= "n") then
        if (strfind(m .. " ", "%W" .. v .. "%W")) then

          if (type == S_LISTTALK) then
            message = getColour(connection, "nick") .. name .. getColour(connection, "list") .. strsub(message, strlen(name) + 2, -1);
          elseif (type == S_LISTEMOTE) then
            name = strsub(message, 4, 3 + strlen(lastUser));
            message = strsub(message, 3 + strlen(lastUser) + 1, -1);
            message = "% " .. getColour(connection, "nick") .. name .. getColour(connection, "list") .. message;
          end;
          break;
        end;
      end;
    end;
  end;

  if connection.termType == "colour" and ((%mLists[type]) or (!{type S_TALK S_EMOTE S_REMOTE} and observeGroup)) then
     -- this is a list thingy.  colourise the list name.
     
     local lStart, lEnd, lName = strfind(message, "(%{[^%{%}]-%})$");
     if (lStart) then
       message = strsub(message, 1, lStart - 1) .. getColour(connection, "listname") .. lName;
     end;
  end;

  if (connection.termType == "colour") then
    message = c .. message .. f;
  end;

  return message;
   
end;

function saveUser(v, dis)
  -- saves connection v.  if dis is set, this is because of a disconnection.
  local conn = colloquy.connections[v];

  local u = strlower(conn.realUser);
  local i, f;
  for i, f in users do
   if (i == u) then
     if (not f.timeon) then f.timeon = 0 end;
     f.timeon = f.timeon + secs - (conn.conTime);
     f.flags = conn.flags;
     f.termType = conn.termType;
     f.colours = conn.colours;
     f.restrict = conn.restrict;
     f.timeWarn = conn.timeWarn;
     f.width = conn.width;
     f.noWrap = conn.noWrap;
     conn.totalIdle = conn.totalIdle + (secs - conn.idle);
     if (not f.totalIdle) then
       f.totalIdle = 0;
     end;
     f.totalIdle = f.totalIdle + conn.totalIdle;
     if (not f.talkBytes) then
       f.talkBytes = 0;
     end;
     f.talkBytes = f.talkBytes + conn.talkBytes;
     f.lang = conn.lang.NAME;
     
     if (dis) then
       f.lastQuit = dis;
       f.lastSite = conn.site;
       f.lastLogon = conn.onSince .. " - " ..date("%a %b %e %H:%M:%S %Y");
       f.connected = nil;
     end;

     conn.conTime = secs;
     conn.totalIdle = 0;
     conn.talkBytes = 0;
   end;
 end;
 saveOneUser(u);
end;

function disconnectUser(v, message, relogin)

   local conn = colloquy.connections[v];

   if (not relogin) then
     conn.socket.toClose = 1;
     local oldGroup = conn.group;
     conn.group = "";
     checkGroupToUnlock(oldGroup);
   end;

   if (conn.status > 0 and not relogin) then
     if (not conn.invis) then
       local ud = users[strlower(conn.realUser)]
       local qm = conn.username .. " has disconnected! "
       if ud and ud.quitmsg then
         qm = ud.quitmsg .. " " .. message;
         sendToAllBut(conn, qm, S_DISCONNECT)
       else
         sendGMAllBut(conn, S_DISCONNECT, "gDisconnect", conn.username, message)
       end
     else
       local i, j;
       for i, j in colloquy.connections do
         if (i ~= "n") then
           if (j.privs ~= nil and j.privs ~= "" and strfind(j.privs, "M", 1, 1)) then
             send(conn.username .. " has (invisibly) disconnected!", j, S_DISCONNECT);
             sendGM(j, S_DISCONNECT, "gInvisDisconnect", conn.username, message)
           end;
         end;
       end;
      end;
      log(format("-  %s[%s] %s", conn.username, conn.realUser, message));
   end;

   if conn.status > 1 then saveUser(v, message) end;

   if (not relogin) then
     conn.status = 0;
   end;

   buildSocketReaders();
   
end;

goo = 1; -- set to 0 for spam debug

function connectUser(bot)
   local r, s;
   
   if (bot == 1) then
     s = clientSocket:accept(colloquy.botServer);
   elseif (bot == 2) then
     s = clientSocket:accept(colloquy.metaServer);
   else
     s = clientSocket:accept(colloquy.server);
   end;
   
   if (not s) then return nil end;

   local peer = getpeername(s.socket);
   local OK = nil;
   if (bot == 2) then
     for i, v in colloquy.metaOK do
       if v == peer then
         OK = 1;
         break;
       end;
     end;

     if (not OK) then
       s:close();
       return nil;
     end;
   end;


   resolve(getpeername(s.socket));
   
   r = {
      socket = s,
      username = "",
      realUser = "",
      status = 0,
      site = getpeername(s.socket),
      group = "", 
      privs = "",
      restrict = "",
      width = 79,
      flags = "CeBpSMLwI", -- default to CR on, Echo off, Beep on, Prompts off, Shouts on, Messages on, Lists on, auto width off, idling messages on
      termType = "dumb",
      --colours = "talk='white',tell='green',list='brblue',listname='brblue',shout='brred',message='brwhite',nick='bryellow',talkback='none',tellback='none',listback='none',listnameback='none',shoutback='none',messageback='none',nickback='red',",
      colours = "!talk!white:none!tell!green:none!list!brblue:none!listname!bryellow:none!shout!brred:none!message!brwhite:none!nick!bryellow:red!me!brwhite:none",
      idle = secs,
      timeWarn = 0,
      timeTick = 0,
      totalIdle = 0,
      aliases = "",
      talkBytes = 0,
      lang = getlang(colloquy.lang),
   };
   
   if (bot == 1) then
     r.termType = "client";
     r.bot = 1;
   end;

   if (bot == 2) then
     r.via = peer;
     r.site = nil;
   end;

   colloquy.connections[r.socket.socket] = r;
   buildSocketReaders();
   if (bot == 1) then
     send("colloquy " .. colloquy.version .. " (" .. colloquy.date .. ")", r, S_HELLO);
   else
     sendFile(colloquy.welcome, {r});
   end;

end;

function sendGMGroup(group, tag, token, ...)
  local t;
  for i, v in getGroupMembers(group) do
    if (i ~= "n") then
      t = { v, tag, token };
      for i=1,getn(arg) do
        tinsert(t, arg[i]);
      end
      call(sendGM, t);
    end
  end
end

function sendGMList(list, tag, token, ...)
  tag = tag or S_TALK;
  tinsert(arg, 1, token)
  tinsert(arg, 1, getlang(colloquy.lang))
  tinsert(arg, 1, "")
  for i, v in list do
    if type(v) == "table" then
      arg[1] = v.lang
      send(call(getmsg, arg), v, tag)
    end
  end
end

function sendGMAll(tag, token, ...)
  tag = tag or S_TALK;
  tinsert(arg, 1, token);
  tinsert(arg, 1, getlang(colloquy.lang));
  tinsert(arg, 1, "");
  for i, v in colloquy.connections do
    if (v.status > 0) then
      arg[1] = v.lang;
      send(call(getmsg, arg), v, tag);
    end
  end;
end

function sendGMAllBut(conn, tag, token, ...)
  tinsert(arg, 1, token)
  tinsert(arg, 1, tag)
  tinsert(arg, 1, "")
  for i, v in colloquy.connections do
    if v ~= conn then
      arg[1] = v
      call(sendGM, arg)
    end
  end
end

function sendGM(conn, tag, token, ...)
  tinsert(arg, 1, token)
  tinsert(arg, 1, getlang(colloquy.lang))
  tinsert(arg, 1, conn.lang)
  token = call(getmsg, arg)
  send(token, conn, tag)
end

function sendToAllBut(conn, string, type)
  local i, v, t;

  if (type == nil) then type = S_TALK end;
    t = {};
    for i, v in colloquy.connections do
      if (v.status > 0 and v ~= conn) then
        tinsert(t, v);
      end;
   end;
   
   sendTo(string, t, type);
end;

function sendToAll(string, type)
  return sendToAllBut(nil, string, type)
end;

function sendBy(string, type, func)
   local i, v;

   for i, v in colloquy.connections do
      if (func(v)) then
        send(string, v, type)
      end;
   end;
end;

function send(string, who, t, observation)
   -- like the following, but only to one connection.
   
   if (who.ignoring and who.ignoring[lastConnection]) then
     return nil;
   end;

   if who.inspectors then for i, v in who.inspectors do
     if (type(v) == "table") then
       sendGM(v, S_DONE, "cinspectReceive", who.username, string);
     end;
   end end;

   local s;
   
   if (t == nil) then type = S_TALK end;
   
   s = formatMessage(who, string, t, observation);
   if (s) then
     s = s .. "\r\n";
     if (who.flags and strfind(who.flags, "c", 1, 1)) then s = gsub(s, "\r", ""); end;
   
     who.socket:send(s);
   
     dataSent = dataSent + strlen(s);
   else
     who.socket:send("");
   end;

end;

function sendTo(string, who, type)
  local i, v;
   
  if (type == nil) then type = S_TALK end;
   
  for i,v in who do
    if (i ~= "n") then
      send(string, v, type);
    end;
 end;
end;

function sendFile(filename, sockets)
   local i, v, f, l, t;
   
   f = openfile(filename, "r");
   if (not f) then return nil end;

   t = getn(sockets);

   repeat
     l = read(f);

     if (l) then
      for i, v in sockets do
        send(l, v, S_RAW);
      end;
      dataSent = dataSent + (strlen(l) * t);
    end;
  until (l == nil);

end;

function sendToGroup(string, group, type)
   local i, v, s;

   if (type == nil) then type = S_TALK end;
   sendTo(string, getGroupMembers(group), type);
end;

function sendToObservers(string, group, type)
  local o = observersGet(group)
  if not o then return end
  for i, v in o do
    if i ~= "n" then
      send(string, v, type, group)
    end
  end
end

function getGroupMembers(group)
   local t, i, v = {};
   
   group = strupper(group)
   for i, v in colloquy.connections do
      if (group == strupper(v.group)) then
        tinsert(t, v);
      end;
   end;

   return t;
end;

function crypt(string)
   return gsub(md5(string), "(.)", function(v) return format("%02x", strbyte(v)) end);
end;

function split(string)
   local t = {};
   local splitFunction = function(v)
     if (strlen(v) > 0) then
       tinsert(%t, v);
     end;
   end;

   gsub(string, " *([^ ]+) *", splitFunction);
   return t;
end;

function esplit(string, sep)
  local t = {}
  local splitFunction = function(v)
    if (strlen(v) > 0) then
      tinsert(%t, v);
    end;
  end;
  local pattern = gsub(" *([^ ]+) *", " ", sep);

  gsub(string, pattern, splitFunction);
  return t;
end;

function userLogon(connection, string)

   if (string == nil) then
     return nil;
   end;

   local z, l;
   l = strlen(string);

   string = gsub(string, "[^\32-\126]", "");

   local params = split(string);
   local i, v, u, p, f, invis, initialGroup;
   local conn = colloquy.connections[connection];
   local currentGuests = 0;

   for i, v in colloquy.connections do
     if v.status == 1 then
       currentGuests = currentGuests + 1;
     end;
   end;
   
   -- check if they even typed something...
   if (getn(params) == 0) then return nil end;

   if (conn.via and not conn.site) then
     -- they're connecting via proxy
     if (params[1] == colloquy.metaPassword) then
       conn.site = params[2];
       resolve(params[2]);
       return nil;
     else
       return nil;
     end;
   end;

   if (strsub(params[1], 1, 1) == "*") then
      f = 1;
      params[1] = strsub(params[1], 2, strlen(params[1]));
   else
      f = nil;
   end;

   if (strsub(params[1], 1, 1) == "_") then
      invis = 1;
      params[1] = strsub(params[1], 2, strlen(params[1]));
   else
      invis = nil;
   end;

   if (strfind(params[1], "@", 1, 1)) then
     -- they have an initial group preference...
     initialGroup = strsub(params[1], strfind(params[1], "@", 1, 1) + 1, -1);
     
     if (strlen(initialGroup) > 15) then
       initialGroup = strsub(initialGroup, 1, 15);
     end;
     
     if (strlen(initialGroup) < 1) then
       initialGroup = "Public";
     end;
     
     if (colloquy.lockedGroups[strlower(initialGroup)]) then
       conn.socket:send("+++ Your initial group is locked.  Please select another.\r\n");
       return nil;
     end;  
     
     if (strfind(initialGroup, "[%s,@%%]")) then
       conn.socket:send("+++ Your initial group has an invalid name.  Please select another.\r\n");
       return nil;
     end;

     params[1] = strsub(params[1], 1, strfind(params[1], "@", 1, 1) - 1);
   else
     initialGroup = "Public";
   end;

--   -- check if the name is at all valid...
--   for i=1,strlen(punctuation) do
--     if (strfind(params[1], strsub(punctuation, i, i), 1, 1)) then
--       conn.socket:send("+++ Invalid user name.\r\n");
--       return nil;
--     end;
--   end;

----------------------------------
-- nicolaw 2006-05-31
   -- check if the name is at all valid...
   for i=1,strlen("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") do
     if (strfind(params[1], strsub(punctuation, i, i), 1, 1)) then
       conn.socket:send("+++ Invalid user name.\r\n");
       return nil;
     end;
   end;
-- nicolaw 2006-05-31
----------------------------------

   if (strlen(params[1]) < 1) then
     conn.socket:send("+++ Invalid user name.\r\n");
     return nil;
   end;

   -- check if they want a name longer than 10 characters...
   if (strlen(params[1]) > 10 and colloquy.defAuthenticator == nil) then
      conn.socket:send("+++ Name is more than 10 characters.\r\n");
      return nil;
   end;

   -- check if the name belongs to somebody else connected...

   u = strupper(params[1]);
   
   local oldUser = nil;

   for i, v in colloquy.connections do
      if (v.status > 0) then
        if (strupper(v.username) == u) then
          if (not f) then
            conn.socket:send("+++ Name is already in use. Use * before your name to force on.\r\n");
            return nil;
          else
            if (f and v.status > 1) then
              oldUser = i;
            elseif (f) then
              conn.socket:send("+++ Name is already in use by another guest. Please select another.\r\n");
              return nil;
            end;
          end;
        end;
      end;
   end;

   if (params[2] == nil) then
      -- check if the username is one of a registered user.
      for i, v in users do
        if (strupper(i) == u) then
          conn.socket:send("+++ That name is used by someone with an account. Either supply\r\n");
          conn.socket:send("+++ the password, or choose another name.\r\n");
          return nil;
        end;
      end;

      if (colloquy.locked ~= nil) then
        conn.socket:send("+++ Sorry, but the talker is currently locked to guests.\r\n");
        return nil;
      end;

      if (colloquy.maxGuests and currentGuests >= colloquy.maxGuests) then
        conn.socket:send("+++ Sorry, the maximum number of guests has been reached. Please try again later.\r\n");
        return nil;
      end

      local b = isBanned(conn.site);      
      
      if (b) then
        conn.socket:send("+++ Sorry, guests from your site have been banned: " .. b.reason .. "\r\n");
        return nil;
      end;

   else
      -- check their password...
      if (users[strlower(u)] == nil) then
        if (colloquy.defAuthenticator) then
          local userNameCropped;
          local thisauthenticator = u.."@"..colloquy.defAuthenticator;
          local pr, message = checkPasswordWithAuthenticator(thisauthenticator, u, params[2]);
          if (not pr) then
            conn.socket:send("+++ No such user.\r\n");
            return nil;
          end;

          if (strlen(u) > 10) then
            userNameCropped = 1;
            -- as we use u and params[1] again, we need to alter both
            u = strsub(u, 1, 10);
            params[1] = strsub(params[1], 1, 10);
          end;

          -- make a default user, as the user authenticated, but doesn't have an account          
          log(format("U  %s created automatically with authenticator %s", u, thisauthenticator));
          users[strlower(u)] = {
            authenticator = thisauthenticator,
            created = date() .. " by authenticator automatically.",
            flags = "",
            restrict = "",
            password2 = crypt(strlower(u) .. u)
          };
          saveUsers(u);
          conn.socket:send("+++ User authenticated, account created.\r\n");
          if (userNameCropped == 1) then
            conn.socket:send(format("+++ Your username was too long, reduced to %s.\r\n+++ You may wish to be renamed by a master.\r\n", strlower(u)));
          end;
        else
          conn.socket:send("+++ No such user.\r\n");
          return nil;
        end;
      end;

      local pr, message = checkPassword(u, params[2]);
      if (not pr) then
        users[strlower(u)].failed = (users[strlower(u)].failed or 0) + 1;
        conn.socket:send("+++ " .. (message or "Incorrect password.") .. "\r\n");
        log(format("!+ Authentication for %s failed (%s) from %s.", params[1], message or "incorrect password", conn.site));
        return nil;
      end;
   end;

   if (params[2] and users[strlower(u)].banned ~= nil and users[strlower(u)].banned ~= "") then
      conn.socket:send("+++ You have been banned: " .. users[strlower(u)].banned .. "\r\n");
      log(format("!+ Banned user %s attempted to log in from %s.", params[1], conn.site));
      return nil;
   end;
   
   if (params[2] and not conn.bot and users[strlower(u)].restrict and strfind(users[strlower(u)].restrict, "B", 1, 1)) then
     conn.socket:send("+++ Bots are not allowed to connect to this port.  Talk to a master.\r\n");
     return nil;
   end;

   if (f and oldUser) then
      send("Sorry, you have been forced off.", colloquy.connections[oldUser], S_ERROR);
      disconnectUser(oldUser, "- Forced off.");
   end;

   if (invis) then
      if (users[strlower(u)] == nil or users[strlower(u)].privs == nil or strfind(users[strlower(u)].privs, "I") == nil) then
        conn.socket:send("+++ You do not have sufficient privilege.\r\n");
        return nil;
      end;
   end;

   local currentUsers = 0;

   if colloquy.daytimeMax and daytime() then
     if not (users[strlower(u)] and strfind(users[strlower(u)].privs or "", "Z", 1, 1)) then
       for i, v in colloquy.connections do
         if v.status > 0 then
           currentUsers = currentUsers + 1;
         end;
       end
       if currentUsers >= colloquy.daytimeMax then
         conn.socket:send("+++ Too many people are logged on.  Please try again later.\r\n");
         return nil;
       end;
     end;
   end;

   if colloquy.nighttimeMax and not daytime() then
     if not (users[strlower(u)] and strfind(users[strlower(u)].privs or "", "Z", 1, 1)) then
       for i, v in colloquy.connections do
         if v.status > 0 then
           currentUsers = currentUsers + 1;
         end
       end
       if currentUsers >= colloquy.nighttimeMax then
         conn.socket:send("+++ Too many people are logged on.  Please try again later.\r\n");
         return nil;
       end;
     end;
   end;

   u = users[strlower(u)];

   if (u and u.restrict and strfind(u.restrict, "B", 1, 1)) then
     -- This user is a bot - force them to log in to Bots-R-Us, and make them log on invisibly.
     initialGroup = "Bots-R-Us";
     invis = 1;
   end;

   local birthday = ".";
   if (u and u.birthday ~= nil) then
     if (date("%m-%d") == strsub(u.birthday, 6, -1)) then
       birthday = " - BIRTHDAY!";
     end;
   end;
   if (not invis) then
      local i, v, s, s2, g;
      local guest = " (Guest)";
      if (u) then
        guest = "";
      end;
      g = strlower(initialGroup);
      for i, v in colloquy.connections do
        if (type(v) == "table" and (v.status > 0)) then
          if (strlower(v.group) ~= g) then
            sendGM(v, S_CONNECT, "gConnectGroup", params[1], y(guest~="", gm(v, "gConnectGuest"), ""), 
                                                  conn.site, initialGroup, y(birthday==".", ".", gm(v, "gConnectBirthday")))
          else
            sendGM(v, S_CONNECT, "gConnect", params[1], y(guest~="", gm(v, "gConnectGuest"), ""),
                                             conn.site, y(birthday==".", ".", gm(v, "gConnectBirthday")))
          end;
         end;
      end;

      --sendToAll(params[1] .. " has connected from " .. conn.site .. " in group " .. initialGroup .. ".", S_CONNECT);
   else
      local i, v;
      for i, v in colloquy.connections do
        if (i ~= "n") then
          if (v.privs ~= nil and v.privs ~= "" and strfind(v.privs, "M", 1, 1)) then
             sendGM(v, S_CONNECT, "gInvisConnect", params[1], conn.site, initialGroup, y(birthday==".", ".", gm(v, "gConnectBirthday")))
          end;
        end;
       end;
      end;

   conn.username = params[1];
   conn.realUser = params[1];
   conn.status = 1;
   conn.group = initialGroup;
   conn.onSince = date("%a %b %e %H:%M:%S %Y");
   conn.conTime = secs;
   conn.invis = invis;
   if (u and u.restrict and strfind(u.restrict, "B", 1, 1)) then
     conn.invis = nil;
   end;
   conn.c = 1;

   if (params[2] ~= nil) then
      -- registered user - fill in the other bits...
      conn.privs = u.privs;
      if (u.flags) then conn.flags = u.flags; end;
      if not strfind(conn.flags, "[iI]") then
        conn.flags = conn.flags .. "I"
      end
      if (u.termType) then conn.termType = u.termType end;
      migrateColours(strlower(params[1]));
      if (u.colours) then conn.colours = u.colours end;
      if (u.restrict) then conn.restrict = u.restrict end;
      if (u.timeWarn) then conn.timeWarn = u.timeWarn end;
      if (u.aliases) then conn.aliases = u.aliases end;
      if (u.width) then conn.width = u.width end;
      if (u.noWrap) then conn.noWrap = u.noWrap end;
      if (u.lang) then conn.lang = getlang(u.lang) or getlang(colloquy.lang) end;
      u.connected = conn.conTime;
      conn.status = 2;

      if (not strfind(conn.flags, "[Cc]")) then conn.flags = conn.flags .. "C" end;
      if (not strfind(conn.flags, "[Ee]")) then conn.flags = conn.flags .. "e" end;
      if (not strfind(conn.flags, "[Bb]")) then conn.flags = conn.flags .. "B" end;
      if (not strfind(conn.flags, "[Pp]")) then conn.flags = conn.flags .. "p" end;
      if (not strfind(conn.flags, "[Ss]")) then conn.flags = conn.flags .. "S" end;
      if (not strfind(conn.flags, "[Mm]")) then conn.flags = conn.flags .. "M" end;
      if (not strfind(conn.flags, "[Ll]")) then conn.flags = conn.flags .. "L" end;
      if (not strfind(conn.flags, "[Ww]")) then conn.flags = conn.flags .. "w" end;
     
      if (strfind(conn.flags, "W") and conn.termType=="colour") then
        send("\255\253\31\255\240", conn, S_RAW);
      end;
   end;      

   if (strfind(conn.flags, "E", 1, 1)) then
     colloquy.connections[connection].socket.echo = 1;
   end;

   if (invis) then
      log(format("+I %s %s %s", conn.username, conn.site, conn.via or "(direct)"));
   else
      log(format("+  %s %s %s", conn.username, conn.site, conn.via or "(direct)"));
   end;

   commandMark(connection, ".-");
   sendFile(colloquy.motd, {colloquy.connections[connection]});

   if (birthday ~= ".") then
     sendFile(colloquy.birthday, {colloquy.connections[connection]});
   end;

   commandSet(connection, ".set", "");
   commandLook(connection, ".look", "");
   commandComments(connection, ".comments");

   if (u and u.failed and u.failed > 0) then
     sendGM(conn, S_DONE, "cloginFailures", u.failed);
     u.failed = 0;
   end;

end;

function resolve(ip)
   if (ip) then
      colloquy.resolver:send(ip .. "\n");
   end;
end;

function resolverResult(string)
   gsub(string, "(.-)\n", function(a)
      local t = split(a);
      for i, v in colloquy.connections do
        if (v.site == t[1]) then
          v.site = t[2];
          if (v.status < 1 and not v.bot) then
            sendGMAll(S_CONNECTWARN, "gConnecting", v.site);
          end;
        end;
        if (v.via == t[1]) then
          v.via = t[2];
        end;
      end;
     end);
end;

function getCaptures(string, pattern)
   local result = {};
   gsub(string, pattern, function(...)
     local loop;
     for loop = 1, arg.n do
       tinsert(%result, arg[loop]);
     end;
   end);
   return result;
end;

Seconds = 1;
Minutes = 60 * Seconds;
Hours = 60 * Minutes;
Days = 24 * Hours;
Weeks = 7 * Days;

function y(a, b, c)
  if (a) then return b else return c end;
end;

function timeToString(t)
   local r = "";
   local c;
   local weeks   = floor(t / Weeks);
   local days    = floor(mod(t, Weeks) / Days);
   local hours   = floor(mod(t, Days) / Hours);
   local minutes = floor(mod(t, Hours) / Minutes);
   local seconds = mod(t, Minutes);
   if (seconds ~= 0) then seconds = seconds / Seconds end;

   if (weeks == 1) then
      r = r .. "1 week, ";
   elseif (weeks > 1) then
      r = r .. weeks .. " weeks, ";
   end;

   if (days == 1) then
      r = r .. "1 day, ";
   elseif (days > 1) then
      r = r .. days .. " days, ";
   end;

   if (hours == 1) then
      r = r .. "1 hour, ";
   elseif (hours > 1) then
      r = r .. hours .. " hours, ";
   end;

   if (minutes == 1) then
      r = r .. "1 minute, ";
   elseif (minutes > 1) then
      r = r .. minutes .. " minutes, ";
   end;

   if (seconds == 1) then
      r = r .. "1 second.";
   elseif (seconds ~= 1) then
      r = r .. seconds .. " seconds.";
   else
      r = strsub(r, 1, strlen(r) - 2) .. ".";
   end;

   return r;

end;

function timeToShortString(t)
   local r = "";
   local c;
   local weeks   = floor(t / Weeks);
   local days    = floor(mod(t, Weeks) / Days);
   local hours   = floor(mod(t, Days) / Hours);
   local minutes = floor(mod(t, Hours) / Minutes);
   local seconds = mod(t, Minutes);
   if (seconds ~= 0) then seconds = seconds / Seconds end;

   if (weeks > 0) then
      days = days + (weeks * 7);
   end;

   if (days > 0) then
     r = days .. " day";
     if (days > 1) then
       r = r .. "s";
     end;
     return r;
   end;

   r = strsub("00" .. hours .. ":", -3, -1);
   r = r .. strsub("00" .. minutes .. ".", -3, -1);
   r = r .. strsub("00" .. seconds, -2, -1);

   return r;
end;

function timeToWhoString(t)
  local weeks   = floor(t / Weeks);
  local days    = floor(mod(t, Weeks) / Days);
  local hours   = floor(mod(t, Days) / Hours);
  local minutes = floor(mod(t, Hours) / Minutes);
  local seconds = mod(t, Minutes);
 
  if (weeks > 0) then
    return format("%dw", weeks);
  end;

  if (days > 0) then
    return format("%dd", days);
  end;

  if (hours > 0) then
    return format("%2.2dh%2.2d", hours, minutes);
  end;

  return format("%2.2d:%2.2d", minutes, seconds);
end;

function userByName(username)
   -- searches all connected users for username, expanding up short versions.
   -- (ie, dks -> dkscully).
   -- returns the connection table from colloquy.connections[] if found, or
   -- a string saying "Ambiguous alias - matches a, b, c" for sending to the user.
   -- if it doesn't match, it returns nil.
   
   local found, luser, i, v, r = {}, strlower(username);

   -- process just their username...
   for i, v in colloquy.connections do
     if (i ~= "n") then
       local vuser = strlower(v.username);
       if (luser == vuser) then return v end;
         r = strfind(vuser, luser, 1, 1);
         if (r == 1) then
           tinsert(found, v);
         end;
       end;
   end;

   -- now process any aliases...
   for i, v in colloquy.connections do
     if (i ~= "n") then
       if (v.aliases ~= nil and v.alias ~= "") then
         local a = split(v.aliases)
         local h, j;

         for h, j in a do
           if (h ~= "n") then
             local vuser = strlower(j);
             if (luser == vuser) then return v end;
             r = strfind(vuser, luser, 1, 1);
             if (r == 1 and not in(v, found)) then
               tinsert(found, v);
             end;
           end;
         end;
       end;
     end;
   end;

   if (getn(found) == 0) then return nil end;
   if (getn(found) > 1) then
      -- more than one matches...
      r = ""
      for i, v in found do
         if (i ~= "n") then
            r = r .. v.username .. ", ";
         end;
      end;
      r = strsub(r, 1, strlen(r) - 2);
      return gm(lastConnection, "Ambiguous", username, r);
   end;

   return found[1];
end;

function groupByName(group)
  local groups = {};
  local i, v;

  local alreadyExists = function(name, table)
    local i, v, n;
    n = strlower(name);
    for i, v in table do
      if (strlower(v) == n) then
        return v;
      end;
    end;
  end;

  -- first of all, make a table of groups...
  for i, v in colloquy.connections do
    if (type(v) == "table" and not alreadyExists(v.group, groups)) then
      tinsert(groups, v.group);
    end;
  end;

  -- now work though them finding matches...
  local matches = {};
  local glen = strlen(group);
  group = strlower(group);
  for i,v in groups do
    if (i ~= "n") then
      if (strfind(strlower(v), group, 1, 1) == 1) then
        -- found a match - if it matches in length too, simply return now.
        if (strlen(v) == glen) then
          return v;
        end;
        tinsert(matches, v);
      end; 
    end;
  end;

  if (getn(matches) == 0) then
    return nil, format("No such group '%s'.", group);
  end;

  if (getn(matches) == 1) then
    return matches[1];
  end;

  -- we've more than one match - create "ambigueous error"
  local err = group .. " is ambiguous - matches ";
  for i, v in matches do
    if (i ~= "n") then
      err = err .. v .. ", ";
    end;
  end;
  return nil, strsub(err, 1, -3) .. "."; 
end;

function in(object, table)
  -- tests in object is in table{}
  local i, v;


  for i, v in table do
    if (v == object) then
      return i;
    end;
  end;

  return nil;
end;

function calculateAge(birthday)
  -- returns the age of somebody whose birthday is 'birthday', in ISO format.
  
  local null, null, year, month, day, age, time = strfind(birthday, "(%d+)%-(%d+)%-(%d+)");

  year = tonumber(year); month = tonumber(month); day = tonumber(day);
  

  if ((year < 1900) or (month > 12) or (day > 31)) then
    return 0;
  end;
  
  time = {
    mday = tonumber(date("%d")),
    mon = tonumber(date("%m")),
    year = tonumber(date("%Y")),
  };

  age = time.year - year;

  if ((time.mon < month) or ((time.mon == month) and (time.mday < day))) then
    age = age -1;
  end;

  return age;

end;

function addInvitation(user, thing)
  thing = strlower(thing);
  if (user.invitations == nil) then
    user.invitations = { [thing] = 1 };
    return nil;
  end;

  if (not user.invitations[thing]) then
    user.invitations[thing] = 1;
  end;
end;

function checkInvitation(user, thing)
  if (not user.invitations) then return nil end;
  return (user.invitations[strlower(thing)])
end;

function removeInvitation(user, thing)
  thing = strlower(thing);

  if (user.invitations == nil) then
    return nil;
  end;

  user.invitations[thing] = nil;
end;

function updateInvitations(old, new)
  old = strlower(old); new = strlower(new);

  local i, v;
  for i, v in colloquy.connections do
    if (type(v) == "table" and v.invitations) then
      if (v.invitations[old]) then
        v.invitations[old] = nil;
        v.invitations[new] = 1;
      end;  
    end;
  end;

end;

function checkGroupToUnlock(group)
  
  if colloquy.lockedGroups[strlower(group)] then
    -- the group they left was locked - check if they were the last person in
    -- that group, and if they were, unlock it.
    local i, v;
    local tmp = nil;
     
    for i, v in getGroupMembers(group) do
      if (type(v) == "table") then
        tmp = 1;
        break; -- found a user - flag it, and break out of the loop.
      end;  
    end;  
    if (not tmp) then
      -- nobody else in the group, unlock it.
      colloquy.lockedGroups[strlower(group)] = nil;
    end;
  end;

  -- also remove any observations, and tell the observers.
  local tmp
  for i, v in getGroupMembers(group) do
    if (type(v) == "table") then
      tmp = 1;
      break; -- found a user - flag it, and break out of the loop.
    end
  end
  if not tmp then
    local o = observersGet(strlower(group))
    for i, v in o do
      if type(v) == "table" then
        observingStop(v, strlower(group))
        send(format("Disregarding group '%s' as it nolonger exists.", group), v, S_GROUPGONE);
      end
    end
  end

end;

function exchange(str, old, new)
  local p = strfind(str, old, 1, 1);
  if not p then
    str = str .. old;
    p = strfind(str, old, 1, 1);
  end
  local n = strlen(old);
  repeat
    if (p) then
      str = strsub(str, 1, p - 1) .. new .. strsub(str, p + n, -1);
    end;
    p = strfind(str, old, 1, 1);
  until p == nil;

  return str;
end;

function wordwrap(text, indent, width)
   local result, words, loop, total;

   return text;

end;

function connection(username)
  local lusername = strlower(username);
  local i, v;
  for i, v in colloquy.connections do
    if (type(v) == "table") then
      if (strlower(v.realUser) == lusername) then
        return v;
      end;
    end;
  end;

  return nil;
end;

function columns(dataset, columns, width)
  local r = {};  -- the table of lines that we return
  local l = 1;   -- the next line in r to be written.
  local f = "";  -- our format string
  local i, v, n; -- looping variables
  local j = {};  -- where items are stored.

  columns = floor(columns);
  f = strrep(format("%%-%d.%ds ", width, width), columns);

  j[1] = f;
  n = 2;
  for i=1,getn(dataset) do
    j[n] = dataset[i];
    n = n + 1;
    if (n == (columns + 2)) then
      r[l] = call(format, j);
      l = l + 1;
      n = 2;
      j = {};
      j[1] = f;
    end
  end;

  if (n == 2) then
    return r;
  end;

  if (n < columns + 2) then
    for n=2,columns + 1 do
      if (j[n] == nil) then j[n] = "" end;
    end;
    r[l] = call(format, j);
  end;

  return r;
end;

function matchStar(string, pattern)
  -- simple wildcard matching
  local p;
  p = gsub(pattern, "([^a-zA-Z0-9*^$])", "%%%1");
  p = gsub(p, "%*", ".*");
  return(strfind(string, p));
end;

function saveBans(file)
  local f = openfile(file, "w");
  local i, v;
  for i, v in colloquy.banMasks do
    if (type(v) == "table") then
      write(f, format("%s\n%s\n", v.mask, v.reason));
    end;
  end;
  closefile(f);
end;

function loadBans(file)
  local f = openfile(file, "r");
  colloquy.banMasks = {};
  if (not f) then
    return nil;
  end;
  local mask, reason;
  repeat
    mask, reason = read(f, "*l", "*l");
    if (mask and reason) then
      tinsert(colloquy.banMasks, { mask = mask, reason = reason } );
    end;
  until not (mask and reason);
  closefile(f);
end;

function isBanned(host)
  local ip = toip(host);
  local i, v, m;
  for i, v in colloquy.banMasks do
    if (type(v) == "table") then
      print(v.mask, host, ip);
      if (matchStar(host, v.mask) or matchStar(ip, v.mask)) then
        return v;
      end;
    end;
  end;

  return nil;
end;

function prettyBytes(n)
  if ( n >= (4 * 1024 * 1024) ) then
    return format("%.2fMB (%d bytes).", (n / 1024) / 1024, n);
  elseif ( n >= (4 * 1024) ) then
    return format("%.2fkB (%d bytes).", n / 1024, n);
  else
    return format("%d bytes.", n);
  end;
end;

function getUserMultiple(text)
   -- processes a multi-user spec in the format of:
   -- >bob,gavin,rick Ogg smells.
   -- <@public,-ogg thinks Ogg smells.
   -- etc...
   -- returns a table of connection objects from colloquy.connections, and a tidied
   -- string form of the spec.  Or, it returns nil and an error message.

   text = gsub(text, "%s*", "");
   local p = esplit(text, ","); -- split it up
   local who = {};              -- table to put connection objects in that we return
   local userAdd = {};          -- table of users to add to who{}
   local userSub = {};          -- table of users to remove from who{}
   local spec = "";             -- string with tidy spec in to return

   for i, v in p do
     local prefix = strsub(v, 1, 1);
     local subtract;
     if (i ~= "n") then
       if (prefix == "-") then
         -- they want to subtract this - set the subtract flag, and strip the -
         subtract = 1;
         prefix = strsub(v, 2, 2);
         v = strsub(v, 2, -1);
       end;
       if (prefix == "@") then
         -- this item is a group name
         v = strsub(v, 2, -1);
         local t, err = groupByName(v);
         if (t == nil) then
           return nil, err;
         end;
         if (subtract == 1) then
           spec = spec .. format(", -@%s", t);
           for i, v in getGroupMembers(t) do
             if (i ~= "n") then
               if (in(v, userSub)) then
                 return nil, u .. " subtracted mulitple times in user specification.";
               end;
               tinsert(userSub, v);
             end;
           end;
         else
           spec = spec .. format(", @%s", t);
           for i, v in getGroupMembers(t) do
             if (i ~= "n") then
               if (in(v, userAdd)) then
                 return nil, u .. " added multiple times in user specification.";
               end;
               tinsert(userAdd, v);
             end;
           end;
         end;
       
       elseif (prefix == "%") then
         -- this item is a list name.
         return nil, "You cannot specify lists in user specifications.";
       elseif (prefix == "*") then
         -- they want to include everybody
         if (subtract) then
           return nil, "You cannot subtract everybody in user specifications.";
         end;
         for i, v in colloquy.connections do
           if (i ~= "n") then tinsert(userAdd, v) end;
         end;
         spec = spec .. ", *";
       else
         -- this item is a username
         local t = userByName(v);
         if (t == nil) then
           return nil, format("Unknown username '%s'.", v);
         elseif (type(t) == "string") then
           return nil, t;
         end;
         if (subtract) then
           if (in(t, userSub)) then
             return nil, t.username .. " subtracted multiple times in user specification";
           end;
           spec = spec .. format(", -%s", t.username);
           tinsert(userSub, t);
         else
           if (in(t, userAdd)) then
             return nil, t.username .. " added multiple times in user specification";
           end;
           spec = spec .. format(", %s", t.username);
           tinsert(userAdd, t);
         end;
       end;
     end;
   end;

   -- now, we want to add everybody in userAdd who isn't in userSub to the who table.
   for i, v in userAdd do
     if (i ~= "n") then
       if (not in(v, userSub)) then
         tinsert(who, v);
       end;
     end;
   end;

   return who, strsub(spec, 3, -1);
end;

-- TODO: Perhaps look into using this (RT's) instead of EH's one?  It would need to be tweaked to
-- allow for prefixing etc.
-- wrap: Wrap a string into a paragraph
--   s: string to wrap
--   w: width to wrap to [78]
--   ind: indent [0]
--   ind1: indent of first line [ind]
-- returns
--   s_: wrapped paragraph
function wrap (s, w, ind, ind1)
  w = w or 78
  ind = ind or 0
  ind1 = ind1 or ind
  s = strrep (" ", ind1) .. s
  local lstart, len = 1, strlen (s)
  while len - lstart > w - ind do
    local i = lstart + w - ind
    while i > lstart and strsub (s, i, i) ~= " " do
      i = i - 1
    end
    local j = i
    while j > lstart and strsub (s, j, j) == " " do
      j = j - 1
    end
    s = strsub (s, 1, j) .. "\n" .. strrep (" ", ind) ..
      strsub (s, i + 1, -1)
    local change = ind + 1 - (i - j)
    lstart = j + change
    len = len + change
  end
  return s
end

function idleListeners()
  -- returns a table of connection tables for people who want idle
  -- messages.
  local t = {}

  for i, v in colloquy.connections do
    if type(v) == "table" then
      if not strfind(v.flags or "", "[iI]") then
        -- they don't have a preference!  merp.  Assume they want them on :)
        v.flags = v.flags .. "I"
      end
      if strfind(v.flags or "", "I", 1, 1) then
        tinsert(t, v)
      end
    end
  end

  return t
end

function fileExists(fn)
  local fh = openfile(fn, "r")
  if fh then
    closefile(fh)
    return 1
  end
  return nil
end


-- observation code
-- The "observing" field in connection tables contains a table with group names
-- as keys, with some unimportant value.  This means we can very quickly decide
-- if a user is observing a certain group by doing conn.observing.foo, where foo
-- is the group we're interested in.  If they're not observing anything, then
-- their observing field is nil.  All the group name keys are in lower case.

function observersGet(group)
  -- returns a table of connection tables for everybody observing
  -- a certain group
  local r = {}

  group = strlower(group)
  for i, v in colloquy.connections do
    if type(v) == "table" then
      local o = v.observing
      if o and o[group] then
        tinsert(r, v)
      end
    end
  end

  return r
end

function observedGet(conn)
  -- return a string with a space seperated list of groups that
  -- conn is observing.  If none are being observed, it returns
  -- nil.
 
  if not conn.observing then return end

  local r = ""

  for i, v in conn.observing do
    if type(v) == "string" then
      -- avoid "n" entry
      r = r .. v .. " "
    end
  end

  return r
end

function observingStart(conn, group)
  -- add a group to conn's list of observations.

  conn.observing = conn.observing or {}
  conn.observing[strlower(group)] = group
end

function observingStop(conn, group)
  -- remove a group from conn's list of observations.

  if not conn.observing then return end
  
  conn.observing[strlower(group)] = nil
  if getn(conn.observing) == 0 then
    conn.observing = nil
  end
end

function observeUpdate(oldg, newg)
  -- update's people's observations when a group is
  -- renamed or removed.  newg is null when it is
  -- emptied.

  for i, v in colloquy.connections do
    if type(v) == "table" then
      if v.observing and v.observing[oldg] then
        observingStop(v, oldg)
        if newg then
          observingStart(v, newg)
        end
      end
    end
  end

end

