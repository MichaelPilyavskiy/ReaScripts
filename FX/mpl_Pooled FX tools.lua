-- @description Pooled FX tools
-- @version 1.02
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @provides
--    mpl_Pooled FX tools.lua
--    [main] mpl_Pooled FX tools/mpl_Set selected track as pooled fx master (group 1).lua
--    [main] mpl_Pooled FX tools/mpl_Add pooled fx slave JSFX to selected tracks at chain end.lua
--    [main] mpl_Pooled FX tools/mpl_Add pooled fx slave JSFX to selected tracks at chain start.lua
--    [main] mpl_Pooled FX tools/mpl_Propagate pooled FX (group 1).lua
--    [main] mpl_Pooled FX tools/mpl_Propagate last touched parameter to all pooled FX parameters.lua
--    [main] mpl_Pooled FX tools/mpl_Propagate pooled FX master parameters to all slaves (group 1).lua
--    [main] mpl_Pooled FX tools/mpl_Propagate pooled FX master bypass states to all slaves (group 1).lua
-- @changelog
--    # Set selected track as pooled fx master (group 1) / fix error on no track selection
--    + Action: Propagate pooled FX master parameters to all slaves (group 1).lua
--    + Action: Propagate pooled FX master bypass states to all slaves (group 1).lua



  --[[ "print" strip to selected track, i.e. remove "POOL" from "POOL <FX_name>", remove slave JSFX]]
