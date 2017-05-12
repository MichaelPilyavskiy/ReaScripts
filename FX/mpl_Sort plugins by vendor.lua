-- @version 1.22
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Sort plugins by vendor
-- @changelog
--    # fix nil on 33 line

  function msg(s) if s then reaper.ShowConsoleMsg(s..'\n') end end
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
  function ExtractVendor(s)
    local out_str
    if s:match('AU') then 
      out_str = s:match('%"(.-)%:')
     else
      
     
    local t_brackets = {}
    for str in s:gmatch("%((.-)%)") do t_brackets[#t_brackets+1] = str end  
    if   #t_brackets < 1 then return end
    for i = #t_brackets, 1, -1 do
      local str = t_brackets[i]
      if str and not 
              (
                str:len()<2
                or str:lower():find('mono')
                or str:lower():find('stereo')
                or str:lower():find('multi')
                or str:lower():find('64')
                or str:lower():find('voice')
                or str:lower():match('v[%d]')
                or str:lower():match('[%d] out')
                or str:lower():match('[%d]ch')
                or str:lower():match('[%d]->[%d]')
              ) 
       then  
        out_str = t_brackets[i] 
        break
      end
    end
    
    local fx_name
    if not out_str then
      local fx_name_comma = s:reverse():find(',')
      if fx_name_comma then 
        fx_name = s:sub(-fx_name_comma+1) 
        fx_name = fx_name:gsub('!!!VSTi', '')
      end      
    end
    
    end
    
    return out_str, fx_name
  end
  -----------------------------------------------------------------------------------
  function GetFileContext(fp)
    local str = "\n"
    local f=io.open(fp, 'r')
    if f then str = f:read('a') f:close() end 
    return str
  end
  -----------------------------------------------------------------------------------  
  function AddSpecific(t)
    local spec_filt = {
      'JS:',
      'JS: ix',
      'JS: Liteon',
      'JS: loser',
      'JS: remaincalm_org',
      'JS: schwa',
      'JS: sstillwell',
      'JS: Teej',
      'JS: X-Raym',
      'JS: ReaTeam'
      }
    for i = 1, #spec_filt do table.insert(t, spec_filt[i]) end
  end
  -----------------------------------------------------------------------------------
  function main()
    -- collect plugins info
      local context = 
          GetFileContext(reaper.GetResourcePath()..'/'..'reaper-vstplugins.ini')
        ..GetFileContext(reaper.GetResourcePath()..'/'..'reaper-vstplugins64.ini')
        ..GetFileContext(reaper.GetResourcePath()..'/'..'reaper-auplugins64-bc.ini')        
      local t_file = {}
      for line in context:gmatch('[^\r\n]+') do t_file[#t_file+1] = line end
    
    -- get sorted table
      local t_sort = {}
      local t_unknown = {}
      for i = 1, #t_file do 
        local vend, fx_name = ExtractVendor(t_file[i])
        if vend then 
          if not t_sort[vend] then t_sort[vend] = '' end
         else 
          if t_file[i]:find('%[') ~= 1 then t_unknown[#t_unknown+1] = fx_name end
        end
      end
      
    -- sort table alphabetically
      local t_sort_ord = {}
      for k,v in spairs(t_sort, function(t,a,b) return b:lower() > a:lower() end) do t_sort_ord[#t_sort_ord+1] = k end      
      
    -- specific names/filters
      AddSpecific(t_sort_ord)
      
    -- form new reaper-fxfolders.ini      
      local new_file_path = reaper.GetResourcePath()..'/'..'reaper-fxfolders_SORTED.ini'
      local f2=io.open(new_file_path, 'w') 
      f2:close()
      
    -- write table sz
      reaper.BR_Win32_WritePrivateProfileString( 'Folders', 'NbFolders', #t_sort_ord, new_file_path )
      
    -- write fold names
      for i = 0, #t_sort_ord-1 do
        reaper.BR_Win32_WritePrivateProfileString( 'Folders', 'Name'..i, t_sort_ord[i+1], new_file_path )
        reaper.BR_Win32_WritePrivateProfileString( 'Folders', 'Id'..i, i, new_file_path )
      end
      
    -- write fold stuff
      for i = 0, #t_sort_ord-1 do
        reaper.BR_Win32_WritePrivateProfileString( 'Folder'..i, 'Nb',    1,          new_file_path )
        reaper.BR_Win32_WritePrivateProfileString( 'Folder'..i, 'Type0', 1048576,    new_file_path )        
        
        local filter = t_sort_ord[i+1]
        if filter:lower():find('waves') then filter = 'waves NOT waveshap' 
          elseif filter == 'JS: ix' then filter = 'JS: ix/' end        
        reaper.BR_Win32_WritePrivateProfileString( 'Folder'..i, 'Item0', filter,    new_file_path )
        
      end 
      
    -- write unknown vendor plugins
      if #t_unknown > 0 then
        local unkn_file_path = reaper.GetResourcePath()..'/'..'reaper-fxfolders_UNKNOWN.txt'
        local f3=io.open(unkn_file_path, 'w') 
        f3:write('Following plugins weren`t be added to Favourites smart folders:\n\n'..table.concat(t_unknown, '\n'))
        f3:close()
      end
    
  end
  -----------------------------------------------------------------------------------  
  function msg_ask()
    ret = reaper.MB(
[[1. Look at REAPER resource path
2. Make backup of your reaper-fxfolders.ini
3. Close REAPER
4. Rename newly created reaper-fxfolders_SORTED.ini as reaper-fxfolders.ini
5. Run REAPER
    
As a result, plugins organized in Favourites by vendor.
Plugins without vendor listed in reaper-fxfolders_UNKNOWN.txt if any.

Show REAPER resource path?
    ]]
    , 'MPL: Sort plugins by vendor',4)
    if ret == 6 then reaper.Main_OnCommand(40027,0) end
  end
  -----------------------------------------------------------------------------------
  
  
  main()
  msg_ask()
  
  