-- @description Sort focused FX presets alphabetically
-- @version 2.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # Complete script rebuild
--    # Direct preset file parsing, avoid using SWS functions and SWS requirement
--    + Do backup file if not exists
--    + Support take FX
--    + Reboot plugin after sort
--    + Inform before executing script
--    + Inform if focused plugin not found
--    + Inform if preset file not found
--    + Inform at succesful sort
--    + Inform at succesful backup

  ----------------------------------------------------------------------
  function SortPresets_GetPath()
    local ret_flags, tracknumber, itemnumber, fxnumber = GetFocusedFX2()
    local tr
    if tracknumber == 0 then tr = GetMasterTrack(0) else tr = GetTrack(0,tracknumber-1) end
    if ret_flags&1==1 then 
      fn = TrackFX_GetUserPresetFilename(tr, fxnumber, '')
     elseif ret_flags&2==2 then
      local it = GetTrackMediaItem( tr, itemnumber ) 
      local take = GetTake(it, (fxnumber>>16)&0xFFFF)
      fn = TakeFX_GetUserPresetFilename( take, fxnumber&0xFFFF )
    end
    return fn
  end
  ----------------------------------------------------------------------
  function SortPresets()
    local fn = SortPresets_GetPath() 
    if not fn then MB('No plugin focused or not preset file found','Sort focused FX presets alphabetically',0) return end 
    
    ret = MB('Want to sort presets in\n'..fn..' ?','Sort focused FX presets alphabetically',3)
    if ret~= 6 then return end
    
    -- parse ini
      local data, content = ParseINI_custom(fn)
      if not (data and content) then return end
      local Presets = {} for key in pairs(data) do if key:match('Preset%d+') then local presetID = key:match('Preset(%d+)') if tonumber(presetID) then Presets[(tonumber(presetID))+1] =  CopyTable(data[key]) end end end  -- copy from data to separated table 
      local idsort = getKeysSortedByValue(Presets, function(a, b) return a < b end, 'Name') -- sort by Name
      PresetsSorted = {} for i = 1, #Presets do PresetsSorted[i] = Presets[idsort[i]] end -- build sorted table
    
    -- generate new file
      local outstr = '[General]\nNbPresets='..#PresetsSorted..'\n'
      for i = 1,#PresetsSorted do
        outstr = outstr..'\n[Preset'..(i-1)..']\n'..
          'Data='..PresetsSorted[i].Data..'\n'..
          'Len='..PresetsSorted[i].Len..'\n'..
          'Name='..PresetsSorted[i].Name..'\n'
        
      end
    
    -- write backup
      local backupcreated 
      if not file_exists(fn..'-backup') then local f = io.open(fn..'-backup','wb') if f then f:write(content) f:close() backupcreated = true else return end end
    -- write modified file
      local f = io.open(fn,'wb') 
      if f then 
        f:write(outstr) 
        f:close()
      end
      
    -- reboot plugin
      SortPresets_RebootPlugin()
      if not backupcreated then MB('Sorted sucessfully','Sort focused FX presets alphabetically',0) else MB('Sorted sucessfully. Backup created.','Sort focused FX presets alphabetically',0) end
  end
  ----------------------------------------------------------------------
  function SortPresets_RebootPlugin()
    local ret_flags, tracknumber, itemnumber, fxnumber = GetFocusedFX2()
    local tr
    if tracknumber == 0 then tr = GetMasterTrack(0) else tr = GetTrack(0,tracknumber-1) end
    if ret_flags&1==1 then 
      TrackFX_SetOffline( tr, fxnumber, true )
      TrackFX_SetOffline( tr, fxnumber, false )
     elseif ret_flags&2==2 then
      local it = GetTrackMediaItem( tr, itemnumber ) 
      local take = GetTake(it, (fxnumber>>16)&0xFFFF)
      TakeFX_SetOffline( take, fxnumber&0xFFFF, true )
      TakeFX_SetOffline( take, fxnumber&0xFFFF, false )
    end
  end
    ---------------------------------------------------------------------  
  function ParseINI_custom(fileName) -- based on https://github.com/Dynodzzo/Lua_INI_Parser/blob/master/LIP.lua, used binary mode
    local file = io.open(fileName, 'rb')
    local content = file:read('a')
    file:close()
    
    local data = {};
    local section;
    for line in content:gmatch('[^\r\n]+') do
      local tempSection = line:match('^%[([^%[%]]+)%]$');
      if(tempSection)then
        section = tonumber(tempSection) and tonumber(tempSection) or tempSection;
        data[section] = data[section] or {};
      end
      local param, value = line:match('^([%w|_]+)%s-=%s-(.+)$');
      if(param and value ~= nil)then
        if(tonumber(value))then
          value = tonumber(value);
        elseif(value == 'true')then
          value = true;
        elseif(value == 'false')then
          value = false;
        end
        if(tonumber(param))then
          param = tonumber(param);
        end
        if data[section] then 
          data[section][param] = value;
        end
      end
    end
    return data,content;
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.18) if ret then local ret2 = VF_CheckReaperVrs(6,true) if ret2 then 
    SortPresets() 
  end end
  --[[
  -------------------
  function main()
    -- get preset file
    local retval, trnum, _, fxnum = GetFocusedFX()
    if retval ~= 1 then return end
    local tr = GetTrack(0,trnum-1)
    if not tr then return end
    local filename = reaper.TrackFX_GetUserPresetFilename(tr, fxnum, '')
    local file = io.open(filename, "rb")
    local content 
    if file then 
      content = file:read('*a')  
      file:close() 
      
      local backupfile_fp = filename..'-backup'
      if not reaper.file_exists( backupfile_fp ) then
        local backupfile = io.open(backupfile_fp, "wb")
        backupfile:write(content)
        backupfile:close()
      end
      
     else  
      return   
    end
    
    -- get data
    local retval, LastDefImpTime = BR_Win32_GetPrivateProfileString( 'General', 'LastDefImpTime', '0', filename )
    local retval, NbPresets = BR_Win32_GetPrivateProfileString( 'General', 'NbPresets', '0', filename )  
    t = {}
    for i = 0, tonumber(NbPresets)-1 do
      local retval, Len = BR_Win32_GetPrivateProfileString( 'Preset'..i, 'Len', '0', filename ) 
      local retval, Name = BR_Win32_GetPrivateProfileString( 'Preset'..i, 'Name', '0', filename ) 
      local retval, data_str0 = BR_Win32_GetPrivateProfileString( 'Preset'..i, 'Data', '0', filename ) 
      local data = {data_str0}
      for j = 1, 1000 do
        local retval0, data_str = BR_Win32_GetPrivateProfileString( 'Preset'..i, 'Data_'..j, '0', filename ) 
        if retval0 ==1 then data[#data+1] = data_str else break end
      end
      t[Name] = {Len = Len, data = data}
    end
    
    i = 0
    for Name in spairs(t) do
      BR_Win32_WritePrivateProfileString( 'Preset'..i, 'Len', t[Name].Len, filename )
      BR_Win32_WritePrivateProfileString( 'Preset'..i, 'Name', Name, filename )
      for j = 1, #t[Name].data do
        local key ='Data_'..j-1
        if j == 1 then key = 'Data' end
        BR_Win32_WritePrivateProfileString( 'Preset'..i, key, t[Name].data[j], filename )
      end
      i = i + 1
    end
    
    -- get params
      local params = {}
      for param = 1, reaper.TrackFX_GetNumParams( tr, fxnum ) do
        params[param], minval, maxval = reaper.TrackFX_GetParam( tr, fxnum, param-1 )
      end
      
    -- refresh table
      local preset_idx, numberOfPresets = reaper.TrackFX_GetPresetIndex( tr, fxnum )
      reaper.TrackFX_SetPresetByIndex(tr, fxnum,preset_idx )

    -- restore params    
      for i = 1, #params do reaper.TrackFX_SetParam( tr,fxnum, i-1, params[i] ) end
      
    MB('Succesfully sorted', 'Sort focused FX presets alphabetically', 0)
  end  
---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
-------------------------------------------------------------------- 
  local ret, ret2 = CheckFunctions('VF_CheckReaperVrs') 
  if ret then ret2 = VF_CheckReaperVrs(5.973) end
  if ret and ret2 then main() end
  ]]
  
  
  
  
  