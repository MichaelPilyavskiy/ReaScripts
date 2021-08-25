-- @description Various_functions_MOUSE
-- @author MPL
-- @noindex
  
   ---------------------------------------------------  
 function VF_MOUSE_Match(b)
   if not b then return end
   if b.x and b.y and b.w and b.h then  
     return MOUSEt.x > b.x
              and MOUSEt.x < b.x+b.w
              and MOUSEt.y > b.y
              and MOUSEt.y < b.y+b.h 
   end  
 end
 --[[-------------------------------------------------
 function MOUSE_ApproxMatch(t,x,y,w,h)
   local x0,y0,w0,h0 = t.x,t.y,t.w,t.w,t.h
   if 
     math.abs(x-x0) <= 1 
     and math.abs(y-y0) <= 1
     and math.abs(w-w0) <= 1
     and math.abs(h-h0) <= 1
     then 
     return 
   end
 end]]
--------------------------------------------------- 
 function VF_MOUSE(MOUSEt,OBJ,DATA)
   if MOUSEt.Performafterloop then MOUSEt.Performafterloop(MOUSEt,OBJ,DATA) MOUSEt.Performafterloop = nil end
   -- main
   MOUSEt.char = gfx.getchar()
   MOUSEt.cap = gfx.mouse_cap
   MOUSEt.x = gfx.mouse_x
   MOUSEt.y = gfx.mouse_y
   
   -- L/M/R button states
   MOUSEt.LMB_state = gfx.mouse_cap&1 == 1 
   MOUSEt.LMB_trig = MOUSEt.LMB_state and not MOUSEt.last_LMB_state
   MOUSEt.RMB_state = gfx.mouse_cap&2 == 2 
   MOUSEt.RMB_trig = MOUSEt.RMB_state and not MOUSEt.last_RMB_state
   MOUSEt.MMB_state = gfx.mouse_cap&64 == 64
   MOUSEt.MMB_trig = MOUSEt.MMB_state and not MOUSEt.last_MMB_state 
   MOUSEt.ANY_state = MOUSEt.LMB_state or MOUSEt.RMB_state or MOUSEt.MMB_state
   MOUSEt.ANY_trig = MOUSEt.LMB_trig or MOUSEt.RMB_trig or MOUSEt.MMB_trig
   
   -- latchx/y 
   if MOUSEt.ANY_trig then
     MOUSEt.latchx = MOUSEt.x
     MOUSEt.latchy = MOUSEt.y
   end
   if MOUSEt.ANY_state then 
     MOUSEt.dx = MOUSEt.x - MOUSEt.latchx
     MOUSEt.dy = MOUSEt.y - MOUSEt.latchy
   end
   if not MOUSEt.ANY_state and MOUSEt.last_ANY_state then
     MOUSEt.dx = 0
     MOUSEt.dy = 0
     MOUSEt.latchx = nil
     MOUSEt.latchy = nil
   end 
   MOUSEt.is_moving = MOUSEt.last_x and MOUSEt.last_y and (MOUSEt.last_x ~= MOUSEt.x or MOUSEt.last_y ~= MOUSEt.y)
   
   -- wheel
   MOUSEt.wheel = gfx.mouse_wheel
   MOUSEt.wheel_trig = MOUSEt.last_wheel and MOUSEt.last_wheel ~= MOUSEt.wheel
   MOUSEt.wheel_dir = MOUSEt.last_wheel and MOUSEt.last_wheel-MOUSEt.wheel>0
   
   -- ctrl alt shift
   MOUSEt.Ctrl = gfx.mouse_cap&4 == 4 
   MOUSEt.Shift = gfx.mouse_cap&8 == 8 
   MOUSEt.Alt = gfx.mouse_cap&16 == 16  
   MOUSEt.hasAltkeys = not (MOUSEt.Ctrl or MOUSEt.Shift or MOUSEt.Alt)
   MOUSEt.pointer = ''
   
for key in spairs(OBJ,function(t,a,b) return b > a end) do
  --if type(OBJ[key]) == 'table' then OBJ[key].selfkey = key end 
  if type(OBJ[key]) == 'table' and not OBJ[key].ignore_mouse then
    local regular_match = VF_MOUSE_Match(OBJ[key]) 
    OBJ[key].undermouse = regular_match -- frame around button 
    if regular_match  then  
      MOUSEt.pointer = key 
      if OBJ[key].func_undermouse then OBJ[key].func_undermouse() end
      --if MOUSEt.is_moving then DATA.refresh.GUI = DATA.refresh.GUI|4 end -- trig Obj buttons update 
      if MOUSEt.wheel_trig and OBJ[key].func_Wtrig then OBJ[key].func_Wtrig(MOUSEt) end 
      if MOUSEt.LMB_trig and   OBJ[key].func_Ltrig then MOUSEt.Performafterloop = OBJ[key].func_Ltrig end
      if MOUSEt.RMB_trig and   OBJ[key].func_Rtrig then OBJ[key].func_Rtrig(MOUSEt) end
      if MOUSEt.ANY_trig then 
        if not OBJ[key].preventregularselection then 
          OBJ[key].selected = true 
          DATA.refresh.GUI = DATA.refresh.GUI|4 
        end
        MOUSEt.latch_key = key 
      end  
    end 
  end 
end
   
   -- hook around change pointer
   if MOUSEt.last_pointer and MOUSEt.pointer and MOUSEt.last_pointer ~= MOUSEt.pointer then
     if OBJ[MOUSEt.last_pointer] then OBJ[MOUSEt.last_pointer].undermouse = false end
     DATA.refresh.GUI = DATA.refresh.GUI|4 -- trig Obj buttons update 
     if OBJ[MOUSEt.pointer] and OBJ[MOUSEt.pointer].func_onptrcatch then OBJ[MOUSEt.pointer].func_onptrcatch() end
     if OBJ[MOUSEt.last_pointer] and OBJ[MOUSEt.last_pointer].func_onptrfree then OBJ[MOUSEt.last_pointer].func_onptrfree() end -- release after navigate
   end 
    
    local dragcond = MOUSEt.latch_key and (MOUSEt.latch_key == MOUSEt.pointer or MOUSEt.pointer == '') and MOUSEt.is_moving 
   if dragcond and MOUSEt.LMB_state and OBJ[MOUSEt.latch_key].func_Ldrag then OBJ[MOUSEt.latch_key].func_Ldrag() end
   if dragcond and MOUSEt.RMB_state and OBJ[MOUSEt.latch_key].func_Rdrag then OBJ[MOUSEt.latch_key].func_Rdrag() end
   if dragcond and MOUSEt.MMB_state and OBJ[MOUSEt.latch_key].func_Mdrag then OBJ[MOUSEt.latch_key].func_Mdrag() end
    
   --  on any button release
     if not MOUSEt.ANY_state and MOUSEt.last_ANY_state then 
       local key
       if MOUSEt.latch_key then key = MOUSEt.latch_key end
       if key and OBJ[key] and OBJ[key].func_onptrrelease then OBJ[key].func_onptrrelease() end -- release after drag
       if key and OBJ[key] and MOUSEt.LMB_state == false and MOUSEt.last_LMB_state == true and OBJ[key].func_Lrelease then OBJ[key].func_Lrelease() end
       if key and OBJ[key] and MOUSEt.ANY_state == false and MOUSEt.last_ANY_state == true then
        if not OBJ[key].preventregularselection then 
          OBJ[key].selected = false 
          DATA.refresh.GUI = DATA.refresh.GUI|4 
        end
        if OBJ[key].func_Arelease then 
         OBJ[key].func_Arelease() 
         OBJ[key].undermouse = false 
         DATA.refresh.GUI = DATA.refresh.GUI|4 -- trig Obj buttons updat
        end
        MOUSEt[key] = nil
       end
     end
   
   MOUSEt.last_x = MOUSEt.x
   MOUSEt.last_y = MOUSEt.y
   MOUSEt.last_pointer = MOUSEt.pointer
   MOUSEt.last_LMB_state = MOUSEt.LMB_state  
   MOUSEt.last_RMB_state = MOUSEt.RMB_state  
   MOUSEt.last_MMB_state = MOUSEt.MMB_state  
   MOUSEt.last_ANY_state = MOUSEt.ANY_state 
   MOUSEt.last_wheel = MOUSEt.wheel
 end
 ---------------------------------------------------
  function VF_MOUSE_menu(MOUSEt,OBJ,DATA,t)
    local str, check ,hidden= '', '',''
    for i = 1, #t do
      if t[i].state then check = '!' else check ='' end
      if t[i].hidden then hidden = '#' else hidden ='' end
      local add_str = hidden..check..t[i].str 
      str = str..add_str
      str = str..'|'
    end
    gfx.x = MOUSEt.x
    gfx.y = MOUSEt.y
    local ret = gfx.showmenu(str)
    local incr = 0
    if ret > 0 then 
      for i = 1, ret do 
        if t[i+incr].menu_decr == true then incr = incr - 1 end
        if t[i+incr].str:match('>') then incr = incr + 1 end
        if t[i+incr].menu_inc then incr = incr + 1 end
      end
      if t[ret+incr] and t[ret+incr].func then 
        t[ret+incr].func() 
        if VF_run_UpdateAll then VF_run_UpdateAll(DATA) end 
      end 
      --- msg(t[ret+incr].str)
    end 
  end   
  ---------------------------------------------------
  --[[
    function S hortCuts(conf, obj, data, refresh, mouse)
        if mouse.char == 32 then Main_OnCommandEx(40044, 0,0) end -- space: play/pause
    end
     ------------------------------------------------------------------------------------------------------
    funct ion MOUSE(conf, obj, data, refresh, mouse)
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
            
         mouse.last_context_latch = mouse.context_latch
         mouse.last_LMB_state_TS = mouse.LMB_state_TS
         --mouse.DLMB_state = nil  
          
     end
     ]]
