-- colouring information format is:
-- "!c!f:b !c!f:b !c!f:b"
-- c = colour name
-- f = foreground colour
-- v = background colour

ESC = format("%c[",27)

chattr = {
  reset = 0,
  bright = 1,
  dim = 2,
  underline = 4,
  blink = 5,
  reverse = 7,
  hidden = 8,
  fg = {
    black = 30,
    red = 31,
    green = 32,
    yellow = 33,
    blue = 34,
    magenta = 35,
    cyan = 36,
    white = 37
  },
  bg = {
    black = 40,
    red = 41,
    green = 42,
    yellow = 43,
    blue = 44,
    magenta = 45,
    cyan = 46,
    white = 47
  }
}

function migrateColours(user)
  if (strfind(users[user].colours or "", ",")) then
    -- they have an old-style colour string - convert it to a new one.
    log("   Migrating " .. user .. "'s colouring settings to new format.")
    local o, c = users[user].colours;
    c = format("!talk!%s:%s", getOldColour(o, "talk"), getOldColour(o, "talkback"));
    c = c .. format("!tell!%s:%s", getOldColour(o, "tell"), getOldColour(o, "tellback"));
    c = c .. format("!list!%s:%s", getOldColour(o, "list"), getOldColour(o, "listback"));
    c = c .. format("!listname!%s:%s", getOldColour(o, "listname"), getOldColour(o, "listnameback"));
    c = c .. format("!shout!%s:%s", getOldColour(o, "shout"), getOldColour(o, "shoutback"));
    c = c .. format("!message!%s:%s", getOldColour(o, "message"), getOldColour(o, "messageback"));
    c = c .. format("!nick!%s:%s", getOldColour(o, "nick"), getOldColour(o, "nickback"));
    users[user].colours = c;
  end
end

function setColouring(conn, tag, fg, bg)
  if (not strfind(conn.colours, "!" .. tag .. "!", 1, 1)) then
    conn.colours = conn.colours .. format("!%s!%s:%s", tag, fg, bg);
  else
    conn.colours = gsub(conn.colours, format("!%s%%![^%%!]+", tag), format("!%s!%s:%s", tag, fg, bg));
  end;
  if (conn.status > 1) then
    users[strlower(conn.realUser)].colours = conn.colours;
  end;
end

function getColouringName(conn, tag, dfg, dbg)
  -- return the english name of the fore and background colours, or
  -- return the defaults if they've not been set yet.
  local null, null, fg = strfind(conn.colours, "!" .. tag .. "!([^%:]+)%:");
  local null, null, bg = strfind(conn.colours, "!" .. tag .. "![^%:]+%:([^%!]+)");
  fg = fg or dfg or "white";
  bg = bg or dbg or "none";
  local rfg, rbg = "", "";

  local c, b = gsub(fg, "^br", "");
  if (b == 1) then rfg = "Br" end
  rfg = rfg .. strupper(strsub(c, 1, 1)) .. strsub(c, 2, -1); -- we can assume this for now.

  c, b = gsub(bg, "^br", "");
  if (b == 1) then rbg = "Br" end
  rbg = rbg .. strupper(strsub(c, 1, 1)) .. strsub(c, 2, -1); -- we can assume this for now.

  return rfg, rbg;
end

function attrib(...)
   local t = ESC;
   if (arg ~= nil) then
      for i = 1, getn(arg) do t = t .. ";" .. arg[i]; end
   end
   return t .. "m";
end

function getColour(conn, tag, dfg, dbg)
  -- return the control codes to apply this colour.
  
  local c = conn.colours;
  local r = attrib(chattr.reset);
  local null, null, fg = strfind(c, "!" .. tag .. "!([^%:]+)%:");
  local null, null, bg = strfind(c, "!" .. tag .. "![^%:]+%:([^%!]+)");
  fg = fg or dfg or "white";
  bg = bg or dbg or "none";

  local t = { [1] = chattr.reset };
  
  getColourInsert(t, fg);
  getColourInsert(t, bg, 1);
  return call(attrib, t);

end

function getColourInsert(t, f, back)
  if (strsub(f, 1, 2) == "br") then
    if (not back) then
      tinsert(t, chattr.bright);
    end;
    f = gsub(f, "^br", "");
  end;
  
  if (f == "black" and back) then tinsert(t, chattr.bg.black)
  elseif (f == "black") then tinsert(t, chattr.fg.black)

  elseif (f == "red" and back) then tinsert(t, chattr.bg.red)
  elseif (f == "red") then tinsert(t, chattr.fg.red)

  elseif (f == "green" and back) then tinsert(t, chattr.bg.green)
  elseif (f == "green") then tinsert(t, chattr.fg.green)

  elseif (f == "yellow" and back) then tinsert(t, chattr.bg.yellow)
  elseif (f == "yellow") then tinsert(t, chattr.fg.yellow)

  elseif (f == "magenta" and back) then tinsert(t, chattr.bg.magenta)
  elseif (f == "magenta") then tinsert(t, chattr.fg.magenta)

  elseif (f == "blue" and back) then tinsert(t, chattr.bg.blue)
  elseif (f == "blue") then tinsert(t, chattr.fg.blue);

  elseif (f == "cyan" and back) then tinsert(t, chattr.bg.cyan)
  elseif (f == "cyan") then tinsert(t, chattr.fg.cyan)

  elseif (f == "white" and back) then tinsert(t, chattr.bg.white)
  elseif (f == "white") then tinsert(t, chattr.fg.white)
  end;
end;

function getOldColour(s, type)

   local c = s;

   if (strfind(c, type, 1, 1) == nil) then
     if (strfind(type, "back", 1, 1)) then
       c = c .. type .. "='none',"
     else
       c = c .. type .. "='white',"
     end;
   end;
   
   local f = strsub(c, strfind(c, type .. "=") + strlen(type .. "=") + 1, strlen(c));
   f = strsub(f, 1, strfind(f, "'") - 1);
   
   local b = (strsub(f, 1, 2) == "br");
   do
     return f;
   end;
   local r;
   
   if (b) then
      f = gsub(f, "br", "");
      r = "Br";
   else
      r = "";
   end;

   if (f == "black") then r = r .. "Black";
   elseif (f == "red") then r = r .. "Red";
   elseif (f == "green") then r = r .. "Green";
   elseif (f == "yellow") then r = r .. "Yellow";
   elseif (f == "blue") then r = r .. "Blue";
   elseif (f == "magenta") then r = r .. "Magenta";
   elseif (f == "cyan") then r = r .. "Cyan";
   elseif (f == "white") then r = r .. "White";
   else r = r .. "None";
   end;

   return r;
end;

