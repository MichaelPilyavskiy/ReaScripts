-- @description PitchEditor_GUI
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
    local r,g,b= table.unpack(obj.GUIcol[col_str])
    gfx.set(r,g,b ) 
    --if not GetOS():match('Win') then gfx.set(b,g,r ) end
    if a then gfx.a = a end  
  end

  
  ---------------------------------------------------
  function GUI_knob(obj, b)
    local x,y,w,h,val =b.x,b.y,b.w,b.h, b.val
    if not val then return end
    local arc_r = math.floor(w/2 * 0.7)
    if b.reduce_knob then arc_r = arc_r*b.reduce_knob end
    y = y - arc_r/2 + 1
    local ang_gr = 120
    local ang_val = math.rad(-ang_gr+ang_gr*2*val)
    local ang = math.rad(ang_gr)
    local thickness = 1.5
    local knob_y_shift = b.knob_y_shift
    if not knob_y_shift then knob_y_shift = 0 end
    
    col(obj, b.col, 0.08)
    if b.knob_as_point then 
      local y = y - 5
      local arc_r = arc_r*0.75
      for i = 0, thickness, 0.5 do
        gfx_arc(x+w/2,y+h/2+ knob_y_shift,arc_r-i, -ang_gr, ang_gr, ang_gr)
      end
      gfx.a = 0.02
      gfx.circle(x+w/2,y+h/2,arc_r, 1)
      return 
    end
    
    
    -- arc back      
    col(obj, b.col, 0.07)
    local halfh = math.floor(h/2)
    local halfw = math.floor(w/2)
    for i = 0, thickness, 0.5 do
      gfx_arc(x+w/2,y+h/2+ knob_y_shift,arc_r-i, -ang_gr, ang_gr, ang_gr)
    end
    
    -- knob_haspoint
    if b.knob_haspoint then
      col(obj, 'green', 0.7)
      gfx.circle(x+w/2,y+h/2+knob_y_shift, 5, 1)
    end
    
    local knob_a = 0.6
    if b.knob_a then knob_a = b.knob_a end
    col(obj, b.col, knob_a)      
    if b.is_centered_knob ==false then 
      -- val       
      local ang_val = -ang_gr+ang_gr*2*val
      for i = 0, thickness, 0.5 do
        gfx_arc(x+w/2,y+h/2+ knob_y_shift,arc_r-i, -ang_gr, ang_val, ang_gr)
      end
      
     else -- if centered
      for i = 0, thickness, 0.5 do
        if val< 0.5 then
          gfx_arc(x+w/2,y+h/2 + knob_y_shift,arc_r-i, -ang_gr+ang_gr*2*val, 0, ang_gr)
         elseif val> 0.5 then
          gfx_arc(x+w/2,y+h/2+ knob_y_shift,arc_r-i, 0, -ang_gr+ang_gr*2*val, ang_gr)
        end
      end    
          
    end 
  end
  ---------------------------------------------------
  function gfx_arc(x,y,r, start_ang0, end_ang0, lim_ang, y_shift0)
    local start_ang = start_ang0
    local end_ang = end_ang0
    local y_shift = y_shift0
    if not y_shift0 then y_shift = 0 end
    local x = math.floor(x)
    local y = math.floor(y)
    local has_1st_segm = (start_ang <= -90) or (end_ang <= -90)
    local has_2nd_segm = (start_ang > -90 and start_ang <= 0) or (end_ang > -90 and end_ang <= 0) or (start_ang<=-90 and end_ang >= 0 )
    local has_3rd_segm = (start_ang >= 0 and start_ang <= 90) or (end_ang > 0 and end_ang <= 90) or (start_ang<=0 and end_ang >= 90 )
    local has_4th_segm = (start_ang > 90) or (end_ang > 90)
    
    if has_1st_segm then  gfx.arc(x,y+1 +y_shift,r, math.rad(math.max(start_ang,-lim_ang)), math.rad(math.min(end_ang, -90)),    1) end
    if has_2nd_segm then  gfx.arc(x,y+y_shift,r, math.rad(math.max(start_ang,-90)), math.rad(math.min(end_ang, 0)),    1) end
    if has_3rd_segm then gfx.arc(x+1,y+y_shift,r, math.rad(math.max(start_ang,0)), math.rad(math.min(end_ang, 90)),    1) end
    if has_4th_segm then  gfx.arc(x+1,y+1+y_shift,r, math.rad(math.max(start_ang,90)), math.rad(math.min(end_ang, lim_ang)),    1)  end
  end
  ---------------------------------------------------
  function GUI_DrawObj(obj, o, mouse, conf)
    if not o then return end
    gfx.dest = 1
    local x,y,w,h, txt = o.x, o.y, o.w, o.h, o.txt
    --gfx.set(1,1,1,1)gfx.rect(x,y,w,h,0)   
    
    if not x or not y or not w or not h then return end
    gfx.a = o.alpha_back or 0.15
    
    if not o.disable_blitback then
      local blit_h, blit_w = obj.grad_sz,obj.grad_sz
      gfx.blit( 5, 1, 0, -- grad back
              0,0,  blit_w,blit_h,
              x,y,w,h, 0,0)  
    end   
    
    ------------------ fill back
      local x_sl = x      
      local w_sl = w 
      local y_sl = y      
      local h_sl = h 
      if o.colint and o.col then
        local r, g, b = ColorFromNative( o.colint )
        gfx.set(r/255,g/255,b/255, o.alpha_back or 0.2)
       else
        if o.col then col(obj, o.col, o.alpha_back or 0.2) end
        
      end

    -- color fill
      if not o.colfill_frame and o.colfill_col then
        col(obj, o.colfill_col, o.colfill_a or 1) 
        gfx.rect(x,y,w,h,1)   
       elseif    o.colfill_frame and o.colfill_col  then
        gfx.a = 0.8
        local blit_h, blit_w = obj.grad_sz,obj.grad_sz
        gfx.blit( 5, 1, 0, -- grad back
              0,math.rad(180),  blit_w,blit_h,
              x,y,w,h, 0,0)   
        col(obj, o.colfill_col, o.colfill_a*0.7 or 1) 
        gfx.rect(x,y,w,h,1)                    
      end
             
      if o.is_progressbar and o.val then
        col(obj, 'white', 0.7) 
        gfx.rect(x,y,w*o.val,h,1)  
      end
    ------------------ knob
      if o.is_knob then GUI_knob(obj, o) end
  
      if o.is_ruleritem then gfx.set(1,1,1,0.7) gfx.line(x-2,y,x-2,y+h) end
    ------------------ txt
    -- text 
      local txt
      if not o.txt then txt = '' else txt = tostring(o.txt) end
      local txt_xshift= 0 if o.txt_xshift then txt_xshift = o.txt_xshift end
      local txt_yshift= 0 if o.txt_yshift then txt_yshift = o.txt_yshift end
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
          local shift = 0
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
              gfx.x = x+ math.ceil((w-gfx.measurestr(line))/2) + txt_xshift
              gfx.y = y+ h/2 - com_texth/2 + i*gfx.texth - comy_shift+txt_yshift
              if o.aligh_txt then
                if o.aligh_txt&1==1 then 
                  gfx.x = x + shift + txt_xshift
                  if check_ex then gfx.x = gfx.x + o.h end
                end -- align left
                if o.aligh_txt&2==2 then gfx.y = y + i*gfx.texth+txt_yshift end -- align top
                if o.aligh_txt&4==4 then gfx.y = h - com_texth+ i*gfx.texth-shift+txt_yshift end -- align bot
                if o.aligh_txt&8==8 then gfx.x = x + w - gfx.measurestr(line) - shift +txt_xshift end -- align right
                if o.aligh_txt&16==16 then gfx.y = y + (h - com_texth)/2+ i*gfx.texth - 2+txt_yshift end -- align center
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
    if o.is_selected and not o.ignore_selection then
      col(obj, 'white', 0.2)
      --gfx.rect(x,y,w,h,1)
      gfx.a = 0.4
      local h0 = math.floor(h/2)
      gfx.blit( 3, 1, math.rad(180), -- grad back
                0,0,  obj.grad_sz,obj.grad_sz,
                x,y,w,h0, 0,0)  
      gfx.blit( 3, 1, 0, -- grad back
                0,0,  obj.grad_sz,obj.grad_sz,
                x,y+h0,w,h0, 0,0)                  
    end
    
      
    
    return true
  end
  ---------------------------------------------------
  function GUI_DrawLine(x1,y1,x2,y2)
    gfx.line(x1,y1,x2,y2)
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
    local dbdx = c*0.00003
    local dbdy = c*0.001
    local dadx = c*0.0004
    local dady = c*0.0001       
    gfx.gradrect(0,0, obj.grad_sz,obj.grad_sz, 
                    r,g,b,a, 
                    drdx, dgdx, dbdx, dadx, 
                    drdy, dgdy, dbdy, dady) 
                    gfx.dest = -1  
  end    
  ------------------------------------------------------------------------
  function GUI_DrawPeaks(conf, obj, data, refresh, mouse)
                  
    if not( data.peaks and #data.peaks>0) or data.has_data==false then return end

    gfx.set(1,1,1,0.7)
    local t_sz= #data.peaks
    local last_val,lastpos_x = 0
    local step = obj.peak_area.w / t_sz
    for buf_idx = 1, t_sz do
      if data.peaks[buf_idx] then
        local pos_x = math.floor(obj.peak_area.x + buf_idx)
        local val = math.abs(data.peaks[buf_idx].peak+last_val)/4
        last_val = val
        gfx.a = 0.1
        if not lastpos_x or lastpos_x ~= pos_x and val > 0.001 then 
          gfx.line( pos_x, obj.peak_area.y + obj.peak_area.h* (0.5 - val), pos_x, obj.peak_area.y + obj.peak_area.h* (0.5 + val)) 
        end
        lastpos_x = pos_x
        if pos_x > obj.peak_area.w then break end
      end
    end 
  end
  ------------------------------------------------------------------------  
  function GUI_DrawPeaksPitchPoints(conf, obj, data, refresh, mouse) 
    if not( data.peaks and #data.peaks>0) or data.has_data==false then return end 
    -- pitch points
    gfx.x,gfx.y = obj.peak_area.x, obj.peak_area.y+obj.peak_area.h/2 
    if data.extpitch then
      local t_sz= #data.extpitch
      local last_val = 0
      local lastpos_x, lastpos_y = gfx.x,gfx.y
      for idx = 1, t_sz do
        local pos_x = math.floor(obj.peak_area.x + obj.peak_area.w * 1/data.it_tkrate *(data.extpitch[idx].xpos- (conf.GUI_scroll *data.it_tkrate))/conf.GUI_zoom)
        if pos_x > obj.peak_area.x + obj.peak_area.w then break end

        
        gfx.set(1,1,1,0.5)                
        local pitch_linval = data.extpitch[idx].pitch/127
        local pos_y = math.floor(obj.peak_area.y + obj.peak_area.h * ( 1- (pitch_linval- conf.GUI_scrollY)/conf.GUI_zoomY) ) 
        gfx.x = lastpos_x
        gfx.y = lastpos_y 
        if pos_y < obj.peak_area.y + obj.peak_area.h and pos_y > obj.peak_area.y then 
          if pos_x - gfx.x < 3/conf.GUI_zoom then 
            gfx.a=.7
            if gfx.y < obj.peak_area.y then gfx.y = obj.peak_area.y  end
            if gfx.y  > obj.peak_area.y + obj.peak_area.h then gfx.y = obj.peak_area.y + obj.peak_area.h end
            gfx.lineto(pos_x,pos_y)
          end
        end
        lastpos_x = pos_x
        lastpos_y = pos_y
      end
    end 
  end
  ------------------------------------------------------------------------  
  function GUI_DrawPeaksPitchPointsMod(conf, obj, data, refresh, mouse) 
    if not( data.peaks and #data.peaks>0) or data.has_data==false then return end 
    -- pitch points
    gfx.x,gfx.y = obj.peak_area.x, obj.peak_area.y+obj.peak_area.h/2 
    if data.extpitch then
      local t_sz= #data.extpitch
      local last_val = 0
      local lastpos_x, lastpos_y = gfx.x,gfx.y
      gfx.set(0.5, 1, 0.5)
      for idx = 1, t_sz do
        local pos_x = math.floor(obj.peak_area.x + obj.peak_area.w * 1/data.it_tkrate *(data.extpitch[idx].xpos- (conf.GUI_scroll *data.it_tkrate))/conf.GUI_zoom)
        if pos_x > obj.peak_area.x + obj.peak_area.w then break end

        local parent = Data_GetParentBlockId(data, idx)
        if not data.extpitch[parent].RMS_pitch then return end
        local parRMSpitch = data.extpitch[parent].RMS_pitch
        local curpitch = data.extpitch[idx].pitch
        local pitch_linval = (curpitch+data.extpitch[idx].pitch_shift - 2*(data.extpitch[parent].mod_pitch-0.5)*(parRMSpitch-curpitch))
          /127
        local pos_y = math.floor(obj.peak_area.y + obj.peak_area.h * ( 1- (pitch_linval- conf.GUI_scrollY)/conf.GUI_zoomY) ) 
        gfx.x = lastpos_x
        gfx.y = lastpos_y 
        if pos_y < obj.peak_area.y + obj.peak_area.h and pos_y > obj.peak_area.y then 
          if pos_x - gfx.x < 3/conf.GUI_zoom then 
            if gfx.y < obj.peak_area.y then gfx.y = obj.peak_area.y  end
            if gfx.y  > obj.peak_area.y + obj.peak_area.h then gfx.y = obj.peak_area.y + obj.peak_area.h end
            gfx.lineto(pos_x,pos_y)
          end
        end
        lastpos_x = pos_x
        lastpos_y = pos_y
      end
    end 
  end
  ------------------------------------------------------------------------  
  function GUI_DrawPeaksPitchGrid(conf, obj, data, refresh, mouse) 
    if not( data.peaks and #data.peaks>0) or data.has_data==false then return end    
    -- pitch grid
    gfx.set(1,1,1)
    gfx.setfont(1, obj.GUI_font, obj.GUI_fontsz3 )
    local x_shift = 0
    local y_lim = 15
    local grid_shift = 0.5* (obj.peak_area.h /127  /conf.GUI_zoomY) -1
    for i = 0, 127, 12 do
      local y_lev = math.floor(obj.peak_area.y + obj.peak_area.h - obj.peak_area.h * ((i/127)- conf.GUI_scrollY)/conf.GUI_zoomY) 
      if y_lev > obj.peak_area.y + y_lim and y_lev < obj.peak_area.y + obj.peak_area.h- y_lim then
        gfx.a = 0.06
        gfx.line(obj.peak_area.x+x_shift, y_lev+grid_shift, obj.peak_area.x + obj.peak_area.w-x_shift,y_lev+grid_shift)
        gfx.x, gfx.y = 0,y_lev - math.ceil(gfx.texth/2)
        gfx.a = 0.7
        gfx.drawstr(GetNoteStr(conf, i))
        
        
      end
    end
  end  
  ---------------------------------------------------  
  function GUI_gradSelection(conf, obj, data, refresh, mouse)
        gfx.dest = 3
        gfx.setimgdim(3, -1, -1)  
        gfx.setimgdim(3, obj.grad_sz,obj.grad_sz)  
        local r,g,b,a = 1,1,1,0.2
        gfx.x, gfx.y = 0,0
        local c = 0.8
        local drdx = c*0.00001
        local drdy = c*0.00001
        local dgdx = c*0.00008
        local dgdy = c*0.00001    
        local dbdx = c*0.00008
        local dbdy = c*0.00001
        local dadx = c*0.0005
        local dady = c*0.003       
        gfx.gradrect(0,0, obj.grad_sz,obj.grad_sz, 
                        r,g,b,a, 
                        drdx, dgdx, dbdx, dadx, 
                        drdy, dgdy, dbdy, dady)  
  end 
  ---------------------------------------------------  
  function GUI_gradPitch(conf, obj, data, refresh, mouse)
        gfx.dest = 6
        gfx.setimgdim(6, -1, -1)  
        gfx.setimgdim(6, obj.grad_sz,obj.grad_sz)  
        local r,g,b,a = 1,1,1,0.3
        gfx.x, gfx.y = 0,0
        local c = 0.8
        local drdx = c*0.00001
        local drdy = c*0.00001
        local dgdx = c*0.00008
        local dgdy = c*0.00001    
        local dbdx = c*0.00008
        local dbdy = c*0.00001
        local dadx = c*0.004
        local dady = c*0.000001    
        gfx.gradrect(0,0, obj.grad_sz,obj.grad_sz, 
                        r,g,b,a, 
                        drdx, dgdx, dbdx, dadx, 
                        drdy, dgdy, dbdy, dady)  
  end 
  
  ---------------------------------------------------
  function GUI_PitchScaleAroundPointer(conf, obj, data, refresh, mouse)
    if not( data.peaks and #data.peaks>0) or data.has_data==false then return end  
    if not 
      ( mouse.x> obj.peak_area.x 
        and mouse.x < obj.peak_area.x + obj.peak_area.w 
        and mouse.y> obj.peak_area.y 
        and mouse.y < obj.peak_area.y + obj.peak_area.h
      ) then return 
    end

    -- pitch grid
    local x_shift = 20
    local y_lim = 15
    local hrect = obj.peak_area.h/127 /conf.GUI_zoomY
    local a_note = 0
    local dx = 1/100
    local w=100
    gfx.setfont(1, obj.GUI_font, obj.GUI_fontsz3 )
    for i = 0, 127 do
      a_note = 0.08
      local note = math.fmod(i,  12)
      if note == 1 
        or note == 3
        or note == 5
        or note == 6
        or note == 8
        or note == 10
        or note == 0 then
        a_note = 0.5 
      end
      local y_lev = math.floor(obj.peak_area.y + obj.peak_area.h * ( 1- ((i/127)- conf.GUI_scrollY)/conf.GUI_zoomY) ) 
      local mult = 1-2*math.abs(mouse.y - y_lev) /obj.peak_area.h
      --gfx.a = a_note *mult
      if --mouse.x + w < obj.peak_area.x + obj.peak_area.w and 
        y_lev > obj.peak_area.y + y_lim and 
        y_lev < obj.peak_area.y + obj.peak_area.h- y_lim and 
        conf.GUI_zoomY < 0.3
         then
        if mouse.x + w > obj.peak_area.x + obj.peak_area.w then w = obj.peak_area.x + obj.peak_area.w - mouse.x end
        --gfx.rect(mouse.x, y_lev+hrect/2, 50,  hrect,1)
        gfx.a = a_note *mult
        if gfx.a > 0 then
          --[[gfx.blit(6, 1, math.rad(180), -- grad back
                  0,0,  obj.grad_sz,obj.grad_sz,
                  mouse.x+w-1, y_lev+hrect/2, w,  hrect-1, 0,0)  ]]    
          gfx.blit(6, 1, math.rad(0), -- grad back
                  0,0,  obj.grad_sz,obj.grad_sz,
                  mouse.x, y_lev+hrect/2, w,  hrect-1, 0,0)   
          gfx.x, gfx.y = mouse.x+x_shift,y_lev - math.ceil(gfx.texth/2)
          if conf.GUI_zoomY < 0.3 and w > 40 then
            gfx.a = 0.8 *mult
            gfx.drawstr(GetNoteStr(conf, i))  
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
    --  3 grad selection
    -- 4 backgr
    -- 5 gradient Draw Obj
    -- 6 grad pitch
    
    --  init
      if refresh.GUI_onStart then
        GUI_gradBack(conf, obj, data, refresh, mouse)
        GUI_gradDrawObj(conf, obj, data, refresh, mouse)
        GUI_gradSelection(conf, obj, data, refresh, mouse)
        GUI_gradPitch(conf, obj, data, refresh, mouse)
        refresh.GUI_onStart = nil             
        refresh.GUI = true       
      end
      
    -- refresh
      if refresh.GUI then 
        -- refresh backgroung
          gfx.dest = 1
          gfx.setimgdim(1, -1, -1)  
          gfx.setimgdim(1, gfx.w, gfx.h) 
          gfx.blit( 2, 1, 0, -- grad back
                    0,0,  obj.grad_sz,obj.grad_sz/2,
                    0,0,  gfx.w,gfx.h, 0,0)                
        -- refresh all buttons
          for key in spairs(obj) do 
            if type(obj[key]) == 'table' and obj[key].show and not obj[key].blit  then 
              GUI_DrawObj(obj, obj[key], mouse, conf) 
            end   
          end  
          
        GUI_DrawPeaks(conf, obj, data, refresh, mouse)
        if obj.current_page == 0 then
          GUI_DrawPeaksPitchPoints(conf, obj, data, refresh, mouse)
          GUI_DrawPeaksPitchPointsMod(conf, obj, data, refresh, mouse)
          GUI_DrawPeaksPitchGrid(conf, obj, data, refresh, mouse)
        end
      end
    
 
      
    --  render    
      gfx.dest = -1   
      gfx.a = 1
      gfx.x,gfx.y = 0,0
      --gfx.set(1,1,1,0.2)
      --gfx.rect(0,0,gfx.w, gfx.h/4,1)
    --  back
      gfx.blit(4, 1, 0, -- backgr
          0,0,gfx.w, gfx.h,
          0,0,gfx.w, gfx.h, 0,0)      
      gfx.blit(1, 1, 0, -- backgr
          0,0,gfx.w, gfx.h,
          0,0,gfx.w, gfx.h, 0,0)  
    
    if obj.current_page == 0 then GUI_PitchScaleAroundPointer(conf, obj, data, refresh, mouse) end
    
    --[[if data.has_take  then
      local cur_pos = GetCursorPosition()
      local pos_x1 = math.floor(obj.peak_area.x + obj.peak_area.w * 1/data.it_tkrate * ( data.extpitch[idx].xpos - (conf.GUI_scroll*data.it_tkrate))/conf.GUI_zoom) 
      local x = obj.peak_area.w  * ((((cur_pos-data.it_tksoffs-data.it_pos) / data.it_len ) - conf.GUI_scroll)/conf.GUI_zoom)
      gfx.set(1,1,1,1)
      gfx.line(x,obj.peak_area.y,x,obj.peak_area.y+obj.peak_area.h)
    end]]
    
    refresh.GUI = nil
    refresh.GUI_minor = nil
    
    gfx.update()
  end

