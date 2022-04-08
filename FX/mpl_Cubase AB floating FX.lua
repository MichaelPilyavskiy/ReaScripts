-- @description AB floating FX parameters
-- @version 1.03
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # fix non track trigger
-- @about
--    implementation of "AB" button in Cubase 7+ plugin window
--    Instructions: float FX, changes params, run script, change params again and run script again. 
--    It will change plugin parameters beetween two states. Use mpl_Cubase AB floating FX make equal to make two states same.

     
  function main()
    local retval, track, item, fxnum = GetFocusedFX()
    local track = GetTrack(0, track-1)
    if retval == 1 and track then -- if track fx
    
        -- get current config  
        config_t = {}
        fx_guid = TrackFX_GetFXGUID(track, fxnum)    
        count_params = TrackFX_GetNumParams(track, fxnum)
        if count_params ~= nil then        
          for i = 1, count_params do
            value = TrackFX_GetParam(track, fxnum, i-1) 
            table.insert(config_t, i, tostring(value))
          end  
        end              
        config_t_s = table.concat(config_t,"_")
    
    
      -- check memory -- 
      ret, config_t_ret = GetProjExtState(0, "mpl_CubaseFloatAB", fx_guid)    
      if config_t_ret == "" then
      
        -- if nothing in memory just store current config
        SetProjExtState(0, "mpl_CubaseFloatAB", fx_guid, config_t_s)
       
       else
        -- if config is already in memory
        
          -- form table from string stored in memory
          config_formed_t = {}        
          for match in string.gmatch(config_t_ret, "([^_]+)") do tonumber(match) table.insert(config_formed_t, match) end
          
          -- set values
          for i = 1, #config_formed_t do
            fx_value = config_formed_t[i]
            TrackFX_SetParam(track, fxnum, i-1, fx_value)
          end        
                
          -- store current config
          SetProjExtState(0, "mpl_CubaseFloatAB", fx_guid, config_t_s)
      end  
    end 
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.07) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then main() end end