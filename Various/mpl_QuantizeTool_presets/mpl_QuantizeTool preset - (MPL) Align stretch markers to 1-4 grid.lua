-- @description Set QuantizeTool preset to '(MPL) Align stretch markers to 1-4 grid'
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @version 1.0pre1
-- @changelog
--     + init

reaper.SetExtState("MPL_QuantizeTool", "ext_strategy_name", "(MPL) Align stretch markers to 1-4 grid",false)
reaper.SetExtState("MPL_QuantizeTool","ext_state",1,false)
