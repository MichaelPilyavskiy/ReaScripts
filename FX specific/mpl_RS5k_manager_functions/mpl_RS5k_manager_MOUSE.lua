-- @description RS5k_manager_MOUSE
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex

  ---------------------------------------------------
  function ShortCuts(char)
    if char == 32 then Main_OnCommandEx(40044, 0,0) end -- space: play/pause
  end
  ---------------------------------------------------
   function MOUSE_Match(mouse, b)
   if not b then return end
     if not b.mouse_offs_x then b.mouse_offs_x = 0 end 
     if not b.mouse_offs_y then b.mouse_offs_y = 0 end
     if b.x and b.y and b.w and b.h then 
       local state= mouse.x > b.x  + b.mouse_offs_x
               and mouse.x < b.x+b.w + b.mouse_offs_x
               and mouse.y > b.y - b.mouse_offs_y
               and mouse.y < b.y+b.h - b.mouse_offs_y
       if state and not b.ignore_mouse then mouse.context = b.context 
         return true,  
                 (mouse.x - b.x- b.mouse_offs_x) / b.w
       end
     end  
   end
  ---------------------------------------------------   
  function MOUSE_dragndrop(conf, obj, data, refresh, mouse)
    if not (obj[ mouse.context ] and obj[ mouse.context ].linked_note) then return end
    local note = obj[ mouse.context ].linked_note
    for i = 0, 127-note do
      local DRret, DRstr = gfx.getdropfile(i)
      if DRret == 0 then return end
      if not (IsMediaExtension( DRstr:match('.*%.(.*)'), false ) and not DRstr:lower():match('%.rpp')) then goto skip_spl end
      
      if conf.dragtonewtracks  == 0 then -- force build new track  MIDI send routing
        --if conf.copy_src_media == 1 then DRstr = MoveSourceMedia(DRstr) end
        ExportItemToRS5K(data,conf,refresh,note+i,DRstr)
       else
        --if conf.copy_src_media == 1 then DRstr = MoveSourceMedia(DRstr) end
        local last_spl = ExportItemToRS5K(data,conf,refresh,note+i,DRstr)
        Data_Update(conf, obj, data, refresh, mouse)
        local new_tr = ShowRS5kChain(data, conf, note+i, last_spl)
        if conf.draggedfile_fxchain ~= '' then AddFXChainToTrack(new_tr, conf.draggedfile_fxchain) end
      end 
                
      ::skip_spl::
    end
    refresh.GUI = true
    refresh.GUI_WF = true
    refresh.data = true  
  end   
  
  ------------------------------------------------------------------------------------------------------
  function MOUSE_droppad(conf, obj, data, refresh, mouse)   
        if data.activedroppedpad and conf.tab == 0 then
          if mouse.context_latch:match('keys_p%d+') and data.activedroppedpad:match('keys_p%d+') then
            local src_note = mouse.context_latch:match('keys_p(%d+)')
            local dest_note = data.activedroppedpad:match('keys_p(%d+)')
            if src_note and tonumber(src_note) and dest_note and tonumber(dest_note) then
              src_note = tonumber(src_note)
              dest_note = tonumber(dest_note)
              if data[src_note] then
                if not mouse.Ctrl_state then
                  for id_spl = 1, #data[src_note] do
                    data[src_note][id_spl].MIDIpitch_normal = dest_note/127
                    SetRS5kData(data, conf, data[src_note][id_spl].src_track, src_note, id_spl)
                  end
                 else
                  for id_spl = 1, #data[src_note] do
                    data[src_note][id_spl].MIDIpitch_normal = dest_note/127
                    SetRS5kData(data, conf, data[src_note][id_spl].src_track, src_note, id_spl, true)
                  end
                end 
              end 
              obj.current_WFkey = dest_note
              refresh.GUI_WF = true
            end         
          end
          refresh.data = true  
          data.activedroppedpad = nil
        end       
    end
   ------------------------------------------------------------------------------------------------------
   function MOUSE(conf, obj, data, refresh, mouse)
     local d_click = 0.4
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
      
     if mouse.last_x and mouse.last_y and (mouse.last_x ~= mouse.x or mouse.last_y ~= mouse.y) then mouse.is_moving = true else mouse.is_moving = false end
     if mouse.last_wheel then mouse.wheel_trig = (mouse.wheel - mouse.last_wheel) end 
      mouse.wheel_on_move =     mouse.wheel_trig ~= 0
     if mouse.LMB_state and not mouse.last_LMB_state then  
       mouse.last_x_onclick = mouse.x     
       mouse.last_y_onclick = mouse.y 
       mouse.LMB_state_TS = os.clock()
     end  
          
     mouse.DLMB_state = mouse.LMB_state 
                        and not mouse.last_LMB_state
                        and mouse.last_LMB_state_TS
                        and mouse.LMB_state_TS- mouse.last_LMB_state_TS > 0
                        and mouse.LMB_state_TS -mouse.last_LMB_state_TS < d_click 

  
     if mouse.last_x_onclick and mouse.last_y_onclick then mouse.dx = mouse.x - mouse.last_x_onclick  mouse.dy = mouse.y - mouse.last_y_onclick else mouse.dx, mouse.dy = 0,0 end
   
     
     -- buttons
       for key in spairs(obj,function(t,a,b) return b < a end) do
         if type(obj[key]) == 'table' and not obj[key].ignore_mouse then
           ------------------------
           local ret = MOUSE_Match(mouse, obj[key])
           if ret and mouse.LMB_state and not mouse.last_LMB_state then mouse.context_latch = key end
           if ret and (not mouse.context_latch or mouse.context_latch == '' ) and obj[key].func_mouseover then obj[key].func_mouseover() end 
                
           mouse.onclick_L = mouse.LMB_state 
                               and not mouse.last_LMB_state 
                               --and not mouse.Ctrl_state  
                               and MOUSE_Match(mouse, obj[key]) 
                 ------------------------
           mouse.onDclick_L = mouse.LMB_state 
                               and not mouse.last_LMB_state 
                               --and not mouse.Ctrl_state  
                               and mouse.DLMB_state 
                               and MOUSE_Match(mouse, obj[key]) 
           if mouse.onDclick_L and not key:match('keys_p')then
              if obj[key].func_DC  then obj[key].func_DC() elseif obj[key].func then obj[key].func()  end
              if conf.MM_reset_val&(1<<0) == (1<<0) and obj[key].func_ResetVal then obj[key].func_ResetVal() end
              goto skip_mouse_obj 
            end
           if mouse.onclick_L and not mouse.Shift_state and not mouse.Ctrl_state and not mouse.Alt_state and obj[key].func then 
            
              obj[key].func() 
              goto skip_mouse_obj 
            end
                 ------------------------
           mouse.ondrag_L = -- left drag (persistent even if not moving)
                               mouse.LMB_state 
                               and not mouse.Ctrl_state 
                               and (mouse.context == key or mouse.context_latch == key) 
           if mouse.ondrag_L and obj[key].func_LD then obj[key].func_LD() end 
                 ------------------------
           mouse.ondrag_L_onmove = -- left drag (only when moving after latch)
                               mouse.LMB_state 
                               and not mouse.Ctrl_state 
                               and mouse.is_moving
                               and mouse.context_latch == key
           if mouse.ondrag_L_onmove and obj[key].func_LD2 then obj[key].func_LD2() end 
           ---------------------------------
            mouse.ondrag_LCAS = mouse.LMB_state 
                               and mouse.last_LMB_state 
                               and mouse.Ctrl_state  
                               and mouse.Shift_state
                               and mouse.Alt_state    
                               and mouse.is_moving
                               and mouse.context_latch == key
           if mouse.ondrag_LCAS and obj[key].ondrag_LCAS then obj[key].ondrag_LCAS() end        
           ---------------------------------
            mouse.onclick_LCAS = mouse.LMB_state 
                               and not mouse.last_LMB_state 
                               and mouse.Ctrl_state  
                               and mouse.Shift_state
                               and mouse.Alt_state    
                               and MOUSE_Match(mouse, obj[key]) 
           if mouse.onclick_LCAS and obj[key].onclick_LCAS then obj[key].onclick_LCAS() end                    
                 ------------------------              
           mouse.onclick_LCtrl = mouse.LMB_state 
                               and not mouse.last_LMB_state 
                               and mouse.Ctrl_state  
                               and MOUSE_Match(mouse, obj[key]) 
           if mouse.onclick_LCtrl and obj[key].func_trigCtrl then obj[key].func_trigCtrl() end
                 ------------------------              
           mouse.onclick_LShift = mouse.LMB_state 
                               and not mouse.last_LMB_state 
                               and mouse.Shift_state  
                               and MOUSE_Match(mouse, obj[key]) 
           if mouse.onclick_LShift and obj[key].func_shiftL then obj[key].func_shiftL() end   
                 ------------------------
           mouse.context_shift = -- left drag (only when moving after latch)
                               mouse.LMB_state 
                               and mouse.Shift_state 
                               and mouse.is_moving
                               and mouse.context == key
           if mouse.context_shift and obj[key].func_context_shift then obj[key].func_context_shift() end                    
                 ------------------------              
           mouse.onclick_LAlt = mouse.LMB_state 
                               and not mouse.last_LMB_state 
                               and mouse.Alt_state  
                               and MOUSE_Match(mouse, obj[key]) 
          if mouse.onclick_LAlt  then 
              if obj[key].func_trigAlt then obj[key].func_trigAlt() end
              if conf.MM_reset_val&(1<<1) == (1<<1) and obj[key].func_ResetVal then obj[key].func_ResetVal() end
              goto skip_mouse_obj  
          end           
                 ------------------------            
           mouse.ondrag_LCtrl = -- left drag (persistent even if not moving)
                               mouse.LMB_state 
                               and mouse.last_LMB_state 
                               and mouse.Ctrl_state 
                               and mouse.context_latch == key
                               and mouse.is_moving
           if mouse.ondrag_LCtrl and obj[key].func_ctrlLD then obj[key].func_ctrlLD() end 
                 ------------------------
           mouse.onclick_R = mouse.RMB_state 
                               and not mouse.last_RMB_state 
                               and not mouse.Ctrl_state  
                               and MOUSE_Match(mouse, obj[key]) 
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
           
     -- mouse release    
      if mouse.last_LMB_state and not mouse.LMB_state   then    
        
        if conf.allow_dragpads == 1 then MOUSE_droppad(conf, obj, data, refresh, mouse)   end
        local key = mouse.context_latch
        if obj[key] and   obj[key].func_onrelease then obj[key].func_onrelease() end
        -- clear context
        mouse.context_latch = ''
        mouse.context_latch_val = -1
        mouse.context_latch_t = nil
        -- clear note
        --for i = 1, 127 do StuffMIDIMessage( 0, '0x8'..string.format("%x", 0), i, 100) end
        if conf.sendnoteoffonrelease == 1 then
          StuffMIDIMessage( 0, '0xB0', 123, 0)
        end
        refresh.GUI = true
      end

       -- drop pads
        if conf.allow_dragpads == 1 and mouse.context_latch and mouse.context_latch:match('keys_p%d+') and mouse.is_moving then
          local C = mouse.Ctrl_state 
          local A = mouse.Alt_state
          local S = mouse.Shift_state
          data.activedroppedpad = mouse.context
          if not C and not A and not S then data.activedroppedpad_action = 'Move/Add to layer' end
          if     C and not A and not S then data.activedroppedpad_action = 'Copy/Add to layer' end
          refresh.GUI = true
        end
        
        
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
       
      -- DragnDrop from MediaExplorer 5.91pre1+
      if obj.reapervrs >= 5.91 then MOUSE_dragndrop(conf, obj, data, refresh, mouse) end     
        
   end
