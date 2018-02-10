-- @description InfoTool
-- @version 0.1alpha
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @provides
--    mpl_InfoTool_functions/mpl_InfoTool_basefunc.lua
--    mpl_InfoTool_functions/mpl_InfoTool_GUI.lua
--    mpl_InfoTool_functions/mpl_InfoTool_DataUpdate.lua
--    mpl_InfoTool_functions/mpl_InfoTool_Widgets_Item.lua
--    mpl_InfoTool_functions/mpl_InfoTool_SpecFunc.lua
--    mpl_InfoTool_functions/mpl_InfoTool_MOUSE.lua
-- @changelog
--    + Prelimitary alpha version. There weren`t plans to develop it further with different widgets like interactive/draggable grid, different indicators/controls, but it probably can be improved in the future if will have some response from users on Cockos Forum.
--    + Basic interactive overview of some parameters
--    + Context: Audio item 
--    + Context: MIDI item
--    + Context: Empty Item
--    + Context: Multiple items
--    + Tags: Item - #snap #position #length #offset
--    + MouseModifiers/ShortCurs: change value - left drag value
--    + MouseModifiers/ShortCurs: change value - mousewheel
--    + MouseModifiers/ShortCurs: type/parse value - doubleclick
--    + Customizable configuration




  local vrs = '0.1alpha'
--[[todo for
--    Automation Item context
--    Envelope point context
--    Ruler event context
--    Track context
--    Additional dynamic stuff
]]
  
  -- lua example by Heda -- http://github.com/ReaTeam/ReaScripts-Templates/blob/master/Files/Require%20external%20files%20for%20the%20script.lua
  -- This run external functions too !
  local info = debug.getinfo(1,'S');
  local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]])
  dofile(script_path .. "mpl_InfoTool_functions/mpl_InfoTool_basefunc.lua")
  dofile(script_path .. "mpl_InfoTool_functions/mpl_InfoTool_SpecFunc.lua")  
  dofile(script_path .. "mpl_InfoTool_functions/mpl_InfoTool_GUI.lua")
  dofile(script_path .. "mpl_InfoTool_functions/mpl_InfoTool_DataUpdate.lua")
  dofile(script_path .. "mpl_InfoTool_functions/mpl_InfoTool_MOUSE.lua") 
  dofile(script_path .. "mpl_InfoTool_functions/mpl_InfoTool_Widgets_Item.lua")
  

  
  
  -- NOT reaper NOT gfx
  --  INIT -------------------------------------------------
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  local conf = {} 
  data = {conf_path = script_path:gsub('\\','/') .. "mpl_InfoTool_Config.ini",
          vrs = vrs  }
  local scr_title = 'InfoTool'
  mouse = {}
  local obj = {}
  local widgets = {}
  local cycle_cnt,clock = 0
  local SCC, SCC_trig, lastSCC
  local FormTS, cur_pos, lastcur_pos, last_FormTS
  --redraw = 1
  ---------------------------------------------------
  function ExtState_Def()
    return {ES_key = 'MPL_'..scr_title,
            wind_x =  50,
            wind_y =  50,
            wind_w =  200,
            wind_h =  300,
            dock =    0}
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
      GUI_Main(obj, cycle_cnt, redraw)
      redraw = 0 
    -- defer cycle   
      if gfx.getchar() >= 0 then defer(Run) else atexit(gfx.quit) end  
  end
  ---------------------------------------------------
  function Config_Default()
    -- default_config string
    return
[[
[AudioItem]
order=#snap #position #length #offset
[MIDIItem]
order=#snap #position #length #offset
[EmptyItem]
order=#position #length
[MultipleItem]
order=#position #length
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
    
    --  parse audio item widgets 
      widgets.types_t ={'EmptyItem',
                        'MIDIItem',
                        'AudioItem',
                        'MultipleItem'
                  }
      for i = 1, #widgets.types_t do 
        local widg_str = widgets.types_t[i]
        local retval, str_widgets_tags = BR_Win32_GetPrivateProfileString( widg_str, 'order', '', conf_path )
        widgets[widg_str] = {}
        for w in str_widgets_tags:gmatch('#(%a+)') do widgets[widg_str] [  #widgets[widg_str] +1 ] = w end
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
  
  
  
    
