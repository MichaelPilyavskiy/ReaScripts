-- @description Snap takes to scale
-- @version 1.01
-- @author MPL
-- @changelog
--   + init (1.01 ReaPack forcing update)
-- @website http://forum.cockos.com/member.php?u=70694
  
  debug = 0
  --  INIT -------------------------------------------------
  for key in pairs(reaper) do _G[key]=reaper[key]  end  
  local mouse = {}
  takes = {}
  local gui -- see GUI_define()
  local obj = {}
  local conf = {}
  sc_table = {}
  local cycle = 0
  local redraw = -1
  local SCC, lastSCC, SCC_trig
  local ProjState
  local key_names = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'}
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
  function  GUI_scale()  
    local pat_t = GetPattern(conf.scale_root, conf.scale_pat)
    
    local cnt_wt = 0 
    local cnt_not_wt = 0
    local t ,alpha_txt
    local w_n = math.floor(obj.pat.w/7)
    for i = 1, 12 do
      local alpha_txt
      if ({Check_Scale(i-1, pat_t)})[2] then alpha_txt = 0.9 else alpha_txt = 0.2 end
      --msg(alpha_txt)
      if      i == 1
          or  i == 3 
          or  i == 5 
          or  i == 6 
          or  i == 8 
          or  i == 10 
          or  i == 12 then 
          
          cnt_wt = cnt_wt + 1
          GUI_DrawBut(
                          {x = math.ceil((cnt_wt-1) * w_n),
                          y = obj.item_h*2,
                          w = w_n,
                          h = obj.pat.h,
                          col = 'white',
                          alpha_back = 0.09,
                          --rect_a = 0.3,
                          alpha_txt=alpha_txt,
                          state = 0,
                          is_but = true,
                          bot_al_txt = true,
                          txt = key_names[i]}
                      )
          gfx.a = 0.2
          local add_y_sub
          if i == 6 then add_y_sub = obj.pat.h/1.5 else  add_y_sub = 0 end
          gfx.line(math.ceil((cnt_wt-1) * w_n), 
                    obj.item_h*2+obj.pat.h,
                   math.ceil((cnt_wt-1) * w_n),
                    obj.item_h*2+obj.pat.h/1.5 -add_y_sub)
       else
          cnt_not_wt = cnt_not_wt + 1 
          if i == 7 then cnt_not_wt = cnt_not_wt + 1  end
          GUI_DrawBut(
                          {x = math.floor((cnt_not_wt - 0.5) * obj.pat.w/7),
                          y = obj.item_h*2,
                          w = math.floor(obj.pat.w/7),
                          h = obj.pat.h/1.5,
                          col = 'white',
                          alpha_back = 0.2,
                          alpha_txt=alpha_txt,
                          --rect_a = 0.3,
                          state = 0,
                          is_but = true,
                          bot_al_txt = true,
                          txt = key_names[i]}
                      )
          if i == 2 or i == 7 or i == 9  then 
            gfx.a = 0.2
            gfx.line(math.floor((cnt_not_wt+0.5) * obj.pat.w/7), 
                      obj.item_h*2,
                     math.floor((cnt_not_wt+0.5 ) * obj.pat.w/7),
                      obj.item_h*2+obj.pat.h/1.5 ) 
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
          gfx.a = 0.1
          --gfx.line(gfx.w-obj.menu_w, 0,gfx.w-obj.menu_w, gfx.h )
        -- refresh all buttons
          for key in pairs(obj) do
            if not key:match('knob') and type(obj[key]) == 'table' and obj[key].is_but then
              GUI_DrawBut(obj[key])
            end
          end 
          GUI_scale()         
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
    return {ES_key = 'MPL_SnapSelTakesToScale',
            wind_x =  50,
            wind_y =  50,
            wind_w =  200,
            wind_h =  300,
            dock =    0,
            scale_root = 0,
            scale_pat = '101011010101',
            scale_name = 'Default (whole tone)'}
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
  function GetTakes()
    takes = {}
    for i = 1, CountSelectedMediaItems(0) do
      local it = GetSelectedMediaItem( 0, i-1 )
      local tk =  GetActiveTake( it )
      if tk and TakeIsMIDI(tk) then 
        takes[#takes+1] =  {guid = BR_GetMediaItemTakeGUID( tk ),
                            data =  ({MIDI_GetAllEvts( tk, '' )})[2]}
      end
    end
  end
  ---------------------------------------------------
  local function OBJ_define()  
    obj.offs = 2
    obj.grad_sz = 200
    obj.item_h = math.floor(gfx.h/7)
    
    obj.get = { x = 0,
                y = 0,
                h = obj.item_h,
                txt = "Get takes",
                col = 'white',
                state = 0,
                is_but = true,
                alpha_back = 0.2,
                func =  function() GetTakes()end}
    obj.cur_root = {x = 0,
                y = obj.item_h,
                h = obj.item_h,
                col = 'white',
                state = 0,
                is_but = true,
                alpha_back = 0.08,
                func =  function() Menu_Root()end}
    obj.cur_scale = {x = 0,
                y = obj.item_h,
                h = obj.item_h,
                col = 'white',
                state = 0,
                is_but = true,
                alpha_back = 0.08,
                func =  function() Menu_Scale() end} 
    obj.pat =  {x = 0,
                y = obj.item_h*2,
                h = obj.item_h*4,
                col = 'white',
                alpha_back = 0.09,
                state = 0
                }               
    obj.set = { x = 0,
                y = obj.item_h*6,
                h = obj.item_h,
                txt = "Snap takes",
                col = 'white',
                state = 0,
                is_but = true,
                alpha_back = 0.2,
                func =  function() SetTakes()end}               
                      
                      
  end
  ---------------------------------------------------
  function SetTakes()
    pat  = GetPattern(conf.scale_root, conf.scale_pat)
    for i = 1, #takes do
      local take = GetMediaItemTakeByGUID( 0, takes[i].guid )
      if take then 
        MIDI_SetAllEvts( take,  takes[i].data )
        local _, notecnt = reaper.MIDI_CountEvts( take )
        for i = 1, notecnt do
          local _, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote( take, i-1 )
          --new_pitch = pitch % 12
          new_pitch = Check_Scale(pitch, pat)
          if selected then reaper.MIDI_SetNote( take, i-1, true, muted, startppqpos, endppqpos, chan, new_pitch, vel, true ) end
        end
        reaper.MIDI_Sort( take )
      end
    end
    UpdateArrange()
  end
  ---------------------------------------------------
  function OBJ_Update()
    obj.get.w = gfx.w
    obj.set.w = gfx.w
    local scale_x_offs = 0.35
    obj.cur_root.w = math.floor(gfx.w*scale_x_offs)
    obj.cur_scale.x = math.floor(gfx.w*scale_x_offs)
    obj.cur_scale.w = gfx.w - math.floor(gfx.w*scale_x_offs)
    obj.cur_root.txt = "KeyRoot: "..key_names[tonumber(conf.scale_root)+1]
    obj.cur_scale.txt = "Scale: "..conf.scale_name
    obj.pat.w = gfx.w
    obj.pat.scale = conf.scale_pat
  end
  ---------------------------------------------------
  function Menu(t)
    gfx.x = mouse.mx
    gfx.y = mouse.my
    local ret = gfx.showmenu('')
  end
  ---------------------------------------------------
  function Menu_Root()
    gfx.x = mouse.mx
    gfx.y = mouse.my
    local ret = gfx.showmenu(table.concat(key_names, '|'))
    if ret > 0 then conf.scale_root = ret - 1 ExtState_Save() redraw = 1 SetTakes() end
  end
  ---------------------------------------------------
  function Menu_Scale()
    gfx.x = mouse.mx
    gfx.y = mouse.my
    local str = 'Default||'
    for i = 1, #sc_table do
      str = str..sc_table[i].name..'|'
    end
    local ret = gfx.showmenu(str)
    if ret and ret > 0 then 
      if ret > 1 and ret < #sc_table+2 then 
        conf.scale_pat = sc_table[ret-1].pat 
        conf.scale_name = sc_table[ret-1].name 
       else
        conf.scale_pat = ({ExtState_Def()})[1].scale_pat
        conf.scale_name = ({ExtState_Def()})[1].scale_name 
      end
      ExtState_Save() 
      redraw = 1 
      SetTakes()
    end
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
  function LoadScale()
    local content = [[
// Scales use same synthax as .reascale files
"Major" 101011010101
"Dorian" 102304050670
"Phrygian" 120304056070
"Lydian" 102030450607
"Mixolydian" 102034050670
"Minor" 102304056070
"Locrian" 120304506070
"Harmonic Minor" 102304056007
"Harmonic Major" 102034056007
"Medolic Minor"  102304050607
"Hungarian Gypsy 1" 102300456007
"Hungarian Gypsy 2" 102300456070
"Hungarian Major" 100230450670
"Enigmatic" 120030405067
"Persian" 120034506007
"Composite Blues" 100334450070 ]]  
    local scales_path = ({get_action_context()})[2]:match('(.*).lua')..'_scales.txt'
    local f = io.open(scales_path, 'r')
    if not f then 
      f = io.open(scales_path, 'w')
      f:write(content)
      f:close()
     else
      local content = f:read('a')
      f:close()
    end
    sc_table  ={}
    for line in content:gmatch('[^\r\n]+') do
      local pat = line:match('%d%d%d%d%d%d%d%d%d%d%d%d')
      local name = line:match('"(.*)"')
      if pat and name then sc_table[#sc_table+1] = {pat =pat ,name=name } end
    end
  end
  -----------------------------------------  
  function GetPattern(root, scale)
    local pat,ex = {}
    local scale = tostring(scale)
    scale = scale:match('%d%d%d%d%d%d%d%d%d%d%d%d')
    scale = scale:sub(12-root+1)..scale:sub(0, 12-root)
    for num in scale:gmatch('%d') do 
      pat[#pat+1] = tonumber(num)>0 
      if tonumber(num) then ex = true end -- check if at least one note in pattern
    end
    if ex then return pat end
  end
  -----------------------------------------
  function Check_Scale(pitch, pat)
    local note = pitch % 12 +1
    local q_note
    for i = 1, 12 do
      if pat[i] then q_note = i end
      if pat[i] and i == note then return pitch, true end
      if not pat[i] and i == note and q_note then return pitch - (i-q_note),false end
    end
    return pitch,false
  end
  ---------------------------------------------------
  LoadScale()
  ExtState_Load()  
  gfx.init('MPL Snap takes to scale',conf.wind_w, conf.wind_h, conf.dock, conf.wind_x, conf.wind_y)
  OBJ_define()
  OBJ_Update()
  GUI_define()
  GetTakes()
  run()
  
  