-- Simple record/key/value database provided as a table.
--
-- Records can map to a single value, or a table.  Supports nested tables.
-- Records are stored to disc, one file per record.  Using : in record names
-- is not supported, neither are non-string record names.
--
-- foo = newdb(name, dir)
--   name - The name for this database
--   dir - directory to store files in.  *MUST* end in / and have no other
--         data in it.  It will read all files in from this directory when
--         created.
--
-- foo.blah = value
-- print(foo.blah)
--
-- foo() -- return raw data table (for use with foreach - if you make changes,
--          remember to flush them.)
--
-- foo('flush') -- flush the whole database
-- foo('sync') -- write changes to disc instantly (default)
-- foo('async') -- don't flush until foo('sync') is called

local writeTable = function(t, fh)
  write(fh, "\n{\n")
  foreach(t, function(k, v)
    local isTable;
    if type(v) == "number" then
      v = tostring(v)
    elseif type(v) == "string" then
      v = format("%q", v)
    elseif type(v) == "table" then
      isTable = 1;
    else
      v = "nil"
    end

    if type(k) == "number" then
      k = "[" .. tostring(k) .. "]"
    elseif type(k) == "string" then
      k = format("[%q]", k)
    else
      k = "__unsupported_key_type__"
    end

    if isTable then
      -- this is a nested table
      write(%fh, format("  %s =", k))
      getinfo(3).func(v, %fh) -- call ourself
      write(%fh, ",\n")
    else
      write(%fh, format("  %s = %s,\n", k, v))
    end
  end)
  write(fh, "}")
end

local flushEntry = function(t, i, force)
  local c = rawget(t, "c")
  if not force and not c[i] then return end -- hasn't been changed since last flush
  local d = rawget(t, "d")
  local fh = openfile(rawget(t, "p") .. i, "w")
  if type(d[i]) == "number" then
    write(fh, "return ", d[i], "\n")
  elseif type(d[i]) == "string" then
    write(fh, format("return %q\n", d[i]))
  elseif type(d[i]) == "table" then
    -- write out the whole table
    write(fh, "return")
    %writeTable(d[i], fh)
  end
  write(fh, "\n")
  closefile(fh)
  c[i] = nil -- clear changed flag
end

local flush = function(t, i, force)
  if not i then
    local d = rawget(t, "d")
    local flushEntry = %flushEntry
    foreach(d, function(k, v) %flushEntry(%t, k, %force) end)
  else
    %flushEntry(t, i, force)
  end
end

local sync = function(t)
  %flush(t)
  rawset(t, "f", 1)
end

local async = function(t)
  rawset(t, "f", nil)
end

local gettable = function(t, i)
  local d = rawget(t, "d")
  return d[i]
end

local settable = function(t, i, v)
  local d = rawget(t, "d")
  local c = rawget(t, "c")
  if not (type(v) == "nil" or type(v) == "number" or type(v) == "string" or type(v) == "table") then
    error("Unsupported value type '" .. type(v) .. "'")
  end
  if type(v) == nil then
    remove(rawget(t, "p") .. i)
  end
  d[i] = v
  c[i] = 1
  if rawget(t, "f") then
    %flush(t, i)
  end
end

local called = function(t, p, p1)
  if not p then
    return rawget(t, "d")
  elseif p == "flush" then
    return %flush(t, p1, 1)
  elseif p == "sync" then
    return %sync(t)
  elseif p == "async" then
    return %async(t)
  else
    error("Unknown db command '" .. tostring(p) .. "'")
  end
  return
end

local ourtag = newtag()
settagmethod(ourtag, "gettable", gettable)
settagmethod(ourtag, "settable", settable)
settagmethod(ourtag, "function", called)

function newdb(n, p)
  local db = { n = n, d = {}, f = 1, p = p or "", c = {} }
  -- n = db name
  -- d = db data
  -- f = flush on change flag
  -- p = prefix
  -- c = table of keys from d that have changed since last flush
  local dir = pfiles(p)
  
  if dir then
    local e = dir()
    while (e) do
      if e ~= "." and e ~= ".." then
        db.d[e] = dofile(p .. e);
      end
      e = dir()
    end
  end

  settag(db, %ourtag) 
  return db
end

--foo = newdb("users", "test/")
--foo.oink = {}
--foo.oink.baah = "sheep"
--foo('flush', 'oink', 1)
