#!bots/lua -f 
-- Colloquy GagBot, by Rob Kendrick
-- Based on Nick Waterman's EH GagBot

_ = {};
function match(pattern, string)
  if (not string) then string = String; end;

  local t = { _ = {} };
  local tmp, r = gsub(string, pattern, function(...)
                                      %t._ = arg;
                                    end);
  _ = t._;
  if (r > 0) then
    return r;
  else
    return nil;
  end;
end;

function split(string)
   local t = {};
   gsub(string, " *([^ ]+) *", function(v) 
				  if (strlen(v) > 0 ) then 
				     tinsert(%t,v);
				  end;
			       end);
   return t;
end;

function print(...)
  tinsert(arg, 1, date() .. " ");
  tinsert(arg, "\n");
  call(%write, arg);
end;

restart = nil;

if (not arg) then arg = {} end;

if (arg[1] == "--help" or arg[1] == "-h") then
  print(arg[0] .. " [host] [port] [password] [username] [group]");
  exit();
end;

repeat
  local botVersion = "0.0.9";
  local serverHost = arg[1] or "catfish.pepperfish.net";
  local serverPort = arg[2] or 1236;
  local botName = arg[4] or "GagBot";
  local botPassword = arg[3] or "passwordhere";
  local botGroup = arg[5] or "Bots-R-Us";

  local mingag    =  10; -- 10 mins gag for first offence.
  local maxgag    = 120; -- 2 hrs maximum gag.
  local gagscale  =   2; -- multiplier for further offences.
  local maxshouts =   2; -- max shouts for one person in any N-min period.
  local watchmins =   5; -- the "N" menioned above
  local shoutfest =   4; -- max shouts in total, from ANYONE.
  local nextgagfn = "gagbot.nextgags";
  local decperday =  10; -- remove 10 mins of gag time per day
  
  local loa       =  {}; -- table of who each name is Logged On As.
  local idling    =  {}; -- table of who is idling.
  local ungag     =  {}; -- table of who's gagged and how long for.
  local nextgag   =  {}; -- how long they'd be gagged for next time.
  local shouts    =  {}; -- shouts within the last N minutes,
        exing     =  ""; -- who we're examining right now.
        socket    = nil; -- our socket handle
  local markcount =   0; -- used for anti-idling
  local startedup =   1; -- used when connecting
  
  -- people who I trust with extra admin commands.  Will automagically
  -- have "list info masters" added to it.
  local trusted   =  {};

  -- for loop detection
        lasttime  = 0;
        thissec   = 0;
  

  for i=0,watchmins do
    shouts[i] = {};
  end;

  local readNextGag = function()
    local f = openfile(%nextgagfn, "r");
    if (not f) then
      return print("# unable to read " .. %nextgagfn);
    end;
    local l = read(f);
    
    while (l) do
      if (match("^(%w+)%:(%d+)$", l)) then
        %nextgag[_[1]] = tonumber(_[2]);
      end;
      l = read(f);
    end;
    closefile(f);    
  end;

  local shift = function(t)
    local i;
    for i=1,getn(t) - 1 do
      t[i] = t[i + 1];
    end;
    t[getn(t)] = {};
  end;

  local writeNextGag = function()
    local f = openfile(%nextgagfn, "w");
    if (not f) then
      return print("# unable to write " .. %nextgagfn);
    end;

    foreach(%nextgag, function(a, b)
                        write(%f, format("%s:%s\n", a, b));
                      end);
    closefile(f);
  end;

  local tread = function()
    String = socket:receive();
    if (String == "" and not restart) then
      print("# Talker has gone away!");
      exit();
    end;
    return String;
  end;

  local tsend = function(...)
    tinsert(arg, 1, socket);
    call(send, arg);
  end;

  local connectTalker = function()
    local err;
    print("# Trying to connect to talker...");
    socket, err = connect(%serverHost, %serverPort);
    if (not socket) then
      print("# " .. err);
      exit();
    end;
  end;

  local loginTalker = function()
    print("# waiting for login prompt.");
    while (%tread()) do
      if match("^HELLO ") then break end;
    end;

    print("# logging on");
    %tsend(format("%s@%s %s\n", %botName, %botGroup, %botPassword));

    while (%tread()) do
      if (match("^%+%+%+ Name is already in use")) then
        print("# already on!");
        %tsend(format("*%s@%s %s\n", %botName, %botGroup, %botPassword));
      elseif (match("^MARK")) then
        break;
      end;
    end;

    print("# setting timewarn, and seeing who's on");
    %tsend(".set timewarn 1\n.groups\n.list info masters\n");

  end;

  local loopcheck = function()
    local thistime = tonumber(date("%s"));
    if (thistime > lasttime) then
      lasttime = thistime + 1;
      thissec = 0;
    end;

    thissec = thissec + 1;
    if (thissec > 30) then
      print("loop detected");
      %tsend(".quit loop detected - quitting to avoid spamming\n");
      exit();
    end;
  end;

  local totshouts = function(acc)
    local t = { tot = 0 };

    foreachi(%shouts, function(i, v)
                       --print("* ", i, " ", v);
                       if (v) then
                         %t.tot = %t.tot + (v[%acc] or 0);
                       end;
                     end);
    return t.tot;
  end;

  local dumptable = function(table)
    if (not table) then return "" end;
    local r = { r = "" };
    foreach(table, function(i, v) %r.r = %r.r .. i .. "=" .. v .. " "; end);
    return r.r;
  end;

  local doTell = function(user, stuff)
    local luser = strlower(user);
    local lstuff = strlower(stuff);
    local acc = %loa[luser];

    -- ignore myself and other bots.
    if (match("bot$", luser)) then
      print(format("# %s : %s"), user, stuff);
      print("# loop?");
      
    -- user commands - help, version
    elseif (match("^help", lstuff)) then
      print(format("# %s needs help.", user));
      %tsend(format(">%s I am GagBot. I gag and ungag people. Commands available:\n", user));
      %tsend(format(">%s help, version: hopefully obvious\n", user));
      %tsend(format(">%s stats: tells you your own gag status\n", user));

      if (not %trusted[acc]) then return nil; end;

      %tsend(format(">%s ungag <user> <N>: ungags <user> in <N> mins time.\n", user));
      %tsend(format(">%s nextgag <user> <N>: sets 'next offence' gag time for user.\n", user));
      %tsend(format(">%s tables: shows all tables - LoggedOnAs, how long un-gags, how long next gag will be, who's shouted " ..
                    "in the last few mins, etc.\n", user));
      %tsend(format(">%s exec: re-runs bot (EG If a new version has been installed)\n", user));
      %tsend(format(">%s lua: executes some instructions inside GagBot's VM.\n", user));
    elseif (match("^version", lstuff)) then
      print(format("# %s asks version", user));
      %tsend(format(">%s %s verison %s by Bob, based on source donated by NoseyNick\n", user, %botName, %botVersion));
      
    -- command to view my own gag stats
    elseif (match("^stats", lstuff)) then
      print(format("# %s asks their stats", user));
      if (%ungag[acc]) then
        %tsend(format(">%s Your account is gagged. I will ungag you within approx %d mins.\n", user, %ungag[acc]));
      else
        %tsend(format(">%s Your account is not gagged.\n", user));
      end;
      local ti = %nextgag[acc] or %mingag;
      if (ti < %mingag) then ti = %mingag end;
      %tsend(format(">%s For your 'next offence' you'd be gagged for %d mins.\n", user, ti));
      %tsend(format(">%s In the last %d mins, I've seen %d shouts, %d of which were yours.\n", user, %watchmins, %totshouts(""),
             %totshouts(acc)));
             
      -- otherwise check we're an admin...
      elseif (not %trusted[acc]) then
        print(format("# %s : %s", user, stuff));
        %tsend(format(">%s Unknown command. See >%s help\n", user, %botName));
        return nil;
     
      -- admin command: scan
      elseif (match("^ungag%s+(%S+)%s(%-?%d+)", lstuff)) then
        print(format("# %s asks me to ungag %s in %d mins", user, _[1], _[2]));
        %ungag[_[1]] = _[2];
        %tsend(format(">%s %s will be un-gagged in %d mins.\n", user, _[1], _[2]));
     
      -- admin command: nextgag
      elseif (match("^nextgag%s+(%S+)%s(%-?%d+)", lstuff)) then
        print(format("# %s asks me to set next gag time for %s to %d mins", user, _[1], _[2]));
        %nextgag[_[1]] = _[2];
        %writeNextGag();
        %tsend(format(">%s %s will be gagged for %d mins for next offence.\n", user, _[1], _[2]));

      -- admin command: show all tables
      elseif (match("^tables", lstuff)) then
        print(format("# %s checks all tables", user));
        %tsend(format(">%s LoggedOnAs: %s\n", user, %dumptable(%loa)));
        %tsend(format(">%s Trusted:    %s\n", user, %dumptable(%trusted)));
        %tsend(format(">%s UnGag:      %s\n", user, %dumptable(%ungag)));
        %tsend(format(">%s NextGag:    %s\n", user, %dumptable(%nextgag)));
        %tsend(format(">%s Idlers:     %s\n", user, %dumptable(%idling)));
        local n;
        for n = 0,%watchmins do
          %tsend(format(">%s Shouts-%d:  %s\n", user, n, %dumptable(%shouts[n])));
        end;
        %tsend(format(">%s Settings:   telnet://%s:%d. Max %d per person per %dm, Shoutfest is %d.  Gag time %dm * %d per " ..
                      "offence, -%dm/day, max %dm.\n", user, %serverHost, %serverPort, %maxshouts, %watchmins, %shoutfest,
                      %mingag, %gagscale, %decperday, %maxgag));

      -- admin command: exec
      elseif (match("^exec", lstuff)) then
        print(format("# %s re-runs...", user));
        %tsend(".quit\n");
        %writeNextGag();
        --execute("exec ./luas gagbot.lua");
        --exit();
        restart = 1;
      elseif (match("^do (.+)", lstuff)) then
        print(format("# %s asks me to do: %s", user, _[1]));
        %tsend(_[1], "\n");
      elseif (match("^lua (.+)", lstuff)) then
        print(format("# %s asks me to execute: %s", user, _[1]));
        dostring(_[1]);
      else
        print(format("# %s : %s", user, stuff));
        %tsend(format(">%s Unknown command. See >%s help\n", user, %botName));
    end;
  end;
  
  print(format("# %s version %s", botName, botVersion));
  readNextGag();
  connectTalker();
  loginTalker();
  
  while (tread() and not restart) do
    -- accept tells, and try to do something with them.
    if (match("^TELL (%w+)%s+>(.+)")) then
      loopcheck();
      doTell(_[1], _[2]);
      
    -- try to preserve the bot group name.
    elseif (match("^GNAME (%w+) has changed the group's name to Bots%-R%-Us.$")) then
      print("# group name OK");
    elseif (match("^GNAME (%w+) has changed the group's name")) then
      print("# bad group name - " .. _[1] .. " did it.");
      loopcheck();
      tsend(format(".gname Bots-R-Us\n.evict %s\n.warn %s Do not change the name of Bots-R-Us\n", _[1], _[1]));
    
    -- try to stay in Bots-R-Us  .
    elseif (match("^EVICT You have been ")) then
      print("# I was evicted!");
      loopcheck();
      tsend(".group Bots-R-Us\n");

    -- when we first connect, we'll be adding members of the Masters list to our trusted table.
    elseif (match("^LISTINFO Users o[nf]f?line:(.+)")) then
      foreachi(split(_[1]), function(i, v)
                              v = gsub(v, "[%[%(%)%]]", "");
                              v = gsub(v, "^%*", "");
                              print("# trusting " .. v);
                              %trusted[v] = 1;
                            end);
    
    -- examine people who connect.  When we see group list, re-examine everyone.                        
    elseif (match("^CONNECT (%w+)")) then
      print(format("# %s has connected.  Examining them.", _[1]));
      loopcheck();
      tsend(format(".examine %s\n", _[1]));
    elseif (match("^GROUP%s+%S+%s(.*)")) then
      loopcheck();
      foreachi(split(_[1]), function(i, v)
                              print("# examining " .. v);
                              %tsend(format(".examine %s\n", v));
                            end);
    
    -- when examining people, keep track of who's logged in as who.
    elseif (match("^EXAMINE User:%s+(%w+) %(logged on as (%w+)%)")) then
      print(format("# %s == %s", _[1], _[2]));
      loa[strlower(_[1])] = strlower(_[2]);
      exing = strlower(_[1]);
    elseif (match("^EXAMINE User:%s+(%w+)")) then
      print(format("# %s == %s", _[1], _[1]));
      loa[strlower(_[1])] = strlower(_[1]);
      exing = strlower(_[1]);
    elseif (match("^EXAMINE Status:%s+Guest")) then
      print(format("# %s == guest", exing));
      loa[exing] = "guest";
    elseif (match("^EXAMINE Restrictions:.*Gagged")) then
      print(format("# %s is gagged.", exing));
      local ti = nextgag[loa[exing]] or 1;
      ti = ti / gagscale;
      if (ti < mingag) then
        ti = mingag;
      end;
      ungag[loa[exing]] = ti;
    elseif (match("^EXAMINE Idle:")) then
      print(format("# %s is idling.", exing));
      idling[exing] = 1;

    -- also try to keep track of who's logged in as who though .names and .logins
    elseif (match("^NAME (%S+) has changed " .. botName .. "'s name")) then
      print(format("# %s renamed me.  changing back.", _[1]));
      loopcheck();
      tsend(".nameself\n");
    elseif (match("^NAME %S+ has changed (%w+)'s? name to (%S+)%.")) then
      print(format("# %s -> %s", _[1], _[2]));
      local t = loa[strlower(_[1])];
      loa[strlower(_[1])] = nil;
      loa[strlower(_[2])] = t; 
    elseif (match("^NAME (%S+) has changed name to (%S+)%.")) then
      print(format("# %s -> %s", _[1], _[2]));
      local t = loa[strlower(_[1])];
      loa[strlower(_[1])] = nil;
      loa[strlower(_[2])] = t; 
    elseif (match("^LOGON (%S+) has logged on as, and changed name to (%S+)%.")) then
      print(format("# %s == %s", _[1], _[2]));
      loa[strlower(_[1])] = strlower(_[2]);
      loopcheck();
      tsend(format(".examine %s\n", _[2]));
    
    -- when people disconnect, forget about them...
    elseif (match("^DISCONNECT (%S+) has disc")) then
      print(format("# %s has disconnected.", _[1]));
      loa[strlower(_[1])] = nil;
      idling[strlower(_[1])] = nil;

    -- and of course when they're gagged or ungagged, remember it!
    elseif (match("^GAG (%w+) has been gagged by (%w+)%.")) then
      print(format("# %s gagged by %s", _[1], _[2]));
      if (strlower(_[1]) ~= "gagbot" and not ungag[loa[strlower(_[1])]]) then
        if (totshouts(loa[strlower(_[1])]) > 0) then
          -- may be fair - this person shouted recently, after all.
          local ti = tonumber(nextgag[loa[strlower(_[1])]]) or mingag;
          if (ti < 0) then return nil end;
          if (ti < mingag) then ti = mingag; end;
          ungag[loa[strlower(_[1])]] = ti;
          ti = ti * gagscale;
          if (ti > maxgag) then ti = maxgag; end;
          nextgag[loa[strlower(_[1])]] = ti;
          writeNextGag();
        else
          print("# UNFAIRLY!!!");
          loopcheck();
          tsend(format(".warn %s Unfair gag!\n.ungag %s\n", _[2], _[1]));
        end;
      end;
    elseif (match("^UNGAG (%S+).*unflagged.*bot")) then
      print(format("# ignoring unbot for %s", _[1]))
    elseif (match("^UNGAG (%S+)")) then
      print(format("# %s ungagged", _[1]));
      if strlower(_[1]) ~= "gagbot" then
        if loa[strlower(_[1])] then
          ungag[loa[strlower(_[1])]] = nil;
	end
      end

    -- when someone shouts, keep count.
    elseif (match("^SHOUT !? ?(%S+)")) then
      local acc = loa[strlower(_[1])];
      shouts[watchmins] = shouts[watchmins] or {};
      shouts[watchmins][""] = (shouts[watchmins][""] or 0) + 1;
      shouts[watchmins][acc] = (shouts[watchmins][acc] or 0) + 1;
      print(format("# %s shouts - %d this minute.", _[1], shouts[watchmins][acc]));
      if (totshouts(acc) >= maxshouts) then
        loopcheck();
        tsend(format(".gag %s\n>%s Be quiet!\n", _[1], _[1]));
      elseif (totshouts("") >= shoutfest) then
        loopcheck();
        tsend(format(".gag %s\n>%s Sorry, bit of a shout-fest going on.\n", _[1], _[1]));
      end;

    -- when a minute ticks by, see if anyone needs ungagging...
    elseif (match("^MARK ")) then
      markcount = markcount + 1;
      if (markcount == 30) then
        tsend("\n");
        markcount = 0;
      end;

      if (startedup == 0) then
        -- shouts within the last minute...
        shift(shouts);
        -- now decrement, then un-gag anyone who reaches zero, then tidy table.
        foreach(ungag, function(i, v)
                         if (%idling[i]) then return nil end;
                         if (tonumber(%ungag[i] or 0) > 0) then %ungag[i] = %ungag[i] - 1 end;
                         if (%ungag[i] ~= 0) then return nil end;
                         %ungag[i] = nil;
                         if (i == "guest") then return nil end;
                         %loopcheck();
                         local lloa = %loa;
                         local ttsend = %tsend;
                         foreach(%loa, function(X)
                                        if (%lloa[X] == %i) then
                                          print("# ungagging " .. X);
                                          %ttsend(".ungag " .. X .. "\n");
                                        end;
                                      end);
                       end);
        if (date("%H%M") == "0600") then
          print("# being nicer to people...");
          foreach(nextgag, function(i, v)
                             if (%nextgag[i] < 0) then return nil end;
                             write(i .. " " .. v .. " -> ");
                             %nextgag[i] = %nextgag[i] - %decperday;
                             if (%nextgag[i] < %mingag) then %nextgag[i] = nil end;
                             write(%nextgag[i], "\n");
                           end);
          writeNextGag();
        end;
      else
        print("# ignoring startup MARK");
        startedup = startedup - 1;
      end;
    elseif (match("^IDLE (%S+) starts")) then
      idling[strlower(_[1])] = 1;
      print(format("# %s has started idling.", _[1]));
    elseif (match("^IDLE (%S+) returns")) then
      idling[strlower(_[1])] = nil;
      print(format("# %s has returned from idling.", _[1]));
    elseif (match("^EXAMINE") or match("^LISTINFO") or match("^LOOKHDR") or match("^LOOK") or match("^GROUPHDR") or
            match("^DONETELL") or match("^TALK") or match("^CONNECTWARN") or match("^WARN")) then
      -- ignore
    else
      print("# " .. String);
    end;
  end;

until (restart);

dofile("gagbot.lua");
