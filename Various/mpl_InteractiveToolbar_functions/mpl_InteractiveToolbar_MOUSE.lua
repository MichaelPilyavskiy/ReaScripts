-- @description InteractiveToolbar_MOUSE
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex


  -- mouse func for mpl_InteractiveToolbar
  ---------------------------------------------------
  function Obj_GenerateCtrl_userinput_value(modify_wholestr, t,src_val,src_val_key,app_func,data, obj,table_key,mouse,parse_pan_tags,out_value)  
    -- if parse whole string  
      if modify_wholestr then                                                   
        local retval0,ret_str = GetUserInputs( 'Edit', 1, ',extrawidth=100', table.concat(t,'') )
        if retval0 then
          if type(src_val) == 'table'  and not src_val[src_val_key] then 
            local t_out_values = {}
            for src_valID = 1, #src_val do t_out_values[src_valID] = src_val[src_valID][src_val_key] end                                                    
            app_func(data, obj, t_out_values, table_key, ret_str, mouse)
           else 
            local out_value 
            if type(src_val) ~= 'number' and src_val[src_val_key] then out_value = src_val[src_val_key] else out_value = src_val end
            app_func(data, obj, out_value, table_key, ret_str, mouse)
          end
        end
        return
      end
    
    -- if modify partially                                          
      local comma = ','
      local name_flds = comma:rep(#t)                                                    
      local sign_t = {}   for i = 1, #t do sign_t[i] = t[i]:match('[%:%.]') end
      local  existval = {} for i = 1, #t do existval[i] =  t[i]:match('[%-%d]+') end
      local ex_val
      if parse_pan_tags then ex_val = table.concat(t,'') else ex_val = table.concat(existval,',') end                        
      local retval0,ret_str = GetUserInputs( 'Edit', #t, name_flds..'extrawidth=100', ex_val )
      if not retval0 then return end
      if parse_pan_tags then app_func(data, obj, out_value, table_key, ret_str, mouse) return end
                                                  
      if type(src_val) == 'table'  and not src_val[src_val_key] then 
        local t_out_values = {}
        for src_valID = 1, #src_val do t_out_values[src_valID] = src_val[src_valID][src_val_key] end
        local out_val_t = {}  for num in ret_str:gmatch('[%-%d]+') do out_val_t[#out_val_t+1] = num end
        local out_str_toparse_concat = ''
        for i = 1, #out_val_t do  
          local sign 
          if sign_t[i] then sign = sign_t[i] else sign = '' end
          out_str_toparse_concat = out_str_toparse_concat..out_val_t[i]..sign 
        end
        app_func(data, obj, t_out_values, table_key, out_str_toparse_concat,mouse) 
       
       else 
        local out_value
        if type(src_val) == 'table' and src_val[src_val_key] then out_value = src_val[src_val_key] else out_value = src_val end
        local out_val_t = {}
        for num in ret_str:gmatch('[%-%d]+') do out_val_t[#out_val_t+1] = num end
        local out_str_toparse_concat = ''
        for i = 1, #out_val_t do                                                    
          local sign if sign_t[i] then sign = sign_t[i] else sign = '' end
          out_str_toparse_concat = out_str_toparse_concat..out_val_t[i]..sign 
        end
        app_func(data, obj, out_value, table_key, out_str_toparse_concat, mouse)                                                   
      end  
  end      
                                                  
  ---------------------------------------------------
  function Obj_GenerateCtrl_reset_value(src_val, src_val_key, default_val, app_func, data, obj, table_key, mouse)  
    if not default_val then return end
    if type(src_val) == 'table' then
      local t_out_values
      if not src_val[src_val_key] then 
        t_out_values = {}
        for src_valID = 1, #src_val do
          t_out_values[src_valID] =default_val                    
        end 
       else 
        t_out_values = default_val
      end
      app_func(data, obj, t_out_values, table_key,nil,mouse)
      redraw = 2 
     else 
      local out_value = default_val
      app_func(data, obj, default_val, table_key, nil, mouse)
      redraw = 2
    end 
  end
  
  ---------------------------------------------------  
  function Obj_GenerateCtrl(tbl)
    local data, obj, mouse,
                            t,                              -- values are splitted to table
                            table_key,                     -- table key>> for ID in {obj.b}
                            x_offs, w_com,                 -- offset + common width of controls
                            src_val,                       -- init dat table
                            src_val_key,                   -- init dat table key
                            modify_func,                   -- func with arg to modify src_float
                            app_func,                      -- func to apply what modify_func returns
                            mouse_scale,
                            use_mouse_drag_xAxis,          -- for example for pan
                            ignore_fields,                  -- use same val/changing for both fields
                            y_offs,
                            y,
                            dont_draw_val,
                            pow_tolerance,
                            parse_pan_tags,
                            modify_wholestr,
                            trig_GUIupdWithWheel,
                            default_val,
                            onRelease_ActName ,
                            persist_buf,
                            pow_tolerance2,
                            rul_format,
                            wheel_ratio
                            
                            
                            = tbl.data, tbl.obj, tbl.mouse,
                            tbl.t,                              -- values are splitted to table
                            tbl.table_key,                     -- table key>> for ID in {obj.b}
                            tbl.x_offs, tbl.w_com,                 -- offset + common width of controls
                            tbl.src_val,                       -- init dat table
                            tbl.src_val_key,                   -- init dat table key
                            tbl.modify_func,                   -- func with arg to modify src_float
                            tbl.app_func,                      -- func to apply what modify_func returns
                            tbl.mouse_scale,
                            tbl.use_mouse_drag_xAxis,          -- for example for pan
                            tbl.ignore_fields,                  -- use same val/changing for both fields
                            tbl.y_offs,                          -- y pos
                            tbl.y,
                            tbl.dont_draw_val,
                            tbl.pow_tolerance,
                            tbl.parse_pan_tags,
                            tbl.modify_wholestr,
                            tbl.trig_GUIupdWithWheel,
                            tbl.default_val,
                            tbl.onRelease_ActName,
                            tbl.persist_buf,
                            tbl.pow_tolerance2,
                            tbl.rul_format,
                            tbl.wheel_ratio 
                            if not obj  then return end
    if not wheel_ratio then wheel_ratio = wheel_override end                       
    if y then y_offs = y end
    local measured_x_offs = 0
    if not y_offs then y_offs = obj.offs *2 +obj.entry_h end
    --if not t or not type(t)=='table' then t = {t} end
    if not t then return end
    -- generate ctrls
      gfx.setfont(1, obj.font, obj.fontsz_entry )
      for i = 1, #t do
        local txt
        if t.return_for_calc_only or dont_draw_val then txt = '' elseif t[i] then txt = t[i] end
        --msg(txt)
        
        local w_but = gfx.measurestr(t[i]..'. ') 
        obj.b[table_key..i] = { persist_buf = persist_buf,
                                x = x_offs + measured_x_offs,
                                y = y_offs,
                                w = w_but,
                                h = obj.entry_h,
                                frame_a = 0,
                                txt = txt,
                                txt_a = obj.txt_a,
                                fontsz = obj.fontsz_entry,
                                func_onRelease = function() if onRelease_ActName then Undo_OnStateChange( onRelease_ActName ) end end,
                                func =        function()
                                                if type(src_val) == 'table' then 
                                                  mouse.temp_val = CopyTable(src_val)
                                                  if src_val[src_val_key] ~= nil then mouse.temp_val = src_val[src_val_key] end
                                                 else
                                                  mouse.temp_val = src_val 
                                                end
                                                mouse.temp_val2 = #t 
                                                redraw = 1
                                              
                                                if mouse.Alt then
                                                  Obj_GenerateCtrl_reset_value(src_val, src_val_key, default_val, app_func, data, obj, table_key, mouse)  
                                                end
                                              
                                              end,
                                func_wheel =  function()
                                                if type(src_val) == 'table' then
                                                  --local t_out_values
                                                  if not src_val[src_val_key] then 
                                                    t_out_values = {}
                                                    for src_valID = 1, #src_val do
                                                      t_out_values[src_valID] = modify_func(src_val[src_valID][src_val_key], i, #t, mouse.wheel_trig/wheel_ratio, data, positive_only, nil, ignore_fields, pow_tolerance2, rul_format)
                                                    end 
                                                   else 
                                                    t_out_values = modify_func(src_val[src_val_key], i, #t, mouse.wheel_trig/wheel_ratio, data, positive_only, pow_tolerance, ignore_fields, pow_tolerance2, rul_format)
                                                  end
                                                  app_func(data, obj, t_out_values, table_key,nil,mouse)
                                                  redraw = 2 
                                                 else 
                                                  local out_value
                                                  out_value = modify_func(src_val, i, #t, mouse.wheel_trig/wheel_ratio, data, positive_only, pow_tolerance, ignore_fields, pow_tolerance2, rul_format)
                                                  app_func(data, obj, out_value, table_key, nil, mouse)
                                                  redraw = 2
                                                end                         
                                              end,                                              
                                func_drag =   function(is_ctrl) 
                                                if not mouse.temp_val2 or mouse.temp_val2 < #t then return end
                                                if mouse.temp_val then 
                                                  if type(src_val) == 'table' then
                                                    local  t_out_values = {}
                                                    for src_valID = 1, #src_val do
                                                      local mouse_shift = 0
                                                      if use_mouse_drag_xAxis then mouse_shift = -mouse.dx else mouse_shift = mouse.dy end
                                                      t_out_values[src_valID] = modify_func(src_val[src_valID][src_val_key], i, #t, math.modf(mouse_shift/mouse_scale), data, positive_only, pow_tolerance, ignore_fields,pow_tolerance2, rul_format) 
                                                    end
                                                    app_func(data, obj, t_out_values, table_key, nil, mouse)
                                                    redraw = 1   
                                                   else
                                                    local mouse_shift,out_value = 0
                                                    if use_mouse_drag_xAxis then mouse_shift = -mouse.dx else mouse_shift = mouse.dy end
                                                    out_value = modify_func(mouse.temp_val, i, #t, math.modf(mouse_shift/mouse_scale), data, positive_only, nil, ignore_fields,pow_tolerance, rul_format)
                                                    app_func(data, obj, out_value, table_key,nil,mouse)
                                                    redraw = 1                                                     
                                                  end
                                                end
                                              end,
                                func_DC =     function() 
                                                if data.MM_doubleclick == 0 then
                                                  Obj_GenerateCtrl_userinput_value(modify_wholestr, t,src_val,src_val_key,app_func,data, obj,table_key,mouse,parse_pan_tags,out_value)                                          
                                                 elseif data.MM_doubleclick == 1 then
                                                  Obj_GenerateCtrl_reset_value(src_val, src_val_key, default_val, app_func, data, obj, table_key, mouse) 
                                                end
                                              end,
                                func_R =      function()
                                                if data.MM_rightclick == 0 then 
                                                  Obj_GenerateCtrl_reset_value(src_val, src_val_key, default_val, app_func, data, obj, table_key, mouse) 
                                                 elseif data.MM_rightclick == 1 then
                                                  Obj_GenerateCtrl_userinput_value(modify_wholestr, t,src_val,src_val_key,app_func,data, obj,table_key,mouse,parse_pan_tags,out_value)
                                                end
                                              end} 
        measured_x_offs = measured_x_offs + w_but
      end
    -- align center
      for i = 1, #t do obj.b[table_key..i].x = obj.b[table_key..i].x + (w_com - measured_x_offs)/2 end    
  end
  -------------------------------------------------
  function MOUSE_Match(mouse, b) return b.x and b.y and b.w and b.h and mouse.x > b.x and mouse.x < b.x+b.w and mouse.y > b.y and mouse.y < b.y+b.h end 
  ---------------------------------------------------
  function MOUSE(obj,mouse, clock, redraw)
    mouse.x = gfx.mouse_x
    mouse.y = gfx.mouse_y
    mouse.LB_gate = gfx.mouse_cap&1 == 1
    mouse.RB_gate = gfx.mouse_cap&2 == 2
    mouse.wheel = gfx.mouse_wheel
    mouse.hwheel = gfx.mouse_hwheel 
    if mouse.hwheel ~= 0 then mouse.wheel = -mouse.hwheel end
    mouse.LB_trig = not mouse.LB_gate_last and mouse.LB_gate
    mouse.RB_trig = not mouse.RB_gate_last and mouse.RB_gate
    mouse.LB_release = mouse.LB_gate_last and not mouse.LB_gate
    mouse.RB_release = mouse.RB_gate_last and not mouse.RB_gate
    mouse.Ctrl = gfx.mouse_cap&4==4
    mouse.Shift = gfx.mouse_cap&8==8
    mouse.Alt = gfx.mouse_cap&16==16
    mouse.on_move = mouse.last_x and (mouse.last_x ~= mouse.x or mouse.last_y ~= mouse.y )
    -- perf doubleclick
      mouse.LDC = mouse.LB_trig and mouse.LB_trig_TS and clock - mouse.LB_trig_TS < 0.3 
      if mouse.LB_trig then mouse.LB_trig_TS = clock end
    
    -- dy drag
      if mouse.LB_trig or mouse.LB_release then 
        mouse.x_latch = mouse.x
        mouse.y_latch = mouse.y
        mouse.dy = 0
        mouse.dx = 0
      end    
      if mouse.LB_gate then 
        mouse.dx = mouse.x_latch - mouse.x 
        mouse.dy = mouse.y_latch - mouse.y 
      end


    -- wheel
      mouse.wheel_trig = 0
      if mouse.wheel ~=0 then  if mouse.wheel > 0 then mouse.wheel_trig = 1 else mouse.wheel_trig = -1 end end
    
    -- loop buttons --------------
      if obj.b then
        for key in pairs(obj.b) do
          if obj.b[key] and not obj.b[key].ignore_mouse then
            if MOUSE_Match(mouse, obj.b[key]) and obj.b[key].func_wheel and mouse.wheel_trig ~= 0 then obj.b[key].func_wheel() end
            if mouse.LB_trig and MOUSE_Match(mouse, obj.b[key]) then mouse.context_latch = key end
            
            if mouse.LB_trig and MOUSE_Match(mouse, obj.b[key]) and obj.b[key].func then obj.b[key].func() end
            if not mouse.LB_gate and MOUSE_Match(mouse, obj.b[key]) and mouse.on_move and obj.b[key].func_matchonly then obj.b[key].func_matchonly() end
            if mouse.RB_trig and MOUSE_Match(mouse, obj.b[key]) and obj.b[key].func_R then obj.b[key].func_R() end
            if mouse.LB_gate and not mouse.Alt and mouse.on_move and mouse.context_latch == key and obj.b[key].func_drag then obj.b[key].func_drag() end
            if mouse.LB_gate and mouse.on_move and mouse.Ctrl and mouse.context_latch == key and obj.b[key].func_drag_Ctrl then obj.b[key].func_drag_Ctrl() end
            if mouse.LDC and MOUSE_Match(mouse, obj.b[key]) and obj.b[key].func_DC then obj.b[key].func_DC() end
            if mouse.LB_trig and MOUSE_Match(mouse, obj.b[key]) and mouse.Shift  and obj.b[key].func_Lshift  then obj.b[key].func_Lshift() end
          end   
        end     
      end
    -----------------------------
    
    -- out states
      local SCC_trig2
      gfx.mouse_wheel = 0
      gfx.mouse_hwheel = 0
      mouse.LB_gate_last = mouse.LB_gate
      mouse.RB_gate_last = mouse.RB_gate
      mouse.last_x = mouse.x
      mouse.last_y = mouse.y
      
    -- act onrelease
      if mouse.LB_release or mouse.RB_release then 
        -- loop buttons --------------
          if obj.b then
            for key in pairs(obj.b) do
              if not obj.b[key].ignore_mouse then
                if mouse.context_latch == key and obj.b[key].func_onRelease then obj.b[key].func_onRelease() break end
              end
            end
          end
        mouse.context_latch = nil 
        mouse.LDC = nil 
        mouse.temp_val = nil    -- latch drag
        mouse.temp_val2 = nil   -- table controls size
        mouse.temp_val3 = nil   -- last good value
        SCC_trig2 = true
        Main_OnCommand(NamedCommandLookup('_BR_FOCUS_ARRANGE_WND'),0)
        
       else
        SCC_trig2 = false
      end
      
      return SCC_trig2
  end  
