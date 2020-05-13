-- @description TaskScheduler
-- @version 1.01
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @provides
--    mpl_TaskScheduler_functions/mpl_TaskScheduler_GUI.lua
--    mpl_TaskScheduler_functions/mpl_TaskScheduler_MOUSE.lua
--    mpl_TaskScheduler_functions/mpl_TaskScheduler_data.lua
--    mpl_TaskScheduler_functions/mpl_TaskScheduler_obj.lua
-- @changelog
--    + Add options for repeating events

  local vrs = 'v1.01'
  --NOT gfx NOT reaper
  

 --  INIT -------------------------------------------------
  local conf = {} 
  local run_GUI = true 
  local refresh = { GUI_onStart = true, 
                    GUI = false, 
                    GUI_minor = false,
                    data = false,
                    data_proj = false, 
                    conf = false}
  local mouse = {}
  local data = {list = {},
          action_table={},
          triggers = {}}
  local obj = {}
  ---------------------------------------------------  
  
  function Main_RefreshExternalLibs()     -- lua example by Heda -- http://github.com/ReaTeam/ReaScripts-Templates/blob/master/Files/Require%20external%20files%20for%20the%20script.lua
    local info = debug.getinfo(1,'S');
    local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]]) 
    if run_GUI then 
      dofile(script_path .. "mpl_TaskScheduler_functions/mpl_TaskScheduler_GUI.lua")
      dofile(script_path .. "mpl_TaskScheduler_functions/mpl_TaskScheduler_MOUSE.lua")  
      dofile(script_path .. "mpl_TaskScheduler_functions/mpl_TaskScheduler_obj.lua") 
    end
    dofile(script_path .. "mpl_TaskScheduler_functions/mpl_TaskScheduler_data.lua")  
  end  

  ---------------------------------------------------
  function ExtState_Def()  
    local t= {
            -- globals
            mb_title = 'TaskScheduler', 
            ES_key = 'MPL_TaskScheduler',
            wind_x =  50,
            wind_y =  50,
            wind_w =  1000,
            wind_h =  200,
            dock =    0,
            
            -- mouse
            mouse_wheel_res = 960,
            }
    return t
  end  
  ---------------------------------------------------  
  function GetActionTable(action_table)
    for i = 0, 200000 do
      local id, actname = reaper.CF_EnumerateActions( 0, i, '' )
      if not id or id < -1 then break end
      action_table[id] = actname
    end
  end
  ---------------------------------------------------    
  function run()
    obj.clock = os.clock()
    refresh.GUI = true
    
    DataUpdate(conf, obj, data, refresh, mouse)   
    if run_GUI then 
      MOUSE(conf, obj, data, refresh, mouse)
      CheckUpdates(obj, conf, refresh)
    end
    if refresh.data == true then DataUpdate2(conf, obj, data, refresh, mouse)  refresh.data = nil end  
    if refresh.conf == true and run_GUI then ExtState_Save(conf) refresh.conf = nil end
    if run_GUI and (refresh.GUI == true or refresh.GUI_onStart == true) then OBJ_Update (conf, obj, data, refresh, mouse) end
    if refresh.GUI_minor == true then refresh.GUI = true end
    if run_GUI then GUI_draw (conf, obj, data, refresh, mouse) end
                                               
 
    if run_GUI then 
      ShortCuts(conf, obj, data, refresh, mouse)
      if mouse.char >= 0 and mouse.char ~= 27 then defer(run) else atexit(gfx.quit) end
     else
      defer(run)
    end
  end
  ---------------------------------------------------------------------
  function RunInit(conf, obj, data, refresh, mouse)  
    
  end
---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
--------------------------------------------------------------------
  function main()
        conf.dev_mode = 0
        conf.vrs = vrs
        local info = debug.getinfo(1,'S');
        conf.script_path = info.source:match([[^@?(.*[\/])[^\/]-$]])
        conf.cur_tasklist = conf.script_path .. "mpl_TaskScheduler_currentlist.tlist" 
        GetActionTable(data.action_table)
        Main_RefreshExternalLibs()
        ExtState_Load(conf)
        if run_GUI then 
          gfx.init('MPL '..conf.mb_title..' '..conf.vrs,
                    conf.wind_w, 
                    conf.wind_h, 
                    conf.dock, conf.wind_x, conf.wind_y)
          OBJ_init(conf, obj, data, refresh, mouse)
          OBJ_Update(conf, obj, data, refresh, mouse) 
        end
        RunInit(conf, obj, data, refresh, mouse) 
        run()  
  end
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF_GetProjIDByPath') 
  if ret then
    local ret2 = VF_CheckReaperVrs(5.95,true)    
    if ret and ret2 then main() end
  end
