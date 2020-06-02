-- @description RegionManager
-- @version 1.01
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @provides
--    mpl_RegionManager_functions/mpl_RegionManager_GUI.lua
--    mpl_RegionManager_functions/mpl_RegionManager_MOUSE.lua
--    mpl_RegionManager_functions/mpl_RegionManager_data.lua
--    mpl_RegionManager_functions/mpl_RegionManager_obj.lua
-- @changelog
--    + Sort by ID
--    + Sort by name
--    + Allow to disable dynamic GUI refresh


  local vrs = 'v1.01'
  
  --NOT gfx NOT reaper
  
  
  
 --  INIT -------------------------------------------------
  local conf = {}  
  local refresh = { GUI_onStart = true, 
                    GUI = false,  
                    GUI_minor = true,
                    data = true,
                    data_proj = false, 
                    conf = false}
  local mouse = {}
  local data = {regions={}}
  local obj = { selection = {},
                realcnt = 0,
                search_field_txt = '',
                mapping = {}}
  ---------------------------------------------------  
  
  function Main_RefreshExternalLibs()     -- lua example by Heda -- http://github.com/ReaTeam/ReaScripts-Templates/blob/master/Files/Require%20external%20files%20for%20the%20script.lua
    local info = debug.getinfo(1,'S');
    local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]]) 
    local scr_name = 'RegionManager'
    dofile(script_path .. "mpl_"..scr_name.."_functions/mpl_"..scr_name.."_GUI.lua")
    dofile(script_path .. "mpl_"..scr_name.."_functions/mpl_"..scr_name.."_MOUSE.lua")  
    dofile(script_path .. "mpl_"..scr_name.."_functions/mpl_"..scr_name.."_obj.lua")  
    dofile(script_path .. "mpl_"..scr_name.."_functions/mpl_"..scr_name.."_data.lua")  
  end  
  ---------------------------------------------------
  function ExtState_Def()  
    local t= {
            -- globals
            mb_title = 'RegionManager', 
            ES_key = 'MPL_RegionManager',
            wind_x =  50,
            wind_y =  50,
            wind_w =  600,
            wind_h =  200,
            dock =    0,
            
            showflag = 1, -- &1 reg &2 mark
            show_proj_ids = 0,
            sort_row = 0,
            sort_rowflag = 0,
            dyn_refresh = 1,
            
            -- mouse
            mouse_wheel_res = 960,
            }
    return t
  end  
  
  
  ---------------------------------------------------    
  function run()
    obj.clock = os.clock()
    
    MOUSE(conf, obj, data, refresh, mouse)
    CheckUpdates(obj, conf, refresh)
    if refresh.data == true then 
      Data_Update(conf, obj, data, refresh, mouse)
      refresh.data = nil 
    end  
    Data_Update2(conf, obj, data, refresh, mouse)
    if refresh.conf == true then 
      ExtState_Save(conf)
      refresh.conf = nil end
    if refresh.GUI == true or refresh.GUI_onStart == true then   
      OBJ_Update (conf, obj, data, refresh, mouse) 
    end  
    --if refresh.GUI_minor == true then refresh.GUI = true end
    GUI_draw (conf, obj, data, refresh, mouse)    
                                               
 
    ShortCuts(conf, obj, data, refresh, mouse)
    if mouse.char >= 0 and mouse.char ~= 27 
      then defer(run) else atexit(gfx.quit) end
  end
---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
--------------------------------------------------------------------
  function main()
        conf.dev_mode = 0
        conf.vrs = vrs
        Main_RefreshExternalLibs()
        ExtState_Load(conf) 
        gfx.init('MPL '..conf.mb_title..' '..conf.vrs,
                    conf.wind_w, 
                    conf.wind_h, 
                    conf.dock, conf.wind_x, conf.wind_y)
        OBJ_init(conf, obj, data, refresh, mouse)
        OBJ_Update(conf, obj, data, refresh, mouse) 
        run()  
  end
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  if ret then
    local ret2 = VF_CheckReaperVrs(5.95,true)    
    if ret and ret2 then main() end
  end
