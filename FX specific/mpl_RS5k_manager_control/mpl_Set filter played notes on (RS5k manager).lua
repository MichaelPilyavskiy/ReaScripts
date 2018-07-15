-- @description Set filter played notes on (RS5k manager)
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=207971
-- @provides
--    mpl_RS5k_manager_control_functions.lua
-- @changelog
--    + init


  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  
  local info = debug.getinfo(1,'S');
  script_path = info.source:match([[^@?(.*[\/])[^\/]-$]]):match('(.*)\\')
  dofile(script_path .. "/mpl_RS5k_manager_control_functions.lua")  
  ----------------------------  
  function main()
    val = 1
    param = 21    
    SetGlobalParam(val, param)
  end
  ----------------------------
  defer(main)