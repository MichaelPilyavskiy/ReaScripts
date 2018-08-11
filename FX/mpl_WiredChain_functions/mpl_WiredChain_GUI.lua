-- @description WiredChain_GUI
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
  ---------------------------------------------------
  function GUI_DrawObj(obj, o, mouse)
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
              for line in txt:gmatch('[^\r\n]+') do 
                if gfx.measurestr(line) > w -5 then 
                  local str = ''
                  for symb = 1, string.len(line) do
                    str = str..line:sub(symb,symb)
                    if gfx.measurestr(str) > w -5 then 
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
    
    -- wire
      if o.wire then      
        for i = 1, #o.wire do
          local wire_t = o.wire[i]
          if wire_t.wiretype == 0 then -- audio
            col(obj, obj.audiowire_col,obj.audiowire_a)
          end
          if wire_t.dest 
            and obj[wire_t.dest] 
            and obj[wire_t.dest].x 
            and obj[wire_t.dest].y 
            and obj[wire_t.dest].h then 
            gfx.line(x+w,y+h/2,obj[wire_t.dest].x, obj[wire_t.dest].y+obj[wire_t.dest].h/2)
           else
            -- drag mouse
            if wire_t.dest == 'mouse' then 
              if o.context:match('_O_') then 
                gfx.line(x+w,y+h/2,mouse.x,mouse.y)   
               else
                gfx.line(x,y+h/2,mouse.x,mouse.y)  
              end 
            end
            
          end
        end
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
  function GUI_symbols(conf, obj, data, refresh, mouse) 
    
    -- mixer
      col(obj, 'green', 1) 
      gfx.a = 1 
      --gfx.rect(0,0,100,100,0)   
      gfx.rect(10,60,20,30,1) 
      gfx.rect(30,30,20,60,1)
      gfx.rect(50,50,20,40,1)
      gfx.rect(70,60,20,30,1)
      
    -- preview
      col(obj, 'white', 1) 
      gfx.a = 1   
      --gfx.rect(100,0,100,100,0) 
      gfx.rect(120,25,30,50,1) 
      gfx.triangle( 150,25,
                    150,75,
                    180,99,
                    180,0
                    )
            
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
    local dady = c*0.001       
    gfx.gradrect(0,0, obj.grad_sz,obj.grad_sz, 
                    r,g,b,a, 
                    drdx, dgdx, dbdx, dadx, 
                    drdy, dgdy, dbdy, dady) 
                    gfx.dest = -1  
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
  function GUI_drawSearchFX(conf, obj, data, refresh, mouse)  
    local fsz =  obj.GUI_fontsz2
    gfx.setfont(1, obj.GUI_font, fsz )
    
    local x = obj.fxsearch_x 
    local y = obj.fxsearch_y 
    local w = obj.fxsearch_w
    local h = obj.fxsearch_h
    GUI_darkBack(x,y,w,h)
    
    local search_box_x = x+obj.offs
    local search_box_y = y+obj.offs
    local search_box_w = w-obj.offs*2
    local search_box_h = obj.fxsearch_item_h
    local alpha  = math.abs((os.clock()%1) -0.5)
    --  draw frame
      gfx.set(  1,1,1,  0.05,  0) --rgb a mode
      gfx.rect(search_box_x,search_box_y,search_box_w,search_box_h ,1) 
      
    -- active char
      if obj.textbox.active_char ~= nil then
        gfx.set(  1,1,1, alpha,  0) --rgb a mode
        gfx.x = search_box_x +obj.offs -2 +
                gfx.measurestr(obj.textbox.text:sub(0,obj.textbox.active_char))  
        gfx.y = search_box_y
        gfx.drawstr('|')
      end  
      
    -- txt
      gfx.x = search_box_x +obj.offs
      gfx.y = search_box_y
      gfx.set(  1,1,1, 0.8,  0) --rgb a mode
      gfx.drawstr(obj.textbox.text)   
      
    -- draw results
      local res_a = 0.9
      local dec = res_a / (obj.fxsearch_h / (1+obj.fxsearch_item_h))
      local limw = obj.fxsearch_w - obj.offs*4
      if obj.textbox.match_t then
        for i = 1, #obj.textbox.match_t do
          local txt = obj.textbox.match_t[i].name
          if gfx.measurestr(txt) > limw then 
            local len = string.len(txt)
            for i = len, 1, -1 do
              txt = txt:sub(0,i)
              if gfx.measurestr(txt) < limw then break end
            end
          end
          if search_box_y + obj.fxsearch_item_h * (i+1) > obj.fxsearch_y + obj.fxsearch_h then break end  
          res_a = math.max(0, res_a -dec)
          -- txt
            gfx.x = search_box_x +obj.offs
            gfx.y = search_box_y + obj.fxsearch_item_h * i
            gfx.set(  1,1,1, res_a,  0) --rgb a mode
            gfx.drawstr(txt)     
        end        
      end   
      
    -- draw match frame
      if obj.textbox.text ~= '' and obj.textbox.matched_id then 
        gfx.set(  0.8,1,0.8, 0.15,  0)
        gfx.rect(search_box_x ,
                 search_box_y + obj.fxsearch_item_h * obj.textbox.matched_id,
                 search_box_w,
                 search_box_h,
                 0)
      end 
  end              
    ---------------------------------------------------
  function GUI_draw(conf, obj, data, refresh, mouse)
    gfx.mode = 0
    

    -- 2 gradient back
    --  3 grad selection
    -- 5 gradient Draw Obj
    -- 11 symbols
    
    --  init
      if refresh.GUI_onStart then
        GUI_gradBack(conf, obj, data, refresh, mouse)
        GUI_gradDrawObj(conf, obj, data, refresh, mouse)
        GUI_gradSelection(conf, obj, data, refresh, mouse)
        gfx.dest = 11
        gfx.setimgdim(11, -1, -1)  
        gfx.setimgdim(11, 1000,1000)  
        GUI_symbols(conf, obj, data, refresh, mouse) 
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
            if type(obj[key]) == 'table' and obj[key].show and not obj[key].blit and key~= 'set_par_tr'  then 
              GUI_DrawObj(obj, obj[key], mouse) 
            end  
          end  
      end
    
 
      
    --  render    
      gfx.dest = -1   
      gfx.a = 1
      gfx.x,gfx.y = 0,0
      --gfx.set(1,1,1,0.2)
      --gfx.rect(0,0,gfx.w, gfx.h/4,1)
    --  back
      gfx.blit(1, 1, 0, -- backgr
          0,0,gfx.w, gfx.h,
          0,0,gfx.w, gfx.h, 0,0)  
    --GUI_symbols(conf, obj, data, refresh, mouse) 
    
    -- clear X
      if mouse.Alt_state then 
        local X = 10
        gfx.set(1,0.8,0.8,0.8)
        gfx.line(mouse.x-X, mouse.y-X,mouse.x+X, mouse.y+X)
        gfx.line(mouse.x-X, mouse.y+X,mouse.x+X, mouse.y-X)
      end
    
    if obj.textbox and obj.textbox.enable then
      GUI_drawSearchFX(conf, obj, data, refresh, mouse)
     else
      if obj.tooltip ~= '' and obj.tooltip_str then GUI_drawTooltip(conf, obj, data, refresh, mouse) end
    end
    
    refresh.GUI = nil
    refresh.GUI_minor = nil
    gfx.update()
  end
