-- @description Select track of floating FX
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--   + init

 retval, tracknumberOut = reaper.GetFocusedFX()
 tr = reaper.CSurf_TrackFromID( tracknumberOut, true )
 if tr then reaper.SetOnlyTrackSelected( tr  ) end