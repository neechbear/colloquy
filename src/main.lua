main = 1;
punctuation = [[!;':@?,`.]]

_oldError = _ERRORMESSAGE;
lastInput = "<none>";
lastUser = "<none>";

ErrorTime = getSecs();
Errors = 0;

function HandleError(s)

   if (secs > (ErrorTime + 5)) then
     ErrorTime = secs;
     Errors = 0;
   end;

   Errors = Errors + 1;

   if (Errors > 15) then
     print("ERK!  Too many errors, giving up and quitting.");
     exit(1);
   end;

   local r, i;
   r = s .. "\ncaused by <";
   r = r .. lastInput;
   r = r .. "> by ";
   r = r .. lastUser;
   r = r .. ". stack backtrace:\n";

   local f;

   f = colloquy.logfile;

   print(strsub(r, 1, -2));

   if (f) then
     write(f, r);
   end;

   for i = 2, 1000 do
      local a = getinfo(i)
      if a==nil then break end
      r = i - 1 .. ":"
      if (a.name) then r =r .. " function '" .. a.name .. "'"; end;
      if (a.currentline > -1) then
        r = r .. " at line " .. a.currentline;
      end;
      r = r .. " [" .. a.short_src .. "]\n";
      print(strsub(r, 1, -2));
      if (f) then
        write(f, r);
      end;
   end
   write("\n");
   print("");
   sendToAll("WARNING: Caught an error that shouldn't have happened.  Blame " .. lastUser .. ".", S_ALERT);
end

function db(v)
  print(v);
end;

function handleWrites(sockets)
   local i, v, err;

   for i, v in sockets do
      local c = colloquy.connections[v]
      if (v == colloquy.resolver.socket) then
        colloquy.resolver:readySend();
      elseif (c and c.socket and c.socket:readySend() ~= nil and not c.socket.toClose) then
        disconnectUser(v, "- Connection closed.");
      end;

      local conn = colloquy.connections[v];

      if (v ~= colloquy.resolver.socket and conn and conn.socket.toClose == 2) then
        conn.socket.socket:close();
        colloquy.connections[v] = nil;
      end;

   end;
end;

function printString(a)
  local i, s;

  for i=1,strlen(a) do
    write(strbyte(a, i) .. " ");
  end
  write("\n");

  for i=1,strlen(a) do
    if (strbyte(a, i) > 31 and strbyte(a, i) < 100) then
      write(strsub(a, i, i) .. "  ");
    elseif (strbyte(a, i) > 100 and strbyte(a, i) < 127) then
      write(strsub(a, i, i) .. "   ");
    else
      write("   ");
    end;
  end;
  write("\n\n");

end;

function handleReads(sockets)
   local i, v, err, string;

   for i, v in sockets do
      if (v == colloquy.server) then
         connectUser();
      elseif (v == colloquy.botServer) then
         connectUser(1);
      elseif (v == colloquy.metaServer) then
         connectUser(2);
      elseif (v == colloquy.resolver.socket) then
         string = colloquy.resolver:readyRead("\n");
         if (string == nil) then
            log("Connection to resolver lost.");
            return nil;
         elseif (string ~= "") then
            resolverResult(string);
         end;
      else
        if (colloquy.connections[v] == nil or colloquy.connections[v].socket == nil) then
          return nil;
        end;
       
       local conn = colloquy.connections[v];

       local opts = conn.socket:readyPeek("\255");
       if (opts ~= nil and opts ~= "") then
         opts = conn.socket:readyRead("\255");
         string = parseTelnetOpts(opts, conn);
       end;

       if (string == nil) then
         string = conn.socket:readyRead("[\n\r]");
       else
         string = string .. conn.socket:readyRead("[\n\r]");
       end;

       if (string == nil) then
         disconnectUser(v, "- Connection closed.");
         conn.socket:close();
         colloquy.connections[v] = nil;
         return nil;
       elseif (string ~= "") then
         -- wahey!  We've a line of text.  Let us bounce.
         -- remove delete characters first...
   
         while (strfind(string, "\127")) do
           string = gsub(string, "^\127", "");
           string = gsub(string, "[^\127]\127", "");
         end;

         while (strfind(string, "\8")) do
           string = gsub(string, "^\8", "");
           string = gsub(string, "[^\8]\8", "");
         end;

         lastUser = conn.username;
         lastConnection = conn;
      
         -- work though thr string, getting each chunk ended by \r\n, and pass it to parseInput...
         local tmp = gsub(string, "\r\n", "\n");
         tmp = gsub(string, "\n\r", "\n");
         if (not strfind(tmp, "\n", 1, 1)) then
           tmp = tmp .. "\n";
         end;
          
         local l;
         repeat
           l = strsub(tmp, 1, strfind(tmp, "\n", 1, 1) - 1);
           call(parseInput, {v, l}, "x", HandleError);
           tmp = strsub(tmp, strfind(tmp, "\n", 1, 1) + 1, -1);
         until not strfind(tmp, "\n", 1, 1) 
       end;
    end;
 end;
end;

function log(...)
   tinsert(arg, 1, date() .. ": ");
   tinsert(arg, 1, colloquy.logfile);
   tinsert(arg, arg.n + 1, "\n");
   call(write, arg); 
   flush(colloquy.logfile);
end;

lastLogRotation = date("%Y%m%d");

function expireLists()
  local toDie = {}
  for i, v in lists do
    if ( not v.used ) then
      -- this has never been used!  give it the benefit of the doubt, and set it to now.
      v.used = secs;
    end;

    if ( (secs - v.used) > (60*60*24*(colloquy.listExpirey)) and not strfind(v.flags, "P", 1, 1) ) then
      -- Awwww!  I bet it feels unwanted.  Let's kill it, and put it out of it's misery.
      tinsert(toDie, i);
    end;
  end;
  for i, v in toDie do
    if (type(v) == "string") then
      lists[v] = nil;
    end;
  end;
end;

function doHousekeeping()
   
   local i, v;
   local toDelete = {}
   
   for i, v in colloquy.connections do
     if (v.status == 0) then
       -- they've not yet logged on...
       if ((secs - v.idle) > 30) then
         send("Your logon has timed out.", v, S_DISCONNECT);
         disconnectUser(i, "");
       end;
     end;

     if (colloquy.guestTimeout and v.status == 1) then
       -- timeout guests...
       if ((secs - v.conTime) > colloquy.guestTimeout) then
         sendGM(v, S_DISCONNECT, "gGuestTimeout");
         disconnectUser(i, "- Guest for too long.");
       elseif (not v.warned and (secs - v.conTime) > (colloquy.guestTimeout - 60)) then
         sendGM(v, S_WARN, "gGuestTimeout1")
         v.warned = 1;
       end
     end
 
     if ((secs - v.idle) > colloquy.maxIdle * 60) then
       if (colloquy.kickIdle) then
         if ((v.privs and strfind(v.privs, "Z", 1, 1)) or (v.restrict and strfind(v.restrict, "B", 1, 1))) then
           v.idle = secs;
         else
           sendGM(v, S_DISCONNECT, "gIdledOut");
           disconnectUser(i, "- Idled out");
         end;
       elseif (not v.veryIdle and not (v.restrict and strfind(v.restrict, "B", 1, 1))) then
         sendGMAll(S_IDLE, "gAutoIdle", v.username);
         v.idleReason = "Became automatically idle: " .. date("%a %b %e %H:%M:%S %Y");
         v.veryIdle = colloquy.maxIdle * 60 ;
       end;
     end;

     if (v.timeWarn ~= 0 and v.timeWarn > 0 and (secs > v.timeTick)) then
       v.timeTick = secs + (v.timeWarn * 60);
       commandMark(v.socket.socket, ".-");
    end;
 
    if (v.group == "" and v.c) then
      -- an empty connection - must fix this, this shouldn't happen.
      tinsert(toDelete, {v.socket.socket, i});
    end;
   end;

   if (getn(toDelete) > 0) then
     for i, v in toDelete do
       if (i ~= "n") then
         close(v[1]);
         colloquy.connections[v[2]] = nil;
       end
     end
     buildSocketReaders();
   end 

   if (colloquy.logRotate and date("%H%M") == "0000" and lastLogRotation ~= date("%Y%m%d")) then
     log("Rotating log file");
     lastLogRotation = date("%Y%m%d");
     closefile(colloquy.logfile);
     execute(date(colloquy.logRotate));
     remove(colloquy.logName)
     colloquy.logfile = openfile(colloquy.logName, "a")
     log("Rotated log file");
   
     if (not colloquy.kickIdle) then
       -- save all the users to disc.
       local i, v;
       for i, v in colloquy.connections do
         if (type(v) == "table") then
           saveOneUser(strlower(v.realUser));
         end;
       end;
       log("Saved connected users to disc");
       
       local oldUsage = gcinfo();
       collectgarbage();
       log("Collected " .. tostring(oldUsage - gcinfo()) .. "kB of garbage");
     end;
     -- now expire lists that havn't been used in 28 days...
     expireLists();
   end;
   
   if date("%H%M") == "0000" and lastNewDate ~= date("%Y%m%d") then
     -- now tell everybody about the date change
     sendToAll(format("Date changed to %s.", date("%A %b %d %Y")), S_DONE);
     lastNewDate = date("%Y%m%d");
   end;

end;

function selectery()
   local sockets, readyRead, readySend, error;
   getSecs(1);
   if not colloquy.readingSockets then buildSocketReaders() end;
   clientSocket.writers.n = nil
   readyRead, readyWrite, error = select(colloquy.readingSockets, clientSocket.writers, 2);

   secs = getSecs();

   if (error ~= "timeout") then
      handleWrites(readyWrite);
      handleReads(readyRead);
   end;

   if (secs - lastHousekeep >= 2) then
      doHousekeeping();
      lastHousekeep = secs;
   end;
end;

function empty(t)
  local i, v, k;
  k = 0;
  for i, v in t do
    k = k + 1;
  end;
  return k == 0;
end;
