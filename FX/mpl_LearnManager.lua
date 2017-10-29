-- @description LearnManager
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init
--    + Basic overview learned parameters and related parameter names
--    + Allow to load/overview default mapping for managed plugin


  local vrs = '1.0'  
  local scr_title = 'LearnManager'
  --NOT gfx NOT reaper
  --  INIT -------------------------------------------------
  for key in pairs(reaper) do _G[key]=reaper[key]  end  
  local mouse = {}
  data = {}
  local gui -- see GUI_define()
  local obj = {}
  local conf = {}
  local cycle = 0
  local redraw = -1
  local SCC, lastSCC, SCC_trig, clock,ProjState
  ---------------------------------------------------
  local gui = {
                aa = 1,
                mode = 3,
                fontname = 'Calibri',
                fontsz = 18,
                fontsz2 = 16,
                col = { grey =    {0.5, 0.5,  0.5 },
                        white =   {1,   1,    1   },
                        red =     {1,   0,    0   },
                        green =   {0.3,   0.9,    0.3   }
                      }
                
                }
    
  if GetOS():match('OSX') then 
    gui.fontsz = gui.fontsz - 7 
    gui.fontsz2 = gui.fontsz2 - 7 
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
  local function msg(s) if s then ShowConsoleMsg(s..'\n') end end
  ---------------------------------------------------
  local function col(col_s, a) gfx.set( table.unpack(gui.col[col_s])) if a then gfx.a = a end  end
  ---------------------------------------------------
  local function GUI_DrawBut(o) 
    if not o then return end
    local x,y,w,h, txt = o.x, o.y, o.w, o.h, o.txt
    if not x or not y or not w or not h then return end
    local txt_offs = 5
    gfx.a = o.alpha_back or 0.3
    gfx.blit( 2, 1, 0, -- grad back
              0,0,  obj.grad_sz,obj.grad_sz,
              x,y,w,h, 0,0)
    col(o.col, o.alpha_back or 0.2)
    gfx.rect(x,y,w,h,1)
    if o.txt then 
      col('white', o.alpha_txt or 0.8)
      gfx.setfont(1, gui.fontname, o.txtsz)
      gfx.x = x+ (w-gfx.measurestr(txt))/2
      if o.txt_align_left then gfx.x = x + txt_offs end
      if o.txt_align_right then gfx.x = x+ w - txt_offs - gfx.measurestr(txt) end
      gfx.y = y+ (h-gfx.texth)/2
      if o.txt_align_top then gfx.y = y + txt_offs end
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
          gfx.a = 0.2
          gfx.line(gfx.w/2, obj.item_h+obj.item_h2,gfx.w/2, gfx.h )
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
            wind_w =  400,
            wind_h =  300,
            dock =    0}
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
  function OBJ_define()  
    obj.offs = 2
    obj.grad_sz = 200
    obj.item_h = 40
    obj.item_h2 = 20
    
    obj.get = { x = 0,
                y = 0,
                h = obj.item_h,
                txt = "FocusedFX: Update info",
                col = 'white',
                state = 0,
                is_but = true,
                txtsz = gui.fontsz,
                alpha_back = 0.3,
                func =  function() 
                          UpdateInfo() 
                          ParseDefMap()
                          redraw = 1 
                          --data0 = {}
                          --obj.t2type.txt = '(no type selected)'                          
                        end}

    obj.t1type = { x = 0,
                y = obj.item_h + obj.item_h2,
                h = obj.item_h2,
                txt = "Current mapping",
                --txt_align_left = true,
                --txt_align_top = true,
                col = 'white',
                state = 0,
                is_but = true,
                txtsz = gui.fontsz2,
                alpha_back = 0.1}    
                
    obj.t2type = { x = 0,
                y = obj.item_h + obj.item_h2,
                h = obj.item_h2,
                txt = '(no type selected)',
                --txt_align_left = true,
                --txt_align_right = true,
                --txt_align_top = true,
                col = 'white',
                state = 0,
                is_but = true,
                txtsz = gui.fontsz2,
                alpha_back = 0.1,
                func = function()
                  Menu({  {str = 'Load default mapping',
                           func = function()                                    
                                    ParseDefMap()
                                    redraw = 1
                                  end
                          }
                        })
                        end}                   
                               
    obj.t1 = { x = 0,
                y = obj.item_h + obj.item_h2*2,
                h = gfx.h - obj.item_h - obj.item_h2*2,
                txt = "(no data)",
                txt_align_left = true,
                txt_align_top = true,
                col = 'white',
                state = 0,
                is_but = true,
                txtsz = gui.fontsz2,
                alpha_back = 0}    
                    
    obj.t2 = { 
                y = obj.item_h + obj.item_h2*2,
                h = gfx.h - obj.item_h - obj.item_h2*2,
                txt = "(no data)",
                txt_align_left = true,
                txt_align_top = true,
                col = 'white',
                state = 0,
                is_but = true,
                txtsz = gui.fontsz2,
                alpha_back = 0}                        
    
                      
  end
  ---------------------------------------------------
  function ParseDefMap()
    obj.t2type.txt = 'Default mapping'
    data0 = {lrn = {}}
    ClearConsole()
    if not data.FX_name then return end
    data0.FX_name = data.FX_name
    local ini_path = GetResourcePath()..'/reaper-fxlearn.ini'
    local f = io.open(ini_path, 'r')
    if not f then 
      return 
     else
      local context = f:read('a')
      local ini_str = context:match(literalize(data.FX_name)..'.-%[')
      if not ini_str then ini_str = context:match(literalize(data.FX_name)..'.*') end
      if not ini_str then return end
      for line in ini_str:gmatch('[^\r\n]+') do 
        if line:match('p[%d]+=') then 
          local t = {} 
          for csv in line:gmatch('[^%,%=]+') do t[#t+1] = csv end
          local par_idx = tonumber(t[2])
          if par_idx then
            local isMIDI = tonumber(t[3]) > 0
            local OSC_str, MIDI_Ch, MIDI_CC
            if not isMIDI then 
              OSC_str = t[5]
             else
              MIDI_Ch = 1 +t[3] & 0x0F
              MIDI_CC = t[3] >> 8  
            end
            data0.lrn[par_idx] = {OSC_str = OSC_str,
                              MIDI_Ch= MIDI_Ch,
                              MIDI_CC = MIDI_CC,
                              MIDI_int = tonumber(t[3])
                              }
          end
        end 
      end
      
      f:close()
    end
  end
  ---------------------------------------------------
  function OBJ_Update()
    if data.FX_name then
      obj.fxname = { x = 0,
              y = obj.item_h,
              w = gfx.w,
              h = obj.item_h2,
              col = 'white',   
              txtsz= gui.fontsz2,  
              txt=   data.FX_name or 'no data',  
              state = 0,
              is_but = true,
              alpha_back = 0.2} 
    end
    obj.get.w = gfx.w
    
    obj.t1type.w = math.floor(gfx.w/2)-1
    obj.t2type.x = math.floor(gfx.w/2)+1
    obj.t2type.w = math.floor(gfx.w/2)
    
    local str_cur_learn = GenerateButtonTxt(data)
    obj.t1.w = math.floor(gfx.w/2)
    obj.t1.txt = str_cur_learn
    
    local dest_learn = GenerateButtonTxt(data0)
    obj.t2.x = math.floor(gfx.w/2)
    obj.t2.w = math.floor(gfx.w/2)
    obj.t2.txt = dest_learn
  end
  ---------------------------------------------------
  function GenerateButtonTxt(t)
    if not t or not t.FX_name then return end
    local ind = ' '
    local str = ''
    for key in spairs(t.lrn) do
      str = str..'#'..key..' '..data.param_names[tonumber(key)]
      if t.lrn[key].OSC_str then
        str = str..':'..ind:rep(2)..'OSC '..t.lrn[key].OSC_str..'\n'
       elseif t.lrn[key].MIDI_Ch then
        str = str..':'..ind:rep(2)..'MIDI Channel '..t.lrn[key].MIDI_Ch..' CC '..t.lrn[key].MIDI_CC..'\n'
      end
    end
    return str
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
  function Menu(t)
    local str, check = '', ''
    for i = 1, #t do
      if t[i].state then check = '!' else check ='' end
      str = str..check..t[i].str..'|'
    end
    gfx.x = mouse.mx
    gfx.y = mouse.my
    local ret = gfx.showmenu(str)
    if ret > 0 then if t[ret].func then t[ret].func() end end
  end
  ---------------------------------------------------
  function UpdateInfo()
    -- get chunk data
      local retval, tracknumberOut, _, fxnumberOut = GetFocusedFX()
      if not retval or fxnumberOut < 0 then return end
      local track = CSurf_TrackFromID( tracknumberOut, false )
      local GUID = TrackFX_GetFXGUID( track, fxnumberOut )
      
      data= { FX_GUID = GUID,
              FX_id = fxnumberOut,
              FX_name = ({TrackFX_GetFXName( track, fxnumberOut, '' )})[2],
              TR_GUID = GetTrackGUID( track ),
              lrn = {},
              param_names = {}
              }
             
      for i = 1,  TrackFX_GetNumParams( track, fxnumberOut ) do
        data.param_names[ #data.param_names + 1 ]= ({TrackFX_GetParamName( track, fxnumberOut, i-1, '' )})[2]     
      end
      
      local _, tr_chunk = GetTrackStateChunk( track, '', false )
      local str = tr_chunk:match(literalize(GUID)..'(.-)>')
      if not str then return end
      for line in str:gmatch('[^\r\n]+') do
        if line:find('PARMLEARN') then
          local t = {}
          for val in line:gmatch('[^%s]+') do t[#t+1] = val end
          local par_idx = tonumber(t[2])
          local isMIDI = tonumber(t[3]) > 0
          local OSC_str, MIDI_Ch, MIDI_CC
          if not isMIDI then 
            OSC_str = t[5]
           else
            MIDI_Ch = 1 +t[3] & 0x0F
            MIDI_CC = t[3] >> 8  
          end
          data.lrn[par_idx] = {
                              OSC_str = OSC_str,
                              MIDI_Ch= MIDI_Ch,
                              MIDI_CC = MIDI_CC,
                              MIDI_int = tonumber(t[3])
                              }
        end
      end
    
    -- parse default mappings
  end
  ---------------------------------------------------
  function literalize(str) -- http://stackoverflow.com/questions/1745448/lua-plain-string-gsub
      return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", function(c) return "%" .. c end)
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
        if MOUSE_Click(obj[key]) and obj[key].func then obj[key].func() end
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
  ExtState_Load()  
  gfx.init('MPL '..scr_title..' v'..vrs,conf.wind_w, conf.wind_h, conf.dock, conf.wind_x, conf.wind_y)
  OBJ_define()
  OBJ_Update()
  UpdateInfo()
  ParseDefMap()
  run()
  
  
  
   --[[function TrackFX_GetSetMIDIOSCLearn(track_in, fx_index, param_id, is_set, string_midiosc)
   -- is_set == 0 - get
   -- is_set == -1 - remove all learn from pointed parameter
   
   -- return midichan,midicc, osclearn
   -- if in_chan == -1 then remove learn for current param
   if fx_index == nil then return end
   fx_index = fx_index+1 -- 0-based    
                 --param_id 0-based
                 
   local out_midi_num, chunk,exists, guid_id,chunk_t,i,fx_chunks_t,fx_count,
     fx_guid,param_count,active_fx_chunk,active_fx_chunk_old,active_fx_chunk_t,
     out_t,midiChannel,midiCC,insert_begin,insert_end,active_fx_chunk_new,main_chunk,temp_s
     
   if track_in == nil then reaper.ReaScriptError('MediaTrack not found') return end
   _, chunk = reaper.GetTrackStateChunk(track, '')      
   --reaper.ShowConsoleMsg(chunk)
   if reaper.TrackFX_GetCount(track) == 0 then reaper.ReaScriptError('There is no FX on track') return end
   if fx_index > reaper.TrackFX_GetCount(track) then reaper.ReaScriptError('FX index > Number of FX') return end
   -- get com table
     main_chunk = {}
     for line in chunk:gmatch("[^\n]+") do 
       table.insert(main_chunk, line)
     end
     
   -- get fx chunks
     chunk_t= {}
     temp_s = nil
     i = 1
     for line in chunk:gmatch("[^\n]+") do 
       if temp_s ~= nil then temp_s = temp_s..'\n'..line end
       if line:find('BYPASS') ~= nil then
         temp_s = i..'\n'..line
       end
       if line:find('WAK') ~= nil then  
         table.insert(chunk_t, temp_s..'\n'..i)  
         temp_s = nil 
       end
       i = i +1
     end
   
   -- filter fx chain, ignore rec/item
     fx_chunks_t = {}
     fx_count = reaper.TrackFX_GetCount(track)
     for i = 1, fx_count do
       fx_guid = reaper.TrackFX_GetFXGUID(track, i-1)
       for k = 1, #chunk_t do
         if chunk_t[k]:find(fx_guid:sub(-2)) ~= nil then table.insert(fx_chunks_t, chunk_t[k]) end
       end
     end
     if #fx_chunks_t ~= fx_count then return nil end
     if fx_index > fx_count then reaper.ReaScriptError('FX index > Number of FX')  return end
     
     param_count = reaper.TrackFX_GetNumParams(track, fx_index-1)
     if param_id+1 > param_count then reaper.ReaScriptError('Parameter index > Number of parameters') return end
     
   -- filter active chunk
     active_fx_chunk = fx_chunks_t[fx_index]
     active_fx_chunk_old = active_fx_chunk
     
   -- extract table
     active_fx_chunk_t = {}
     for line in active_fx_chunk:gmatch("[^\n]+") do table.insert(active_fx_chunk_t, line) end
 
   -- get first param
     for i = 1, #active_fx_chunk_t do
       if active_fx_chunk_t[i]:find('PARMLEARN '..param_id..' ') then exists = i break end
     end 
      
     --------------------------      
     if is_set == 0 then -- GET 
       if exists == nil then reaper.ReaScriptError('There is no learn for current parameter') return end
       -- form out table
         out_t = {}
         for word in active_fx_chunk_t[exists]:gsub('PARMLEARN ', ''):gmatch('[^%s]+') do
           table.insert(out_t, word)
         end
       -- convert
         midiChannel = out_t[2] & 0x0F
         midiCC = out_t[2] >> 8    
         
       return midiChannel + 1, midiCC, out_t[4] 
     end
     
     --------------------------
     if is_set == 1 then -- SET  midi
       if string_midiosc ~= nil and string_midiosc ~= '' then
       
           -- add to active_fx_chunk_t
             for i = 1, #active_fx_chunk_t do
               if active_fx_chunk_t[i]:find('FXID ') then guid_id = i break end
             end
             
             table.insert(active_fx_chunk_t, guid_id+1,
               'PARMLEARN '..param_id..' '..string_midiosc)
       end 
     end
       
       
     --------------------------  
     if is_set == -1 then -- remove current parameters learn
         for i = 1, #active_fx_chunk_t do
           if active_fx_chunk_t[i]:find('PARMLEARN '..param_id..' ') then 
             active_fx_chunk_t[i] = ''
           end
         end       
     end
     --------------------------   
           
     if is_set == -1 or is_set == 1 then
       -- return fx chunk table to chunk
         insert_begin = active_fx_chunk_t[1]
         insert_end = active_fx_chunk_t[#active_fx_chunk_t]
         active_fx_chunk_new = table.concat(active_fx_chunk_t, '\n', 2, #active_fx_chunk_t-1)
         
         
       -- delete_chunk lines
         for i = insert_begin, insert_end do
           table.remove(main_chunk, insert_begin)
         end
       
       -- insert new fx chunk
         table.insert(main_chunk, insert_begin, active_fx_chunk_new)
         
       -- clean chunk table from empty lines
         local out_chunk = table.concat(main_chunk, '\n')
         local out_chunk_clean = out_chunk:gsub('\n\n', '')
         --reaper.ShowConsoleMsg(out_chunk_clean)
         reaper.SetTrackStateChunk(track, table.concat(main_chunk, '\n')) 
     end
 end
 
   
   track  = reaper.GetTrack(0,0)  
   str, str0 = TrackFX_GetSetMIDIOSCLearn(track, 
                      0, --fx_index 0 -based,
                      6, --param_id 0-based
                      0, --is_set
                      '0 0 /1/fader1' --string_midiosc
                      )
                      
   --[[string_midiosc = (midiCC << 8) | 0xB0 + midiChan - 1 ..
                    is_soft_takeover ..
                    osc_address]]
                    
                    