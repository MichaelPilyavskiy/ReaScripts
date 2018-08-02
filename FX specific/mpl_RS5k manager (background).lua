-- @description RS5k manager
-- @version 1.71
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=207971
-- @about Script for handling ReaSamplomatic data on selected track
-- @provides
--    mpl_RS5k_manager_functions/mpl_RS5k_manager_GUI.lua
--    mpl_RS5k_manager_functions/mpl_RS5k_manager_MOUSE.lua
--    mpl_RS5k_manager_functions/mpl_RS5k_manager_data.lua
--    mpl_RS5k_manager_functions/mpl_RS5k_manager_obj.lua
--    mpl_RS5k_manager_control/mpl_RS5k_manager_control_functions.lua
-- @changelog
--    + draw action type when draggin pad
--    + add 'Pad/Show linked FX chain'
--    # fix 'Pad/Float linked FX'


  local vrs = 'v1.71'
  local scr_title = 'RS5K manager'
  --NOT gfx NOT reaper
 
  
  --  INIT -------------------------------------------------
  for key in pairs(reaper) do _G[key]=reaper[key]  end  
  local conf = {}  
  local refresh = { GUI_onStart = true, 
                    GUI = false, 
                    data = false,
                    GUI_WF = false,
                    conf = false}
   mouse = {}
  local obj = {}
  local data = {}
        
  ---------------------------------------------------  
  
  function Main_RefreshExternalLibs()     -- lua example by Heda -- http://github.com/ReaTeam/ReaScripts-Templates/blob/master/Files/Require%20external%20files%20for%20the%20script.lua
    local info = debug.getinfo(1,'S');
    local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]]) 
    dofile(script_path .. "mpl_RS5k_manager_functions/mpl_RS5k_manager_GUI.lua")
    dofile(script_path .. "mpl_RS5k_manager_functions/mpl_RS5k_manager_MOUSE.lua")  
    dofile(script_path .. "mpl_RS5k_manager_functions/mpl_RS5k_manager_obj.lua")  
    dofile(script_path .. "mpl_RS5k_manager_functions/mpl_RS5k_manager_data.lua")  
  end  

  ---------------------------------------------------
  function ExtState_Def()
    local GUI_fontsz2 = 15
    local GUI_fontsz3 = 13
    if GetOS():find("OSX") then 
      GUI_fontsz2 = GUI_fontsz2 - 5 
      GUI_fontsz3 = GUI_fontsz3 - 4
    end    
    local t= {
            -- globals
            mb_title = 'RS5K manager',
            ES_key = 'MPL_RS5K manager',
            wind_x =  50,
            wind_y =  50,
            wind_w =  600,
            wind_h =  200,
            dock =    0,
            dock2 =    0, -- set manually docked state
            
            -- GUI
            tab = 0,  -- 0-sample browser
            GUI_padfontsz = GUI_fontsz2,
            GUI_splfontsz = GUI_fontsz3,
            GUI_ctrlscale = 1,
            
            -- GUI control
            mouse_wheel_res = 960,
            
            -- Samples
            allow_multiple_spls_per_pad = 0,
            
            
            -- Pads
            keymode = 0,  -- 0-keys
            keypreview = 1, -- send MIDI by clicking on keys
            oct_shift = -1, -- note names
            start_oct_shift = 0, -- scroll
            key_names2 = '#midipitch #keycsharp |#notename #samplecount |#samplename' ,
            key_names_mixer = '#midipitch #keycsharp |#notename ' ,
            --key_names = 8, --8 return MIDInotes and keynames
            --displayMIDInotenames = 1,
            prepareMIDI2 = 0, -- prepare MIDI on start
            FX_buttons = 255,
            
            invert_release = 0,
            
            MM_reset_val = 1,
            --MM_dc_float = 0,
            
            pintrack = 0,
            dontaskforcreatingrouting = 0,
            obeynoteoff_default = 1,
            dragtonewtracks = 0,
            draggedfile_fxchain = '',
            }
    return t
  end  
  
  ---------------------------------------------------    
  function run()
    obj.clock = os.clock()
    
    MOUSE(conf, obj, data, refresh, mouse)
    CheckUpdates(obj, conf, refresh)
    
    if refresh.data == true then 
      data = {}
      Data_Update (conf, obj, data, refresh, mouse) 
      refresh.data = nil 
    end    
    if refresh.conf == true                       then ExtState_Save(conf)                                            refresh.conf = nil end
    if refresh.GUI == true or refresh.GUI_onStart == true then OBJ_Update              (conf, obj, data, refresh, mouse) end  
                                                GUI_draw               (conf, obj, data, refresh, mouse)    
                                               
    local char =gfx.getchar()  
    ShortCuts(char)
    if char >= 0 and char ~= 27 then defer(run) else atexit(gfx.quit) end
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
        Main_RefreshExternalLibs()
        ExtState_Load(conf)  
        gfx.init('MPL RS5k manager '..vrs,
                  conf.wind_w, 
                  conf.wind_h, 
                  conf.dock2, conf.wind_x, conf.wind_y)
        OBJ_init(obj)
        OBJ_Update(conf, obj, data, refresh, mouse, pat) 
        conf.dev_mode = 0
        conf.scr_title = scr_title
        conf.vrs = vrs
        MIDI_prepare(data, conf)
        run()
      end
      
     else
      MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0)
    end  
  end
--------------------------------------------------------------------
  CheckFunctions('GetInput')     
