-- some stuff to detect swearing etc...
swears = {}

function loadSwearWords(filename)
  local fh = openfile(filename, "r");
  local l = "";
  local word, exclusions;
  local et = {};
  while (l) do
    l = read(fh, "*l");
    if l then
      if strsub(l, 1, 1) ~= "#" then
        null, null, word, exclusions = strfind(l, "^([a-z-]*)%:?(.*)$");
        swears[word] = 1;
        exclusions = strlower(exclusions);
        if exclusions then
          et = {};
          local insertExclusion = function(eword)
            %et[eword] = 1;
          end;
          gsub(exclusions, "([a-z]+)", insertExclusion);
          swears[word] = et;
        end;
      end;
    end;
   end;
   closefile(fh)
end;

function checkWord(word)
  local lword = strlower(word);
  for w, k in swears do
    if not (not w or w == "" or type(w) ~= "string") then 
      if strfind(lword, w, 1, 1) then
        -- this word contains a forbidden word
        if swears[w][lword] then
          return word;
        else
          return strrep("*", strlen(word));
        end;
      end;
    end;
  end;
  return word; -- it's OK.
end;

function censor(string)
  return gsub(string, "(%w+)", checkWord)
end

