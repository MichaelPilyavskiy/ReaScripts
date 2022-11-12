-- @description InteractiveToolbar_Widgets_Persist
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex


  -- Persistent wigets for mpl_InteractiveToolbar
  --#swing #grid #timesellen #timeselend #timeselstart #lasttouchfx #transport #bpm #clock #tap #master 
  ---------------------------------------------------
  function Obj_UpdatePersist(data, obj, mouse, widgets, conf)
    local x_margin = gfx.w-obj.offs
    local y_margin = 0
    if conf.dock_orientation == 1 then 
      x_margin = 0 
      y_margin = gfx.h
    end
    if widgets.Persist then
      for i = 1, #widgets.Persist do
        local key = widgets.Persist[i]
        if _G['Widgets_Persist_'..key] then
          if conf.dock_orientation == 0 then 
            if x_margin-50 < obj.menu_b_rect_side then break end
            local ret = _G['Widgets_Persist_'..key](data, obj, mouse, x_margin, widgets, conf, y_margin)
            if ret then x_margin = x_margin - ret end
          end
          
          if conf.dock_orientation == 1 then 
            local retX, retY = _G['Widgets_Persist_'..key](data, obj, mouse, x_margin, widgets, conf, y_margin)
            if not retY then retY = obj.entry_h end
            y_margin = y_margin - obj.offs - retY 
          end
          
        end
      end  
    end
    return x_margin, y_margin
  end
  -------------------------------------------------------------- 






------------------------------------------------------------
  function Widgets_Persist_grid(data, obj, mouse, x_margin, widgets, conf, y_offs)    -- generate position controls 
    local grid_widg_val_w = 50*conf.scaling
    local grid_widg_w_trpl = 20*conf.scaling
    local grid_widg_w = grid_widg_val_w + grid_widg_w_trpl
    local vert_sep = math.floor(gfx.w/4)
    local frame_a = 0
    local rel_snap_w = 25*conf.scaling
    local rel_snap_h = 10*conf.scaling
    local gridwidg_xpos = gfx.w-grid_widg_w-obj.menu_b_rect_side - x_margin
    if (data.grid_isactive and data.obj_type_int ~= 8) or (data.MIDIgrid_isactive and data.obj_type_int == 8) then  
      frame_a = obj.frame_a_state 
    end
    local txt_a,txt_a_relsnap,txt_a_visgrid =obj.txt_a
    if (data.grid_rel_snap == 0 and data.obj_type_int ~= 8) or (data.MIDIgrid_rel_snap == 0 and data.obj_type_int == 8) then txt_a_relsnap = txt_a * 0.3 end
    if (data.grid_vis == 0 and data.obj_type_int ~= 8) or (data.MIDIgrid_vis == 0 and data.obj_type_int == 8) then      txt_a_visgrid = txt_a * 0.3 end
    
    
    
    obj.b.obj_pers_grid_back = { persist_buf = true,
                        x = x_margin - grid_widg_w,
                        y = obj.offs ,
                        w = grid_widg_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = '',
                        ignore_mouse = true} 
    if conf.dock_orientation == 1 then 
      obj.b.obj_pers_grid_back.persist_buf = nil   
      obj.b.obj_pers_grid_back.x = 0
      obj.b.obj_pers_grid_back.y = y_offs-obj.entry_h
      obj.b.obj_pers_grid_back.w = gfx.w
      obj.b.obj_pers_grid_back.h = obj.entry_h
    end
    obj.b.obj_pers_grid_back2 = { persist_buf = true,
                        x = x_margin - grid_widg_w,
                        y = obj.offs + obj.entry_h,
                        w = grid_widg_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = '',
                        ignore_mouse = true}  
                          
    obj.b.obj_pers_grid_relsnap = { persist_buf = true,
                        x = x_margin - grid_widg_w,
                        y = obj.offs ,
                        w = rel_snap_w,
                        h = rel_snap_h,
                        frame_a = 0,--obj.frame_a_entry,
                        frame_rect_a = 0,
                        txt_a = txt_a_relsnap,
                        --txt_col = 'white',
                        txt = 'REL',
                        --aligh_txt = 1,
                        fontsz = obj.fontsz_grid_rel,
                        func =  function ()
                                  if data.obj_type_int ~= 8 then
                                    Action(41054)
                                   else
                                    local ME = MIDIEditor_GetActive() 
                                    if ME then MIDIEditor_OnCommand(ME, 40829) end
                                  end
                                end}   
    if conf.dock_orientation == 1 then 
      obj.b.obj_pers_grid_relsnap.persist_buf = nil   
      obj.b.obj_pers_grid_relsnap.x = 0
      obj.b.obj_pers_grid_relsnap.y = y_offs-obj.entry_h
      obj.b.obj_pers_grid_relsnap.w = vert_sep
      obj.b.obj_pers_grid_relsnap.h = obj.entry_h
    end                               
    obj.b.obj_pers_grid_visible = { persist_buf = true,
                        x = x_margin - grid_widg_w + rel_snap_w,
                        y = obj.offs ,
                        w = rel_snap_w,
                        h = rel_snap_h,
                        frame_a = 0,--obj.frame_a_entry,
                        frame_rect_a = 0,
                        txt_a = txt_a_visgrid,
                        --txt_col = 'white',
                        txt = 'LINE',
                        --aligh_txt = 1,
                        fontsz = obj.fontsz_grid_rel,
                        func =  function ()
                                  if data.obj_type_int ~= 8 then
                                    Action(40145)
                                   else
                                    local ME = MIDIEditor_GetActive() 
                                    if ME then MIDIEditor_OnCommand(ME, 1017) end
                                  end                                  
                                end}            
    local grid_txt = ''
    if data.obj_type_int ~= 8 then 
      grid_txt = data.grid_val_format
     else
      grid_txt = data.MIDIgrid_val_format
    end 
    if conf.dock_orientation == 1 then 
      obj.b.obj_pers_grid_visible.persist_buf = nil   
      obj.b.obj_pers_grid_visible.x = vert_sep
      obj.b.obj_pers_grid_visible.y = y_offs-obj.entry_h
      obj.b.obj_pers_grid_visible.w = vert_sep
      obj.b.obj_pers_grid_visible.h = obj.entry_h
    end                                            
    obj.b.obj_pers_grid_B_val = { persist_buf = true,
                        x = x_margin - grid_widg_w,
                        y = 0 ,
                        w = grid_widg_val_w,
                        h = obj.entry_h*2,
                        frame_a = frame_a,
                        --frame_rect_a = 1,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = grid_txt,
                        func =        function()
                                        if not MOUSE_Match(mouse, obj.b.obj_pers_grid_relsnap) and 
                                            not MOUSE_Match(mouse, obj.b.obj_pers_grid_visible)  then
                                            
                                          if data.MM_grid_ignoreleftdrag == 1 then 
                                            if data.obj_type_int == 8 and data.ME_ptr then MIDIEditor_OnCommand( data.ME_ptr, 1014)  else Main_OnCommand(1157, 0) end -- toggle grid
                                            redraw = 2
                                          end
                                          
                                          if data.obj_type_int ~= 8 then 
                                            mouse.temp_val = data.grid_val
                                            mouse.temp_val2 = data.grid_istriplet
                                           else
                                            mouse.temp_val = data.MIDIgrid_val
                                            mouse.temp_val2 = data.MIDIgrid_istriplet
                                          end
                                          redraw = 1    
                                        end                        
                                      end,
                        func_wheel =  function()local div
                                        if mouse.wheel_trig > 0 then div = 2 
                                          elseif mouse.wheel_trig < 0 then div = 0.5 
                                          else return
                                        end 
                                        local lim_max = 1
                                      
                                        if data.obj_type_int ~= 8 then 
                                          if data.grid_istriplet then lim_max = 2/3 end
                                          local out_val = lim(data.grid_val*div, 0.0078125*lim_max, lim_max)
                                          GetSetProjectGrid( 0, true,  out_val, data.grid_swingactive_int, data.grid_swingamt )
                                         else
                                          if data.MIDIgrid_istriplet then lim_max = 2/3 end
                                          local out_val = lim(data.MIDIgrid_val*div, 0.0078125*lim_max, lim_max)
                                          SetMIDIEditorGrid(0,out_val)                                         
                                        end
                                        redraw = 2                           
                                      end,                                              
                        func_drag =   function() 
                                        if mouse.temp_val and data.MM_grid_ignoreleftdrag == 0 then 
                                          
                                          local mouse_shift, div
                                          if data.always_use_x_axis==1 then 
                                            mouse_shift = math.floor(-mouse.dx/10)
                                            div = 1
                                           else
                                            mouse_shift = math.floor(mouse.dy/30)
                                            div = 1
                                          end                                            
                                          
                                          if mouse_shift > 0 then div = 2^math.abs(mouse_shift)
                                           elseif mouse_shift < 0 then div = 0.5^math.abs(mouse_shift)
                                          end 
                                          
                                          if div then 
                                            local lim_max = 1
                                            
                                            if data.obj_type_int ~= 8 then
                                              if data.grid_istriplet then lim_max = 2/3 end
                                             else
                                              if data.MIDIgrid_istriplet then lim_max = 2/3 end
                                            end
                                            
                                            local out_val = lim(mouse.temp_val*div, 0.0078125*lim_max, lim_max)                                         
                                            if data.obj_type_int == 8 then
                                              SetMIDIEditorGrid( 0, out_val )
                                             else 
                                              GetSetProjectGrid( 0, true,  out_val, data.grid_swingactive_int, data.grid_swingamt )
                                            end
                                            if data.obj_type_int ~= 8 then 
                                              _, obj.b.obj_pers_grid_B_val.txt = MPL_GetFormattedGrid()
                                             else 
                                              _, obj.b.obj_pers_grid_B_val.txt = MPL_GetFormattedMIDIGrid()
                                            end
                                            redraw = 1  
                                          end 
                                        end
                                      end,
                        func_DC =     function()
                                        if data.MM_grid_ignoreleftdrag == 0 then
                                          if data.MM_grid_doubleclick == 0 then
                                            Main_OnCommand(40071, 0) -- open settings
                                           elseif data.MM_grid_doubleclick == 1 and data.MM_grid_default_reset_grid then
                                            if data.obj_type_int ~= 8 then 
                                              GetSetProjectGrid( 0, true,  conf.MM_grid_default_reset_grid, data.grid_swingactive_int, data.grid_swingamt )
                                             else
                                              SetMIDIEditorGrid( 0, conf.MM_grid_default_reset_MIDIgrid )
                                            end
                                          end
                                          redraw = 2
                                        end
                                      end,
                        func_R =     function()
                                        if data.MM_grid_rightclick == 1 then
                                          if data.obj_type_int == 8 and data.ME_ptr and MIDIEditor_GetActive() then 
                                            MIDIEditor_OnCommand( data.ME_ptr, 1014)  else Main_OnCommand(1157, 0) end -- toggle grid -- toggle grid
                                         elseif data.MM_grid_rightclick == 0 then
                                          Main_OnCommand(40071, 0) -- open settings
                                        end
                                        redraw = 2
                                      end,                                      
                                      
                                      
                                      }
    if conf.dock_orientation == 1 then 
      obj.b.obj_pers_grid_B_val.persist_buf = nil   
      obj.b.obj_pers_grid_B_val.x = vert_sep*2
      obj.b.obj_pers_grid_B_val.y = y_offs-obj.entry_h
      obj.b.obj_pers_grid_B_val.w = vert_sep
      obj.b.obj_pers_grid_B_val.h = obj.entry_h
    end                                        
    local tripl_a = 0
    if (data.grid_istriplet and data.obj_type_int ~= 8) or (data.MIDIgrid_istriplet and data.obj_type_int == 8) then  tripl_a = obj.frame_a_state end
    obj.b.obj_pers_grid_tripl = { persist_buf = true,
                        x = x_margin - grid_widg_w+ grid_widg_val_w-1,
                        y = 0 ,
                        w = grid_widg_w_trpl,
                        h = obj.entry_h*2,
                        frame_a = tripl_a,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'T',                          
                        func =  function() 
                                  if not MOUSE_Match(mouse, obj.b.obj_pers_grid_relsnap) and 
                                      not MOUSE_Match(mouse, obj.b.obj_pers_grid_visible)  then
                                      
                                        if data.obj_type_int ~= 8 then 
                                          if not data.grid_istriplet then
                                            GetSetProjectGrid( 0, true, data.grid_val  * 2/3 )
                                            if data.grid_vis == 0 then  Action(40145) end
                                           else 
                                            GetSetProjectGrid( 0, true, data.grid_val  * 3/2  )
                                            if data.grid_vis == 0 then  Action(40145) end
                                          end
                                         elseif data.obj_type_int == 8 and data.ME_ptr and MIDIEditor_GetActive() then
                                          if not data.MIDIgrid_istriplet then
                                            SetMIDIEditorGrid( 0, data.MIDIgrid_val  * 2/3 )
                                            if data.MIDIgrid_vis == 0 then  MIDIEditor_OnCommand( data.ME_ptr, NamedCommandLookup('_NF_ME_TOGGLETRIPLET')) end
                                           else 
                                            SetMIDIEditorGrid( 0, data.MIDIgrid_val  * 3/2 )
                                            if data.MIDIgrid_vis == 0 then  MIDIEditor_OnCommand( data.ME_ptr, NamedCommandLookup('_NF_ME_TOGGLETRIPLET')) end
                                          end
                                        end                                          
                                        redraw = 2
                                  end
                                end} 
    if conf.dock_orientation == 1 then 
      --obj.b.obj_pers_grid_tripl.persist_buf = nil   
      obj.b.obj_pers_grid_tripl.x = vert_sep*3
      obj.b.obj_pers_grid_tripl.y = y_offs-obj.entry_h
      obj.b.obj_pers_grid_tripl.w = vert_sep
      obj.b.obj_pers_grid_tripl.h = obj.entry_h
      obj.b.obj_pers_grid_tripl.frame_a = 0
      if (data.grid_istriplet and data.obj_type_int ~= 8) or (data.MIDIgrid_istriplet and data.obj_type_int == 8) then  
        obj.b.obj_pers_grid_tripl.txt_a = obj.txt_a
       else
        obj.b.obj_pers_grid_tripl.txt_a = 0.2
      end
    end                                  
                                            
    return grid_widg_w
  end  




  --------------------------------------------------------------
  function Widgets_Persist_timeselstart(data, obj, mouse, x_margin, widgets, conf, y_offs)    -- generate position controls 
    obj.b.obj_tsstart = { persist_buf = true,
                        x = x_margin-obj.entry_w2,
                        y = obj.offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'TimeSelStart'} 
    obj.b.obj_tsstart_back = { persist_buf = true,
                        x =  x_margin-obj.entry_w2,
                        y = obj.offs *2 +obj.entry_h ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
      if conf.dock_orientation == 1 then
        obj.b.obj_tsstart.x= 0
        obj.b.obj_tsstart.y = y_offs-obj.entry_h
        obj.b.obj_tsstart.w = obj.entry_w2/2
        obj.b.obj_tsstart_back.x= obj.entry_w2/2
        obj.b.obj_tsstart_back.y = y_offs-obj.entry_h
        obj.b.obj_tsstart_back.w = obj.entry_w2/2
        obj.b.obj_tsstart_back.frame_a = obj.frame_a_head
      end                          
                        
      local TSpos_str =  data.timeselectionstart_format

      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = MPL_GetTableOfCtrlValues(TSpos_str), 
                        table_key='timesel_position_ctrl',
                        x_offs= obj.b.obj_tsstart_back.x,  
                        y_offs= obj.b.obj_tsstart_back.y,  
                        w_com=obj.b.obj_tsstart_back.w,
                        src_val=data.timeselectionstart,
                        src_val_key= '',
                        modify_func= MPL_ModifyTimeVal,
                        app_func= Apply_TimeselSt,                         
                        mouse_scale= obj.mouse_scal_time,
                        use_mouse_drag_xAxis = data.always_use_x_axis==1,
                        persist_buf = true})                         
    return obj.entry_w2
  end  
  function Apply_TimeselSt(data, obj, out_value, butkey, out_str_toparse, mouse)
    if not out_str_toparse then  
      local startOut, endOut = GetSet_LoopTimeRange2( 0, false, false, -1, -1, false )
      local nudge = startOut - math.max(0,out_value)  
      GetSet_LoopTimeRange2( 0, true, true, math.max(0,out_value), endOut-nudge, false )
      Main_OnCommand(40749,0) -- Options: Set loop points linked to time selection
      local new_str = format_timestr_pos( math.max(0,out_value), '', data.timiselwidgetsformatoverride ) 
      local new_str_t = MPL_GetTableOfCtrlValues(new_str)
      for i = 1, #new_str_t do
        obj.b[butkey..i].txt = new_str_t[i]
      end
     else
      -- nudge values from first item
      local out_val = parse_timestr_pos(out_str_toparse,data.timiselwidgetsformatoverride) 
      local startOut, endOut = GetSet_LoopTimeRange2( 0, false, false, -1, -1, false )  
      local nudge = startOut - math.max(0,out_val) 
      GetSet_LoopTimeRange2( 0, true, true, math.max(0,out_val), endOut-nudge, false )
      redraw = 2   
    end
  end  
  -------------------------------------------------------------- 








  --------------------------------------------------------------
  function Widgets_Persist_timeselend(data, obj, mouse, x_margin, widgets, conf, y_offs)    -- generate position controls 
    obj.b.obj_tsend = { persist_buf = true,
                        x = x_margin-obj.entry_w2,
                        y = obj.offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'TimeSelEnd'} 
    obj.b.obj_tsend_back = { persist_buf = true,
                        x =  x_margin-obj.entry_w2,
                        y = obj.offs *2 +obj.entry_h ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
      if conf.dock_orientation == 1 then
        obj.b.obj_tsend.x= 0
        obj.b.obj_tsend.y = y_offs-obj.entry_h
        obj.b.obj_tsend.w = obj.entry_w2/2
        obj.b.obj_tsend_back.x= obj.entry_w2/2
        obj.b.obj_tsend_back.y = y_offs-obj.entry_h
        obj.b.obj_tsend_back.w = obj.entry_w2/2
        obj.b.obj_tsend_back.frame_a = obj.frame_a_head
      end                     
                        
      local TSposend_str =  data.timeselectionend_format
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = MPL_GetTableOfCtrlValues(TSposend_str), 
                        table_key='timeselend_position_ctrl',
                        x_offs= obj.b.obj_tsend_back.x, 
                        y_offs = obj.b.obj_tsend_back.y ,
                        w_com=obj.b.obj_tsend_back.w,--obj.entry_w2,
                        src_val=data.timeselectionend,
                        src_val_key= '',
                        modify_func= MPL_ModifyTimeVal,
                        app_func= Apply_Timeselend,                         
                        mouse_scale= obj.mouse_scal_time,
                        use_mouse_drag_xAxis = data.always_use_x_axis==1,
                        persist_buf = true})                         
    return obj.entry_w2
  end  
  function Apply_Timeselend(data, obj, out_value, butkey, out_str_toparse, mouse)
    if not out_str_toparse then  
      local startOut, endOut = GetSet_LoopTimeRange2( 0, false, false, -1, -1, false )  
      GetSet_LoopTimeRange2( 0, true, true, startOut, math.max(0,out_value), false )
      Main_OnCommand(40749,0) -- Options: Set loop points linked to time selection
      local new_str = format_timestr_pos( math.max(0,out_value), '',data.timiselwidgetsformatoverride ) 
      local new_str_t = MPL_GetTableOfCtrlValues(new_str)
      for i = 1, #new_str_t do
        obj.b[butkey..i].txt = new_str_t[i]
      end
     else
      -- nudge values from first item
      local out_val = reaper.parse_timestr_pos(out_str_toparse,data.timiselwidgetsformatoverride) 
      local startOut, endOut = GetSet_LoopTimeRange2( 0, false, false, -1, -1, false ) 
      GetSet_LoopTimeRange2( 0, true, true, startOut, out_val, false )
      redraw = 2   
    end
  end  
  -------------------------------------------------------------- 




  --------------------------------------------------------------
  function Widgets_Persist_timesellen(data, obj, mouse, x_margin, widgets, conf, y_offs)    -- generate position controls 
    obj.b.obj_tslen = { persist_buf = true,
                        x = x_margin-obj.entry_w2,
                        y = obj.offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'TimeSelLen'} 
    obj.b.obj_tslen_back = { persist_buf = true,
                        x =  x_margin-obj.entry_w2,
                        y = obj.offs *2 +obj.entry_h ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
      if conf.dock_orientation == 1 then
        obj.b.obj_tslen.x= 0
        obj.b.obj_tslen.y = y_offs-obj.entry_h
        obj.b.obj_tslen.w = obj.entry_w2/2
        obj.b.obj_tslen_back.x= obj.entry_w2/2
        obj.b.obj_tslen_back.y = y_offs-obj.entry_h
        obj.b.obj_tslen_back.w = obj.entry_w2/2
        obj.b.obj_tslen_back.frame_a = obj.frame_a_head
      end                          
                        
      local TSlen_str =  data.timeselectionlen_format
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = MPL_GetTableOfCtrlValues(TSlen_str), 
                        table_key='timesellen_position_ctrl',
                        x_offs= obj.b.obj_tslen_back.x,  
                        y_offs= obj.b.obj_tslen_back.y,  
                        w_com=obj.b.obj_tslen_back.w,--obj.entry_w2,
                        src_val=data.timeselectionlen,
                        src_val_key= '',
                        modify_func= MPL_ModifyTimeVal,
                        app_func= Apply_Timesellen,                         
                        mouse_scale= obj.mouse_scal_time,
                        use_mouse_drag_xAxis = data.always_use_x_axis==1,
                        persist_buf = true})                         
    return obj.entry_w2
  end  
  function Apply_Timesellen(data, obj, out_value, butkey, out_str_toparse, mouse)
    if not out_str_toparse then  
      local startOut, endOut = GetSet_LoopTimeRange2( 0, false, false, -1, -1, false )  
      GetSet_LoopTimeRange2( 0, true, true, startOut, startOut+math.max(0,out_value), false )
      Main_OnCommand(40749,0) -- Options: Set loop points linked to time selection
      local new_str = format_timestr_len( math.max(0,out_value), '',startOut, data.timiselwidgetsformatoverride ) 
      local new_str_t = MPL_GetTableOfCtrlValues(new_str)
      for i = 1, #new_str_t do
        obj.b[butkey..i].txt = new_str_t[i]
      end
     else
      local startOut, endOut = GetSet_LoopTimeRange2( 0, false, false, -1, -1, false )  
      local out_val = parse_timestr_len(out_str_toparse,startOut,data.timiselwidgetsformatoverride) 
      GetSet_LoopTimeRange2( 0, true, true, startOut, startOut+out_val, false )
      UpdateArrange()
      redraw = 2   
    end
  end  
  -------------------------------------------------------------- 
  
  
  --------------------------------------------------------------
  function Widgets_Persist_timeselLeftEdge(data, obj, mouse, x_margin, widgets, conf, y_offs)    -- generate position controls 
    obj.b.obj_tsledge = { persist_buf = true,
                        x = x_margin-obj.entry_w2,
                        y = obj.offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'TimeSelLEdge'} 
    obj.b.obj_tsledge_back = { persist_buf = true,
                        x =  x_margin-obj.entry_w2,
                        y = obj.offs *2 +obj.entry_h ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
      if conf.dock_orientation == 1 then
        obj.b.obj_tsledge.x= 0
        obj.b.obj_tsledge.y = y_offs-obj.entry_h
        obj.b.obj_tsledge.w = obj.entry_w2/2
        obj.b.obj_tsledge_back.x= obj.entry_w2/2
        obj.b.obj_tsledge_back.y = y_offs-obj.entry_h
        obj.b.obj_tsledge_back.w = obj.entry_w2/2
        obj.b.obj_tsledge_back.frame_a = obj.frame_a_head
      end                          
                        
      local TSpos_str =  data.timeselectionstart_format

      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = MPL_GetTableOfCtrlValues(TSpos_str), 
                        table_key='tsledge_position_ctrl',
                        x_offs= obj.b.obj_tsledge_back.x,  
                        y_offs= obj.b.obj_tsledge_back.y,  
                        w_com=obj.b.obj_tsledge_back.w,
                        src_val=data.timeselectionstart,
                        src_val_key= '',
                        modify_func= MPL_ModifyTimeVal,
                        app_func= Apply_TimeselSt2,                         
                        mouse_scale= obj.mouse_scal_time,
                        use_mouse_drag_xAxis = data.always_use_x_axis==1,
                        persist_buf = true})                         
    return obj.entry_w2
  end  
  function Apply_TimeselSt2(data, obj, out_value, butkey, out_str_toparse, mouse)
    if not out_str_toparse then  
      local startOut, endOut = GetSet_LoopTimeRange2( 0, false, false, -1, -1, false )
      local nudge = startOut - math.max(0,out_value)  
      GetSet_LoopTimeRange2( 0, true, true, math.max(0,out_value), endOut, false )
      Main_OnCommand(40749,0) -- Options: Set loop points linked to time selection
      local new_str = format_timestr_pos( math.max(0,out_value), '', data.timiselwidgetsformatoverride ) 
      local new_str_t = MPL_GetTableOfCtrlValues(new_str)
      for i = 1, #new_str_t do
        obj.b[butkey..i].txt = new_str_t[i]
      end
     else
      -- nudge values from first item
      local out_val = parse_timestr_pos(out_str_toparse,data.timiselwidgetsformatoverride) 
      local startOut, endOut = GetSet_LoopTimeRange2( 0, false, false, -1, -1, false )  
      local nudge = startOut - math.max(0,out_val) 
      GetSet_LoopTimeRange2( 0, true, true, math.max(0,out_val), endOut, false )
      redraw = 2   
    end
  end  
  -------------------------------------------------------------- 
  
  function V_Widgets_Persist_transport(data, obj, mouse, x_margin, widgets, conf, y_offs)
    local rep_w = 40
    obj.b.obj_pers_transport_state_bck1 = {--persist_buf = true,
                        x = 0,
                        y = y_offs-obj.entry_h*2,
                        w = gfx.w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        fontsz = obj.fontsz_clock}   
    obj.b.obj_pers_transport_state_bck2 = {--persist_buf = true,
                        x = 0,
                        y = y_offs-obj.entry_h,
                        w = gfx.w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        fontsz = obj.fontsz_clock}  
    local state_col, state
    local txt = 'Stop'
    local txt_a,txt_a_repstate =obj.txt_a
    if data.repeat_state == 0 then txt_a_repstate = txt_a * 0.3 end
    if  data.record  then
      state = true
      txt = 'Record'
      state_col = 'red'
     elseif data.play  then
      state = true
      txt = 'Play'
      state_col = 'green'
     elseif data.pause  then
      txt = 'Pause'
      state = true
      state_col = 'greendark'
     else
    end  
    obj.b.obj_pers_transport_A_repeat = { persist_buf = true,
                        x = gfx.w-rep_w,
                        y = y_offs-obj.entry_h*2,
                        w = rep_w,
                        h = obj.entry_h*2,
                        frame_a = 0,--obj.frame_a_entry,
                        frame_rect_a = 0,
                        txt_a = txt_a_repstate,
                        --txt_col = 'white',
                        txt = 'REP',
                        --aligh_txt = 1,
                        fontsz = obj.fontsz_grid_rel,
                        func =  function ()
                                  Action(1068)--Transport: Toggle repeat
                                  redraw = 2
                                end}     
    obj.b.obj_pers_transport_B_state = {--persist_buf = true,
                        x = 0,
                        y = y_offs-obj.entry_h*2,
                        w = gfx.w-rep_w,
                        h = obj.entry_h*2,
                        frame_a = 0,--,
                        state_col = state_col,
                        state = state,
                        --frame_rect_a = 1,
                        txt_a = obj.txt_a,
                        txt_col = 'white',
                        txt = txt,
                        func =        function()
                                        if MOUSE_Match(mouse, obj.b.obj_pers_transport_A_repeat) then return end
                                        if not mouse.Ctrl then
                                          if data.pause then
                                            Main_OnCommand(1016, 0) --Transport: Stop
                                            if data.play_editcurzeropos then SetEditCurPos( data.play_editcurzeropos, true , true ) end
                                           else
                                            Main_OnCommand(40044, 0) -- Transport: Play/stop
                                            data.play_editcurzeropos = GetCursorPositionEx( 0 )
                                          end
                                          redraw = 1    
                                          
                                         else
                                          if not data.play then
                                             data.play_editcurzeropos = GetCursorPositionEx( 0 )
                                           end
                                           Main_OnCommand(1013, 0) -- Transport: Record                                       
                                           redraw = 1 
                                          end                       
                                      end,   
                        func_R =     function()
                                        Main_OnCommand(40073, 0) -- Transport: Play/pause                                        
                                        redraw = 1
                                      end,                                      
                                      
                                      
                                      }                                                 
  end
------------------------------------------------------------
  function Widgets_Persist_transport(data, obj, mouse, x_margin, widgets, conf, y_offs)    -- generate position controls 
    if conf.dock_orientation == 1 then 
      V_Widgets_Persist_transport(data, obj, mouse, x_margin, widgets, conf, y_offs)
      return 0, obj.entry_h*2
    end
    local transport_state_w = 60*conf.scaling
    local repeat_w = 25*conf.scaling
    local frame_a = 0
    local txt = 'Stop'
    local gridwidg_xpos = gfx.w-transport_state_w-obj.menu_b_rect_side - x_margin
    local txt_a,txt_a_repstate =obj.txt_a
    if data.repeat_state == 0 then txt_a_repstate = txt_a * 0.3 end
    obj.b.obj_pers_transport_state_bck1 = {persist_buf = true,
                        x = x_margin - transport_state_w,
                        y = obj.offs ,
                        w = transport_state_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        fontsz = obj.fontsz_clock}   
    obj.b.obj_pers_transport_state_bck2 = {persist_buf = true,
                        x = x_margin - transport_state_w,
                        y = obj.offs+obj.entry_h ,
                        w = transport_state_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        fontsz = obj.fontsz_clock}   
    obj.b.obj_pers_transport_A_repeat = { persist_buf = true,
                        x = x_margin-transport_state_w,
                        y = obj.offs ,
                        w = repeat_w,
                        h = 10,
                        frame_a = 0,--obj.frame_a_entry,
                        frame_rect_a = 0,
                        txt_a = txt_a_repstate,
                        --txt_col = 'white',
                        txt = 'REP',
                        aligh_txt = 1,
                        fontsz = obj.fontsz_grid_rel,
                        func =  function ()
                                  Action(1068)--Transport: Toggle repeat
                                  redraw = 2
                                end}                         
    local state_col, state
    if  data.record  then
      state = true
      txt = 'Record'
      state_col = 'red'
     elseif data.play  then
      state = true
      txt = 'Play'
      state_col = 'green'
     elseif data.pause  then
      txt = 'Pause'
      state = true
      state_col = 'greendark'
     else
    end
    obj.b.obj_pers_transport_B_state = {persist_buf = true,
                        x = x_margin - transport_state_w,
                        y =  0,
                        w = transport_state_w,
                        h = obj.entry_h*2,
                        frame_a = frame_a,--,
                        state_col = state_col,
                        state = state,
                        --frame_rect_a = 1,
                        txt_a = obj.txt_a,
                        txt_col = 'white',
                        txt = txt,
                        func =        function()
                                        if MOUSE_Match(mouse, obj.b.obj_pers_transport_A_repeat) then return end
                                        if not mouse.Ctrl then
                                          if data.pause then
                                            Main_OnCommand(1016, 0) --Transport: Stop
                                            if data.play_editcurzeropos then SetEditCurPos( data.play_editcurzeropos, true , true ) end
                                           else
                                            Main_OnCommand(40044, 0) -- Transport: Play/stop
                                            data.play_editcurzeropos = GetCursorPositionEx( 0 )
                                          end
                                          redraw = 1    
                                          
                                         else
                                          if not data.play then
                                             data.play_editcurzeropos = GetCursorPositionEx( 0 )
                                           end
                                           Main_OnCommand(1013, 0) -- Transport: Record                                       
                                           redraw = 1 
                                          end                       
                                      end,   
                        func_R =     function()
                                        Main_OnCommand(40073, 0) -- Transport: Play/pause                                        
                                        redraw = 1
                                      end,                                      
                                      
                                      
                                      }
                                              
    return transport_state_w
  end  
  
  
  
  
  
  
  
  function Widgets_Persist_bpm(data, obj, mouse, x_margin, widgets, conf, y_offs) 
    local bpm_w = 60*conf.scaling
    local frame_a = 0
    local gridwidg_xpos = gfx.w-bpm_w-obj.menu_b_rect_side - x_margin
    obj.b.obj_pers_bpm = { persist_buf = true,
                        x = x_margin - bpm_w,
                        y = obj.offs ,
                        w = bpm_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        fontsz = obj.fontsz_entry,
                        txt = data.TempoMarker_bpm_format,
                        func =  function()  
                                  local retval0,ret_str = GetUserInputs( 'Edit BPM', 1, 'BPM,extrawidth=200', data.TempoMarker_bpm )
                                  if retval0 and tonumber (ret_str) then
                                    if data.TempoMarker_ID == -1 then 
                                      CSurf_OnTempoChange(  tonumber (ret_str) )
                                      UpdateTimeline()
                                      redraw = 2  
                                     else 
                                      SetTempoTimeSigMarker( 0, data.TempoMarker_ID, 
                                                                data.TempoMarker_timepos, 
                                                                -1, 
                                                                -1, 
                                                                tonumber (ret_str), 
                                                                data.TempoMarker_timesig_num, 
                                                                data.TempoMarker_timesig_denom, 
                                                                data.TempoMarker_lineartempochange )
                                      UpdateTimeline()
                                    end
                                  end
                                end,
                        func_wheel =  function()  
                                  local src_bpm = data.TempoMarker_bpm
                                  local out_bpm = data.TempoMarker_bpm + mouse.wheel_trig
                                  if out_bpm then
                                    if data.TempoMarker_ID == -1 then 
                                      CSurf_OnTempoChange( out_bpm )
                                      UpdateTimeline()
                                      redraw = 2  
                                     else 
                                      SetTempoTimeSigMarker( 0, data.TempoMarker_ID, 
                                                                data.TempoMarker_timepos, 
                                                                -1, 
                                                                -1, 
                                                                out_bpm, 
                                                                data.TempoMarker_timesig_num, 
                                                                data.TempoMarker_timesig_denom, 
                                                                data.TempoMarker_lineartempochange )
                                      UpdateTimeline()
                                    end
                                  end
                                end}
    if conf.dock_orientation == 1 then 
      obj.b.obj_pers_bpm.persist_buf = nil   
      obj.b.obj_pers_bpm.x = 0
      obj.b.obj_pers_bpm.y = y_offs-obj.entry_h
      obj.b.obj_pers_bpm.w = gfx.w/2
      obj.b.obj_pers_bpm.h = obj.entry_h
    end                                                                
    obj.b.obj_pers_timesign = { persist_buf = true,
                        x = x_margin - bpm_w,
                        y = obj.offs +obj.entry_h,
                        w = bpm_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        fontsz = obj.fontsz_entry,
                        txt = data.TempoMarker_timesig1..'/'..data.TempoMarker_timesig2,
                        func =  function()  
                                  local retval0,ret_str = GetUserInputs( 'Edit Time signature', 2, 'Numerator,Denomerator', data.TempoMarker_timesig1..','..data.TempoMarker_timesig2 )
                                  if not retval0 then return end
                                  if not ret_str:match('(%d+)%,(%d+)') then return end
                                  local num, denom = ret_str:match('(%d+)%,(%d+)')
                                  if not tonumber(num) or not tonumber(denom) then return end
                                  if data.TempoMarker_ID ~= -1 then 
                                    SetTempoTimeSigMarker( 0, data.TempoMarker_ID, 
                                                                data.TempoMarker_timepos, 
                                                                -1, 
                                                                -1, 
                                                                data.TempoMarker_bpm, 
                                                                tonumber(num), 
                                                                tonumber(denom), 
                                                                data.TempoMarker_lineartempochange )
                                      UpdateTimeline()
                                    else 
                                    SetTempoTimeSigMarker( 0,-1, 
                                                                data.editcur_pos, 
                                                                -1, 
                                                                -1, 
                                                                data.TempoMarker_bpm, 
                                                                tonumber(num), 
                                                                tonumber(denom), 
                                                                data.TempoMarker_lineartempochange )
                                      UpdateTimeline()                                     
                                  end
                                end,
                        func_wheel =  function()  
                                  local src_num = data.TempoMarker_timesig1
                                  local out_num = data.TempoMarker_timesig1 + mouse.wheel_trig
                                  if not out_num then return end
                                  if data.TempoMarker_ID ~= -1 then 
                                    SetTempoTimeSigMarker( 0, data.TempoMarker_ID, 
                                                                data.TempoMarker_timepos, 
                                                                -1, 
                                                                -1, 
                                                                data.TempoMarker_bpm, 
                                                                out_num, 
                                                                data.TempoMarker_timesig2, 
                                                                data.TempoMarker_lineartempochange )
                                      UpdateTimeline()
                                    else 
                                    SetTempoTimeSigMarker( 0,-1, 
                                                                data.editcur_pos, 
                                                                -1, 
                                                                -1, 
                                                                data.TempoMarker_bpm, 
                                                                out_num, 
                                                                data.TempoMarker_timesig2, 
                                                                data.TempoMarker_lineartempochange )
                                      UpdateTimeline()                                     
                                  end
                                end}   
    if conf.dock_orientation == 1 then 
      obj.b.obj_pers_timesign.persist_buf = nil   
      obj.b.obj_pers_timesign.x =  gfx.w/2
      obj.b.obj_pers_timesign.y = y_offs-obj.entry_h
      obj.b.obj_pers_timesign.w = gfx.w/2
      obj.b.obj_pers_timesign.h = obj.entry_h
      obj.b.obj_pers_timesign.frame_a = obj.frame_a_head
    end                                                  
    return bpm_w
  end    
  
  
  
  
  
  
  
  
  
  
  
  
  ----------------------------------------------------------------------------
  function Widgets_Persist_lasttouchfx(data, obj, mouse, x_margin, widgets, conf, y_offs)
    local lasttouchfx_w = 120*conf.scaling 
    if not data.LTFX.exist or data.LTFX_parname == 'Bypass' or data.LTFX_fxname == 'JS: time_adjustment' then return end
    obj.b.obj_lasttouchfx_back1 = { persist_buf = true,
                        x = x_margin-lasttouchfx_w,
                        y = obj.offs ,
                        w = lasttouchfx_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        fontsz = obj.fontsz_entry,
                        txt = '',
                        ignore_mouse = true}  
    obj.b.obj_lasttouchfx_param_back = { persist_buf = true,
                        x =  x_margin-lasttouchfx_w,
                        y = obj.offs *2 +obj.entry_h ,
                        w = lasttouchfx_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        fontsz = obj.fontsz_entry,
                        ignore_mouse = true}
      if conf.dock_orientation == 1 then
        obj.b.obj_lasttouchfx_back1.persist_buf = nil
        obj.b.obj_lasttouchfx_back1.x= 0
        obj.b.obj_lasttouchfx_back1.y = y_offs-obj.entry_h*2
        obj.b.obj_lasttouchfx_back1.w = obj.entry_w2
        obj.b.obj_lasttouchfx_back1.h = obj.entry_h
        obj.b.obj_lasttouchfx_param_back.x= 0
        obj.b.obj_lasttouchfx_param_back.y = y_offs-obj.entry_h
        obj.b.obj_lasttouchfx_param_back.w = obj.entry_w2
        obj.b.obj_lasttouchfx_param_back.frame_a = obj.frame_a_entry     
      end                      
                        
                                 
    obj.b.obj_lasttouchfx_knob = { persist_buf = true,
                        x = x_margin-lasttouchfx_w,
                                y = obj.offs,
                                w = lasttouchfx_w,
                                h = obj.entry_h*2,
                                frame_a = 0,
                                txt = '',
                                txt_a = obj.txt_a,
                                fontsz = obj.fontsz_entry,
                                is_triangle_slider = true,
                                knob_col = obj.txt_col_header,
                                val = lim(data.LTFX_val),
                                func =        function()
                                                mouse.temp_val = data.LTFX_val
                                                redraw = 1                              
                                              end,
                                func_R =        function()
                                                Action(41142)                  
                                              end,                                              
                                func_ctrlL =        function()
                                                mouse.temp_val = data.LTFX_val
                                                redraw = 1                              
                                              end,                                              
                                func_wheel =  function()
                                                local out_value = MPL_ModifyFloatVal(data.LTFX_val, 1, 1, mouse.wheel_trig, data, nil, -2)
                                                out_value = lim(out_value,data.LTFX_minval,data.LTFX_maxval)
                                                ApplyFXVal(out_value, data.LTFX_trptr, data.LTFX_fxID, data.LTFX_parID)
                                                data.LTFX_val = out_value
                                                redraw = 2          
                                              end,                                              
                                func_drag =   function(is_ctrl) 
                                                if not mouse.temp_val then return end
                                                local pow_tol = -2
                                                local out_value, mouse_shift 
                                                
                                                if data.always_use_x_axis==1 then mouse_shift = -mouse.dx else mouse_shift = -mouse.dx end
                                                
                                                out_value = MPL_ModifyFloatVal(mouse.temp_val, 1, 1, math.modf(mouse_shift/obj.mouse_scal_float), data, nil, pow_tol)
                                                out_value = lim(out_value,data.LTFX_minval,data.LTFX_maxval)
                                                ApplyFXVal(out_value, data.LTFX_trptr, data.LTFX_fxID, data.LTFX_parID)
                                                redraw =2
                                              end,
                                func_drag_Ctrl =   function(is_ctrl) 
                                                if not mouse.temp_val then return end
                                                local pow_tol = -4 
                                                local out_value = MPL_ModifyFloatVal(mouse.temp_val, 1, 1, math.modf(mouse.dy/obj.mouse_scal_float), data, nil, pow_tol)
                                                out_value = lim(out_value,data.LTFX_minval,data.LTFX_maxval)
                                                ApplyFXVal(out_value, data.LTFX_trptr, data.LTFX_fxID, data.LTFX_parID)
                                                redraw = 2
                                              end,                                              
                                func_DC =     function() 
                                                local retval0,ret_str = GetUserInputs( 'Edit value', 1, ',extrawidth=100', data.LTFX_val )
                                                if not retval0 or not tonumber(ret_str) then return end
                                                ApplyFXVal(tonumber(ret_str), data.LTFX_trptr, data.LTFX_fxID, data.LTFX_parID)                                                                 
                                              end} 
                                              
      if conf.dock_orientation == 1 then
        obj.b.obj_lasttouchfx_knob.x= obj.entry_w2/2
        obj.b.obj_lasttouchfx_knob.y = y_offs-obj.entry_h*2-1
        obj.b.obj_lasttouchfx_knob.w = obj.entry_w2/2
        obj.b.obj_lasttouchfx_knob.h = obj.entry_h*2
        obj.b.obj_lasttouchfx_knob.is_knob = true
        obj.b.obj_lasttouchfx_knob.knob_yshift = 3
        obj.b.obj_lasttouchfx_knob.knob_w = 40
        obj.b.obj_lasttouchfx_knob.is_triangle_slider = false
      end                                                    
    obj.b.obj_lasttouchfx = { persist_buf = true,
                        x = x_margin-lasttouchfx_w,
                        y = obj.offs ,
                        w = lasttouchfx_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        fontsz = obj.fontsz_entry,
                        txt = MPL_ReduceFXname(data.LTFX_fxname),
                        ignore_mouse = true,
                        func = function() 
                          --TrackFX_Show( data.LTFX_trptr, data.LTFX_fxID, 3 ) 
                        end}
      if conf.dock_orientation == 1 then
        obj.b.obj_lasttouchfx.x= 0
        obj.b.obj_lasttouchfx.y = y_offs-obj.entry_h*2
        obj.b.obj_lasttouchfx.w = obj.entry_w2/2
        obj.b.obj_lasttouchfx.h = obj.entry_h
      end                         
    local LTFX_parname, LTFX_val_format    = '',''         
    if data.LTFX_parname then LTFX_parname = data.LTFX_parname   end
    if data.LTFX_val_format   then LTFX_val_format = data.LTFX_val_format  end                
    obj.b.obj_lasttouchfx_param = { persist_buf = true,
                        x =  x_margin-lasttouchfx_w,
                        y = obj.offs *2 +obj.entry_h ,
                        w = lasttouchfx_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = 0,
                        txt = LTFX_parname..': '..LTFX_val_format,
                        fontsz = obj.fontsz_entry,
                        ignore_mouse = true,
                        func = function () 
                                  --Main_OnCommand(41984,0)--FX: Arm track envelope for last touched FX parameter
                                  --TrackFX_Show( data.LTFX_trptr, data.LTFX_fxID, 3 )
                                end} 
      if conf.dock_orientation == 1 then
        obj.b.obj_lasttouchfx_param.x= 0
        obj.b.obj_lasttouchfx_param.y = y_offs-obj.entry_h
        obj.b.obj_lasttouchfx_param.w = obj.entry_w2/2
        obj.b.obj_lasttouchfx_param.h = obj.entry_h
      end                                
  --[[
                 
    local txt_val = string.format('%.3f',data.LTFX_val)
    obj.b.obj_lasttouchfx_knobval = { persist_buf = true,
                        x = x_margin-val_w-knob_x_offs,
                                    y = obj.offs,
                                    w = lasttouchfx_w,
                                    h = obj.entry_h,
                                    frame_a = 0,
                                    txt = txt_val,
                                    txt_a = obj.txt_a,
                                    fontsz = obj.fontsz_entry,
                                    ignore_mouse = true}
    obj.b.obj_lasttouchfx_knobval2 = { persist_buf = true,
                        x = x_margin-val_w-knob_x_offs,
                                    y = obj.offs+obj.entry_h,
                                    w = val_w,
                                    h = obj.entry_h,
                                    frame_a = 0,
                                    txt = data.LTFX_val_format,
                                    txt_a = obj.txt_a,
                                    fontsz = obj.fontsz_entry,
                                    ignore_mouse = true}  ]]                                               
    return lasttouchfx_w,obj.entry_h*2              
  end  
  ------------------------------------------------------------------------  
  function ApplyFXVal(val, track, fx, param) 
    TrackFX_SetParamNormalized( track, fx, param, val )
  end 
  
  
  
  
  
  
  
  
  
  
  ------------------------------------------------------------------------  
  function Widgets_Persist_clock(data, obj, mouse, x_margin, widgets, conf, y_offs)
    local clock_w = 130*conf.scaling
    if data.persist_clock_showtimesec > 0 then clock_w = 260*conf.scaling end
    local frame_a = 0
    obj.b.obj_pers_clock_back1 = {persist_buf = true,
                        x = x_margin - clock_w,
                        y = obj.offs ,
                        w = clock_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        fontsz = obj.fontsz_clock}
    obj.b.obj_pers_clock_back2 = {persist_buf = true,
                        x = x_margin - clock_w,
                        y = obj.offs+obj.entry_h ,
                        w = clock_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        fontsz = obj.fontsz_clock}  
    obj.b.obj_pers_clock = { outside_buf = true,
                        x = x_margin - clock_w,
                        y = obj.offs ,
                        w = clock_w,
                        h = obj.entry_h*2,
                        frame_a = 0,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        fontsz = obj.fontsz_clock,
                        txt = data.editcur_pos_format  -- SEE GUI_Main
                        }
      if conf.dock_orientation == 1 then
        obj.b.obj_pers_clock_back1.persist_buf = nil
        obj.b.obj_pers_clock_back1.x= 0
        obj.b.obj_pers_clock_back1.y = y_offs-obj.entry_h*2
        obj.b.obj_pers_clock_back1.w = obj.entry_w2
        obj.b.obj_pers_clock_back1.h = obj.entry_h
        obj.b.obj_pers_clock_back2.x= 0
        obj.b.obj_pers_clock_back2.y = y_offs-obj.entry_h
        obj.b.obj_pers_clock_back2.w = obj.entry_w2
        obj.b.obj_pers_clock_back2.frame_a = obj.frame_a_entry   
        
        obj.b.obj_pers_clock.x= 0
        obj.b.obj_pers_clock.y = y_offs-obj.entry_h*2
        obj.b.obj_pers_clock.w = obj.entry_w2
        obj.b.obj_pers_clock.h = obj.entry_h*2        
          
      end                                 
    return clock_w   , obj.entry_h*2
  end
  ------------------------------------------------------------------------  
  function Widgets_Persist_chordlive(data, obj, mouse, x_margin, widgets, conf, y_offs)
    local clock_w = 130*conf.scaling
    local frame_a = 0
    obj.b.obj_pers_chordlive_back1 = {persist_buf = true,
                        x = x_margin - clock_w,
                        y = obj.offs ,
                        w = clock_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        fontsz = obj.fontsz_clock}
    obj.b.obj_pers_chordlive_back2 = {persist_buf = true,
                        x = x_margin - clock_w,
                        y = obj.offs+obj.entry_h ,
                        w = clock_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        fontsz = obj.fontsz_clock}  
    obj.b.obj_pers_chordlive = { outside_buf = true,
                        x = x_margin - clock_w,
                        y = obj.offs ,
                        w = clock_w,
                        h = obj.entry_h*2,
                        frame_a = 0,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        fontsz = obj.fontsz_clock,
                        txt = data.retrospectchordkey..' '..data.retrospectchordname  -- SEE GUI_Main
                        }
      if conf.dock_orientation == 1 then
        obj.b.obj_pers_chordlive_back1.persist_buf = nil
        obj.b.obj_pers_chordlive_back1.x= 0
        obj.b.obj_pers_chordlive_back1.y = y_offs-obj.entry_h*2
        obj.b.obj_pers_chordlive_back1.w = obj.entry_w2
        obj.b.obj_pers_chordlive_back1.h = obj.entry_h
        obj.b.obj_pers_chordlive_back2.x= 0
        obj.b.obj_pers_chordlive_back2.y = y_offs-obj.entry_h
        obj.b.obj_pers_chordlive_back2.w = obj.entry_w2
        obj.b.obj_pers_chordlive_back2.frame_a = obj.frame_a_entry   
        
        obj.b.obj_pers_chordlive.x= 0
        obj.b.obj_pers_chordlive.y = y_offs-obj.entry_h*2
        obj.b.obj_pers_chordlive.w = obj.entry_w2
        obj.b.obj_pers_chordlive.h = obj.entry_h*2        
          
      end                                 
    return clock_w   , obj.entry_h*2
  end
  ------------------------------------------------------------------------  
  function Widgets_Persist_mastermeter(data, obj, mouse, x_margin, widgets, conf, y_offs)
    local mastermeter_w = 110*conf.scaling
    local frame_a = 0
    obj.b.obj_pers_mastermeter_back1 = {persist_buf = true,
                        x = x_margin - mastermeter_w,
                        y = obj.offs ,
                        w = mastermeter_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        fontsz = obj.fontsz_clock}
    obj.b.obj_pers_mastermeter_back2 = {persist_buf = true,
                        x = x_margin - mastermeter_w,
                        y = obj.offs+obj.entry_h ,
                        w = mastermeter_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        fontsz = obj.fontsz_clock}  
    obj.b.obj_pers_mastermeter = { outside_buf = true,
                        x = x_margin - mastermeter_w,
                        y = obj.offs ,
                        w = mastermeter_w,
                        h = obj.entry_h*2,
                        frame_a = 0,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        fontsz = obj.fontsz_clock,
                        txt =data.masterdata.rmsR -- SEE GUI_Main
                        }
      if conf.dock_orientation == 1 then
        obj.b.obj_pers_mastermeter_back1.persist_buf = nil
        obj.b.obj_pers_mastermeter_back1.x= 0
        obj.b.obj_pers_mastermeter_back1.y = y_offs-obj.entry_h*2
        obj.b.obj_pers_mastermeter_back1.w = obj.entry_w2
        obj.b.obj_pers_mastermeter_back1.h = obj.entry_h
        obj.b.obj_pers_mastermeter_back2.x= 0
        obj.b.obj_pers_mastermeter_back2.y = y_offs-obj.entry_h
        obj.b.obj_pers_mastermeter_back2.w = obj.entry_w2
        obj.b.obj_pers_mastermeter_back2.frame_a = obj.frame_a_entry   
        
        obj.b.obj_pers_mastermeter.x= 0
        obj.b.obj_pers_mastermeter.y = y_offs-obj.entry_h*2
        obj.b.obj_pers_mastermeter.w = obj.entry_w2
        obj.b.obj_pers_mastermeter.h = obj.entry_h*2        
          
      end                                 
    return mastermeter_w   , obj.entry_h*2
  end
  



--[[-------------------------------------------------------------
  function Widgets_Persist_toolbar(data, obj, mouse, x_margin, widgets)  
    local toolb_w = obj.entry_h*2
    local frame_a = 0
    obj.b.obj_pers_toolb_back1 = {persist_buf = true,
                        x = x_margin - toolb_w,
                        y = obj.offs ,
                        w = toolb_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        fontsz = obj.fontsz_clock}
    obj.b.obj_pers_toolb_back2 = {persist_buf = true,
                        x = x_margin - toolb_w,
                        y = obj.offs+obj.entry_h ,
                        w = toolb_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        fontsz = obj.fontsz_clock} 
                                
    return toolb_w   
  end
  ---------------------------------------------------------------------------]]
  
  
  
  
  
  
  
  
  ------------------------------------------------------------
    function Widgets_Persist_tap(data, obj, mouse, x_margin, widgets, conf, y_offs)    -- generate position controls 
      local tap_w = 80*conf.scaling
      local tap_menu_w = 20*conf.scaling
      local tap_menu_w_vert = 20
      local frame_a = 0
      local gridwidg_xpos = gfx.w-tap_w-obj.menu_b_rect_side - x_margin
      obj.b.obj_pers_tap_bck1 = {persist_buf = true,
                          x = x_margin - tap_w,
                          y = obj.offs ,
                          w = tap_w,
                          h = obj.entry_h,
                          frame_a = obj.frame_a_head,
                          frame_rect_a = 0,
                          txt_a = obj.txt_a,
                          txt_col = obj.txt_col_entry,
                          fontsz = obj.fontsz_clock}   
      obj.b.obj_pers_tap_bck2 = {persist_buf = true,
                          x = x_margin - tap_w,
                          y = obj.offs+obj.entry_h ,
                          w = tap_w,
                          h = obj.entry_h,
                          frame_a = obj.frame_a_entry,
                          frame_rect_a = 0,
                          txt_a = obj.txt_a,
                          txt_col = obj.txt_col_entry,
                          fontsz = obj.fontsz_clock}  
                          
      local txt = 'TAP'
      if data.tap_data and data.tap_data.tap_tempo then txt = data.tap_data.tap_tempo end
      obj.b.obj_pers_tap_app = {persist_buf = true,
                          x = x_margin - tap_w,
                          y =  0,
                          w = tap_w-tap_menu_w,
                          h = obj.entry_h*2,
                          frame_a = frame_a,--,
                          state_col = state_col,
                          state = state,
                          --frame_rect_a = 1,
                          txt_a = obj.txt_a,
                          txt_col = 'white',
                          txt = txt,
                          func =        function()
                                          local taps_cnt = 16
                                                                                    
                                          -- wrap tap timestamps
                                          local TapTS = os.clock()
                                          if not lastTapTS then lastTapTS = TapTS end
                                          local diff = TapTS - lastTapTS
                                          
                                          lastTapTS = TapTS
                                          if diff > 0.1 and diff < 1.5 then
                                            if #data.tap_data.tapst < taps_cnt then 
                                              table.insert(data.tap_data.tapst,diff )
                                             else
                                              table.remove(data.tap_data.tapst,1 )
                                              table.insert(data.tap_data.tapst,diff )
                                            end
                                          end
                                          
                                          -- calc RMS                                          
                                          if #data.tap_data.tapst < 2 then return end  
                                          local diff_com = 0                                          
                                          for i = 1, #data.tap_data.tapst do diff_com = diff_com + data.tap_data.tapst[i]   end 
                                          diff = diff_com / #data.tap_data.tapst
                                          
                                          -- convert into data
                                          if diff then
                                            data.tap_data.diff = diff
                                            data.tap_data.tap_tempo = tonumber(string.format('%.3f', 60 / diff))
                                            if conf.tap_quantize == 1 then data.tap_data.tap_tempo = math_q (data.tap_data.tap_tempo) end
                                            redraw = 1
                                          end
                                          
                                        end,
                                          
                          func_R =      function()
                                          data.tap_data.tapst = {}
                                          data.tap_data.tap_tempo = data.TempoMarker_bpm
                                          redraw = 2
                                        end,                                                                          
                          func_Lshift = function() 
                                          local ex_t = data.tap_data.tap_tempo
                                          if not ex_t then ex_t = data.TempoMarker_bpm end
                                          if not ex_t then ex_t = 140 end
                                                    local retval, new_tempo = GetUserInputs(conf.scr_title, 1,'New tempo', ex_t)
                                                    if retval and tonumber(new_tempo) then
                                                      new_tempo = lim(tonumber(new_tempo), 40, 1000)
                                                      if data.TempoMarker_ID == -1 then 
                                                        CSurf_OnTempoChange( new_tempo )
                                                        UpdateTimeline()
                                                        redraw = 2  
                                                       else 
                                                        SetTempoTimeSigMarker( 0, data.TempoMarker_ID, 
                                                                                  data.TempoMarker_timepos, 
                                                                                  -1, 
                                                                                  -1, 
                                                                                  new_tempo, 
                                                                                  data.TempoMarker_timesig_num, 
                                                                                  data.TempoMarker_timesig_denom, 
                                                                                  data.TempoMarker_lineartempochange )
                                                        UpdateTimeline()
                                                      end
                                                    end
                                                  end             
                                        
                                          }
        local is_accesible = '#'
        if data.tap_data.tap_tempo then is_accesible = '' end
        obj.b.obj_pers_tapmenu = { persist_buf = true,
                          x = x_margin-tap_menu_w,
                          y = obj.offs ,
                          w = tap_menu_w,
                          h = obj.entry_h*2,
                          frame_a = frame_a,
                          txt_a = obj.txt_a,
                          txt_col = 'white',
                          txt = '->',
                          fontsz = obj.fontsz_grid_rel,
                          func =  function ()
                                    Menu(mouse, 
                                        { { str = 'Quantize tapped tempo|',
                                            state = conf.tap_quantize==1,
                                            func = function() 
                                                    conf.tap_quantize = math.abs(1-conf.tap_quantize)
                                                    ExtState_Save(conf)
                                                    redraw = 2
                                                  end
                                          },
                                          { str = is_accesible..'Apply to tempo marker',
                                            func = function() 
                                                    if data.tap_data.tap_tempo then 
                                                      if data.TempoMarker_ID == -1 then 
                                                        CSurf_OnTempoChange(  data.tap_data.tap_tempo )
                                                        UpdateTimeline()
                                                        redraw = 2  
                                                       else 
                                                        SetTempoTimeSigMarker( 0, data.TempoMarker_ID, 
                                                                                  data.TempoMarker_timepos, 
                                                                                  -1, 
                                                                                  -1, 
                                                                                  data.tap_data.tap_tempo, 
                                                                                  data.TempoMarker_timesig_num, 
                                                                                  data.TempoMarker_timesig_denom, 
                                                                                  data.TempoMarker_lineartempochange )
                                                        UpdateTimeline()
                                                      end
                                                    end
                                                  end
                                          },  
                                      { str = is_accesible..'Apply to selected item',
                                            func = function() 
                                                    if data.tap_data.tap_tempo and data.TempoMarker_bpm then 
                                                      local new_rate = data.TempoMarker_bpm / data.tap_data.tap_tempo
                                                      for i = 1 , CountSelectedMediaItems(0) do
                                                        local item = GetSelectedMediaItem(0, i-1)
                                                        local take = GetActiveTake(item)
                                                        if take then 
                                                          SetMediaItemTakeInfo_Value( take, 'D_PLAYRATE', new_rate )
                                                        end
                                                      end
                                                      UpdateArrange()
                                                    end
                                                  end
                                          },                                           
                                          {str = is_accesible..'Show delay times',
                                          func = function()
                                                    ClearConsole()
                                                    form = '%.3f'
                                                    local s_info = 'Tempo: '..data.tap_data.tap_tempo..'BPM\n'..
                                                                    
                                                                    'Frequency: '..60/data.tap_data.tap_tempo..'Hz\n\n'..
                                                                    
                                                                    ' 1/2:  '..string.format(form,        1000        * 120/data.tap_data.tap_tempo)..'ms\n'..
                                                                    ' 1/2T:  '..string.format(form,       1000 * 2/3  * 120/data.tap_data.tap_tempo)..'ms\n'..
                                                                    ' 1/2 dotted:  '..string.format(form, 1000 * 3/2  * 120/data.tap_data.tap_tempo)..'ms\n'..
                                                                    ' 1/2 cycle: '..string.format(form,   1/(           120/data.tap_data.tap_tempo))..'Hz\n\n'..
                                                                                                                     
                                                                    ' 1/4:  '..string.format(form,        1000        * 60/data.tap_data.tap_tempo)..'ms\n'..
                                                                    ' 1/4T:  '..string.format(form,       1000 * 2/3  * 60/data.tap_data.tap_tempo)..'ms\n'..
                                                                    ' 1/4 dotted:  '..string.format(form, 1000 * 3/2  * 60/data.tap_data.tap_tempo)..'ms\n'..
                                                                    ' 1/4 cycle: '..string.format(form,   1/(           60/data.tap_data.tap_tempo))..'Hz\n\n'..
                                                                    
                                                                    ' 1/8:  '..string.format(form,        1000        * 30/data.tap_data.tap_tempo)..'ms\n'..
                                                                    ' 1/8T:  '..string.format(form,       1000 * 2/3  * 30/data.tap_data.tap_tempo)..'ms\n'..
                                                                    ' 1/8 dotted:  '..string.format(form, 1000 * 3/2  * 30/data.tap_data.tap_tempo)..'ms\n'..                                                                 
                                                                    ' 1/8 cycle: '..string.format(form,   1/(           30/data.tap_data.tap_tempo))..'Hz\n\n'..
                                                                    
                                                                    ' 1/16:  '..string.format(form,        1000        * 15/data.tap_data.tap_tempo)..'ms\n'..
                                                                    ' 1/16T:  '..string.format(form,       1000 * 2/3  * 15/data.tap_data.tap_tempo)..'ms\n'..
                                                                    ' 1/16 dotted:  '..string.format(form, 1000 * 3/2  * 15/data.tap_data.tap_tempo)..'ms\n'..
                                                                    ' 1/16 cycle: '..string.format(form,   1/(           15/data.tap_data.tap_tempo))..'Hz\n\n'
                                                    
                                                    msg(s_info)
                                                  end
                                          }                                        
                                          
                                          
                                          
                                          
                                        })
                                  end}      
      if conf.dock_orientation == 1 then
        obj.b.obj_pers_tap_bck1.persist_buf = nil
        obj.b.obj_pers_tap_bck1.x= 0
        obj.b.obj_pers_tap_bck1.y = y_offs-obj.entry_h
        obj.b.obj_pers_tap_bck1.w = obj.entry_w2
        obj.b.obj_pers_tap_bck1.h = obj.entry_h
        --[[obj.b.obj_pers_tap_bck2.x= 0
        obj.b.obj_pers_tap_bck2.y = y_offs-obj.entry_h
        obj.b.obj_pers_tap_bck2.w = obj.entry_w2
        obj.b.obj_pers_tap_bck2.frame_a = obj.frame_a_entry   
        ]]
        obj.b.obj_pers_tap_app.x= 0
        obj.b.obj_pers_tap_app.y = y_offs-obj.entry_h
        obj.b.obj_pers_tap_app.w = obj.entry_w2-tap_menu_w_vert
        obj.b.obj_pers_tap_app.h = obj.entry_h        
          
        obj.b.obj_pers_tapmenu.x= gfx.w -tap_menu_w_vert
        obj.b.obj_pers_tapmenu.y = y_offs-obj.entry_h
        obj.b.obj_pers_tapmenu.w = tap_menu_w_vert
        obj.b.obj_pers_tapmenu.h = obj.entry_h        

      end                                                                              
      return tap_w
    end  





  ------------------------------------------------------------
  function Widgets_Persist_swing(data, obj, mouse, x_margin, widgets, conf, y_offs)
    local grid_widg_swingval_w = 50*conf.scaling
    if data.obj_type_int == 8 then return end
    local frame_a = 0
    local txt_a_swact =obj.txt_a
    if data.grid_swingactive_int == 0 then txt_a_swact = obj.txt_a * 0.3 end
    local back = obj.frame_a_entry
    if data.grid_swingactive_int == 0 then back = 0 end
obj.b.obj_pers_swgrid_name = { persist_buf = true,
                        x = x_margin - grid_widg_swingval_w,
                        y = obj.offs ,
                        w = grid_widg_swingval_w,
                        h = 10,
                        frame_a =0,--obj.frame_a_entry,
                        frame_rect_a = 0,
                        txt_a = txt_a_swact,
                        --txt_col = 'white',
                        txt = 'SWING',
                        --aligh_txt = 1,
                        fontsz = obj.fontsz_grid_rel,
                        func =  function ()
                                  Action(42304)
                                end}   
    if conf.dock_orientation == 1 then 
      --obj.b.obj_pers_swgrid_name.persist_buf = nil 
      obj.b.obj_pers_swgrid_name.frame_a = 0
      obj.b.obj_pers_swgrid_name.x = 0
      obj.b.obj_pers_swgrid_name.y = y_offs - obj.entry_h
      obj.b.obj_pers_swgrid_name.w = gfx.w/2
      obj.b.obj_pers_swgrid_name.h = obj.entry_h
    end                             
    obj.b.obj_pers_swgrid_back = { persist_buf = true,
                        x = x_margin - grid_widg_swingval_w,
                        y = obj.offs ,
                        w = grid_widg_swingval_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = '',
                        ignore_mouse = true} 
    if conf.dock_orientation == 1 then 
      --obj.b.obj_pers_swgrid_back.persist_buf = nil 
      obj.b.obj_pers_swgrid_back.x = 0
      obj.b.obj_pers_swgrid_back.y = y_offs - obj.entry_h
      obj.b.obj_pers_swgrid_back.w = gfx.w
      obj.b.obj_pers_swgrid_back.h = obj.entry_h
    end                         
    obj.b.obj_pers_swgrid_back2 = { persist_buf = true,
                        x = x_margin - grid_widg_swingval_w,
                        y = obj.offs + obj.entry_h,
                        w = grid_widg_swingval_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = '',
                        ignore_mouse = true}    
                                                        
    obj.b.obj_pers_swgrid_B_val = { persist_buf = true,
                        x = x_margin - grid_widg_swingval_w,
                        y = 0 ,
                        w = grid_widg_swingval_w,
                        h = obj.entry_h*2,
                        frame_a = 0,--back,--frame_a,
                        --frame_rect_a = 1,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = data.grid_swingamt_format,
                        func =        function()                                        
                                        mouse.temp_val = data.grid_swingamt
                                        redraw = 1              
                                      end,
                        func_wheel =  function()
                                        local inc
                                        if mouse.wheel_trig > 0 then 
                                          inc = 0.01 
                                         elseif mouse.wheel_trig < 0 then 
                                          inc = -0.01 
                                        end 
                                        local out_val = lim(data.grid_swingamt+inc, -1, 1)
                                        GetSetProjectGrid( project, true,  data.grid_val, data.grid_swingactive_int, out_val )
                                        redraw = 2                           
                                      end,                                              
                        func_drag =   function() 
                                        if mouse.temp_val then 
                                          local mouse_shift
                                          if data.always_use_x_axis==1 then 
                                            mouse_shift = -mouse.dx/100
                                           else
                                            mouse_shift = mouse.dy/300
                                          end  
                                          
                                          if mouse_shift then 
                                            mouse_shift = math.floor(mouse_shift*100)/100
                                            local out_val = lim(data.grid_swingamt+mouse_shift, -1, 1)
                                            GetSetProjectGrid( project, true,  data.grid_val, data.grid_swingactive_int, out_val )
                                            redraw = 1  
                                            local _, _, _, _, _, grid_swingamt_form = MPL_GetFormattedGrid()
                                            obj.b.obj_pers_swgrid_B_val.txt = grid_swingamt_form
                                          end 
                                        end
                                      end,
                        func_DC =     function()
                                        if data.MM_grid_ignoreleftdrag == 0 then
                                          if data.MM_grid_doubleclick == 0 then
                                            Main_OnCommand(40071, 0) -- open settings
                                           elseif data.MM_grid_doubleclick == 1 and data.MM_grid_default_reset_grid then
                                            GetSetProjectGrid( project, true,  data.grid_val, data.grid_swingactive_int, 0 )
                                          end
                                          redraw = 2
                                        end
                                      end,
                        func_R =     function()
                                        if data.MM_grid_rightclick == 1 then
                                          Main_OnCommand(42304, 0) -- toggle grid
                                         elseif data.MM_grid_rightclick == 0 then
                                          Main_OnCommand(40071, 0) -- open settings
                                        end
                                        redraw = 2
                                      end}
    if conf.dock_orientation == 1 then 
      obj.b.obj_pers_swgrid_B_val.persist_buf = nil 
      obj.b.obj_pers_swgrid_B_val.x = gfx.w/2
      obj.b.obj_pers_swgrid_B_val.y = y_offs - obj.entry_h
      obj.b.obj_pers_swgrid_B_val.w = gfx.w/2
      obj.b.obj_pers_swgrid_B_val.h = obj.entry_h
      obj.b.obj_pers_swgrid_B_val.frame_a = 0
    end                                      
    return grid_widg_swingval_w
  end    
  
  
  
  
  
  ------------------------------------------------------------------------  
  function Widgets_Persist_master(data, obj, mouse, x_margin, widgets, conf, y_offs)  
    local master_w = (conf.master_buf + 14)*conf.scaling
    local frame_a = 0
    obj.b.obj_pers_master_back1 = {persist_buf = true,
                        x = x_margin - master_w,
                        y = obj.offs ,
                        w = master_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        fontsz = obj.fontsz_clock}
    obj.b.obj_pers_master_back2 = {persist_buf = true,
                        x = x_margin - master_w,
                        y = obj.offs+obj.entry_h ,
                        w = master_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        fontsz = obj.fontsz_clock}  
    obj.b.obj_pers_master = { outside_buf = true,
                        x = x_margin - master_w/conf.scaling,
                        y = obj.offs ,
                        w = master_w,
                        h = obj.entry_h*2,
                        frame_a = 0,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        fontsz = obj.fontsz_clock,
                        txt = '',
                        peaks_src = data.masterdata
                        }
      if conf.dock_orientation == 1 then
        obj.b.obj_pers_master_back1.x= 0
        obj.b.obj_pers_master_back1.y = y_offs-obj.entry_h*2
        obj.b.obj_pers_master_back1.w = obj.entry_w2
        obj.b.obj_pers_master_back1.h = obj.entry_h*2
       obj.b.obj_pers_master.x= 0
        obj.b.obj_pers_master.y = y_offs-obj.entry_h*2
        obj.b.obj_pers_master.w = obj.entry_w2
        obj.b.obj_pers_master.h = obj.entry_h*2        
      end                                 
    return master_w   
  end

  -------------------------------------------------------------- 
  function Widgets_Persist_masterswapLR(data, obj, mouse, x_margin, widgets, conf, y_offs)  
    local w = 40*obj.entry_ratio
    obj.b.obj_pers_swap = {  x = x_offs,
                        y = y_offs ,
                        w = w,
                        h = obj.entry_h,
                        frame_a = frame_a,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_toolbar,
                        txt = 'Swap LR',
                        fontsz = obj.fontsz_entry,
                        state = data.master_W==-1,
                        state_col = 'green',
                        func =  function()
                          
                                end                          
                                
                                }
    return w
  end
  --------------------------------------------------------------
  function Widgets_Persist_masterchan(data, obj, mouse, x_margin, widgets, conf, y_offs)  
    local w = 60*obj.entry_ratio
    obj.b.obj_masterswapLR = {  x = x_margin-w,
                        y = y_offs ,
                        w = w,
                        h = obj.entry_h,
                        frame_a = frame_a,
                        txt_a = obj.txt_a,
                        fontsz = obj.fontsz_entry,
                        txt_col = obj.txt_col_toolbar,
                        txt = 'Swap LR',
                        state = data.master_W==-1,
                        state_col = 'red',
                        func =  function()
                                  local tr = GetMasterTrack(0)
                                  if data.master_W < 0 then reaper.SetMediaTrackInfo_Value( tr, 'D_WIDTH', 1 ) elseif data.master_W >0  then SetMediaTrackInfo_Value( tr, 'D_WIDTH', - 1) end
                                  reaper.SetMediaTrackInfo_Value( tr, 'I_PANMODE', 5 )
                                  redraw = 1                              
                                end}
    obj.b.obj_mastermono = {  x = x_margin-w,
                        y = y_offs+obj.entry_h ,
                        w = w,
                        h = obj.entry_h,
                        frame_a = frame_a,
                        txt_a = obj.txt_a,
                        fontsz = obj.fontsz_entry,
                        txt_col = obj.txt_col_toolbar,
                        txt = 'Mono',
                        state = data.master_W==0,
                        state_col = 'green',
                        func =  function()
                                  local tr = GetMasterTrack(0)
                                  if data.master_W ~= 0 then reaper.SetMediaTrackInfo_Value( tr, 'D_WIDTH', 0 ) else SetMediaTrackInfo_Value( tr, 'D_WIDTH', 1) end
                                  reaper.SetMediaTrackInfo_Value( tr, 'I_PANMODE', 5 )
                                  redraw = 1                              
                                end}                                
    return w
  end 
  --------------------------------------------------------------
  function Widgets_Persist_mchancnt(data, obj, mouse, x_margin, widgets, conf, y_offs)  
    local w = 70*conf.scaling
    local frame_a = 0
    obj.b.obj_pers_mchancnt_back1 = {persist_buf = true,
                        x = x_margin - w,
                        y = obj.offs ,
                        w = w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        fontsz = obj.fontsz_clock}
    obj.b.obj_pers_mchancnt_back2 = {persist_buf = true,
                        x = x_margin - w,
                        y = obj.offs+obj.entry_h ,
                        w = w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        fontsz = obj.fontsz_clock}  
    obj.b.obj_pers_mchancnt = { persist_buf = true,--outside_buf = true,
                        x = x_margin - w,
                        y = obj.offs ,
                        w = w,
                        h = obj.entry_h*2,
                        frame_a = 0,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        fontsz = obj.fontsz_clock,
                        txt = data.master_chanformat , -- SEE GUI_Main
                        func =  function()
                          local t = {}
                          for ch = 2, 64,2 do
                            t[#t+1] = { str = 'Set master parent channels to '..ch,
                                        func = function() 
                                                local tr =  reaper.GetMasterTrack( 0 )
                                                reaper.SetMediaTrackInfo_Value( tr, 'I_NCHAN', ch)
                                                redraw = 2
                                              end}
                                      
                          end
                          Menu(mouse, t)
                        end
                        }
    return w
  end   
  
