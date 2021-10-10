-- @description Show plugin path for focused FX
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init
 
  --NOT gfx NOT reaper
  function main()
    local retval, trackid,_, fxid = reaper.GetFocusedFX()
    if retval then
       track = reaper.GetTrack(0, trackid-1)
      if trackid == 0 then track = reaper.GetMasterTrack( 0 ) end
      if track then
        local retval, buf = reaper.TrackFX_GetNamedConfigParm(track, fxid, 'fx_ident')
        reaper.ClearConsole()
        reaper.ShowConsoleMsg(buf)
      end  
    end
  end  
  
  vrs = reaper.GetAppVersion()
  vrs_major = vrs:match('%d+%.%d+')
  if vrs_major and tonumber(vrs_major) and tonumber(vrs_major ) >= 6.37 then main() else reaper.MB('This script is supported from REAPER 6.37+', 'Error', 0)end