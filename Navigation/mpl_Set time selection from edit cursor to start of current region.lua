-- @description Set time selection from edit cursor to start of current region
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    # fix comparing region ID (http://forum.cockos.com/showpost.php?p=2008307)

  
cur_pos =  reaper.GetCursorPositionEx( 0 )
_, regionidx = reaper.GetLastMarkerAndCurRegion( 0, cur_pos )
if regionidx >= 0 then 
  _, _, start = reaper.EnumProjectMarkers( regionidx )
  reaper.GetSet_LoopTimeRange2( 0, true, true, start, cur_pos, false)
end
