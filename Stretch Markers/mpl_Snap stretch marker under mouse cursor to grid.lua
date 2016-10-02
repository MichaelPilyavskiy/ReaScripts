-- @description Snap stretch marker under mouse cursor to grid
-- @version 1.0
-- @author mpl
-- @website http://forum.cockos.com/member.php?u=70694 
-- @changelog
--    + init
  
  
  pixel_find = 4
  
  
  
  function main(pixel_find)    
    local pixel_per_sec = reaper.GetHZoomLevel()
    local second_find = pixel_find / pixel_per_sec
    reaper.BR_GetMouseCursorContext()
    local pos = reaper.BR_GetMouseCursorContext_Position()
    local item =  reaper.BR_GetMouseCursorContext_Item()
    local take = reaper.BR_GetMouseCursorContext_Take()
    
    if pos >= 0 and item and take and not reaper.TakeIsMIDI( take ) then 
      local item_pos = reaper.GetMediaItemInfo_Value( item, 'D_POSITION' )
      local item_len = reaper.GetMediaItemInfo_Value( item, 'D_LENGTH' )
      local sm_pos = pos - item_pos
      local cnt_SM = reaper.GetTakeNumStretchMarkers( take )
      if cnt_SM > 0 then
        reaper.SetTakeStretchMarker( take, -1, 0) 
        reaper.SetTakeStretchMarker( take, -1, item_len) 
        for i = 1, cnt_SM do
          local _, pos, srcpos = reaper.GetTakeStretchMarker( take, i-1 )
          if math.abs(pos - sm_pos) <second_find  then
            local snap_pos = reaper.BR_GetClosestGridDivision( sm_pos )
            reaper.SetTakeStretchMarker( take, i-1, snap_pos)             
            break
          end      
        end              
      end
    end
    
  end
  
  reaper.Undo_BeginBlock()
  main(pixel_find)
  reaper.UpdateArrange()
  reaper.Undo_EndBlock("Snap stretch marker under mouse cursor to grid", 0)
