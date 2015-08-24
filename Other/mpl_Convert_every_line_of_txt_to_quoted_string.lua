  readfile = "C:/Users/Michael/Desktop/Main_Section.txt"
  writefile = "C:/file.txt"
  
  f = io.open(readfile, "r")
  content = f:read("*all")
  lines_t = {}
  for line in io.lines(readfile) do table.insert(lines_t, line) end
  f:close()
  if lines_t ~= nil then
    for i = 1, #lines_t do
      line = lines_t[i]
    end
  str = table.concat(lines_t, '"'..",".."\n"..'"')   
  --reaper.ShowConsoleMsg(str) 
  f = io.open(writefile, "w")  
  f:write(str)
  end 
