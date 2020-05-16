-- @description PitchEditor
-- @version 1.13
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=222825
-- @about Script for editing take pitch envelope
-- @provides
--    mpl_PitchEditor_functions/mpl_PitchEditor_GUI.lua
--    mpl_PitchEditor_functions/mpl_PitchEditor_MOUSE.lua
--    mpl_PitchEditor_functions/mpl_PitchEditor_data.lua
--    mpl_PitchEditor_functions/mpl_PitchEditor_obj.lua
--    [main] mpl_PitchEditor_functions/mpl_PitchEditor_analyzer.eel
-- @changelog
--    # GUI: fix line#384 error

  local vrs = 'v1.13'
  --NOT gfx NOT reaper
  
  
  
  --  INIT -------------------------------------------------
  local conf = {}  
  local refresh = { GUI_onStart = true, 
                    GUI = false, 
                    GUI_minor = false,
                    data = true,
                    data_proj = false, 
                    data_minor = false,
                    conf = false}
  local mouse = {context_latch = ''}
  local data = { 
            has_data = false,
                }
  local obj = {current_page = 0,
               edit_mode = 0}
  
  local info = debug.getinfo(1,'S');  
  local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]]) 
  obj.script_path = script_path
  ---------------------------------------------------  
  function GetExternalEELID()
    local kbini = reaper.GetResourcePath()..'/reaper-kb.ini'--/Scripts/MPL Scripts/Various/mpl_PitchEditor_functions/mpl_PitchEditor_analyzer.eel'
    local f = io.open(kbini, 'r')
    local cont = f:read('a')
    if not f then return else  f:close() end
    local name_str
    for line in cont:gmatch('[^\r\n]+') do
      if line:match('PitchEditor_analyzer') then name_str = line:match('SCR %d+ %d+ ([%a%_%d]+)') break end
    end
    local command_id =  reaper.NamedCommandLookup( '_'..name_str )
    --msg(CF_GetCommandText( 0, command_id ))
    if command_id ~= 0 then return true, command_id end
  end
  ---------------------------------------------------   
  function Main_RefreshExternalLibs()     -- lua example by Heda -- http://github.com/ReaTeam/ReaScripts-Templates/blob/master/Files/Require%20external%20files%20for%20the%20script.lua    
    dofile(script_path .. "mpl_PitchEditor_functions/mpl_PitchEditor_GUI.lua")
    dofile(script_path .. "mpl_PitchEditor_functions/mpl_PitchEditor_MOUSE.lua")  
    dofile(script_path .. "mpl_PitchEditor_functions/mpl_PitchEditor_obj.lua")  
    dofile(script_path .. "mpl_PitchEditor_functions/mpl_PitchEditor_data.lua")  
  end  
  ---------------------------------------------------
  function ExtState_Def()  
    local t= {
            -- globals
            mb_title = 'PitchEditor',
            ES_key = 'MPL_PitchEditor',
            wind_x =  50,
            wind_y =  50,
            wind_w =  520,
            wind_h =  250,
            dock =    0,
            
            GUI_zoom = 1,
            GUI_scroll = 0,
            GUI_zoomY = 1,
            GUI_scrollY = 0,
                        
            -- GUI
            key_names = 0,
            minzoomY = 0.1,
            
            -- mouse
            mouse_wheel_res = 960,
            activeknob = 0, 
            
                        
            -- YIN pitch detection algorithm
              max_len = 300,
              window_step = 0.04;
              minF = 80;
              maxF = 800;
              YINthresh = 0.2, --D. Step 4: Absolute threshold
              overlap = 2,
              lowRMSlimit_dB = -60; 
              
            -- post
              post_note_diff  = 2, -- MIDI Pitch diff
              RMS_diff_linear = .05, -- RMS linear difference
              noteoff_offsetblock = 0,
              min_block_len = 3, -- in windows
              
            }
    return t
  end  
  
  ---------------------------------------------------    
  function run()
    obj.clock = os.clock()
    
    MOUSE(conf, obj, data, refresh, mouse)
    CheckUpdates(obj, conf, refresh)
    
    if refresh.data_minor == true then refresh.data = true end
    if refresh.data == true then 
      --data = {}
      data.extpitch_refresh  = true
      Data_Update (conf, obj, data, refresh, mouse) 
      refresh.data = nil 
      refresh.data_minor = nil
    end    
    if refresh.conf == true then 
      if conf.dock > 0 then conf.lastdockID = conf.dock end
      ExtState_Save(conf) 
      refresh.conf = nil 
    end
    
    if refresh.GUI == true or refresh.GUI_onStart == true then           OBJ_Update              (conf, obj, data, refresh, mouse) end  
    if refresh.GUI_minor == true then refresh.GUI = true end
    GUI_draw               (conf, obj, data, refresh, mouse)                            
 
    ShortCuts(conf, obj, data, refresh, mouse)
    if mouse.char >= 0 and mouse.char ~= 27 then defer(run) else atexit(gfx.quit) end
  end
    
  
  
---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end

--------------------------------------------------------------------
  function main()
        conf.dev_mode = 0
        conf.vrs = vrs
        
        
        Main_RefreshExternalLibs()
        ExtState_Load(conf)
        
        local ret, command_id = GetExternalEELID()
        if ret and command_id and command_id ~= 0 then
          conf.ExternalID = command_id
         else
          MB('EEL library not found', conf.mb_title, 0)
          return 
        end
        
        gfx.init('MPL '..conf.mb_title..' '..conf.vrs,
                    conf.wind_w,
                    conf.wind_h,
                    conf.dock, conf.wind_x, conf.wind_y)
        OBJ_init(conf, obj, data, refresh, mouse) 
        OBJ_Update(conf, obj, data, refresh, mouse,strategy) 
        run()  
  end
  
  
  
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF_GetTrackByGUID') 
  local ret2 = VF_CheckReaperVrs(5.97,true)    
  if ret and ret2 then 
    reaper.gmem_attach('PitchEditor' )
    main()
  end
