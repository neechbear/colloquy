-- lists
-- table layout:
-- 
-- lists[listname] = {
--   listname = "capitalised list name",
--   description = "description of the list",
--   owner = "who owns this list, and is always a list master",
--   created = "when this list was created",
--   flags = "flags - O = open, L = locked, P = permanent, A = anonymous",
--   members = {
--     "bob",
--     "god",
--     "foo"
--   },
--   masters = {
--     "bob",
--     "god"
--   }
--   used = time since the epoch that the list was last used.
-- }

lists = {
  masters = {
    listname = "Masters",
    description = "Talker administration",
    flags = "OLP",
    owner = "god",
    created = date("%a %b %d %H:%M:%S %Z %Y"),
    members = {
      "god"
    },
    masters = {}
  }
}

function numberOfListsOwned(username)
  local username = strlower(username)
  local t = 0;
  for i, v in lists do
    if ( v.owner == username and not strfind(v.flags, "P") ) then
      t = t + 1;
    end;
  end;

  return t;
end;

function searchForUser(realName)
  -- searches for a user with realName
  local l, i, v = strlower(realName);
  for i, v in colloquy.connections do
    if (v.realUser and l == strlower(v.realUser)) then
      return v;
    end;
  end;
  return nil;
end;

function isListMaster(listname, username)
  listname = strlower(listname);
  username = strlower(username);
  local l = lists[listname];

  if l.owner == username or strfind((connection(username).privs or ""), "M", 1, 1) then
    return 1;
  end

  for i, v in (l.masters or {}) do
    if v == username then
      return 1;
    end;
  end;

  return nil;
end

function getListMembers(listname, talking)
   local r, i, v = {};
   
   for i, v in lists[listname].members do
      if (i ~= "n") then
        local bing = searchForUser(v);
          if (type(bing) == "table") then
           if (talking) then
             if (not listHasPaused(bing, listname)) then
               tinsert(r, bing);
             end;
           else
             tinsert(r, bing);
           end;
         end;
      end;
   end;

   return r;
end;

function listIsMember(user, list, real)
  local m, l, i, v = strlower(user), strlower(list);

  if (not lists[list]) then return nil end;
  if (not real and strfind(lists[list].flags, "O", 1, 1)) then return 0 end;

  for i, v in lists[l].members do
    if (type(v) == "string" and v == m) then return i end;
  end;

  return nil;
end;

function listByName(conn, list, talk)
  local found, i, v = {};
  local luser = strlower(conn.realUser);
  local llist = strlower(list);
  
  if (lists[llist] ~= nil ) then
    return llist;
  end;

  for i, v in lists do
    if (type(v) == "table") then
      if (strfind(i, llist, 1, 1) == 1) then
        if (listIsMember(luser, i) or not talk) then
          tinsert(found, i);
        end;
      end;
    end;
  end;

  for i, v in found do
    if (v == llist) then
      return v;
    end;
  end;

  if (getn(found) == 0) then
    if (lists[llist] ~= nil ) then
      return llist;
    end;
    return nil, "That list does not exist!";
  end;
  if (getn(found) > 1) then
    local r = list .. " is ambiguous - matches ";
    for i, v in found do
      if (type(v) == "string") then
        r = r .. lists[v].listname .. ", ";
      end;
    end;
    r = strsub(r, 1, -3) .. ".";
    return nil, r;
  end;
  return found[1];

end;

function commandListTell(connection, line, params)
   local p = split(params);
   local conn = colloquy.connections[connection];
      
   if (p[1] == nil or p[2] == nil) then
      send("Whispering nothing to a list is silly.", colloquy.connections[connection], S_ERROR);
      return nil;
   end;
   
   local l = strlower(p[1]);
   local l, err = listByName(conn, l, 1);
   if (l == nil) then
     send(err, conn, S_ERROR);
     return nil;
   end;
   
   if (lists[l] == nil) then
      send("No such list.", conn, S_ERROR);
      return nil;
   end;

   if (not listIsMember(conn.realUser, l) and not strfind(conn.privs or "", "M", 1, 1)) then
     send("You are not a member of that list, and it is not open!", conn, S_ERROR);
     return nil;
   end;

   if (strfind(lists[l].flags, "R", 1, 1)) then
     -- the list is read-only.  Check if they're the owner, or a master.
     if not isListMaster(l, conn.realUser) then
       send("That list is read-only.", conn, S_ERROR);
       return nil;
     end;
   end;

   if (listHasPaused(conn, lists[l].listname)) then
     listUnpause(conn, l);
   end;

   local m = getListMembers(l, 1);
   local t = strsub(line, strfind(line, p[1], 1, 1) + strlen(p[1]) + 1, strlen(line));
   local a = conn.username .. strrep(" ", 11);
   a = strsub(a, 1, 12) .. "%" .. t .. " {" .. lists[l].listname .. "}";
   sendTo(a, m, S_LISTTALK);
  
  if (not listIsMember(conn.realUser, l, 1)) then
    send(format("Whispered to list %s: '%s'", lists[l].listname, t), conn, S_DONETELL);
  end;

  lists[l].used = secs;
end;

function commandListEmote(connection, line, params)
   local p = split(params);
   local conn = colloquy.connections[connection];
      
   if (p[1] == nil or p[2] == nil) then
      send("Whispering nothing to a list is silly.", colloquy.connections[connection], S_ERROR);
      return nil;
     end;
   
   local l = strlower(p[1]);
   local l, err = listByName(conn, l, 1);
   if (l == nil) then
     send(err, conn, S_ERROR);
     return nil;
   end;
 
   if (lists[l] == nil) then
      send("No such list.", colloquy.connections[connection], S_ERROR);
      return nil;
   end;

   if (not listIsMember(conn.realUser, l) and not strfind(conn.privs, "M", 1, 1)) then
     send("You are not a member of that list, and it is not open!", conn, S_ERROR);
     return nil;
   end;

   if (strfind(lists[l].flags, "R", 1, 1)) then
     -- the list is read-only.  Check if they're the owner, or a master.
     if not isListMaster(l, conn.realUser) then
       send("That list is read-only.", conn, S_ERROR);
       return nil;
     end;
   end;

   if (listHasPaused(conn, lists[l].listname)) then
     listUnpause(conn, l);
   end;

   local m = getListMembers(l, 1);
   local t = strsub(line, strfind(line, p[1], 1, 1) + strlen(p[1]) + 1, strlen(line));
   local blah = " ";
   if (strfind(punctuation, strsub(t, 1, 1), 1, 1)) then
     blah = "";
   end;
   sendTo(format("%% %s%s%s {%s}", colloquy.connections[connection].username, blah, t, lists[l].listname) , m, S_LISTEMOTE);

   if (not listIsMember(conn.realUser, l, 1)) then
     send(format("REmote'd to list %s: '%s%s%s'", lists[l].listname, conn.username, blah, t), conn, S_DONETELL);
   end;

   lists[l].used = secs;
end;

function commandList(connection, line, params)
   local conn = colloquy.connections[connection]; 
   local p = split(params);

   if (p[1] == nil) then
     send("Usage: .list <command> <parameters...>", conn, S_ERROR);
     return nil;
   end;

   if (p[1] == "info") then
     if (p[2] == nil) then
       return commandLists(connection, ".lists", "");
     else
       listInfo(conn, p[2]);
       return nil;
     end;
   end;

   if (p[1] == "create") then
     if (p[2] == nil) then
       send("Usage: .list create <listname>", conn, S_ERROR);
       return nil;
     else
       listCreate(conn, p[2]);
       return nil;
     end;
   end;

   if (p[1] == "delete") then
     if (p[2] == nil) then
       send("Usage: .list delete <listname>", conn, S_ERROR);
       return nil;
     else
       listDelete(conn, p[2]);
       return nil;
     end;
   end;

   if (p[1] == "join") then
     if (p[2] == nil) then
       send("Usage: .list join <listname>", conn, S_ERROR);
       return nil;
     else
       listJoin(conn, p[2]);
       return nil;
     end;
   end;

   if (p[1] == "leave") then
     if (p[2] == nil) then
       send("Usage: .list leave <listname>", conn, S_ERROR);
       return nil;
      else
        listLeave(conn, p[2]);
        return nil;
      end;
    end;

    if (p[1] == "invite") then
      if (p[2] == nil or p[3] == nil) then
        send("Usage: .list invite <listname> <username>", conn, S_ERROR);
        return nil;
      else
        listInvite(conn, p[2], p[3]);
        return nil;
      end;
    end;

    if (p[1] == "owner") then
      if (p[2] == nil or p[3] == nil) then
        send("Usage: .list owner <listname> <username>", conn, S_ERROR);
        return nil;
      else
        listOwner(conn, p[2], p[3]);
        return nil;
      end;
    end;

    if (p[1] == "description") then
      if (p[2] == nil or p[3] == nil) then
        send("Usage: .list description <listname> <description>", conn, S_ERROR);
        return nil;
      else
        listDescription(conn, p[2], strsub(params, strfind(params, p[2], 1, 1) + strlen(p[2]) + 1, -1));
        return nil;
      end;
    end;
    
    if (p[1] == "lock") then
      if (p[2] == nil) then
        send("Usage: .list lock <listname>", conn, S_ERROR);
        return nil;
      else
        listLock(conn, p[2]);
        return nil;
      end;
    end;

    if (p[1] == "unlock") then
      if (p[2] == nil) then
        send("Usage: .list unlock <listname>", conn, S_ERROR);
        return nil;
      else
        listUnlock(conn, p[2]);
        return nil;
      end;
    end;

    if (p[1] == "evict") then
      if (not p[2] or not p[3]) then
        send("Usage: .list evict <listname> <username>", conn, S_ERROR);
        return nil;
      else
        listEvict(conn, p[2], p[3]);
        return nil;
      end;
    end;

    if (p[1] == "open") then
      if (not p[2]) then
        send("Usage: .list open <listname>", conn, S_ERROR);
        return nil;
      else
        listOpen(conn, p[2]);
        return nil;
      end;
    end;

    if (p[1] == "close") then
      if (not p[2]) then
        send("Usage: .list close <listname>", conn, S_ERROR);
        return nil;
      else
        listClose(conn, p[2]);
        return nil;
      end;
    end;

    if (p[1] == "pause") then
      listPause(conn, p[2]);
      return nil;
    end;

    if (p[1] == "unpause") then
      listUnpause(conn, p[2]);
      return nil;
    end;

    if (p[1] == "permanent") then
      if not p[2] then
        send("Usage: .list permanent <listname>", conn, S_ERROR);
        return nil;
      end;
      listPermanent(conn, p[2]);
      return nil;
    end;
    
    if (p[1] == "unpermanent") then
      if not p[2] then
        send("Usage: .list unpermanent <listname>", conn, S_ERROR);
        return nil;
      end;
      listUnpermanent(conn, p[2]);
      return nil;
    end;

    if (p[1] == "anonymous") then
      if not p[2] then
        send("Usage: .list anonymous <listname>", conn, S_ERROR);
        return nil;
      end;
      listAnonymous(conn, p[2]);
      return nil;
    end;

    if (p[1] == "unanonymous") then
      if not p[2] then
        send("Usage: .list unanonymous <listname>", conn, S_ERROR);
        return nil;
      end;
      listUnanonymous(conn, p[2]);
      return nil;
    end;

    if (p[1] == "readonly") then
      if not p[2] then
        send("Usage: .list readonly <listname>", conn, S_ERROR);
        return nil;
      end;
      listReadOnly(conn, p[2]);
      return nil;
    end;

    if (p[1] == "readwrite") then
      if not p[2] then
        send("Usage: .list readwrite <listname>", conn, S_ERROR);
        return nil;
      end
      listReadWrite(conn, p[2]);
      return nil;
    end;

    if (p[1] == "master") then
      if (not p[2] or not p[3]) then
        send("Usage: .list master <listname> <username>", conn, S_ERROR);
        return nil;
      else
        listMaster(conn, p[2], p[3]);
        return nil;
      end;
    end;

    if (p[1] == "unmaster") then
      if (not p[2] or not p[3]) then
        send("Usage: .list unmaster <listname> <username>", conn, S_ERROR);
        return nil;
      else
        listUnmaster(conn, p[2], p[3]);
        return nil;
      end;
    end;

    if (p[1] == "rename") then
      listRename(conn, p[2], p[3]);
      return nil;
    end;

    send("Unknown .list command.", conn, S_ERROR);

end;

function listMember(list, user)
  -- returns a * if user is a member of list, or " " otherwise.
  if (lists[strlower(list)] == nil) then return " " end;
  local m, i, v = lists[strlower(list)].members;
  for i, v in m do
    if (type(v) == "string" and v == user) then
      return "*";
    end;
  end;
  return " ";
end;

function commandLists(connection, line, params) 

  local p = split(params);
  local conn = colloquy.connections[connection];

  if (p[1]) then
    listInfo(conn, p[1]);
    return nil;
  end;

  local sortedLists = {};
  local i, v;
  local u = strlower(conn.realUser);
  local t = 0;
  
  for i, v in lists do
    if (type(v) == "table" and strfind(v.flags, "L", 1, 1)) then
      tinsert(sortedLists, v.listname);
    end;
  end;

  t = getn(sortedLists);
  
  if (getn(sortedLists) > 0) then
    send("Available locked lists are: ('*' marks ones currently subscribed to)", conn, S_LISTSHDR);
    sort(sortedLists);
    for i, v in sortedLists do
      if (type(v) == "string") then
        sortedLists[i] = listMember(v, u) .. v;
      end;
    end;
    local rl = columns(sortedLists, (conn.width-6)/17, 17);
    for i=1,getn(rl) do
      send("  " .. rl[i], conn, S_LISTS);
    end;
  end;

  sortedLists = {};
  
  for i, v in lists do
    if (type(v) == "table" and not strfind(v.flags, "L", 1, 1)) then
      tinsert(sortedLists, v.listname);
    end;
  end;
  
  t = t + getn(sortedLists);

  if (getn(sortedLists) > 0) then
    send("Available unlocked lists are: ('*' marks ones currently subscribed to)", conn, S_LISTSHDR);
    sort(sortedLists);  
    for i, v in sortedLists do
      if (type(v) == "string") then
        sortedLists[i] = listMember(v, u) .. v;
      end;
    end;
    local rl = columns(sortedLists, (conn.width-6)/17, 17);
    for i=1,getn(rl) do
      send("  " .. rl[i], conn, S_LISTS);
    end;
  end;

  if (t == 0) then
    send("There are no lists.", conn, S_ERROR);
  else
    send(tostring(t) .. " total.", conn, S_DONE);
  end;

end;

function listInfo(conn, params)
  local l = strlower(params);

  local l, err = listByName(conn, l);
  if (not l) then
    send(err, conn, S_ERROR);
    return nil;
  end;

  if (lists[l] == nil) then
    send("This list does not exist!", conn, S_ERROR);
    return nil;
  end;

  send(format("%-15.15s %s", "Name:", lists[l].listname), conn, S_LISTINFO);
  if (lists[l].description ~= "") then
    send(format("%-15.15s %s", "Description:", lists[l].description), conn, S_LISTINFO);
  end;
  if (lists[l].flags ~= "" and lists[l].flags ~= nil) then
    local f = lists[l].flags;
    f = gsub(f, "A", "Anonymous ");
    f = gsub(f, "L", "Locked ");
    f = gsub(f, "O", "Open ");
    f = gsub(f, "P", "Permanent ");
    f = gsub(f, "R", "Read-Only ");
    send(format("%-15.15s %s", "Flags:", f), conn, S_LISTINFO);
  end;
  send(format("%-15.15s %s", "Created:", lists[l].created), conn, S_LISTINFO);
  send(format("%-15.15s %s", "Owner:", lists[l].owner), conn, S_LISTINFO);

  local on, off =  "", "";
  local i, v;

  if not strfind(lists[l].flags, "A", 1, 1) then
    for i, v in lists[l].members do
      if (type(v) == "string") then
        local vconn = connection(v);
        local lmaster;
        if (vconn) then
          lmaster = isListMaster(l, vconn.realUser);
          local pconn = listHasPaused(vconn, lists[l].listname);
          if lmaster then
            on = on .. "*";
          end
          if (pconn) then
            on = on .. "(" .. v .. ") ";
          elseif (vconn.veryIdle) then
            on = on .. "[" .. v .. "] ";
          else
            on = on .. v .. " ";
          end;
        else
          if lmaster then
            off = off .. "*";
          end;
          off = off .. v .. " ";
        end;
      end;
    end;
  end;

  if (lists[l].used) then
    send(format("%-15.15s %s", "Last used:", strsub(timeToString(secs - lists[l].used), 1, -2) .. " ago."), conn, S_LISTINFO);
  end;
  if (on ~= "") then
    send(format("%-15.15s %s", "Users online:", on), conn, S_LISTINFO);
  end;
  if (off ~= "") then
    send(format("%-15.15s %s", "Users offline:", off), conn, S_LISTINFO);
  end;
end;

function listCreate(conn, params)
  local l = strlower(params);
  if (lists[l] ~= nil) then
    send("That list already exists!", conn, S_ERROR);
    return nil;
  end;

  if ( numberOfListsOwned(conn.realUser) >= colloquy.listQuota ) then
    send("You have exhausted your list quota.  Either delete some old lists, or ask a master to make some of them permanent.", conn, S_ERROR);
    return nil;
  end;

  if (strlen(gsub(l, "[%w%-]", "")) > 0 or (strlen(params) > 15)) then
    send("That isn't a valid list name.", conn, S_ERROR);
    return nil;
  end;

  lists[l] = {
    listname = params,
    description = "",
    flags = "",
    owner = strlower(conn.realUser),
    created = date("%a %b %e %H:%M:%S %Y"),
    members = {
      strlower(conn.realUser)
    }
  };

  saveOneList(l);
  send("List created.", conn, S_DONE);

end;

function listDelete(conn, params)
  local l = strlower(params);
  local l, err = listByName(conn, l, 1);
  if (not l) then
    send(err, conn, S_ERROR);
    return nil;
  end;

  
  if (lists[l] == nil) then
    send("That list does not exist!", conn, S_ERROR);
    return nil;
  end;

  if ((strlower(conn.realUser) ~= lists[l].owner) and (conn.privs == nil or strfind(conn.privs, "M", 1, 1) == nil)) then
    send("You cannot delete a list you do not own.", conn, S_ERROR);
    return nil;
  end;

  updateInvitations("%" .. l, "");

  sendTo(format("%s has deleted the list. {%s}", conn.username, lists[l].listname), getListMembers(l), S_LISTDELETE);
  if (not listIsMember(conn.realUser, l, 1)) then
    send(format("%s has deleted the list. {%s}", conn.username, lists[l].listname), conn, S_LISTDELETE);
  end;

  lists[l] = nil;
  remove(colloquy.lists .. "/" .. l)
  
end;

function listJoin(conn, params)
  local l = strlower(params);
  local l, err = listByName(conn, l);
  if (not l) then
    send(err, conn, S_ERROR);
    return nil;
  end;


  if (lists[l] == nil) then
    send("That list does not exist!", conn, S_ERROR);
    return nil;
  end;

  local u, i, v = strlower(conn.realUser);
  for i, v in lists[l].members do
    if (type(v) == "string" and v == u) then
      send("You are already a member of that list.", conn, S_ERROR);
      return nil;
    end;
  end;

  if (lists[l].flags and strfind(lists[l].flags, "L", 1, 1) and (not checkInvitation(conn, "%" .. l))) then
    if ( not (conn.privs and strfind(conn.privs, "M", 1, 1))) then
      send("That list is locked.", conn, S_ERROR);
      return nil;
    end;
  end;

  tinsert(lists[l].members, u);
  removeInvitation(conn, "%" .. l);
  if strfind(lists[l].flags, "A", 1, 1) then
    -- this list is anonymous.  Don't tell the list that this person has joined.
    send(format("You have joined the list anonymously. {%s}", lists[l].listname), conn, S_LISTJOIN);
  else
    sendTo(format("%s has joined the list. {%s}", conn.username, lists[l].listname), getListMembers(l), S_LISTJOIN);
  end;

  saveOneList(l);
  
end;

function listLeave(conn, params)
  local l = strlower(params);
  local l, err = listByName(conn, l, 1);
  if (not l) then
    send(err, conn, S_ERROR);
    return nil;
  end;


  if (lists[l] == nil) then
    send("That list does not exist!", conn, S_ERROR);
    return nil;
  end;

  if (lists[l].owner == strlower(conn.realUser)) then
    send("You cannot leave a list you own.", conn, S_ERROR);
    return nil;
  end;

  local u, i, v = strlower(conn.realUser);
  for i, v in lists[l].members do
    if (type(v) == "string" and v == u) then
      
      if strfind(lists[l].flags, "A", 1, 1) then
        -- this list is anonymous.  Don't tell the list that this person has left.
        send(format("You have left the list anonymously. {%s}", lists[l].listname), conn, S_LISTLEAVE);
      else
        sendTo(format("%s has left the list. {%s}", conn.username, lists[l].listname), getListMembers(l), S_LISTLEAVE);
      end;

      tremove(lists[l].members, i);
      saveOneList(l);
      return nil;
    end;
  end;

  send("You are not a member of that list.", conn, S_ERROR);
  
end;

function listInvite(conn, list, user)
  local l = strlower(list);
  local u = userByName(user);
  local master;  -- is this a master override?
  
  local l, err = listByName(conn, l);
  if (not l) then
    send(err, conn, S_ERROR);
    return nil;
  end;

  
  if (lists[l] == nil) then
    send("That list does not exist!", conn, S_ERROR);
    return nil;
  end;

  if (u == nil) then
    send("No such user.", conn, S_ERROR);
    return nil;
  end;

  if (type(u) == "string") then
    send(u, conn, S_ERROR);
    return nil;
  end;
  
  if (lists[l].flags and strfind(lists[l].flags, "L", 1, 1) and (not strfind(conn.privs or "", "M", 1, 1))) then
    local m, i, v, f;
    m = strlower(conn.realUser);
    for i, v in lists[l].members do
      if (type(v) == "string" and v == m) then
        f = 1;
        break;
      end;
    end;

    if (f ~= 1) then
      send("Only list members can invite users to locked lists.", conn, S_ERROR);
      return nil;
    end;
  end;

  local n = strlower(u.realUser);
  local f = nil;
  local un = strlower(conn.realUser);

  local m, i, v = lists[l].members;
  for i, v in m do
    if (type(v) == "string" and v == n) then
      send("User is already a member.", conn, S_ERROR);
      return nil;
    end;
    if (v == un) then
      f = 1;
    end;
  end;

  addInvitation(u, "%" .. l);

  if strfind(lists[l].flags, "A", 1, 1) then
    -- this list is anonymous.  Don't tell the whole list about it.
    send(format("You invite %s to the list anonymously. {%s}", u.username, lists[l].listname), conn, S_LISTINVITE);
  else
    sendTo(format("%s invites %s to the list. {%s}", conn.username, u.username, lists[l].listname), getListMembers(l), S_LISTINVITE);
  end;

  if (not listIsMember(conn.realUser, l, 1)) then
    if strfind(lists[l].flags, "A", 1, 1) then
      send(format("You invite %s to the list anonymously. {%s}", u.username, lists[l].listname), conn, S_LISTINVITE);
    else
      send(format("%s invites %s to the list. {%s}", conn.username, u.username, lists[l].listname), conn, S_LISTINVITE);
    end;
  end;

  local an = "";
  if strfind(lists[l].flags, "A", 1, 1) then
    an = " anonymously"
  end;

  send(format("%s invites you to %%%s%s.  To respond, type .list join %s", conn.username, lists[l].listname, an, lists[l].listname), u, S_LISTINVITE);

end;

function listOwner(conn, list, user)
  local l = strlower(list);
  local u = userByName(user);
  local l, err = listByName(conn, l, 1);
  if (not l) then
    send(err, conn, S_ERROR);
    return nil;
  end;


  if (lists[l] == nil) then
    send("That list does not exist!", conn, S_ERROR);
    return nil;
  end;

  if (u == nil) then
    send("No such user.", conn, S_ERROR);
    return nil;
  end;

  if (type(u) == "string") then
    send(u, conn, S_ERROR);
    return nil;
  end;

  if (lists[l].owner ~= strlower(conn.realUser)) then
    if (not (conn.privs and strfind(conn.privs, "M", 1, 1))) then
      send("You cannot change the owner of lists you do not own.", conn, S_ERROR);
      return nil;
    end;
  end;

  local n = strlower(u.realUser);
  if ( numberOfListsOwned(n) >= colloquy.listQuota ) then
    send(format("%s has exhausted their list quota, and cannot take ownership.", u.username), conn, S_ERROR);
    return nil;
  end;

  local m, i, v = lists[l].members;
  for i, v in m do
    if (type(v) == "string" and (v == n)) then
      sendTo(format("%s makes %s the list owner. {%s}", conn.username, u.username, lists[l].listname), getListMembers(l), S_LISTOWNER);
      if (not listIsMember(conn.realUser, l, 1)) then
        send(format("%s makes %s the list owner. {%s}", conn.username, u.username, lists[l].listname), conn, S_LISTOWNER);
      end;

      lists[l].owner = n;
      saveOneList(l);

      return nil;
    end;
  end;

  send("Only a list's members can be made the owner.", conn, S_ERROR);
end;

function listDescription(conn, list, desc)
  local l = strlower(list);
  local l, err = listByName(conn, l, 1);
  if (not l) then
    send(err, conn, S_ERROR);
    return nil;
  end;


  if (lists[l] == nil) then
    send("That list does not exist!", conn, S_ERROR);
    return nil;
  end;

  if not isListMaster(l, conn.realUser) then
    send("You cannot change the descriptions of lists you are not a master of.", conn, S_ERROR);
    return nil;
  end;

  lists[l].description = desc;
  sendTo(format("%s has changed the list's description to '%s'. {%s}", conn.username, desc, lists[l].listname), getListMembers(l), S_LISTDESC);

  if (not listIsMember(conn.realUser, l, 1)) then
    send(format("%s has changed the list's description to '%s'. {%s}", conn.username, desc, lists[l].listname), conn, S_LISTDESC);
  end;

  saveOneList(l);
  
end;

function listLock(conn, list)
  local l = strlower(list);
  local l, err = listByName(conn, l, 1);
  if (not l) then
    send(err, conn, S_ERROR);
    return nil;
  end;


  if (lists[l] == nil) then
    send("That list does not exist!", conn, S_ERROR);
    return nil;
  end;
  
  if not isListMaster(l, conn.realUser) then
    send("You cannot lock lists that you are not a master of.", conn, S_ERROR);
  end;

  if (lists[l].flags and (strfind(lists[l].flags, "L", 1, 1))) then
    send("That list is already locked.", conn, S_ERROR);
    return nil;
  end;

  if (not lists[l].flags) then lists[l].flags = "" end;

  lists[l].flags = lists[l].flags .. "L";

  sendTo(format("%s has locked the list. {%s}", conn.username, lists[l].listname), getListMembers(l), S_LISTLOCK);
  if (not listIsMember(conn.realUser, l, 1)) then
    send(format("%s has locked the list. {%s}", conn.username, lists[l].listname), conn, S_LISTLOCK);
  end;

  saveOneList(l);

end;

function listUnlock(conn, list)
  local l = strlower(list);
  local l, err = listByName(conn, l, 1);
  if (not l) then
    send(err, conn, S_ERROR);
    return nil;
  end;

  if (lists[l] == nil) then
    send("That list does not exist!", conn, S_ERROR);
    return nil;
  end;

  if not isListMaster(l, conn.realUser) then
    send("You cannot unlock lists that you are not a master of.", conn, S_ERROR);
    return nil;
  end;

  if (lists[l].flags and (not strfind(lists[l].flags, "L", 1, 1))) then
    send("That list is already unlocked.", conn, S_ERROR);
    return nil;
  end;

  if (not lists[l].flags) then lists[l].flags = "" end;
  lists[l].flags = gsub(lists[l].flags, "L", "");

  updateInvitations("%" .. l, "");

  sendTo(format("%s has unlocked the list. {%s}", conn.username, lists[l].listname), getListMembers(l), S_LISTUNLOCK);
  if (not listIsMember(conn.realUser, l, 1)) then
    send(format("%s has unlocked the list. {%s}", conn.username, lists[l].listname), conn, S_LISTUNLOCK);
  end;

  saveOneList(l);

end;

function listEvict(conn, list, user)
  local l = strlower(list);
  local l, err = listByName(conn, l, 1);
  if (not l) then
    send(err, conn, S_ERROR);
    return nil;
  end;


  if (lists[l] == nil) then
    send("That list does not exist!", conn, S_ERROR);
    return nil;
  end;

  if not isListMaster(l, conn.realUser) then
    send("You cannot evict users from lists you are not a master of.", conn, S_ERROR);
    return nil;
  end;

  local m, i, v;
  m = userByName(user);
  if (m == nil) then
    send("No such user.", conn, S_ERROR);
    return nil;
  end;

  if (type(m) == "string") then
    send(m, conn, S_ERROR);
    return nil;
  end;

  local mm = strlower(m.username);

  if (mm == lists[l].owner) then
    send("You cannot evict the list owner.", conn, S_ERROR);
    return nil;
  end;

  for i, v in lists[l].members do
    if (type(v) == "string" and v == mm) then
      sendTo(format("%s has evicted %s from the list. {%s}", conn.username, m.username, lists[l].listname), getListMembers(l), S_LISTEVICT);
      if (not listIsMember(conn.realUser, l, 1)) then
        send(format("%s has evicted %s from the list. {%s}", conn.username, m.username, lists[l].listname), conn, S_LISTEVICT);
      end;

      tremove(lists[l].members, i);
      saveOneList(l);
      return nil;
    end;
  end;

  send("User isn't on that list.", conn, S_ERROR);

end;

function listOpen(conn, list)
  local l = strlower(list);
  local l, err = listByName(conn, l, 1);
  if (not l) then
    send(err, conn, S_ERROR);
    return nil;
  end;

  if not isListMaster(l, conn.realUser) then
    send("You cannot open a list that you are not a master of.", conn, S_ERROR);
    return nil;
  end;

  if (strfind(lists[l].flags, "O", 1, 1)) then
    send("That list is already open!", conn, S_ERROR);
    return nil;
  end;

  lists[l].flags = lists[l].flags .. "O";

  sendTo(format("%s has opened the list. {%s}", conn.username, lists[l].listname), getListMembers(l), S_LISTOPEN);
  if (not listIsMember(conn.realUser, l, 1)) then
    send(format("%s has opened the list. {%s}", conn.username, lists[l].listname), conn, S_LISTOPEN);
  end;

  saveOneList(l);

end;

function listPermanent(conn, list)
  local l = strlower(list);
  local l, err = listByName(conn, l, 1);
  if (not l) then
    send(err, conn, S_ERROR);
    return nil;
  end;

  if (not (conn.privs and strfind(conn.privs, "M", 1, 1))) then
    send("Only masters can do that.", conn, S_ERROR);
    return nil;
  end;

  if (strfind(lists[l].flags, "P", 1, 1)) then
    send("That list is already permanent!", conn, S_ERROR);
    return nil;
  end;

  lists[l].flags = lists[l].flags .. "P";

  sendTo(format("%s has made the list permanent. {%s}", conn.username, lists[l].listname), getListMembers(l), S_LISTPERM);
  if (not listIsMember(conn.realUser, l, 1)) then
    send(format("%s has made the list permanent. {%s}", conn.username, lists[l].listname), conn, S_LISTPERM);
  end;
 
  saveOneList(1);

end;

function listUnpermanent(conn, list)
  local l = strlower(list);
  local l, err = listByName(conn, l, 1);
  if (not l) then
    send(err, conn, S_ERROR);
    return nil;
  end;

  if (not (conn.privs and strfind(conn.privs, "M", 1, 1))) then
    send("Only masters can do that.", conn, S_ERROR);
    return nil;
  end;

  if (not strfind(lists[l].flags, "P", 1, 1)) then
    send("That list isn't permanent!", conn, S_ERROR);
    return nil;
  end;

  lists[l].flags = gsub(lists[l].flags, "P", "");

  sendTo(format("%s has made the list non-permanent. {%s}", conn.username, lists[l].listname), getListMembers(l), S_LISTUNPERM);
  if (not listIsMember(conn.realUser, l, 1)) then
    send(format("%s has made the list non-permanent. {%s}", conn.username, lists[l].listname), conn, S_LISTUNPERM);
  end;
 
  saveOneList(l);

end;

function listAnonymous(conn, list)
  local l = strlower(list);
  local l, err = listByName(conn, l, 1);
  if (not l) then
    send(err, conn, S_ERROR);
    return nil;
  end;

  if (not (conn.privs and strfind(conn.privs, "M", 1, 1))) then
    send("Only masters can do that.", conn, S_ERROR);
    return nil;
  end;

  if (strfind(lists[l].flags, "A", 1, 1)) then
    send("That list is already anonymous!", conn, S_ERROR);
    return nil;
  end;

  lists[l].flags = lists[l].flags .. "A";

  sendTo(format("%s has made the list anonymous. {%s}", conn.username, lists[l].listname), getListMembers(l), S_LISTANON);
  if (not listIsMember(conn.realUser, l, 1)) then
    send(format("%s has made the list anonymous. {%s}", conn.username, lists[l].listname), conn, S_LISTANON);
  end;
 
  saveOneList(l);

end;

function listUnanonymous(conn, list)
  local l = strlower(list);
  local l, err = listByName(conn, l, 1);
  if (not l) then
    send(err, conn, S_ERROR);
    return nil;
  end;

  if (not (conn.privs and strfind(conn.privs, "M", 1, 1))) then
    send("Only masters can do that.", conn, S_ERROR);
    return nil;
  end;

  if (not strfind(lists[l].flags, "A", 1, 1)) then
    send("That list isn't anonymous!", conn, S_ERROR);
    return nil;
  end;

  lists[l].flags = gsub(lists[l].flags, "A", "");

  sendTo(format("%s has made the list non-anonymous. {%s}", conn.username, lists[l].listname), getListMembers(l), S_LISTUNANON);
  if (not listIsMember(conn.realUser, l, 1)) then
    send(format("%s has made the list non-anonymous. {%s}", conn.username, lists[l].listname), conn, S_LISTUNANON);
  end;
 
  saveOneList(l);

end;

function listReadOnly(conn, list)
  local l = strlower(list);
  local l, err = listByName(conn, l, 1);
  if (not l) then
    send(err, conn, S_ERROR);
    return nil;
  end;

  if not isListMaster(l, conn.realUser) then
    send("You cannot make a list read-only that you are not a master of.", conn, S_ERROR);
    return nil;
  end;

  if (strfind(lists[l].flags, "R", 1, 1)) then
    send("That list is already read-only!", conn, S_ERROR);
    return nil;
  end;

  lists[l].flags = lists[l].flags .. "R";

  sendTo(format("%s has made the list read-only. {%s}", conn.username, lists[l].listname), getListMembers(l), S_LISTREAD);
  if (not listIsMember(conn.realUser, l, 1)) then
    send(format("%s has made the list read-only. {%s}", conn.username, lists[l].listname), conn, S_LISTREAD);
  end;

  saveOneList(l);

end;

function listReadWrite(conn, list)
  local l = strlower(list);
  local l, err = listByName(conn, l, 1);
  if (not l) then
    send(err, conn, S_ERROR);
    return nil;
  end;

  if not isListMaster(l, conn.realUser) then
    send("You cannot make a list read-write that you are not a master of.", conn, S_ERROR);
    return nil;
  end;

  if (not strfind(lists[l].flags, "R", 1, 1)) then
    send("That list isn't read-only!", conn, S_ERROR);
    return nil;
  end;

  lists[l].flags = gsub(lists[l].flags, "R", "");

  sendTo(format("%s has made the list read-write. {%s}", conn.username, lists[l].listname), getListMembers(l), S_LISTUNREAD);
  if (not listIsMember(conn.realUser, l, 1)) then
    send(format("%s has made the list read-write. {%s}", conn.username, lists[l].listname), conn, S_LISTUNREAD);
  end;

  saveOneList(l);

end;


function listClose(conn, list)
  local l = strlower(list);
  local l, err = listByName(conn, l, 1);
  if (not l) then
    send(err, conn, S_ERROR);
    return nil;
  end;

  if not isListMaster(l, conn.realUser) then
    send("You cannot close a list that you are not a master of.", conn, S_ERROR);
    return nil;
  end;

  if (not strfind(lists[l].flags, "O", 1, 1)) then
    send("That list is already closed!", conn, S_ERROR);
    return nil;
  end;

  lists[l].flags = gsub(lists[l].flags, "O", "");

  sendTo(format("%s has closed the list. {%s}", conn.username, lists[l].listname), getListMembers(l), S_LISTCLOSE);
  if (not listIsMember(conn.realUser, l, 1)) then
    send(format("%s has closed the list. {%s}", conn.username, lists[l].listname), conn, S_LISTCLOSE);
  end;
   
  saveOneList(l);

end;

function listPause(conn, list)
  if (not list) then
    if (not conn.pausedLists) then
      send("You have no paused lists.", conn, S_DONE);
      return nil;
    else
      send("Paused lists: " .. conn.pausedLists, conn, S_DONE);
    end;
    return nil;
  end;

  local llist = strlower(list);
  local rlist, err = listByName(conn, list);

  if (not rlist) then
    send(err, conn, S_ERROR);
    return nil;
  end;

  if (not listIsMember(conn.realUser, rlist)) then
    send("You cannot pause lists you are not a member of.", conn, S_ERROR);
    return nil;
  end;

  rlist = lists[rlist].listname;

  if (conn.pausedLists and strfind(conn.pausedLists, rlist .. " ", 1, 1)) then
    send("You already have that list paused!", conn, S_ERROR);
    return nil;
  end;

  if (not conn.pausedLists) then
    conn.pausedLists = "";
  end;

  conn.pausedLists = conn.pausedLists .. rlist .. " ";
  send("Paused list " .. rlist .. ".", conn, S_DONE);
end;

function listUnpause(conn, list)
  if (not list) then
    if (not conn.pausedLists) then
      send("You have no paused lists.", conn, S_DONE);
      return nil;
    else
      send("Paused lists: " .. conn.pausedLists, conn, S_DONE);
    end;
    return nil;
  end;

  local llist = strlower(list);
  local rlist, err = listByName(conn, list);

  if (not rlist) then
    send(err, conn, S_ERROR);
    return nil;
  end;

  if (not listIsMember(conn.realUser, rlist)) then
    send("You cannot unpause lists you are not a member of.", conn, S_ERROR);
    return nil;
  end;

  rlist = lists[rlist].listname;

  if (not conn.pausedLists or not strfind(conn.pausedLists, rlist .. " ", 1, 1)) then
    send("You do not have that list paused!", conn, S_ERROR);
    return nil;
  end;

  conn.pausedLists = gsub(conn.pausedLists, rlist .. " ", "");
  if (conn.pausedLists == "") then
    conn.pausedLists = nil;
  end;

  send("Unpaused list " .. rlist .. ".", conn, S_DONE);
end;

function listRename(conn, oldName, newName)
  if (oldName == nil or newName == nil) then
    send("Usage: .List Rename <list> <newname>", conn, S_ERROR);
    return nil;
  end;

  local oldName = strlower(oldName);
  local l, err = listByName(conn, oldName, 1);
  if (not l) then
    send(err, conn, S_ERROR);
    return nil;
  end;

  oldName = strlower(l)

  if not isListMaster(l, conn.realUser) then
    send("You cannot rename a list that you are not a master of.", conn, S_ERROR);
    return nil;
  end;

  if (lists[strlower(newName)]) then
    send("There is already a list with that name.", conn, S_ERROR);
    return nil;
  end;

  sendTo(format("%s has renamed %%%s to %%%s. {%s}", conn.username, lists[oldName].listname, newName, newName), getListMembers(oldName), S_LISTRENAME);
  if (not listIsMember(conn.realUser, l, 1)) then
    send(format("%s has renamed %%%s to %%%s. {%s}", conn.username, lists[oldName].listname, newName, newName), conn, S_LISTRENAME);
  end;


  lists[strlower(newName)] = lists[oldName];
  lists[oldName] = nil;
  lists[strlower(newName)].listname = newName;

  remove(colloquy.lists .. "/" .. strlower(oldName));
  saveOneList(strlower(newName));

end;

function listMaster(conn, list, user)
  local l, err = listByName(conn, list, 1);
  if (not l) then
    send(err, conn, S_ERROR);
    return nil;
  end;

  if not isListMaster(l, conn.realUser) then
    send("You cannot make somebody a master on a list you are not a master of.", conn, S_ERROR);
    return nil;
  end;

  local m, i, v;
  m = userByName(user);
  if (m == nil) then
    send("No such user.", conn, S_ERROR);
    return nil;
  end;

  if (type(m) == "string") then
    send(m, conn, S_ERROR);
    return nil;
  end;

  local mm = strlower(m.username);

  if isListMaster(l, m.realUser) then
    send(format("%s is already a master of that list.", m.username), conn, S_ERROR);
    return nil;
  end;

  if not listIsMember(m.realUser, l) then
    send(format("%s is not on that list.", m.username), conn, S_ERROR);
    return nil;
  end

  if not lists[l].masters then
    lists[l].masters = {};
  end;

  tinsert(lists[l].masters, strlower(m.realUser));
  sendTo(format("%s has made %s a list master. {%s}", conn.username, m.username, lists[l].listname), getListMembers(l), S_LISTMASTER);
  if not listIsMember(conn.realUser, l, 1) then
    send(format("%s has made %s a list master. {%s}", conn.username, m.username, lists[l].listname), conn, S_LISTMASTER);
  end;

  saveOneList(l);

end;

function listUnmaster(conn, list, user)
  local l, err = listByName(conn, list, 1);
  if (not l) then
    send(err, conn, S_ERROR);
    return nil;
  end;

  if not isListMaster(l, conn.realUser) then
    send("You cannot unmaster somebody on a list you are not a master of.", conn, S_ERROR);
    return nil;
  end;

  local m, i, v;
  m = userByName(user);
  if (m == nil) then
    send("No such user.", conn, S_ERROR);
    return nil;
  end;

  if (type(m) == "string") then
    send(m, conn, S_ERROR);
    return nil;
  end;

  local mm = strlower(m.username);

  if not isListMaster(l, m.realUser) then
    send(format("%s is not a master of that list.", m.username), conn, S_ERROR);
    return nil;
  end;

  if not listIsMember(m.realUser, l) then
    send(format("%s is not on that list.", m.username), conn, S_ERROR);
    return nil;
  end

  for i, v in lists[l].masters or {} do
    if v == strlower(m.realUser) then
      tremove(lists[l].masters, i);
      break;
    end;
  end;
  
  sendTo(format("%s has unmastered %s. {%s}", conn.username, m.username, lists[l].listname), getListMembers(l), S_LISTMASTER);
  if not listIsMember(conn.realUser, l, 1) then
    send(format("%s has unmastered %s. {%s}", conn.username, m.username, lists[l].listname), conn, S_LISTMASTER);
  end;

  saveOneList(l);

end;

function listHasPaused(conn, list)
  if (conn.pausedLists) then
    return strfind(conn.pausedLists, lists[strlower(list)].listname .. " ", 1, 1);
  else
    return nil;
  end;
end;

function loadLists(dirname)
  dirname = dirname or colloquy.lists
  local dir = pfiles(dirname .. "/")
  if dir then
    local e = dir();
    while (e) do
      if (not strfind(e, "^%.") and strlower(e) == e) then
        lists[e] = dofile(dirname .. "/" .. e)
      end
      e = dir()
    end
  else
    -- let's check to see if there's an old-style single-file
    -- lists file that we can convert to the new style.
    if pstat(colloquy.base .. "/data/lists.lua") then
      write(" (importing old list data)"); flush();
      dofile(colloquy.base .. "/data/lists.lua")
      rename(colloquy.base .. "/data/lists.lua", colloquy.base .. "/data/lists-old.lua")
    end
    pmkdir(dirname)
    saveLists(dirname)    
  end
end

function saveLists(dirname)
  dirname = dirname or colloquy.lists
  for i, v in lists do
    if (type(v) == "table" and strlower(i) == i) then
      local f = openfile(dirname .. "/" .. strlower(i), "w")
      write(f, "return ")
      dumpList(v, f, 0)
      closefile(f)
    end
  end
end

function saveOneList(list)
  local f = openfile(colloquy.lists .. "/" .. strlower(list), "w")
  write(f, "return ")
  dumpList(lists[list], f, 0)
  closefile(f)
end

function dumpList(table, f, indent)
  write(f, "{\n")
  indent = indent + 2

  for j, k in table do
    if (j ~= "n") then
      write(f, strrep(" ", indent) .. j .. " = ")
      t = type(k)
      if     (t == "string") then
        k = format("%q", k)
        write(f, k, ",\n")
      elseif (t == "number") then write(f, k, ",\n")
      elseif (t == "table") then 
        -- tables inside list tables only ever contain strings, so
        -- this is slightly easier.
        write(f, "{ ")
        for q, w in k do
          if type(w) == "string" then
            write(f, format("%q, ", w))
          end
        end
        write(f, "},\n")
      end
    end
  end
  indent = indent - 2;
  write(f, strrep(" ", indent), "}\n")
end
