-- @version 1.0
-- @author mpl
-- @changelog
--   + init release, thanks to ReaperBlog for testing.

--[[
   * ReaScript Name: Delete non-existent scripts from Action List
   * Lua script for Cockos REAPER
   * Author: Michael Pilyavskiy (mpl)
   * Author URI: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
   * Version: 1.0
  ]]


  function main()
    local scr_filename_temp, ex, filename, kb_table, file, content, file_BU, idx, temp_t, scripts_to_del, res_path, exists0, exists
    filename = reaper.GetResourcePath().."/reaper-kb.ini"
    kb_table = {}  
    file = io.open(filename, "r")    
    if file == nil then  reaper.ReaScriptError( 'Error: reaper-kb.ini not found' ) return  end    
    content = file:read("*all")
    for line in content:gmatch('[^\r\n]+') do table.insert(kb_table, line) end
    file:close()

  
    
    -- loop kb.ini / check for is exists
      idx = 0 -- count for deleted scripts
      scripts_to_del = {}       -- table for deleted scripts names
       res_path = reaper.GetResourcePath():gsub('%\\','/')
      for i = 1,#kb_table do
        if string.find(kb_table[i], 'SCR') ~= nil then
        
          temp_t = {}
          for param in kb_table[i]:gmatch('[^%"]+') do 
            if param:find('%:') == nil and param ~= ' ' and param:find('SCR') == nil then 
              if param:find(res_path) == nil then
                table.insert(temp_t, param) 
                table.insert(temp_t, res_path.."/Scripts/"..param) 
                table.insert(temp_t, res_path.."/Scripts/"..param:sub(2)) 
               else
                table.insert(temp_t, param) 
              end
            end
          end
          
          exists0 = false
          for j = 1, #temp_t do
            exists = reaper.file_exists( temp_t[j] )
            if exists then exists0 = true break end
          end
          
          if exists0 == false then 
            idx = idx + 1 
            scripts_to_del[#scripts_to_del+1] = idx..'. '..kb_table[i]--..'\n'
            kb_table[i] = '' 
          end
          
        end
      end
      
    -- return edited kb.ini
      local out_str = table.concat(kb_table,"\n") : gsub("\n\n", "\n")
    
    -- ask for changes
      if idx > 0 then
        reaper.ShowConsoleMsg(table.concat(scripts_to_del,"\n"))
        local ret = reaper.MB("Do you wanna remove "..idx.." records(s) from reaper-kb.ini?\n" ,"Delete nonexistent scripts from ActionList", 4)
        if ret == 6 then -- if yes
          file = io.open(filename, "w")
          file:write(out_str)
          file:close()
          
          reaper.MB(idx.." record(s) deleted. \nReload REAPER to affect changes\n\n".."REAPER/reaper-kb.ini-backup is created", "",0)
          
          file_BU = io.open(filename..'-backup', "w")
          file_BU:write(content)
          file_BU:close()  
          
        end
       else
        reaper.MB("Nothing to delete", "Delete nonexistent scripts from ActionList", 0)
      end
  
  end
  
  main()
  
  
