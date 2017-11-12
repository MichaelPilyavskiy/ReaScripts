-- @description Comb-filtering check selected items
-- @version 1.05
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    + GUI
--    + Splitted selection reference take and dub takes

  sz = 2^11
  area = 0.1
  
  -- NOT gfx NOT reaper
  local scr_title = 'Comb-filtering check selected items'
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  --local dub_takes = {}
  ---------------------------------------------------
  function msg(s)  if not s then return end  ShowConsoleMsg(s..'\n')   end
------------------------------------------  
  function GetBuffer(it, sz, SR, shift)
    local tk = GetActiveTake(it)
    if TakeIsMIDI(tk) then return end
    local read_pos = GetCursorPosition() - shift
    local tr = GetMediaItemTake_Track( tk )
    local accessor = CreateTrackAudioAccessor( tr )
    local src = GetMediaItemTake_Source(tk)
    local numch = 1--GetMediaSourceNumChannels(src)
    local buffer = new_array(sz)--*numch )
    GetAudioAccessorSamples(
                           accessor,
                           SR,
                           1,--numch,
                           read_pos,
                           sz, -- numsamplesperchannel
                           buffer) --samplebuffer
                         
    DestroyAudioAccessor( accessor )
    if inv then for i = 1, sz do buffer[i] = - buffer[i] end end
    return buffer
  end
  ---------------------------------------------------
  function GetFFTSum(b1, b2, sz)
    local b = new_array(sz)
    for i = 1, sz do 
      b[i] = b1[i] + b2[i] 
    end
    b.fft_real(sz, true, 1)
    local t = b.table()
    local s = 0
    for i = 1, #t do s = s + math.abs(t[i]) end
    return  s
  end
  ---------------------------------------------------    
  function CalcOffset(it, area, ref_item_buf ,sz, SR)
    
    -- 1ms brutforce
      local t = {}
      local sum = 0 
      for shift = 0, area, 0.001 do
        local b2 = GetBuffer(it, sz, SR, shift)  
        sum  = GetFFTSum(ref_item_buf, b2, sz)
        t[#t+1] = sum
      end        
      shift_ms = GetMaxValIdx(t)
      if shift_ms < 0 then return end
      if not shift_ms then return end
      --for i = 1, #t do msg(t[i]) end
    -- 1spl brutforce
      local t2 = {}
      local sum2 = 0
      local spl_area = math.floor(SR/1000)*2
      for shift = 1, spl_area  do
        local b2 = GetBuffer(it, sz, SR, (shift_ms-1)/1000 + shift/SR)  
        sum2  = GetFFTSum(ref_item_buf, b2, sz)
        t2[#t2+1] = sum2      
      end
      shift_spl = GetMaxValIdx(t2)
      if not shift_spl then return end
      
    return (shift_ms-1)/1000 + shift_spl/SR
  end
  --------------------------------------------------- 
  function GetMaxValIdx(t) 
    if not t then return end
    local ret_id, max ,last_max= 0 , 0
    for i = 1, #t do
      max = math.max(t[i],max)
      if last_max and last_max < max then ret_id = i end
      last_max = max 
    end
    return ret_id
  end
  ---------------------------------------------------  
  function CombFiltCheck(sz,area) 
    local SR = tonumber(format_timestr_pos( 1, '', 4 ) )
    if not ref_item then return end
    local ref_item_buf = GetBuffer(ref_item, sz, SR, 0)
  
    for i =1 , #dub_takes do
      dub_it = dub_takes[i]
      if not dub_it then return end      
      local pos = GetMediaItemInfo_Value( dub_it, 'D_POSITION' )
      SetMediaItemInfo_Value( dub_it, 'D_POSITION', pos -area/2 )
      offs = CalcOffset(dub_it, area, ref_item_buf, sz, SR)
      SetMediaItemInfo_Value( dub_it, 'D_POSITION', pos + offs -area/2)
    end
  end

  --  INIT -------------------------------------------------
  local mouse = {}
  local gui -- see GUI_define()
  local obj = {}
  local conf = {}
  local cycle = 0
  local redraw = -1
  local SCC, lastSCC, SCC_trig,ProjState
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
    col(o.col, o.alpha_back or 0.2)
    gfx.rect(x,y,w,h,1)
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
      
    --  init
      if redraw == -1 then
        OBJ_Update()
        gfx.dest = 2
        gfx.setimgdim(2, -1, -1)  
        gfx.setimgdim(2, obj.grad_sz,obj.grad_sz)  
        local r,g,b,a = 0.9,0.9,1,0.6
        gfx.x, gfx.y = 0,0
        local c = 0.6
        local drdx = c*0.00001
        local drdy = c*0.00001
        local dgdx = c*0.00008
        local dgdy = c*0.0001    
        local dbdx = c*0.00008
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
      gfx.a = 1
      gfx.x,gfx.y = 0,0
    --  back
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
    return {ES_key = 'MPL_'..scr_title,
            wind_x =  50,
            wind_y =  50,
            wind_w =  430,
            wind_h =  150,
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
  local function OBJ_define()  
    obj.offs = 2
    obj.grad_sz = 200
    obj.item_h = math.floor(gfx.h/7)
    local h = gfx.h/3
    obj.get_ref = { x = 0,
                y = 0,
                w= gfx.w,
                h = h,
                txt = "1. Get reference take",
                col = 'white',
                state = 0,
                is_but = true,
                alpha_back = 0.2,
                func =  function() 
                          ref_item = GetSelectedMediaItem(0,0) 
                          if ref_item then 
                            obj.get_ref.txt = "1. Get reference take (done)" 
                            redraw = 1 
                          end
                        end}
    obj.get_dub = { x = 0,
                y = h,
                w= gfx.w,
                h = h,
                txt = "2. Get dub takes",
                col = 'white',
                state = 0,
                is_but = true,
                alpha_back = 0.2,
                func =  function() 
                          dub_takes = {}
                          for i =1 , CountSelectedMediaItems(0) do
                            local dub_it = GetSelectedMediaItem(0,i-1)
                            if not (ref_item and ref_item == dub_it) then
                              dub_takes[#dub_takes+1] = dub_it
                            end
                          end
                          
                          obj.get_dub.txt = '2. Get dub takes (done, '..#dub_takes..' found)'
                          redraw = 1 
                        end}    
    obj.match = { x = 0,
                y = 2*h,
                w= gfx.w,
                h = h,
                txt = "3. Put edit cursor at reference item transient and click",
                col = 'white',
                state = 0,
                is_but = true,
                alpha_back = 0.2,
                func =  function() CombFiltCheck(sz,area)  end}  
                
    --[[obj.options = { x = 0,
                y = gfx.h/2+2,
                w= gfx.w,
                h = gfx.h/4,
                txt = "OPtions",
                col = 'white',
                state = 0,
                is_but = true,
                alpha_back = 0.2,
                func =  function() 
                          
                        end} ]] 
                                                    
  end
  ---------------------------------------------------
  function OBJ_Update()

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
      if type(obj[key]) == 'table'and obj[key].is_but then
        if MOUSE_Click(obj[key]) then obj[key].func() end
      end
    end
          
    
    -- mouse release    
      if mouse.last_LMB_state and not mouse.LMB_state   then  mouse.context_latch = '' end
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
                font = 'Arial',
                fontsz = 18,
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
  gfx.init('MPL '..scr_title,conf.wind_w, conf.wind_h, conf.dock, conf.wind_x, conf.wind_y)
  OBJ_define()
  OBJ_Update()
  GUI_define()
  run()
  
  
  