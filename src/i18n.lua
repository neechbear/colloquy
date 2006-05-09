-- Colloquy i18n (internationalisation)
-- these functions look up tokens in a specific language, and return
-- them, optionally including some parameters.
--
-- It reads from a table called 'lang' keyed on language name, such
-- as "en-gb" etc.  Each of these is a table, keyed on token.  The
-- value can then be either a string, or a function.  If it is a
-- string, parameters are subsitited into the string.  Place holders
-- in the string are $n where n is a number from 0 to 9 for keying
-- purposes.  If the value is a function, then the function is called,
-- passing it the values as parameters, and it takes the string the
-- function returns as the text.

-- example:
-- lang["en-gb"] = {
--   hello = "Hello, $0!",
--   connect = "$0 has connected from $1.",
--   goodbye = function(a, b, c)
--               return format("Wibble %s splat %s goo %s.", a, b, c)
--             end
--   }
--
-- then:
--   getmsg(lang["en-gb"], lang["en-gb"], "hello", "Bob") = "Hello, Bob!"
--   getmsg(lang["en-gb"], lang["en-gb"], "connect", "Bob", "localhost") = 
--      "Bob has connected from localhost."
--   getmsg(lang["en-gb"], lang["en-gb"], "goodbye", "Moo", "Oink", Cluck") =
--      "Wibble Moo splat Oink goo Cluck"
--
-- Tokens can include the result of expanding another token, such that if
-- the token "moo" is defined as "Hello $0, welcome to ${Oink,Pig Meat}" and
-- the token "Oink" is defined as "I love $0" then "moo" might expand to 
-- "Hello Bob, welcome to 'I love Pig Meat'"
--
-- The getmsg function takes a language to look a token up in, a fallback
-- language if the first one doesn't contain the token, the token name,
-- and the parameters for it.  If no token is found, it returns a string
-- with each parameter seperated by spaces.

lang = {}
local loaded = {}
unfoundToken = "(none)"
msgCache = {}  -- pre-expanded strings, keyed on these values \n seperated:
               -- pLang, fLang, token, param1, param2, ... paramN
               -- Also contains number -> key mappings for random replacement
               -- once the cache reaches a maximum size.
msgCacheSize = 0
msgCacheMax = 512 
msgCacheLastRemoved = 0
msgCacheHits = 0
msgCacheMisses = 0

function msgCacheState()
  for i = 1, msgCacheSize do
    print(i .. ": " .. gsub(msgCache[i], "\n", ".") .. "=" .. msgCache[msgCache[i]] .. "\n")
  end
end

function flushMsgCache()
  msgCache = {}
  msgCacheSize = 0
end

function searchMsgCache(pLang, fLang, token, params)
  local key = format("%s\n%s\n%s\n", pLang.NAME, fLang.NAME, token)
  for i = 1, getn(params) do
    key = key .. format("%s\n", params[i])
  end
  if( msgCache[key] ) then
    msgCacheHits = msgCacheHits + 1
  else
    msgCacheMisses = msgCacheMisses + 1
  end
  return msgCache[key]
end

function insertMsgCache(msg, pLang, fLang, token, params)
  local pos
  if( msgCacheSize >= msgCacheMax ) then
    -- we need to randomly select an entry to remove
    pos = random(msgCacheMax)
    msgCacheLastRemoved = pos
    msgCache[msgCache[pos]] = nil -- remove the key/value pair
  else
    msgCacheSize = msgCacheSize + 1
    pos = msgCacheSize
  end
  local key = format("%s\n%s\n%s\n", pLang.NAME, fLang.NAME, token)
  for i = 1, getn(params) do
    key = key .. format("%s\n", params[i])
  end
  msgCache[pos] = key
  msgCache[key] = msg
end

local defaultToken = function(...)
  local r = "Unknown token '" .. unfoundToken .. "': "
  for i = 1, getn(arg) do
    r = r .. arg[i]
    if( i < getn(arg) ) then
      r = r .. " "
    end
  end
  return r
end

evalsubtoken = function(pLang, fLang, ft)
  -- takes "${token,params...}"
  local t = {}
  local f;
  if( strsub(ft, 1, 2) == "${" and strsub(ft, -1, -1) == "}" ) then
    -- yes, we need to fiddle this.
    gsub(ft, "([^%,%$%{%}]+)%,?", function(a) tinsert(%t, a) end)
    f = tremove(t, 1)
    tinsert(t, 1, f)
    tinsert(t, 1, fLang)
    tinsert(t, 1, pLang)
    return call(getmsg, t)
  else
    return ft
  end
end

local expandDollars = function(ft, arg)
  for i = 0, getn(arg or {}) - 1 do
    -- we can't use gsub here, because this may contain information from a user,
    -- and as such might contain gsub magic characters.
    -- search for "$n", where n is the number i, and replace it with arg[i + 1]
    local l = strfind(ft, "$" .. i, 1, 1)
    if( l ) then
      ft = strsub(ft, 1, l - 1) .. arg[i + 1] .. strsub(ft, l + 2, -1)
    end
  end
  return ft
end

local subtext = function(pLang, fLang, ft, arg)
  local expandDollars = %expandDollars
  ft = gsub(ft, "(%$%{[%w%d%s$,]+%})", function(x) return evalsubtoken(%pLang, %fLang, %expandDollars(x,%arg)) end)
  return expandDollars(ft, arg)
end

function getmsg(pLang, fLang, token, ...)
  -- pLang: Primary search language
  -- fLang: Fallback search language
  -- token: Token to search for
  -- ...  : Parameters for token

  pLang = pLang or getlang(colloquy.lang)
  fLang = fLang or pLang
  
  local cached = searchMsgCache(pLang, fLang, token, arg)
  if( cached ) then return cached end

  local ft, cL
  -- search pLang for the token, falling back to each of its parents if
  -- it's not there.
  cL = pLang
  repeat
    ft = cL[token]
    if( not ft and cL.PARENT ) then
      cL = getlang(cL.PARENT)
    else
      cL = nil
    end
  until( ft or not cL )
  -- if we've still not found it, try looking in fLang for it, falling
  -- back to each of its parents if it's not there.
  if( not ft ) then
    cL = fLang
    repeat
      ft = cL[token]
      if( not ft and cL.PARENT ) then
        cL = getlang(cL.PARENT)
      else
        cL = nil
      end
    until( ft or not cL )
  end
  -- give up, and give them the default token.
  unfoundToken = token
  ft = ft or %defaultToken

  if( type(ft) == "string" ) then
    local r = %subtext(pLang, fLang, ft, arg)
    insertMsgCache(r, pLang, fLang, token, arg)
    return r
  elseif( type(ft) == "function" ) then
    ft = call(ft, arg)
    ft = %subtext(pLang, fLang, ft)
    return ft
  else
    -- god knows what went wrong.  Return the default.
    return "unknown token type: " .. call(%defaultToken, arg)
  end
end

function getlang(plang)
  if( %loaded[plang] ~= nil ) then
    return %loaded[plang]
  else
    -- OK, it's not loaded.  Let's load it, after having flushed
    -- the msgCache
    flushMsgCache()
    local n = gsub(plang, "[%/%.]", "")
    local f = openfile(colloquy.langs .. n .. ".lua", "r")
    if( not f ) then
      return nil
    else
      closefile(f)
      dofile(colloquy.langs .. n .. ".lua")
      %loaded[n] = lang[n]
      return lang[n]
    end
  end
end

function reload(plang)
  %loaded[plang] = nil
  getlang(plang)
  for i, v in colloquy.connections do
    if( type(i) == "table" ) then
      if( v.lang.NAME == plang ) then
        v.lang = %loaded[plang]
      end
    end
  end
end

function gm(conn, token, ...)
  tinsert(arg, 1, token)
  tinsert(arg, 1, getlang(colloquy.lang))
  tinsert(arg, 1, conn.lang)
  return call(getmsg, arg)
end

function getHelp(conn, item)
  -- gets the lines for help 'item' suitable for connection 'conn'
  -- looks for data/lang/<langname>-help/<item> to see if it exists, if not,
  -- it searches each of the languages parents.  If nothing is found, it
  -- returns data/help/<item>

  local lang = conn.lang
  local alang
  local item = strlower(item)
  local fh
  local r = {} -- our result - one line per row.
  local l

  -- let's check if there's an exactly suitable match.
  fh = openfile(format("%s%s-help/%s", colloquy.langs, lang.NAME, item), "r")
  if fh then
    -- found the perfect match.  Read each line into r.
    repeat
      l = read(fh, "*l")
      if l then
        tinsert(r, l)
      end
    until (not l)
    closefile(fh)
    return r
  end

  -- let's check their language's ancestors for matches.
  if lang.PARENT then
    alang = lang
    repeat
      if alang.PARENT then
        alang = getlang(alang.PARENT)
        fh = openfile(format("%s%s-help/%s", colloquy.langs, alang.NAME, item), "r")
        if fh then
          -- oooh, we've found one.
          repeat
            l = read(fh, "*l")
            if l then
              tinsert(r, l)
            end
          until (not l)
          closefile(fh)
          return r
        end
      end
    until (not alang.PARENT)
  end

  -- let's return the default one.
  fh = openfile(format("%s%s", colloquy.help, item), "r")
  if fh then
    repeat
      l = read(fh, "*l")
      if l then
        tinsert(r, l)
      end
    until (not l)
    closefile(fh)
    return r
  end

  return nil -- no match found.
end
