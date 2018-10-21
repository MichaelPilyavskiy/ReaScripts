-- @description QuantizeTool
-- @version 2.0alpha1
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @about Script for handling FX chain data on selected track
-- @provides
--    mpl_QuantizeTool_functions/mpl_QuantizeTool_GUI.lua
--    mpl_QuantizeTool_functions/mpl_QuantizeTool_MOUSE.lua
--    mpl_QuantizeTool_functions/mpl_QuantizeTool_data.lua
--    mpl_QuantizeTool_functions/mpl_QuantizeTool_obj.lua
--    mpl_QuantizeTool_Strategies/default.qtstr
-- @changelog
--    + Complete script rebuild. This is an early developer test alpha. It is more about replacing old buggy code that adding new functions.
--    + GUI: split into 4 sections: reference, source, action, and contol area
--    + Strategy: all objects handling follows strategy
--    + Strategy: load/save from/to file 
--    + Strategy: load/save from/to <res_path>/mpl_QuantizeTool_Strategies list
--    + Strategy: load/save from/to action list (non-persist external state reading on initialization)
--    + Strategy/Action/Type/Position-based Align: deductive brutforce engine
--    + Strategy/Action/Type/Position-based Align: independent position/value sliders
--    + Strategy/Action/Initialization/Catch reference on init
--    + Strategy/Action/Initialization/Catch source on init
--    + Strategy/Action/Initialization/Apply action on init
--    + Strategy/Action/Option/Sort positions before taking values (so values aren`t attached to src positions)

  local vrs = 'v2.0alpha1'
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
   data = {}
  local obj = {}
  strategy = {}
  
  local info = debug.getinfo(1,'S');  
  local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]]) 
  obj.script_path = script_path
  
  function Main_RefreshExternalLibs()     -- lua example by Heda -- http://github.com/ReaTeam/ReaScripts-Templates/blob/master/Files/Require%20external%20files%20for%20the%20script.lua    
    dofile(script_path .. "mpl_QuantizeTool_functions/mpl_QuantizeTool_GUI.lua")
    dofile(script_path .. "mpl_QuantizeTool_functions/mpl_QuantizeTool_MOUSE.lua")  
    dofile(script_path .. "mpl_QuantizeTool_functions/mpl_QuantizeTool_obj.lua")  
    dofile(script_path .. "mpl_QuantizeTool_functions/mpl_QuantizeTool_data.lua")  
  end  
  --------------------------------------------------------------------
  function LoadStrategy_Default(strategy)
    strategy.name = 'default' 
    
    -- reference
      -- positions
        strategy.ref_positions = 1
        strategy.ref_selitems = 0
        strategy.ref_envpoints = 1
      -- values
        strategy.ref_values = 1 -- &2 ordered sort
        strategy.ref_val_itemvol = 0
        strategy.ref_val_envpoint = 1
        
    -- source
      -- positions
        strategy.src_positions = 1
        strategy.src_selitems = 1
      -- values
        strategy.src_values = 1
        strategy.src_val_itemvol = 1  
         
    -- action
      --  align
        strategy.act_action = 1  
        
      -- init
        strategy.act_initcatchref = 1    
        strategy.act_initcatchsrc = 0 
        strategy.act_initact = 0  
        
    -- execute
      strategy.exe_val1 = 0
      strategy.exe_val2 = 0
  end
  ---------------------------------------------------
  function ExtState_Def()  
    local t= {
            -- globals
            mb_title = 'QuantizeTool',
            ES_key = 'MPL_QuantizeTool',
            wind_x =  50,
            wind_y =  50,
            wind_w =  400,
            wind_h =  450,
            dock =    0,
            dock2 =    0, -- set manually docked state
            
            -- mouse
            mouse_wheel_res = 960,
            activetab = 1, 
            
            -- data
            app_on_strategy_change = 0,
            app_on_slider_click = 1,
            iterationlim = 30000, -- deductive brutforce
            
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
    
  
    if refresh.conf == true then 
      ExtState_Save(conf)
      refresh.conf = nil end
    --if refresh.data_proj == true then Data_Update_ExtState_ProjData_Load (conf, obj, data, refresh, mouse) refresh.data_proj = nil end
    if refresh.GUI == true or refresh.GUI_onStart == true then            OBJ_Update              (conf, obj, data, refresh, mouse,strategy) end  
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
  function LoadStrategy(conf, strategy)
    obj.is_strategy_dirty = false
     cur_strat = GetExtState( conf.ES_key, 'ext_strategy_name' )
     ext_state = GetExtState( conf.ES_key, 'ext_state' )
    if ext_state and ext_state=='1' then 
      SetExtState( conf.ES_key, 'ext_state', 0, false )
      ext_state = true
     else
      SetExtState( conf.ES_key, 'ext_state', 0, false )
      ext_state = false
    end


    if cur_strat == '' then 
      LoadStrategy_Default(strategy)
      SetExtState( conf.ES_key, 'ext_strategy_name', 'default', false )
     elseif cur_strat ~= '' and not ext_state then 
      LoadStrategy_Parse(strategy, obj.script_path .. 'mpl_QuantizeTool_Strategies/last saved.qtstr'   ) 
     elseif cur_strat ~= '' and ext_state then 
      LoadStrategy_Parse(strategy, obj.script_path .. 'mpl_QuantizeTool_Strategies/'..cur_strat..'.qtstr'   ) 
    end
    
    -- inspect keys
      local t = CopyTable(strategy)
      LoadStrategy_Default(t)
      for key in pairs(t) do
        if not strategy[key] then strategy[key] = t[key] end
      end
  end
  --------------------------------------------------------------------
  function SaveStrategy(conf, strategy, flag, lastsaved)
  
    if (strategy.name == 'default' or strategy.name == '') and not lastsaved then return end
    local name = strategy.name
    if lastsaved then name = 'last saved' end
    
    name = name:gsub('*','')
    local out_fp = script_path .. "mpl_QuantizeTool_Strategies/"..name..'.qtstr'
    local out_str = '//strategy for MPL`s QuantizeTool v2\n'
    for val in spairs(strategy) do out_str = out_str..'\n'..val..'='..strategy[val] end
    
    if flag&1==1 then
      -- save to file
        local f = io.open(out_fp, 'w')
        f:write(out_str)
        f:close()
    end
    
    if flag&2==2 then
      -- save to action list
        local out_fp_script = script_path .. "mpl_QuantizeTool_Strategies/mpl_QuantizeTool - "..name..'.lua'
        local out_str = 
[[
-- generated from MPL QuantizeTool v2
-- @description Set QuantizeTool strategy to ']]..strategy.name..[['
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335

reaper.SetExtState("]].. conf.ES_key..'", "ext_strategy_name", "'..strategy.name..[[",false)
reaper.SetExtState("]].. conf.ES_key..[[","ext_state",1,false)
]]                                                          
        local f = io.open(out_fp_script, 'w')
        f:write(out_str)
        f:close()    
        AddRemoveReaScript( true, 0, out_fp_script, true )      
    end                                    
  end  
  --------------------------------------------------------------------
  function LoadStrategy_Parse(strategy, strat_fp)
    
    -- read content
      local f, content = io.open(strat_fp, 'r')
      if  f then  content = f:read('a') f:close()  else   return     end    
      if content then 
        for line in content:gmatch('[^\r\n]+') do
          if line:match('=') then
            local val = line:match('=(.*)')
            if tonumber(val) then val = tonumber(val) end
            strategy[line:match('(.*)=')] = val
          end
        end
      end
      
  end
--------------------------------------------------------------------
  function main()
        conf.dev_mode = 0
        conf.vrs = vrs
        Main_RefreshExternalLibs()
        ExtState_Load(conf)  
        LoadStrategy(conf, strategy)
        if strategy.act_initcatchref == 1 then  Data_ApplyStrategy_reference(conf, obj, data, refresh, mouse, strategy) end
        if strategy.act_initcatchsrc == 1 then  Data_ApplyStrategy_source   (conf, obj, data, refresh, mouse, strategy) end
        if strategy.act_initact > 0 then Data_ApplyStrategy_action(conf, obj, data, refresh, mouse, strategy) end
        gfx.init('MPL '..conf.mb_title..' '..conf.vrs,
                  conf.wind_w, 
                  conf.wind_h, 
                  conf.dock2, conf.wind_x, conf.wind_y)
        OBJ_init(obj)
        OBJ_Update(conf, obj, data, refresh, mouse,strategy) 
        run()  
  end
--------------------------------------------------------------------  
  local ret = CheckFunctions('Action') 
  local ret2 = CheckReaperVrs(5.95)    
  if ret and ret2 then main() end
