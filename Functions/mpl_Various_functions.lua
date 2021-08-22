-- @description Various_functions
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @about Functions used by MPL scripts.
-- @version 2.50
-- @provides
--    mpl_Various_functions_v1.lua
--    mpl_Various_functions_v2.bin
--    mpl_Various_functions_GUI.lua
--    mpl_Various_functions_MOUSE.lua
--    mpl_Various_functions_Purchase.lua
--    mpl_Various_functions_Pers.lua
--    [main] mpl_Various_functions_PurchaseGUI.lua
-- @changelog
--    + Added persistent stuff, this planned as framework base for scripts with GUI, standartized to make it more editable at higher level
--    + Added purchase dialog as separate window
--    + Big list of small additions inside some functions related to global standartisation
    
  VF_version = 2.50 -- do not remove, use for versions comparement
     
  --------------------------------------------------
  function VF_LoadLibraries()
    local info = debug.getinfo(1,'S');  
    local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]]) 
    dofile(script_path .. "mpl_Various_functions_GUI.lua")
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
      if funct2run then funct2run() end
     else
      reaper.MB('mpl_Various_functions_v1 not found', 'MPL VariousFunctions', 0)
    end
  end  
--------------------------------------------------- 
  function VF2_LoadVFv2()
    local response = reaper.GetExtState('MPL_Scripts', 'response')
    if response == '' then 
      
      --[[ old version
      local sysID = VF_GetSystemID()
      local ret = MB('Since version 2.0 "VariousFunction" version 2+ is paid. You can use last available free version (v1.31) via ReaPack. For more information contact me via email m.pilyavskiy@gmail.com\n\nProceed purchasing package?', '' ,4)
      if ret == 6 then 
        local retval, retvals_csv = reaper.GetUserInputs( 'Purchasing VariousFunctions v2', 4, '1. Copy System ID,2.Send it to:,3.Pay $30 via Paypal,4:Enter response(1-3days):,extrawidth=200', sysID..',m.pilyavskiy@gmail.com,https://www.paypal.com/paypalme/donate2mpl,' )
        local resp = retvals_csv:match('.-%,.-%,.-%,(.*)')
        if not resp then MB('No response entered','',0) return end
        local check_offset = VF_CheckResponseOffset(sysID,resp)
        if check_offset then  
          reaper.SetExtState('MPL_Scripts', 'response',resp, true)
          MB('SystemID - Response pair was successfully passed','MPL Various functions',0)
         else
          MB('Checksum mismatch. Contact m.pilyavskiy@gmail.com','MPL Various functions',0)
        end
      end]]
      
      local info = debug.getinfo(1,'S');  
      local purch_script_path = info.source:match([[^@?(.*[\/])[^\/]-$]] ) .. "mpl_Various_functions_PurchaseGUI.lua" 
      purch_script_pathID = VF_GetActionCommandIDByFilename('mpl_Various_functions_PurchaseGUI', 0)
      Action('_'..purch_script_pathID)
      
      --dofile(purch_script_path )
      --main = function() end -- clear main() functions
      
     else
      local sysID = VF_GetSystemID()
      local check_offset = VF_CheckResponseOffset(sysID,response)
      if check_offset then 
        VF_LoadVFv2_DecodeBinary(sysID,response)
       else
        MB('Checksum mismatch. Contact m.pilyavskiy@gmail.com','MPL Various functions',0)
      end
    end 
  end
  --------------------------------------------------
  VF_LoadLibraries()
  VF_LoadVFv1() 
  VF2_LoadVFv2()
  
