-- @description Pooled FX tools
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init
-- @provides
--    mpl_Pooled FX tools.lua
--    [main] mpl_Pooled FX tools/mpl_Set selected track as pooled fx master (group 1).lua
--    [main] mpl_Pooled FX tools/mpl_Add pooled fx slave JSFX to selected tracks at chain end.lua
--    [main] mpl_Pooled FX tools/mpl_Add pooled fx slave JSFX to selected tracks at chain start.lua
--    [main] mpl_Pooled FX tools/mpl_Propagate pooled FX to project (group 1).lua

  --[[
  propagate all/focused pooled FX parameters to project
  propagate all/focused pooled FX bypass state to project
  for realtime tweak I can build a one-knob UI to rule last touched parameter for all FX instances in project which are pooled and have same name
  "print" strip to track, i.e. remove "POOL" from "POOL <FX_name>", remove slave JSFX]]
