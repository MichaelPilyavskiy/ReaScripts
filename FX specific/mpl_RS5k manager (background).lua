-- @description RS5k manager
-- @version 1.92
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=207971
-- @about Script for handling ReaSamplomatic5000 data on selected track
-- @provides
--    mpl_RS5k_manager_functions/mpl_RS5k_manager_GUI.lua
--    mpl_RS5k_manager_functions/mpl_RS5k_manager_MOUSE.lua
--    mpl_RS5k_manager_functions/mpl_RS5k_manager_data.lua
--    mpl_RS5k_manager_functions/mpl_RS5k_manager_obj.lua
--    mpl_RS5k_manager_functions/mpl_RS5k_manager_pat.lua
-- @changelog
--    + Pattern: swing support (was dropped at MIDI code side before)
--    + Pattern: alt+click on knob reset swing
--    + Pattern: change take/pattern name
--    + Pattern: select patterns from list (require update pattern manually from previous versions, patterns are take-POOLGUID-based)
--    + Pattern: allow to apply pattern tools for selected key or for all keys in pattern
--    + Pattern: random gates
--    + Pattern: probability control for random gates
--    + Pattern: random velocities
--    + Pattern: limits control for random velocities
--    # Pattern: fixed potential issua when setting up steps
--    # Pattern: update take name immediately

  local vrs = 'v1.92'
  local scr_title = 'RS5K manager'
  --NOT gfx NOT reaper
  --rs5k manager_
 
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
   pat = {}    
   
    
  ---------------------------------------------------  
  
  function Main_RefreshExternalLibs()     -- lua example by Heda -- http://github.com/ReaTeam/ReaScripts-Templates/blob/master/Files/Require%20external%20files%20for%20the%20script.lua
    local info = debug.getinfo(1,'S');
    local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]]) 
    dofile(script_path .. "mpl_RS5k_manager_functions/mpl_RS5k_manager_GUI.lua")
    dofile(script_path .. "mpl_RS5k_manager_functions/mpl_RS5k_manager_MOUSE.lua")  
    dofile(script_path .. "mpl_RS5k_manager_functions/mpl_RS5k_manager_obj.lua")  
    dofile(script_path .. "mpl_RS5k_manager_functions/mpl_RS5k_manager_data.lua")  
    dofile(script_path .. "mpl_RS5k_manager_functions/mpl_RS5k_manager_pat.lua")
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
            show_wf = 1,
            
            -- GUI control
            mouse_wheel_res = 960,
            separate_spl_peak = 0,
            
            -- Samples
            allow_multiple_spls_per_pad = 0,
            
            
            -- Pads
            keymode = 0,  -- 0-keys
            keypreview = 1, -- send MIDI by clicking on keys
            oct_shift = -1, -- note names
            start_oct_shift = 2, -- scroll
            key_names2 = '#midipitch #keycsharp |#notename #samplecount |#samplename' ,
            key_names_mixer = '#midipitch #keycsharp |#notename ' ,
            key_names_pat = '#midipitch #keycsharp  #notename ',
            prepareMIDI3 = 0,
            FX_buttons = 255,
            allow_track_notes = 0,
            
            invert_release = 0,
            
            MM_reset_val = 1,
            --MM_dc_float = 0,
            
            pintrack = 0,
            dontaskforcreatingrouting = 0,
            obeynoteoff_default = 1,
            dragtonewtracks = 0,
            draggedfile_fxchain = '',
            --copy_src_media = 0,
            sendnoteoffonrelease = 1,
            
            -- patterns
            def_steps = 16,
            def_swing = 0,
            patctrl_mode = 0, -- 0 selected 1 all
            randgateprob = 0.5, -- probability
            randvel1=0,
            randvel2 = 1,
            
            
            }
    return t
  end  
  
  ---------------------------------------------------  
   -- Set ToolBar Button ON
  function SetButtonON()
    local is_new_value, filename, sec, cmd, mode, resolution, val = reaper.get_action_context()
    local state = reaper.GetToggleCommandStateEx( sec, cmd )
    reaper.SetToggleCommandState( sec, cmd, 1 ) -- Set ON
    reaper.RefreshToolbar2( sec, cmd )
    return state==0
  end
  ---------------------------------------------------  
  -- Set ToolBar Button OFF
  function SetButtonOFF()
    local is_new_value, filename, sec, cmd, mode, resolution, val = reaper.get_action_context()
    local state = reaper.GetToggleCommandStateEx( sec, cmd )
    reaper.SetToggleCommandState( sec, cmd, 0 ) -- Set OFF
    reaper.RefreshToolbar2( sec, cmd )
    gfx.quit()
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
    if refresh.GUI == true or refresh.GUI_onStart == true then OBJ_Update              (conf, obj, data, refresh, mouse, pat) end  
    GUI_draw (conf, obj, data, refresh, mouse)    
                                               
    local char =gfx.getchar()  
    ShortCuts(char)
    if char >= 0 and char ~= 27 then defer(run) else atexit(SetButtonOFF) end
  end
---------------------------------------------------------------------    
  function main()
    if VF_CheckReaperVrs(5.961) and gmem_attach then gmem_attach('RS5KManTrack') end
    
        local ret = SetButtonON()
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
        obj.allow_track_notes = VF_CheckReaperVrs and VF_CheckReaperVrs(5.961)
        run() 
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
      reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing. Use <Action list/Browse packages> to install it from ReaPack', '', 0)
    end  
  end
--------------------------------------------------------------------
  if CheckFunctions('VF_CheckReaperVrs') then main() end  
