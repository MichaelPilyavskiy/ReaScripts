-- @description Various_functions_MOUSE
-- @author MPL
-- @noindex
  
  MOUSE = {}
    ---------------------------------------------------  
  function MOUSE:Match(b)
    local edges = 0
    if not b then return end
    if b.x and b.y and b.w and b.h then 
    
      local ret= MOUSE.x > b.x
               and MOUSE.x < b.x+b.w
               and MOUSE.y > b.y
               and MOUSE.y < b.y+b.h 
      local top_edge_match =  
              MOUSE.x > b.x
               and MOUSE.x < b.x+b.w
               and MOUSE.y > b.y
               and MOUSE.y < b.y+MOUSE.edge_catch_px  
      local bot_edge_match =  
               MOUSE.x > b.x
               and MOUSE.x < b.x+b.w
               and MOUSE.y > b.y+b.h-MOUSE.edge_catch_px 
               and MOUSE.y < b.y+b.h 
      local left_edge_match =  
               MOUSE.x > b.x
               and MOUSE.x < b.x+MOUSE.edge_catch_px 
               and MOUSE.y > b.y
               and MOUSE.y < b.y+b.h          
      local right_edge_match =  
               MOUSE.x > b.x+b.w-MOUSE.edge_catch_px 
               and MOUSE.x < b.x+b.w
               and MOUSE.y > b.y
               and MOUSE.y < b.y+b.h 

      local beetween_Hedge_match =  
               MOUSE.x > b.x+MOUSE.edge_catch_px 
               and MOUSE.x < b.x+b.w-MOUSE.edge_catch_px 
               and MOUSE.y > b.y
               and MOUSE.y < b.y+b.h                
      local beetween_Vedge_match =  
               MOUSE.x > b.x
               and MOUSE.x < b.x+b.w
               and MOUSE.y > b.y+MOUSE.edge_catch_px 
               and MOUSE.y < b.y+b.h -MOUSE.edge_catch_px 
               
      if top_edge_match then edges = edges|1 end
      if bot_edge_match then edges = edges|2 end
      if left_edge_match then edges = edges|4 end
      if right_edge_match then edges = edges|8 end
      if beetween_Hedge_match then edges = edges|16 end
      if beetween_Vedge_match then edges = edges|32 end
      
      return ret, edges
    end  
  end
 --------------------------------------------------- 
  function VF_MOUSE(MOUSE, OBJ) 
    
    MOUSE.edge_catch_px = OBJ.edge_catch_px or 5
    
    -- main
    MOUSE.char = gfx.getchar()
    MOUSE.cap = gfx.mouse_cap
    MOUSE.x = gfx.mouse_x
    MOUSE.y = gfx.mouse_y
    
    -- L/M/R button states
    MOUSE.LMB_state = gfx.mouse_cap&1 == 1 
    MOUSE.LMB_trig = MOUSE.LMB_state and not MOUSE.last_LMB_state
    
    if MOUSE.LMB_trig_simulate then 
      MOUSE.LMB_trig_simulate = false
      MOUSE.LMB_trig = true
    end
    MOUSE.RMB_state = gfx.mouse_cap&2 == 2 
    MOUSE.RMB_trig = MOUSE.RMB_state and not MOUSE.last_RMB_state
    MOUSE.MMB_state = gfx.mouse_cap&64 == 64
    MOUSE.MMB_trig = MOUSE.MMB_state and not MOUSE.last_MMB_state 
    MOUSE.ANY_state = MOUSE.LMB_state or MOUSE.RMB_state or MOUSE.MMB_state
    MOUSE.ANY_trig = MOUSE.LMB_trig or MOUSE.RMB_trig or MOUSE.MMB_trig
    
    -- latchx/y 
    if MOUSE.ANY_trig then
      MOUSE.latchx = MOUSE.x
      MOUSE.latchy = MOUSE.y
    end
    if MOUSE.ANY_state then 
      MOUSE.dx = MOUSE.x - MOUSE.latchx
      MOUSE.dy = MOUSE.y - MOUSE.latchy
    end
    if not MOUSE.ANY_state and MOUSE.last_ANY_state then
      MOUSE.dx = 0
      MOUSE.dy = 0
      MOUSE.latchx = nil
      MOUSE.latchy = nil
    end 
    MOUSE.is_moving = MOUSE.last_x and MOUSE.last_y and (MOUSE.last_x ~= MOUSE.x or MOUSE.last_y ~= MOUSE.y)
    
    -- wheel
    MOUSE.wheel = gfx.mouse_wheel
    MOUSE.wheel_trig = MOUSE.last_wheel and MOUSE.last_wheel ~= MOUSE.wheel
    MOUSE.wheel_dir = MOUSE.last_wheel and MOUSE.last_wheel-MOUSE.wheel>0
    
    -- ctrl alt shift
    MOUSE.Ctrl = gfx.mouse_cap&4 == 4 
    MOUSE.Shift = gfx.mouse_cap&8 == 8 
    MOUSE.Alt = gfx.mouse_cap&16 == 16  
    MOUSE.hasAltkeys = not (MOUSE.Ctrl or MOUSE.Shift or MOUSE.Alt)
    MOUSE.pointer = ''
    
    for key in spairs(OBJ,function(t,a,b) return b > a end) do
      if type(OBJ[key]) == 'table' then OBJ[key].selfkey = key end 
      if type(OBJ[key]) == 'table' and OBJ[key].otype and not OBJ[key].ignore_mouse then
        local regular_match, edges = MOUSE:Match(OBJ[key]) 
        if regular_match or MOUSE.force_context then 
          MOUSE.pointer = key 
          if MOUSE.force_context then MOUSE.pointer = MOUSE.force_context end
          
          if MOUSE.last_pointer then
            if MOUSE.last_pointer ~= MOUSE.pointer and OBJ[key].func_onptrcatch then --and OBJ[MOUSE.last_pointer] and OBJ[MOUSE.last_pointer].func_onptrfree then OBJ[MOUSE.last_pointer].func_onptrfree() end
              OBJ[key].func_onptrcatch() 
              if MOUSE.RMB_state and OBJ[key].func_onptrcatchRdrag then OBJ[key].func_onptrcatchRdrag() end
            end
          end
          
          if MOUSE.wheel_trig and OBJ[key].func_Wtrig then OBJ[key].func_Wtrig(MOUSE.wheel_dir, MOUSE.Ctrl, MOUSE.Alt, MOUSE.Shift) end 
          if MOUSE.LMB_trig and   OBJ[key].func_Ltrig then OBJ[key].func_Ltrig() end
          if MOUSE.RMB_trig and   OBJ[key].func_Rtrig then OBJ[key].func_Rtrig() end
          if MOUSE.ANY_trig then
            MOUSE.latch_key = key  
            MOUSE.latch_key_edges = edges
            if OBJ[key].val_t then MOUSE.latch_val_t =OBJ[key].val_t end 
          end  
          MOUSE.force_context = nil
          break
        end 
      end
      
    end
    
    ::skip_obj_loop::
     
    if MOUSE.latch_key and MOUSE.hasAltkeys and MOUSE.latch_key_edges==0 and MOUSE.LMB_state and MOUSE.is_moving and OBJ[MOUSE.latch_key].func_Ldrag then OBJ[MOUSE.latch_key].func_Ldrag() end
    if MOUSE.latch_key and MOUSE.hasAltkeys and MOUSE.latch_key_edges&1==1 and MOUSE.LMB_state and MOUSE.is_moving and OBJ[MOUSE.latch_key].func_LTEdrag then OBJ[MOUSE.latch_key].func_LTEdrag() end
    if MOUSE.latch_key and MOUSE.hasAltkeys and MOUSE.latch_key_edges&2==2 and MOUSE.LMB_state and MOUSE.is_moving and OBJ[MOUSE.latch_key].func_LBEdrag then OBJ[MOUSE.latch_key].func_LBEdrag() end
    if MOUSE.latch_key and MOUSE.hasAltkeys and MOUSE.latch_key_edges&4==4 and MOUSE.LMB_state and MOUSE.is_moving and OBJ[MOUSE.latch_key].func_LLEdrag then OBJ[MOUSE.latch_key].func_LLEdrag() end
    if MOUSE.latch_key and MOUSE.hasAltkeys and MOUSE.latch_key_edges&8==8 and MOUSE.LMB_state and MOUSE.is_moving and OBJ[MOUSE.latch_key].func_LREdrag then OBJ[MOUSE.latch_key].func_LREdrag() end
    if MOUSE.latch_key and MOUSE.hasAltkeys and MOUSE.latch_key_edges&16==16 and MOUSE.LMB_state and MOUSE.is_moving and OBJ[MOUSE.latch_key].func_LHdrag then OBJ[MOUSE.latch_key].func_LHdrag() end
    if MOUSE.latch_key and MOUSE.hasAltkeys and MOUSE.latch_key_edges&32==32 and MOUSE.LMB_state and MOUSE.is_moving and OBJ[MOUSE.latch_key].func_LVdrag then OBJ[MOUSE.latch_key].func_LVdrag() end
    
    if MOUSE.latch_key and MOUSE.MMB_state and MOUSE.is_moving and OBJ[MOUSE.latch_key].func_Mdrag then OBJ[MOUSE.latch_key].func_Mdrag() end
    
    -- execute on lost focus
      if MOUSE.pointer == "" 
        and MOUSE.last_pointer 
        and MOUSE.last_pointer~="" 
        and OBJ[MOUSE.last_pointer] 
        and not OBJ[MOUSE.last_pointer].ignore_mouse 
        and OBJ[MOUSE.last_pointer].func_onptrfree then 
        OBJ[MOUSE.last_pointer].func_onptrfree()
        --if not MOUSE.ANY_state and OBJ[MOUSE.last_pointer].func_onptrfree2 then OBJ[MOUSE.last_pointer].func_onptrfree2() end -- for scroll handle, leave focus only if nothing pressed
      end
    
    --  on any buitton release
      if not MOUSE.ANY_state and MOUSE.last_ANY_state then 
        local key
        if MOUSE.latch_key then key = MOUSE.latch_key end
        if key and OBJ[key] and OBJ[key].func_onrelease then OBJ[key].func_onrelease() end
        if key and OBJ[key] and MOUSE.last_LMB_state == true and OBJ[key].func_onLrelease then OBJ[key].func_onLrelease() end
        MOUSE.latch_key = nil
        MOUSE.latch_val_t = nil
      end
    
    MOUSE.last_x = MOUSE.x
    MOUSE.last_y = MOUSE.y
    MOUSE.last_pointer = MOUSE.pointer
    MOUSE.last_LMB_state = MOUSE.LMB_state  
    MOUSE.last_RMB_state = MOUSE.RMB_state  
    MOUSE.last_MMB_state = MOUSE.MMB_state  
    MOUSE.last_ANY_state = MOUSE.ANY_state 
    MOUSE.last_wheel = MOUSE.wheel
  end
  ---------------------------------------------------
  function MOUSE_ApproxMatch(t, x,y,w,h)
    local x0,y0,w0,h0 = t.x,t.y,t.w,t.w,t.h
    if 
      math.abs(x-x0) <= 1 
      and math.abs(y-y0) <= 1
      and math.abs(w-w0) <= 1
      and math.abs(h-h0) <= 1
      then 
      return 
    end
  end
  ---------------------------------------------------
  function MOUSE:menu(t)
    local str, check ,hidden= '', '',''
    for i = 1, #t do
      if t[i].state then check = '!' else check ='' end
      if t[i].hidden then hidden = '#' else hidden ='' end
      local add_str = hidden..check..t[i].str 
      str = str..add_str
      str = str..'|'
    end
    gfx.x = MOUSE.x
    gfx.y = MOUSE.y
    local ret = gfx.showmenu(str)
    local incr = 0
    if ret > 0 then 
      for i = 1, ret do 
        if t[i+incr].menu_decr == true then incr = incr - 1 end
        if t[i+incr].str:match('>') then incr = incr + 1 end
        if t[i+incr].menu_inc then incr = incr + 1 end
      end
      if t[ret+incr] and t[ret+incr].func then t[ret+incr].func() end 
     --- msg(t[ret+incr].str)
    end
  end    
  ---------------------------------------------------
  --[[
    function ShortCuts(conf, obj, data, refresh, mouse)
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
