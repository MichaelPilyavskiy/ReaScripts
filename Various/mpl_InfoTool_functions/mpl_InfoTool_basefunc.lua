-- @description InfoTool_basefunc
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex



  -- basic functions for mpl_InfoTool


  ---------------------------------------------------
  function msg(s) if s then ShowConsoleMsg(s..'\n') end end
  ---------------------------------------------------
  function MPL_ReduceFXname(s)return s:match('%: (.*)'):gsub('%(.-%)','') end
 ---------------------------------------------------  
  function lim(val, min,max) --local min,max 
    if not min or not max then min, max = 0,1 end 
    return math.max(min,  math.min(val, max) ) 
  end
  ---------------------------------------------------
  function HasWindXYWHChanged(last_gfxx, last_gfxy, last_gfxw, last_gfxh, last_dock)
    local  dock, wx,wy,ww,wh = gfx.dock(-1, 0,0,0,0)
    local retval=0
    if wx ~= last_gfxx or wy ~= last_gfxy then retval= 2 end --- minor
    if ww ~= last_gfxw or wh ~= last_gfxh or dock ~= last_dock then retval= 1 end --- major
    if not last_gfxx then retval = -1 end
    return retval, wx,wy,ww,wh, dock
  end
  ---------------------------------------------------
  function CopyTable(orig)--http://lua-users.org/wiki/CopyTable
      local orig_type = type(orig)
      local copy
      if orig_type == 'table' then
          copy = {}
          for orig_key, orig_value in next, orig, nil do
              copy[CopyTable(orig_key)] = CopyTable(orig_value)
          end
          setmetatable(copy, CopyTable(getmetatable(orig)))
      else -- number, string, boolean, etc
          copy = orig
      end
      return copy
  end 
  ---------------------------------------------------
  function ExtState_Load(conf)
    local def = ExtState_Def()
    for key in pairs(def) do 
      local es_str = GetExtState(def.ES_key, key)
      if es_str == '' then conf[key] = def[key] else conf[key] = tonumber(es_str) or es_str end
    end
  end  
  ---------------------------------------------------
  function ExtState_Save(conf)
    conf.dock2 , conf.wind_x, conf.wind_y, conf.wind_w, conf.wind_h= gfx.dock(-1, 0,0,0,0)
    for key in pairs(conf) do SetExtState(conf.ES_key, key, conf[key], true)  end
  end
   
    function F_open_URL(url) if GetOS():match("OSX") then os.execute('open '.. url) else os.execute('start '..url) end  end
  ---------------------------------------------------
  function Menu(mouse, t)
    local str, check ,hidden= '', '',''
    for i = 1, #t do
      if t[i].state then check = '!' else check ='' end
      if t[i].hidden then hidden = '#' else hidden ='' end
      str = str..hidden..check..t[i].str..'|'
    end
    gfx.x = mouse.x
    gfx.y = mouse.y
    local ret = gfx.showmenu(str)
    if ret > 0 then if t[ret].func then t[ret].func() end end
  end  
  ---------------------------------------------------   
  function math_q(num)  if math.abs(num - math.floor(num)) < math.abs(num - math.ceil(num)) then return math.floor(num) else return math.ceil(num) end end
  ---------------------------------------------------  
  function HasCurPosChanged()
    local cur_pos = GetCursorPositionEx( 0 )
    local ret = false
    if lastcur_pos and lastcur_pos ~= cur_pos then  ret = true end
    lastcur_pos = cur_pos
    return ret
  end
  ---------------------------------------------------
  function HasTimeSelChanged()
    local TS_st, TSend = GetSet_LoopTimeRange2( 0, false, false, -1, -1, false )
    local ret = false
    if lastTS_st and lastTSend and (lastTS_st ~= TS_st or lastTSend ~=TSend)  then  ret = true end
    lastTS_st, lastTSend = TS_st, TSend
    return ret
  end
  ---------------------------------------------------
  function HasGridChanged()
    local _, ProjGid = GetSetProjectGrid( 0, false )
    local ret = false
    if last_ProjGid and last_ProjGid ~= ProjGid  then  ret = true end
    last_ProjGid = ProjGid
    return ret
  end 
  ---------------------------------------------------
  function HasPlayStateChanged()
    local int_playstate = GetPlayStateEx( 0 )
    local ret = false
    if lastint_playstate and lastint_playstate ~= int_playstate  then  ret = true end
    lastint_playstate = int_playstate
    return ret
  end 
  ---------------------------------------------------
  function HasRulerFormChanged()
    local FormTS = format_timestr_pos( 100, '', -1 )
    local ret = false
    if last_FormTS and last_FormTS ~= FormTS  then  ret = true end
    last_FormTS = FormTS 
    return ret
  end
  function dBFromReaperVal(val)  local out
    if val < 1 then 
      out = 20*math.log(val, 10)
     else 
      out = 6*math.log(val, 2)
    end 
    return string.format('%.2f',out)
  end
  ---------------------------------------------------
  function ReaperValfromdB(dB_val)  local out
    local dB_val = tonumber(dB_val)
    if dB_val < 0 then 
      out = 10^(dB_val/20)
     else 
      out = 10^(dB_val/20)
    end 
    return out--string.format('%.2f',tonumber(out))
  end
  ---------------------------------------------------  
  function HasSelEnvChanged()
    local Sel_env = GetSelectedEnvelope( 0 )
    local ret = false
    if (Sel_env and not last_Sel_env) or (last_Sel_env and last_Sel_env ~= Sel_env)  then  ret = true end
    last_Sel_env = Sel_env 
    return ret
  end  
  ---------------------------------------------------
  function Config_ParseIni(conf_path, widgets) 
    local def_conf = Config_DefaultStr()
    --  create if not exists
      local f = io.open(conf_path, 'r')
      local cont
      if f then
        cont = f:read('a')
        f:close()
       else
        f = io.open(conf_path, 'w')
        if f then 
          f:write(def_conf)
          f:close()
        end
      end
    
    
                      
    --  parse widgets 
      for i = 1, #widgets.types_t do 
        local widg_str = widgets.types_t[i]
        if widg_str ~= nil then
          local retval, str_widgets_tags = BR_Win32_GetPrivateProfileString( widg_str, 'order', '', conf_path )
          widgets[widg_str] = {}
          for w in str_widgets_tags:gmatch('#(%a+)') do widgets[widg_str] [  #widgets[widg_str] +1 ] = w end
            
          widgets[widg_str].buttons = {}
          local retval, buttons_str = BR_Win32_GetPrivateProfileString( widg_str, 'buttons', '', conf_path )
          for w in buttons_str:gmatch('#(%a+)') do widgets[widg_str].buttons [  #widgets[widg_str].buttons +1 ] = w end
        end
      end
      
    -- persist
      local retval, pers_widg = BR_Win32_GetPrivateProfileString( 'Persist', 'order', '', conf_path )
      widgets.Persist = {}
      for w in pers_widg:gmatch('#(%a+)') do widgets.Persist [  #widgets.Persist +1 ] = w end
      
  end
  ---------------------------------------------------
  function Config_DumpIni(widgets, conf_path) 
      local str = '//Configuration for MPL InfoTool'
        
  
                        
      --  parse widgets 
        for i = 1, #widgets.types_t do 
          local widg_str = widgets.types_t[i]
          if widg_str then 
            str = str..'\n'..'['..widg_str..']'
            local ord = ''
            for i2 =1 , #widgets[widg_str] do 
              ord = ord..'#'..widgets[widg_str][i2]..' '
            end
            str = str..'\norder='..ord
            if widgets[widg_str].buttons and #widgets[widg_str].buttons > 0 then
              local b_ord = ''
              for i2 =1 , #widgets[widg_str].buttons do 
                b_ord = b_ord..'#'..widgets[widg_str].buttons[i2]..' '
              end
              str = str..'\nbuttons='..b_ord
            end
          end
        end
        
      -- persist
          local widg_str = 'Persist'
          str = str..'\n'..'['..widg_str..']'
          local ord = ''
          for i2 =1 , #widgets[widg_str] do 
            ord = ord..'#'..widgets[widg_str][i2]..' '
          end
          str = str..'\norder='..ord
          if widgets[widg_str].buttons and #widgets[widg_str].buttons > 0 then
            local b_ord = ''
            for i2 =1 , #widgets[widg_str].buttons do 
              b_ord = b_ord..'#'..widgets[widg_str].buttons[i2]..' '
            end
            str = str..'\nbuttons='..b_ord
          end
          
        
      local f = io.open(conf_path, 'w')        
      if f then 
        f:write(str)
        f:close()
      end           
    end
  ---------------------------------------------------
  function Config_Reset(conf_path)
    local def_conf = Config_DefaultStr()
    local f = io.open(conf_path, 'w')
    if f then 
      f:write(def_conf)
      f:close()
    end
    redraw = 1
    SCC_trig = true
  end
