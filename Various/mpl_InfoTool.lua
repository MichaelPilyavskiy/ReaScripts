-- @description InfoTool
-- @version 0.3alpha
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @about
--    An info bar displaing some information about different objects, also allow to edit them quickly without walking through menus and windows.
-- @provides
--    mpl_InfoTool_functions/mpl_InfoTool_basefunc.lua
--    mpl_InfoTool_functions/mpl_InfoTool_GUI.lua
--    mpl_InfoTool_functions/mpl_InfoTool_DataUpdate.lua
--    mpl_InfoTool_functions/mpl_InfoTool_SpecFunc.lua
--    mpl_InfoTool_functions/mpl_InfoTool_MOUSE.lua
--    mpl_InfoTool_functions/mpl_InfoTool_Widgets_Item.lua
--    mpl_InfoTool_functions/mpl_InfoTool_Widgets_Envelope.lua
--    mpl_InfoTool_functions/mpl_InfoTool_Widgets_Persist.lua
-- @changelog
--    + Add support for persistent widgets (out of contexts, displayed on the right side, config order - backwards)
--    + Tags/Persistent - #grid, drag/wheel controls value from 1/128 to 1, right click toggle snap, double click open snap settings
--    + Tags/Persistent - #timeselend #timeselstart, same behaviour as object controls
--    + Tags/AudioItem - #bwfsrc perform action Item: Move to source preferred position (used by BWF)
--    + GUI: Store XYWH+docked window settings, loads to the second docker by default
--    + Config: allow to customize font sizes
--    + Config: allow to customize text colors
--    + Config: allow to customize background color and alpha
--    + WidgetConfig: add editable fields to the menus
--    # Context: fix envpoint/multiple env points catching, ignore AI for now
--    # Config: fix emptyitem string for default config
--    # GUI: move config button to the left side
--    # GUI: increased default font size for OSX
--    # GUI: use font2 for buttons
--    # GUI: hardcoded volume, pitch, pah heights
--    # GUI: fix hardcode Item/#lock y offset
--    # GUI: refresh GUI when not docked and changing window size
--    # GUI: reduce context modules when they overlapped by persistent modules
--    # Performance: force GUI/data update on changing timeselection








  local vrs = '0.3alpha'

    local info = debug.getinfo(1,'S');
    local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]])
      
  function RefreshExternalLibs()
    -- lua example by Heda -- http://github.com/ReaTeam/ReaScripts-Templates/blob/master/Files/Require%20external%20files%20for%20the%20script.lua
    dofile(script_path .. "mpl_InfoTool_functions/mpl_InfoTool_basefunc.lua")
    dofile(script_path .. "mpl_InfoTool_functions/mpl_InfoTool_SpecFunc.lua")  
    dofile(script_path .. "mpl_InfoTool_functions/mpl_InfoTool_GUI.lua")
    dofile(script_path .. "mpl_InfoTool_functions/mpl_InfoTool_DataUpdate.lua")
    dofile(script_path .. "mpl_InfoTool_functions/mpl_InfoTool_MOUSE.lua") 
    dofile(script_path .. "mpl_InfoTool_functions/mpl_InfoTool_Widgets_Item.lua")
    dofile(script_path .. "mpl_InfoTool_functions/mpl_InfoTool_Widgets_Envelope.lua")
    dofile(script_path .. "mpl_InfoTool_functions/mpl_InfoTool_Widgets_Persist.lua")
  end
  
  RefreshExternalLibs()
  
  
  -- NOT reaper NOT gfx
  --  INIT -------------------------------------------------
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  local conf = {} 
  local data = {conf_path = script_path:gsub('\\','/') .. "mpl_InfoTool_Config.ini",
          vrs = vrs}
  local scr_title = 'InfoTool'
  local mouse = {}
  local obj = {}
  local widgets = {    -- map types to data.obj_type_int order
              types_t ={'EmptyItem',
                        'MIDIItem',
                        'AudioItem',
                        'MultipleItem',
                        'EnvelopePoint',
                        'MultipleEnvelopePoints'
                        }
                  }
  local cycle_cnt,clock = 0
  local SCC, SCC_trig, lastSCC
  local lastcur_pos
  local last_FormTS
  local lastTS_st, lastTSend
  local last_gfxx, last_gfxy, last_gfxw, last_gfxh, last_dock
  ---------------------------------------------------
  function Config_DefaultStr()
    return [[
//Configuration for MPL InfoTool
[EmptyItem]
order=#position #length
[MIDIItem]
order=#buttons#snap #position #length #offset #fadein #fadeout #vol #transpose #pan
buttons=#lock #loop #mute 
[AudioItem]
order=#buttons#snap #position #length #offset #fadein #fadeout #vol #transpose #pan
buttons=#lock #preservepitch #loop #mute #chanmode #bwfsrc 
[MultipleItem]
order=#buttons#position #length #offset #fadein #fadeout #vol #transpose #pan
buttons=#lock #preservepitch #loop #chanmode #mute 
[EnvelopePoint]
order = #position #value
[MultipleEnvelopePoints]
order = #position #value
[Persist]
order = #grid #timeselend #timeselstart
]]
  end  
  ---------------------------------------------------
  function ExtState_Def()
    return {ES_key = 'MPL_'..scr_title,
            scr_title = 'InfoTool',
            wind_x =  50,
            wind_y =  50,
            wind_w =  200,
            wind_h =  300,
            dock2 =    513, --second
            GUI_font1 = 17,
            GUI_font2 = 15,
            GUI_colortitle =      16768407, -- blue
            GUI_background_col =  16777215, -- white
            GUI_background_alpha = 0.18}
  end
  ---------------------------------------------------
  function Run()
    -- global clock/cycle
      clock = os.clock()
      cycle_cnt = cycle_cnt+1      
    -- check is something happen 
      SCC =  GetProjectStateChangeCount( 0 )       
      SCC_trig = (lastSCC and lastSCC ~= SCC) or cycle_cnt == 1
      lastSCC = SCC      
      if not SCC_trig and HasCurPosChanged() then SCC_trig = true end
      if not SCC_trig and HasTimeSelChanged() then SCC_trig = true end
      if not SCC_trig and HasRulerFormChanged() then SCC_trig = true end      
      
    -- wind state
      local ret
      ret,last_gfxx, last_gfxy, last_gfxw, last_gfxh, last_dock = HasWindXYWHChanged(last_gfxx, last_gfxy, last_gfxw, last_gfxh, last_dock)
      if ret == 1 then 
        redraw = 2
        ExtState_Save(conf)
       elseif ret == 2 then
        ExtState_Save(conf)
      end
    -- perf mouse
      local SCC_trig2 = MOUSE(obj,mouse, clock) 
    -- produce update if yes
      if redraw == 2 or SCC_trig2 then DataUpdate(data, mouse, widgets, obj, conf) redraw = 1 end
      if SCC_trig then 
        DataUpdate(data, mouse, widgets, obj, conf)
        redraw = 1      
      end
    -- perf GUI 
      GUI_Main(obj, cycle_cnt, redraw, data)
      redraw = 0 
    -- defer cycle   
      if gfx.getchar() >= 0 and not force_exit then defer(Run) else atexit(gfx.quit) end  
  end
  
  
  ---------------------------------------------------
  ExtState_Load(conf)  
  gfx.init('MPL '..conf.scr_title,conf.wind_w, conf.wind_h,  conf.dock2 , conf.wind_x, conf.wind_y)
  obj = Obj_init(conf)
  Config_ParseIni(data.conf_path, widgets)
  Run()  
  
  ---------------------------------------------------
  
  
  
    
