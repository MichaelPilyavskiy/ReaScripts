  kb_file_loc = "C:/Users/Michael/Desktop/Untitled1.txt"
  f = io.open(kb_file_loc, "r")
  content = f:read("*all")
  lines_t = {}
  for line in io.lines(kb_file_loc) do table.insert(lines_t, line) end
  f:close()
  if lines_t ~= nil then
    for i = 1, #lines_t do
      line = lines_t[i]
    end
  str = table.concat(lines_t, '"\n"')   
  reaper.ShowConsoleMsg(str)   
  end 
