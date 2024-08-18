-- @description Toggle auto bypass on silence
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @metapackage
-- @provides
--    [main] . > mpl_Toggle auto bypass on silence for all project FX.lua
--    [main] . > mpl_Toggle auto bypass on silence for selected track FX.lua
-- @changelog
--    # VF independent

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------
  function VF_CheckReaperVrs(rvrs, showmsg) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      if showmsg then reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0) end
      return
     else
      return true
    end
  end
 ---------------------------------------------------
  function main(selectedtrackmode)
    local extstatekey = 'MPLFABPTOGGLE'
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
          local retval, buf = TrackFX_GetNamedConfigParm( track, fx_id-1, 'force_auto_bypass' )
          if retval then 
            local is_bypass = tonumber(buf)
            str = str..'\n'..TrackFX_GetFXGUID( track, fx_id-1)..' '..is_bypass
            TrackFX_SetNamedConfigParm( track, fx_id-1, 'force_auto_bypass',1 )
          end 
        end

        for fx_id = 1,  TrackFX_GetCount( track ) do
          local retval, buf = TrackFX_GetNamedConfigParm( track, 0x1000000+fx_id-1, 'force_auto_bypass' )
          if retval then 
            local is_bypass = tonumber(buf)
            str = str..'\n'..TrackFX_GetFXGUID( track, 0x1000000+fx_id-1)..' '..is_bypass
            TrackFX_SetNamedConfigParm( track, 0x1000000+fx_id-1, 'force_auto_bypass',1 )
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
            TrackFX_SetNamedConfigParm( track, fx_id-1, 'force_auto_bypass',t[GUID] )
          end
        end
        
        for fx_id = 1,  TrackFX_GetRecCount( track ) do
          local GUID = TrackFX_GetFXGUID( track, 0x1000000+fx_id-1)
          if t[GUID] then 
            TrackFX_SetNamedConfigParm( track, 0x1000000+fx_id-1, 'force_auto_bypass',t[GUID] )
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
    ---------------------------------------------------------------------  
  if VF_CheckReaperVrs(6.72,true) then 
    local selectedtrackmode = ({reaper.get_action_context()})[2]:match('selected') 
    main(selectedtrackmode)
  end 