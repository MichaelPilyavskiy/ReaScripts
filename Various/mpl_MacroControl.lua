-- @version 1.01
-- @author MPL
-- @changelog
--    + formatted parameters at the top
--    + font scaled to script window width
--    # redraw all knobs when changing one
--    # fix pan send indication/ctrl
-- @description MacroControl
-- @website http://forum.cockos.com/member.php?u=70694
  
  debug = 0
  --  INIT -------------------------------------------------
  for key in pairs(reaper) do _G[key]=reaper[key]  end  
   mouse = {}
  local gui -- see GUI_define()
   obj = {}
  local conf = {}
  local cycle = 0
  local redraw = 1
  local SCC, lastSCC, SCC_trig
  local ProjState
  --local K -- current knob name
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
  function ENGINE_Learn()
    local state = obj.learn.state
    if state == 1 and SCC_trig then  
      --local LTT = GetLastTouchedTrack()
      --local LTT_GUID = GetTrackGUID(LTT)
      local LTT_t = GetProjectState()--(LTT_GUID)
      for tr_guids in pairs(LTT_t)do
        for key in pairs(LTT_t[tr_guids]) do
          if LTT_t[tr_guids][key] ~= ProjState[tr_guids][key] then
            routing_table.ES_str = tr_guids..'_'..key
            break
          end    
        end    
      end
    end    
    if state == 1 and routing_table.ES_str and routing_table.knob then
      obj.learn.state = 0
      obj.knob[routing_table.knob].ES_str = routing_table.ES_str
      obj.knob[routing_table.knob].colint = 4248832
      routing_table = nil
      ExtStateProj_Save()
    end    
  end
  ---------------------------------------------------
  function GetProjectState(Pass_GUID)
     t = {}
    for tr_id = 1, CountTracks(0) do
      local tr = GetTrack(0, tr_id-1)
      --if Pass_GUID and GetTrackGUID(tr) ~= Pass_GUID then goto skip end
      -- info
          t[GetTrackGUID(tr)] = {info_vol =  GetMediaTrackInfo_Value( tr, 'D_VOL'  ) ,
                               info_pan =  GetMediaTrackInfo_Value( tr, 'D_PAN'  ) ,
                               info_width =  GetMediaTrackInfo_Value( tr, 'D_WIDTH') }                              
      -- sends 
        for send_id = 1, GetTrackNumSends( tr, 0 ) do
          destGUID = GetTrackGUID(BR_GetMediaTrackSendInfo_Track( tr, 0, send_id-1, 1 ))
          t[GetTrackGUID(tr)]['send_'..destGUID..'_vol'] = GetTrackSendInfo_Value( tr, 0, send_id-1, 'D_VOL' )
          t[GetTrackGUID(tr)]['send_'..destGUID..'_pan'] = GetTrackSendInfo_Value( tr, 0, send_id-1, 'D_PAN' )
        end
        
      -- fx
        for fx_id = 1, TrackFX_GetCount(tr) do
          for param_id = 1,  TrackFX_GetNumParams( tr, fx_id-1 ) do
            t[GetTrackGUID(tr)]['fx'..'_'..TrackFX_GetFXGUID( tr, fx_id-1 )..'_'..param_id] =  TrackFX_GetParam( tr, fx_id-1, param_id-1 )
          end
        end
      --::skip::    
    end
    return t
  end
  ---------------------------------------------------
  local function col(col_s, a) gfx.set( table.unpack(gui.col[col_s])) if a then gfx.a = a end  end
  ---------------------------------------------------
  function GUI_knob(k)
    local offs = 5
    local x,y,w,h0 = offs,offs, math.ceil(k.w-offs*2), math.ceil(k.w-offs*2)
    local arc_r = lim(w/2, 0, gfx.h/2)
    local ang_gr = 120
    local arc_w = 2
    local arc_w_step = 0.5
    local ang_val = math.rad(-ang_gr+math.ceil(ang_gr*2*k.val))
    local h = math.ceil(arc_r*2)
    
    --gfx.rect(x,y,w,h,0)
    -- val
      if k.val_str then 
        col('white', 0.8)
        gfx.setfont(1, gui.font, gui.fontsz)
        gfx.x = x+ (w-gfx.measurestr(k.val_str))/2
        gfx.y = y
        gfx.drawstr(k.val_str)
      end
      
    local y_knob_offs = 10
    local x1 = math.floor(x+w/2-1)
    local x2 = x1+1
    local y1 = math.floor(y+h/2-1) +h*0.3
    local y2 = y1 +2
      
      
    col(k.col)
    if k.colint then 
      local r, g, b = ColorFromNative( k.colint )
      r,g,b = r/255,g/255,b/255
      if GetOS():match('OSX') then 
        gfx.set(b,g,r) else gfx.set(r,g,b)
      end
    end
    
    -- arc back
      for i = 0, arc_w, arc_w_step do
        gfx.a = 0.2
        gfx.arc(x1,y2,arc_r-i,    math.rad(-ang_gr),math.rad(-90),    gui.aa)
        gfx.arc(x1,y1,arc_r-i,    math.rad(-90),math.rad(0),    gui.aa)
        gfx.arc(x2,y1,arc_r-i,    math.rad(0),math.rad(90),    gui.aa)
        gfx.arc(x2,y2,arc_r-i,    math.rad(90),math.rad(ang_gr),    gui.aa)
      end
      
    -- arc   
      
      gfx.a = 0.5
      for i = 0, arc_w, arc_w_step do
        if not k.centered then 
          if ang_val < math.rad(-90) then 
            gfx.arc(x1,y2,arc_r-i,    math.rad(-ang_gr),ang_val, gui.aa)
           else
            if ang_val < math.rad(0) then 
              gfx.arc(x1,y2,arc_r-i,    math.rad(-ang_gr),math.rad(-90),  gui.aa)
              gfx.arc(x1,y1,arc_r-i,    math.rad(-90),ang_val,     gui.aa)
             else
              if ang_val < math.rad(90) then 
                gfx.arc(x1,y2,arc_r-i,    math.rad(-ang_gr),math.rad(-90), gui.aa)
                gfx.arc(x1,y1,arc_r-i,    math.rad(-90),math.rad(0),    gui.aa)
                gfx.arc(x2,y1,arc_r-i,    math.rad(0),ang_val,    gui.aa)
               else
                if ang_val < math.rad(ang_gr) then 
                  gfx.arc(x1,y2,arc_r-i,    math.rad(-ang_gr),math.rad(-90), gui.aa)
                  gfx.arc(x1,y1,arc_r-i,    math.rad(-90),math.rad(0),    gui.aa)
                  gfx.arc(x2,y1,arc_r-i,    math.rad(0),math.rad(90),    gui.aa)
                  gfx.arc(x2,y2,arc_r-i,    math.rad(90),ang_val,    gui.aa)
                 else
                  gfx.arc(x1,y2,arc_r-i,    math.rad(-ang_gr),math.rad(-90),    gui.aa)
                  gfx.arc(x1,y1,arc_r-i,    math.rad(-90),math.rad(0),    gui.aa)
                  gfx.arc(x2,y1,arc_r-i,    math.rad(0),math.rad(90),    gui.aa)
                  gfx.arc(x2,y2,arc_r-i,    math.rad(90),math.rad(ang_gr),    gui.aa)                  
                end
              end
            end     
          end
          
         else  -- if centered
          if ang_val < math.rad(-90) then 
            gfx.arc(x1,y1,arc_r-i,    math.rad(0),math.rad(-90),     gui.aa)
            gfx.arc(x1,y2,arc_r-i,    math.rad(-90),ang_val, gui.aa)
           else
            if ang_val < math.rad(0) then 
              gfx.arc(x1,y1,arc_r-i,    math.rad(0),ang_val,     gui.aa)
             else
              if ang_val < math.rad(90) then 
                gfx.arc(x1,y1,arc_r-i,    math.rad(0),ang_val,    gui.aa)
               else
                if ang_val < math.rad(180) then 
                  gfx.arc(x1,y1,arc_r-i,    math.rad(0), math.rad(90),    gui.aa)
                  gfx.arc(x1,y2,arc_r-i,    math.rad(90),ang_val,    gui.aa)  
                                 
                end
              end
            end               
          end     
        end
      end
      
    -- pointer
      local lc = 0.9
      gfx.a = 0.8
      gfx.line( x1,
                y2,
                x1+math.cos(ang_val-math.rad(90))*arc_r*lc,
                y2+math.sin(ang_val-math.rad(90))*arc_r*lc)
                
  end
  ---------------------------------------------------
  local function GUI_DrawBut(o) 
    local x,y,w,h, txt = o.x, o.y, o.w, o.h, o.txt
    gfx.a = o.alpha_back or 0.3
    gfx.blit( 2, 1, 0, -- grad back
              0,0,  obj.grad_sz,obj.grad_sz,
              x,y,w,h, 0,0)
    col(o.col, o.alpha_back or 0.2)
    gfx.rect(x,y,w,h,1)
    col('white', 0.8)
    gfx.setfont(1, gui.font, gui.fontsz)
    gfx.x = x+ (w-gfx.measurestr(txt))/2
    gfx.y = y+ (h-gfx.texth)/2
    gfx.drawstr(o.txt)
  end
  ---------------------------------------------------
  local function GUI_draw()
    gfx.mode = 0
    -- redraw: -1 init, 1 maj changes, 2 minor changes
    -- 1 back
    -- 2 gradient
    --// 3 dynamic stuff
    -- 10-18 - knobs
      if redraw == 0 then
        if obj.learn.state == 1 then 
          -- learn rect
            gfx.a = clock%1
            gfx.rect( obj.learn.x, 
                      obj.learn.y,  
                      obj.learn.w,
                      obj.learn.h,0)
         -- knob rect
          if mouse.context_last_latch 
            and mouse.context_last_latch:match('knob_[%d]+') 
            and tonumber(mouse.context_last_latch:match('[%d]+')) then 
            local id = tonumber(mouse.context_last_latch:match('[%d]+'))
            gfx.a = clock%1
            gfx.rect(obj.knob[id].x,
                      obj.knob[id].y,
                      obj.knob[id].w,
                      obj.knob[id].h,
                      0)
          end
        end
      end
      
    --  init
      if redraw == -1 then
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
        -- refresh all knobs
          for i = 1, obj.knob_cnt do
            gfx.dest = 10+i
            gfx.setimgdim(10+i, -1, -1)  
            gfx.setimgdim(10+i, obj.knob[i].w,obj.knob[i].h) 
            GUI_knob(obj.knob[i])      
          end
      end
      
    -- redraw cur knob
      if redraw >=11 and redraw <= 10+obj.knob_cnt then
        local src_id = redraw-10
        gfx.dest = redraw
        gfx.setimgdim(redraw, -1, -1)  
        gfx.setimgdim(redraw, obj.knob[src_id].w,obj.knob[src_id].h) 
        GUI_knob(obj.knob[src_id])          
      end
      
    --  render    
      gfx.dest = -1   
      gfx.a = 1
      gfx.x,gfx.y = 0,0
    --  back
      gfx.blit(1, 1, 0, -- backgr
          0,0,gfx.w, gfx.h,
          0,0,gfx.w, gfx.h, 0,0)  
    -- knobs      
      gfx.x,gfx.y = 0,0
      for i = 1, obj.knob_cnt do 
        local kx,ky,kw,kh = obj.knob[i].x, obj.knob[i].y, obj.knob[i].w, obj.knob[i].h
        gfx.blit(10+i, 1, 0,    0,0,kw,kh,       kx,ky,kw,kh, 0,0)        
      end 
    
    if K and tonumber(K) > 0 then 
      local txt = obj.knob[tonumber(K)].ES_str
      if txt then
        txt = GetInfoFromESStr(obj.knob[tonumber(K)].ES_str)
        col('white', 0.5)
        gfx.setfont(1, gui.font, gui.fontsz)
        gfx.x = ((gfx.w-obj.menu_w)-gfx.measurestr(txt))/2
        gfx.y =gfx.h-gfx.texth
        gfx.drawstr(txt)
      end
    end
    
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
    return {ES_key = 'MPL_MacroControl',
            wind_x =  50,
            wind_y =  50,
            wind_w =  500,
            wind_h =  60,
            dock =    0}
  end
  ---------------------------------------------------
  function GetFXIDbyGUID(tr, guid)
    for fx =1,  TrackFX_GetCount( tr ) do
      local fx_guid = TrackFX_GetFXGUID( tr, fx-1 )--:gsub('-',''):match('{.-}')
      if fx_guid == guid then return fx end
    end
    return -1
  end
  ---------------------------------------------------
  function GetSendIdxFromGUID(tr, destGUID)
    for i = 1, GetTrackNumSends( tr, 0 ) do
      local dest_tr =  BR_GetMediaTrackSendInfo_Track( tr, 0, i-1, 1 )
      if destGUID == reaper.GetTrackGUID( dest_tr ) then return i-1 end
    end
    return -1
  end
  ---------------------------------------------------
  function ENGINE_ApplyValue(ES_str, val)
    --deb(val)
    if not ES_str then return end
    t = {}
    for word in ES_str:gmatch('[^%_]+') do t[#t+1] = word end
    -- perform FX param ctrl
      if #t == 4 and t[2] == 'fx' then
        local tr =  BR_GetMediaTrackByGUID( 0, t[1] )
        if not tr then return end -- BROKEN
        local fx_id = GetFXIDbyGUID(tr, t[3])
        if fx_id < 0 then return end -- BROKEN
        local par_id = tonumber(t[4])
        if not par_id then return end -- BROKEN
        reaper.TrackFX_SetParamNormalized( tr, fx_id-1, par_id-1, val )
      end
      
    -- perform track info
      if #t == 3 and t[2] == 'info' then
        local tr =  BR_GetMediaTrackByGUID( 0, t[1] )
        if not tr then return end -- BROKEN
        if t[3] == 'vol' then
          SetMediaTrackInfo_Value( tr, 'D_VOL', val )
         elseif t[3] == 'pan' then
          SetMediaTrackInfo_Value( tr, 'D_PAN', 2*(val-0.5 ))
         elseif t[3] == 'width' then 
          SetMediaTrackInfo_Value( tr, 'D_WIDTH', 2*(val-0.5 ))
        end
      end
      
    -- perform trsend info
      if #t == 4 and t[2] == 'send' then
        local tr =  BR_GetMediaTrackByGUID( 0, t[1] )
        if not tr then return end -- BROKEN
        local sendidx = GetSendIdxFromGUID(tr, t[3])
        if sendidx < 0 then return end
        if t[4] == 'vol' then
          SetTrackSendInfo_Value( tr, 0, sendidx, 'D_VOL', val )
         elseif t[4] == 'pan' then
          SetTrackSendInfo_Value( tr, 0, sendidx, 'D_PAN', (val-0.5 )*2)
        end
      end      
  end
  ---------------------------------------------------
  function GetInfoFromESStr(ES_str)
    local str = ''
    local  t = {}
    for word in ES_str:gmatch('[^%_]+') do t[#t+1] = word end
    -- perform FX param ctrl
      if #t == 4 and t[2] == 'fx' then
        local tr =  BR_GetMediaTrackByGUID( 0, t[1] )
        if not tr then return 0 end -- BROKEN
        local fx_id = GetFXIDbyGUID(tr, t[3])
        if fx_id < 0 then return 0 end -- BROKEN
        local par_id = tonumber(t[4])
        if not par_id then return 0 end -- BROKEN
        return  ({GetTrackName( tr, '' )})[2]..'   /   '
          .. ({TrackFX_GetFXName( tr, fx_id-1, '' )})[2]..'  /  '
          .. ({TrackFX_GetParamName( tr, fx_id-1, par_id-1, '')})[2]
      end  
      
    -- perform track info
      if #t == 3 and t[2] == 'info' then
        local tr =  BR_GetMediaTrackByGUID( 0, t[1] )
        if not tr then return end -- BROKEN
        if t[3] == 'vol' then
          return  ({GetTrackName( tr, '' )})[2]..'   /   Volume'
         elseif t[3] == 'pan' then
            return  ({GetTrackName( tr, '' )})[2]..'   /   Pan'
         elseif t[3] == 'width' then
            return  ({GetTrackName( tr, '' )})[2]..'   /   Width'            
        end
      end  

    -- perform trsend info
      if #t == 4 and t[2] == 'send' then
        local tr =  BR_GetMediaTrackByGUID( 0, t[1] )
        local desttr = BR_GetMediaTrackByGUID( 0, t[3] )
        if not tr or not desttr then return end -- BROKEN        
        if t[4] == 'vol' then
          return ({GetTrackName( tr, '' )})[2]..' >> '..({GetTrackName( desttr, '' )})[2]..' :   Volume'
         elseif t[4] == 'pan' then
          return ({GetTrackName( tr, '' )})[2]..' >> '..({GetTrackName( desttr, '' )})[2]..' :   Pan'
        end
      end  
              
    return str
  end
  ---------------------------------------------------
  function ENGINE_GetValue(ES_str)
    if not ES_str then return 0 end
    local deg = 2 -- quantize volume levels
    local  t = {}
    for word in ES_str:gmatch('[^%_]+') do t[#t+1] = word end
    -- perform FX param ctrl
      if #t == 4 and t[2] == 'fx' then
        local tr =  BR_GetMediaTrackByGUID( 0, t[1] )
        if not tr then return 0 end -- BROKEN
        local fx_id = GetFXIDbyGUID(tr, t[3])
        if fx_id < 0 then return 0 end -- BROKEN
        local par_id = tonumber(t[4])
        if not par_id then return 0 end -- BROKEN
        return 
          math.max(0, math.min(1,TrackFX_GetParamNormalized( tr, fx_id-1, par_id-1 ))),
          ({TrackFX_GetFormattedParamValue( tr, fx_id-1, par_id-1,'' )})[2]
      end  
      
    -- perform track info
      if #t == 3 and t[2] == 'info' then
        local tr =  BR_GetMediaTrackByGUID( 0, t[1] )
        if not tr then return end -- BROKEN
        if t[3] == 'vol' then
          local out_val = math.max(0, math.min(1,GetMediaTrackInfo_Value( tr, 'D_VOL' )))
          return out_val,
                math.floor((20*math.log(out_val, 10))*10^deg)/10^deg..'dB'
        elseif t[3] == 'pan' then
          local out_val = (GetMediaTrackInfo_Value( tr, 'D_PAN')+1)/2
          local ch if out_val<0.5 then ch = 'L' else ch =  'R' end
          local val_str = math.floor((-0.5+out_val)*200)..'%'..ch
          return out_val,val_str
        elseif t[3] == 'width' then
          local out_val = (GetMediaTrackInfo_Value( tr, 'D_WIDTH')+1)/2   
          return    out_val,math.floor((-0.5+out_val) *200   )..'W'
        end
      end
      
    -- perform trsend info
      if #t == 4 and t[2] == 'send' then
        local tr =  BR_GetMediaTrackByGUID( 0, t[1] )
        if not tr then return end -- BROKEN
        local sendidx = GetSendIdxFromGUID(tr, t[3])
        if sendidx < 0 then return end
        if t[4] == 'vol' then
          local out_val = math.max(0, math.min(1,GetTrackSendInfo_Value( tr, 0, sendidx, 'D_VOL' )))
          return out_val,
            math.floor((20*math.log(out_val, 10))*10^deg)/10^deg..'dB'
         elseif t[4] == 'pan' then
          local out_val = 0.5*GetTrackSendInfo_Value( tr, 0, sendidx, 'D_PAN' )+0.5
          local ch if out_val<0.5 then ch = 'L' else ch =  'R' end
          local val_str = math.floor((-0.5+out_val)*200)..'%'..ch
          return out_val,
            val_str
        end
      end    
       
    return 0
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
  local function OBJ_Update()
    local w1 = (gfx.w-obj.menu_w)/obj.knob_cnt
    for i = 1, obj.knob_cnt do
      if not  obj.knob[i] then  obj.knob[i] = {} end 
      if obj.knob[i].ES_str and obj.knob[i].ES_str:match('pan') then obj.knob[i].centered = true end
      obj.knob[i].x=  (i-1)*w1 
      obj.knob[i].w = w1
      obj.knob[i].y = obj.offs
      obj.knob[i].h = gfx.h-obj.offs*2
      obj.knob[i].col = 'white'
      obj.knob[i].val,obj.knob[i].val_str  = ENGINE_GetValue(obj.knob[i].ES_str)
      if not obj.knob[i].val then obj.knob[i].val = 0 end
    end
    obj.learn.x = gfx.w-obj.menu_w
    obj.learn.h = gfx.h - obj.offs*2
  end
  ---------------------------------------------------
  local function OBJ_define()  
    obj.offs = 2
    obj.knob_h = 20
    obj.menu_w = 30
    obj.knob_cnt = 8
    obj.grad_sz = 500 -- gradient rect
    obj.knob = {}
    
    obj.learn ={x = gfx.w-obj.menu_w+obj.offs,
                y = obj.offs,
                w = obj.menu_w-obj.offs,
                txt = "L",
                col = 'white',
                state = 0,
                is_but = true,
                func =  function() 
                          obj.learn.state = math.abs(1-obj.learn.state) 
                          if obj.learn.state == 1 then 
                            ProjState = GetProjectState() 
                            routing_table = {}
                          end
                        end}
                     
                      
                      
  end
  ---------------------------------------------------
  function Menu(knob_id)
    gfx.x = mouse.mx
    gfx.y = mouse.my
    local ret = gfx.showmenu('#Knob #'..knob_id..
                  '||Change color|Remove link')
    if ret == 2 then
      local retval, colorOut = reaper.GR_SelectColor(  )
      obj.knob[knob_id].colint = colorOut
      ExtStateProj_Save()
      redraw = 1
      OBJ_Update()
     elseif ret ==3 then
      obj.knob[knob_id].ES_str = nil
      obj.knob[knob_id].colint = nil
      ExtStateProj_Save()
      redraw = 1
      OBJ_Update()
    end
  end
 ---------------------------------------------------
  local function MOUSE_Match(b) return mouse.mx > b.x and mouse.mx < b.x+b.w and mouse.my > b.y and mouse.my < b.y+b.h end 
 --------------------------------------------------- 
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
          
    -- knobs
    for i = 1, obj.knob_cnt do
      if MOUSE_Match(obj.knob[i]) then mouse.context = 'knob_'..i end
      if MOUSE_Click(obj.knob[i]) then 
        mouse.context_latch = 'knob_'..i 
        mouse.context_last_latch = mouse.context_latch
        obj.knob[i].val_latch = obj.knob[i].val
      end
      if MOUSE_ClickR(obj.knob[i]) then Menu(i) end
      if MOUSE_Click(obj.knob[i]) and obj.learn.state == 1 then routing_table.knob = i end
    end   
     
    if mouse.context_latch and mouse.context_latch:match('knob') then K = mouse.context_latch:match('knob_[%d]+'):match('[%d]+')
     elseif mouse.context and mouse.context:match('knob') then K = mouse.context:match('knob_[%d]+'):match('[%d]+')
     else K =-1
    end
    if K and tonumber(K) and tonumber(K) > 0 and not MOUSE_Match({x=0, y =0, w =gfx.w, h =gfx.h}) then K = -1 end
    
    if mouse.LMB_state and mouse.context_latch and mouse.context_latch:match('knob_[%d]+') and tonumber(mouse.context_latch:match('[%d]+')) then 
      local id = tonumber(mouse.context_latch:match('[%d]+'))
      obj.knob[id].val = lim(obj.knob[id].val_latch - mouse.dy * 0.01)
      ENGINE_ApplyValue(obj.knob[id].ES_str, obj.knob[id].val)
      redraw = id+10
      OBJ_Update()
    end
    
    -- mouse release    
      if mouse.last_LMB_state and not mouse.LMB_state   then  
        mouse.context_latch = '' 
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
    if st_wind >= -1 then 
      ExtState_Save() 
      if math.abs(st_wind) == 1 then 
        redraw = st_wind 
        OBJ_Update() 
      end 
      GUI_define()
    end
    if SCC_trig then OBJ_Update() redraw = -1 end
    ENGINE_Learn()
    MOUSE()
    GUI_draw()
    if gfx.getchar() >= 0 then defer(run) else atexit(gfx.quit) end
  end
  ---------------------------------------------------
  function ExtStateProj_Load()  
    local _, outstr= GetProjExtState( 0, 'MPL_MC', 'data' )
    deb('load')
    deb(outstr)
    for line in outstr:gmatch('[^\r\n]+') do
      local knob_id = line:match('[%d]+') 
      if knob_id and tonumber(knob_id) and obj.knob[tonumber(knob_id)] then  
        line = line:match('[^%d_].*')
        obj.knob[tonumber(knob_id)].ES_str = line
        obj.knob[tonumber(knob_id)].colint = 16777215
      end
      if  line:match('col') then  
        local t = {}
        for line1 in line:gmatch('[^%s]+') do t[#t+1] = tonumber(line1) end
        for i = 1, obj.knob_cnt do obj.knob[i].colint = t[i] end
      end
    end
  end
  ---------------------------------------------------
  function ExtStateProj_Save()
    local outstr = ''
    local colors = 'col'
    for i = 1, obj.knob_cnt do
      if obj.knob[i].ES_str then outstr = outstr..i..'_'..obj.knob[i].ES_str..'\n' end
      if not obj.knob[i].colint then obj.knob[i].colint = 16777215 end
      colors = colors..' '..obj.knob[i].colint
    end
    outstr = outstr..'\n'..colors
    deb('save')
    deb(outstr)
    SetProjExtState( 0, 'MPL_MC', 'data', outstr )
  end
  ---------------------------------------------------
  function GUI_define()
    gui = {
                aa = 1,
                mode = 3,
                fontname = 'Calibri',
                fontsz = math.floor(gfx.w/35),
                col = { grey =    {0.5, 0.5,  0.5 },
                        white =   {1,   1,    1   },
                        red =     {1,   0,    0   },
                        green =   {0.3,   0.9,    0.3   }
                      }
                
                }
    
      if OS == "OSX32" or OS == "OSX64" then gui.fontsize = gui.fontsize - 5 end
  end
  ---------------------------------------------------
  ExtState_Load()  
  gfx.init('MPL MacroControl',conf.wind_w, conf.wind_h, conf.dock, conf.wind_x, conf.wind_y)
  OBJ_define()
  OBJ_Update()
  ExtStateProj_Load()
  GUI_define()
  run()
  
  