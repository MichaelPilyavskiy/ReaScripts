  --[[
     * ReaScript Name: Duplicate item to next grid division
     * Lua script for Cockos REAPER
     * Author: Michael Pilyavskiy (mpl)
     * Author URI: http://forum.cockos.com/member.php?u=70694
     * Licence: GPL v3
     * Version: 1.0
    ]]
    
  script_title = 'Duplicate item to next grid division'
  
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  
  count_sel_items = reaper.CountSelectedMediaItems(0)
  if  count_sel_items ~= nil then
    for i = 1, count_sel_items do
      item = reaper.GetSelectedMediaItem(0, i-1)
      if item ~= nil then
        item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        next_pos = reaper.BR_GetNextGridDivision(item_pos)
        reaper.ApplyNudge(0, 0, 5, 1, next_pos-item_pos , 0, 1) 
      end
    end
  end     
        
        
  reaper.UpdateArrange()
  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock(script_title, 0)
