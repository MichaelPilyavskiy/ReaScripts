-- @description ImportSessionData
-- @version 1.22
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=233358
-- @about Port of PT/S1 Import Session Data feature
-- @provides
--    mpl_ImportSessionData_functions/mpl_ImportSessionData_GUI.lua
--    mpl_ImportSessionData_functions/mpl_ImportSessionData_MOUSE.lua
--    mpl_ImportSessionData_functions/mpl_ImportSessionData_data.lua
--    mpl_ImportSessionData_functions/mpl_ImportSessionData_obj.lua
--    [main] mpl_ImportSessionData_presets/mpl_ImportSessionData preset - default.lua
-- @changelog
--    # fix dest tr GUI error

     
  local vrs = '1.22'
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
  local obj = {}
  local strategy = {}
  
  local info = debug.getinfo(1,'S');  
  local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]]) 
  obj.script_path = script_path
  ---------------------------------------------------   
  function Main_RefreshExternalLibs()     -- lua example by Heda -- http://github.com/ReaTeam/ReaScripts-Templates/blob/master/Files/Require%20external%20files%20for%20the%20script.lua    
    dofile(script_path .. "mpl_ImportSessionData_functions/mpl_ImportSessionData_GUI.lua")
    dofile(script_path .. "mpl_ImportSessionData_functions/mpl_ImportSessionData_MOUSE.lua")  
    dofile(script_path .. "mpl_ImportSessionData_functions/mpl_ImportSessionData_obj.lua")  
    dofile(script_path .. "mpl_ImportSessionData_functions/mpl_ImportSessionData_data.lua")  
  end  
  ---------------------------------------------------
  function ExtState_Def()  
    local t= {
            -- globals
            mb_title = 'ImportSessionData',
            ES_key = 'MPL_ImportSessionData',
            wind_x =  50,
            wind_y =  50,
            wind_w =  1200,
            wind_h =  300,
            dock =    0, 
            
            lastrppsession = '',
            sourceimportpath = 'ISD_mport',
            match_flags = 0, 
                    --[[
                      &1 full match
                      &2 case sensitive
                    ]]
            }
    return t
  end  
  ---------------------------------------------------    
  function run()
    obj.clock = os.clock()
    
    MOUSE(conf, obj, data, refresh, mouse)
    CheckUpdates(obj, conf, refresh)
    
  
    if refresh.conf == true then 
      ExtState_Save(conf)
      refresh.conf = nil 
    end

    if refresh.GUI == true or refresh.GUI_onStart == true then            OBJ_Update (conf, obj, data, refresh, mouse, strategy) end  
    if refresh.GUI_minor == true then refresh.GUI = true end
    GUI_draw (conf, obj, data, refresh, mouse) 
                                               
 
    ShortCuts(conf, obj, data, refresh, mouse)
    if mouse.char >= 0 and mouse.char ~= 27 
      then defer(run) else atexit(gfx.quit) end
  end
    
  
  
---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
--------------------------------------------------------------------
  function Run_Init(conf, obj, data, refresh, mouse)
    Data_ParseRPP(conf, obj, data, refresh, mouse)
    Data_CollectProjectTracks(conf, obj, data, refresh, mouse)
    Data_MatchDest(conf, obj, data, refresh, mouse, strategy) 
  end
--------------------------------------------------------------------
  function main()
        conf.dev_mode = 0
        conf.vrs = vrs
        Main_RefreshExternalLibs()
        ExtState_Load(conf)
        LoadStrategy(conf, strategy)
        gfx.init('MPL '..conf.mb_title..' '..conf.vrs,
                    conf.wind_w, 
                    conf.wind_h, 
                    conf.dock, conf.wind_x, conf.wind_y)
        OBJ_init(conf, obj, data, refresh, mouse)
        OBJ_Update(conf, obj, data, refresh, mouse, strategy) 
        Run_Init(conf, obj, data, refresh, mouse)   
        run()  
  end
  --------------------------------------------------------------------
    function LoadStrategy(conf, strategy, force_default)
     
       local cur_strat = GetExtState( conf.ES_key, 'ext_strategy_name' )
       local ext_state = GetExtState( conf.ES_key, 'ext_state' )
       ext_state = ext_state and ext_state=='1' 
       SetExtState( conf.ES_key, 'ext_state', 0, false )
        
      -- load defaults
        local def_t = LoadStrategy_Default()
        for key in pairs(def_t) do strategy[key] = def_t[key] end
        if force_default or (ext_state and cur_strat == 'default') then 
          SaveStrategy(conf, strategy, 1, true)
          return 
        end
        
      -- check ext state      
        if ext_state and cur_strat ~= 'default' then
          local preset_path = obj.script_path .. 'mpl_ImportSessionData_presets/'..cur_strat..'.qt'
          local f = io.open(preset_path, 'r')
          if f then 
            f:close()
            LoadStrategy_Parse(strategy, preset_path )
            return
           else
            MB('External strategy not found', 'ImportSessionData',0)
          end
        end
            
      -- load last saved
        local preset_path = obj.script_path .. 'mpl_ImportSessionData_presets/last saved.qt'
        local f = io.open(preset_path, 'r')
        if f then
          f:close()
          LoadStrategy_Parse(strategy, preset_path )
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
              local key = line:match('(.*)='):gsub('%s','')
              strategy[key] = val
            end
          end
        end
        
    end
  --------------------------------------------------------------------
  function SaveStrategy(conf, strategy, flag, lastsaved)
    if (strategy.name == 'default' or strategy.name == '') and not lastsaved then return end
    if lastsaved and strategy.name == 'default' then strategy.name = 'default_mod' end
    local name = strategy.name
    if lastsaved then name = 'last saved' end
    
    name = name:gsub('*','')
    local out_fp = script_path .. "mpl_ImportSessionData_presets/"..name..'.qt'
    local out_str = '//Preset for MPL`s ImportSessionData v1\n'
    for val in spairs(strategy) do out_str = out_str..'\n'..val..'='..strategy[val] end
    
    if flag&1==1 then
      -- save to file
        local f = io.open(out_fp, 'w')
        if f then
          f:write(out_str)
          f:close()
        end
    end
    
    if flag&2==2 then
      -- save to action list
        local out_fp_script = script_path .. "mpl_ImportSessionData_presets/mpl_ImportSessionData preset - "..name..'.lua'
        local out_str = 
[[
-- @description ImportSessionData preset - ]]..strategy.name..[[

-- @author PresetGenerator
-- @noindex

-- generated from MPL ImportSessionData v1
 
reaper.SetExtState("]].. conf.ES_key..'", "ext_strategy_name", "'..strategy.name..[[",false)
reaper.SetExtState("]].. conf.ES_key..[[","ext_state",1,false)
]]                                                          
        local f = io.open(out_fp_script, 'w')
        f:write(out_str)
        f:close()    
        local sect_ID = 0
        AddRemoveReaScript( true, sect_ID, out_fp_script, true )      
    end                                    
  end  
  --------------------------------------------------------------------
  function LoadStrategy_Default()
    local t = {name = 'default', 
    
        tr_filter = '',
        
        comchunk = 1,
        fxchain = 0, -- &2 add to chain instead replace
        trparams = 0, 
          --[[  &2 vol
                &4 pan stuff
                &8 phase
                &16 input settings 
                &32 monitor settings 
                &64 master/parent send
                &128 color
                ]]
        trsend = 0, 
          --[[  &2 insert new if not present
                &4 imported
                &8 imported as new track
                &16 disable checking multiple sends from same track
                ]]                 
        tritems = 0, 
          --[[  &2 replace
                &4 link sources from imported RPP folder
                &16 copy source to ISD_imported
                &8 build any missing peaks at the end of import
                ]]                
        master_stuff = 0,
          --[[  &2 FX chain
                &4 tempo/timesignature
                ]]
        markers_flags = 0,   
          --[[  &1 markers
                &2 markersreplace
                &4 regions
                &8 regionsreplace
                ]]                     
      }
    return t
  end 
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  if ret then
    local ret2 = VF_CheckReaperVrs(5.95,true)    
    if ret and ret2 then main() end
  end
