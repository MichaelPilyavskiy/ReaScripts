-- @description Add note into RS5k instance name on selected track
-- @version 1.01
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # VF independent
--    # use modern REAPER API

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
  function main()
    local track = GetSelectedTrack(0,0)
    if not track then return end
    
    cntfx =  TrackFX_GetCount(track) 
    for fx = 1, cntfx do
      local ret, fxname = reaper.TrackFX_GetFXName( track, fx-1, '' )
      if not fxname:match('Note %d+') then
        local MIDIpitch = math.floor(TrackFX_GetParamNormalized( track, fx-1, 3)*128) 
        reaper.TrackFX_SetNamedConfigParm( track, fx-1, 'renamed_name', 'Note '..MIDIpitch..'_'..fxname )
      end
    end 
  end
---------------------------------------------------------------------
  if VF_CheckReaperVrs(7,true) then 
      Undo_BeginBlock2( 0 )
      main() 
      Undo_EndBlock2( 0, 'Add note into RS5k instance name on selected track', -1 )
  end