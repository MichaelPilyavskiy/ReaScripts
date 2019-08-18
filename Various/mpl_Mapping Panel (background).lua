-- @description MappingPanel
-- @version 2.04
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @about Script for link parameters across tracks
-- @provides
--    mpl_MappingPanel_functions/mpl_MappingPanel_GUI.lua
--    mpl_MappingPanel_functions/mpl_MappingPanel_MOUSE.lua
--    mpl_MappingPanel_functions/mpl_MappingPanel_data.lua
--    mpl_MappingPanel_functions/mpl_MappingPanel_obj.lua
-- @changelog
--    # fix undefined selected knob area error

  local vrs = 'v2.04'
  --NOT gfx NOT reaper
  
  --[[ map:
  
  Master
  [slider / gmem] 1-16: knob values
  [gmem] 100: value changed from script
  
  Slave
  [slider] 1-16 [float] knob values
  [slider] 17-32 [int] to which master knob linked
  [slider] 33-48 [int] &1 mute, then 8 bytes tension, then 16 bytes scale max
  [slider] 49-64 [int] 16 bytes lim min, then 16bytes lim max, then 16 bytes scale min  
  
  ]]
  
  
  --  INIT -------------------------------------------------
  local conf = {}  
  local refresh = { GUI_onStart = true, 
                    GUI = false, 
                    GUI_minor = false,
                    data = true,
                    data_proj = false, 
                    data_minor = false,
                    conf = false}
  local mouse = {}
  local data = {}
  local obj = {}
  
  local info = debug.getinfo(1,'S');  
  local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]]) 
  obj.script_path = script_path
  ---------------------------------------------------   
  function Main_RefreshExternalLibs()     -- lua example by Heda -- http://github.com/ReaTeam/ReaScripts-Templates/blob/master/Files/Require%20external%20files%20for%20the%20script.lua    
    dofile(script_path .. "mpl_MappingPanel_functions/mpl_MappingPanel_GUI.lua")
    dofile(script_path .. "mpl_MappingPanel_functions/mpl_MappingPanel_MOUSE.lua")  
    dofile(script_path .. "mpl_MappingPanel_functions/mpl_MappingPanel_obj.lua")  
    dofile(script_path .. "mpl_MappingPanel_functions/mpl_MappingPanel_data.lua")  
  end  
  ---------------------------------------------------
  function ExtState_Def()  
    local t= {
            -- globals
            mb_title = 'MappingPanel',
            ES_key = 'MPL_MappingPanel',
            wind_x =  50,
            wind_y =  50,
            wind_w =  520,
            wind_h =  250,
            dock =    0,
            
            -- mouse
            mouse_wheel_res = 960,
            activeknob = 0, 
            
            -- data
            slot_cnt = 16,
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
      Data_Update (conf, obj, data, refresh, mouse) 
      refresh.data = nil 
    end    
    if refresh.conf == true then 
      if conf.dock > 0 then conf.lastdockID = conf.dock end
      ExtState_Save(conf) 
      refresh.conf = nil 
    end
    
    if refresh.GUI == true or refresh.GUI_onStart == true then        OBJ_Update              (conf, obj, data, refresh, mouse) end  
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
        gfx.init('MPL '..conf.mb_title..' '..conf.vrs,
                    conf.wind_w, --780,--
                    conf.wind_h, --530,--
                    conf.dock, conf.wind_x, conf.wind_y)
        OBJ_init(conf, obj, data, refresh, mouse) 
        OBJ_Update(conf, obj, data, refresh, mouse,strategy) 
        run()  
  end
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF_GetTrackByGUID') 
  local ret2 = VF_CheckReaperVrs(5.97,true)    
  if ret and ret2 then 
    reaper.gmem_attach('MappingPanel' )
    main() 
  end
