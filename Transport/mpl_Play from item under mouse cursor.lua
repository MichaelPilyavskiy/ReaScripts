--[[
   * ReaScript Name: Play from item under mouse cursor
   * Lua script for Cockos REAPER
   * Author: MPL
   * Author URI: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
   * Version: 1.0
  ]]
  
_, _, _ = reaper.BR_GetMouseCursorContext()
item = reaper.BR_GetMouseCursorContext_Item()
if item ~= nil then
  pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
  reaper.SetEditCurPos2(0, pos, true, true)
  reaper.CSurf_OnPlay()
end
