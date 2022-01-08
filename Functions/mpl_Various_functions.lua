-- @description Various_functions
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @about Functions used by MPL scripts.
-- @version 2.74
-- @provides
--    mpl_Various_functions_v1.lua
--    mpl_Various_functions_v2.bin
--    mpl_Various_functions_v3.lua
--    mpl_Various_functions_GUI.lua
--    mpl_Various_functions_MOUSE.lua
--    mpl_Various_functions_Purchase.lua
--    mpl_Various_functions_Pers.lua
--    [main] mpl_Various_functions_PurchaseGUI.lua
-- @changelog
--    # move to the v1 scope VF_FormatToNormValue(), VF_NormToFormatValue(), VF_GetTakeGUID()
    
  VF_version = 2.74 -- do not remove, use for versions comparement
  VF_isregist = 0 
  --------------------------------------------------
  function VF_LoadLibraries()
    local info = debug.getinfo(1,'S');  
    local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]]) 
    dofile(script_path .. "mpl_Various_functions_GUI.lua")
    dofile(script_path .. "mpl_Various_functions_v3.lua")
    dofile(script_path .. "mpl_Various_functions_MOUSE.lua")
    dofile(script_path .. "mpl_Various_functions_Purchase.lua")
    dofile(script_path .. "mpl_Various_functions_Pers.lua")
  end
 
  --------------------------------------------------    
  function VF_LoadVFv1()
    local info = debug.getinfo(1,'S');  
    local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]]) .. "mpl_Various_functions_v1.lua"
    local f = io.open(script_path,'r')
    if f then 
      local content = f:read('a')
      f:close()
      local funct2run = load(content)
      if funct2run then funct2run() VF_isregist = VF_isregist|1 end
     else
      reaper.MB('mpl_Various_functions_v1 not found', 'MPL VariousFunctions', 0)
    end
  end  
--------------------------------------------------- 
  function VF2_LoadVFv2()
    local response = reaper.GetExtState('MPL_Scripts', 'response')
    if response == '' then  
      local info = debug.getinfo(1,'S');  
      local purch_script_path = info.source:match([[^@?(.*[\/])[^\/]-$]] ) .. "mpl_Various_functions_PurchaseGUI.lua" 
      purch_script_pathID = VF_GetActionCommandIDByFilename('mpl_Various_functions_PurchaseGUI', 0)
      Action('_'..purch_script_pathID)
     else
      local sysID = VF_GetSystemID()
      local check_offset = VF_CheckResponseOffset(sysID,response)
      if check_offset then 
        VF_LoadVFv2_DecodeBinary(sysID,response)
        VF_isregist = VF_isregist|2
       else
        MB('Checksum mismatch. Contact m.pilyavskiy@gmail.com','MPL Various functions',0)
      end
    end 
  end
  --------------------------------------------------
  VF_LoadLibraries()
  VF_LoadVFv1() 
  VF2_LoadVFv2()
  
