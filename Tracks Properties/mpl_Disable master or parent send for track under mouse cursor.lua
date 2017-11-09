-- @description Disable master or parent send for track under mouse cursor
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

reaper.BR_GetMouseCursorContext()
tr =  reaper.BR_GetMouseCursorContext_Track()
if tr then 
  reaper.Undo_BeginBlock()
  reaper.SetMediaTrackInfo_Value( tr, 'B_MAINSEND', 0 ) 
  reaper.Undo_EndBlock( 'Disable master or parent send for track under mouse cursor', -1 )
end