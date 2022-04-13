-- @description Various_functions
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @about Functions used by MPL scripts.
-- @version 3.10
-- @provides
--    mpl_Various_functions_v1.lua
--    mpl_Various_functions_v3.lua
--    mpl_Various_functions_GUI.lua
--    mpl_Various_functions_MOUSE.lua
--    mpl_Various_functions_Pers.lua
-- @changelog
--    + GUI_RESERVED_draw_data2 for draw before text
--    # drawtxt: support flag2
--    + DATA_RESERVED_ONPROJCHANGE(DATA)
--    + Custom Layer: redraw only visible area
--    + Settings: allow long readout up to item width


    
  VF_version = 3.10 -- do not remove, used for versions comparement
  VF_isregist = 1|2 -- do not remove, used for VF versions check
  --------------------------------------------------
  function VF_LoadLibraries()
    local info = debug.getinfo(1,'S');  
    local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]]) 
    dofile(script_path .. "mpl_Various_functions_GUI.lua")
    dofile(script_path .. "mpl_Various_functions_v1.lua")
    dofile(script_path .. "mpl_Various_functions_v3.lua")
    dofile(script_path .. "mpl_Various_functions_MOUSE.lua")
    --dofile(script_path .. "mpl_Various_functions_Purchase.lua")
    dofile(script_path .. "mpl_Various_functions_Pers.lua")
  end
--------------------------------------------------- 
  function VF2_UpdUsedCount() 
    local cnt = reaper.GetExtState('MPL_Scripts', 'counttotal')
    if cnt == '' then cnt = 0 end
    cnt = tonumber(cnt)
    if not cnt then cnt = 0 end
    cnt = cnt + 1 
    reaper.SetExtState('MPL_Scripts', 'counttotal', cnt, true)
  end
  --------------------------------------------------
  VF_LoadLibraries() 
  VF2_UpdUsedCount() 
  
  
