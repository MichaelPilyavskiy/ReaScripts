-- @description Toggle gradually transition for tempo marker before edit cursor
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init


curpos =  reaper.GetCursorPositionEx( 0 )
ptidx =  reaper.FindTempoTimeSigMarker( 0, curpos + 10^-15 )
if ptidx >=0 then 
  retval, timepos, measurepos, beatpos, bpm, timesig_num, timesig_denom, lineartempo = reaper.GetTempoTimeSigMarker( 0, ptidx )
  reaper.SetTempoTimeSigMarker( 0, ptidx, timepos, measurepos, beatpos, bpm, timesig_num, timesig_denom, not lineartempo )
  reaper.UpdateTimeline()
end