-- fudges bits of Lua surrounded by !{ }

-- if !{oink n1 n2 n3 n4} then
--   goes to
-- if oink == n1 or oink == n2 or oink == n3 or oink == n4 then

dofile "tags.lua"

i = read "*a"

i = gsub(i, "!{(.-)}", function(x) 
  t = {}
  r = ""
  gsub(x, "(%S+)", function(y)
    tinsert(%t, y)
  end)
  for i = 2, getn(t) do
    r = r .. t[1] .. " == '" .. getglobal(t[i]) .. "' or "
  end
  return strsub(r, 1, -4)
end)

print(i)
