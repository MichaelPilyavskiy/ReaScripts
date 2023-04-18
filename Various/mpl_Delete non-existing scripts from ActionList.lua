-- @description Delete non-existing scripts from Action List
-- @version 1.03
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @about Remove entries from reaper-kb.ini if they linked to files not currently presented in Reaper/Scripts path, make backup of reaper-kb.ini just in case
-- @changelog
--    # rename title
--    # update proposed by @Hipox, match/find functions updated

function Lead_Trim_ws(s) return s:match '^%s*(.*)' end

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
          param = Lead_Trim_ws(param)
          if param:find('^Custom: ') == nil and param ~= ' ' and param:find('SRC') == nil then
            if param:find('[A-Z]:') ~= nil then
              table.insert(temp_t, param)
            else
              table.insert(temp_t, res_path .."/Scripts/".. param)
            end
          end
        end
        
        exists0 = false
        for j = 1, #temp_t do
          exists = reaper.file_exists( temp_t[j] )
          if exists then 
            exists0 = true 
            break 
          end
        end
        
        if exists0 == false then 
          idx = idx + 1 
          scripts_to_del[#scripts_to_del+1] = idx..'. '..kb_table[i] ..'\n'
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
