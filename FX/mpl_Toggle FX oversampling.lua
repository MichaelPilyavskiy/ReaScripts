-- @description Toggle FX oversampling
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @metapackage
-- @provides
--    [main] . > mpl_Toggle set to none oversampling for all project FX.lua
--    [main] . > mpl_Toggle set to none oversampling for selected track FX.lua
--    [main] . > mpl_Toggle set to 2x oversampling for all project FX.lua
--    [main] . > mpl_Toggle set to 2x oversampling for selected track FX.lua
--    [main] . > mpl_Toggle set to 4x oversampling for all project FX.lua
--    [main] . > mpl_Toggle set to 4x oversampling for selected track FX.lua
--    [main] . > mpl_Toggle set to 8x oversampling for all project FX.lua
--    [main] . > mpl_Toggle set to 8x oversampling for selected track FX.lua
-- @changelog
--    + init
 
  --NOT gfx NOT reaper
  --------------------------------------------------------------------
  function main(selectedtrackmode, instanceOS)
    local extstatekey = 'MPLOVSMPLTOGGLE'
    if selectedtrackmode then extstatekey = extstatekey..'_SEL' end
    local state =  GetExtState( extstatekey, 'STATE' )
    if not state or state == '' or tonumber(state)==0 then 
      
      -- bypass 
      local cnttr = CountTracks(0) if selectedtrackmode then cnttr = CountSelectedTracks(0) end
      local str = ''
      for tr_id = 0, cnttr do
        local track
        if not selectedtrackmode then 
          if tr_id ==0 then track = GetMasterTrack( 0 ) else track = GetTrack(0,tr_id-1) end
         else
          track = GetSelectedTrack( 0,tr_id-1 )
        end
        
        for fx_id = 1,  TrackFX_GetCount( track ) do
          local retval, buf = TrackFX_GetNamedConfigParm( track, fx_id-1, 'instance_oversample_shift' )
          if retval then 
            local is_bypass = tonumber(buf)
            str = str..'\n'..TrackFX_GetFXGUID( track, fx_id-1)..' '..is_bypass
            TrackFX_SetNamedConfigParm( track, fx_id-1, 'instance_oversample_shift',instanceOS )
          end 
        end

        for fx_id = 1,  TrackFX_GetCount( track ) do
          local retval, buf = TrackFX_GetNamedConfigParm( track, 0x1000000+fx_id-1, 'instance_oversample_shift' )
          if retval then 
            local is_bypass = tonumber(buf)
            str = str..'\n'..TrackFX_GetFXGUID( track, 0x1000000+fx_id-1)..' '..is_bypass
            TrackFX_SetNamedConfigParm( track, 0x1000000+fx_id-1, 'instance_oversample_shift',instanceOS )
          end 
        end
                
        
      end
      
      
      SetButtonON()
      SetExtState( extstatekey, 'STATE', 1, true )
      SetProjExtState( 0, extstatekey, 'FXGUIDS', str )
      
     else
      
      local ret, str = GetProjExtState( 0, extstatekey, 'FXGUIDS' )
      local t = {}
      for line in str:gmatch('[^\r\n]+') do local GUID, bypass = line:match('({.*}) (%d)') t[GUID] = tonumber(bypass) end      
      
      local cnttr = CountTracks(0) if selectedtrackmode then cnttr = CountSelectedTracks(0) end
      for tr_id = 0, cnttr do
        local track
        if not selectedtrackmode then 
          if tr_id ==0 then track = GetMasterTrack( 0 ) else track = GetTrack(0,tr_id-1) end
         else
          track = GetSelectedTrack( 0,tr_id-1 )
        end
        
        for fx_id = 1,  TrackFX_GetCount( track ) do
          local GUID = TrackFX_GetFXGUID( track, fx_id-1)
          if t[GUID] then 
            TrackFX_SetNamedConfigParm( track, fx_id-1, 'instance_oversample_shift',t[GUID] )
          end
        end
        
        for fx_id = 1,  TrackFX_GetRecCount( track ) do
          local GUID = TrackFX_GetFXGUID( track, 0x1000000+fx_id-1)
          if t[GUID] then 
            TrackFX_SetNamedConfigParm( track, 0x1000000+fx_id-1, 'instance_oversample_shift',t[GUID] )
          end
        end
        
      end  
      SetButtonOFF()
      SetExtState( extstatekey, 'STATE', 0, true )
    end
  end

  ---------------------------------------------------------------------  
  function SetButtonON()
    is_new_value, filename, sec, cmd, mode, resolution, val = reaper.get_action_context()
    state = reaper.GetToggleCommandStateEx( sec, cmd )
    reaper.SetToggleCommandState( sec, cmd, 1 ) -- Set ON
    reaper.RefreshToolbar2( sec, cmd )
  end
  ---------------------------------------------------------------------  
  function SetButtonOFF()
    is_new_value, filename, sec, cmd, mode, resolution, val = reaper.get_action_context()
    state = reaper.GetToggleCommandStateEx( sec, cmd )
    reaper.SetToggleCommandState( sec, cmd, 0 ) -- Set OFF
    reaper.RefreshToolbar2( sec, cmd )
  end
  -------------------------------------------------------------------- 
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.51) 
  if ret then 
    local ret2 = VF_CheckReaperVrs(6.72,true) 
    if ret2 then 
      local selectedtrackmode = ({reaper.get_action_context()})[2]:match('selected') 
      local instanceOS = 0
      local OS_str = ({reaper.get_action_context()})[2]:match('set to (%d)x oversampling') 
      if OS_str then 
        if tonumber(OS_str) == 2 then instanceOS = 1
        elseif tonumber(OS_str) == 4 then instanceOS = 2
        elseif tonumber(OS_str) == 8 then instanceOS = 3
        end
      end
      main(selectedtrackmode,instanceOS)
    end end