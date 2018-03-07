-- @description Note selector
-- @about
--    MPL: code snippets based on juliansader work https://forum.cockos.com/member.php?u=14710
-- @version 0.1alpha
-- @author juliansader, MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init release



  --  INIT -------------------------------------------------
  for key in pairs(reaper) do _G[key]=reaper[key]  end  
  local mouse = {}
  local obj = {}
  local conf = {}
  local cycle_cnt = 0
  local redraw = -1
  local SCC, lastSCC, SCC_trig,ProjState, clock
  ---------------------------------------------------
  function msg(s)  ShowConsoleMsg(s..'\n') end
  ---------------------------------------------------
  function HasWindXYWHChanged()
    local dock, wx,wy,ww,wh = gfx.dock(-1, 0,0,0,0)
    local retval=0
    if wx ~= last_gfxx or wy ~= last_gfxy then retval= 2 end --- minor
    if ww ~= last_gfxw or wh ~= last_gfxh or dock ~= last_dock then retval= 1 end --- major
    if not last_gfxx then retval = -1 end
    last_gfxx, last_gfxy, last_gfxw, last_gfxh, last_dock = wx,wy,ww,wh,dock
    return retval
  end
  ---------------------------------------------------
  function lim(val, min,max) --local min,max 
    if not min or not max then min, max = 0,1 end 
    return math.max(min,  math.min(val, max) ) 
  end
  ---------------------------------------------------
  function ExtState_Save()
    _, conf.wind_x, conf.wind_y, conf.wind_w, conf.wind_h = gfx.dock(-1, 0,0,0,0)
    for key in pairs(conf) do SetExtState(conf.ES_key, key, conf[key], true)  end
  end
  ---------------------------------------------------
  function ExtState_Def()
    return {ES_key = 'MPL_MIDIsel',
            scr_title = 'MIDI note selector',
            wind_x =  50,
            wind_y =  50,
            wind_w =  300,
            wind_h =  90,
            dock2 =    513, --second
            GUI_font1 = 17,
            GUI_font2 = 15,
            GUI_colortitle =      16768407, -- blue
            GUI_background_col =  16777215, -- white
            GUI_background_alpha = 0.20,
            
            param_selectNnote = 0, -- selecte every N note
            param_noteOnppqtol = 0,    -- if noteons are (almost) on same position
            }
  end

  ---------------------------------------------------
  function GUI_col(col_s, obj) 
    if type(col_s) == 'string' then 
      if obj and obj.col and col_s and obj.col[col_s] then 
        gfx.set( table.unpack(obj.col[col_s]))  
      end   
     else
      local rOut, gOut, bOut = ColorFromNative(col_s)
      gfx.set(rOut/255, gOut/255, bOut/255)
      if GetOS():match('OSX') then gfx.set(bOut/255, gOut/255, rOut/255) end
    end
  end
    ---------------------------------------------------
  function GUI_DrawObj(o, obj)

    if not o then return end
    local x,y,w,h = o.x, o.y, o.w, o.h
    if not x or not y or not w or not h then return end
    
    -- glass back
      gfx.a = o.frame_a
      gfx.blit( 2, 1, math.rad(180), -- grad back
                0,0,  obj.grad_sz,obj.grad_sz,
                x,y,w,h, 0,0)
                
    -- fr rect
      if o.frame_rect_a then
        gfx.set(1,1,1,o.frame_rect_a)
        gfx.rect(x+1,y+1,w-2,h-2,0)
      end
    
    -- state
      if o.state then
        if o.state_col then GUI_col(o.state_col, obj) end
        gfx.a = 0.49
        gfx.rect(x,y,w,h,1)        
      end
      
    -- slider
      if o.is_slider and o.val then 
        local val = o.val
        if o.slider_a then gfx.a =  o.slider_a end
        if o.sider_col then GUI_col(o.sider_col, obj) end
        if not o.centered_slider then 
          val = lim(val,0,1)
          gfx.rect(x,y,w*val,h,1)
         else
          val = lim(val,-1,1)
          if val > 0 then 
            local w2 = val*w/2
            gfx.rect(x+w/2,y,w2,h,1)
           else 
            local w2 = math.abs(val*w/2)
            gfx.rect(x+w/2-w2,y,w2,h,1)
          end
        end
      end
      
    -- knob
      if o.is_knob then GUI_knob(o, obj) end
      
    -- text 
      local txt
      if not o.txt then txt = '' else txt = tostring(o.txt) end
      --if not o.txt then txt = '>' else txt = o.txt..'|' end
      ------------------ txt
        if txt and w > 0 then 
          if o.txt_col then GUI_col(o.txt_col, obj)else GUI_col('white', obj) end
          if o.txt_a then gfx.a = o.txt_a else gfx.a = 0.8 end
          gfx.setfont(1, obj.font, o.fontsz or obj.fontsz )
          local shift = 5
          local cnt = 0
          for line in txt:gmatch('[^\r\n]+') do cnt = cnt + 1 end
          local com_texth = gfx.texth*cnt
          local i = 0
          local reduce1, reduce2 = 2, nil
          if o.aligh_txt and o.aligh_txt&8==8 then reduce1, reduce2 = 0,-2 end
          for line in txt:gmatch('[^\r\n]+') do
            if gfx.measurestr(line:sub(2)) > w -5 and w > 20 then 
              repeat line = line:sub(reduce1, reduce2) until gfx.measurestr(line..'...') < w -5
              if o.aligh_txt and o.aligh_txt&8==8 then line = line..'...'
                else line = '...'..line end
            end
            gfx.x = x+ math.ceil((w-gfx.measurestr(line))/2)
            gfx.y = y+ h/2 - com_texth/2 + i*gfx.texth-1
            if o.aligh_txt then
              if o.aligh_txt&1==1 then gfx.x = x + shift  end -- align left
              if o.aligh_txt&2==2 then gfx.y = y + i*gfx.texth end -- align top
              if o.aligh_txt&4==4 then gfx.y = h - com_texth+ i*gfx.texth-shift end -- align bot
              if o.aligh_txt&8==8 then gfx.x = x + w - gfx.measurestr(line) - shift end -- align right
            end
            gfx.drawstr(line)
            --shift = shift + gfx.texth
            i = i + 1
          end
        end                
              
  end  
  ---------------------------------------------------
  function GUI_Main(obj, cycle_cnt, redraw, data, clock)
    gfx.mode = 0
    -- redraw: -1 init, 1 maj changes, 2 minor changes
    -- 1 back
    -- 2 gradient
    
    -- init grad buf on first loop
      if cycle_cnt == 1 then redraw = -1 end
    
    --  init
      if redraw == -1  then
        gfx.dest = 2
        gfx.setimgdim(2, -1, -1)  
        gfx.setimgdim(2, obj.grad_sz,obj.grad_sz)  
        local r,g,b,a = 0.9,0.9,1,0.6
        gfx.x, gfx.y = 0,0
        local c = 1
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
      
      
      
      local buf_dest = 10
      if redraw == 1 then
        -- refresh backgroung
          gfx.dest = buf_dest
          gfx.setimgdim(buf_dest, -1, -1)          
          gfx.setimgdim(buf_dest, gfx.w, gfx.h) 
        -- refresh all buttons
          if obj.b then for key in spairs(obj.b) do GUI_DrawObj(obj.b[key], obj) end end
          
      end
            
      gfx.dest = -1   
    ----  render    
      
      gfx.a = 1
    --  backgr
      --gfx.set(1,1,1,0.18)
      GUI_col(obj.background_col)
      gfx.a = obj.background_alpha
      gfx.rect(0,0,gfx.w,gfx.h, 1)
          
    -- butts  
      gfx.a = 1
      gfx.blit(10, 1, 0,
          0,0,gfx.w, gfx.h,
          0,0,gfx.w, gfx.h, 0,0)  
      
    gfx.update()
  end
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
  function ExtState_Load()
    local def = ExtState_Def()
    for key in pairs(def) do 
      local es_str = GetExtState(def.ES_key, key)
      if es_str == '' then conf[key] = def[key] else conf[key] = tonumber(es_str) or es_str end
    end
  end
  ---------------------------------------------------
  function Obj_init(conf)  
    local obj = { aa = 1,
                  mode = 0,
                  
                  font = 'Calibri',
                  fontsz = conf.GUI_font1,
                  fontsz_entry = conf.GUI_font2,
                  col = { grey =    {0.5, 0.5,  0.5 },
                          white =   {1,   1,    1   },
                          red =     {1,   0.3,    0.3   },
                          green =   {0.3, 0.9,  0.3 },
                          greendark =   {0.2, 0.4,  0.2 },
                          blue  =   {0.5, 0.9,  1}},
                  background_col = conf.GUI_background_col,
                  background_alpha = conf.GUI_background_alpha,
                  frame_a_entry = 0.9,
                  frame_rect_a_entry = 0.05,
                  
                  txt_a = 0.85,
                  txt_col_header = conf.GUI_colortitle,
                  txt_col_toolbar ='white', 
                  
                  grad_sz = 200,
                  b = {},             -- buttons table
                  
                  offs= 2,
                  but_w = 150,
                  but_w2 = 40,
                  but_w3 = 70,
                  but_h = 25
                  
          }
    if GetOS():match('OSX') then 
      obj.fontsz = obj.fontsz - 5
      obj.fontsz_entry = obj.fontsz_entry - 5
    end
    return obj             
  end
  ---------------------------------------------------
  function Menu(t)
    gfx.x = mouse.mx
    gfx.y = mouse.my
    local ret = gfx.showmenu('')
  end
  -------------------------------------------------
  function MOUSE_Match(mouse, b) return b.x and b.y and b.w and b.h and mouse.x > b.x and mouse.x < b.x+b.w and mouse.y > b.y and mouse.y < b.y+b.h end 
  ---------------------------------------------------
  function MOUSE(obj,mouse, clock, redraw)
    mouse.x = gfx.mouse_x
    mouse.y = gfx.mouse_y
    mouse.LB_gate = gfx.mouse_cap&1 == 1
    mouse.RB_gate = gfx.mouse_cap&2 == 2
    mouse.wheel = gfx.mouse_wheel
    mouse.LB_trig = not mouse.LB_gate_last and mouse.LB_gate
    mouse.RB_trig = not mouse.RB_gate_last and mouse.RB_gate
    mouse.LB_release = mouse.LB_gate_last and not mouse.LB_gate
    mouse.RB_release = mouse.RB_gate_last and not mouse.RB_gate
    mouse.Ctrl = gfx.mouse_cap&4==4
    mouse.Shift = gfx.mouse_cap&8==8
    mouse.Alt = gfx.mouse_cap&16==16
    mouse.on_move = mouse.last_x and (mouse.last_x ~= mouse.x or mouse.last_y ~= mouse.y )
    -- perf doubleclick
      mouse.LDC = mouse.LB_trig and mouse.LB_trig_TS and clock - mouse.LB_trig_TS < 0.3 
      if mouse.LB_trig then mouse.LB_trig_TS = clock end
    
    -- dy drag
      if mouse.LB_trig or mouse.LB_release then 
        mouse.x_latch = mouse.x
        mouse.y_latch = mouse.y
        mouse.dy = 0
        mouse.dx = 0
      end    
      if mouse.LB_gate then 
        mouse.dx = mouse.x_latch - mouse.x 
        mouse.dy = mouse.y_latch - mouse.y 
      end
    
    -- wheel
      if mouse.wheel_last then 
        if mouse.wheel_last ~= mouse.wheel then 
          if mouse.wheel_last - mouse.wheel < 0 then mouse.wheel_trig = 1 else mouse.wheel_trig = -1 end
         else
          mouse.wheel_trig = 0
        end
      end
      
    -- loop buttons --------------
      if obj.b then
        for key in pairs(obj.b) do
          if not obj.b[key].ignore_mouse then
            if MOUSE_Match(mouse, obj.b[key]) and obj.b[key].func_wheel and mouse.wheel_trig ~= 0 then obj.b[key].func_wheel() end
            if mouse.LB_trig and MOUSE_Match(mouse, obj.b[key]) then mouse.context_latch = key end
            
            if mouse.LB_trig and MOUSE_Match(mouse, obj.b[key]) and obj.b[key].func then obj.b[key].func() end
            
            if mouse.RB_trig and MOUSE_Match(mouse, obj.b[key]) and obj.b[key].func_R then obj.b[key].func_R() end
            if mouse.LB_gate and not mouse.Alt and mouse.on_move and mouse.context_latch == key and obj.b[key].func_drag then obj.b[key].func_drag() end
            if mouse.LB_gate and mouse.on_move and mouse.Ctrl and mouse.context_latch == key and obj.b[key].func_drag_Ctrl then obj.b[key].func_drag_Ctrl() end
            if mouse.LDC and MOUSE_Match(mouse, obj.b[key]) and obj.b[key].func_DC then obj.b[key].func_DC() end
          end   
        end     
      end
    
    -- out states
      local SCC_trig2
      mouse.wheel_last = mouse.wheel
      mouse.LB_gate_last = mouse.LB_gate
      mouse.RB_gate_last = mouse.RB_gate
      mouse.last_x = mouse.x
      mouse.last_y = mouse.y
      
    -- act onrelease
      if mouse.LB_release then 
        -- loop buttons
          if obj.b then
            for key in pairs(obj.b) do
              if not obj.b[key].ignore_mouse then
                if mouse.context_latch == key and obj.b[key].func_onRelease then obj.b[key].func_onRelease() break end
              end
            end
          end
        mouse.context_latch = nil 
        mouse.LDC = nil 
        mouse.temp_val = nil    -- latch drag
        mouse.temp_val2 = nil   -- table controls size
        mouse.temp_val3 = nil   -- last good value
        SCC_trig2 = true
        Main_OnCommand(NamedCommandLookup('_SN_FOCUS_MIDI_EDITOR'),0)
        
       else
        SCC_trig2 = false
      end
      
      return SCC_trig2
  end  
  ----------------------------------------------------
  function Obj_Update(data, mouse, obj, conf)
    -- selecte every note
    obj.b.setnotes = { x = obj.offs,
                            y = obj.offs,
                            w = obj.but_w,
                            h = obj.but_h,
                            fontsz = obj.fontsz,
                            frame_a = obj.frame_a_entry,
                            frame_rect_a = obj.frame_rect_a_entry,
                            txt_a = obj.txt_a,
                            txt = 'Select every'}
    obj.b.setnotes2 = { x = obj.offs*2+obj.but_w,
                            y = obj.offs,
                            w = obj.but_w2,
                            h = obj.but_h,
                            fontsz = obj.fontsz,
                            frame_a = obj.frame_a_entry,
                            frame_rect_a = obj.frame_rect_a_entry,
                            txt_a = obj.txt_a,
                            txt = conf.param_selectNnote ,
                            func =  function() 
                                      mouse.temp_val = conf.param_selectNnote
                                      redraw = 1 
                                    end,
                            func_drag = function() 
                                          if not mouse.temp_val then return end
                                          local mouse_shift = 0
                                          conf.param_selectNnote = lim(math.floor(mouse.temp_val + mouse.dy/10), 0, 16 )
                                          
                                          ExtState_Save(conf)
                                          redraw = 2
                                        end,
                            func_wheel = function() 
                                          conf.param_selectNnote = lim(math.floor(conf.param_selectNnote + mouse.wheel_trig), 0, 16 )                                          
                                          ExtState_Save(conf)
                                          APP_SetMIDIData(conf)
                                          redraw = 2
                                        end,                                        
                            func_onRelease = function () APP_SetMIDIData(conf)  end
                        }
    obj.b.setnotes3 = { x = obj.offs*3+obj.but_w+obj.but_w2,
                            y = obj.offs,
                            w = obj.but_w3,
                            h = obj.but_h,
                            fontsz = obj.fontsz,
                            frame_a = obj.frame_a_entry,
                            frame_rect_a = obj.frame_rect_a_entry,
                            txt_a = obj.txt_a,
                            txt = 'note'} 
    -- ppq tolerance 
    local ppqtol_y_offs = obj.offs*2 + obj.but_h
    obj.b.ppqtol = { x = obj.offs,
                            y = ppqtol_y_offs,
                            w = obj.but_w,
                            h = obj.but_h,
                            fontsz = obj.fontsz,
                            frame_a = obj.frame_a_entry,
                            frame_rect_a = obj.frame_rect_a_entry,
                            txt_a = obj.txt_a,
                            txt = 'PPQ tolerance (ticks)'}
    obj.b.ppqtol2 = { x = obj.offs*2+obj.but_w,
                            y = ppqtol_y_offs,
                            w = obj.but_w2,
                            h = obj.but_h,
                            fontsz = obj.fontsz,
                            frame_a = obj.frame_a_entry,
                            frame_rect_a = obj.frame_rect_a_entry,
                            txt_a = obj.txt_a,
                            txt = conf.param_noteOnppqtol ,
                            func =  function() 
                                      mouse.temp_val = conf.param_noteOnppqtol
                                      redraw = 1 
                                    end,
                            func_drag = function() 
                                          if not mouse.temp_val then return end
                                          local mouse_shift = 0
                                          conf.param_noteOnppqtol = lim(math.floor(mouse.temp_val + mouse.dy/0.5), 0, 960 )
                                          
                                          ExtState_Save(conf)
                                          redraw = 2
                                        end,
                            func_wheel = function() 
                                          conf.param_noteOnppqtol = lim(math.floor(conf.param_noteOnppqtol + mouse.wheel_trig*10), 0, 960 )                                          
                                          ExtState_Save(conf)
                                          APP_SetMIDIData(conf)
                                          redraw = 2
                                        end,                                        
                            func_onRelease = function () APP_SetMIDIData(conf)  end
                        }                            
                            
                                                                                
  end    
  --------------------------------------------------------------------
  function DataUpdate(data, mouse, obj, conf)
  end
  --------------------------------------------------------------------
  function Run()
    -- global clock/cycle
      clock = os.clock()
      cycle_cnt = cycle_cnt+1      
    -- check is something happen 
      SCC =  GetProjectStateChangeCount( 0 )       
      SCC_trig = (lastSCC and lastSCC ~= SCC) or cycle_cnt == 1
      lastSCC = SCC      
      local ret =  HasWindXYWHChanged() 
      if ret == 1 then  redraw = 2  ExtState_Save(conf)  elseif ret == 2 then  ExtState_Save(conf)  end
    -- perf mouse
      local SCC_trig2 = MOUSE(obj,mouse, clock) 
    -- produce update if yes
      if redraw == 2 or SCC_trig2 then 
        DataUpdate(data, mouse, obj, conf)
        Obj_Update(data, mouse, obj, conf)
        redraw = 1 
      end
      if SCC_trig then 
        DataUpdate(data, mouse, obj, conf)
        Obj_Update(data, mouse, obj, conf)
        redraw = 1      
      end
    -- perf GUI 
      GUI_Main(obj, cycle_cnt, redraw, data, clock)
      redraw = 0 
    -- defer cycle   
      if gfx.getchar() >= 0 and not force_exit then defer(Run) else atexit(gfx.quit) end  
  end
  ---------------------------------------------------
  function APP_SetMIDIData(conf) -- based on code snippets by juliansader work https://forum.cockos.com/member.php?u=14710
    local ME = MIDIEditor_GetActive()
    if not ME then return end
    local take =  MIDIEditor_GetTake( ME )   
    if not take then return end
    local tableEvents = {}
    local t = 0 -- Table key
    local gotAllOK, MIDIstring = MIDI_GetAllEvts(take, "")
    local MIDIlen = MIDIstring:len()
    local stringPos = 1 -- Position inside MIDIstring while parsing
    local offset, flags, msg
    
    local note_cnt = 0
    local pitch_t = {}
    local everynote = conf.param_selectNnote
    local noteOn_ppq_tol = conf.param_noteOnppqtol
    
    
    while stringPos < MIDIlen-12 do -- -12 to exclude final All-Notes-Off message
      offset, flags, msg, stringPos = string.unpack("i4Bs4", MIDIstring, stringPos)
      flags = 0
      if msg:byte(1)>>4 == 0x9  then  -- if noteOn        
        note_cnt = note_cnt + 1 
        if last_is_noteOn and offset < noteOn_ppq_tol then note_cnt = note_cnt - 1 end
        last_is_noteOn = true
        
        if everynote < 1 then 
          flags = 0
         else 
          if (note_cnt % everynote) == 0 then 
            pitch_t[msg:byte(2)] = true
            flags = 1
          end
        end
       else 
        last_is_noteOn = false
      end
      if msg:byte(1)>>4 == 0x8 then -- if noteOff
        if everynote < 1 then
          flags = 0
         else
          if pitch_t[msg:byte(2)] then 
            flags = 1
            pitch_t[msg:byte(2)] = nil
          end
        end
      end
      t = t + 1
      tableEvents[t] = string.pack("i4Bs4", offset, flags , msg)
    end
                
    MIDI_SetAllEvts(take, table.concat(tableEvents) .. MIDIstring:sub(-12))
    MIDI_Sort(take)    
  end 
  ---------------------------------------------------
  ExtState_Load()  
  gfx.init('MPL '..conf.scr_title,conf.wind_w, conf.wind_h, conf.dock, conf.wind_x, conf.wind_y)
  obj = Obj_init(conf)
  Run()
  APP_SetMIDIData(conf)
  