-- @description RS5k manager
-- @version 1.60
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @about Script for handling ReaSamplomatic data on selected track
-- @provides
--    mpl_RS5k_manager_functions/mpl_RS5k_manager_GUI.lua
--    mpl_RS5k_manager_functions/mpl_RS5k_manager_MOUSE.lua
--    mpl_RS5k_manager_functions/mpl_RS5k_manager_data.lua
--    mpl_RS5k_manager_functions/mpl_RS5k_manager_obj.lua
-- @changelog
--    + Drag pad move content to other note
--    + Ctrl+drag pad duplicate content to other note [p=2003020]
--    + Rename MIDI note name [p=2003111] [p=2002672]
--    + Remove pad content [p=2002680]
--    + Remove pad layers [p=2002680]
--    + Options: don`t display MIDI note names
--    + Options: invert mouse for release knob [p=2003074]
--    + Options: allow manually prepare parent track rather than automatically on script start
--    + Controls: obey noteoff [p=2003004] [p=2002672]
--    + Link to REAPER blog video on YouTube
--    + MouseModifiers: doubleclick or alt+click to reset value [p=2003074]
--    + MouseModifiers: doubleclick float related rs5k instances [p=2002672]
--    # Mixer View: indentation improvements
--    # Mixer View: fix pan knob doesnt respond if all pans are centered
--    # fix pad color match track color in OSX
--    # fix error click on empty draganddrop space
--    # fix reset obey note-offs [p=2002672] 
--    # remove debug message shown at export selected items action

  local vrs = 'v1.60'
  local scr_title = 'RS5K manager'
  --NOT gfx NOT reaper
  
  -- todo
  -- MIDI controlled globals [p=1993032]
  -- moving back rs5k instance to main track
  -- link to one project track
  -- dalay ctrl [p=2002275]
   -- color/theme options [p=2003074]
   -- listing samples
  
  --  INIT -------------------------------------------------
  for key in pairs(reaper) do _G[key]=reaper[key]  end  
  local conf = {}  
  local refresh = { GUI_onStart = true, 
                    GUI = false, 
                    data = false,
                    GUI_WF = false,
                    conf = false}
  local mouse = {}
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
            
            -- GUI control
            mouse_wheel_res = 960,
            
            -- Samples
            allow_multiple_spls_per_pad = 0,
            
            
            -- Pads
            keymode = 0,  -- 0-keys
            keypreview = 1, -- send MIDI by clicking on keys
            oct_shift = -1, -- note names
            start_oct_shift = 0, -- scroll
            key_names = 8, --8 return MIDInotes and keynames
            prepareMIDI2 = 0, -- prepare MIDI on start
            FX_buttons = 255,
            
            displayMIDInotenames = 1,
            invert_release = 0,
            
            MM_reset_val = 1,
            MM_dc_float = 0,
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
