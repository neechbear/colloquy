-- non-blocking sockets object
-- requires LuaSocket, stringStack.

assert(stringStack, "stringstack is needed.");
assert(select, "LuaSocket is needed.");

-- Usage:
-- To create a client socket from a server socket with a connection waiting, do
--   myClient = clientSocket:accept(myServer);
--
-- To poke some data into the send buffer for a client socket...
--   myClient:send(string);
--
-- To see if there is some data waiting for you...
--   s = myClient:readyRead(pattern);
-- where pattern is a strfind pattern to decide if a whole interesting thing has
-- arrived.  Returns it as a string if it is, returns an empty string when there
-- is nothing waiting, and nil if the socket has been closed.
--
-- To send data to a socket (when read from select())...
--   n = myClient:readySend();
-- n is non-nil if the socket has been closed.

clientSocket = {
   
   recBuff = {},     -- contains a stringStack with received chunks
                     -- of data in it.  When you use the readyRead()
                     -- method, and the pattern passed to it matches,
                     -- it concatanates the string, and returns it.

   sendBuff = {},    -- contains a list of strings that need to be
                     -- sent to the client.  This is used to send
                     -- data when the readySend() method is called.

   socket = nil,     -- LuaSocket's handle for this connection.

   writers = {},     -- contains luasocket handles that have data
                     -- waiting to be written.

   toClose = nil,    -- this socket needs to be closed once all data has
                     -- been sent.

   accept = function(self, server)
       -- This function is called in the form clientSocket:accept(s),
       -- where 's' is the server socket which has just recieved a
       -- connection.  It returns a table to represent that socket,
       -- which has all of the other functions in it.
       
       local r;
       r = {
          recBuff = stringStack:new(),
          sendBuff = {},
          socket = accept(server),
          send = self.send,
          readySend = self.readySend,
          readyPeek = self.readyPeek,
          readyRead = self.readyRead,
          close = self.close,
          echo = nil,
       };

       if (r.socket) then
         r.socket:timeout(0, "b");  -- make socket non-blocking
         return r;
       else
         return nil;
       end;
    end,
   
   new = function(self, ip, port)
    -- This function actually creates a connection to somewhere else...
    
    local r;
    local t = secs;
    r = {
       recBuff = stringStack:new(),
       sendBuff = {},
       socket = nil,
       send = self.send,
       readySend = self.readySend,
       readyPeek = self.readyPeek,
       readyRead = self.readyRead,
       close = self.close,
    };

    while ((secs < t + 3) and r.socket == nil) do
       r.socket = connect(ip, port);
    end;
   
    if (r.socket == nil) then return nil end;

    r.socket:timeout(0, "b");  -- make socket non-blocking
    
    return r;
  end,

   close = function(self)
      -- This function closes a socket, and tidies up.
      if (getn(self.sendBuff) > 0) then
        -- remove ourself from the writers list...
        foreachi(clientSocket.writers, function(i, v)
          if (v == %self.socket) then
            tremove(clientSocket.writers, i);
            return 1;
          end;
        end);
      end;
      self.sendBuff = {};
      self.recBuff = {};
      self.socket:close();
      self.socket = nil;
   end,

   send = function(self, string)
     -- This function adds a string to the send table.
     if (self.toClose and self.toClose > 1) then return nil end;
     if (getn(self.sendBuff) == 0) then
       tinsert(clientSocket.writers, self.socket);
     end;

     tinsert(self.sendBuff, string);
   end,
   
   readySend = function(self)
     -- This function tries to send as much data in the send
     -- table to self.socket before it would block, and the
     -- returns, after updating the send buffer.  It returns
     -- non-nil if the connection has closed.
     local err, sent, string, v;

     while (self.sendBuff.n > 0) do
       string = self.sendBuff[1];
       err, sent = self.socket:send(string);
       if (err == "closed") then
         if (self.toClose == 1) then
           self.toClose = 2;
         end;
         return 1;
       end;

       if (sent < strlen(string)) then
         -- we didn't get to send it all...
         -- update this string to chop what we've sent,
         -- and then return.
         self.sendBuff[1] = strsub(string, sent + 1, -1);
         return nil;
      else
         -- we sent it all!  yay!  remove the entry.
         tremove(self.sendBuff, 1);
      end;
    end;
  
    -- we've sent all waiting data, remove us from the
    -- writers table.
    v = clientSocket.writers;
    for i=1, getn(v) do
      if (v[i] == self.socket) then
        tremove(v, i);
        break;
      end;
    end;

   if (self.toClose == 1) then
     self.toClose = 2;
   end;

   end,

   readyRead = function(self, pattern)
     -- This function reads the available data from the
     -- socket and adds it to the recieved string stack.
     -- If the string read matches 'pattern', the string
     -- is concatenated, returned, and the stringstack
     -- emptied.  If no string is ready, it returns "",
     -- if the connection has been closed, it returns
     -- nil.

    local r, err, s, l;
    repeat
     r, err = self.socket:receive("*a");
     if (err ~= "" and err ~= "timeout") then return nil end;   
     if (not self.toClose) then
       if (self.echo ~= nil) then
         self:send(r);
         dataSent = dataSent + (strlen(r));
       end;

       self.recBuff:add(r);

       -- Check what has just been read, and the last read too, since a peek
       -- may have appeneded our pattern to the stack
       if (self.recBuff.stack.n > 1 and r ~= nil) then
         r = self.recBuff.stack[self.recBuff.stack.n-1] .. r;
       end;

       if (strfind(r, pattern, 1) ~= nil) then
         s = self.recBuff:create();
         self.recBuff = stringStack:new();
         if (debugFile) then
           write(debugFile, "read data from ", tostring(self.socket), ": ", (r or "(no data)"), "\n")
           flush(debugFile)
         end
         return s or "";
       end;
     end;
  until (err == "timeout");

  return "";
  end,

   readyPeek = function(self, pattern)
     -- This function reads the available data from the
     -- socket and adds it to the recieved string stack.
     -- If the string read matches 'pattern', the string
     -- is concatenated, returned, and the stringstack
     -- emptied.  If no string is ready, it returns "",
     -- if the connection has been closed, it returns
     -- nil.

    local r, err, s, l;
    repeat
     r, err = self.socket:receive("*a");
     if (err ~= "" and err ~= "timeout") then return nil end;   
     if (not self.toClose) then

       self.recBuff:add(r);
       if (strfind(self.recBuff:create(), pattern, 1) ~= nil) then
         s = self.recBuff:create();
         return s;
       end;
     end;
  until (err == "timeout");

  return "";
  end,
};
