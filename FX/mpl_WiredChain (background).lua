-- @description WiredChain
-- @version 1.12
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @about Script for handling FX chain data on selected track
-- @provides
--    mpl_WiredChain_functions/mpl_WiredChain_GUI.lua
--    mpl_WiredChain_functions/mpl_WiredChain_MOUSE.lua
--    mpl_WiredChain_functions/mpl_WiredChain_data.lua
--    mpl_WiredChain_functions/mpl_WiredChain_obj.lua
-- @changelog
--    + Add/Replace FX: support for VST64, AU32/64, DX32/64, JSFX
--    + Add/Replace FX: set XY position to mouse position (scroll compensated) for newly added FX

  local vrs = 'v1.12'
  --NOT gfx NOT reaper
  
  
  
  --  INIT -------------------------------------------------
  for key in pairs(reaper) do _G[key]=reaper[key]  end  
  local conf = {}  
  local refresh = { GUI_onStart = true, 
                    GUI = false, 
                    GUI_minor = false,
                    data = false,
                    data_proj = false,
                    conf = false}
  local mouse = {}
  local data = {}
  local  obj = {
            plugs_data = {},
            textbox = {
                      --enable = true,
                        },
            
          }
  
  ---------------------------------------------------  
  
  function Main_RefreshExternalLibs()     -- lua example by Heda -- http://github.com/ReaTeam/ReaScripts-Templates/blob/master/Files/Require%20external%20files%20for%20the%20script.lua
    local info = debug.getinfo(1,'S');
    local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]]) 
    dofile(script_path .. "mpl_WiredChain_functions/mpl_WiredChain_GUI.lua")
    dofile(script_path .. "mpl_WiredChain_functions/mpl_WiredChain_MOUSE.lua")  
    dofile(script_path .. "mpl_WiredChain_functions/mpl_WiredChain_obj.lua")  
    dofile(script_path .. "mpl_WiredChain_functions/mpl_WiredChain_data.lua")  
  end  

  ---------------------------------------------------
  function ExtState_Def()  
    local t= {
            -- globals
            mb_title = 'WiredChain',
            ES_key = 'MPL_WiredChain',
            wind_x =  50,
            wind_y =  50,
            wind_w =  600,
            wind_h =  200,
            dock =    0,
            dock2 =    0, -- set manually docked state
            
            -- mouse
            mouse_wheel_res = 960,
            
            -- data
            autoroutestereo = 0,
            reducetrackouts = 0,
            
            -- GUI
            snapFX = 1,
            snap_px = 10, -- snap FX when drag
            struct_xshift = 0,
            struct_yshift = 0,
            
            }
    return t
  end  
  --[[local GUI_fontsz2 = 15
  local GUI_fontsz3 = 13
  if GetOS():find("OSX") then 
    GUI_fontsz2 = GUI_fontsz2 - 5 
    GUI_fontsz3 = GUI_fontsz3 - 4
  end ]] 
  
  
  ---------------------------------------------------    
  function run()
    obj.clock = os.clock()
    
    MOUSE(conf, obj, data, refresh, mouse)
    CheckUpdates(obj, conf, refresh)
    
    if refresh.data == true then 
      data = {}
      Data_Update (conf, obj, data, refresh, mouse) 
      Data_Update_ExtState_ProjData_Load (conf, obj, data, refresh, mouse)
      refresh.data = nil 
    end    
    if refresh.conf == true then 
      Data_Update_ExtState_ProjData_Save (conf, obj, data, refresh, mouse)
      ExtState_Save(conf)
      refresh.conf = nil end
    --if refresh.data_proj == true then Data_Update_ExtState_ProjData_Load (conf, obj, data, refresh, mouse) refresh.data_proj = nil end
    if refresh.GUI == true or refresh.GUI_onStart == true then OBJ_Update              (conf, obj, data, refresh, mouse) end  
    if refresh.GUI_minor == true then refresh.GUI = true end
    GUI_draw               (conf, obj, data, refresh, mouse)    
                                               
 
    ShortCuts(conf, obj, data, refresh, mouse)
    if mouse.char >= 0 and mouse.char ~= 27 
      then defer(run) else atexit(gfx.quit) end
  end
    

  
  
---------------------------------------------------------------------
  function CheckFunctions(str_func)
    local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'
    local f = io.open(SEfunc_path, 'r')
    if f then
      f:close()
      dofile(SEfunc_path)
      
      if not _G[str_func] then 
        reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0)
       else
        return true
      end
      
     else
      reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0)
    end  
  end
  ---------------------------------------------------
  function CheckReaperVrs(rvrs) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0)
      return
     else
      return true
    end
  end
--------------------------------------------------------------------
  function main()
        conf.dev_mode = 0
        conf.vrs = vrs
        Main_RefreshExternalLibs()
        ExtState_Load(conf)  
        gfx.init('MPL '..conf.mb_title..' '..conf.vrs,
                  conf.wind_w, 
                  conf.wind_h, 
                  conf.dock2, conf.wind_x, conf.wind_y)
        OBJ_init(obj)
        OBJ_Update(conf, obj, data, refresh, mouse) 
        run()  
  end
--------------------------------------------------------------------  
  local ret = CheckFunctions('MPL_ReduceFXname') 
  local ret2 = CheckReaperVrs(5.95)    
  if ret and ret2 then main() end
