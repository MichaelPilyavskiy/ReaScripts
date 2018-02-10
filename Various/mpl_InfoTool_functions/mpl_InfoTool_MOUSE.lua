-- @description InfoTool_MOUSE
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex


  -- mouse func for mpl_InfoTool
  
  ---------------------------------------------------  
  function Obj_GenerateCtrl(data, obj, mouse,
                            t,                              -- values are splitted to table
                            table_key,                     -- table key>> for ID in {obj.b}
                            x_offs, w_com,                 -- offset + common width of controls
                            src_val,                       -- init dat table
                            src_val_key,                   -- init dat table key
                            modify_func,                   -- func with arg to modify src_float
                            t_out_values,
                            app_func,                      -- func to apply what modify_func returns
                            positive_only)
    local measured_x_offs = 0
    if not t then return end
    -- generate ctrls
      gfx.setfont(1, obj.font, obj.fontsz_entry )
      for i = 1, #t do
        local w_but = gfx.measurestr(t[i]..'. ') 
        obj.b[table_key..i] = { x = x_offs + measured_x_offs,
                                y = obj.offs *2 +obj.entry_h,
                                w = w_but,
                                h = obj.entry_h,
                                frame_a = 0,
                                txt = t[i],
                                txt_a = obj.txt_a,
                                fontsz = obj.fontsz_entry,
                                func =        function()
                                                mouse.temp_val = CopyTable(src_val)
                                                mouse.temp_val2 = #t 
                                                redraw = 1                              
                                              end,
                                func_wheel =  function()
                                                local t_out_values = {}
                                                for src_valID = 1, #src_val do
                                                  t_out_values[src_valID] = modify_func(src_val[src_valID][src_val_key], i, #t, mouse.wheel_trig, data, positive_only)                                                  
                                                end 
                                                app_func(data, obj, t_out_values, table_key)
                                                redraw = 2                           
                                              end,                                              
                                func_drag =   function(is_ctrl) 
                                                if mouse.temp_val2 < #t then return end
                                                if mouse.temp_val then 
                                                  local  t_out_values = {}
                                                  for src_valID = 1, #src_val do
                                                    t_out_values[src_valID] = modify_func(src_val[src_valID][src_val_key], i, #t, math.modf(mouse.dy/15), data, positive_only) 
                                                  end
                                                  app_func(data, obj, t_out_values, table_key)
                                                  redraw = 1   
                                                end
                                              end,
                                func_DC =     function() 
                                                local out_str_toparse = table.concat(t,'')
                                                local retval0, out_str_toparse = GetUserInputs( 'Edit', 1, 'New value, extrawidth=100', out_str_toparse )
                                                if not retval0 then return end
                                                local  t_out_values = {}
                                                for src_valID = 1, #src_val do t_out_values[src_valID] = src_val[src_valID][src_val_key] end
                                                app_func(data, obj, t_out_values, table_key, out_str_toparse)                                                                   
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
    mouse.wheel = gfx.mouse_wheel
    mouse.LB_trig = not mouse.LB_gate_last and mouse.LB_gate
    mouse.LB_release = mouse.LB_gate_last and not mouse.LB_gate
    mouse.Ctrl = (gfx.mouse_cap>>2)&1==1
    -- perf doubleclick
      mouse.LDC = mouse.LB_trig and mouse.LB_trig_TS and clock - mouse.LB_trig_TS < 0.3 
      if mouse.LB_trig then mouse.LB_trig_TS = clock end
    
    -- dy drag
      if mouse.LB_trig or mouse.LB_release then 
        mouse.y_latch = mouse.y
        mouse.dy = 0
      end    
      if mouse.LB_gate then mouse.dy = mouse.y_latch - mouse.y end
    
    -- wheel
      if mouse.wheel_last then 
        if mouse.wheel_last ~= mouse.wheel then 
          if mouse.wheel_last - mouse.wheel < 0 then mouse.wheel_trig = 1 else mouse.wheel_trig = -1 end
         else
          mouse.wheel_trig = 0
        end
      end
    
    
    -- loop buttons --------------
      if obj.b then
        for key in pairs(obj.b) do
          if not obj.b[key].ignore_mouse then
            if MOUSE_Match(mouse, obj.b[key]) and obj.b[key].func_wheel and mouse.wheel_trig ~= 0 then obj.b[key].func_wheel() end
            if mouse.LB_trig and MOUSE_Match(mouse, obj.b[key]) then mouse.context_latch = key end
            if mouse.LB_trig and MOUSE_Match(mouse, obj.b[key]) and obj.b[key].func then obj.b[key].func() end
            if mouse.LB_gate and mouse.context_latch == key and obj.b[key].func_drag then obj.b[key].func_drag(mouse.Ctrl) end
            if mouse.LDC and MOUSE_Match(mouse, obj.b[key]) and obj.b[key].func_DC then obj.b[key].func_DC() end
          end   
        end     
      end
    -----------------------------
    
    -- out states
      local SCC_trig2
      mouse.wheel_last = mouse.wheel
      mouse.LB_gate_last = mouse.LB_gate
      if mouse.LB_release then 
        mouse.context_latch = nil 
        mouse.LDC = nil 
        mouse.temp_val = nil    -- latch drag
        mouse.temp_val2 = nil   -- table controls size
        mouse.temp_val3 = nil   -- last good value
        SCC_trig2 = true
       else
        SCC_trig2 = false
      end
      
      return SCC_trig2
  end  
  
  
  --[[
      mouse.RMB_state = gfx.mouse_cap&2 == 2 
      mouse.MMB_state = gfx.mouse_cap&64 == 64
      mouse.LMB_state_doubleclick = false
      mouse.Ctrl_LMB_state = gfx.mouse_cap&5 == 5 
      mouse.Ctrl_state = gfx.mouse_cap&4 == 4 
      mouse.Alt_state = gfx.mouse_cap&17 == 17 -- alt + LB
    ]]
  ----------------------------------------------------------------------- 
