-- @description RS5k manager
-- @version 1.50
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @provides
--    mpl_RS5k_manager_functions/mpl_RS5k_manager_trackfunc.lua
--    mpl_RS5k_manager_functions/mpl_RS5k_manager_GUI.lua
--    mpl_RS5k_manager_functions/mpl_RS5k_manager_MOUSE.lua
--    mpl_RS5k_manager_functions/mpl_RS5k_manager_PAT.lua
--    mpl_RS5k_manager_functions/mpl_RS5k_manager_data.lua
--    mpl_RS5k_manager_functions/mpl_RS5k_manager_obj.lua
-- @changelog
--    # Cleaning most code, split functions. Because it is serious code change, some functions and parts of GUI was removed to make the whole structure stable. Feel free to post issues into common thread at http://forum.cockos.com/showthread.php?t=188335
--    # Basic functions used from MPL Scripts/Funcions/Various functions. This is a must have file for further MPL scripts updates.
--    - (structure change) Additional global modes removed, script now working only with one selected track contains RS5k instances
--    + (structure change) allows you to have multiple parent tracks depending on parent selection
--    + (structure change) provides clean project structure (no need additional tracks by default + MIDI track for input)
--    + (structure change) Load note names from parent track. So script config not linket to project state external data. That means you can save track template with you drum maps and use it with other project. [p=1993149]
--    + (structure change) Allow to split sample for further use with custom FX chain using MIDI send 
--    - Patterns part removed. It will probably return as a separate script for maintain similar MIDI takes (aka patterns) along whole project.
--    - Options window removed, all options moved to menu
--    + Drandrop samples from MediaExplorer (REAPER 5.91pre1+), Sample Browser removed
--    + Send CC123 on mouse release instead loop all notes all channels
--    + Allow to auto prepare MIDI input from VirtualKeyboard or from all channels, disabled by default
--    + GUI octave shift splitted from Note names return value [p=1992718] [p=1993149]
--    + GUI: display section of sample on waveform, changing loop start keep item length
--    + GUI: improvements for fitting pad names and buttons
--    + GUI: highlight FX buttons if there a external FX chain for this note (aka MIDI send)
--    + GUI: muting pads [p=1993149]
--    + GUI: solo pad (simply mutes other, note - it doesn`t store mute state) [p=1993149]
--    + GUI: option to toggle per-pad controls
--    + GUI: waveform color follow parent/send track color
--    + Action: Export selected items to RS5k instances without glue each piece, source offset is take from items offset and length
--    # Prevent building peaks and check for proper file to add when dropped on pads [p=1998367]
  
  
  local vrs = 'v1.50'
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
  local mouse = {}
  local obj = {}
  local data = {}
        
  ---------------------------------------------------  
  
  function Main_RefreshExternalLibs()     -- lua example by Heda -- http://github.com/ReaTeam/ReaScripts-Templates/blob/master/Files/Require%20external%20files%20for%20the%20script.lua
    local info = debug.getinfo(1,'S');
    local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]]) 
    dofile(script_path .. "mpl_RS5k_manager_functions/mpl_RS5k_manager_trackfunc.lua")
    dofile(script_path .. "mpl_RS5k_manager_functions/mpl_RS5k_manager_GUI.lua")
    dofile(script_path .. "mpl_RS5k_manager_functions/mpl_RS5k_manager_MOUSE.lua")
    dofile(script_path .. "mpl_RS5k_manager_functions/mpl_RS5k_manager_PAT.lua")    
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
            
            }
    return t
  end  
  
  ---------------------------------------------------    
  function run()
    obj.clock = os.clock()
    
    MOUSE(conf, obj, data, refresh, mouse, pat)
    CheckUpdates(obj, conf, refresh)
    
    if refresh.data == true then 
      data = {}
      Data_Update (conf, obj, data, refresh, mouse, pat) 
      refresh.data = nil 
    end    
    if refresh.conf == true                       then ExtState_Save(conf)                                            refresh.conf = nil end
    if refresh.GUI == true or refresh.GUI_onStart == true then OBJ_Update              (conf, obj, data, refresh, mouse, pat) end  
                                                GUI_draw               (conf, obj, data, refresh, mouse, pat)    
                                               
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
        MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0)
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
