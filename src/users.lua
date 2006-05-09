-- stuff to handle users

users = {
   god = {
      password = crypt("godgod"), -- god's default password is "god"
      privs = "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
      site = "",
      talktime = 0,
   }
}

-- the users table is keyed by lower-case username.  The values are
-- a table describing that user, in the following form:
--  .password  = [string] an md5 hash of their password
--  .password2 = [string] new style password - md5 of their username concatenated with their password
--  .privs     = [string] a list of the user's priviledges.
--  .site      = [string] site the user last connected from
--  .talktime  = [number] how many minutes the user has been connected
--  .name      = [string] real name of the user
--  .birthday  = [string] date of birth in ISO format
--  .location  = [string] where the user is based
--  .homepage  = [string] url to user's homepage
--  .email     = [string] user's email address
--  .sex       = [stirng] male/female/etc
--  .around    = [string] when the user is next around
--  .restrict  = [string] list of restrictions (eg, G)
--  .timeon    = [number] seconds of online time.
--  .connected = [number] time of their connection, if they're connected now, otherwise nil.
--  .idlePrompt= [string] If they want something as their prompt when idle

function escapeUserData(data)
  -- does stuff to a string so it can be safely saved...
  -- strings are assumed to only be sensitive to the double quote chartacter.
  local p, l = 1;
  local r = '" .. strchar(34) .. "';
  local rl = strlen(r);
  local dl = 0;

  repeat
    l = strfind(data, '"', p, 1);
    if (l) then
      data = strsub(data, 1, l - 1) .. r .. strsub(data, l + 1, - 1);
      p = l + rl;
      dl = strlen(data);
    end;
  until l == nil or p > dl

  return data;
end;

function saveUsers(dirname)
   -- dumps the users table to file in an executable form

   for i, v in users do
     if (type(v) == "table" and strlower(i) == i) then
       local f = openfile(dirname .. "/" .. strlower(i), "w");
       write(f, "return ")
       dumpUser(v, f, 0)
       closefile(f)
     end
   end
end;

function saveOneUser(user)
  local f = openfile(colloquy.users .. "/" .. strlower(user), "w");
  write(f, "return ")
  dumpUser(users[strlower(user)], f, 0)
  closefile(f)
end

function loadUsers(dirname)
  local dir = pfiles(dirname .. "/")
  if dir then
    local e = dir();
    while (e) do
      if (not strfind(e, "^%.") and strlower(e) == e) then
        users[e] = dofile(dirname .. "/" .. e);
      end
      e = dir();
    end
  else
    if pstat(colloquy.base .. "/data/users.lua") then
      write(" (importing old user data)"); flush();
      dofile(colloquy.base .. "/data/users.lua");
      rename(colloquy.base .. "/data/users.lua", colloquy.base .. "/data/users-old.lua");
      pmkdir(dirname)
      saveUsers(dirname)
    else
      users = {
        god = {
          password = crypt("godgod"), -- god's default password is "god"
          privs = "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
          site = "",
          talktime = 0,
        }
      }
      pmkdir(dirname);
      saveOneUser("god");
    end
  end
end

function dumpUser(table, f, indent)
   write(f, "{\n"); indent = indent + 2;

   if not table.password then
     table.password = table.password2;
     table.password2 = nil;
   end

   for j, k in table do
     if (j ~= "n" and j ~= "connected") then
       write(f, strrep(" ", indent) .. j .. " = ");
       t = type(k);
       if     (t == "string") then
         k = format("%q", k);
         write(f, k, ",", "\n");
       elseif (t == "number") then write(f, k .. ",\n");
       elseif (t == "table")  then saveTable(k, f, indent);
       end;
     end;
   end;
   indent = indent - 2; write(f, strrep(" ", indent) .. "}\n");
end

function saveTable(table, f, indent)
   local i, v;

   write(f, "{\n"); indent = indent + 2;

   for i, v in table do
      if (i ~= "n") then
         write(f, strrep(" ", indent) .. i .. " = {\n"); indent = indent + 2;
         local j, k, t;
         for j, k in v do
            if (j ~= "n" and j ~= "connected") then
               write(f, strrep(" ", indent) .. j .. " = ");
               t = type(k);
               if     (t == "string") then 
                 k = format("%q", k);
                 write(f, k, ",", "\n");
               elseif (t == "number") then write(f, k .. ",\n");
               elseif (t == "table")  then saveTable(k, f, indent);
               end;
            end;
         end;
         indent = indent - 2; write(f, strrep(" ", indent) .. "},\n");
      end;
   end;

   write(f, "}\n");

end;

--function loadUsers(filename)
--   dofile(filename);
--end;

function checkPasswordWithAuthenticator(authenticator, user, password)
  local null, null, rUser, host, port = strfind(authenticator, "^([^%@]-)%@([^%:]-):(.-)$");
  if (not null) then
    return nil, "Invalid authenticator field.";
  end;
  local s = connect(host, port);
  if (not s) then
    return nil, "Unable to connect to authenticator.";
  end;
  s:send(format("auth %s %s\n", rUser, password));
  local r = s:receive("*l");
  s:close();
  if (not r) then
    return nil, "Unable to get response from authenticator.";
  end;
  local null, null, code, message = strfind(r, "^auth (.-) (.-)$");
  if (not null) then
    return nil, "Invalid response from authenticator.";
  end;
  if (code == "1") then
    return 1, message;
  else
    return nil, message;
  end;
end;

function checkPassword(user, password)
  user = strlower(user);
  if (users[user].authenticator) then
    -- they have an authenticator!
    return checkPasswordWithAuthenticator(users[user].authenticator, user, password);
  else
    if (users[user].password == crypt(user .. password)) then
      return 1, "";
    else
      return nil, "Incorrect password.";
    end;
  end;
end;

function changePassword(user, old, new)

  user = strlower(user);
  if (users[user].authenticator) then
    local null, null, rUser, host, port = strfind(users[user].authenticator, "^([^%@]-)%@([^%:]-):(.-)$");
    if (not null) then
      return nil, "Invalid authenticator field.";
    end;
    local s = connect(host, port);
    if (not s) then
      return nil, "Unable to connect to authenticator.";
    end;
    s:send(format("pass %s %s %s\n", rUser, old, new));
    local r = s:receive("*l");
    s:close();
    if (not r) then
      return nil, "Unable to get response from authenticator.";
    end;
    local null, null, code, message = strfind(r, "^pass (.-) (.-)$");
    if (not null) then
      return nil, "Invalid response from authenticator.";
    end;
    if (code == "1") then
      return 1, message;
    else
      return nil, message;
    end;
  else
    local pr, message = checkPassword(user, old);
    if (not pr) then
       return nil, (message or "Incorrect old password");
    end;
 
    users[user].password2 = crypt(user .. new);
    users[user].password = nil;
    saveUsers(colloquy.users);

    return 1, "Password changed.";
  end;
end;
