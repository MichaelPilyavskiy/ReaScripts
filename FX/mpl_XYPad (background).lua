-- @description XYPad
-- @version 1.0
-- @author MPL 
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--  + init

  
  local scr_title = 'XYPad'
  debug = 0
  -- NOT reaper NOT gfx
  --  INIT -------------------------------------------------
  for key in pairs(reaper) do _G[key]=reaper[key]  end  
  local mouse = {}
  local gui -- see GUI_define()
  local obj = {}
  local conf = {}
  local cycle = 0
  local redraw = -1
  data = {}
  local SCC, lastSCC, SCC_trig,ProjState
  --local V1, V2, V3, V4 = 0,0,0,0
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
  local function msg(s)  ShowConsoleMsg(s..'\n') end
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
    if o.val then
      col('green', 0.49)
      gfx.rect(x,y,lim(w*o.val,0,w),h,1)
    end              
    col(o.col, o.alpha_back or 0.2)
    gfx.rect(x,y,w,h,1)
    ------------------ txt
      if o.txt and w > 0 then 
        local txt = tostring(o.txt)
        if o.txt_col then 
          col(o.txt_col, o.alpha_txt or 0.8)
         else
          col('white', o.alpha_txt or 0.8)
        end
        local f_sz = gui.fontsz
        gfx.setfont(1, gui.font,o.fontsz or gui.fontsz )
        local y_shift = -1
        for line in txt:gmatch('[^\r\n]+') do
          if gfx.measurestr(line:sub(2)) > w -2 and w > 20 then 
            repeat line = line:sub(2) until gfx.measurestr(line..'...')< w -2
            line = '...'..line
          end
          if o.txt2 then line = o.txt2..' '..line end
          gfx.x = x+ math.ceil((w-gfx.measurestr(line))/2)
          gfx.y = y+ (h-gfx.texth)/2 + y_shift 
          if o.aligh_txt then
            if o.aligh_txt&1==1 then gfx.x = x  end -- align left
            if o.aligh_txt>>2&1==1 then gfx.y = y + y_shift end -- align top
            if o.aligh_txt>>4&1==1 then gfx.y = h - gfx.texth end -- align bot
          end
          if o.bot_al_txt then 
            gfx.y = y+ h-gfx.texth-3 +y_shift
          end
          gfx.drawstr(line)
          y_shift = y_shift + gfx.texth
        end
      end    if o.rect_a then 
      col(o.col, o.rect_a)
      gfx.rect(x,y,w,h,0)
    end
  end
 ---------------------------------------------------  
  function Data_Update()
    if data.values then 
      for key in pairs(data.values) do
        local tr =  BR_GetMediaTrackByGUID( 0, data.values[key].trGUID )
        if tr then 
          local fx = GetFXIDbyGUID(tr, data.values[key].fxGUID)
          local retval, fx_name = TrackFX_GetFXName( tr, fx, '' )
          if fx_name then data.values[key].fx_name = fx_name end
          local retval, parname = TrackFX_GetParamName( tr, fx, data.values[key].param, '' )
          if parname then data.values[key].param_name = parname end
          data.values[key].val_readout = TrackFX_GetParam(tr, fx, data.values[key].param )
         else 
          data.values[key] = nil
        end
      end
    end
  end
  ---------------------------------------------------
  local function GUI_draw()
    gfx.mode = 0
    -- redraw: -1 init, 1 maj changes, 2 minor changes
    -- 1 back
    -- 2 gradient
      
    --  init
      if redraw == -1 then
        Data_Update()
        OBJ_Update()
        gfx.dest = 2
        gfx.setimgdim(2, -1, -1)  
        gfx.setimgdim(2, obj.grad_sz,obj.grad_sz)  
        local r,g,b,a = 0.9,0.9,1,0.65
        gfx.x, gfx.y = 0,0
        local c = 1
        local drdx = c*0.00001
        local drdy = c*0.00001
        local dgdx = c*0.001
        local dgdy = c*0.0005    
        local dbdx = c*0.00008
        local dbdy = c*0.00001
        local dadx = c*0.0001
        local dady = c*0.001       
        gfx.gradrect(0,0, obj.grad_sz,obj.grad_sz, 
                        r,g,b,a, 
                        drdx, dgdx, dbdx, dadx, 
                        drdy, dgdy, dbdy, dady) 
        redraw = 1 -- force com redraw after init 
      end
      
    -- refresh
      if redraw == 1 then 
        Data_Update()
        OBJ_Update()
        -- refresh backgroung
          gfx.dest = 1
          gfx.setimgdim(1, -1, -1)  
          gfx.setimgdim(1, gfx.w, gfx.h) 
          gfx.blit( 2, 1, 0, -- grad back
                    0,0,  obj.grad_sz,obj.grad_sz/3,
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
      gfx.a = 1
      gfx.x,gfx.y = 0,0
    --  back
      gfx.blit(1, 1, 0, -- backgr
          0,0,gfx.w, gfx.h,
          0,0,gfx.w, gfx.h, 0,0)  
    
    if mouse.LMB_state  then GUI_point(X,Y) end
    
    
    redraw = 0
    gfx.update()
  end
  function GUI_point(x,y)
    if not x or not y then return end
    col('green', 0.4)
    gfx.circle(x*obj.XYpad.w,obj.XYpad.y+obj.XYpad.h - y*obj.XYpad.h,5, 1)
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
    return {ES_key = 'MPL_'..scr_title,
            wind_x =  50,
            wind_y =  50,
            wind_w =  300,
            wind_h =  300,
            dock =    0,
            scale_root = 0}
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
  function GetLearn(slot)
    if not slot then return end
    local retval, tracknum, fxnum, paramnum  = GetLastTouchedFX()
    if retval then
      if not data.values then data.values = {} end
      local tr = CSurf_TrackFromID( tracknum, false )
      data.values[slot] = { trGUID = GetTrackGUID( tr ),
                            fxGUID = TrackFX_GetFXGUID( tr, fxnum ),
                            param = paramnum
                          }
    end
  end
  ---------------------------------------------------
  function SetValue(val, data_id)
    if not data.values or not val then return end
    if not data.values[data_id] then return end
    
    local tr = BR_GetMediaTrackByGUID( 0, data.values[data_id].trGUID )
    if not tr or not  reaper.ValidatePtr2( 0, tr, 'MediaTrack*' ) then return end
    fx_id = GetFXIDbyGUID(tr, data.values[data_id].fxGUID) 
    if fx_id < 0 then return end
    TrackFX_SetParam( tr, fx_id, data.values[data_id].param, val )
  end
  ---------------------------------------------------
  local function OBJ_define()  
    obj.offs = 2
    obj.grad_sz = 200
    obj.y_offs_setup = 100
    obj.lrn_w = 70
    obj.id_w =  25
    obj.XYpad = { x = 0,
                y = obj.y_offs_setup,
                txt = '',
                col = 'white',
                state = 0,
                is_but = true,
                alpha_back = 0.05,
                func_LD2 =  function() 
                            local x_st,y_st,w_st,h_st = obj.XYpad.x, obj.XYpad.y, obj.XYpad.w, obj.XYpad.h
                            X = lim((mouse.mx-x_st) / w_st,0,1)
                            Y = 1-lim((mouse.my-y_st) / h_st,0,1)
                            V1 = (1-X)*Y
                            V2 = X*Y
                            V3 = (1-Y)*(1-X)
                            V4 = X*(1-Y)
                            SetValue(V1, 1)
                            SetValue(V2, 2)
                            SetValue(V3, 3)
                            SetValue(V4, 4)
                            redraw = 1
                          end                        
                }
    obj.par_id_pad_1 = { x = 0,
                    y = obj.y_offs_setup,
                    w = obj.id_w,
                    h = obj.id_w,
                    txt = 1,
                    col = 'white',
                    state = 0,
                    is_but = true,
                    rect_a = 0.1,
                    alpha_back = 0.01                 
                    }  
    obj.par_id_pad_2 = { x = gfx.w-obj.id_w,
                    y = obj.y_offs_setup,
                    w = obj.id_w,
                    h = obj.id_w,
                    txt =2,
                    col = 'white',
                    state = 0,
                    is_but = true,
                    rect_a = 0.1,
                    alpha_back = 0.01                 
                    } 
    obj.par_id_pad_3 = { x = gfx.w-obj.id_w,
                    y = gfx.h-obj.id_w,
                    w = obj.id_w,
                    h = obj.id_w,
                    txt =4,
                    col = 'white',
                    state = 0,
                    is_but = true,
                    rect_a = 0.1,
                    alpha_back = 0.01                 
                    }     
    obj.par_id_pad_4 = { x = 0,
                    y = gfx.h-obj.id_w,
                    w = obj.id_w,
                    h = obj.id_w,
                    txt =3,
                    col = 'white',
                    state = 0,
                    is_but = true,
                    rect_a = 0.1,
                    alpha_back = 0.01                 
                    }                                                          
    local h = obj.y_offs_setup/4

    for i = 1, 4 do
      obj['par_id'..i] = { x = 0,
                  y = h*(i-1),
                  w = obj.id_w,
                  h = h,
                  txt = i,
                  col = 'white',
                  state = 0,
                  is_but = true,
                  alpha_back = 0.15                    
                  }       
                 
      obj['par'..i] = { x = obj.id_w,
                  y = h*(i-1),
                  w = 200,
                  h = h,
                  txt = '',
                  col = 'white',
                  state = 0,
                  is_but = true,
                  alpha_back = 0.15                    
                  }    
      obj['learn'..i] = { 
                  y = h*(i-1),
                  w = obj.lrn_w,
                  h = h,
                  txt = 'Get',
                  col = 'white',
                  state = 0,
                  is_but = true,
                  alpha_back = 0.1,
                  func = function() GetLearn(i) ExtStateProj_Save() redraw = 1 end }                 
    end
                      
  end
  ---------------------------------------------------
  function OBJ_Update()
    obj.XYpad.w = gfx.w
    obj.XYpad.h = gfx.h-obj.y_offs_setup
    for i = 1, 4 do
      obj['par'..i].x = obj.id_w+1
      obj['par'..i].w = gfx.w - obj.lrn_w -2 -obj.id_w
      obj['learn'..i].x = gfx.w - obj.lrn_w
    end
    if data.values then 
      for i = 1, 4 do
        if data.values[i] then 
          obj['par'..i].txt = data.values[i].fx_name..' / '..data.values[i].param_name
          obj['par'..i].val = data.values[i].val_readout
        end
      end
    end
    obj.par_id_pad_2.x = gfx.w-obj.id_w
    obj.par_id_pad_4.y = gfx.h-obj.id_w
    obj.par_id_pad_3.x = gfx.w-obj.id_w
    obj.par_id_pad_3.y = gfx.h-obj.id_w
    for key in pairs(obj) do if type(obj[key]) == 'table' then obj[key].context = key end end  
  end
  ---------------------------------------------------
  function Menu(t)
    gfx.x = mouse.mx
    gfx.y = mouse.my
    local ret = gfx.showmenu('')
  end
 ---------------------------------------------------
  function MOUSE_Match(b) if b.x and b.y and b.w and b.h then return mouse.mx > b.x and mouse.mx < b.x+b.w and mouse.my > b.y and mouse.my < b.y+b.h end  end
 ------------- -------------------------------------- 
  local function MOUSE_Click(b) return MOUSE_Match(b) and mouse.LMB_state and not mouse.last_LMB_state end
  local function MOUSE_ClickR(b) return MOUSE_Match(b) and mouse.RMB_state and not mouse.last_RMB_state end
  ---------------------------------------------------
  function spairs(t, order) --http://stackoverflow.com/questions/15706270/sort-a-table-in-lua
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end
    if order then table.sort(keys, function(a,b) return order(t, a, b) end)  else  table.sort(keys) end
    local i = 0
    return function()
              i = i + 1
              if keys[i] then return keys[i], t[keys[i]] end
           end
  end
  ---------------------------------------------------
  local function MOUSE()
    local d_click = 0.2
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
    
    if mouse.last_mx and mouse.last_my and (mouse.last_mx ~= mouse.mx or mouse.last_my ~= mouse.my) then mouse.is_moving = true else mouse.is_moving = false end
    if mouse.last_wheel then mouse.wheel_trig = (mouse.wheel - mouse.last_wheel) end 
    if not mouse.LMB_state_TS then mouse.LMB_state_TS = clock end
    if mouse.LMB_state and mouse.LMB_state_TS and clock -mouse.LMB_state_TS < d_click and clock -mouse.LMB_state_TS  > 0 then  mouse.DLMB_state = true  end 
    if mouse.LMB_state and not mouse.last_LMB_state then  
      mouse.last_mx_onclick = mouse.mx     
      mouse.last_my_onclick = mouse.my 
      mouse.LMB_state_TS = clock
    end    
    if mouse.last_mx_onclick and mouse.last_my_onclick then mouse.dx = mouse.mx - mouse.last_mx_onclick  mouse.dy = mouse.my - mouse.last_my_onclick else mouse.dx, mouse.dy = 0,0 end
    

    -- buttons
      for key in spairs(obj) do
        if type(obj[key]) == 'table' and not obj[key].ignore_mouse then
          --[[----------------------
          if MOUSE_Match(obj[key]) and obj[key].mouse_overlay then 
            if mouse.LMB_state and not mouse.last_LMB_state and MOUSE_Match(obj[key]) then if obj[key].func then  obj[key].func() end end
          end]]
          ------------------------
          if MOUSE_Match(obj[key]) then mouse.context = key end
          if MOUSE_Match(obj[key]) and mouse.LMB_state and not mouse.last_LMB_state then mouse.context_latch = key end
          
          if mouse.LMB_state 
            and not mouse.last_LMB_state 
            and not mouse.Ctrl_state  
            and MOUSE_Match(obj[key]) then 
            if obj[key].func then  obj[key].func() 
          end end
          
          if mouse.LMB_state 
            and not mouse.last_LMB_state 
            and not mouse.Ctrl_state  
            and mouse.DLMB_state 
            and MOUSE_Match(obj[key]) then 
            if obj[key].func_DC then obj[key].func_DC() 
          end end
          
          if mouse.LMB_state 
            and not mouse.Ctrl_state 
            and (mouse.context == key or mouse.context_latch == key) then 
            if obj[key].func_LD then obj[key].func_LD() end 
          end
          
          if mouse.LMB_state 
            and not mouse.Ctrl_state 
            and mouse.is_moving
            and mouse.context_latch == key then 
            if obj[key].func_LD2 then obj[key].func_LD2() end 
          end
          
          if mouse.Ctrl_LMB_state 
            and (mouse.context == key or mouse.context_latch == key) then 
            if obj[key].func_ctrlLD then obj[key].func_ctrlLD() 
          end end
          
          if mouse.RMB_state 
            and  (mouse.context == key or mouse.context_latch == key) then 
            if obj[key].func_RD then obj[key].func_RD() 
          end end
          
          if mouse.RMB_state 
            and  mouse.context == key 
              and not mouse.last_RMB_state then 
              if obj[key].func_R then obj[key].func_R() 
          end end
            
          if mouse.wheel_trig 
            and mouse.wheel_trig ~= 0 
            and mouse.Ctrl_state then 
            if obj[key].func_wheel then obj[key].func_wheel(mouse.wheel_trig) 
          end end
        end
      end
          
    
    -- mouse release    
      if mouse.last_LMB_state and not mouse.LMB_state   then  mouse.context_latch = '' end
      mouse.last_mx = mouse.mx
      mouse.last_my = mouse.my
      mouse.last_LMB_state = mouse.LMB_state  
      mouse.last_RMB_state = mouse.RMB_state
      mouse.last_MMB_state = mouse.MMB_state 
      mouse.last_Ctrl_LMB_state = mouse.Ctrl_LMB_state
      mouse.last_Ctrl_state = mouse.Ctrl_state
      mouse.last_Alt_state = mouse.Alt_state
      mouse.last_wheel = mouse.wheel   
      mouse.last_context_latch = mouse.context_latch
      mouse.DLMB_state = nil    
  end
  ---------------------------------------------------
  function run()
    SCC =  GetProjectStateChangeCount( 0 ) 
    if not lastSCC or lastSCC ~= SCC then SCC_trig = true else SCC_trig = false end lastSCC = SCC
    local clock = os.clock()
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
                font = 'Calibri',
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
  function GetFXIDbyGUID(tr, guid)
    for fx =1,  TrackFX_GetCount( tr ) do
      local fx_guid = TrackFX_GetFXGUID( tr, fx-1 )--:gsub('-',''):match('{.-}')
      if fx_guid == guid then return fx-1 end
    end
    return -1
  end
  ---------------------------------------------------
  function ExtStateProj_Save()
    if not data.values then return end
    local str = ''
    for key in pairs(data.values) do
      str = str..key..'_'..data.values[key].trGUID..'_'..data.values[key].fxGUID..'_'..data.values[key].param..'\n'
    end
    --msg(str)
    SetProjExtState( 0, conf.ES_key, 'FX_data', str )
  end
  ---------------------------------------------------
  function ExtStateProj_Load()
    local ret, str = GetProjExtState( 0, conf.ES_key, 'FX_data' )
    if ret ~= 1 then return end
    for line in str:gmatch('[^\r\n]+') do 
      local t = {} 
      for w in line:gmatch('[^_]+') do if tonumber(w) then w =  tonumber(w) end t[#t+1] = w end
      if #t == 4 then
        if not data.values then data.values = {} end
        data.values[  t[1] ] = {trGUID = t[2],
                                fxGUID = t[3],
                                param = t[4],
                                }
      end
    end
  end
  ---------------------------------------------------
  ExtState_Load()  
  gfx.init('MPL '..scr_title,300,400, 0, conf.wind_x, conf.wind_y)
  OBJ_define()
  OBJ_Update()
  GUI_define()
  ExtStateProj_Load()
  run()
  
  