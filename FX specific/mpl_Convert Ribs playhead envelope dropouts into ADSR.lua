-- @description Convert Ribs playhead envelope dropouts into ADSR
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--   + init
  
  for key in pairs(reaper) do _G[key]=reaper[key]  end  
  
  scale = {a = 0.2, --ms
           d = 0.5,
           r = 1}
  
  
  debug = 0
  --  INIT -------------------------------------------------
  for key in pairs(reaper) do _G[key]=reaper[key]  end  
  local mouse = {}
  local gui -- see GUI_define()
  local obj = {}
  data = {a = 0,
          d = 0.5,
          s = 0.3,
          r = 0.1}
  points = {}
  local conf = {}
  local cycle = 0
  local redraw = -1
  local SCC, lastSCC, SCC_trig,ProjState
  ---------------------------------------------------  
  function Action_GrabPoints()
    local env = GetSelectedEnvelope( 0 )
    if not env then MB('Select playhead position envelope first', 'MPL Ribs ADSR', 0) return end
    local _, env_chunk = GetEnvelopeStateChunk( env, '', true )
    if not env_chunk:match('PARMENV 24 ') then MB('Select playhead position envelope first', 'MPL Ribs ADSR', 0) return end
    
    -- get points
      local t = {}
      for i = 1,  CountEnvelopePoints( env ) do t[#t+1] = ({GetEnvelopePoint( env, i-1 )})  end
    
    -- filter points
      points = {env=env}
      local cur_val,cur_pos,last_val,last_pos
      for i = 1, #t do
        cur_val = t[i][3]
        cur_pos = t[i][2]
        if last_val and last_val <= 0.001 and cur_val > 0.001 then points[#points+1] = t[i] end
        last_val = cur_val
        last_pos = cur_pos
      end
      
  end
  ---------------------------------------------------
  function Action_ApplyADSR()
    if not points.env then return end
    DeleteEnvelopePointRangeEx( points.env, -1, 0,  math.huge)
    local tech_shift = 0.0001
    for i = 1, #points do
      local pos = points[i][2]
      local a = tech_shift+data.a*scale.a
      local d = tech_shift+data.d*scale.d
      local r = tech_shift+data.r*scale.r 
      if i < #points then if pos+a+d+r > points[i+1][2] then r = points[i+1][2] - pos - a- d-tech_shift end end
      local value = points[i][3]
      local shape = points[i][4]
      local tension = points[i][5]
      InsertEnvelopePoint( points.env, pos, 0, 0, 0, false, true )
      InsertEnvelopePoint( points.env, pos+a, value, 0, 0, false, true )
      InsertEnvelopePoint( points.env, pos+a+d, value*data.s, 0, 0, false, true )
      InsertEnvelopePoint( points.env, pos+a+d+r, 0, 0, 0, false, true )
    end
    Envelope_SortPoints(points.env)
    UpdateArrange()
  end
  ---------------------------------------------------
  local function lim(val, min,max) --local min,max 
    if not min or not max then min, max = 0,1 end 
    return math.max(min,  math.min(val, max) ) 
  end
  ---------------------------------------------------
  local function ExtState_Save()
    _, conf.wind_x, conf.wind_y, conf.wind_w, conf.wind_h = gfx.dock(-1, 0,0,0,0)
    for key in pairs(conf) do SetExtState(conf.ES_key, key, conf[key], true)  end
  end
  ---------------------------------------------------
  function msg(s)  ShowConsoleMsg(s..'\n') end
  function deb(s)  if debug == 1 then ShowConsoleMsg(s..'\n') end end
  ---------------------------------------------------
  local function col(col_s, a) gfx.set( table.unpack(gui.col[col_s])) if a then gfx.a = a end  end
  ---------------------------------------------------
  local function GUI_DrawBut(o) 
    if not o then return end
    local x,y,w,h, txt = o.x, o.y, o.w, o.h, o.txt
    if not x or not y or not w or not h then return end
    gfx.a = o.alpha_back or 0.3
    gfx.blit( 2, 1, 0, -- grad back
              0,0,  obj.grad_sz,obj.grad_sz,
              x,y,w,h, 0,0)
    col(o.col, o.alpha_back or 0.2)
    if o.state and o.alpha_back_active then gfx.a = o.alpha_back_active end
    if o.is_but ==2 and o.val then 
      gfx.a = 0.6 
      gfx.rect(x,y+h*(1-o.val),w,h*o.val,1) 
    end
    --gfx.rect(x,y,w,h,1)
    if o.txt then 
      col('white', o.alpha_txt or 0.8)
      gfx.setfont(1, gui.font, gui.fontsz)
      gfx.x = x+ (w-gfx.measurestr(txt))/2
      gfx.y = y+ (h-gfx.texth)/2
      if o.bot_al_txt then 
        gfx.y = y+ h-gfx.texth-3
      end
      gfx.drawstr(o.txt)
    end
    if o.rect_a then 
      col(o.col, o.alpha_back or 0.2)
      gfx.rect(x,y,w,h,0)
    end
  end
  ---------------------------------------------------
  local function GUI_draw()
    gfx.mode = 0
    -- redraw: -1 init, 1 maj changes, 2 minor changes
    -- 1 back
    -- 2 gradient
    --// 3 dynamic stuff
      
    --  init
      if redraw == -1 then
        OBJ_Update()
        gfx.dest = 2
        gfx.setimgdim(2, -1, -1)  
        gfx.setimgdim(2, obj.grad_sz,obj.grad_sz)  
        local r,g,b,a = 1,1,1,0.68
        gfx.x, gfx.y = 0,0
        local c = 0.9
        local drdx = c*0.00001
        local drdy = c*0.00001
        local dgdx = c*0.00001
        local dgdy = c*0.00001    
        local dbdx = c*0.00001 
        local dbdy = c*0.00001 
        local dadx = c*0.00003
        local dady = c*0.0004       
        gfx.gradrect(0,0, obj.grad_sz,obj.grad_sz, 
                        r,g,b,a, 
                        drdx, dgdx, dbdx, dadx, 
                        drdy, dgdy, dbdy, dady) 
        redraw = 1 -- force com redraw after init 
      end
      
    -- refresh
      if redraw == 1 then 
        OBJ_Update()
        -- refresh backgroung
          gfx.dest = 1
          gfx.setimgdim(1, -1, -1)  
          gfx.setimgdim(1, gfx.w, gfx.h) 
          gfx.blit( 2, 1, 0, -- grad back
                    0,0,  obj.grad_sz,obj.grad_sz,
                    0,0,  gfx.w,gfx.h, 0,0)
          gfx.a = 0.1
          --gfx.line(gfx.w-obj.menu_w, 0,gfx.w-obj.menu_w, gfx.h )
        -- refresh all buttons
          for key in pairs(obj) do
            if not key:match('knob') and type(obj[key]) == 'table' and obj[key].is_but then
              GUI_DrawBut(obj[key])
            end
          end         
      end
      
      
    --  render    
      gfx.dest = -1   
    -- static GUI
      gfx.a = 1
      gfx.x,gfx.y = 0,0
      gfx.blit(1, 1, 0, -- backgr
          0,0,gfx.w, gfx.h,
          0,0,gfx.w, gfx.h, 0,0)  
    
    
    redraw = 0
    gfx.update()
  end
  ---------------------------------------------------
  function HasWindXYWHChanged()
    local  _, wx,wy,ww,wh = gfx.dock(-1, 0,0,0,0)
    local retval=0
    if wx ~= obj.last_gfxx or wy ~= obj.last_gfxy then retval= 2 end --- minor
    if ww ~= obj.last_gfxw or wh ~= obj.last_gfxh then retval= 1 end --- major
    if not obj.last_gfxx then retval = -1 end
    obj.last_gfxx, obj.last_gfxy, obj.last_gfxw, obj.last_gfxh = wx,wy,ww,wh
    return retval
  end
  ---------------------------------------------------
  local function ExtState_Def()
    return {ES_key = 'MPL_Ribs_ADSR',
            wind_x =  50,
            wind_y =  50,
            wind_w =  250,
            wind_h =  140,
            dock =    0,}
  end
  ---------------------------------------------------
  local function ExtState_Load()
    local def = ExtState_Def()
    for key in pairs(def) do 
      local es_str = GetExtState(def.ES_key, key)
      if es_str == '' then conf[key] = def[key] else conf[key] = tonumber(es_str) or es_str end
    end
  end
  ---------------------------------------------------
  local function OBJ_define()  
    obj.offs = 2
    obj.grad_sz = 200
    obj.item_h = 30
    obj.tr_w = 130
    obj.tr_h = 35
    
    obj.grab = { x = 0,
                y = 0,
                h = obj.item_h,
                txt = "Grab Ribs playhead envelope points",
                col = 'white',
                state = 0,
                is_but = 1,
                alpha_back = 0.2,
                func =  function() Action_GrabPoints() redraw = 1 end}     
    obj.a =     { x = 0,
                y = obj.item_h+1,
                txt = "A",
                col = 'white',
                state = 0,
                is_but = 2,
                alpha_back = 0.2,
                func =  function() end}    
    obj.d =     {
                y = obj.item_h+1,
                txt = "D",
                col = 'white',
                state = 0,
                is_but = 2,
                alpha_back = 0.2,
                func =  function() end}   
    obj.s =     { 
                y = obj.item_h+1,
                txt = "S",
                col = 'white',
                state = 0,
                is_but = 2,
                alpha_back = 0.2,
                func =  function() end} 
    obj.r =     { 
                y = obj.item_h+1,
                txt = "R",
                col = 'white',
                state = 0,
                is_but = 2,
                alpha_back = 0.2,
                func =  function() end}                                                            
                      
  end
  ---------------------------------------------------
  function OBJ_Update()
    obj.grab.w = gfx.w
    obj.a.w = math.floor(gfx.w/4)
    obj.a.h = gfx.h-obj.item_h
    obj.a.val = data.a
    
    obj.d.x = obj.a.w+1
    obj.d.w = math.floor(gfx.w/4)
    obj.d.h = gfx.h-obj.item_h
    obj.d.val = data.d
    
    obj.s.x = obj.d.x+obj.d.w+1
    obj.s.w = math.floor(gfx.w/4)
    obj.s.h = gfx.h-obj.item_h
    obj.s.val = data.s
    
    obj.r.x = obj.s.x+obj.s.w+1
    obj.r.w = math.floor(gfx.w/4)
    obj.r.h = gfx.h-obj.item_h
    obj.r.val = data.r
        
    obj.grab.txt = "Grab Ribs playhead envelope points ("..#points..')'
  end
  ---------------------------------------------------
  function Menu(t)
    gfx.x = mouse.mx
    gfx.y = mouse.my
    local ret = gfx.showmenu('')
  end
 ---------------------------------------------------
  local function MOUSE_Match(b) if b.x and b.y and b.w and b.h then return mouse.mx > b.x and mouse.mx < b.x+b.w and mouse.my > b.y and mouse.my < b.y+b.h end  end
 ------------- -------------------------------------- 
  local function MOUSE_Click(b) return MOUSE_Match(b) and mouse.LMB_state and not mouse.last_LMB_state end
  local function MOUSE_ClickR(b) return MOUSE_Match(b) and mouse.RMB_state and not mouse.last_RMB_state end
  ---------------------------------------------------
  local function MOUSE()
    mouse.mx = gfx.mouse_x
    mouse.my = gfx.mouse_y
    mouse.LMB_state = gfx.mouse_cap&1 == 1 
    mouse.RMB_state = gfx.mouse_cap&2 == 2 
    mouse.MMB_state = gfx.mouse_cap&64 == 64
    mouse.LMB_state_doubleclick = false
    mouse.Ctrl_LMB_state = gfx.mouse_cap&5 == 5 
    mouse.Ctrl_state = gfx.mouse_cap&4 == 4 
    mouse.Alt_state = gfx.mouse_cap&17 == 17 -- alt + LB
    mouse.wheel = gfx.mouse_wheel
    if mouse.last_wheel then mouse.wheel_trig = (mouse.wheel - mouse.last_wheel) end 
    if mouse.LMB_state and not mouse.last_LMB_state then  mouse.last_mx_onclick = mouse.mx     mouse.last_my_onclick = mouse.my end    
    if mouse.last_mx_onclick and mouse.last_my_onclick then mouse.dx = mouse.mx - mouse.last_mx_onclick  mouse.dy = mouse.my - mouse.last_my_onclick else mouse.dx, mouse.dy = 0,0 end

    -- butts    
    for key in pairs(obj) do
      if not key:match('knob') and type(obj[key]) == 'table'and obj[key].is_but then
        if MOUSE_Click(obj[key]) then if obj[key].func then obj[key].func() end end
        
        if obj[key].is_but == 2 then 
          if MOUSE_Click(obj[key]) then 
            mouse.context_latch = key 
            mouse.context_latch_val = obj[key].val            
          end
          if mouse.last_LMB_state and mouse.LMB_state and mouse.context_latch and tonumber(mouse.context_latch_val) then 
            data[mouse.context_latch] = lim(mouse.context_latch_val-mouse.dy/100,0,1)
            Action_ApplyADSR()
            redraw = 1
          end
        end
        
      end
    end
          
    
    -- mouse release    
      if mouse.last_LMB_state and not mouse.LMB_state   then  
        mouse.context_latch = '' 
        mouse.context_latch_val = '' 
      end
      mouse.last_LMB_state = mouse.LMB_state  
      mouse.last_RMB_state = mouse.RMB_state
      mouse.last_MMB_state = mouse.MMB_state 
      mouse.last_Ctrl_LMB_state = mouse.Ctrl_LMB_state
      mouse.last_Ctrl_state = mouse.Ctrl_state
      mouse.last_Alt_state = mouse.Alt_state
      mouse.last_wheel = mouse.wheel      
  end
  ---------------------------------------------------
  function run()
    SCC =  GetProjectStateChangeCount( 0 ) 
    if not lastSCC or lastSCC ~= SCC then SCC_trig = true else SCC_trig = false end lastSCC = SCC
    clock = os.clock()
    cycle = cycle+1
    local st_wind = HasWindXYWHChanged()
    if st_wind >= -1 then ExtState_Save() if math.abs(st_wind) == 1 then redraw = st_wind  end end
    if SCC_trig then redraw = -1 end
    MOUSE()
    GUI_draw()
    if gfx.getchar() >= 0 then defer(run) else atexit(gfx.quit) end
  end  
  ---------------------------------------------------
  local function GUI_define()
    gui = {
                aa = 1,
                mode = 3,
                fontname = 'Calibri',
                fontsz = 16,
                col = { grey =    {0.5, 0.5,  0.5 },
                        white =   {1,   1,    1   },
                        red =     {1,   0,    0   },
                        green =   {0.3,   0.9,    0.3   }
                      }
                
                }
    
      if OS == "OSX32" or OS == "OSX64" then gui.fontsize = gui.fontsize - 7 end
  end
  ---------------------------------------------------
  ExtState_Load()  
  gfx.init('MPL Ribs ADSR',conf.wind_w, conf.wind_h, conf.dock, conf.wind_x, conf.wind_y)
  OBJ_define()
  OBJ_Update()
  GUI_define()
  Action_GrabPoints()
  run()
  
  