-- @description RS5k_manager_GUI
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
    if not GetOS():match('Win') then gfx.set(b,g,r ) end
    
    if a then gfx.a = a end  
  end
  ---------------------------------------------------
  function GUI_DrawWF_edges(obj, data)   
    local w = (gfx.w-obj.keycntrlarea_w)--obj.WF_w
    local h = obj.kn_h 
    local cur_note = obj.current_WFkey
    local cur_spl = obj.current_WFspl
    if cur_note and data[cur_note] and data[cur_note][cur_spl] and 
      not ( data[cur_note][cur_spl].offset_end == 1 and data[cur_note][cur_spl].offset_start ==0) then
      
      local x_sel = w*data[cur_note][cur_spl].offset_start+obj.keycntrlarea_w
      local y_sel =  0
      local w_sel = w*data[cur_note][cur_spl].offset_end - w*data[cur_note][cur_spl].offset_start
      local h_sel = 2--h-1
      --gfx.muladdrect(x_sel,y_sel,w_sel,h_sel,1,1,1,2.5,0,0,0,0 )
      gfx.set(1,1,1,0.6)
      gfx.rect(x_sel,y_sel,w_sel,h_sel,1)
    end
  end
  ---------------------------------------------------
  function GUI_DrawWF(obj, data, conf)    
    local w = obj.WF_w
    local h = obj.kn_h
    -- WF
      if obj.current_WFkey 
          and obj.current_WFspl 
          and data[obj.current_WFkey] 
          and data[obj.current_WFkey][obj.current_WFspl] 
          and data[obj.current_WFkey][obj.current_WFspl].src_track_col 
          then
        local int_col = data[obj.current_WFkey][obj.current_WFspl].src_track_col
        local r, g, b = ColorFromNative( int_col )
        gfx.set(r/255,g/255,b/255, 0.2)
       else
        col(obj, 'green', 0.2)
      end
      if conf.separate_spl_peak == 1 then gfx.a = 0.6 end
      gfx.x, gfx.y = 0, h
      local step = lim(w/#data.current_spl_peaks, 0.1,0.2)
      local last_x, cnt = nil, #data.current_spl_peaks
      for i = 1, cnt, step do 
        local val = math.abs(data.current_spl_peaks[math.floor(i)])
        local x = math.floor(w*i / cnt )
        local y = h/2 --h-h*val 
        local h0 =  h*val
        gfx.rect(x,y,math.ceil(w/#data.current_spl_peaks),h0, 1)  
        gfx.rect(x,h/2-h*val+1,math.ceil(w/#data.current_spl_peaks),h0, 1)
      end 
  end

  ---------------------------------------------------
  function Menu_FormBrowser(conf,refresh)    
    for i = 1, conf.fav_path_cnt  do if not conf['smpl_browser_fav_path'..i] then conf['smpl_browser_fav_path'..i] = '' end end
    local browser_t =
                                  {
                                    {str = 'Browse for file/path',
                                    func = function()
                                              local ret, fn = GetUserFileNameForRead('', 'Browse for file/path', '.wav' )
                                              if ret then
                                                local par_fold = GetParentFolder(fn)
                                                if par_fold then 
                                                  conf.cur_smpl_browser_dir = par_fold 
                                                  refresh.conf = true
                                                  refresh.GUI = true
                                                  refresh.data = true                                             
                                                end
                                              end
                                            end
                                    },                                
                                    {str = '|>Save as favourite'},
                                    {str = '1 - '..conf.smpl_browser_fav_path1,
                                    func = function()
                                              conf.smpl_browser_fav_path1 = conf.cur_smpl_browser_dir
                                              refresh.conf = true 
                                              refresh.GUI = true
                                                                                            refresh.data = true
                                            end,
                                    }
                                  }
    -- save favourite 
    for i = 2, conf.fav_path_cnt  do
      if conf['smpl_browser_fav_path'..i] then 
        if i == conf.fav_path_cnt or not conf['smpl_browser_fav_path'..i+1] then close = '<' else close = '' end
        browser_t[#browser_t+1] = { str = close..i..' - '..conf['smpl_browser_fav_path'..i],
                                    func = function()
                                      conf['smpl_browser_fav_path'..i] = conf.cur_smpl_browser_dir
                                      refresh.conf = true
                                      refresh.GUI = true
                                                                                    refresh.data = true 
                                    end
                                }
      end
    end 
    -- load favourite
    for i = 1, conf.fav_path_cnt  do
      if conf['smpl_browser_fav_path'..i] then
        browser_t[#browser_t+1] = { str = 'Fav'..i..' - '..conf['smpl_browser_fav_path'..i],
                                  func = function()
                                    conf.cur_smpl_browser_dir = conf['smpl_browser_fav_path'..i]
                                    refresh.conf = true
                                    refresh.GUI = true
                                                                                  refresh.data = true
                                  end
                                }    
      end
    end
    return  browser_t
  end
  ---------------------------------------------------
  function GUI_selector(obj, b)
    local wsel = 20
    local hsel = 28
        
    local x,y,w,h,val =b.x,b.y,b.w,b.h, b.val
    x = x + (w-wsel)/2
    y = y + obj.offs
    w = wsel
    h = hsel
    if not val then return end
    gfx.a = 0.5 
    if b.val and b.val_cnt then
      gfx.rect(x,y,w,h,0)
      gfx.rect(x+2,y+2 + b.val * (h-4)/b.val_cnt ,w-4,(h-4)/b.val_cnt,1)
    end  
    
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
    col(obj, b.col, 0.15)
    local halfh = math.floor(h/2)
    local halfw = math.floor(w/2)
    for i = 0, thickness, 0.5 do
      gfx_arc(x+w/2,y+h/2+ knob_y_shift,arc_r-i, -ang_gr, ang_gr, ang_gr)
    end
    
    
    
    local knob_a = 0.6
    if b.knob_a then knob_a = b.knob_a end
    col(obj, b.col, knob_a)      
    if not b.is_centered_knob then 
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
  function GUI_DrawObj(obj, o) 
    if not o then return end
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
      gfx.blit( 11, 1, 0, -- grad back
                100*o.cymb,0,  100,100,
                x + (w- edgesz)/2,
                y + (h- edgesz)/2,
                edgesz,edgesz, 0,0)       
    end
    
   -- pads drop line
    if o.draw_drop_line then
      gfx.set(1,1,1,0.8)
      gfx.rect(x,y,w,h, 0)
      local xshift = 20   
      local yshift = 30     
      local x_drop_rect = x+xshift
      local y_drop_rect = y-yshift
      local w_drop_rect = 150
      local h_drop_rect = 20
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
      if o.is_selector then GUI_selector(obj, o) end
      
    ------------------ txt
      if o.txt and w > 5 then 
        local w0 = w -2
        if o.limtxtw then w0 = w - o.limtxtw end
        local txt = tostring(o.txt)
        if o.txt_col then 
          col(obj, o.txt_col, o.alpha_txt or 0.8)
         else
          col(obj, 'white', o.alpha_txt or 0.8)
        end
        local f_sz = obj.GUI_fontsz
        gfx.setfont(1, obj.GUI_font,o.fontsz or obj.GUI_fontsz )
        local y_shift = -1
        local cnt_lines = 0 for line in txt:gmatch('[^\r\n]+') do cnt_lines = cnt_lines + 1 end
        local cnt = -1
        for line in txt:gmatch('[^\r\n]+') do
          cnt = cnt + 1 
          if gfx.measurestr(line:sub(2)) > w0 -2 and w0 > 20 then 
            repeat line = line:sub(2) until gfx.measurestr(line..'...')< w0 -2
            line = '...'..line
          end
          if o.txt2 then line = o.txt2..' '..line end
          gfx.x = x+ math.ceil((w-gfx.measurestr(line))/2)
          gfx.y = y+ (h-gfx.texth)/2 + y_shift 
          if o.aligh_txt then
            if o.aligh_txt&1==1 then gfx.x = x+2  end -- align left
            if o.aligh_txt>>2&1==1 then gfx.y = y + y_shift end -- align top
            if o.aligh_txt>>4&1==1 then gfx.y = h - gfx.texth*cnt_lines + cnt*gfx.texth end -- align bot
          end
          if o.bot_al_txt then 
            gfx.y = y+ h-gfx.texth-3 +y_shift
          end
          if gfx.y + gfx.texth > y + h then break end
          gfx.drawstr(line)
          y_shift = y_shift + gfx.texth
        end
      end
      
            
    --[[---------------- key txt
      if o.vertical_txt then
        gfx.dest = 10
        gfx.setimgdim(10, -1, -1)  
        gfx.setimgdim(10, h,h) 
        gfx.setfont(1, obj.GUI_font,o.fontsz or obj.GUI_fontsz )
        gfx.x,gfx.y = 2,0
        col(obj, 'white', 0.9)
        
        local line = o.vertical_txt
        
        if o.limtxtw_vert then
          lim_cnt = 0
          local str_len = gfx.measurestr(line)
          if str_len > h - o.limtxtw_vert - 10 then 
             repeat 
             line = line:sub(2)
             
             lim_cnt = lim_cnt + 1
             until gfx.measurestr(line) < h - o.limtxtw_vert -10 or lim_cnt > 200
             line = '...'..line 
          end
        end
        gfx.drawstr(line) 
        gfx.dest = o.blit or 1
        local offs = 0
        gfx.blit(10,1,math.rad(-90),
                  0,0,h,h,
                  x,y-2,h,h,0,0)
                  ---5,h-w+5)
      end
    ]]
    ------------------ line
      if o.a_line and o.col then  -- low frame
        col(obj, o.col, o.a_frame or 0.2)
        gfx.x,gfx.y = x+1,y+h
        gfx.lineto(x+w,y+h)
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
      
      if o.selection_tri then 
        -- bottom triangle selected
        local sel_tr_w = math.min(20,w)
        local sel_tr_h = math.min(8,h)
        if not o.selection_tri_vertpos then 
          gfx.triangle(x+(w-sel_tr_w)/2,y+h,
                               x+w/2,y+h-sel_tr_h,
                               x+(w+sel_tr_w)/2,y+h)
         else 
          gfx.triangle(x,y+(h-sel_tr_w)/2,
                       x+sel_tr_h,y+h/2,
                       x,y+(h+sel_tr_w)/2)
        end
      end    
  
    if o.is_step and o.val then
      if o.colint then 
        local r, g, b = ColorFromNative( o.colint ) 
        gfx.set(r/255,g/255,b/255, 0.4)
        --gfx.rect(x,y,w-1,h,1)
      end
      gfx.muladdrect(x,y + h - h*o.val,w-1,h*o.val,1,1,1,1, 0,0,0,0.9)
    end
        
    return true
  end
  ---------------------------------------------------
  function GUI_symbols(conf, obj, data, refresh, mouse) 
    
    -- mixer
      col(obj, 'white', 1) 
      gfx.a = 1 
      --gfx.rect(0,0,100,100,0)   
      gfx.rect(10,10,20,80,1) 
      gfx.rect(30,30,20,60,1)
      gfx.rect(50,50,20,40,1)
      gfx.rect(70,40,20,50,1)
      
    -- preview
      local xo = 100
      col(obj, 'white', 1) 
      gfx.a = 1   
      --gfx.rect(100,0,100,100,0) 
      gfx.rect(20+xo,25,30,50,1) 
      gfx.triangle( 50+xo,25,
                    50+xo,75,
                    80+xo,99,
                    80+xo,0
                    )
                    
    -- pad
      xo = 200
      col(obj, 'white', 1) 
      gfx.a = 1   
      for x = 1, 3 do
        for y = 1, 3 do
          gfx.rect(12 + xo + 25*(x-1),10+ 25*(y-1),24,24,1)  
        end
      end        

    -- pattern
      xo = 300
      col(obj, 'white', 1) 
      gfx.a = 1   
      for x = 1, 2 do
        for y = 1, 3 do
          if x == 2 then 
            gfx.rect(8 + xo + 25*(x-1),10+ 25*(y-1),48,24,1)  
           else
            gfx.rect(12 + xo + 25*(x-1),10+ 25*(y-1),18,24,1) 
          end
        end
      end  
                  
  end
  ---------------------------------------------------
  function GUI_draw(conf, obj, data, refresh, mouse)
    gfx.mode = 0
    
    -- 1 back
    -- 2 gradient
    -- 3 smpl browser blit
    -- 4 stepseq 
    -- 5 gradient steps
    -- 6 WaveForm
    -- 10 sample keys
    -- 11 symbols
    
    --  init
      if refresh.GUI_onStart then
        -- com grad
        gfx.dest = 2
        gfx.setimgdim(2, -1, -1)  
        gfx.setimgdim(2, obj.grad_sz,obj.grad_sz)  
        local r,g,b,a = conf.GUIback_R,conf.GUIback_G,conf.GUIback_B,conf.GUIback_A
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
        -- steps grad
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
        local dady = c*0.001       
        gfx.gradrect(0,0, obj.grad_sz,obj.grad_sz, 
                        r,g,b,a, 
                        drdx, dgdx, dbdx, dadx, 
                        drdy, dgdy, dbdy, dady) 
                        gfx.dest = -1  
        gfx.dest = 11
        gfx.setimgdim(11, -1, -1)  
        gfx.setimgdim(11, 1000,1000)  
        GUI_symbols(conf, obj, data, refresh, mouse) 
        refresh.GUI_onStart = nil             
        refresh.GUI = true       
      end
      
    -- refresh
      if refresh.GUI or refresh.GUI_minor then 
        -- refresh backgroung
          gfx.dest = 1
          gfx.setimgdim(1, -1, -1)  
          gfx.setimgdim(1, gfx.w, gfx.h) 
          gfx.blit( 2, 1, 0, -- grad back
                    0,0,  obj.grad_sz,obj.grad_sz/2,
                    0,0,  gfx.w,gfx.h, 0,0)
        -- refresh all buttons
          for key in spairs(obj) do 
            if type(obj[key]) == 'table' and obj[key].show and not obj[key].blit and key~= 'set_par_tr'  then 
              GUI_DrawObj(obj, obj[key]) 
            end  
          end  
        -- 
          if conf.show_wf == 1 then
            GUI_DrawWF_edges(obj, data)    
          end
        -- WF
          if conf.show_wf == 1 and refresh.GUI_WF then
            GetPeaks(data, obj.current_WFkey, obj.current_WFspl)
            gfx.setimgdim(6, -1, -1)  
            gfx.setimgdim(6, obj.WF_w,obj.WF_h) 
            if data.current_spl_peaks then 
              gfx.dest = 6
              gfx.a = 0.5
              gfx.setimgdim(6, -1, -1)  
              gfx.setimgdim(6, obj.WF_w,obj.WF_h) 
              GUI_DrawWF(obj, data, conf)              
            end
            refresh.GUI_WF = nil
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
    --  WF
    if conf.tab == 0 then 
      gfx.a = 1
      gfx.mode = 0
      local WFy = 0 
      if conf.show_wf == 1 and conf.separate_spl_peak == 1 then WFy = obj.WF_h+obj.samplename_h end
      gfx.blit(6, 1, 0, -- backgr
            0,0,obj.WF_w, obj.WF_h-1,
            
            obj.keycntrlarea_w  ,
            WFy,--gfx.h-obj.WF_h-obj.key_h,
            gfx.w- obj.keycntrlarea_w  , 
            obj.WF_h-1 , 0,0) 
    end      
    
    if obj.allow_track_notes and conf.allow_track_notes == 1 and data.jsfxtrack_exist == true then GUI_TrackInputNotes(obj, conf) end
    if conf.tab == 2 and obj.pat_item_pos_sec and obj.pat_item_len_sec then GUI_DrawPlayCursor(obj, conf) end--and GetPlayStateEx( 0 )&1==1 
    
    refresh.GUI = nil
    refresh.GUI_minor = nil
    gfx.update()
  end
  ---------------------------------------------------  
  function GUI_DrawPlayCursor(obj, conf)
    local playpos 
    if GetPlayStateEx( 0 )&1==1  then playpos = GetPlayPosition2Ex( 0 ) else  playpos = GetCursorPosition() end
    if playpos >= obj.pat_item_pos_sec and playpos <= obj.pat_item_pos_sec + obj.pat_item_len_sec then
      local retval, measures, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats( 0, obj.pat_item_pos_sec ) 
      local barlen = TimeMap2_beatsToTime( 0, fullbeats+4 ) -  obj.pat_item_pos_sec
      local pos = (playpos - obj.pat_item_pos_sec) /  barlen--obj.pat_item_len_sec
      local key_w0 = obj.key_w
      if conf.key_width_override > 0 then key_w0 = conf.key_width_override end
      local back_w = (obj.pat_area_w-obj.step_cnt_w*2-obj.offs*2-key_w0)
      local line_x = obj.keycntrlarea_w + obj.offs*2 + key_w0 + back_w * pos
      local line_y = obj.samplename_h + obj.kn_h
      local line_h = gfx.h - obj.samplename_h + obj.kn_h
      
      local line_w = 2
      
      gfx.set(0.2, 0.6, 0.3, 0.2)
      gfx.rect(line_x, line_y, line_w, line_h)
      --[[local px_w = 10
      for i = -px_w, px_w do
        gfx.a = math.abs(1-math.abs(i/px_w))*0.2
        gfx.line(line_x+i, line_y, line_x + line_w+i, line_y + line_h)
      end]]
    end
  end
  ---------------------------------------------------  
  function GUI_TrackInputNotes(obj, conf)
    if not gmem_read then return end
    local buf = reaper.gmem_read(98)
    local time_fall = (0.5/10)*buf
    buf = buf *2
    local cur_ts = reaper.gmem_read(buf+1)
    if not cur_ts then return end
    local circ_r = 10
    local shift_right = conf.tab==2
    
    local t_out = {}
    for i = 1, buf/2 do
      local alpha = time_fall - math.min(cur_ts - reaper.gmem_read(i+buf/2) , time_fall)
      t_out[i] = {note = reaper.gmem_read(i),
                  alpha =alpha/time_fall}
    end
    local t_sorted = {}
    -- sort/get last values
    for i = 1, #t_out do if t_out[i].alpha ~= 0 then t_sorted[ t_out[i].note ]= t_out[i].alpha end end
    
    local x,y
    for note in pairs(t_sorted) do
      if obj['keys_p'..note] and obj['keys_p'..note].w then
        gfx.set(1,1,1)
        gfx.a = math.min(1,math.max(0,t_sorted[note]))
        x = obj['keys_p'..note].x + obj['keys_p'..note].w/2
        y = obj['keys_p'..note].y + obj['keys_p'..note].h/2-1
        if shift_right then 
          x = obj['keys_p'..note].x + obj['keys_p'..note].w - circ_r -1
        end
        gfx.circle(x,y,circ_r,1)
      end
    end
  end
