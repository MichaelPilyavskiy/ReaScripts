-- @description Remove item under mouse cursor
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--   # ReaPack header


  
  _,_,_ = reaper.BR_GetMouseCursorContext()
item = reaper.BR_GetMouseCursorContext_Item()
track = reaper.BR_GetMouseCursorContext_Track()
if item~=nil then reaper.DeleteTrackMediaItem(track, item) reaper.UpdateArrange() end