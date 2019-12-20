-- @description Smart duplicate items grid relative
-- @version 1.13
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    # fix crash on zero selection

  
  function main()
    count_sel_items = reaper.CountSelectedMediaItems(0)
    local floating_point_threshold = 0.000001
          
    if  count_sel_items ~= 0 then
    
      min_pos = math.huge
      max_pos = 0
      for i = 1, count_sel_items do
        item = reaper.GetSelectedMediaItem(0, i-1)
        if item ~= nil then
          item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
          item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
          min_pos= math.min(min_pos,item_pos)
          max_pos= math.max(max_pos,item_pos+item_len)
        end  
      end
      com_len = max_pos-min_pos   

      closest_division = reaper.BR_GetClosestGridDivision(min_pos)
      
      if math.abs(closest_division - min_pos) < floating_point_threshold then 
        prev_division = closest_division
      else 
        prev_division = reaper.BR_GetPrevGridDivision(min_pos)
      end
      
      closest_division2 = reaper.BR_GetClosestGridDivision(max_pos)     
      if math.abs(closest_division2 - max_pos) < floating_point_threshold then
        next_division = closest_division2
      else 
        next_division = reaper.BR_GetNextGridDivision(max_pos) 
      end  
      
      nudge_diff = com_len + (min_pos-prev_division)+(next_division-max_pos)
      reaper.ApplyNudge(0, 0, 5, 1, nudge_diff , 0, 1)   
    end     
  end
     
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Smart duplicate items grid relative", 0)