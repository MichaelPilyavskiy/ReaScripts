--[[
   * ReaScript Name: Set fadeout of item under cursor to mouse position
   * Lua script for Cockos REAPER
   * Author: Michael Pilyavskiy (mpl)
   * Author URI: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
   * Version: 1.0
  ]]
  
  reaper.BR_GetMouseCursorContext()
  item = reaper.BR_GetMouseCursorContext_Item()
  pos_cur = reaper.BR_GetMouseCursorContext_Position()
  if item ~= nil then
    pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    len = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH' )    
    reaper.SetMediaItemInfo_Value(item, 'D_FADEOUTLEN', len - pos_cur + pos)
    reaper.UpdateItemInProject(item)
  end
