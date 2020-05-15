-- @description LearnEditor
-- @version 1.02
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @about Script for handling FX parameter bindings data
-- @provides
--    mpl_LearnEditor_functions/mpl_LearnEditor_GUI.lua
--    mpl_LearnEditor_functions/mpl_LearnEditor_MOUSE.lua
--    mpl_LearnEditor_functions/mpl_LearnEditor_data.lua
--    mpl_LearnEditor_functions/mpl_LearnEditor_obj.lua
-- @changelog
--    + Allow to edit MIDI Channel/StatusByte/2ndByte or OSC string
--    # do not initiate project reading twice on start
--    # fix read CC higher than 0x0F

  local vrs = 'v1.02'
  
  --NOT gfx NOT reaper
  --Delete all MIDI OSC learn from focused FX
  --Delete all MIDI OSC learn from selected track
  --List all MIDI OSC learn for current project
  --List all MIDI OSC learn for focused FX
  

 --  INIT -------------------------------------------------
  local conf = {}  
  local refresh = { GUI_onStart = true, 
                    GUI = false, 
                    GUI_minor = false,
                    data = true,
                    data_proj = false, 
                    conf = false}
  local mouse = {}
  data = {}
  local obj = {}
  ---------------------------------------------------  
  
  function Main_RefreshExternalLibs()     -- lua example by Heda -- http://github.com/ReaTeam/ReaScripts-Templates/blob/master/Files/Require%20external%20files%20for%20the%20script.lua
    local info = debug.getinfo(1,'S');
    local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]]) 
    dofile(script_path .. "mpl_LearnEditor_functions/mpl_LearnEditor_GUI.lua")
    dofile(script_path .. "mpl_LearnEditor_functions/mpl_LearnEditor_MOUSE.lua")  
    dofile(script_path .. "mpl_LearnEditor_functions/mpl_LearnEditor_obj.lua")  
    dofile(script_path .. "mpl_LearnEditor_functions/mpl_LearnEditor_data.lua")  
  end  
  ---------------------------------------------------
  function ExtState_Def()  
    local t= {
            -- globals
            mb_title = 'LearnEditor', 
            ES_key = 'MPL_LearnEditor',
            wind_x =  50,
            wind_y =  50,
            wind_w =  600,
            wind_h =  200,
            dock =    0,
            
            -- mouse
            mouse_wheel_res = 960,
            showflag = 1,
                      --[[&1 learn
                        &2 param mod
                      ]]
            }
    return t
  end  
  
  
  ---------------------------------------------------    
  function run()
    obj.clock = os.clock()
    
    MOUSE(conf, obj, data, refresh, mouse)
    CheckUpdates(obj, conf, refresh)
    if refresh.data == true then 
      refresh.data = nil 
      DataReadProject(conf, obj, data, refresh, mouse) 
    end  
    if refresh.conf == true then 
      ExtState_Save(conf)
      refresh.conf = nil end
    if refresh.GUI == true or refresh.GUI_onStart == true then   
      Data_HandleTouchedObjects(conf, obj, data, refresh, mouse) 
      OBJ_Update (conf, obj, data, refresh, mouse) 
    end  
    if refresh.GUI_minor == true then refresh.GUI = true end
    GUI_draw (conf, obj, data, refresh, mouse)    
                                               
 
    ShortCuts(conf, obj, data, refresh, mouse)
    if mouse.char >= 0 and mouse.char ~= 27 
      then defer(run) else atexit(gfx.quit) end
  end
  ---------------------------------------------------------------------
  function RunInit(conf, obj, data, refresh, mouse) 
    --DataReadProject(conf, obj, data, refresh, mouse) 
    Data_HandleTouchedObjects(conf, obj, data, refresh, mouse, true) 
  end
---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
--------------------------------------------------------------------
  function main()
        conf.dev_mode = 0
        conf.vrs = vrs
        Main_RefreshExternalLibs()
        ExtState_Load(conf)
        --conf.tableentries = 15
        RunInit(conf, obj, data, refresh, mouse) 
        gfx.init('MPL '..conf.mb_title..' '..conf.vrs,
                    conf.wind_w, 
                    conf.wind_h, 
                    conf.dock, conf.wind_x, conf.wind_y)
        OBJ_init(conf, obj, data, refresh, mouse)
        OBJ_Update(conf, obj, data, refresh, mouse) 
        run()  
  end
  -------------------------------------------------------------------- 
  function DataReadProject_GetVariables(line, param, id)
    local paramline = line:match(param..' (.-)\n')
    if not paramline then return end
    local t = {}
    for val in paramline:gmatch('[^%s]+') do t[#t+1] = val end
    if t[id] then 
      if tonumber(t[id]) then t[id] = tonumber(t[id]) 
       elseif 
        t[id]:match('%:') then t[id] =  t[id]:match('%d+') 
      end
      return t[id] 
    end
  end
  -------------------------------------------------------------------- 
  function DataReadProject_GetMod(line)
    local t = {typelink = 2, chunk = line}
    t.PARAMBASE = DataReadProject_GetVariables(line, 'PARAMBASE', 1)
    t.LFO = DataReadProject_GetVariables(line, 'LFO', 1)
    t.LFOWT1 = DataReadProject_GetVariables(line, 'LFOWT', 1)
    t.LFOWT2 = DataReadProject_GetVariables(line, 'LFOWT', 2)
    t.AUDIOCTL = DataReadProject_GetVariables(line, 'AUDIOCTL', 1)
    t.AUDIOCTLWT1 = DataReadProject_GetVariables(line, 'AUDIOCTLWT', 1)
    t.AUDIOCTLWT2 = DataReadProject_GetVariables(line, 'AUDIOCTLWT', 2)
    t.AUDIOCTLWT3 = DataReadProject_GetVariables(line, 'AUDIOCTLWT', 3)
    t.LFOSHAPE = DataReadProject_GetVariables(line, 'LFOSHAPE', 1)
    t.LFOSYNC1 = DataReadProject_GetVariables(line, 'LFOSYNC', 1)
    t.LFOSYNC2 = DataReadProject_GetVariables(line, 'LFOSYNC', 2)
    t.LFOSYNC3 = DataReadProject_GetVariables(line, 'LFOSYNC', 3)
    t.LFOSPEED1 = DataReadProject_GetVariables(line, 'LFOSPEED', 1)
    t.LFOSPEED2 = DataReadProject_GetVariables(line, 'LFOSPEED', 2)
    t.LFOSPEED3 = DataReadProject_GetVariables(line, 'LFOSPEED', 3)
    t.CHAN = DataReadProject_GetVariables(line, 'CHAN', 1)
    t.STEREO = DataReadProject_GetVariables(line, 'STEREO', 1)
    t.RMS1 = DataReadProject_GetVariables(line, 'RMS', 1)
    t.RMS2 = DataReadProject_GetVariables(line, 'RMS', 2)
    t.DBLO = DataReadProject_GetVariables(line, 'DBLO', 1)
    t.DBHI = DataReadProject_GetVariables(line, 'DBHI', 1)
    t.X2 = DataReadProject_GetVariables(line, 'X2', 1)
    t.Y2 = DataReadProject_GetVariables(line, 'Y2', 1)
    t.PLINK1 = DataReadProject_GetVariables(line, 'PLINK', 1)
    t.PLINK2 = DataReadProject_GetVariables(line, 'PLINK', 2)
    t.PLINK3 = DataReadProject_GetVariables(line, 'PLINK', 3)
    t.PLINK4 = DataReadProject_GetVariables(line, 'PLINK', 4)
    t.MIDIPLINK1 = DataReadProject_GetVariables(line, 'MIDIPLINK', 1)
    t.MIDIPLINK2 = DataReadProject_GetVariables(line, 'MIDIPLINK', 2)
    t.MIDIPLINK3 = DataReadProject_GetVariables(line, 'MIDIPLINK', 3)
    t.MIDIPLINK4 = DataReadProject_GetVariables(line, 'MIDIPLINK', 4)
    t.MODWND1 = DataReadProject_GetVariables(line, 'MODWND', 1)
    t.MODWND2 = DataReadProject_GetVariables(line, 'MODWND', 2)
    t.MODWND3 = DataReadProject_GetVariables(line, 'MODWND', 3)
    t.MODWND4 = DataReadProject_GetVariables(line, 'MODWND', 4)
    return t
  end
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  if ret then
    local ret2 = VF_CheckReaperVrs(5.95,true)    
    if ret and ret2 then main() end
  end
