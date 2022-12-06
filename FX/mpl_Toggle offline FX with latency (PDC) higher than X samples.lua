-- @description Toggle offline FX with latency (PDC) higher than X samples
-- @version 1.07
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @metapackage
-- @provides
--    [main] . > mpl_Toggle offline selected track FX with latency (PDC) higher than 64 samples.lua
--    [main] . > mpl_Toggle offline selected track FX with latency (PDC) higher than 128 samples.lua
--    [main] . > mpl_Toggle offline selected track FX with latency (PDC) higher than 256 samples.lua
--    [main] . > mpl_Toggle offline selected track FX with latency (PDC) higher than 512 samples.lua
--    [main] . > mpl_Toggle offline selected track FX with latency (PDC) higher than 1024 samples.lua
--    [main] . > mpl_Toggle offline selected track FX with latency (PDC) higher than 2048 samples.lua
--    [main] . > mpl_Toggle offline selected track FX with latency (PDC) higher than 4096 samples.lua
--    [main] . > mpl_Toggle offline selected track FX with latency (PDC) higher than 8192 samples.lua
-- @changelog
--    + add offline mode
 
  --NOT gfx NOT reaper
  --------------------------------------------------------------------
  function main(spl_thrshld,selectedtrackmode, offlinemode)
    local state =  GetExtState( 'MPLPDCTOGGLEOFF', 'STATE' ) 
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
          local retval, buf = TrackFX_GetNamedConfigParm( track, fx_id-1, 'pdc' )
          if retval and tonumber(buf) and tonumber(buf) > spl_thrshld then  
            local is_bypass = TrackFX_GetEnabled( track, fx_id-1)
            if offlinemode then  is_bypass = not TrackFX_GetOffline( track, fx_id-1) end
            if is_bypass then is_bypass =1 else is_bypass = 0 end       
            str = str..'\n'..TrackFX_GetFXGUID( track, fx_id-1)..' '..is_bypass
            if not offlinemode then  TrackFX_SetEnabled( track, fx_id-1, false) else TrackFX_SetOffline( track, fx_id-1, true ) end
          end 
        end

        for fx_id = 1,   TrackFX_GetRecCount( track ) do
          local retval, buf = TrackFX_GetNamedConfigParm( track, 0x1000000+ fx_id-1, 'pdc' )
          if retval and tonumber(buf) and tonumber(buf) > spl_thrshld then  
            local is_bypass = TrackFX_GetEnabled( track, 0x1000000 + fx_id-1) 
            if offlinemode then  is_bypass = not TrackFX_GetOffline( track, fx_id-1) end
            if is_bypass then is_bypass =1 else is_bypass = 0 end       
            str = str..'\n'..TrackFX_GetFXGUID( track, 0x1000000 + fx_id-1)..' '..is_bypass
            TrackFX_SetEnabled( track, 0x1000000 + fx_id-1, false)
            if not offlinemode then  TrackFX_SetEnabled( track, 0x1000000 + fx_id-1, false) else TrackFX_SetOffline( track, 0x1000000 + fx_id-1, true ) end
          end 
        end
                
        
      end
      
      
      SetButtonON()
      SetExtState( 'MPLPDCTOGGLEOFF', 'STATE', 1, true )
      SetProjExtState( 0, 'MPLPDCTOGGLEOFF', 'FXGUIDS', str )
     else
      
      local ret, str = GetProjExtState( 0, 'MPLPDCTOGGLEOFF', 'FXGUIDS' )
       t = {}
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
            local st = t[GUID]==1
            if not offlinemode then  TrackFX_SetEnabled( track, fx_id-1, st) else TrackFX_SetOffline( track, fx_id-1, not st ) end
          end
        end
        
        for fx_id = 1,  TrackFX_GetRecCount( track ) do
          local GUID = TrackFX_GetFXGUID( track, 0x1000000+fx_id-1)
          if t[GUID] then 
            local st = t[GUID]==1
            if not offlinemode then  TrackFX_SetEnabled( track, 0x1000000+fx_id-1, st) else TrackFX_SetOffline( track, 0x1000000+fx_id-1, not st ) end
          end
        end
        
      end  
      SetButtonOFF()
      SetExtState( 'MPLPDCTOGGLEOFF', 'STATE', 0, true )
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
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.51) 
  if ret then 
    local ret2 = VF_CheckReaperVrs(5.95,true) 
    if ret2 then 
      local cnt_spls = ({reaper.get_action_context()})[2]:match('([%d]+) samples')
      local selectedtrackmode = ({reaper.get_action_context()})[2]:match('selected track') 
      local offlinemode = ({reaper.get_action_context()})[2]:match('offline') 
      if not (cnt_spls and tonumber(cnt_spls)) then cnt_spls = 256 else cnt_spls = tonumber(cnt_spls) end 
      main(cnt_spls, selectedtrackmode, true)
    end end