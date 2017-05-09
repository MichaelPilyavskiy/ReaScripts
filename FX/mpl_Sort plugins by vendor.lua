-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Sort plugins by vendor
-- @changelog
--    + init

  function msg(s) reaper.ShowConsoleMsg(s) end
  reaper.ClearConsole()
  ----------------------------------------------------------------------------------- 
  function spairs(t, order) --http://stackoverflow.com/questions/15706270/sort-a-table-in-lua
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end
    if order then table.sort(keys, function(a,b) return order(t, a, b) end)  else  table.sort(keys) end
    local i = 0
    return function()
              i = i + 1
              if keys[i] then return keys[i], t[keys[i]] end
           end
end
  -----------------------------------------------------------------------------------   
  function ExtractVSTName(s)
    if not s then return end
    local t = {}
    for val in s:gmatch('[^%,]+') do t[#t+1]=val end
    local out_val
    if t[3] then out_val = t[3] else return end
    if out_val:find('!!!') then out_val = out_val:sub(0, out_val:find('!!!')-1) end
    return out_val
  end
  -----------------------------------------------------------------------------------  
  function ExtractVendor(s)
    local t = {}
    local out_str = ''
    for str in s:gmatch("%((.-)%)") do 
      if not 
        (
          str:len()<2
          or str:lower():find('mono')
          or str:lower():find('stereo')
          or str:lower():find('multi')
          or str:lower():find('64')
          or str:lower():find('voice')
          or str:lower():match('v[%d]')
        ) 
       then 
        if str:len() > out_str:len() then out_str = str end
      end
    end
    return out_str
  end
  -----------------------------------------------------------------------------------
  function GetPluginsTable()
      local context = ''
      local plugins_info = reaper.GetResourcePath()..'/'..'reaper-vstplugins.ini'
      f=io.open(plugins_info, 'r')
      if f then context = f:read('a') else return end
      f:close()  
      
      local plugins_info = reaper.GetResourcePath()..'/'..'reaper-vstplugins64.ini'
      f=io.open(plugins_info, 'r')
      if f then 
        context = context..f:read('a')
        f:close() 
      end             
        
      local t = {}
      for line in context:gmatch('[^\r\n]+') do t[#t+1] = line end
      return t
  end
  -----------------------------------------------------------------------------------
  function main()
    local t = GetPluginsTable()
    -- get sorted table
      local t_sort = {}
      for i = 1, #t do
        local vend = ExtractVendor(t[i])
        local fx_name = ExtractVSTName(t[i])
        
        if not vend then vend = 'Unknown' end 
        if not t_sort[vend] then t_sort[vend] = {} end
        if fx_name and vend == 'Unknown' then        
          t_sort[vend][#t_sort[vend]+1] = fx_name
        end
      end
      
      --[[local addTS = os.date():gsub('%:', '.')
      local command = 'rename "'..reaper.GetResourcePath()..'/'..'reaper-fxfolders.ini"'..'  '..'"reaper-fxfolders'..'_backup'..addTS..'.ini"'
      command = command:gsub('/', '\\')
      --msg(command)
      os.execute(command)]]
      
    -- form new reaper-fxfolders.ini
      
      local new_file_path = reaper.GetResourcePath()..'/'..'reaper-fxfolders_SORTED.ini'
      f2=io.open(new_file_path, 'w') 
      f2:close()
    -- get table size
      local tsz = 0 for key in pairs(t_sort) do tsz = tsz + 1 end
      reaper.BR_Win32_WritePrivateProfileString( 'Folders', 'NbFolders', tsz, new_file_path )
    -- write fold names
      local f_id = 0
      for k,v in spairs(t_sort, function(t,a,b) return b:lower() > a:lower() end) do
        reaper.BR_Win32_WritePrivateProfileString( 'Folders', 'Name'..f_id, k, new_file_path )
        reaper.BR_Win32_WritePrivateProfileString( 'Folders', 'Id'..f_id, f_id, new_file_path )
        f_id = f_id + 1 
      end
    -- write fold stuff
      local f_id = 0
      for k,v in spairs(t_sort, function(t,a,b) return b:lower() > a:lower() end) do
        if k ~= 'Unknown' then
          reaper.BR_Win32_WritePrivateProfileString( 'Folder'..f_id, 'Nb',    1,          new_file_path )
          reaper.BR_Win32_WritePrivateProfileString( 'Folder'..f_id, 'Type0', 1048576,    new_file_path )
          reaper.BR_Win32_WritePrivateProfileString( 'Folder'..f_id, 'Item0', '('..k..')\n',    new_file_path )
        end
        f_id = f_id + 1 
      end    
  end
  -----------------------------------------------------------------------------------
  main()
  reaper.MB(
[[  - look at REAPER resource folder, you use 'Show resource path' action
  - make backup of your fxfolders.ini
  - close REAPER
  - rename newly created fxfolders_SORTED as fxfolders
  - run REAPER
  
  As a result, plugins organized in Favourites by vendor.
  ]]
  , '',0)
  
  
