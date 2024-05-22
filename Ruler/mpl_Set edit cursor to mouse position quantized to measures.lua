-- @description Set edit cursor to mouse position quantized to measures
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

local x,y = reaper.GetMousePosition()
mouse_pos = reaper.GetSet_ArrangeView2(0, false, x, x+1)
moveview = true
seekplay = false
beats, measures, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats( 0, mouse_pos )
mouse_pos_quantized = reaper.TimeMap2_beatsToTime( 0, 0, math.floor(measures +  beats / cml  + 0.5) )
reaper.SetEditCurPos(  mouse_pos_quantized, moveview, seekplay )