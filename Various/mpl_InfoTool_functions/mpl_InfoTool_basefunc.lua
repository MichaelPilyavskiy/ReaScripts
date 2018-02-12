-- @description InfoTool_basefunc
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex



  -- basic functions for mpl_InfoTool


  ---------------------------------------------------
  function msg(s) if s then ShowConsoleMsg(s..'\n') end end
  ---------------------------------------------------
  function lim(val, min,max) --local min,max 
    if not min or not max then min, max = 0,1 end 
    return math.max(min,  math.min(val, max) ) 
  end
  --[[-------------------------------------------------
  function HasWindXYWHChanged()
    local  _, wx,wy,ww,wh = gfx.dock(-1, 0,0,0,0)
    if   wx ~= last_gfxx 
     or  wy ~= last_gfxy 
     or  ww ~= last_gfxw 
     or  wh ~= last_gfxh then 
      retval = 1 
    end
    if not last_gfxx then retval = -1 end
    last_gfxx, last_gfxy, last_gfxw, last_gfxh = wx,wy,ww,wh
    return retval
  end]]
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
    _, conf.wind_x, conf.wind_y, conf.wind_w, conf.wind_h = gfx.dock(-1, 0,0,0,0)
    for key in pairs(conf) do SetExtState(conf.ES_key, key, conf[key], true)  end
  end
   
    function F_open_URL(url) if GetOS():match("OSX") then os.execute('open '.. url) else os.execute('start '..url) end  end
  ---------------------------------------------------
  function Menu(mouse, t)
    local str, check = '', ''
    for i = 1, #t do
      if t[i].state then check = '!' else check ='' end
      str = str..check..t[i].str..'|'
    end
    gfx.x = mouse.x
    gfx.y = mouse.y
    local ret = gfx.showmenu(str)
    if ret > 0 then if t[ret].func then t[ret].func() end end
  end  
  ---------------------------------------------------   
  function math_q(num)  if math.abs(num - math.floor(num)) < math.abs(num - math.ceil(num)) then return math.floor(num) else return math.ceil(num) end end
