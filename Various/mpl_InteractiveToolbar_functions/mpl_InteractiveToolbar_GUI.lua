-- @description InteractiveToolbar_GUI
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex

  -- GUI functions for mpl_InteractiveToolbar 
  -- common objects functions for mpl_InteractiveToolbar
  
  ---------------------------------------------------  
  function GUI_shortcuts(char)
    --if char == 32 then Main_OnCommand(40044,0) end --Transport: Play/stop
  end
  ---------------------------------------------------  
  function Obj_init(conf)  
    local obj = {       aa = 1,
                  mode = 0,
                  --GUI_flow_time = 0.1,
                  
                  font = 'Calibri',
                  fontsz = conf.GUI_font1,
                  fontsz_entry = conf.GUI_font2,
                  fontsz_clock = conf.GUI_font3,
                  fontsz_grid_rel = conf.GUI_font4,
                  fontszFXctrl = 13,
                  col = { grey =    {0.5, 0.5,  0.5 },
                          white =   {1,   1,    1   },
                          red =     {1,   0.3,    0.3   },
                          green =   {0.3, 0.9,  0.3 },
                          greendark =   {0.2, 0.4,  0.2 },
                          blue  =   {0.5, 0.9,  1},
                          blue_bright  =   {0.2, 0.7,  1}},
                  background_col = conf.GUI_background_col,
                  background_alpha = conf.GUI_background_alpha,
                  
                  txt_a = 0.85,
                  txt_col_header = conf.GUI_colortitle,
                  txt_col_toolbar ='white', 
                  
                  grad_sz = 200,
                  b = {},             -- buttons table
                  
                  mouse_scal_time = 5,
                  mouse_scal_time2 = 0.2, -- note pos
                  mouse_scal_vol = 5,
                  mouse_scal_sendmixvol = 5,
                  mouse_scal_pitch = 5,
                  mouse_scal_pan = 1,
                  mouse_scal_float = 0.5,
                  mouse_scal_rate = 0.1,
                  mouse_scal_intMIDICC = 5,
                  mouse_scal_intMIDIchan = 10,
                  mouse_scal_FXCtrl = 60,   -- FX wheel
                  mouse_scal_FXCtrl2 = 1000, -- FX drag
                  
                  entry_w = 200*scale,      -- name w
                  entry_w2 = 90*conf.scaling*scale,     -- controls w / position
                  entry_ratio = 1*conf.scaling*scale,    -- toolbar
                  entry_h = 18*conf.scaling*scale,
                  menu_b_rect_side = 20*scale,
                  offs = 0,
                  offs2 = 2*scale,
                  frame_a_head = 1.3, -- alpha header frames
                  frame_a_entry = 0.95,   -- alpha entries frames
                  frame_a_state = 0.9 -- active state
          }
    if GetOS():match('OSX') then 
      obj.fontsz = obj.fontsz - 5
      obj.fontsz_entry = obj.fontsz_entry - 5
      obj.fontsz_clock = obj.fontsz_clock - 5
      obj.fontsz_grid_rel = obj.fontsz_grid_rel - 5
      obj.fontszFXctrl = obj.fontszFXctrl-4
    end
    
    if conf.dock_orientation == 1 then 
      obj.entry_w = gfx.w
      obj.entry_w2 = gfx.w
    end
    
    return obj             
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

-----------------------------------------------------------------------          
  function GUI_knob(o, obj)
    gfx.set(1,1,1,1)
    gfx.rect(x,y,w,h,0)
    local val = o.val
    if val == nil then val = 0 end 
    local x,y,w,h = o.x, o.y, o.w, o.h
    do return end
    if o.knob_w then 
      x = x + w/2-o.knob_w/2
      w = o.knob_w
    end
    if o.knob_yshift then 
      y = y + o.knob_yshift
    end
    local arc_w = 2
    local arc_r = math.floor(w/2)
    local ang_gr = 110
    
    local ang_val = math.rad(-ang_gr+ang_gr*2*val)
    local ang = math.rad(ang_gr)
    
    gfx.a = 0.07
    
      -- arc back
        local x_offsr = math.floor(x+w/2)
        --local diff = -math.sin(math.rad(90+ang_gr))
        local y_offsr = math.floor(y+w/2)
        for i = 0, arc_w, 0.4 do
          
          gfx.arc(x_offsr,y_offsr+1,arc_r-i,    math.rad(-ang_gr),math.rad(-90),    1)
          gfx.arc(x_offsr,y_offsr,arc_r-i,    math.rad(-90),math.rad(0),    1)
          gfx.arc(x_offsr+1,y_offsr,arc_r-i,    math.rad(0),math.rad(90),    1)
          gfx.arc(x_offsr+1,y_offsr+1,arc_r-i,    math.rad(90),math.rad(ang_gr),    1)
        end
    -- val arc
      if o.knob_col then GUI_col(o.knob_col, obj) end
      gfx.a = 0.4
      local ang_val = math.rad(-ang_gr+ang_gr*2*val)
      for i = 0, arc_w, 0.4 do
            if ang_val < math.rad(-90) then 
              gfx.arc(x+w/2-1,y_offsr+1,arc_r-i,    math.rad(-ang_gr),ang_val, 1)
             else
              if ang_val < math.rad(0) then 
                gfx.arc(x_offsr,y_offsr+1,arc_r-i,    math.rad(-ang_gr),math.rad(-90), 1)
                gfx.arc(x_offsr,y_offsr,arc_r-i,    math.rad(-90),ang_val,    1)
               else
                if ang_val < math.rad(90) then 
                  gfx.arc(x_offsr,y_offsr+1,arc_r-i,    math.rad(-ang_gr),math.rad(-90), 1)
                  gfx.arc(x_offsr,y_offsr,arc_r-i,    math.rad(-90),math.rad(0),    1)
                  gfx.arc(x_offsr+1,y_offsr,arc_r-i,    math.rad(0),ang_val,    1)
                 else
                  if ang_val < math.rad(ang_gr) then 
                    gfx.arc(x_offsr,y_offsr+1,arc_r-i,    math.rad(-ang_gr),math.rad(-90), 1)
                    gfx.arc(x_offsr,y_offsr,arc_r-i,    math.rad(-90),math.rad(0),    1)
                    gfx.arc(x+w/2+1,y_offsr,arc_r-i,    math.rad(0),math.rad(90),    1)
                    gfx.arc(x+w/2+1,y_offsr+1,arc_r-i,    math.rad(90),ang_val,    1)
                   else
                    gfx.arc(x_offsr,y_offsr+1,arc_r-i,    math.rad(-ang_gr),math.rad(-90),    1)
                    gfx.arc(x_offsr,y_offsr,arc_r-i,    math.rad(-90),math.rad(0),    1)
                    gfx.arc(x_offsr+1,y_offsr,arc_r-i,    math.rad(0),math.rad(90),    1)
                    gfx.arc(x_offsr+1,y_offsr+1,arc_r-i,    math.rad(90),math.rad(ang_gr),    1)                  
                  end
                end
              end                
            end
          end
  end
  
  
  ---------------------------------------------------
  function Obj_UpdateCom(data, mouse, obj, widgets, conf)
    
    local main_type_frame_a
    if data.obj_type_int and data.obj_type_int >=0 then main_type_frame_a = obj.frame_a_head else main_type_frame_a = 0 end
    obj.b.type_name = { x = obj.menu_b_rect_side + obj.offs,
                        y = obj.offs,
                        w = conf.GUI_contextname_w*conf.scaling,
                        h = obj.entry_h,
                        frame_a = main_type_frame_a,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt =data.obj_type}
    if conf.dock_orientation == 1 then obj.b.type_name.w = gfx.w - obj.menu_b_rect_side end
    obj.b.menu_back1 = { x = obj.offs,
                        y = obj.offs,
                        w = obj.menu_b_rect_side,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head}
    obj.b.menu_back2 = { x = obj.offs,
                        y = obj.offs+obj.entry_h,
                        w = obj.menu_b_rect_side,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry}                        
    obj.b.menu = { x = obj.offs,
                        y = obj.offs,
                        w = obj.menu_b_rect_side,
                        h = obj.entry_h*2,
                        frame_a = 0,--obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = '>',
                        func =  function()
                                  Menu2_Settings(mouse, obj, widgets, conf, data)
                                end}                        
  end 
  
  
    
    ---------------------------------------------------
  function GUI_DrawObj(o, obj, conf)
    if not o then return end
    local x,y,w,h = o.x, o.y, o.w, o.h
    if not x or not y or not w or not h then return end
    if conf.dock_orientation ==0 and o.persist_buf then x = x - obj.persist_margin end
    -- knob
      if o.is_knob==true  then  GUI_knob(o, obj) end
      
      
    -- glass back
      gfx.a = o.frame_a or 1 
      if o.outside_buf then gfx.a = o.frame_a*0.2 end
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
        if o.state_a then gfx.a = o.state_a else gfx.a = conf.state_contrast end
        gfx.rect(x,y,w,h,1)        
      end
    -- slider
      if o.is_slider and o.val then 
        local val = o.val
        if o.slider_a then gfx.a =  o.slider_a end
        if o.sider_col then GUI_col(o.sider_col, obj) end
        if not o.centered_slider then 
          val = lim(val,0,1)
          if not o.is_vertical_slider then
            gfx.rect(x,y,w*val,h,1)
           else 
            local h0 = math.floor(h * val)
            gfx.rect(x+1,y+h-h0,w-2,h0,1)
            --[[gfx.rect(x+1,
                      y+math.floor(h*(1-val)),
                      w-2,
                      lim(  math.floor(h*val), 0, h-y-math.floor(h*(1-val)) ),
                          1)]]
          end
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
      
      
    -- tri
      if o.is_triangle_slider then
        gfx.set(1,1,1,0.2)
        gfx.triangle(x,y+h,
                     x+w*o.val, y+h-h*o.val,
                     x+w*o.val, y+h)
      end 
      
      
    -- text 
      local txt
      if not o.txt then txt = '' else txt = tostring(o.txt) end
      --if not o.txt then txt = '>' else txt = o.txt..'|' end
      ------------------ txt
        if txt and w > 0 then 
          if o.txt_col then GUI_col(o.txt_col, obj)else GUI_col('white', obj) end
          if o.txt_a then 
            gfx.a = o.txt_a 
            if o.outside_buf then gfx.a = o.txt_a*0.8 end
           else 
            gfx.a = 0.8 
          end
          local fontsz= o.fontsz or obj.fontsz
          
          gfx.setfont(1, obj.font, fontsz*font_coeff )
          local shift = 2
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
            gfx.y = y+ h/2 - com_texth/2 + i*gfx.texth
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
              
    -- peaks
      if o.peaks_src then
        --GUI_Goniometer(o, obj, conf)
        -- levels
        local meter_w = 4
        local entries = 3
        
        local RMSL = 0
        local entries = math.min(#o.peaks_src.peakL, entries)
        for i = 1, entries do RMSL = math.abs(o.peaks_src.peakL[i]) + RMSL end
        RMSL = RMSL / entries
        gfx.rect(x + conf.master_buf + 5, y+h-h*RMSL, meter_w,h*RMSL)
        
        local RMSR = 0
        local entries = math.min(#o.peaks_src.peakR, entries)
        for i = 1, entries do RMSR = math.abs(o.peaks_src.peakR[i]) + RMSR end
        RMSR = RMSR / entries
        gfx.rect(x + conf.master_buf + 5 + meter_w, y+h-h*RMSR, meter_w,h*RMSR)
        
        -- goniometer
        local gonio_h = obj.entry_h*2
        local gonio_x = x + conf.master_buf + 5 + meter_w*2
        local gonio_w = obj.entry_h*2
        local gonio_y = y+ h - gonio_h-1
        
        gfx.set(1,1,1,0.1)
        --gfx.rect(gonio_x,gonio_y+2,gonio_w,gonio_h-2, 0)
        
        -- oscillogram
        local a = 0.6
        local gonio_lim = 7
        for i = 1, #o.peaks_src.peakL do
            -- L
            local peakvalL = o.peaks_src.peakL[i]
            local peakvalR = o.peaks_src.peakR[i]
            local x0 = x +conf.master_buf - i + 3
            
            
            if peakvalL > 1 then 
              gfx.set(1,0.1,0.1, a)
              gfx.line(x0+1, y, x0, y+h/2-1)
             else
              peakvalL = lim(peakvalL, 0,1)
              gfx.set(1,1,1, a)     
              gfx.line( x0,
                        y +  h/4 -peakvalL*h/4,
                        x0,
                        y +  h/4 +peakvalL*h/4)
             end
             
            --R
            if peakvalR > 1 then 
              gfx.set(1,0.1,0.1, a)
              gfx.line(x0, y+h/2, x0, y+h-1)
             else
              peakvalL = lim(peakvalL, 0,1)
              gfx.set(1,1,1,a)   
              gfx.line( x0,
                        y +  3*h/4 -peakvalR*h/4,
                        x0,
                        y +  3*h/4 +peakvalR*h/4)
             end
        end                 
      end
  end
  ---------------------------------------------------
  function GUI_Goniometer(o, obj, conf)
  
  end
  ---------------------------------------------------
  --[[--[[
@init
off = 50000;
rot=-45*0.017453292;
MAXDRAWSPLS = 100;

@sample
s0 = sign(spl0);
s1 = sign(spl1);
angle = atan( spl0 / spl1 );
(s0 == 1 && s1 == -1) || (s0 == -1 && s1 == -1) ? angle += 3.141592654;
s0 == -1 && s1 == 1 ? angle += 6.283185307;
spl1 == 0 ? spl0 > 0 ? angle = 1.570796327 : angle = 4.71238898;
spl0 == 0 ? spl1 > 0 ? angle = 0 : angle = 3.141592654;
radius = sqrt( sqr(spl0)+sqr(spl1) ) ;
angle -= rot;
0[b] = cos(angle)*radius;
off[b] = sin(angle)*radius;
b<MAXDRAWSPLS ? b += 1;
s0 != s1 ? phC-=1:phC+=1;

@gfx

size = min(gfx_w,gfx_h-20);
sizeH = size/2;
sizeDSqr05 = sizeH * 0.70710681;
x = y = sizeH;

i = 1000;
while (
   gfx_x=x; gfx_y=y;
   x=sizeH+0[i]*sizeDSqr05;
   y=sizeH-off[i]*sizeDSqr05;
   gfx_r=0.5; gfx_g=1; gfx_b=0; gfx_a=0.6;
  gfx_lineto(x,y,0);
  (i-=1)>0;
);
b=0;]]  
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
  function GUI_Main(obj, cycle_cnt, redraw, data, clock, conf)
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
        local r,g,b,a = 0.9,0.9,1,0.58
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
          if obj.b then 
            for key in spairs(obj.b) do 
              if conf.dock_orientation ==0  then
                if not obj.b[key].persist_buf and not obj.b[key].outside_buf then GUI_DrawObj(obj.b[key], obj, conf) end
               elseif conf.dock_orientation ==1  then
                if not obj.b[key].outside_buf then GUI_DrawObj(obj.b[key], obj, conf) end
              end
            end 
          end
      end

      local x_persist_draw = obj.persist_margin
      local w_persist_draw = gfx.w - obj.persist_margin      
      local buf_dest = 11
      if redraw == 1 then
        -- refresh backgroung
          gfx.dest = buf_dest
          gfx.setimgdim(buf_dest, -1, -1)          
          gfx.setimgdim(buf_dest, w_persist_draw, gfx.h) 
        -- refresh all buttons
          if obj.b then 
            for key in spairs(obj.b) do 
              if conf.dock_orientation ==0 and obj.b[key].persist_buf then GUI_DrawObj(obj.b[key], obj, conf) end
            end 
          end
      end
                  
      gfx.dest = -1   
    ----  render    
      
      gfx.a = 1
    --  backgr
      --gfx.set(1,1,1,0.18)
      GUI_col(obj.background_col)
      gfx.a = obj.background_alpha
      gfx.rect(0,0,gfx.w,gfx.h, 1)
      --[[gfx.blit(2, 1, 0, -- backgr
          0,0,obj.grad_sz, obj.grad_sz,
          0,0,gfx.w, gfx.h, 0,0)]]
          
          
    -- butts  
      gfx.a = 1
      gfx.blit(10, 1, 0,
          0,0,gfx.w, gfx.h,
          0,0,gfx.w, gfx.h, 0,0)  
      gfx.a = 1
      gfx.blit(11, 1, 0,  -- persist buf
          0,0,w_persist_draw, gfx.h,
          x_persist_draw,0,w_persist_draw, gfx.h, 0,0)  

    -- refresh outside_buf buttons
      gfx.dest = -1
      
      if data.play then 
        if obj.b.obj_pers_clock then obj.b.obj_pers_clock.txt = data.playcur_pos_format end
        if obj.b.obj_pers_mastermeter then obj.b.obj_pers_mastermeter.txt = data.masterdata.rmsR end
       else
        if obj.b.obj_pers_clock then obj.b.obj_pers_clock.txt = data.editcur_pos_format end
      end
      if obj.b.obj_pers_chordlive then obj.b.obj_pers_chordlive.txt = data.retrospectchordkey..' '..data.retrospectchordname end
      GUI_DrawObj(obj.b.obj_pers_clock, obj, conf)
      GUI_DrawObj(obj.b.obj_pers_master, obj, conf)
      GUI_DrawObj(obj.b.obj_pers_mastermeter, obj, conf)
      GUI_DrawObj(obj.b.obj_pers_chordlive, obj, conf)
                                        
    --[[ draw vrs
      gfx.x, gfx.y = gfx.w-150,0
      gfx.set(0,0,0,1)
      gfx.setfont(1,'Arial', 13)
      gfx.set(1,1,1,0.5)
      gfx.rect(gfx.w-150,0,150, 10)
      gfx.set(0,0,0,1)
      gfx.drawstr('MPL_InfoTool '..data.vrs)]]
      
    gfx.update()
  end
  
  -----------------------------------------------------------------------
  function Menu2_Settings(mouse, obj, widgets, conf, data)
    local Grid_DC_cond = ''
    if data.MM_grid_ignoreleftdrag == 1 then Grid_DC_cond = '#' end
    local t = { { str = data.scr_title..' v'..data.vrs,
                  hidden = true},
                { str = '|#Links / Info'},
                {str = 'Help',
                 func = function()  
ClearConsole()                 
msg(
[[  Here is the list of all supported widgets for MPL`s InteractiveToolbar.
  You can edit them via menu (recommended) or open /REAPER/Scripts/mpl_InteractiveToolbar_functions/mpl_InteractiveToolbar_Config.ini in any text editor
  After changing configuration, you need to restart script. If you do it from Action List, click 'Terminate Instances' when REAPER will ask for what to do with already running ReaScript.
  Buttons tags are added to the buttons module interleaved.
  Persist modules are in right-to-left order.

      Modules info:
        Item
          #position editing position
          #length editing length
          #snap editing take snap offset
          #endedge editing position of item refering to its end
          #length editing length
          #offset editing take source offset
          #fadein editing fadein
          #fadeout editing fadeout
          #vol editing item volume
          #transpose editing item pitch
          #pan editing take pan
          #srclen editing source length (for loop source), update require rebuilding peaks
          #color set item color from system dialog or use Airon`s Color Swatch tool
          #leftedge editing both offset and positions (simulate leftedge drag)
          #buttons
            #lock toggle lock
            #loop toggle loop source
            #mute toggle mute
            #srcreverse (Audio and Multiple only)
            #preservepitch (Audio and Multiple only) toggle take preserve pitch
            #chanmode (Audio and Multiple only) editing take channel mode
            #bwfsrc (Audio and Multiple only) Action Item: Move to source preferred position (used by BWF)
            #timebase allow to loop through item timebase modes, rightclick reset to project default
        Envelope
          #floatfx float FX related with current envelope
          #position editing point position
          #value editing point value, volume envelopes use db<>linear convertion
          #AIlooplen edit loop length of Automation Item
        Track
          #vol editing track volume
          #pan editing track pan
          #fxlist Show FX in chain, LeftClick float FX, Shift+Click bypass FX
          #sendto Small tool for quick creating sends from selected track, to have potential sends in the list add them via selecting and 'Mark as predefined send'
          #delay get/set value in seconds for 'JS: time adjustment'
          #troffs change track offset (REAPER 6.0+)
          #chsendmixer shows all send faders if sends existed for the first selected track. Ctrl+drag move on any slider acts as a VCA.
          #chrecvmixer shows all receive faders if receives existed for the first selected track. Ctrl+drag move on any slider acts as a VCA.
          #fxcontrols allow to store some FX macro controls stores per track (although params can be stored from another track FX). Rightclick slider for options.
          #freeze allow to freeze/unfreeze track, show freeze depth
          #color set track color from system dialog or use Airon`s Color Swatch tool
          #buttons
            #polarity Toggle inverted polarity ("phase" in REAPER) of track audio output
            #parentsend Toggle Master/Parent send
        MIDIEditor
          #position perform a PPQ<>ProjectTime convertion as absolute time of note
          #notelen change note length , MIDI code based on juliansader MIDI scripts (see ReaTeam repo).
          #CCval change CC value, MIDI code based on juliansader MIDI scripts (see ReaTeam repo).
          #notepitch change note pitch, MIDI code based on juliansader MIDI scripts (see ReaTeam repo).
          #notevel change note velocity, MIDI code based on juliansader MIDI scripts (see ReaTeam repo).
          #midichan change event channel, MIDI code based on juliansader MIDI scripts (see ReaTeam repo).
        Persist
          #grid show current grid, allow to change grid lines visibility and relative snap
          #swing show current swing value, 'SWING' text is a toggle
          #timeselend editing time selection end
          #timeselstart editing time selection start, preserve length
          #timesellen editing time selection length
          #timeselLeftEdge editing time selection start
          #lasttouchfx editing last touched FX parameter
          #transport show/editing current play state, RightClick - pause, LeftClick - stop/revert to start position, Cltr+Left - record
          #bpm shows/edit tempo and time signature for project (or tempo marker falling at edit cursor if any)
          #clock shows play/edit cursor positions
          #tap Get a tempo from tap, allow to distribute that info in different ways. RightClick reset taps data and force current tempo to convertion chart. Shift click for entering new value.     
          #master Shows master track peaks
          #mastermeter Show master RMS/LUFS
          #masterchan Hover around master width. -100% button makes channes swapped, mono set width to zero. Both change panmode to stereo pan.
          #chordlive Show note / chord of recent played incoming MIDI events
          #mchancnt Number of master channels
 ]] )  
                 
                        end   
                }  ,
                { str = 'Cockos Forum thread|',
                  func = function() F_open_URL('http://forum.cockos.com/showthread.php?t=203393') end  } , 
                  
                { str = '>Options'},
                { str = 'Context: Force track context on change track selection',
                  state = conf.use_context_specific_conditions==1,
                  func = function() conf.use_context_specific_conditions = math.abs(-1+conf.use_context_specific_conditions) ExtState_Save(conf) redraw = 2 end }  ,                   
                
                { str = 'Controls: Always use X axis control',
                  state = conf.always_use_x_axis==1,
                  func = function() conf.always_use_x_axis = math.abs(-1+conf.always_use_x_axis) ExtState_Save(conf) redraw = 2 end }  ,
                { str = '>Controls: Time formatting mode'},
                { str = 'Ruler linked',
                  state = conf.ruleroverride == -1,
                  func = function() conf.ruleroverride = -1 ExtState_Save(conf) redraw = 2 end} ,    
                { str = 'Time',
                  state = conf.ruleroverride == 0,
                  func = function() conf.ruleroverride = 0 ExtState_Save(conf) redraw = 2 end} ,   
                { str = 'measures.beats',
                  state = conf.ruleroverride == 2,
                  func = function() conf.ruleroverride = 2 ExtState_Save(conf) redraw = 2 end} ,  
                { str = 'seconds',
                  state = conf.ruleroverride == 3,
                  func = function() conf.ruleroverride = 3 ExtState_Save(conf) redraw = 2 end} ,  
                { str = 'samples',
                  state = conf.ruleroverride == 4,
                  func = function() conf.ruleroverride = 4 ExtState_Save(conf) redraw = 2 end} ,  
                { str = 'h:m:s:f|<',
                  state = conf.ruleroverride == 5,
                  func = function() conf.ruleroverride = 5 ExtState_Save(conf) redraw = 2 end} , 
                                  
                { str = '>Controls: MouseModifiers'},
                --{ str = ''},
                { str = 'Doubleclick on value to type value',
                  state = conf.MM_doubleclick==0,
                  func = function() conf.MM_doubleclick = 0 ExtState_Save(conf) redraw = 2 end }  ,                   
                { str = 'Doubleclick on value to reset value|',
                  state = conf.MM_doubleclick==1,
                  func = function() conf.MM_doubleclick = 1 ExtState_Save(conf) redraw = 2 end }  ,  
                { str = 'Rightclick on value to reset value',
                  state = conf.MM_rightclick==0,
                  func = function() conf.MM_rightclick = 0 ExtState_Save(conf) redraw = 2 end }  ,                   
                { str = 'Rightclick on value to type value|<',
                  state = conf.MM_rightclick==1,
                  func = function() conf.MM_rightclick = 1 ExtState_Save(conf) redraw = 2 end }  ,                   
                
                { str = 'Run in native-API-only mode for Track Context|<',
                  state = conf.runnatAPI==1,
                  func = function() conf.runnatAPI = math.abs(1-conf.runnatAPI) ExtState_Save(conf) redraw = 2 end }  ,                 
                
                  
                { str = '>Theme'},
                
                { str = 'Scaling (script restart required)',
                  func = function()                           
                            local ret, scaling = GetUserInputs( conf.scr_title, 1, 'Scaling',conf.scaling )
                            if  ret and tonumber(scaling) then
                                conf.scaling = lim(tonumber(scaling), 0.7, 4)
                                ExtState_Save(conf)
                                redraw = 2 
                                DataUpdate(data, mouse, widgets, obj, conf)                           
                            end
                          end}  ,                
                
                
                { str = 'Font size',
                  func = function() 
                            
                            local ret, ftsz = GetUserInputs( conf.scr_title, 4, 'Font 1,Font 2,Clock,Grid_widget', 
                              conf.GUI_font1..','
                              ..conf.GUI_font2..','
                              ..conf.GUI_font3..','
                              ..conf.GUI_font4 )
                            if not ret then return end
                            
                            local f_sz = {}
                            for num in ftsz:gmatch('[^%,]+') do f_sz[#f_sz+1] = tonumber(num) end
                            
                            -- set font1 
                              if f_sz[1] then 
                                conf.GUI_font1 = f_sz[1]
                                ExtState_Save(conf)
                                obj = Obj_init(conf)
                                redraw = 2
                              end

                            -- set font2
                              if f_sz[2] then 
                                conf.GUI_font2 = f_sz[2]
                                ExtState_Save(conf)
                                obj = Obj_init(conf)
                                redraw = 2
                              end

                            -- set font2
                              if f_sz[3] then 
                                conf.GUI_font3 = f_sz[3]
                                ExtState_Save(conf)
                                obj = Obj_init(conf)
                                redraw = 2
                              end
                              
                              -- set font2
                                if f_sz[4] then 
                                  conf.GUI_font4 = f_sz[4]
                                  ExtState_Save(conf)
                                  obj = Obj_init(conf)
                                  redraw = 2
                                end    
                            
                            MB('Please restart script for applying changes', conf.scr_title , 0 )                                                        
                          end },
                { str = 'Text color (titles)',
                  func = function()                           
                            local retval, colorOut  = GR_SelectColor(  ) 
                            if  retval ~= 0 then
                                if GetOS():match('OSX') then
                                  local r, g, b = ColorFromNative(colorOut)
                                  colorOut = ColorToNative( b, g, r )
                                end
                                
                                conf.GUI_colortitle = colorOut
                                ExtState_Save(conf)
                                local temp_t = Obj_init(conf)
                                obj.txt_col_header = temp_t.txt_col_header
                                redraw = 2                            
                            end
                          end} , 
                { str = 'Background color',
                  func = function()                           
                            local retval, colorOut  = GR_SelectColor(  ) 
                            if  retval ~= 0 then
                                conf.GUI_background_col = colorOut
                                ExtState_Save(conf)
                                local temp_t = Obj_init(conf)
                                obj.background_col = temp_t.background_col
                                redraw = 2                            
                            end
                          end}    ,
                { str = 'Background alpha',
                  func = function()                           
                            local ret, ftsz = GetUserInputs( conf.scr_title, 1, 'Background alpha',conf.GUI_background_alpha )
                            if  ret and tonumber(ftsz) then
                                conf.GUI_background_alpha = lim(tonumber(ftsz), 0, 2)
                                ExtState_Save(conf)
                                local temp_t = Obj_init(conf)
                                obj.background_alpha = temp_t.background_alpha
                                redraw = 2                            
                            end
                          end}  ,
                { str = 'Toggle buttons contrast',
                  func = function()                           
                            local ret, stctrst = GetUserInputs( conf.scr_title, 1, 'Toggle buttons contrast',conf.state_contrast )
                            if  ret and tonumber(stctrst) then
                                conf.state_contrast = lim(tonumber(stctrst), 0, 1)
                                ExtState_Save(conf)
                                local temp_t = Obj_init(conf)
                                obj.state_contrast = temp_t.state_contrast
                                redraw = 2                            
                            end
                          end}  ,                          
                          
                          
                { str = 'Context name width|<',
                  func = function()                           
                            local ret, str = GetUserInputs( conf.scr_title, 1, 'Context name width (def. = 200)',conf.GUI_contextname_w )
                            if  ret and tonumber(str) then
                                conf.GUI_contextname_w = lim(tonumber(str), 0, 300)
                                ExtState_Save(conf)
                                redraw = 2                            
                            end
                          end}  ,                          
                          
                          
                  
 
                                                                                                                                                                        
                { str = '|#Contexts/Widgets'}  ,
                { str = '>No context'}, 
                { str = 'Run external action when no active context|<',
                  state = conf.actiononchangecontext_no~='',        
                  func =  function() 
                            local ret, ret_val = GetUserInputs( conf.scr_title, 1, 'Action ID (empty to disable)', conf.actiononchangecontext_no )
                            if ret then
                              conf.actiononchangecontext_no = ret_val
                              ExtState_Save(conf)
                            end
                          end} ,                   
                { str = '>Item: All '}, 
                --[[{ str = '# #color'},
                { str = 'Use ReaPack/Airon_Colour Swatch.lua|',
                  state = conf.use_aironCS_item==1,
                  func = function() conf.use_aironCS_item = math.abs(1-conf.use_aironCS_item) ExtState_Save(conf) redraw = 2 end }  ,    ]]    --deprecated at 2.17                         
                { str = '# #lenght'},                  
                { str = 'Edit length relatively on typing edits|',    
                  state = conf.relative_it_len==1,              
                  func = function() conf.relative_it_len = math.abs(1-conf.relative_it_len) ExtState_Save(conf) redraw = 2 end} ,  
                { str = 'Run external action on founding item context',
                  state = conf.actiononchangecontext_item~='',        
                  func =  function() 
                            local ret, ret_val = GetUserInputs( conf.scr_title, 1, 'Action ID (empty to disable)', conf.actiononchangecontext_item )
                            if ret then
                              conf.actiononchangecontext_item = ret_val
                              ExtState_Save(conf)
                            end
                          end} ,                                  
                { str = 'Ignore all item contexts|<',    
                  state = conf.ignore_context&(1<<0) == (1<<0),              
                  func = function() Menu_IgnoreContext(conf, 0) end} ,                                   
                
                { str = '>Item: Empty '}, 
                { str = 'Widgets order|<',                  
                  func = function() Menu_ChangeOrder(widgets, data, conf, 0 ) end} , 
                { str = '>Item: MIDI'}, 
                { str = 'Run external action on founding item context',
                  state = conf.actiononchangecontext_itemM~='',        
                  func =  function() 
                            local ret, ret_val = GetUserInputs( conf.scr_title, 1, 'Action ID (empty to disable)', conf.actiononchangecontext_itemM )
                            if ret then
                              conf.actiononchangecontext_itemM = ret_val
                              ExtState_Save(conf)
                            end
                          end} ,                 
                 { str = 'Widgets order',
                  func = function() Menu_ChangeOrder(widgets, data, conf, 1 ) end} ,
                { str = 'Buttons order|<',
                  func = function() Menu_ChangeOrder(widgets, data, conf, 1, true ) end} , 
                { str = '>Item: Audio'},
                { str = 'Run external action on founding item context',
                  state = conf.actiononchangecontext_itemA~='',        
                  func =  function() 
                            local ret, ret_val = GetUserInputs( conf.scr_title, 1, 'Action ID (empty to disable)', conf.actiononchangecontext_itemA )
                            if ret then
                              conf.actiononchangecontext_itemA = ret_val
                              ExtState_Save(conf)
                            end
                          end} ,                 
                { str = 'Widgets order',
                  func = function() Menu_ChangeOrder(widgets, data, conf, 2 ) end} ,
                { str = 'Buttons order|<',
                  func = function() Menu_ChangeOrder(widgets, data, conf, 2, true ) end} ,
                { str = '>Item: Multiple'},
                { str = 'Widgets order',
                  func = function() Menu_ChangeOrder(widgets, data, conf, 3 ) end} ,
                { str = 'Buttons order|<',
                  func = function() Menu_ChangeOrder(widgets, data, conf, 3, true ) end} , 
                  
                { str = '>Envelope'},
                { str = 'Run external action on founding envelope context',
                  state = conf.actiononchangecontext_env~='',        
                  func =  function() 
                            local ret, ret_val = GetUserInputs( conf.scr_title, 1, 'Action ID (empty to disable)', conf.actiononchangecontext_env )
                            if ret then
                              conf.actiononchangecontext_env = ret_val
                              ExtState_Save(conf)
                            end
                          end} ,                  
                { str = 'Ignore',    
                  state = conf.ignore_context&(1<<6) == (1<<6),              
                  func = function() Menu_IgnoreContext(conf, 6) end} , 
                { str = 'Widgets order|<',
                  func = function() Menu_ChangeOrder(widgets, data, conf, 6 ) end} , 
                  
                { str = '>Track'},
                --[[{ str = '# #color'},
                { str = 'Use ReaPack/Airon_Colour Swatch.lua|',
                  state = conf.use_aironCS==1,
                  func = function() conf.use_aironCS = math.abs(1-conf.use_aironCS) ExtState_Save(conf) redraw = 2 end }  , ]]  --deprecated at 2.17    
                { str = '# #vol'},                  
                { str = 'Use big knob in vertical mode|',
                  state = conf.trackvol_slider==1,
                  func = function() conf.trackvol_slider = math.abs(1-conf.trackvol_slider) ExtState_Save(conf) redraw = 2 end }  ,                  
                   
                { str = 'Run external action on founding track context',
                  state = conf.actiononchangecontext_track~='',        
                  func =  function() 
                            local ret, ret_val = GetUserInputs( conf.scr_title, 1, 'Action ID (empty to disable)', conf.actiononchangecontext_track )
                            if ret then
                              conf.actiononchangecontext_track = ret_val
                              ExtState_Save(conf)
                            end
                          end} ,                                   
                { str = 'Ignore',    
                  state = conf.ignore_context&(1<<7) == (1<<7),              
                  func = function() Menu_IgnoreContext(conf, 7) end} , 
                { str = 'Widgets order',
                  func = function() Menu_ChangeOrder(widgets, data, conf, 7 ) end} ,
                { str = 'Buttons order|<',
                  func = function() Menu_ChangeOrder(widgets, data, conf, 7, true ) end} ,
                  
                { str = '>MIDI editor'},
                { str = '# #notepitch'},   
                  
                { str = '>MIDI Pitch formatting mode'},
                { str = 'Pitch only',
                  state = conf.pitch_format == 0,
                  func = function() conf.pitch_format = 0 ExtState_Save(conf) redraw = 2 end} ,    
                { str = 'C#',
                  state = conf.pitch_format == 1,
                  func = function() conf.pitch_format = 1 ExtState_Save(conf) redraw = 2 end} ,   
                { str = 'D♭',
                  state = conf.pitch_format == 2,
                  func = function() conf.pitch_format = 2 ExtState_Save(conf) redraw = 2 end} ,  
                { str = 'Do#',
                  state = conf.pitch_format == 3,
                  func = function() conf.pitch_format = 3 ExtState_Save(conf) redraw = 2 end} ,  
                { str = 'Re♭',
                  state = conf.pitch_format == 4,
                  func = function() conf.pitch_format = 4 ExtState_Save(conf) redraw = 2 end} ,  
                { str = 'Frequency',
                  state = conf.pitch_format == 5,
                  func = function() conf.pitch_format = 5 ExtState_Save(conf) redraw = 2 end} ,                    
                { str = '|Octave shift|<|',
                  func =  function() 
                            local ret, ret_val = GetUserInputs( conf.scr_title, 1, 'Set octave shift', conf.oct_shift )
                            if ret and tonumber(ret_val)  then
                              conf.oct_shift = tonumber(ret_val) 
                              ExtState_Save(conf)
                              redraw = 2 
                            end
                          end} , 
                { str = 'Run external action on founding ME context',
                  state = conf.actiononchangecontext_ME~='',        
                  func =  function() 
                            local ret, ret_val = GetUserInputs( conf.scr_title, 1, 'Action ID (empty to disable)', conf.actiononchangecontext_ME )
                            if ret then
                              conf.actiononchangecontext_ME = ret_val
                              ExtState_Save(conf)
                            end
                          end} ,  
                          
                          
                { str = 'Force ME context if selected take is MIDI',    
                  state = conf.miditake_forceMEcontext==1,              
                  func = function() conf.miditake_forceMEcontext = math.abs(1-conf.miditake_forceMEcontext)end , 
                  },                          
                { str = 'Ignore',    
                  state = conf.ignore_context&(1<<8) == (1<<8),              
                  func = function() Menu_IgnoreContext(conf, 8) end , 
                  },
                  
                  
                { str = 'Widgets order|<',
                  func = function() Menu_ChangeOrder(widgets, data, conf, 8 ) end} ,  
                                                                                                     
                { str = '>Persistent modules'},
               
                { str = '# #grid and #swing'},
                { str = '(#grid only) Ignore left drag, pass left click as toggle snap',
                  state = conf.MM_grid_ignoreleftdrag==1,
                  func = function() conf.MM_grid_ignoreleftdrag = math.abs(1-conf.MM_grid_ignoreleftdrag) ExtState_Save(conf) redraw = 2 end }  ,                 
                { str = Grid_DC_cond..'DoubleClick on grid/swing value: disabled',
                  state = conf.MM_grid_doubleclick==2,
                  func = function() conf.MM_grid_doubleclick = 2 ExtState_Save(conf) redraw = 2 end }  ,
                { str = Grid_DC_cond..'DoubleClick on grid/swing value open Snap/Grid dialog',
                  state = conf.MM_grid_doubleclick==0,
                  func = function() conf.MM_grid_doubleclick = 0 ExtState_Save(conf) redraw = 2 end }  ,
                { str = Grid_DC_cond..'DoubleClick on grid/swing value reset grid to custom value',
                  state = conf.MM_grid_doubleclick==1,
                  func = function() conf.MM_grid_doubleclick = 1 ExtState_Save(conf) redraw = 2 end }  , 
                { str = Grid_DC_cond..'Set default grid',
                  func =  function() 
                            local ret, grid_out = GetUserInputs( conf.scr_title, 1, 'Default grid',
                                                                ({MPL_GetFormattedGrid(conf.MM_grid_default_reset_grid )})[2])
                            if ret then
                              local f = load('return '..grid_out)
                              if not f then MB('Wrong value',conf.scr_title,0 ) return end
                              conf.MM_grid_default_reset_grid = f()
                              ExtState_Save(conf) 
                              redraw = 2 
                            end
                          end }  ,   
                { str = Grid_DC_cond..'Set default MIDI grid',
                  func =  function() 
                            local ret, grid_out = GetUserInputs( conf.scr_title, 1, 'Default MIDI grid',
                                                                ({MPL_GetFormattedGrid(conf.MM_grid_default_reset_MIDIgrid )})[2])
                            if ret then
                              local f = load('return '..grid_out)
                              if not f then MB('Wrong value',conf.scr_title,0 ) return end
                              conf.MM_grid_default_reset_MIDIgrid = f()
                              ExtState_Save(conf) 
                              redraw = 2 
                            end
                          end }  ,                                                             
                { str = 'Rightclick on grid value open Snap/Grid dialog',
                  state = conf.MM_grid_rightclick==0,
                  func = function() conf.MM_grid_rightclick = 0 ExtState_Save(conf) redraw = 2 end }  ,                 
                { str = 'Rightclick on grid value toggle snap|',
                  state = conf.MM_grid_rightclick==1,
                  func = function() conf.MM_grid_rightclick = 1 ExtState_Save(conf) redraw = 2 end }  ,                   
                { str = '# #clock'},
                
                { str = 'Show additional time',
                  state = conf.persist_clock_showtimesec > 0,
                  func =  function() 
                            if conf.persist_clock_showtimesec> 0 then conf.persist_clock_showtimesec = 0 else conf.persist_clock_showtimesec = 1 end
                          end} ,                  
                { str = 'Show additional time in seconds',
                  state = conf.persist_clock_showtimesec == 1,  
                  func = function() conf.persist_clock_showtimesec = 1  end} ,                   
                { str = 'Show additional time in h:m:s:f|',
                  state = conf.persist_clock_showtimesec ==2,  
                  func = function() conf.persist_clock_showtimesec = 2  end} ,                  
                

                { str = '# Time selection widgets format'},
                
                { str = 'Follow local override',
                  state = conf.timiselwidgetsformatoverride == -2,
                  func =  function() conf.timiselwidgetsformatoverride = -2 end} ,                  
                { str = 'Project default',
                  state = conf.timiselwidgetsformatoverride == -1,
                  func =  function() conf.timiselwidgetsformatoverride = -1 end} ,               
                { str = 'Time',
                  state = conf.timiselwidgetsformatoverride == 0,
                  func = function() conf.timiselwidgetsformatoverride = 0 end} ,   
                { str = 'measures.beats',
                  state = conf.timiselwidgetsformatoverride == 2,
                  func = function() conf.timiselwidgetsformatoverride = 2 end} ,   
                { str = 'seconds',
                  state = conf.timiselwidgetsformatoverride == 3,
                  func = function() conf.timiselwidgetsformatoverride = 3 end} ,   
                { str = 'samples',
                  state = conf.timiselwidgetsformatoverride == 4,
                  func = function() conf.timiselwidgetsformatoverride = 4 end} ,   
                { str = 'h:m:s:f|',
                  state = conf.timiselwidgetsformatoverride == 5,
                  func = function() conf.timiselwidgetsformatoverride = 5 end} ,   
                  { str = '#master'},
                { str = 'Samples buffer (default = 100)|',
                  func = function()
                            local ret, str = GetUserInputs( conf.scr_title, 1, 'Samples buffer', conf.master_buf)
                            if ret and tonumber(str ) then 
                              conf.master_buf = lim(  math.floor(tonumber(str)), 10, 500) 
                              data.masterdata.peakL = {}
                              data.masterdata.peakR = {}
                            end
                          end},
                
                { str = 'Disable persistent modules',    
                  state = conf.ignore_context&(1<<9) == (1<<9),              
                  func = function() Menu_IgnoreContext(conf, 9) end} ,       
                                  
                { str = 'Widgets order|<',
                  func = function() Menu_ChangeOrder(widgets, data, conf, 9 ) end} , 
                  
                  
                  
                  
                {str = '|>Context and widgets configuration'},
                { str = 'Enable all contexts + persistent widgets',          
                  func =function() 
                          conf.ignore_context = 0
                          ExtState_Save(conf) 
                          redraw = 2 
                        end} ,                  
                { str = 'Disable all contexts + persistent widgets',          
                  func =function() 
                          Menu_IgnoreContext(conf, 0, 0)  -- item
                          Menu_IgnoreContext(conf, 6, 0)  -- env
                          Menu_IgnoreContext(conf, 7, 0)  -- tr
                          Menu_IgnoreContext(conf, 8, 0)  -- midi
                          Menu_IgnoreContext(conf, 9, 0)  -- persist
                        end} ,   
                { str = '|Use custom color change tool',          
                  func =function() 
                          local ret, str = GetUserInputs( conf.scr_title, 1, 'Script ID (from action list),extrawidth=400', conf.use_custom_color_editor)
                          if ret  then 
                            conf.use_custom_color_editor = str
                            ExtState_Save(conf) 
                            redraw = 2 
                          end
                        end} ,                         
                { str = '|Edit custom name mapping',          
                  func =function() 
                          local ret, str = GetUserInputs( conf.scr_title, 1, 'Custom name mapping,extrawidth=400', conf.customname_map)
                          if ret  then 
                            conf.customname_map = str
                            ExtState_Save(conf) 
                            redraw = 2 
                          end
                        end} ,                  
                { str = 'Clear custom name mapping',          
                  func =function() 
                          conf.customname_map = ''
                          ExtState_Save(conf) 
                          redraw = 2 
                        end} , 
                        
                        
                {str = '|Reset all widgets order to default',
                 func = function()  
                          local ret = MB('Are you sure you want to reset widget configuration of MPL InteractiveToolbar?',  'MPL InteractiveToolbar', 4)
                          if ret == 6 then 
                            Config_Reset(data.conf_path) 
                            Config_ParseIni(data.conf_path, widgets)
                            redraw = 2
                          end
                        end
                            }  ,                               
                {str = 'Edit widget order manually|<|',
                 func = function()  F_open_URL('"" "'..data.conf_path..'"') end}  ,   
                 
                 
                 
                 
                 
                {str = 'Dock MPL InteractiveToolbar',
                                 func = function() 
                                          if conf.dock > 0 then conf.dock = 0 else 
                                            if conf.lastdockID and conf.lastdockID > 0 then conf.dock = conf.lastdockID else conf.dock = 1  end
                                          end
                                          gfx.quit() 
                                          gfx.init('MPL '..conf.scr_title,conf.wind_w, conf.wind_h, conf.dock , conf.wind_x, conf.wind_y)end,
                                 state = conf.dock > 0 }, 
                {str = 'Use vertical widgets orientation',
                                 func = function() 
                                          conf.dock_orientation = math.abs(1-conf.dock_orientation)
                                          gfx.quit() 
                                          gfx.init('MPL '..conf.scr_title,100, gfx.h, conf.dock , conf.wind_x, conf.wind_y)
                                          redraw = 1
                                        end,
                                 state = conf.dock_orientation == 1 },                                  
                                 
                {str = 'Refresh GUI',
                 func = function() 
                          SCC_trig = true 
                          Config_ParseIni(data.conf_path, widgets)
                          redraw = 2
                        end}  ,                  
                {str = 'Close MPL InteractiveToolbar',
                 func = function() force_exit = true end} ,                   
                        
                        
                                                                                                                                                           
              }
    Menu(mouse, t)
    ExtState_Save(conf) 
    redraw = 2
  end
  -----------------------------------------------------------
  function Menu_IgnoreContext(conf, context_int, set)
    local byte_num = 1<<context_int
    
    if conf.ignore_context&byte_num == byte_num then 
      if not set or (set and set == 1) then conf.ignore_context = conf.ignore_context - byte_num end
     else 
      if not set or (set and set == 0) then conf.ignore_context = conf.ignore_context + byte_num end
    end
    ExtState_Save(conf) 
    redraw = 2 
  end   
  -----------------------------------------------------------
  function Menu_ChangeOrder(widgets, data, conf, widgtype, is_buttons )
    local cur_str = ''
    local key
    if not widgtype or not tonumber(widgtype) then 
      MB('Configuration file damaged. Reset configuration or try to fix manually (Menu/Global configuration)',conf.scr_title, 0 )
      return
    end
    local widgtype = widgtype + 1
    if tonumber(widgtype) and tonumber(widgtype) >= 1 then key = widgets.types_t[widgtype] else key = widgtype end
    local temp_but_t if widgets[key].buttons then temp_but_t = CopyTable(widgets[key].buttons) end
    
    if is_buttons then 
      if not widgets[key].buttons then return end
      for i = 1, #widgets[key].buttons do cur_str = cur_str..'#'..widgets[key].buttons[i]..' ' end 
      local key_show = key..' buttons' 
      local ret, retorder = GetUserInputs( conf.scr_title, 1, key_show..' context,extrawidth=500',cur_str ) 
      widgets[key].buttons = {}
      for val in retorder:gmatch('#(%a+)') do widgets[key].buttons [#widgets[key].buttons + 1 ] =val end
      
     else 
     
      for i = 1, #widgets[key] do cur_str = cur_str..'#'..widgets[key][i]..' ' end
      local ret, retorder = GetUserInputs( conf.scr_title, 1, key..' context,extrawidth=500',cur_str ) 
      widgets[key] = {}
      for val in retorder:gmatch('#(%a+)') do widgets[key] [#widgets[key] + 1 ] =val end   
      widgets[key].buttons = CopyTable(temp_but_t)
    end
    redraw = 2
    Config_DumpIni(widgets, data.conf_path) 
      
  end
