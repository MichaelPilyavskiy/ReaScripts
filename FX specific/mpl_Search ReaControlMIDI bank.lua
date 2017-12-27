-- @description Search ReaControlMIDI bank
-- @version 1.0alpha
-- @author MPL
-- @changelog
--   + Alpha release, it loops through all possible combinations (even if their real count not too much), so it FREEZE app for 5-20 seconds.
--   + This behaviour can be changed if devs implement API to get current opened reabank or ins file.
-- @website http://forum.cockos.com/showthread.php?t=188335

  local scr_title = 'Search ReaControlMIDI bank'
  for key in pairs(reaper) do _G[key]=reaper[key]  end  
  --NOT gfx NOT reaper
  local obj = {}
  local mouse = {}
  local textbox_t = {} 
  local alpha, char, last_char
  local t = {}
  ---------------------------------------------------------------------------------------
  function msg(s) reaper.ShowConsoleMsg(s..'\n') end
  ---------------------------------------------------------------------------------------    
  function TextBox(char)
    if not textbox_t.active_char then textbox_t.active_char = 0 end
    if not textbox_t.text        then textbox_t.text = '' end
     
    if char ==  1919379572 or char == 1818584692 then return end -- Ctrl+ArrLeft/Right
    
    if  -- regular input
        (
            (char >= 65 -- a
            and char <= 90) --z
            or (char >= 97 -- a
            and char <= 122) --z
            or ( char >= 212 -- A
            and char <= 223) --Z
            or ( char >= 48 -- 0
            and char <= 57) --Z
            or char == 95 -- _
            or char == 44 -- ,
            or char == 32 -- (space)
            or char == 45 -- (-)
        )
        then        
          textbox_t.text = textbox_t.text:sub(0,textbox_t.active_char)..
            string.char(char)..
            textbox_t.text:sub(textbox_t.active_char+1)
          textbox_t.active_char = textbox_t.active_char + 1
      end
      
      if char == 8 then -- backspace
        textbox_t.text = textbox_t.text:sub(0,textbox_t.active_char-1)..
          textbox_t.text:sub(textbox_t.active_char+1)
        textbox_t.active_char = textbox_t.active_char - 1
      end

      if char == 6579564 then -- delete
        textbox_t.text = textbox_t.text:sub(0,textbox_t.active_char)..
          textbox_t.text:sub(textbox_t.active_char+2)
        textbox_t.active_char = textbox_t.active_char
      end
            
      if char == 1818584692 then -- left arrow
        textbox_t.active_char = textbox_t.active_char - 1
      end
      
      if char == 1919379572 then -- right arrow
        textbox_t.active_char = textbox_t.active_char + 1
      end
      
    --[[if char == 13  then   -- enter
        -- RUN search for textbox_t.text
    end]]
    
    if textbox_t.active_char < 0 then textbox_t.active_char = 0 end
    if textbox_t.active_char > textbox_t.text:len()  then textbox_t.active_char = textbox_t.text:len() end
  end
  ---------------------------------------------------
  function GUI_DrawBut(_) 
    gfx.set(1,1,1,0.1)
    gfx.rect(_.x,_.y,_.w,_.h,1)
    gfx.a = 0.7
    if _.txt then 
      gfx.x = _.x+ obj.offs--(_.w-gfx.measurestr(_.txt))/2
      if _.fontsize then gfx.setfont(1, obj.fontname, _.fontsize) end
      gfx.y = _.y+ (_.h-gfx.texth)/2 + 1
      gfx.drawstr(_.txt)
    end
  end  
  ---------------------------------------------------------------------------------------  
  function GUI_draw()
    --  draw back
        gfx.set(  1,1,1,  0.2,  0) --rgb a mode
        gfx.rect(0,0,gfx.w,gfx.h,1)   
        
    --  draw frame
        gfx.set(  1,1,1,  0.1,  0) --rgb a mode
        gfx.rect(obj.offs,obj.offs,gfx.w-obj.offs*3,obj.frame_h ,1)   
        
    -- draw buttons
        for key in pairs(obj) do if type(obj[key]) == 'table' then GUI_DrawBut(obj[key]) end end  
                       
    gfx.update() 
  end
  --------------------------------------------------------------------------------------- 
  function TextGUI()
    -- draw text
      gfx.set(  1,1,1,  0.8,  0) --rgb a mode
      gfx.setfont(1, obj.fontname, obj.fontsize)
      gfx.x = obj.offs*2
      gfx.y = obj.offs
      gfx.drawstr(textbox_t.text) 
      
    -- active char
      if textbox_t.active_char ~= nil then
        gfx.set(  1,1,1, alpha,  0) --rgb a mode
        gfx.x = obj.offs*1.5+
                gfx.measurestr(textbox_t.text:sub(0,textbox_t.active_char))  
        gfx.y = obj.offs + obj.fontsize/2 - gfx.texth/2
        gfx.drawstr('|')
      end  
  end
  --------------------------------------------------------------------------------------- 
  function SearchReaBank()
    local str = textbox_t.text
    local cnt = 0
    for key in pairs(obj) do if key:match('it%d+') then obj[key] = nil end end
    for i =1, #t do
      if t[i].name:lower():find(textbox_t.text:lower()) then
        cnt = cnt + 1 
        obj['it'..i] = {x = obj.offs,
                        y = obj.frame_h + obj.item_h * cnt,
                        w = gfx.w - obj.offs*2,
                        h = obj.item_h,
                        txt = t[i].name,
                        fontsize = 16,
                        func_onLclick = function()
                                  SetBank(i)
                              end}
      end
    end
  end
  --------------------------------------------------- 
  function MOUSE_Match(b) 
    local xoffs, yoffs = 0,0
    if b.clear then 
      xoffs = obj.toolbar_w
      yoffs = obj.nav_panel_h
    end
    if b.x and b.y and b.w and b.h then 
      return 
        mouse.mx > b.x+xoffs 
        and mouse.mx < b.x+b.w+xoffs 
        and mouse.my > b.y+yoffs 
        and mouse.my < b.y+b.h+yoffs 
        --and (b.clear and mouse.mx  > obj.toolbar_w and mouse.mx  > obj.nav_panel_h  )
    end  
  end
  --------------------------------------------------- 
  function MOUSE()
    mouse.mx = gfx.mouse_x
    mouse.my = gfx.mouse_y
    mouse.dx, mouse.dy = 0,0
    mouse.LMB_state = gfx.mouse_cap&1 == 1 
    mouse.RMB_state = gfx.mouse_cap&2 == 2 
    mouse.MMB_state = gfx.mouse_cap&64 == 64
    mouse.Ctrl_LMB_state = gfx.mouse_cap&5 == 5 
    mouse.Ctrl_state = gfx.mouse_cap&4 == 4 
    mouse.Alt_state = gfx.mouse_cap&17 == 17 -- alt + LB
    mouse.wheel = gfx.mouse_wheel
    
    -- init dyn states 
      if not mouse.mx_latch then 
        mouse.mx_latch = mouse.mx
        mouse.my_latch = mouse.my
      end  
      if not mouse.onLclickTS then mouse.onLclickTS = clock end
      if not mouse.onLDclick then mouse.onLDclick = false end
    
    -- get base states
      mouse.onLclick = mouse.LMB_state and not mouse.last_LMB_state    
      mouse.onLDrag = mouse.LMB_state and mouse.last_LMB_state
      mouse.onLRelease = not mouse.LMB_state and mouse.last_LMB_state
    
    -- analyze state
      if not mouse.onLDrag then mouse.context_latch = '' end
      if mouse.onLclick then 
        mouse.onLDclick = mouse.onLclickTS and clock - mouse.onLclickTS < 0.2        
        mouse.onLclickTS = clock
        mouse.mx_latch = mouse.mx
        mouse.my_latch = mouse.my
      end
      if mouse.onLDrag then 
        mouse.dx = mouse.mx - mouse.mx_latch
        mouse.dy = mouse.my - mouse.my_latch
      end
    
    -- perform on GUI
    for key in spairs(obj) do 
      if type(obj[key]) == 'table' then
        
        if obj[key].func_onLclick and mouse.onLclick and MOUSE_Match(obj[key]) and not mouse.onLDclick then  
          obj[key].func_onLclick() 
          mouse.context_latch = key
          mouse.context_latch_xobj = obj[key].x
          mouse.context_latch_yobj = obj[key].y
          break 
        end
        if obj[key].func_onLDrag and mouse.onLDrag  and mouse.context_latch == key then 
          obj[key].func_onLDrag() 
          break 
        end
        if obj[key].func_onLDclick and mouse.onLDclick  and MOUSE_Match(obj[key])  then 
          obj[key].func_onLDclick() 
          break 
        end
        
      end
    end
    
    if mouse.onLRelease then 
      upd_data = true
      mouse.custom_val_latch = nil
    end
    mouse.onLDclick = false
    mouse.last_LMB_state = mouse.LMB_state
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
  ---------------------------------------------------------------------------------------        
  function Run()
      char  = gfx.getchar()      
      alpha  = math.abs((os.clock()%1) -0.5)
      
      GUI_draw()
      TextGUI()
      TextBox(char) -- perform typing
      
      if last_char and char > 0 and textbox_t.text  ~= '' then 
        SearchReaBank()
      end
      
      MOUSE()
      last_char = char
      if char ~= -1 and char ~= 27 and char ~= 13  then reaper.defer(Run) else reaper.atexit(gfx.quit) end
      
    end 

  ---------------------------------------------------------------------------------------
  function Lokasenna_WindowAtCenter(w, h)
    -- thanks to Lokasenna 
    -- http://forum.cockos.com/showpost.php?p=1689028&postcount=15    
    local l, t, r, b = 0, 0, w, h    
    local __, __, screen_w, screen_h = reaper.my_getViewport(l, t, r, b, l, t, r, b, 1)    
    local x, y = (screen_w - w) / 2, (screen_h - h) / 2    
    gfx.init(scr_title, w, h, 0)--, x, y)  
  end
  ---------------------------------------------------------------------------------------
  function OBJ_init()
    obj.mainW = 400
    obj.mainH = 300
    obj.offs = 10
    
    obj.fontname = 'Calibri'
    obj.fontsize = 23      
    obj.frame_h = obj.fontsize+obj.offs/2
    obj.item_h = 15
    obj.upd_w = 50
    --[[obj.upd = {x = 10, 
                y = obj.offs,
                w = obj.upd_w,
                h = obj.frame_h,
                txt = 'Upd'}]]
    
    if GetOS():match("OSX") then gui_fontsize = gui_fontsize - 7 end  
  end
  ---------------------------------------------------------------------------------------
  function GetReaControlBankData()
    local retval, tracknumberOut, _, fx = GetFocusedFX()
    local tr = CSurf_TrackFromID(tracknumberOut, false)
    local retval, buf = reaper.TrackFX_GetFXName( tr, fx, '' )
    if not buf:match('ReaControlMIDI') then return end
    
    
    -- get cur params
      _,cur_bankMSB = TrackFX_GetFormattedParamValue( tr, fx, 0, '' )
      _,cur_bankLSB = TrackFX_GetFormattedParamValue( tr, fx, 1, '' )
      _,cur_prog = TrackFX_GetFormattedParamValue( tr, fx, 2, '' )
      
    -- get table
    ClearConsole()
      t = {}
      TrackFX_SetParamNormalized( tr, fx, 1, 0 )
      for MSB = 0, 127 do
        TrackFX_SetParamNormalized( tr, fx, 0, MSB/127 )
        local retval, bankMSB = TrackFX_GetFormattedParamValue( tr, fx, 0, '' )
        for LSB = 0, 127 do
          TrackFX_SetParamNormalized( tr, fx, 1, LSB/127 )
          local retval, bankLSB = TrackFX_GetFormattedParamValue( tr, fx, 1, '' )

          for prog = 0, 127 do
            TrackFX_SetParamNormalized( tr, fx, 2, prog/127 )
            local retval, progstr = TrackFX_GetFormattedParamValue( tr, fx, 2, '' )
            --if not progstr:match('%d+')==progstr then
                  t[#t+1] = { msb = MSB/127,
                              lsb = LSB/127,
                              prog = prog/127,
                              name = progstr,
                              is_cur = (--cur_bankMSB==bankLSB
                                         cur_bankLSB==bankLSB
                                        and cur_prog==progstr)
                              
                            }
            --end
          end
        end
      end          

    for i = 1, #t do
      if t[i].is_cur then
        TrackFX_SetParamNormalized( tr, fx, 0, t[i].msb)
        TrackFX_SetParamNormalized( tr, fx, 1, t[i].lsb)
        TrackFX_SetParamNormalized( tr, fx, 2, t[i].prog)
      end
    end
            
    return true
      
  end
  ---------------------------------------------------------------------------------------  
  function SetBank(i)
    local retval, tracknumberOut, _, fx = GetFocusedFX()
    local tr = CSurf_TrackFromID(tracknumberOut, false)
    TrackFX_SetParamNormalized( tr, fx, 1, t[i].lsb)
    TrackFX_SetParamNormalized( tr, fx, 0, t[i].msb)
    TrackFX_SetParamNormalized( tr, fx, 2, t[i].prog)
  end
  --------------------------------------------------------------------------------------- 
  ret = GetReaControlBankData() 
  if ret then 
    OBJ_init()
    Lokasenna_WindowAtCenter(obj.mainW,obj.mainH)
    Run()
  end