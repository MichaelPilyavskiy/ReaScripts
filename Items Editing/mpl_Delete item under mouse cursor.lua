--[[
   * ReaScript Name: Delete item under mouse cursor
   * Lua script for Cockos REAPER
   * Author: Michael Pilyavskiy (mpl)
   * Author URI: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
   * Version: 1.0
  ]]
  
_,_,_ = reaper.BR_GetMouseCursorContext()
item = reaper.BR_GetMouseCursorContext_Item()
track = reaper.BR_GetMouseCursorContext_Track()
if item~=nil then reaper.DeleteTrackMediaItem(track, item) reaper.UpdateArrange() end
