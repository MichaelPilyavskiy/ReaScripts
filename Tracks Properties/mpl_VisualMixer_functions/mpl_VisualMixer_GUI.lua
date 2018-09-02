-- @description VisualMixer_GUI
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex

  ---------------------------------------------------
  function rect(x,y,w,h)
    gfx.x,gfx.y = x,y
    gfx.lineto(x,y+h)
    gfx.x,gfx.y = x+1,y+h
    gfx.lineto(x+w,y+h)
    gfx.x,gfx.y = x+w,y+h-1
    gfx.lineto(x+w,y)
    gfx.x,gfx.y = x+w-1,y
    gfx.lineto(x+1,y)
  end
  ---------------------------------------------------
  function col(obj, col_str, a) 
    local r,g,b= table.unpack({1,1,1})
    gfx.set(r,g,b ) 
    if not GetOS():match('Win') then gfx.set(b,g,r ) end    
    if a then gfx.a = a end  
  end  
  ---------------------------------------------------
  function GUI_knob(obj, b)
    local x,y,w,h,val =b.x,b.y,b.w,b.h, b.val
    if not val then return end
    local arc_r = math.floor(w/2 * 0.8)
    if b.reduce_knob then arc_r = arc_r*b.reduce_knob end
    y = y - arc_r/2 + 1
    local ang_gr = 120
    local ang_val = math.rad(-ang_gr+ang_gr*2*val)
    local ang = math.rad(ang_gr)
  
    col(obj, b.col, 0.08)
    if b.knob_as_point then 
      local y = y - 5
      local arc_r = arc_r*0.75
      for i = 0, 1, 0.5 do
        gfx.arc(x+w/2-1,y+h/2,arc_r-i,    math.rad(-180),math.rad(-90),    1)
        gfx.arc(x+w/2-1,y+h/2-1,arc_r-i,    math.rad(-90),math.rad(0),    1)
        gfx.arc(x+w/2,y+h/2-1,arc_r-i,    math.rad(0),math.rad(90),    1)
        gfx.arc(x+w/2,y+h/2,arc_r-i,    math.rad(90),math.rad(180),    1)
      end
      gfx.a = 0.02
      gfx.circle(x+w/2,y+h/2,arc_r, 1)
      return 
    end
    
    
    -- arc back      
    col(obj, b.col, 0.2)
    local halfh = math.floor(h/2)
    local halfw = math.floor(w/2)
    for i = 0, 3, 0.5 do
      gfx.arc(x+halfw-1,y+halfh+1,arc_r-i,    math.rad(-ang_gr),math.rad(-90),    1)
      gfx.arc(x+halfw-1,y+halfh,arc_r-i,    math.rad(-90),math.rad(0),    1)
      gfx.arc(x+halfw,y+halfh,arc_r-i,    math.rad(0),math.rad(90),    1)
      gfx.arc(x+halfw,y+halfh+1,arc_r-i,    math.rad(90),math.rad(ang_gr),    1)
    end
    
    
    
    local knob_a = 0.6
    if b.knob_a then knob_a = b.knob_a end
    col(obj, b.col, knob_a)      
    if not b.is_centered_knob then 
      -- val       
      local ang_val = math.rad(-ang_gr+ang_gr*2*val)
      for i = 0, 3, 0.5 do
        if ang_val < math.rad(-90) then 
          gfx.arc(x+w/2-1,y+h/2,arc_r-i,    math.rad(-ang_gr),ang_val, 1)
         else
          if ang_val < math.rad(0) then 
            gfx.arc(x+w/2-1,y+h/2,arc_r-i,    math.rad(-ang_gr),math.rad(-90), 1)
            gfx.arc(x+w/2-1,y+h/2-1,arc_r-i,    math.rad(-90),ang_val,    1)
           else
            if ang_val < math.rad(90) then 
              gfx.arc(x+w/2-1,y+h/2,arc_r-i,    math.rad(-ang_gr),math.rad(-90), 1)
              gfx.arc(x+w/2-1,y+h/2-1,arc_r-i,    math.rad(-90),math.rad(0),    1)
              gfx.arc(x+w/2,y+h/2-1,arc_r-i,    math.rad(0),ang_val,    1)
             else
              if ang_val < math.rad(ang_gr) then 
                gfx.arc(x+w/2-1,y+h/2,arc_r-i,    math.rad(-ang_gr),math.rad(-90), 1)
                gfx.arc(x+w/2-1,y+h/2-1,arc_r-i,    math.rad(-90),math.rad(0),    1)
                gfx.arc(x+w/2,y+h/2-1,arc_r-i,    math.rad(0),math.rad(90),    1)
                gfx.arc(x+w/2,y+h/2,arc_r-i,    math.rad(90),ang_val,    1)
               else
                gfx.arc(x+w/2-1,y+h/2,arc_r-i,    math.rad(-ang_gr),math.rad(-90),    1)
                gfx.arc(x+w/2-1,y+h/2-1,arc_r-i,    math.rad(-90),math.rad(0),    1)
                gfx.arc(x+w/2,y+h/2-1,arc_r-i,    math.rad(0),math.rad(90),    1)
                gfx.arc(x+w/2,y+h/2,arc_r-i,    math.rad(90),math.rad(ang_gr),    1)                  
              end
            end
          end                
        end
      end
      
     else -- if centered
      local ang_val = math.rad(-ang_gr+ang_gr*2*val)
      for i = 0, 3, 0.5 do
        if ang_val < math.rad(-90) then 
          gfx.arc(x+w/2-1,y+h/2-1,arc_r-i,    math.rad(0),math.rad(-90),    1)
          gfx.arc(x+w/2-1,y+h/2,arc_r-i,    math.rad(-90),ang_val,    1)
         else
          if ang_val < math.rad(0) then 
            gfx.arc(x+w/2-1,y+h/2-1,arc_r-i,    math.rad(0),ang_val,    1)
           else
            if ang_val < math.rad(90) then 
              gfx.arc(x+w/2,y+h/2-1,arc_r-i,    math.rad(0),ang_val,    1)
             else
              if ang_val < math.rad(ang_gr) then 
  
                gfx.arc(x+w/2,y+h/2-1,arc_r-i,    math.rad(0),math.rad(90),    1)
                gfx.arc(x+w/2,y+h/2,arc_r-i,    math.rad(90),ang_val,    1)
               else
  
                gfx.arc(x+w/2,y+h/2-1,arc_r-i,    math.rad(0),math.rad(90),    1)
                gfx.arc(x+w/2,y+h/2,arc_r-i,    math.rad(90),math.rad(ang_gr),    1)                  
              end
            end
          end                
        end
      end    
          
    end 
  end
  ------------------------
  function GUI_DrawObj(obj, o, mouse, conf)
    if not o then return end
    gfx.dest = 1
    local x,y,w,h, txt = o.x, o.y, o.w, o.h, o.txt
    --[[
    gfx.set(1,1,1,1)
    gfx.setfont()
    gfx.x, gfx.y = x+20,y
    gfx.drawstr(x)]]
    
    if not x or not y or not w or not h then return end
    gfx.a = o.alpha_back or 0.2
    local blit_h, blit_w = obj.grad_sz,obj.grad_sz
    gfx.blit( 5, 1, 0, -- grad back
              0,0,  blit_w,blit_h,
              x,y,w,h, 0,0)     
    
    ------------------ fill back
      local x_sl = x      
      local w_sl = w 
      local y_sl = y      
      local h_sl = h 
      if o.mixer_slider_val then 
        y_sl = y+ h_sl - o.mixer_slider_val*h_sl 
        h_sl =o.mixer_slider_val*h_sl 
      end
      if o.colint and o.col then
        local r, g, b = ColorFromNative( o.colint )
        gfx.set(r/255,g/255,b/255, o.alpha_back or 0.2)
       else
        if o.col then col(obj, o.col, o.alpha_back or 0.2) end
      end
      if o.mixer_slider_pan then 
        local w_sl_fix = w_sl-1
        local h_sl_fix = h_sl -2
        local w_slpanL, w_slpanR = 0,0
        w_slpanL = lim(o.mixer_slider_pan-0.5) * w_sl_fix*2
        w_slpanR = (lim(o.mixer_slider_pan, 0, 0.5)-0.5) * w_sl_fix*2
        gfx.triangle( x_sl + w_slpanL,           y_sl,
                      x_sl+w_sl_fix+w_slpanR,  y_sl,
                      x_sl+w_sl_fix,  y_sl + h_sl_fix,
                      x_sl,           y_sl + h_sl_fix)
       else
        gfx.rect(x_sl,y_sl,w_sl,h_sl,1)
      end
           
    --------- cymb  ----------------
    if o.cymb then 
      if o.cymb_a then gfx.a = o.cymb_a end
      local edgesz = math.min(w,h)
      gfx.blit( 11, 1, 0, 
                100*o.cymb,0,  100,100,
                x + (w- edgesz)/2,
                y + (h- edgesz)/2,
                edgesz,edgesz, 0,0)       
    end
    
   -- pads drop line
    if o.draw_drop_line then
      gfx.set(1,1,1,0.8)
      gfx.rect(x,y,w,h, 0)
      xshift = 20   
      yshift = 30     
      x_drop_rect = x+xshift
      y_drop_rect = y-yshift
      w_drop_rect = 150
      h_drop_rect = 20
      if x_drop_rect + w_drop_rect > gfx.w then x_drop_rect = gfx.w - w_drop_rect end
      if y_drop_rect + h_drop_rect > gfx.h then y_drop_rect = gfx.h - h_drop_rect end
      if y_drop_rect + h_drop_rect <= 0  then y_drop_rect = 0 end
      gfx.line(x,y,x_drop_rect,y_drop_rect+h_drop_rect/2)
      gfx.set(0,0,0,0.8)
      gfx.rect(x_drop_rect,y_drop_rect,w_drop_rect,h_drop_rect,1)
      
      if o.drop_line_text then 
        gfx.setfont(1, obj.GUI_font,obj.GUI_fontsz )
        gfx.set(1,1,1,0.8)
        gfx.x,gfx.y = x_drop_rect+1,y_drop_rect+1
        gfx.drawstr(o.drop_line_text)
      end
    end        
           
             
    ------------------ check
      if o.check and o.check == 1 then
        gfx.a = 0.5
        gfx.rect(x+w-h+2,y+2,h-3,h-3,1)
        rect(x+w-h,y,h,h,0)
       elseif o.check and o.check == 0 then
        gfx.a = 0.5
        rect(x+w-h,y,h,h,0)
      end
      
    
    ------------------ tab
      if o.is_tab and o.col then
        col(obj, o.col, 0.6)
        local tab_cnt = o.is_tab >> 7
        local cur_tab = o.is_tab & 127
        gfx.line( x+cur_tab*w/tab_cnt,y,
                  x+w/tab_cnt*(1+cur_tab),y)
        gfx.line( x+cur_tab*w/tab_cnt,y+h,
                  x+w/tab_cnt*(1+cur_tab),y+h)                  
      end
    
    ------------------ knob
      if o.is_knob then GUI_knob(obj, o) end
  
    ------------------ txt
    -- text 
      local txt
      if not o.txt then txt = '' else txt = tostring(o.txt) end
      --if not o.txt then txt = '>' else txt = o.txt..'|' end
      ------------------ txt
        if txt and w > 0 then 
          if o.txt_col then col(obj, o.txt_col)else col(obj, 'white') end
          if o.txt_a then 
            gfx.a = o.txt_a 
            if o.outside_buf then gfx.a = o.txt_a*0.8 end
           else 
            gfx.a = 0.8 
          end
          gfx.setfont(1, obj.GUI_font, o.fontsz or obj.GUI_fontsz )
          local shift = 2
          local cnt = 0
          for line in txt:gmatch('[^\r\n]+') do cnt = cnt + 1 end
          local com_texth = gfx.texth*cnt
          local i = 0
          local reduce1, reduce2 = 2, nil
          if o.aligh_txt and o.aligh_txt&8==8 then reduce1, reduce2 = 0,-2 end
            local txt_t = {}
            
            if not o.txt_wrap then 
              for line in txt:gmatch('[^\r\n]+') do txt_t[#txt_t+1] = line end
             else
              local lim_wr = 10
              for line in txt:gmatch('[^\r\n]+') do 
                if gfx.measurestr(line) > w -lim_wr then 
                  local str = ''
                  for symb = 1, string.len(line) do
                    str = str..line:sub(symb,symb)
                    if gfx.measurestr(str) > w -lim_wr then 
                      txt_t[#txt_t+1] = str
                      str = ''
                    end
                  end
                  txt_t[#txt_t+1] = str
                 else
                  txt_t[#txt_t+1] = line
                end   
              end
            end
            
            local comy_shift = ((#txt_t-1) * gfx.texth)/2
            for lineid = 1, #txt_t do
              local line = txt_t[lineid]
              if gfx.measurestr(line:sub(2)) > w -5 and w > 20 then                 
                repeat line = line:sub(reduce1, reduce2) until gfx.measurestr(line..'...') < w -5
                if o.aligh_txt and o.aligh_txt&8==8 then line = line..'...' else line = '...'..line end                
              end
              gfx.x = x+ math.ceil((w-gfx.measurestr(line))/2)
              gfx.y = y+ h/2 - com_texth/2 + i*gfx.texth - comy_shift
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


      
    ------------------ frame
      if o.a_frame and o.col then  -- low frame
        col(obj, o.col, o.a_frame or 0.2)
        gfx.rect(x,y,w,h,0)
        gfx.x,gfx.y = x,y
        gfx.lineto(x,y+h)
        gfx.x,gfx.y = x+1,y+h
        --gfx.lineto(x+w,y+h)
        gfx.x,gfx.y = x+w,y+h-1
        --gfx.lineto(x+w,y)
        gfx.x,gfx.y = x+w-1,y
        gfx.lineto(x+1,y)
      end    
    
      
    
    -- highlight
    if o.is_selected then
      col(obj, 'white', 0.4)
      --gfx.rect(x,y,w,h,1)
      gfx.a = 0.8
      local h0 = math.floor(h/2)
      gfx.blit( 3, 1, math.rad(180), -- grad back
                0,0,  obj.grad_sz,obj.grad_sz,
                x,y,w,h0, 0,0)  
      gfx.blit( 3, 1, 0, -- grad back
                0,0,  obj.grad_sz,obj.grad_sz,
                x,y+h0,w,h0, 0,0)                  
    end
    
    -- is_marked_pin on drag
      if o.is_marked_pin then
        col(obj, 'green', 0.45)
        gfx.rect(x-1,y-1,w+2,h+2,0)
      end
      
    
    return true
  end
  ---------------------------------------------------
  function GUI_darkBack(x,y,w,h)
    gfx.set(0.2,0.2,0.2,0.9)    
    gfx.rect(x,y,w,h,1)
    gfx.set(1,1,1,0.2)
    gfx.rect(x,y,w,h,0)
  end
  ---------------------------------------------------
  function GUI_drawTooltip(conf, obj, data, refresh, mouse)
    local x_offs= 10
    local tt_w = 190
    local tt_h = 90
    local x,y=mouse.x+x_offs, mouse.y+x_offs
    local w,h = tt_w, tt_h
    
    if x + tt_w  > gfx.w then x = mouse.x - tt_w - x_offs end
    if y + tt_h  > gfx.h then y = gfx.h - tt_h end
    
    GUI_darkBack(x,y,w,h)
    gfx.setfont(1, obj.GUI_font,obj.GUI_fontsz_tooltip )
    gfx.set(1,1,1,0.8)
    gfx.x, gfx.y = x+5,y+5
    gfx.drawstr(obj.tooltip_str)
  end  
  ---------------------------------------------------  
  function GUI_gradBack(conf, obj, data, refresh, mouse)
    -- com grad
    gfx.dest = 2
    gfx.setimgdim(2, -1, -1)  
    gfx.setimgdim(2, obj.grad_sz,obj.grad_sz)  
    local r,g,b,a = 1,1,1,0.72
    gfx.x, gfx.y = 0,0
    local c = 0.8
    local drdx = c*0.00001
    local drdy = c*0.00001
    local dgdx = c*0.00008
    local dgdy = c*0.0001    
    local dbdx = c*0.00008
    local dbdy = c*0.00001
    local dadx = c*0.0001
    local dady = c*0.0001       
    gfx.gradrect(0,0, obj.grad_sz,obj.grad_sz, 
                    r,g,b,a, 
                    drdx, dgdx, dbdx, dadx, 
                    drdy, dgdy, dbdy, dady) 
  end
    ---------------------------------------------------  
  function GUI_gradDrawObj(conf, obj, data, refresh, mouse)
    gfx.dest = 5
    gfx.setimgdim(5, -1, -1)  
    gfx.setimgdim(5, obj.grad_sz,obj.grad_sz)  
    local r,g,b,a = 1,1,1,0.5
    gfx.x, gfx.y = 0,0
    local c = 1
    local drdx = c*0.001
    local drdy = c*0.01
    local dgdx = c*0.001
    local dgdy = c*0.001    
    local dbdx = c*0.00008
    local dbdy = c*0.001
    local dadx = c*0.001
    local dady = c*0.0007       
    gfx.gradrect(0,0, obj.grad_sz,obj.grad_sz, 
                    r,g,b,a, 
                    drdx, dgdx, dbdx, dadx, 
                    drdy, dgdy, dbdy, dady) 
                    gfx.dest = -1  
  end    
  ---------------------------------------------------
  function GUI_drawAmpLine(conf, obj, data, refresh, mouse)
    local x_plane = gfx.w * 0.3
    local x_plane2 = 5
    local y1 = Obj_GetYPos(obj, 12.5)
    local y2 = Obj_GetYPos(obj, -150)
    gfx.set(1,1,1,0.1)
    gfx.line(gfx.w/2,y1, gfx.w/2,y2)
    gfx.line(gfx.w/2,y1, gfx.w/2,y2+10)
    
    local t_val = {12, 8, 4, 0, -3, -6, -12, -18, -24, -36, -48, -100}
    if gfx.h < 400 then  t_val = {12, 6, 0, -6,-12, -20,   -36,  -100} end
    if gfx.h < 300 then t_val = {12, 6, 0, -6, -12, -30, -100} end
    if gfx.h < 250 then t_val = {12, 0, -12, -100} end
    
    -- values
    gfx.set(1,1,1)
    for i =1 , #t_val do
      local ypos,linearval = Obj_GetYPos(obj, t_val[i])
      local txt = t_val[i]..'dB'
      gfx.setfont(1, obj.GUI_font, obj.GUI_fontsz3 )
      gfx.a = 0.4
      gfx.x, gfx.y = gfx.w-gfx.measurestr(txt)-obj.offs*2,ypos-gfx.texth/2
      gfx.drawstr(txt)
      gfx.x, gfx.y = obj.offs*2,ypos-gfx.texth/2
      gfx.drawstr(txt)
      gfx.a = 0.1
      if t_val[i] ~= 0 then gfx.line(gfx.w/2-x_plane2, ypos,gfx.w/2 +x_plane2,ypos) end
    end
    
    -- zero
    local ypos,linearval = Obj_GetYPos(obj, 0)
    gfx.line(gfx.w/2-x_plane, ypos,gfx.w/2 +x_plane,ypos)
  end
  -----------------------------------------------
  function GUI_Peaks(conf, obj, data, refresh, mouse)
    if not data.tracks then return end
    for GUID in pairs(data.tracks) do
      if obj['tr'..GUID] then 
        local o = obj['tr'..GUID]
        local x,y,w,h, txt = o.x, o.y, o.w, o.h
        local cnt_lp = math.floor(w/2)-2
        for i = 1, cnt_lp  do
          if data.tracks[GUID].peakL and data.tracks[GUID].peakL[i] then
            
            -- L
            local peakvalL = data.tracks[GUID].peakL[i]
            local x0 = x +w/2 -i -1
            if peakvalL > 1 then 
              gfx.set(1,0.1,0.1, 0.8)
              gfx.line(x0, y, x0, y+h-1)
             else
              peakvalL = lim(peakvalL, 0,1)
              gfx.set(1,1,1)       
              gfx.a = 0.5 * (cnt_lp-i)/cnt_lp
              gfx.line( x0,
                        y +  h/2 -peakvalL*h/2,
                        x0+1,
                        y +  h/2 +peakvalL*h/2-1)
             end
             
             -- R
            local peakvalR = data.tracks[GUID].peakR[i]
            local x0 = x +w/2 +i-2
            if peakvalR > 1 then 
              gfx.set(1,0.1,0.1, 0.8)
              gfx.line(x0, y, x0, y+h-1)
             else
              peakvalR = lim(peakvalR, 0,1)
              gfx.set(1,1,1) 
              gfx.a = 0.5 * (cnt_lp-i)/cnt_lp                    
              gfx.line( x0,
                        y +  h/2 -peakvalR*h/2,
                        x0+1,
                        y +  h/2 +peakvalR*h/2-1)
             end             
          end
        end
      end
    end
  end
  
         
    ---------------------------------------------------
  function GUI_draw(conf, obj, data, refresh, mouse)
    gfx.mode = 0
    
    -- 1 main
    -- 2 gradient back
    --  3 grad obj
    -- 5 gradient Draw Obj
    
    --  init
      if refresh.GUI_onStart then
        GUI_gradBack(conf, obj, data, refresh, mouse)
        GUI_gradDrawObj(conf, obj, data, refresh, mouse)
        refresh.GUI_onStart = nil             
        refresh.GUI = true       
      end
      
    -- refresh
      if refresh.GUI then
        gfx.blit(4, 1, 0, -- backgr
            0,0,gfx.w, gfx.h,
            0,0,gfx.w, gfx.h, 0,0)
        -- refresh backgroung
          gfx.dest = 1
          gfx.setimgdim(1, -1, -1)  
          gfx.setimgdim(1, gfx.w, gfx.h) 
          gfx.blit( 2, 1, 0, -- grad back
                    0,0,  obj.grad_sz,obj.grad_sz/2,
                    0,0,  gfx.w,gfx.h, 0,0) 
        -- draw amp line
          GUI_drawAmpLine(conf, obj, data, refresh, mouse)
        -- refresh all buttons
          for key in spairs(obj) do 
            if type(obj[key]) == 'table' and obj[key].show  then 
              if obj[key].istrobj then
                GUI_DrawTrackObj(obj, obj[key], mouse, conf) 
               else
                GUI_DrawObj(obj, obj[key], mouse, conf) 
              end
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
    
    GUI_Peaks(conf, obj, data, refresh, mouse)
    
    refresh.GUI = nil
    refresh.GUI_minor = nil
    gfx.update()
  end
  ------------------------
  function GUI_DrawTrackObj(obj, o, mouse, conf)
    if not o then return end
    gfx.dest = 1
    local x,y,w,h, txt = o.x, o.y, o.w, o.h, o.txt
    -- frame
      gfx.set(1,1,1,0.3)
      gfx.rect(x,y,w,h,1)
    -- txt
      local trname = o.txt
      gfx.set(1,1,1,0.8)
      gfx.setfont(1, obj.GUI_font, obj.GUI_fontsz2 )
      gfx.x = x + (w-gfx.measurestr(trname))/2
      gfx.y = y + h + 2
      gfx.drawstr(trname) 
    -- cent line
      gfx.set(1,1,1,0.2)
      gfx.line(x+w/2, y+1,x+w/2, y + 5 )
    -- w circle
      gfx.circle(x,y+h/2, 5)
      gfx.circle(x+w,y+h/2, 5)
  end  
