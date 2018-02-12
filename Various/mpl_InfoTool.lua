-- @description InfoTool
-- @version 0.2alpha
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @about
--    Alpha version of Cubase-based feature. An info bar displaing some information about different objects, also allow to edit them quickly without walking through menus and windows.
-- @provides
--    mpl_InfoTool_functions/mpl_InfoTool_basefunc.lua
--    mpl_InfoTool_functions/mpl_InfoTool_GUI.lua
--    mpl_InfoTool_functions/mpl_InfoTool_DataUpdate.lua
--    mpl_InfoTool_functions/mpl_InfoTool_Widgets_Item.lua
--    mpl_InfoTool_functions/mpl_InfoTool_SpecFunc.lua
--    mpl_InfoTool_functions/mpl_InfoTool_MOUSE.lua
--    mpl_InfoTool_functions/mpl_InfoTool_Widgets_Envelope.lua
-- @changelog
--    # fix renaming items
--    # fix error when using #offset tag for multiple item selection
--    # use format_timestr_len for snapoffset
--    # extend MIDI source when extendind MIDI item length
--    + Context: Envelope Point (underlying envelope)
--    + Tags/Item - #fadein #fadeout #volume #transpose #itembuttons
--    + Tags/Envelope - #position #value
--    + Add support for custom ordered buttons
--    + ButtonTags/Item - #lock #mute #loop #chanmode




  local vrs = '0.2alpha'
--[[todo for
--    Automation Item context
--    Envelope point context
--    Ruler event context
--    Track context
--    Additional dynamic stuff


stretch marker - optimize for tonal content , force size
pan
]]
  
  -- lua example by Heda -- http://github.com/ReaTeam/ReaScripts-Templates/blob/master/Files/Require%20external%20files%20for%20the%20script.lua
  local info = debug.getinfo(1,'S');
  local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]])
  dofile(script_path .. "mpl_InfoTool_functions/mpl_InfoTool_basefunc.lua")
  dofile(script_path .. "mpl_InfoTool_functions/mpl_InfoTool_SpecFunc.lua")  
  dofile(script_path .. "mpl_InfoTool_functions/mpl_InfoTool_GUI.lua")
  dofile(script_path .. "mpl_InfoTool_functions/mpl_InfoTool_DataUpdate.lua")
  dofile(script_path .. "mpl_InfoTool_functions/mpl_InfoTool_MOUSE.lua") 
  dofile(script_path .. "mpl_InfoTool_functions/mpl_InfoTool_Widgets_Item.lua")
  dofile(script_path .. "mpl_InfoTool_functions/mpl_InfoTool_Widgets_Envelope.lua")
  

  
  
  -- NOT reaper NOT gfx
  --  INIT -------------------------------------------------
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  local conf = {} 
   data = {conf_path = script_path:gsub('\\','/') .. "mpl_InfoTool_Config.ini",
          vrs = vrs}
  local scr_title = 'InfoTool'
  local mouse = {}
  local obj = {}
  widgets = {}
  local cycle_cnt,clock = 0
  --local SCC, SCC_trig, lastSCC
  local FormTS, cur_pos, lastcur_pos, last_FormTS
  ---------------------------------------------------
  function ExtState_Def()
    return {ES_key = 'MPL_'..scr_title,
            wind_x =  50,
            wind_y =  50,
            wind_w =  200,
            wind_h =  300,
            dock =    513}--second
  end
  ---------------------------------------------------
  function Run()
    -- global clock/cycle
      clock = os.clock()
      cycle_cnt = cycle_cnt+1      
    -- check is something happen 
      FormTS = format_timestr_pos( 100, '', -1 )
      SCC =  GetProjectStateChangeCount( 0 ) 
      cur_pos = GetCursorPositionEx( 0 )
      SCC_trig = (lastSCC and lastSCC ~= SCC ) or (lastcur_pos and lastcur_pos ~= cur_pos) or (last_FormTS~=nil and FormTS ~= last_FormTS) or cycle_cnt == 1
      lastSCC = SCC
      lastcur_pos = cur_pos
      last_FormTS = FormTS    
    -- perf mouse
      local SCC_trig2 = MOUSE(obj,mouse, clock) 
    -- produce update if yes
      if redraw == 2 or SCC_trig2 then DataUpdate(data, mouse, widgets, obj) redraw = 1 end
      if SCC_trig then 
        DataUpdate(data, mouse, widgets, obj)
        redraw = 1      
      end
    -- perf GUI 
      GUI_Main(obj, cycle_cnt, redraw, data)
      redraw = 0 
    -- defer cycle   
      if gfx.getchar() >= 0 then defer(Run) else atexit(gfx.quit) end  
  end
  ---------------------------------------------------
  function Config_Default()
    -- default_config string
    return
[[
//Configuration for MPL InfoTool

[AudioItem]
order=#buttons#snap #position #length #offset #fadein #fadeout #vol #transpose #pan
buttons=#lock #preservepitch #loop #chanmode #mute 

[MIDIItem]
order=#buttons#snap #position #length #offset #fadein #fadeout #vol #transpose #pan
buttons=#lock #preservepitch #loop #mute

[EmptyItem]
buttons=#position #length

[MultipleItem]
order=#buttons#position #length #offset #fadein #fadeout #vol #transpose #pan
buttons=#lock #preservepitch #loop #chanmode #mute 

[EnvelopePoint]
order = #position #value

[MultipleEnvelopePoints]
order = #position #value
]]
  end
  ---------------------------------------------------
  function Config_ParseIni(conf_path) 
    local def_conf = Config_Default()
     
    --  create if not exists
      local f = io.open(conf_path, 'r')
      if f then
        f:close()
       else
        f = io.open(conf_path, 'w')
        if f then 
          f:write(def_conf)
          f:close()
        end
      end

    -- map types to data.obj_type_int order
      widgets.types_t ={'EmptyItem',
                        'MIDIItem',
                        'AudioItem',
                        'MultipleItem',
                        'EnvelopePoint',
                        'MultipleEnvelopePoints',
                  }
                      
    --  parse item widgets 
      for i = 1, #widgets.types_t do 
        local widg_str = widgets.types_t[i]
        local retval, str_widgets_tags = BR_Win32_GetPrivateProfileString( widg_str, 'order', '', conf_path )
        widgets[widg_str] = {}
        for w in str_widgets_tags:gmatch('#(%a+)') do widgets[widg_str] [  #widgets[widg_str] +1 ] = w end
        
        widgets[widg_str].buttons = {}
        local retval, buttons_str = BR_Win32_GetPrivateProfileString( widg_str, 'buttons', '', conf_path )
        for w in buttons_str:gmatch('#(%a+)') do widgets[widg_str].buttons [  #widgets[widg_str].buttons +1 ] = w end
      end
      
      
  end
  ---------------------------------------------------
  function Config_Reset(data)
    local def_conf = Config_Default()
    f = io.open(data.conf_path, 'w')
    if f then 
      f:write(def_conf)
      f:close()
    end
    redraw = 1
    SCC_trig = true
  end
  
  
 
  
  
  
  
  
  ---------------------------------------------------
  ExtState_Load(conf)  
  gfx.init('MPL '..scr_title,conf.wind_w, 30,513)--, conf.wind_x, conf.wind_y)
  obj = Obj_init()
  Config_ParseIni(data.conf_path)
  Run()  
  
  ---------------------------------------------------
  
  
  
    
