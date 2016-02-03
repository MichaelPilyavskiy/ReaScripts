--[[
   * ReaScript Name: Duplicate items to closest grid
   * Lua script for Cockos REAPER
   * Author: Michael Pilyavskiy (mpl)
   * Author URI: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
   * Version: 1.0
  ]]
  
script_title = "Duplicate items to closest grid"

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

count_sel_items = reaper.CountSelectedMediaItems(0)
      
if  count_sel_items ~= nil then
  for i = 1, count_sel_items do
    item = reaper.GetSelectedMediaItem(0, i-1)
    if item ~= nil then
      item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
      dupl_pos = item_pos+item_len+0.0001
      new_pos = reaper.BR_GetClosestGridDivision(dupl_pos)
      reaper.ApplyNudge(0, 0, 5, 1, new_pos-item_pos , 0, 1) 
      
    end  
  end    
end     
      
      
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(script_title, 0)
