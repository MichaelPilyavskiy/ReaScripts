-- @description PitchEditor_MOUSE
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex

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
   mouse.context = ''
        
        -- loop with break
        for key in spairs(obj,function(t,a,b) return b < a end) do
         if type(obj[key]) == 'table' and not obj[key].ignore_mouse then
           ------------------------
           --[[if ((is_mouse_over == true and not mouse.last_LMB_state and not mouse.LMB_state )
                or (mouse.context_latch and mouse.context_latch == key))
            and obj[key].func_mouseover and mouse.is_moving then 
              obj[key].func_mouseover() 
              
          end]]
            ------------------------
          local is_mouse_over = MOUSE_Match(mouse, obj[key])
          if mouse.context == key and 
            (
              (mouse.LMB_state and not mouse.last_LMB_state) or
              (mouse.MMB_state and not mouse.last_MMB_state)
            )
            then mouse.context_latch = key end
          ------------------------

          if mouse.DLMB_state == true and is_mouse_over and obj[key].funcDC then obj[key].funcDC() goto skip_mouse_obj end
          mouse.onclick_L = not mouse.last_LMB_state 
                               and mouse.LMB_state 
                               and not (mouse.Ctrl_state or mouse.Alt_state or mouse.Shift_state)
                               and is_mouse_over
          if mouse.onclick_L and obj[key].func then obj[key].func() goto skip_mouse_obj end
          mouse.onclick_L2 = not mouse.last_LMB_state  -- support for ctrl alt shift
                               and mouse.LMB_state 
                               and is_mouse_over
          if mouse.onclick_L2 and obj[key].func2 then obj[key].func2() goto skip_mouse_obj end          
          ------------------------
          mouse.onclick_M = not mouse.last_MMB_state 
                               and mouse.cap == 64
                               and is_mouse_over
          if mouse.onclick_M and obj[key].funcM then obj[key].funcM() goto skip_mouse_obj end          
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
           mouse.ondrag_L_onmove2 = -- left drag support ctrl alt shift (only when moving after latch)
                               mouse.LMB_state 
                               and mouse.is_moving
                               and mouse.context_latch == key
           if mouse.ondrag_L_onmove2 and obj[key].func_LD3 then obj[key].func_LD3() end            
                 ------------------------
           mouse.ondrag_M_onmove = -- middle drag (only when moving after latch)
                               mouse.cap == 64
                               and mouse.is_moving
                               and mouse.context_latch == key
           if mouse.ondrag_M_onmove and obj[key].func_MD2 then obj[key].func_MD2() end            
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
                               and mouse.LMB_state 
                               and mouse.Alt_state
                               and is_mouse_over
          if mouse.onclick_LAlt  and obj[key].func_L_Alt then obj[key].func_L_Alt() goto skip_mouse_obj end           
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
                           --and not mouse.Ctrl_state 
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
      
      if mouse.MMB_state and mouse.last_MMB_state and  mouse.is_moving then 

        refresh.GUI = true
        refresh.conf = true
      end

      if not mouse.MMB_state and mouse.last_MMB_state then

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

