-- @description Set time selection from edit cursor to end of current region
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    # fix "end" keyword, doesn't work in first region (Lokasenna)

  
cur_pos =  reaper.GetCursorPositionEx( 0 )
_, regionidx = reaper.GetLastMarkerAndCurRegion( 0, cur_pos )
if regionidx >= 0 then 
  _, _, _, end_pos = reaper.EnumProjectMarkers( regionidx )
  reaper.GetSet_LoopTimeRange2( 0, true, true, end_pos, cur_pos, false)
end