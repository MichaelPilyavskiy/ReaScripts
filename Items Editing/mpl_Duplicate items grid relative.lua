--[[
   * ReaScript Name: Duplicate items grid relative
   * Lua script for Cockos REAPER
   * Author: MPL
   * Author URI: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
   * Version: 1.2
  ]]

-- 1.2 multiple items tweaks

script_title = "Duplicate items grid relative"

  function get_new_pos(item1) 
    local item_pos = reaper.GetMediaItemInfo_Value(item1, "D_POSITION")
    local item_len = reaper.GetMediaItemInfo_Value(item1, "D_LENGTH")
    local dupl_pos = item_pos+item_len+0.0001      
    local new_pos = reaper.BR_GetClosestGridDivision(dupl_pos)
    if new_pos == item_pos then 
      new_pos = reaper.BR_GetNextGridDivision(dupl_pos)
    end
    return new_pos
  end
  
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  
  count_sel_items = reaper.CountSelectedMediaItems(0)
       
  if  count_sel_items ~= nil then
    item_fin = reaper.GetSelectedMediaItem(0, count_sel_items-1) 
    item0 = reaper.GetSelectedMediaItem(0, 0)
    if item_fin == nil or item0 == nil then return end
    new_pos = get_new_pos(item_fin)
    item0_pos = reaper.GetMediaItemInfo_Value(item0, "D_POSITION")
    item0_pos_grid = reaper.BR_GetClosestGridDivision(item0_pos+0.0001)
    diff = new_pos-item0_pos    
    reaper.ApplyNudge(2, 0, 5, 1, diff + (item0_pos - item0_pos_grid), 0, 1)
  end     
      
      
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(script_title, 0)
