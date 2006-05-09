function Resolver()
  local bind, print, tohostname, exit, collectgarbage, globals = 
        bind, print, tohostname, exit, collectgarbage, globals
  local resolverIP = colloquy.resolverIP
  local resolverPort = colloquy.resolverPort
  
  local sock, err = bind(resolverIP, resolverPort)
  local talker
  local l, h

  if not sock then
    print("\n+++ Failed to bind to resolver port: " .. err)
    exit(1)
  end

  -- wait for the connection from the main talker
  talker = sock:accept()
  
  sock:close()
  sock = nil
  pclose(0)
  pclose(1)
  pclose(2)

  globals { tostring = tostring } -- eugh.  we crash without this.
  bind, print, globals =  nil -- we don't need these now, either.
  collectgarbage()
  collectgarbage = nil

  while(1) do
    l = talker:receive("*l")  
    if not l or l == "" then
      -- talker has disconnected, quit.
      exit(0)
    end
    h = tohostname(l)
    h = h or l
    talker:send(l, " ", h, "\n")
  end
end

