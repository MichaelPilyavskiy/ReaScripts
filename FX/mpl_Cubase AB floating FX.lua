-- @description AB floating FX parameters
-- @version 1.05
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # fix missing FX GUID error
-- @about
--    implementation of "AB" button in Cubase 7+ plugin window
--    Instructions: float FX, changes params, run script, change params again and run script again. 
--    It will change plugin parameters beetween two states. Use mpl_Cubase AB floating FX make equal to make two states same.

     
  function main()
    local retval, tracknumber, itemnumber, fxnum = reaper.GetFocusedFX2()
    if retval == 0 then return end
    local tr = CSurf_TrackFromID( tracknumber, false )
    if not ValidatePtr2( 0, tr, 'MediaTrack*' ) then return end
    local it = GetTrackMediaItem( tr, itemnumber )
    
    local func_str = 'TrackFX_'
    if retval&1 == 1 then 
      ptr = tr
     elseif retval&2 == 2 then  
      local takeidx = (fxnum>>16)&0xFFFF
      ptr = GetTake( it, takeidx )
      func_str = 'TakeFX_'
     elseif retval == 4 then  
      return 
    end
    
    -- get current config  
      local config_t = {}
      local fx_guid = _G[func_str..'GetFXGUID'](ptr, fxnum&0xFFFF)    
      local count_params = _G[func_str..'GetNumParams'](ptr, fxnum&0xFFFF)
      if count_params ~= nil then        
        for i = 1, count_params do
          value = _G[func_str..'GetParam'](ptr, fxnum&0xFFFF, i-1) 
          table.insert(config_t, i, tostring(value))
        end  
      end              
      config_t_s = table.concat(config_t,"_")
      if not fx_guid then return end
      
    -- check memory -- 
      local ret, config_t_ret = GetProjExtState(0, "mpl_CubaseFloatAB", fx_guid)    
      if config_t_ret == "" then 
        SetProjExtState(0, "mpl_CubaseFloatAB", fx_guid, config_t_s) -- if nothing in memory just store current config
       else
        local config_formed_t = {} -- if config is already in memory       -- form table from string stored in memory
        for match in string.gmatch(config_t_ret, "([^_]+)") do tonumber(match) table.insert(config_formed_t, match) end
        
        -- set values
        for i = 1, #config_formed_t do
          fx_value = tonumber(config_formed_t[i])
          _G[func_str..'SetParam'](ptr, fxnum&0xFFFF, i-1, fx_value)
        end        
              
        -- store current config
        SetProjExtState(0, "mpl_CubaseFloatAB", fx_guid, config_t_s)
      end 
    
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.07) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then main() end end