-- @description Sort focused FX presets alphabetically
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init
 
  -------------------
  function main()
    -- get preset file
    local retval, trnum, _, fxnum = GetFocusedFX()
    if retval ~= 1 then return end
    local tr = GetTrack(0,trnum-1)
    local filename = reaper.TrackFX_GetUserPresetFilename(tr, fxnum, '')
    local file = io.open(filename, "r")
    local content if file then content = file:read('*a')  file:close()  else  return   end
    
    -- get data
    local retval, LastDefImpTime = BR_Win32_GetPrivateProfileString( 'General', 'LastDefImpTime', '0', filename )
    local retval, NbPresets = BR_Win32_GetPrivateProfileString( 'General', 'NbPresets', '0', filename )  
    t = {}
    for i = 0, tonumber(NbPresets)-1 do
      local retval, Len = BR_Win32_GetPrivateProfileString( 'Preset'..i, 'Len', '0', filename ) 
      local retval, Name = BR_Win32_GetPrivateProfileString( 'Preset'..i, 'Name', '0', filename ) 
      local retval, data_str0 = BR_Win32_GetPrivateProfileString( 'Preset'..i, 'Data', '0', filename ) 
      local data = {data_str0}
      for j = 1, 50 do
        local retval0, data_str = BR_Win32_GetPrivateProfileString( 'Preset'..i, 'Data_'..j, '0', filename ) 
        if retval ==1 then data[#data+1] = data_str end
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
  
  
  
  
  
  