-- @description Pooled FX tools
-- @version 1.01
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @provides
--    mpl_Pooled FX tools.lua
--    [main] mpl_Pooled FX tools/mpl_Set selected track as pooled fx master (group 1).lua
--    [main] mpl_Pooled FX tools/mpl_Add pooled fx slave JSFX to selected tracks at chain end.lua
--    [main] mpl_Pooled FX tools/mpl_Add pooled fx slave JSFX to selected tracks at chain start.lua
--    [main] mpl_Pooled FX tools/mpl_Propagate pooled FX (group 1).lua
--    [main] mpl_Pooled FX tools/mpl_Propagate last touched parameter to all pooled FX parameters.lua
-- @changelog
--    # Propagate pooled FX to project: Remove pooled FX if not exist in master chain but still marked as pool for defined group
--    # Rename 'Propagate pooled FX to project (group 1)' to 'Propagate pooled FX (group 1)'
--    + Action: Propagate last touched parameter to all pooled FX parameters


  --[[
  propagate all/focused pooled FX parameters to project
  propagate all/focused pooled FX bypass state to project
  "print" strip to track, i.e. remove "POOL" from "POOL <FX_name>", remove slave JSFX]]