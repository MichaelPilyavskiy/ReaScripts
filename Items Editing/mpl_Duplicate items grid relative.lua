-- @description Duplicate items grid relative
-- @version 1.21
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # ReaPack header
--    # fix error on no items selected


-- 1.2 multiple items tweaks

script_title = "Duplicate items grid relative"

  function get_new_pos(item1) 
    if not item1 then return end
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
  
  function main()
    count_sel_items = reaper.CountSelectedMediaItems(0)       
    if  count_sel_items ~= nil then
      item_fin = reaper.GetSelectedMediaItem(0, count_sel_items-1) 
      new_pos = get_new_pos(item_fin)   
      if not new_pos then return end
      item0 = reaper.GetSelectedMediaItem(0, 0)
      item0_pos = reaper.GetMediaItemInfo_Value(item0, "D_POSITION")
      item0_pos_grid = reaper.BR_GetClosestGridDivision(item0_pos+0.0001)
      diff = new_pos-item0_pos    
      reaper.ApplyNudge(2, 0, 5, 1, diff + (item0_pos_grid - item0_pos), 0, 1)
    end     
  end
  main()
      
      
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(script_title, 0)