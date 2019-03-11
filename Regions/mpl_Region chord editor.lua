-- @description Region chord editor
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=165672
-- @changelog
--    # any region with @ character is ignored
--    # change layout to 4 measures per line
--    + added various improvements for adding regions logic
--    + feedback region color to GUI

  local vrs = 'v1.01'
  --NOT gfx NOT reaper
  

  
  --  INIT -------------------------------------------------
  local conf = {}  
  local refresh = { GUI_onStart = true, 
                    GUI = false, 
                    GUI_minor = false,
                    data = false,
                    data_proj = false, 
                    conf = false}
  local mouse = {}
  local data = {}
  local obj = {}
  
  local info = debug.getinfo(1,'S');  
  local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]]) 
  obj.script_path = script_path 
  ---------------------------------------------------
  function ExtState_Def()  
    local t= {
            -- globals
            mb_title = 'Region chord editor',
            ES_key = 'MPL_Region chord editor',
            wind_x =  50,
            wind_y =  50,
            wind_w =  450,
            wind_h =  450,
            dock =    0,
            
            -- mouse
            mouse_wheel_res = 960,
            activetab = 1, 
            
            -- data
            app_on_strategy_change = 0,
            app_on_slider_click = 1,
            app_on_slider_release = 1, 
            app_on_groove_change = 0,
            iterationlim = 30000, -- deductive brutforce
            
            }
    return t
  end  
  ---------------------------------------------------    
  function run()
    obj.clock = os.clock()
    
    MOUSE(conf, obj, data, refresh, mouse)
    CheckUpdates(obj, conf, refresh)
    Data_Update2 (conf, obj, data, refresh, mouse) 
    if refresh.data == true then 
      Data_Update (conf, obj, data, refresh, mouse) 
      refresh.data = nil 
    end    
  
    if refresh.conf == true then 
      ExtState_Save(conf)
      refresh.conf = nil 
    end
    
    if refresh.GUI == true or refresh.GUI_onStart == true then
      OBJ_Update              (conf, obj, data, refresh, mouse,strategy) end  
    if refresh.GUI_minor == true then refresh.GUI = true end
    GUI_draw               (conf, obj, data, refresh, mouse, strategy)    
                                               
 
    ShortCuts(conf, obj, data, refresh, mouse)
    if mouse.char >= 0 and mouse.char ~= 27 
      then defer(run) else atexit(gfx.quit) end
  end
    
  
  
---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end

---------------------------------------------------------------------
  function Data_Update (conf, obj, data, refresh, mouse) 
    data.pr_len = GetProjectLength( 0 )
    local retval, measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats( 0, data.pr_len )
    data.pr_len_measures = measures
    data.measures = {}
    for i = 0, data.pr_len_measures do
      local meas_time = TimeMap2_beatsToTime( 0, 0, i )
      local retval, measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats( 0, meas_time )
      local chord_t = {}
      for b = 0, cml do
        local meas_time0 = TimeMap2_beatsToTime( 0, b, i )
        local markeridx, regionidx = GetLastMarkerAndCurRegion( 0, meas_time0-0.001 )
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color
        if regionidx >= 0 then
          retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = EnumProjectMarkers3( 0, regionidx )
         else 
          name = ''
        end
        chord_t[b] = {name=name,color=color}
      end
      
      data.measures[i] = {cml = cml,
                          cdenom =cdenom,
                          chord_t = chord_t}
    end
    
  end
  ---------------------------------------------------
  function Data_Update2 (conf, obj, data, refresh, mouse) 
    if not data.pr_len_measures then return end
    if  GetPlayStateEx( 0 ) &1~=1 then data.curpos = GetCursorPositionEx( 0 ) else data.curpos = GetPlayPosition2Ex( 0 ) end
    local retval, measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats( 0, data.curpos )
    data.cur_measure = measures
    data.cur_measure_progress = retval / cml
    data.proj_progress = data.cur_measure / data.pr_len_measures
    if not data.last_cur_measure or data.cur_measure ~= data.last_cur_measure then 
      obj.scroll_val = data.proj_progress
      refresh.GUI = true 
    end
    data.last_cur_measure = data.cur_measure
        
    for i = 0, data.pr_len_measures do
      if obj['meas'..i] then 
        if i  < data.cur_measure then
          obj['meas'..i].val = 1
         elseif i  == data.cur_measure then
          obj['meas'..i].val = data.cur_measure_progress 
         elseif i  > data.cur_measure then
          obj['meas'..i].val = 0     
        end
      end
    end
    
    --
    
    refresh.GUI_minor = true
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
      if o.col_int2 then
        local r, g, b = ColorFromNative( o.col_int2 )
        gfx.set(r/255,g/255,b/255, o.alpha_back)
        gfx.rect(x,y, w,h,1)
      end
  
    if o.val then 
      gfx.set(1,1,1,0.4)
      gfx.rect(x,y, w * o.val,h,1)
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
             
    ------------------ check
    local check_ex = ((type(o.check)=='boolean' and o.check==true) or (o.check and o.check&1==1))
                        or ((type(o.check)=='boolean' and o.check==false) or (o.check and o.check&1==0))
    --if o.check then
      gfx.a = 0.8
      if (type(o.check)=='boolean' and o.check==true) or (o.check and o.check&1==1) then
        local xr = x+2
        local yr = y+2
        local wr = h-6
        local hr = h-5
        gfx.rect(xr,yr,wr,hr,1)
        rect(x,y,h-3,h-2,0)
       elseif (type(o.check)=='boolean' and o.check==false) or (o.check and o.check&1==0) then
        rect(x,y,h-3,h-2,0)
      end
    --end
      
    


  
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
                if o.aligh_txt&1==1 then 
                  gfx.x = x + shift 
                  if check_ex then gfx.x = gfx.x + o.h end
                end -- align left
                if o.aligh_txt&2==2 then gfx.y = y + i*gfx.texth end -- align top
                if o.aligh_txt&4==4 then gfx.y = y + h - com_texth+ gfx.texth*i end -- align bot
                if o.aligh_txt&8==8 then gfx.x = x + w - gfx.measurestr(line) - shift end -- align right
                if o.aligh_txt&16==16 then gfx.y = y + (h - com_texth)/2+ i*gfx.texth - 2 end -- align center

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
  function GUI_draw(conf, obj, data, refresh, mouse, strategy)
    gfx.mode = 0
    
    -- 1 main
    -- 2 gradient back
    --  3 grad selection
    -- 5 gradient Draw Obj\
    
    --  init
      if refresh.GUI_onStart then
        GUI_gradBack(conf, obj, data, refresh, mouse)
        GUI_gradDrawObj(conf, obj, data, refresh, mouse)
        GUI_gradSelection(conf, obj, data, refresh, mouse)
        refresh.GUI_onStart = nil             
        refresh.GUI = true       
      end
      
    -- refresh
      if refresh.GUI then 
          gfx.dest = 1
          gfx.setimgdim(1, -1, -1)  
          gfx.setimgdim(1, gfx.w, gfx.h) 
          gfx.blit( 2, 1, 0, -- grad back
                    0,0,  obj.grad_sz,obj.grad_sz/2,
                    0,0,  gfx.w,gfx.h, 0,0)                
        -- refresh all buttons
          for key in spairs(obj) do 
            if type(obj[key]) == 'table' and obj[key].show and not obj[key].blit and not obj[key].strategy_reserved then 
              GUI_DrawObj(obj, obj[key], mouse, conf) 
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
      gfx.blit(4, 1, 0, -- backgr
          0,0,gfx.w, gfx.h,
          0,0,gfx.w, gfx.h, 0,0)      
      gfx.blit(1, 1, 0, -- backgr
          0,0,gfx.w, gfx.h,
          0,0,gfx.w, gfx.h, 0,0)  
    

    refresh.GUI = nil
    refresh.GUI_minor = nil
    gfx.update()
  end

  ---------------------------------------------------
  function ShortCuts(conf, obj, data, refresh, mouse)
      if mouse.char == 32 then Main_OnCommandEx(40044, 0,0) end -- space: play/pause
  end
  ---------------------------------------------------
  function MOUSE_Match(mouse, b)
    if not b then return end
    if b.x and b.y and b.w and b.h then 
      local state= mouse.x > b.x
               and mouse.x < b.x+b.w
               and mouse.y > b.y
               and mouse.y < b.y+b.h
      if state and not b.ignore_mouse then 
        mouse.context = b.context 
        return true, (mouse.x - b.x) / b.w
      end
    end  
  end
   ------------------------------------------------------------------------------------------------------
  function MOUSE(conf, obj, data, refresh, mouse)
    local d_click = 0.4
    mouse.char =gfx.getchar() 
    
    mouse.cap = gfx.mouse_cap
    mouse.x = gfx.mouse_x
    mouse.y = gfx.mouse_y
    mouse.LMB_state = gfx.mouse_cap&1 == 1 
    mouse.RMB_state = gfx.mouse_cap&2 == 2 
    mouse.MMB_state = gfx.mouse_cap&64 == 64
    mouse.Ctrl_LMB_state = gfx.mouse_cap&5 == 5 
    mouse.Ctrl_state = gfx.mouse_cap&4 == 4 
    mouse.Shift_state = gfx.mouse_cap&8 == 8 
    mouse.Alt_state = gfx.mouse_cap&16 == 16 -- alt
    mouse.wheel = gfx.mouse_wheel
    --mouse.context = '_window'
    mouse.is_moving = mouse.last_x and mouse.last_y and (mouse.last_x ~= mouse.x or mouse.last_y ~= mouse.y)
    mouse.wheel_trig = mouse.last_wheel and (mouse.wheel - mouse.last_wheel) 
    mouse.wheel_on_move = mouse.wheel_trig and mouse.wheel_trig ~= 0
    if (mouse.LMB_state and not mouse.last_LMB_state) or (mouse.MMB_state and not mouse.last_MMB_state) then  
       mouse.last_x_onclick = mouse.x     
       mouse.last_y_onclick = mouse.y 
       mouse.LMB_state_TS = os.clock()
    end  
    
    
     mouse.DLMB_state = mouse.LMB_state 
                        and not mouse.last_LMB_state
                        and mouse.last_LMB_state_TS
                        and mouse.LMB_state_TS- mouse.last_LMB_state_TS > 0
                        and mouse.LMB_state_TS -mouse.last_LMB_state_TS < d_click 

  
     if mouse.last_x_onclick and mouse.last_y_onclick then 
      mouse.dx = mouse.x - mouse.last_x_onclick  mouse.dy = mouse.y - mouse.last_y_onclick 
     else 
      mouse.dx, mouse.dy = 0,0 
    end
   
   
        -- loop with break
        for key in spairs(obj,function(t,a,b) return b < a end) do
         if type(obj[key]) == 'table' and not obj[key].ignore_mouse then
           ------------------------
           local is_mouse_over = MOUSE_Match(mouse, obj[key])
           if ((is_mouse_over and not mouse.last_LMB_state and not mouse.LMB_state )
                or (mouse.context_latch and mouse.context_latch == key))
            and obj[key].func_mouseover then obj[key].func_mouseover() end
            ------------------------
           if is_mouse_over and mouse.LMB_state and not mouse.last_LMB_state then mouse.context_latch = key end
           ------------------------
           mouse.onclick_L = not mouse.last_LMB_state 
                               and mouse.cap == 1
                               and is_mouse_over
          if mouse.onclick_L and obj[key].func then obj[key].func() goto skip_mouse_obj end
           ------------------------
           mouse.onrelease_L = not mouse.LMB_state  -- release under object
                               and mouse.last_LMB_state 
                               and is_mouse_over 
          if mouse.onrelease_L and obj[key].onrelease_L then obj[key].onrelease_L() goto skip_mouse_obj end   
           mouse.onrelease_L2 = not mouse.LMB_state -- release of previous latch object
                               and mouse.last_LMB_state 
                               and mouse.context_latch == key 
          if mouse.onrelease_L2 and obj[key].onrelease_L2 then obj[key].onrelease_L2() goto skip_mouse_obj end                  
           ------------------------
           mouse.ondrag_L = -- left drag (persistent even if not moving)
                               mouse.cap == 1
                               and not mouse.Ctrl_state 
                               and (mouse.context == key or mouse.context_latch == key) 
                               
           if mouse.ondrag_L and obj[key].func_LD then obj[key].func_LD() end 
                 ------------------------
           mouse.ondrag_L_onmove = -- left drag (only when moving after latch)
                               mouse.cap == 1
                               and mouse.is_moving
                               and mouse.context_latch == key
           if mouse.ondrag_L_onmove and obj[key].func_LD2 then obj[key].func_LD2() end 
                 ------------------------              
           mouse.onclick_LCtrl = mouse.LMB_state 
                               and not mouse.last_LMB_state 
                               and mouse.cap == 5
                               and is_mouse_over
           if mouse.onclick_LCtrl and obj[key].func_trigCtrl then obj[key].func_trigCtrl() end
           mouse.onclick_LShift = mouse.LMB_state 
                               and not mouse.last_LMB_state 
                               and mouse.cap == 9
                               and is_mouse_over
           if mouse.onclick_LShift and obj[key].func_trigShift then obj[key].func_trigShift() end           
                 ------------------------              
           mouse.onclick_LAlt = not mouse.last_LMB_state 
                               and mouse.cap == 17   -- alt + lclick
                               and is_mouse_over
          if mouse.onclick_LAlt  then 
              if obj[key].func_L_Alt then obj[key].func_L_Alt() end
              goto skip_mouse_obj  
          end           
                 ------------------------            
           mouse.ondrag_LCtrl = -- left drag (persistent even if not moving)
                               mouse.LMB_state 
                               and mouse.Ctrl_state 
                               and mouse.context_latch == key
                               
           if mouse.ondrag_LCtrl and obj[key].func_ctrlLD then obj[key].func_ctrlLD() end 
                 ------------------------
           mouse.onclick_R = mouse.cap == 2
                               and not mouse.last_RMB_state 
                               and is_mouse_over 
           if mouse.onclick_R and obj[key].func_R then obj[key].func_R() end
                 ------------------------                
           mouse.ondrag_R = --
                               mouse.RMB_state 
                               and not mouse.Ctrl_state 
                               and (mouse.context == key or mouse.context_latch == key) 
                               and mouse.is_moving
           if mouse.ondrag_R and obj[key].func_RD then obj[key].func_RD() end 
                 ------------------------  
           mouse.onwheel = mouse.wheel_trig 
                           and mouse.wheel_trig ~= 0 
                           and not mouse.Ctrl_state 
                           and mouse.context == key
           if mouse.onwheel and obj[key].func_wheel then obj[key].func_wheel(mouse.wheel_trig) end
         end
       end
       
       ::skip_mouse_obj::
    
    
    
    if not MOUSE_Match(mouse, {x=0,y=0,w=gfx.w, h=gfx.h}) then obj.tooltip = '' end
    
     -- mouse release    
      if mouse.last_LMB_state and not mouse.LMB_state   then  
        -- clear context
        mouse.context_latch = ''
        mouse.context_latch_val = -1
        mouse.context_latch_t = nil
        --Main_OnCommand(NamedCommandLookup('_BR_FOCUS_ARRANGE_WND'),0)
        refresh.GUI_minor = true
      end
    
    
    
    -- Middle drag
      if mouse.MMB_state and not mouse.last_MMB_state then       
        mouse.context_latch_t = {x= conf.struct_xshift,
                                y= conf.struct_yshift}
      end
      
      if mouse.MMB_state and mouse.last_MMB_state and  mouse.is_moving then 
        conf.struct_xshift = mouse.context_latch_t.x  + mouse.dx
        conf.struct_yshift = mouse.context_latch_t.y + mouse.dy
        refresh.GUI = true
        refresh.conf = true
      end

      if not mouse.MMB_state and mouse.last_MMB_state then
        mouse.context_latch_t = nil
        refresh.GUI = true
        refresh.conf = true
      end
      
    -- any key to refresh
      if not mouse.last_char or mouse.last_char ~= mouse.char then 
          refresh.GUI_minor = true 
      end
      
      mouse.last_char =mouse.char
      mouse.last_context = mouse.context
       mouse.last_x = mouse.x
       mouse.last_y = mouse.y
       mouse.last_LMB_state = mouse.LMB_state  
       mouse.last_RMB_state = mouse.RMB_state
       mouse.last_MMB_state = mouse.MMB_state 
       mouse.last_Ctrl_LMB_state = mouse.Ctrl_LMB_state
       mouse.last_Ctrl_state = mouse.Ctrl_state
       mouse.last_Alt_state = mouse.Alt_state
       mouse.last_wheel = mouse.wheel   
       mouse.last_context_latch = mouse.context_latch
       mouse.last_LMB_state_TS = mouse.LMB_state_TS
       --mouse.DLMB_state = nil  
        
   end

  ---------------------------------------------------  
  function CheckUpdates(obj, conf, refresh)
  
    -- force by proj change state
      obj.SCC =  GetProjectStateChangeCount( 0 ) 
      if not obj.lastSCC then 
        refresh.GUI_onStart = true  
        refresh.data = true
       elseif obj.lastSCC and obj.lastSCC ~= obj.SCC then 
        refresh.data = true
        refresh.GUI = true
        refresh.GUI_WF = true
      end 
      obj.lastSCC = obj.SCC
      
    -- window size
      local ret = HasWindXYWHChanged(obj)
      if ret == 1 then 
        refresh.conf = true 
        refresh.data = true
        refresh.GUI_onStart = true 
        refresh.GUI_WF = true       
       elseif ret == 2 then 
        refresh.conf = true
        refresh.data = true
      end
  end
  
  ---------------------------------------------------
  function OBJ_init(obj)  
    -- globals
    obj.reapervrs = tonumber(GetAppVersion():match('[%d%.]+')) 
    obj.offs = 5 
    obj.grad_sz = 200 
    
    obj.chord_h = 38
    obj.edit_h_area = 0
    obj.scroll_w = 20
    obj.scroll_val = 0
    
    -- font
    obj.GUI_font = 'Calibri'
    obj.GUI_fontsz = VF_CalibrateFont(21)
    obj.GUI_fontsz2 = VF_CalibrateFont( 19)
    obj.GUI_fontsz3 = VF_CalibrateFont( 15)
    obj.GUI_fontsz4 = VF_CalibrateFont( 13)
    obj.GUI_fontsz_tooltip = VF_CalibrateFont( 13)
    
    -- colors    
    obj.GUIcol = { grey =    {0.5, 0.5,  0.5 },
                   white =   {1,   1,    1   },
                   red =     {0.85,   0.35,    0.37   },
                   green =   {0.35,   0.75,    0.45   },
                   green_marker =   {0.2,   0.6,    0.2   },
                   blue =   {0.35,   0.55,    0.85   },
                   blue_marker =   {0.2,   0.5,    0.8   },
                   black =   {0,0,0 }
                   }    
    
  end
  --------------------------------------------------- 
  function OBJ_Scroll(conf, obj, data, refresh, mouse)
    local scroll_h = gfx.h - obj.edit_h_area
        obj.scroll = 
                      { clear = true,
                        x = gfx.w -obj.scroll_w -1,
                        y = 0,
                        w = obj.scroll_w,
                        h = scroll_h,
                        txt = '',
                        state = 1,
                        show = true,
                        is_but = true,
                        ignore_mouse = true,
                        alpha_back = 0.05,
                        fontsz = conf.GUI_padfontsz,--obj.GUI_fontsz2,  
                      }
        obj.scroll_handle = 
                      { clear = true,
                        x = gfx.w -obj.scroll_w -1,
                        y = obj.scroll_val * (scroll_h -obj.scroll_w)*0.5 ,
                        w = obj.scroll_w,
                        h = obj.scroll_w,
                        txt = '',
                        col = 'green',
                        show = true,
                        is_but = true,
                        alpha_back = 0.4,
                        fontsz = conf.GUI_padfontsz,--obj.GUI_fontsz2, 
                      func =  function() 
                        mouse.context_latch_val = obj.scroll_val
                      end,
              func_LD2 = function ()
                
                          if not mouse.context_latch_val then return end
                          local dragratio = 1
                          local out_val = lim(mouse.context_latch_val + (mouse.dy/(scroll_h -obj.scroll_w))*dragratio, 0, 1)
                          if not out_val then return end
                          obj.scroll_val = out_val
                          refresh.GUI = true 
                        end,             
                         
                      }                      
  end
  ---------------------------------------------------
  function OBJ_BuildChords(conf, obj, data, refresh, mouse) 
    if not data.pr_len_measures then return end
    --local shift_x = 10
    obj.chord_area_h = gfx.h - obj.edit_h_area
    obj.chord_area_x = obj.offs
    obj.chord_area_y = obj.offs
    obj.chord_area_w = gfx.w - obj.scroll_w - obj.offs*2 
    
    obj.chord_true_h_area = obj.chord_h * ( data.pr_len_measures-1)/4
    local scroll_y_offs =  obj.scroll_val * obj.chord_true_h_area
    local last_reg_name, txt
    if data.pr_len_measures > 0 then 
      local y = obj.chord_area_y+10
      for i = 0, data.pr_len_measures do
        if y+obj.chord_h-scroll_y_offs >obj.chord_area_h then return end
        local segm = data.measures[i].cml
        local x = obj.chord_area_x + (i%4)*obj.chord_area_w/4
        obj['meas'..i..'num'] = { clear = true,
              x = x,
              y = y-scroll_y_offs+obj.chord_h,
              w = obj.chord_area_w/4,
              h = obj.chord_h,
              col = 'white',
              state = 0,
              aligh_txt = 3,
              txt= i+1,
              show = true,
              is_but = true,
              val = 0,
              fontsz = obj.GUI_fontsz4,
              ignore_mouse = true,
              alpha_back = 0,
              func =  function()   end}        
            
          local wsegm = math.floor(0.25*obj.chord_area_w/segm)
          for b = 0, segm-1 do
          
          obj['meas'..i..'beat'..b..'point'] = { clear = true,
                              x = x + b*wsegm,
                              y = y-scroll_y_offs + obj.chord_h*2-2,
                              w = 2,
                              h = 2,
                              --col = 'white',
                              col_int2 = data.measures[i].chord_t[b].color,
                              state = 0,
                              aligh_txt = 1,
                              txt= '',
                              show = true,
                              is_but = true,
                              val = 0,
                              fontsz = obj.GUI_fontsz,
                              alpha_back = 0.5,
                              ignore_mouse = true,
                              func =  function() end}  
                              
            if not data.measures[i].chord_t[b].name:find('@') then 
              local alpha_back = 0
              if data.measures[i].chord_t[b].name ~= '' then alpha_back = .3 end
              local txt0 = data.measures[i].chord_t[b].name
              
              if last_reg_name and last_reg_name:lower() == txt0:lower() then txt = '' else txt = txt0 end
              last_reg_name = txt0
              obj['meas'..i..'beat'..b] = { clear = true,
                    x = x + b*wsegm,
                    y = y-scroll_y_offs+obj.chord_h,
                    w = wsegm,
                    h = obj.chord_h,
                    --col = 'white',
                    col_int2 = data.measures[i].chord_t[b].color,
                    state = 0,
                    aligh_txt = 5,
                    txt= txt,
                    show = true,
                    is_but = true,
                    val = 0,
                    fontsz = obj.GUI_fontsz,
                    alpha_back =alpha_back,
                    --a_frame = 0.05,
                    func =  function() 
                              Data_AddChord(conf, data, b, i)
                              refresh.data=true
                              refresh.GUI = true
                            end}           
            end
          end
          obj['meas'..i] = { clear = true,
                x = x,
                y = y-scroll_y_offs+obj.chord_h,
                w = obj.chord_area_w/4,
                h = obj.chord_h,
                col = 'white',
                state = 0,
                aligh_txt = 1,
                txt= '',
                show = true,
                is_but = true,
                val = 0,
                fontsz = obj.GUI_fontsz2,
                ignore_mouse = true,
                alpha_back = 0.1,
                func =  function()   end} 
          if (i%4)==3 then y = y + obj.chord_h end   
      end
    end 
  end
  ---------------------------------------------------
  function Data_AddChord(conf, data, beat, measure)
    cur_region, next_region = {}, {}
    local pos_start = TimeMap2_beatsToTime( 0,beat-1, measure )
    
    -- get current region data
      local markeridx, regionidx = GetLastMarkerAndCurRegion( 0, pos_start+0.001 )
      if regionidx >= 0 then
        cur_region  = ({EnumProjectMarkers( regionidx )})         --retval, isrgn, pos, rgnend, name, markrgnindexnumber
        --if pos_start == cur_region[3] then goto skip_cur_region end
      end  
      if not cur_region or not cur_region[1] then
        for searchmeas = measure, 0, -1 do
          for searchbeat = data.measures[measure].cml, 1, -1 do
            if searchmeas < measure or (searchmeas == measure and searchbeat < beat) then
              local searchpos = TimeMap2_beatsToTime( 0, searchbeat-1, searchmeas )
              local markeridx, regionidx = GetLastMarkerAndCurRegion( 0, searchpos+0.001 ) 
              if regionidx >=0  then
                cur_region  = ({EnumProjectMarkers( regionidx )})
                goto skip_cur_region
              end
            end
          end
        end
      end
      ::skip_cur_region::
      
      
    -- get next region data
      for searchmeas = measure, data.pr_len_measures do
        for searchbeat = 1, data.measures[measure].cml do
          if searchmeas > measure or (searchmeas == measure and searchbeat > beat) then
            local searchpos = TimeMap2_beatsToTime( 0, searchbeat-1, searchmeas )
            local markeridx, regionidx = GetLastMarkerAndCurRegion( 0, searchpos+0.001 )
            local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers( regionidx )
            if regionidx >=0 and ((cur_region and cur_region[5] and cur_region[5]:lower()~= name:lower()) or not (cur_region and cur_region[5])) then
              next_region  = ({EnumProjectMarkers( regionidx )})
              goto skip_next_region
            end
          end
        end
      end 
      ::skip_next_region::
      
      new_color = ColorToNative(math.random(0,255),math.random(0,255),math.random(0,255))|0x1000000
      
    -- add reg
      local cur_name if cur_region and cur_region[5] then cur_name = cur_region[5] else cur_name = 'C' end
      local retval, retvals_csv = GetUserInputs( conf.mb_title, 1, 'region name', cur_name)
      if retval then 
        if (cur_region and cur_region[5] and cur_region[5] ~= retvals_csv:lower()) then
          SetProjectMarker( cur_region[6], true, cur_region[3], pos_start, cur_region[5] ) -- crop previous region
          local pos_end 
          
          if next_region and next_region[5] then 
            if next_region[5]:lower() ~= retvals_csv:lower() then 
              pos_end = next_region[3]
              AddProjectMarker2( 0, true, pos_start, pos_end, retvals_csv, -1, new_color )
             else
              SetProjectMarker( next_region[6], true, pos_start, next_region[4], next_region[5] )
            end
           else
            AddProjectMarker2( 0, true, pos_start, data.pr_len, retvals_csv, -1, new_color )
          end
          
         elseif not (cur_region and cur_region[5]) then 
          if next_region and next_region[5] then 
            if next_region[5]:lower() ~= retvals_csv:lower() then 
              AddProjectMarker2( 0, true, pos_start, next_region[3], retvals_csv, -1, new_color )
             else
              SetProjectMarker( next_region[6], true, pos_start, next_region[4], next_region[5] )
            end
           else
            AddProjectMarker2( 0, true, pos_start, data.pr_len, retvals_csv, -1, new_color )
          end
          
        end
      end
      
      
  end
    
    
    --[[ 
    
    local retval, retvals_csv = GetUserInputs( conf.mb_title, 1, 'region name', 'C' )
    if not retval then return end
    local pos_end = data.pr_len
    
    
    add region if previous with other name
      local markeridx, regionidx = GetLastMarkerAndCurRegion( 0, pos_start-0.001 )
      if regionidx >= 0 then
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers( regionidx )
        if name:lower()~=retvals_csv:lower() then AddProjectMarker( 0, true, pos_start, pos_end, retvals_csv, -1 )  end
       else
        AddProjectMarker( 0, true, pos_start, pos_end, retvals_csv, -1 )
      end
    
    -- crop previous region
    local markeridx, regionidx = GetLastMarkerAndCurRegion( 0, pos_start-0.001 )
    if regionidx >= 0 then
      local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers( regionidx )
      if name:lower()~=retvals_csv:lower() then
        SetProjectMarker( markrgnindexnumber, true, pos, pos_start, name ) 
      end
    end
    
    
    do return end
    for searchmeas = measure, data.pr_len_measures do
      for searchbeat = 1, data.measures[measure].cml do
        if searchmeas > measure or (searchmeas == measure and searchbeat > beat) then
          local searchpos = TimeMap2_beatsToTime( 0, searchbeat, searchmeas )
          local markeridx, regionidx = GetLastMarkerAndCurRegion( 0, searchpos )
          local retval, isrgn, pos_end, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers( regionidx )
          if not name:match('@') and name~= '' then
            --msg(name)
            if name:lower() == retvals_csv:lower() then 
              DeleteProjectMarker( 0, markrgnindexnumber, true )
             else
              SetProjectMarker( markrgnindexnumber, true, pos_start, pos_end, retvals_csv ) 
              break
            end
          end
        end
      end
    end
    
    do return end
    
    --FindCloserregion(pos_end, data.pr_len)
    
    local pos_end = TimeMap2_beatsToTime( 0, b, i )
    
    local markeridx, regionidx = GetLastMarkerAndCurRegion( 0, pos_start )
    if regionidx >= 0 then
      retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers( regionidx )
      local retval, retvals_csv = GetUserInputs( conf.mb_title, 1, 'region name', name )
      SetProjectMarker( markrgnindexnumber, true, pos, rgnend, retvals_csv ) 
     else 
      local retval, retvals_csv = GetUserInputs( conf.mb_title, 1, 'region name', 'C' )
      if retval then 
        AddProjectMarker( 0, true, pos_start, pos_end, retvals_csv, -1 )
      end
    end]]
  ---------------------------------------------------
  function OBJ_Update(conf, obj, data, refresh, mouse) 
    for key in pairs(obj) do if type(obj[key]) == 'table' and obj[key].clear then obj[key] = {} end end  
    
    local min_w = 300
    local min_h = 200
    local reduced_view = gfx.h  <= min_h
    gfx.w  = math.max(min_w,gfx.w)
    gfx.h  = math.max(min_h,gfx.h)
    
    OBJ_Scroll(conf, obj, data, refresh, mouse)
    OBJ_BuildChords(conf, obj, data, refresh, mouse) 
    
    
    for key in pairs(obj) do if type(obj[key]) == 'table' then 
      obj[key].context = key 
    end end    
  end


--------------------------------------------------------------------
  function main()
        conf.dev_mode = 0
        conf.vrs = vrs
        ExtState_Load(conf)
          gfx.init('MPL '..conf.mb_title..' '..conf.vrs,
                    conf.wind_w, 
                    conf.wind_h, 
                    conf.dock, conf.wind_x, conf.wind_y)
          OBJ_init(obj)
          OBJ_Update(conf, obj, data, refresh, mouse,strategy) 
          run()  
  end
--------------------------------------------------------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  local ret2 = VF_CheckReaperVrs(5.95,true)    
  if ret and ret2 then main() end