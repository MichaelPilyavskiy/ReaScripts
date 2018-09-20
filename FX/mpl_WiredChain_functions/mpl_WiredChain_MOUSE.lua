-- @description WiredChain_MOUSE
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex

  ---------------------------------------------------
  function ShortCuts(conf, obj, data, refresh, mouse)
    if not obj.textbox.enable then
      if mouse.char == 6579564 then -- delete
        
        Data_DeleteSelectedFX(conf, obj, data, refresh, mouse)
      end
      
      if mouse.char == 32 then Main_OnCommandEx(40044, 0,0) end -- space: play/pause
      if mouse.char == 13 then --enter
        mouse.char = 0 
        Obj_EnumeratePlugins(conf, obj, data, refresh, mouse)
        obj.textbox.enable = true
        obj.textbox.is_replace = false
        refresh.GUI = true
      end
    end  
    
    
    -- text box
    if obj.textbox.enable then
      if mouse.char == 27 then --escape
        obj.textbox.enable = false
        mouse.char = 0 
        refresh.GUI = true
      end     
      
      if mouse.char == 13 then --enter
        mouse.char = 0
        Data_AddReplaceFX(conf, obj, data, refresh, mouse)
      end      
      
    end
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
  function MOUSE_Mod_ToolTips(conf, obj, data, refresh, mouse)
    if not mouse.context or not mouse.context:match('mod_') then  obj.tooltip = '' return end
    if not mouse.is_moving and obj.tooltip then 
      -- format tip
      local strTT = obj.tooltip
      local str = ''
      for line in strTT:gmatch('[^\r\n]+') do
          t = obj[line]
        
        if t and t.is_pin then
          local pin = t.pin_idx
          if t.pin_type == 1 then str = str..'track IO' end
          if t.pin_type == 0 and pin then str = str..t.pin_idxFX..':'..data.fx[t.pin_idxFX].reducedname..' pin'..pin end
          if t.pin_type == 1 and pin then str = str..' pin'..pin end
          str = str..'\n'       
        end
      end
      
      obj.tooltip_str = str 
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
   
    if obj.textbox.enable then goto skip_mouse_obj end
    
    
    
        -- loop with break
        for key in spairs(obj,function(t,a,b) return b < a end) do
         if type(obj[key]) == 'table' and not obj[key].ignore_mouse then
           ------------------------
           local is_mouse_over = MOUSE_Match(mouse, obj[key])
           if is_mouse_over and obj[key].func_mouseover then obj[key].func_mouseover() end
            ------------------------
           if is_mouse_over and mouse.LMB_state and not mouse.last_LMB_state then mouse.context_latch = key end
           ------------------------
           mouse.onclick_L = not mouse.last_LMB_state 
                               and mouse.cap == 1
                               and is_mouse_over
          if mouse.onclick_L and obj[key].func then obj[key].func() goto skip_mouse_obj end
           ------------------------
           mouse.onrelease_L = not mouse.LMB_state 
                               and mouse.last_LMB_state 
                               and is_mouse_over 
          if mouse.onrelease_L and obj[key].onrelease_L then obj[key].onrelease_L() goto skip_mouse_obj end          
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
           mouse.ondrag_R = -- left drag (persistent even if not moving)
                               mouse.RMB_state 
                               and not mouse.Ctrl_state 
                               and (mouse.context == key or mouse.context_latch == key) 
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
      
      
      
    if not mouse.context and mouse.cap == 2 and not mouse.last_RMB_state then 
      if obj.textbox.enable then
        obj.textbox.enable = false 
        refresh.GUI = true
       else
        Obj_Actions(conf, obj, data, refresh, mouse)  
      end
    end  
    
    -- add fx
    local addfx_context
    if obj.textbox.enable then
      addfx_context = MOUSE_Match(mouse, {x = obj.fxsearch_x ,
                                                               y = obj.fxsearch_y ,
                                                               w = obj.fxsearch_w,
                                                               h = obj.fxsearch_h })
      if addfx_context and obj.textbox.match_t then MOUSE_ContextAddFX(conf, obj, data, refresh, mouse) end
    end
    
    
    -- reset selection/textbox
      if not mouse.last_LMB_state and mouse.cap == 1  then
        if not obj.textbox.enable  and (not mouse.context or mouse.context == '' )  then 
          obj.textbox.enable = false
          refresh.GUI = true
         elseif obj.textbox.enable and not addfx_context then
          obj.textbox.enable = false
          refresh.GUI = true
        elseif obj.textbox.enable and addfx_context then
          if obj.textbox.match_t then  MOUSE_ContextAddFX(conf, obj, data, refresh, mouse, true)       end
        end
      end
      
              
     -- pins
        if mouse.context and mouse.context:match('mod_') then
          local do_upd_minor = false 
          for key in spairs(obj,function(t,a,b) return b < a end) do
            if type(obj[key]) == 'table'  and obj[key].is_pin then 
              local new_state = mouse.context == key 
              if obj[key].is_selected ~= new_state and not do_upd_minor then do_upd_minor = true end
              obj[key].is_selected = new_state
            end
          end
          if do_upd_minor == true then refresh.GUI_minor = true  end
         else
          local do_upd_minor = false 
          for key in spairs(obj,function(t,a,b) return b < a end) do
            if type(obj[key]) == 'table'  and obj[key].is_pin then 
              local new_state = false
              if obj[key].is_selected ~= new_state and not do_upd_minor then do_upd_minor = true end
              obj[key].is_selected = new_state
            end
          end
          if do_upd_minor == true then refresh.GUI_minor = true  end
        end
          
   -- selection
      if (not mouse.context_latch or mouse.context_latch == '') and  mouse.last_LMB_state and mouse.LMB_state then 
        
        local x,y,w,h
        x = mouse.x - mouse.dx
        y = mouse.y - mouse.dy
        w = mouse.dx
        h = mouse.dy
        if h < 0 then 
          y = y + h 
          h = -h
        end
        if w < 0 then 
          x = x + w
          w = -w
        end        
        obj.selection_rect = {x=x,y=y,w=w,h=h} 
      end
      if (not mouse.context_latch or mouse.context_latch == '') and  mouse.last_LMB_state and not mouse.LMB_state then 
        ObjSelectRect(conf, obj, data, refresh, mouse) 
      end
    
    MOUSE_Mod_ToolTips(conf, obj, data, refresh, mouse)
    
    if not MOUSE_Match(mouse, {x=0,y=0,w=gfx.w, h=gfx.h}) then obj.tooltip = '' end
    
     -- mouse release    
      if mouse.last_LMB_state and not mouse.LMB_state   then   
        mouse.drag_obj = nil
        obj.selection_rect = nil
        if mouse.context_latch and  mouse.context_latch:match('mod_') then refresh.GUI = true end
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
        if obj.textbox.enable then 
          refresh.GUI = true 
         else
          refresh.GUI_minor = true 
        end
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
   --------------------------------------------------
   function MOUSE_ContextAddFX(conf, obj, data, refresh, mouse, commit)
      cnt =math.modf((obj.fxsearch_h-obj.offs*2)/(obj.fxsearch_item_h +2))
      val =  (mouse.y-obj.fxsearch_y)/(obj.fxsearch_h-obj.fxsearch_y)
     val = math.ceil(val* cnt)
     if val >= 2 and val <= #obj.textbox.match_t+1 then 
       obj.textbox.matched_id = val -1
       if commit then Data_AddReplaceFX(conf, obj, data, refresh, mouse) end
       refresh.GUI_minor = true      
     end
   end
