-- @description InstrumentRack
-- @version 1.12
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=165672 
-- @about Script for showing instruments in currently opened REAPER project
-- @provides
--    mpl_InstrumentRack_functions/mpl_InstrumentRack_GUI.lua
--    mpl_InstrumentRack_functions/mpl_InstrumentRack_MOUSE.lua
--    mpl_InstrumentRack_functions/mpl_InstrumentRack_data.lua
--    mpl_InstrumentRack_functions/mpl_InstrumentRack_obj.lua
-- @changelog
--    + allow to hide RS5k instances

  local vrs = 'v1.12'
  --NOT gfx NOT reaper
  
  --  INIT -------------------------------------------------
  local conf = {}  
  local refresh = { GUI_onStart = true, 
                    GUI = false, 
                    GUI_minor = false,
                    data = false,
                    data_proj = false, 
                    conf = false}
  local mouse = {}
  local data = {}
  local data_ext = {}
  obj = {}
  
  local info = debug.getinfo(1,'S');  
  local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]]) 
  obj.script_path = script_path
  ---------------------------------------------------   
  function Main_RefreshExternalLibs()     -- lua example by Heda -- http://github.com/ReaTeam/ReaScripts-Templates/blob/master/Files/Require%20external%20files%20for%20the%20script.lua    
    dofile(script_path .. "mpl_InstrumentRack_functions/mpl_InstrumentRack_GUI.lua")
    dofile(script_path .. "mpl_InstrumentRack_functions/mpl_InstrumentRack_MOUSE.lua")  
    dofile(script_path .. "mpl_InstrumentRack_functions/mpl_InstrumentRack_obj.lua")  
    dofile(script_path .. "mpl_InstrumentRack_functions/mpl_InstrumentRack_data.lua")  
  end  

  ---------------------------------------------------
  function ExtState_Def()  
    local t= {
            -- globals
            mb_title = 'InstrumentRack',
            ES_key = 'MPL_InstrumentRack',
            wind_x =  50,
            wind_y =  50,
            wind_w =  500,
            wind_h =  400,
            dock =    0,
            
            -- mouse
            mouse_wheel_res = 960,
            
            -- options
            scrolltotrackonedit = 0, 
            floatchain = 0,
            allowonlyonectrl = 1,
            obeyyallcontrols = 0,
            hiders5k = 0,
            
            }
    return t
  end  
  --------------------------------------------------
  function ExtStateProj_Set(data_ext)
    local str = ''
    for GUID in pairs(data_ext) do
      local open = 0
      if data_ext[GUID].open == true then open = 1 end
      str = str..GUID..' '
            ..open..'\n'
    end
    SetProjExtState( 0, conf.ES_key, 'plug_state', str )
  end
  --------------------------------------------------
  function ExtStateProj_Get(data_ext)
    local retval, str = GetProjExtState( 0, conf.ES_key, 'plug_state' )
    for line in str:gmatch('[^\r\n]+') do
      local t = {}
      for val in line:gmatch('[^%s]+') do t[#t+1] = val end
      local GUID = t[1]
      local open = 0 
      if t[2] then open = tonumber(t[2]) end
      data_ext[GUID] = {open= open==1}
      
    end    
  end
  ---------------------------------------------------    
  function run()
    obj.clock = os.clock()
    
    MOUSE(conf, obj, data, refresh, mouse)
    CheckUpdates(obj, conf, refresh)
    
    if refresh.data_ext == true then 
      ExtStateProj_Set(data_ext)
      refresh.data_ext = nil 
    end
    
    if refresh.data == true then 
      data = {}
      ExtStateProj_Get(data_ext)
      Data_Update (conf, obj, data, refresh, mouse, data_ext)       
      refresh.data = nil 
    end  
    
    Data_Update2(conf, obj, data, refresh, mouse)
    
    if refresh.conf == true then 
      ExtState_Save(conf)
      refresh.conf = nil 
    end

    if refresh.GUI == true or refresh.GUI_onStart == true then    OBJ_Update   (conf, obj, data, refresh, mouse,data_ext) end  
    if refresh.GUI_minor == true then refresh.GUI = true end
    GUI_draw               (conf, obj, data, refresh, mouse, strategy)    
                                               
 
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
        obj.plugs_data = Data_EnumeratePlugins(conf, obj, data, refresh, mouse)
          gfx.init('MPL '..conf.mb_title..' '..conf.vrs,
                    conf.wind_w, 
                    conf.wind_h, 
                    conf.dock, conf.wind_x, conf.wind_y)
          OBJ_init(obj)
          OBJ_Update(conf, obj, data, refresh, mouse, data_ext)
          run()  
  end
--------------------------------------------------------------------  
  local ret = CheckFunctions('VF_GetFXByGUID') 
  local ret2 = VF_CheckReaperVrs(5.95,true)    
  if ret and ret2 then main() end
