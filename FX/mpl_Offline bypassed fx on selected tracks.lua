-- @description Offline bypassed fx on selected tracks
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @version 1.02
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
  --------------------------------------------------------------------
  function main()
    Undo_BeginBlock()
    for i =1, CountSelectedTracks(0) do 
      local tr = GetSelectedTrack(0,i-1)
      for fx = TrackFX_GetCount( tr ), 1, -1 do
        local is_byp = TrackFX_GetEnabled( tr, fx-1 )
        if not is_byp then 
          local byp_param =  TrackFX_GetParamFromIdent( tr, fx-1, ':bypass' )
          local byp_envelope = reaper.GetFXEnvelope( tr, fx-1, byp_param, false )
          if not byp_envelope then 
            TrackFX_SetOffline( tr, fx-1, 1 ) 
          end
        end
      end
    end
    Undo_EndBlock('Offline bypassed fx on selected tracks', 0)
  end 
  --------------------------------------------------------------------  
  if VF_CheckReaperVrs(6.37,true) then main() end 
  