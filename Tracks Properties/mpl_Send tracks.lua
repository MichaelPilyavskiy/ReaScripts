-- @version 1.02
-- @author MPL
-- @description Send tracks
-- @website http://forum.cockos.com/showthread.php?t=188335    
-- @changelog
--    # refresh matrix after changing 
--    + clear matrix button

  for key in pairs(reaper) do _G[key]=reaper[key]  end 

      
  local scr_title = "MPL Send tracks"  
  local defsendvol = ({BR_Win32_GetPrivateProfileString( 'REAPER', 'defsendvol', '0',  reaper.get_ini_file() )})[2]
  local defsendflag = ({BR_Win32_GetPrivateProfileString( 'REAPER', 'defsendflag', '0',  reaper.get_ini_file() )})[2]
  
  --init 
  debug = 0
  --  INIT -------------------------------------------------
  for key in pairs(reaper) do _G[key]=reaper[key]  end  
  local mouse = {}
  local gui -- see GUI_define()
  local obj = {}
  mtrx_audio = {}
  mtrx_midi = {}
  conf = {}
  local cycle = 0
  local redraw = -1
  local SCC, lastSCC, SCC_trig
  local ProjState
  src_tr = {}
  dest_tr = {}
  function msg(s) if s then ShowConsoleMsg(s..'\n') end end
  ---------------------------------------------------------------------
  function GetTracks()
    local t = {}
    for i = 1, CountSelectedTracks(0) do
      tr = GetSelectedTrack(0,i-1)
      t[#t+1] = GetTrackGUID( tr )
    end  
    return t 
  end
  --------------------------------------------------------------------- 
  function Check_t(src_t, dest_t)
    for i = 1, #src_t do
      local chGUID = src_t[i]:gsub('%p', '')
      for i = #dest_t, 1, -1 do
        if dest_t[i]:gsub('%p', '') == chGUID then
          table.remove(dest_t,i)
          break
        end
      end
    end
  end

  ---------------------------------------------------------------------   
  function GetFlags(t,c,r)
    local s_id, d_id
    
    --mono/stereo
      if conf.multichan == 0 then 
        if t[c][r] == 2 then 
          return c-1, r-1  
         elseif t[c][r] == 1 then 
          if not(t[c-1] and t[c-1][r-1]and t[c-1][r-1] == 2) then return (c-1)|1024, (r-1)|1024 end
        end
      end
    
    -- multi
      if conf.multichan == 1 then 
        if t[c][r] == 1 and not (t[c+1] and t[c+1][r+1]and t[c+1][r+1] > 0) then return (c-1)|1024, (r-1)|1024 end
        if t[c][r] > 1 then 
          s_id = (c-1)+512*t[c][r] - t[c][r]+1 
          d_id = (r-1) - t[c][r]+1
          return s_id, d_id
        end
      end
    
  end
  
  ---------------------------------------------------------------------   
  function AddSends(src_t, dest_t)      
    if #src_t < 1 or #dest_t < 1 then return end
    Undo_BeginBlock()
    local t if conf.matrix == 1 then t = mtrx_midi else t = mtrx_audio end
    for i = 1, #src_t do
      local src_tr =  BR_GetMediaTrackByGUID( 0, src_t[i] )
      SetMediaTrackInfo_Value( src_tr, 'I_NCHAN', conf.sz )
      for i = 1, #dest_t do
        local dest_tr =  BR_GetMediaTrackByGUID( 0, dest_t[i] )
        SetMediaTrackInfo_Value( dest_tr, 'I_NCHAN', conf.sz )
        for c in pairs(t) do
          for r in pairs(t[c]) do
            
            if conf.matrix == 0 then
              local s_id, d_id = GetFlags(t,c,r)
              if s_id and d_id then 
                local new_id = CreateTrackSend( src_tr, dest_tr )
                SetTrackSendInfo_Value( src_tr, 0, new_id, 'D_VOL', defsendvol)
                SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_SENDMODE', defsendflag)
                SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_SRCCHAN', s_id)
                SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_DSTCHAN', d_id)
              end
            end
          
            
            if t[c][r] > 0 and conf.matrix == 1 then 
              local flag = (r<<5) + c
              local new_id = CreateTrackSend( src_tr, dest_tr )
              SetTrackSendInfo_Value( src_tr, 0, new_id, 'D_VOL', defsendvol)
              SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_SENDMODE', defsendflag)
              SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_MIDIFLAGS', flag)
              SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_SRCCHAN', -1)
              SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_DSTCHAN', -1)
            end
          end 
        end       
      end
    end
    TrackList_AdjustWindows(false)
    Undo_EndBlock(scr_title, 0) 
  end
  ---------------------------------------------------------------------  
  function main()
    local src_GUID = GetSrcTrGUID()
    local dest_GUID = GetDestTrGUID()    
    AddSends(src_GUID,dest_GUID)
  end 
  ---------------------------------------------------------------------    
  
    
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
      if not o.is_but then return end
      -- blit buf
        if o.state == 1 then 
          gfx.a = o.alpha1
          gfx.blit( 2, 1, 0, -- grad back
                    0,0,  obj.grad_sz,obj.grad_sz,
                    x,y,w,h, 0,0)
        end
        
      -- color back                
        if o.RM_state then 
          if (conf.multichan == 0 and o.RM_state == 1)
            or (conf.multichan == 1 and o.RM_state > 0) then -- mono
            gfx.a = 0.6 
            gfx.rect(x,y,w,h,1) 
           elseif (conf.multichan == 0 and o.RM_state == 2) then -- stereo 1
            col('green', 0.6)
            gfx.rect(x,y,w,h,1)
            col('white', 0.8)
            gfx.x = x+w/2
            gfx.y = y+h/2
            gfx.lineto(x+w*1.5,y+h*1.5 )
           elseif (conf.multichan == 0 and o.RM_state == 3) then -- stereo 2
            col('green', 0.6)
            gfx.rect(x,y,w,h,1)                         
          end
         else
          col(o.col, o.alpha2)
          gfx.rect(x,y,w,h,1)
        end
      
      -- draw txt
        if o.txt then 
          col(o.txt_col or 'white', o.alpha_txt or 0.9)
          local fnsz = gui.fontsz
          if o.val_tbl then fnsz = fnsz - 2 end
          gfx.setfont(1, gui.font, fnsz)
          gfx.x = x+ (w-gfx.measurestr(txt))/2
          gfx.y = y+ (h-gfx.texth)/2
          gfx.drawstr(o.txt)
        end
      
      -- frame
        if o.rect_a then 
          col(o.col, o.rect_a or 0.2)
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
          local r,g,b,a = 0.9,0.9,0.9,0.6
          gfx.x, gfx.y = 0,0
          local c = 1
          local drdx = c*0.00001
          local drdy = c*0.00001
          local dgdx = c*0.00008
          local dgdy = c*0.0001    
          local dbdx = c*0.00008
          local dbdy = c*0.00001
          local dadx = c*0.0005
          local dady = c*0.0005      
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
            gfx.a = 0.4
            gfx.blit( 2, 1, 0, -- grad back
                      0,0,  obj.grad_sz,obj.grad_sz,
                      0,0,  gfx.w,gfx.h, 0,0)
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
              wind_w =  300,
              wind_h =  343,
              dock =    0,
              sz = 16,
              multichan = 0,
              matrix = 0} -- 0 audio 1 midi
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
      
      local alpha1 = 0.8
      local alpha2 = 0.3
      obj.get_src = { x = 0,
                  y = 0,
                  h = obj.item_h,
                  col = 'green',
                  state = 1,
                  is_but = true,
                  alpha1 = alpha1,
                  alpha2 = alpha2,
                  func =  function() src_tr = GetTracks() Check_t(src_tr, dest_tr) redraw = 1 end}
      
      obj.get_dest = { x = 0,
                  y = obj.item_h+1,
                  h = obj.item_h,
                  col = 'blue',
                  state = 1,
                  is_but = true,                 
                   alpha1 = alpha1,
                  alpha2 = alpha2,
                  func =  function() dest_tr = GetTracks() Check_t(src_tr, dest_tr) redraw = 1 end}      
      obj.clear = { x = 0,
                  y = (obj.item_h+1)*3,
                  h = obj.item_h,
                  w = 60,
                  col = 'red',
                  state = 1,
                  is_but = true,
                  alpha1 = alpha1,
                  alpha2 = alpha2,
                  txt = 'Clear',
                  func =  function() 
                            if conf.matrix == 1 then mtrx_midi = {} else mtrx_audio = {} end 
                            redraw = 1
                          end}                   
      obj.addsend = { x = obj.clear.w+1,
                  y = (obj.item_h+1)*3,
                  h = obj.item_h,
                  
                  col = 'red',
                  state = 1,
                  is_but = true,
                  alpha1 = alpha1,
                  alpha2 = alpha2,
                  func =  function() AddSends(src_tr, dest_tr) end}     
      obj.options = { x = 0,
                  y = (obj.item_h+1)*2,
                  h = obj.item_h,
                  txt='Menu',
                  col = 'white',
                  state = 1,
                  is_but = true,
                  alpha1 = alpha1,
                  alpha2 = alpha2,
                  func =  function() Menu() end}  
      obj.RM = { x = 0,
                  y = (obj.item_h+1)*4,
                  txt='',
                  col = 'white',
                  state = 0,
                  is_but = false,
                  alpha1 = alpha1,
                  alpha2 = alpha2,
                  func =  function() Menu() end}                                                                        
    end
    ---------------------------------------------------
    function OBJ_Update()
      obj.get_src.w = gfx.w
      obj.get_src.txt = "Get source tracks ("..#src_tr..')'
      
      obj.get_dest.w = gfx.w
      obj.get_dest.txt = "Get destination tracks ("..#dest_tr..')'
      
      obj.addsend.w = gfx.w-obj.clear.w
      local what = 'audio' if conf.matrix == 1 then what = 'MIDI' end
      obj.addsend.txt='Create '..what..' send'
      
      
      obj.options.w = gfx.w
      obj.RM.w = gfx.w
      obj.RM.h = gfx.w
      
      OBJ_BuildRM()
    end
    ---------------------------------------------------
    function OBJ_BuildRM()
      for key in pairs(obj) do if key:match('RM_but_x') then obj[key]=nil end end
      local sz = tonumber(conf.sz)
       local w = math.floor(obj.RM.w/sz)
      local h = math.floor(obj.RM.h/sz)
      for r = 1, sz do
        for c = 1, sz do
          local alpha2 = 0
          local col = 'white'
          local txt,txt_col = ''
          local RM_state
          local t if conf.matrix == 1 then t = mtrx_midi else t = mtrx_audio end
          if t[c] and t[c][r] then
            RM_state = t[c][r]
          end
          local val_tbl
          if r == 1 then 
            txt = c 
            txt_col = 'green'
            val_tbl = true
           elseif c ==1 then 
            txt = r 
            txt_col = 'blue'
            val_tbl = true
          end
          obj['RM_but_x'..r..'y'..c] = {x = w*(c-1),
                                   y = obj.RM.y + h*(r-1),
                                   w = w,
                                   h = h,
                                  txt=txt,
                                  txt_col = txt_col,
                                  col = col,
                                  state =  0,
                                  RM_state = RM_state,
                                  is_but = true,
                                  alpha1 = alpha1,
                                  alpha2 = alpha2,
                                  rect_a = 0.1,
                                  val_tbl= val_tbl,
                                  func =  function() 
                                            local t if conf.matrix == 1 then t = mtrx_midi else t = mtrx_audio end
                                            if not t[c] then t[c] = {} end
                                            if not t[c][r] then t[c][r] = 0 end
                                            if t[c][r] > 0 then t[c][r] = 0 else t[c][r] = 1 end
                                            Analyze_t(t)
                                            redraw = 1
                                          end}  
        end
      end
    end
    ----------------------------------------------------------------------
    function Analyze_t(t)
      if conf.matrix == 1 then return end
      local sz = conf.sz
      for c = 1, sz do
        if not t[c] then t[c] = {} end
        for r = 1, sz do
          if not t[c][r] then t[c][r] = 0 end
        end
      end
      if conf.multichan == 0 then 
      
        for c in pairs(t) do
          for r in pairs(t[c]) do
            if t[c][r] then
              if c%2 == 1 and r%2 == 1 then
                if t[c+1] and t[c+1][r+1] then
                
                  if t[c][r] > 0 and t[c+1][r+1] > 0 then
                    t[c][r] = 2
                    t[c+1][r+1] = 3
                   elseif t[c][r] == 0 and t[c+1][r+1] > 0  then
                    t[c+1][r+1] = 1
                  end
                 
                end
              end
            end 
          end
        end
        
       else
        
        
        for c in pairs(t) do
          for r in pairs(t[c]) do
            if t[c][r] then
            
              if      t[c][r] > 0 
                  and t[c+1] 
                  and t[c+1][r+1] 
                  and t[c+1][r+1] > 0 then
                  t[c+1][r+1] = t[c][r] + 1
                  t[c][r] = 1
              end
              
              --if t[c][r] == 0 and t[c+1][r+1] > 0  then  t[c+1][r+1] = 1   end
            end 
          end
        end
      end
    end
    ---------------------------------------------------
    function Menu()
      local t = { {str = 'Show Audio Routing Matrix',
            state = conf.matrix == 0,
            func =  function() 
                      conf.matrix = 0 
                      redraw = 1 
                      ExtState_Save()
                    end},
            {str = 'Show MIDI Routing Matrix',
            state = conf.matrix == 1,
            func =  function() 
                      conf.matrix = 1 
                      redraw = 1 
                      ExtState_Save()
                    end},
            {str = '|Change matrix size',
            state = false,
            func =  function() 
                      local ret, retval = GetUserInputs('Change matrix size', 1, 'size', conf.sz)
                      if not ret then return end
                      if not retval or not tonumber(retval) or math.floor(tonumber(retval) ) <= 0 then return end
                      new_sz = math.floor(tonumber(retval) )
                      conf.sz = new_sz 
                      redraw = 1 
                      ExtState_Save()
                    end},     
            {str = 'Allow multichannel sends',
            state = conf.multichan == 1,
            func =  function()       
                      mtrx_audio = {}                
                      conf.multichan = math.abs(1-conf.multichan)
                      redraw = 1 
                      ExtState_Save()
                    end},                                               
            {str = '|Build multichannel send',
            state = false,
            func =  function() 
                      local t if conf.matrix == 1 then t = mtrx_midi else t = mtrx_audio end
                      for c = 1, conf.sz do
                        t[c] = {}
                        for r = 1,conf.sz do
                          if r == c then t[c][r] =1 end
                        end
                      end
                      Analyze_t(t)
                      redraw = 1
                    end},                     
          }
          
      local str, check = '', ''
      for i = 1, #t do
        if t[i].state then check = '!' else check ='' end
        str = str..check..t[i].str..'|'
      end
      gfx.x = mouse.mx
      gfx.y = mouse.my
      local ret = gfx.showmenu(str)
      if ret > 0 then t[ret].func() end
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
                          green =   {0.3,   0.9,    0.3 },
                          blue =    {0.4,   0.4,    0.9}
                        }
                  
                  }
      
        if OS == "OSX32" or OS == "OSX64" then gui.fontsize = gui.fontsize - 7 end
    end
    ---------------------------------------------------
    ExtState_Load()  
    gfx.init(scr_title,
              340,--conf.wind_w, 
              464,--conf.wind_h, 
              conf.dock, conf.wind_x, conf.wind_y)
    OBJ_define()
    OBJ_Update()
    GUI_define()
    run()
    
    