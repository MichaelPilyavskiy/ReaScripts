-- @description InteractiveToolbar_Widgets_MIDIEditor
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex


  -- MIDI wigets for mpl_InteractiveToolbar
  
  ---------------------------------------------------
  function Obj_UpdateMIDIEditor(data, obj, mouse, widgets, conf)
    obj.b.obj_name = { x = obj.menu_b_rect_side + obj.offs,
                        y = obj.offs *2 +obj.entry_h,
                        w = conf.GUI_contextname_w*conf.scaling,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt_a = obj.txt_a,
                        txt = data.take_name,
                        fontsz = obj.fontsz_entry} 
    local y_offs = obj.entry_h*2 + obj.offs
    local x_offs = obj.menu_b_rect_side + obj.offs + conf.GUI_contextname_w *conf.scaling
    if conf.dock_orientation == 1 then 
      x_offs = 0 
      obj.b.obj_name.w = gfx.w - obj.menu_b_rect_side
     else 
      y_offs = 0  
    end
    
    
    
  --------------------------------------------------------------  
    local tp_ID = data.obj_type_int
    local widg_key = widgets.types_t[tp_ID+1] -- get key of current mapped table
    if widgets[widg_key] then    
      for i = 1, #widgets[widg_key] do
        local key = widgets[widg_key][i]
        if _G['Widgets_MIDIEditor_'..key] then
            local retX, retY = _G['Widgets_MIDIEditor_'..key](data, obj, mouse, x_offs, widgets, conf, y_offs) 
            if conf.dock_orientation == 1 and not retY then retY = obj.entry_h elseif conf.dock_orientation == 0 and not retY then retY = 0 end
            if retX and retY then 
              if conf.dock_orientation == 0 then 
                x_offs = x_offs + obj.offs + retX 
               elseif conf.dock_orientation == 1  then
                y_offs = y_offs + obj.offs + retY 
              end
            end
        end
      end  
    end
  end
  -------------------------------------------------------------- 







  --------------------------------------------------------------
  function Widgets_MIDIEditor_position(data, obj, mouse, x_offs, widgets, conf, y_offs)    -- generate position controls 
    if not data.evts or not data.evts.first_selected or not data.evts[  data.evts.first_selected  ] then return  x_offs end
    if x_offs + obj.entry_w2 > obj.persist_margin then return x_offs end 
    obj.b.obj_MEevtpos = { x = x_offs,
                        y = y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'Position'} 
    obj.b.obj_MEevtpos_back = { x =  x_offs,
                        y = obj.entry_h+y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
      if conf.dock_orientation == 1 then
        obj.b.obj_MEevtpos.w = obj.entry_w2/2
        obj.b.obj_MEevtpos_back.x= obj.entry_w2/2
        obj.b.obj_MEevtpos_back.y = y_offs
        obj.b.obj_MEevtpos_back.w = obj.entry_w2/2
        obj.b.obj_MEevtpos_back.frame_a = obj.frame_a_head
      end                         
      
      local pos_str = data.evts[  data.evts.first_selected  ].pos_sec_format
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = MPL_GetTableOfCtrlValues(pos_str),
                        table_key='MEentposition_ctrl',
                        x_offs= obj.b.obj_MEevtpos_back.x, 
                        y_offs= obj.b.obj_MEevtpos_back.y,  
                        w_com=obj.b.obj_MEevtpos_back.w,
                        src_val=data.evts,
                        src_val_key= 'pos_sec',
                        modify_func= MPL_ModifyTimeVal,
                        app_func= Apply_MEevt_Pos,                         
                        mouse_scale= obj.mouse_scal_time2,
                        onRelease_ActName = data.scr_title..': Change MIDI event properties',
                        use_mouse_drag_xAxis = data.always_use_x_axis==1,
                        rul_format = conf.ruleroverride })                        
    return obj.entry_w2
  end  
  
  function Apply_MEevt_Pos(data, obj, t_out_values, butkey, out_str_toparse, mouse)
    if not out_str_toparse then  
      local pos_sec = t_out_values[ data.evts.first_selected  ]
      local sec_shift = pos_sec - data.evts[  data.evts.first_selected  ].pos_sec
      local ppq_shift = math.floor(MIDI_GetPPQPosFromProjTime( data.take_ptr, sec_shift+data.item_pos ))
      RawMIDI_shiftppq(data.take_ptr, data.evts, ppq_shift, mouse)
      local new_str = format_timestr_pos( pos_sec, '', data.ruleroverride ) 
      local new_str_t = MPL_GetTableOfCtrlValues(new_str)
      for i = 1, #new_str_t do
        obj.b[butkey..i].txt = new_str_t[i]
      end
     else
      -- nudge values from first item
      local out_val = parse_timestr_pos(out_str_toparse,data.ruleroverride)
      local pos_sec = t_out_values[ data.evts.first_selected  ]
      local sec_shift = out_val - pos_sec
      local ppq_shift = math.floor(MIDI_GetPPQPosFromProjTime( data.take_ptr, sec_shift+data.item_pos ))
      RawMIDI_shiftppq(data.take_ptr, data.evts, ppq_shift, mouse)

      redraw = 2   
    end
  end  
  -------------------------------------------------------------- 
  function RawMIDI_shiftppq(take, t0, ppq_shift, mouse)
    if not take or not t0 then return end    
    local str = ''
    ppq = 0
    local trig_neg_shift,trig_neg_shift_close
    local t = CopyTable(t0)
    local init = math.max(1,t[  t.first_selected  ].ppq_pos + ppq_shift) 
    for i = 1, #t do      
      local str_per_msg = string.pack("i4Bs4", t[i].offset, t[i].flags , t[i].msg1)
      
      if t[i].selected and not mouse.Ctrl then 
        if t[i].isNoteOff then 
          local val = math.max(1,t[i].ppq_pos+ppq_shift) 
          if val == 1 then
            t[i].ppq_pos = t0[i].offset
           else
            t[i].ppq_pos = val
          end
         else
          t[i].ppq_pos = math.max(1,t[i].ppq_pos+ppq_shift) 
        end        
      end
      
      local new_offs
      if i == 1 then new_offs = t[i].ppq_pos else new_offs = t[i].ppq_pos - t[i-1].ppq_pos end
      str_per_msg = string.pack("i4Bs4", new_offs,  t[i].flags , t[i].msg1)
      str = str..str_per_msg
    end
    MIDI_SetAllEvts(take, str)
    MIDI_Sort(take)
  end
  --------------------------------------------------------------
  
  
  
  
  
  
  
  --------------------------------------------------------------
  function Widgets_MIDIEditor_CCval(data, obj, mouse, x_offs, widgets, conf, y_offs)    -- generate position controls 
    if not data.evts or data.evts.cnt_sel_CC == 0 then return end
    if x_offs + obj.entry_w2 > obj.persist_margin then return end 
    obj.b.obj_MEevtCC = { x = x_offs,
                        y = y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'CC value'} 
    obj.b.obj_MEevtCC_back = { x =  x_offs,
                        y = y_offs +obj.entry_h ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
      if conf.dock_orientation == 1 then
        obj.b.obj_MEevtCC.w = obj.entry_w2/2
        obj.b.obj_MEevtCC_back.x= obj.entry_w2/2
        obj.b.obj_MEevtCC_back.y = y_offs
        obj.b.obj_MEevtCC_back.w = obj.entry_w2/2
        obj.b.obj_MEevtCC_back.frame_a = obj.frame_a_head
      end                         
      
      local CCval_str = data.evts[  data.evts.first_selectedCC  ].CCval
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = {CCval_str},
                        table_key='MEevtCCval_ctrl',
                        x_offs= obj.b.obj_MEevtCC_back.x,  
                        y_offs= obj.b.obj_MEevtCC_back.y,  
                        w_com=obj.b.obj_MEevtCC_back.w,
                        src_val=data.evts,
                        src_val_key= 'CCval',
                        modify_func= MPL_ModifyIntVal,
                        app_func= Apply_MEevt_CCval,                         
                        mouse_scale= obj.mouse_scal_intMIDICC,
                        onRelease_ActName = data.scr_title..': Change MIDI event properties',
                        modify_wholestr = true,
                        use_mouse_drag_xAxis = data.always_use_x_axis==1,
                        })                        
    return obj.entry_w2
  end  
  function Apply_MEevt_CCval(data, obj, t_out_values, butkey, out_str_toparse, mouse)
    if not out_str_toparse then  
      
      local shift = t_out_values[ data.evts.first_selectedCC  ] - data.evts[  data.evts.first_selectedCC  ].CCval
      RawMIDI_ChangeCC(data.take_ptr, data.evts, shift, mouse)
      obj.b[butkey..1].txt = lim(t_out_values[ data.evts.first_selectedCC  ],0,127)
      
     else
      -- nudge values from first item
      local out_val = tonumber(out_str_toparse)
      if out_val then
        local shift =out_val - data.evts[  data.evts.first_selectedCC  ].CCval
        RawMIDI_ChangeCC(data.take_ptr, data.evts, shift, mouse)
        redraw = 2 
      end  
    end
  end  
  function RawMIDI_ChangeCC(take, t, CCshift, mouse)
    if not take or not t then return end
    
    local str = ''
    local out_val0
    if mouse.Ctrl then out_val0 = lim(t[  t.first_selectedCC  ].CCval+CCshift,0,127) end
    for i = 1, #t do      
      local str_per_msg = string.pack("i4Bs4", t[i].offset, t[i].flags , t[i].msg1)
      
      if t[i].selected and t[i].CClane and t[i].CClane >=0 and t[i].CClane <=127 then   
        local out_val = lim(t[i].CCval + CCshift,0,127)
        if out_val0 then out_val = out_val0 end
        str_per_msg = string.pack("i4BI4BBB", t[i].offset, t[i].flags, 3, 
                                  0xB0 | t[i].chan-1, t[i].CClane, out_val)
                                  
      end
      str = str..str_per_msg
    end
    MIDI_SetAllEvts(take, str)
    MIDI_Sort(take)
  end  
  --------------------------------------------------------------
  
  
  
  
  --------------------------------------------------------------
  function Widgets_MIDIEditor_notepitch(data, obj, mouse, x_offs, widgets, conf, y_offs)    -- generate position controls 
    if not data.evts or data.evts.cnt_sel_notes == 0 then return   end
    if x_offs + obj.entry_w2 > obj.persist_margin then return  end 
    obj.b.obj_MEevtnotepitch = { x = x_offs,
                        y = y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'NotePitch'} 
    obj.b.obj_MEevtnotepitch_back = { x =  x_offs,
                        y =y_offs +obj.entry_h ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        fontsz = obj.fontsz_entry,
                        ignore_mouse = true}  
 if conf.dock_orientation == 1 then
   obj.b.obj_MEevtnotepitch.w = obj.entry_w2/2
   obj.b.obj_MEevtnotepitch_back.x= obj.entry_w2/2
   obj.b.obj_MEevtnotepitch_back.y = y_offs
   obj.b.obj_MEevtnotepitch_back.w = obj.entry_w2/2
   obj.b.obj_MEevtnotepitch_back.frame_a = obj.frame_a_head
 end                        
      
      local pitch_str = data.evts[  data.evts.first_selectednote  ].pitch_format
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = {pitch_str},
                        table_key='MEevtnotepitch_ctrl',
                        x_offs=  obj.b.obj_MEevtnotepitch_back.x,
                        y_offs=  obj.b.obj_MEevtnotepitch_back.y,  
                        w_com= obj.b.obj_MEevtnotepitch_back.w,
                        src_val=data.evts,
                        src_val_key= 'pitch',
                        modify_func= MPL_ModifyIntVal,
                        app_func= Apply_MEevt_notepitch,                         
                        mouse_scale= obj.mouse_scal_intMIDICC,
                        onRelease_ActName = data.scr_title..': Change MIDI event properties',
                        modify_wholestr = true,
                        use_mouse_drag_xAxis = data.always_use_x_axis==1,
                        --dont_draw_val = true
                        })                        
    return obj.entry_w2
  end  
  function Apply_MEevt_notepitch(data, obj, t_out_values, butkey, out_str_toparse, mouse)
    if not out_str_toparse then  
      
      local shift = t_out_values[ data.evts.first_selectednote  ] - data.evts[  data.evts.first_selectednote  ].pitch
      RawMIDI_ChangeNotePitch(data.take_ptr, data.evts, shift, mouse)
      obj.b[butkey..1].txt = MPL_FormatMIDIPitch(data, lim(t_out_values[ data.evts.first_selectednote  ],0,127))
      
     else
      -- nudge values from first item
      local out_val = MPL_ParseMIDIPitch(data, out_str_toparse)-- tonumber(out_str_toparse)
      if out_val then
        local shift =out_val - data.evts[  data.evts.first_selectednote  ].pitch
        RawMIDI_ChangeNotePitch(data.take_ptr, data.evts, shift, mouse)
        redraw = 2 
      end  
    end
  end  
  function RawMIDI_ChangeNotePitch(take, t, pitch_change, mouse)
    if not take or not t then return end
    
    local str = ''
    local out_val0
    if mouse.Ctrl then out_val0 = lim(t[  t.first_selectednote  ].pitch+pitch_change,0,127) end
    for i = 1, #t do      
      local str_per_msg = string.pack("i4Bs4", t[i].offset, t[i].flags , t[i].msg1)
      
      if t[i].selected and (t[i].isNoteOn or t[i].isNoteOff)  then   
        local out_val = lim(t[i].pitch + pitch_change,0,127)
        if out_val0 then out_val = out_val0 end
        local msgtype, int
        if t[i].isNoteOn then msgtype = 0x90 int = 1 else msgtype = 0x80 int = 0 end
        str_per_msg = string.pack("i4Bi4BBB", t[i].offset, t[i].flags, 3, 
                                  msgtype| (t[i].chan-1),out_val, t[i].vel )
                                  
                                           
      end
      
      str = str..str_per_msg
    end
    MIDI_SetAllEvts(take, str)
    MIDI_Sort(take)
  end  
  --------------------------------------------------------------  
  
  
  
  
  
  
  --------------------------------------------------------------
  function Widgets_MIDIEditor_notevel(data, obj, mouse, x_offs, widgets, conf, y_offs)    -- generate position controls 
    if not data.evts or data.evts.cnt_sel_notes == 0 then return   end
    if x_offs + obj.entry_w2 > obj.persist_margin then return  end 
    obj.b.obj_MEevtnotevel = { x = x_offs,
                        y = y_offs,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'NoteVelocity'} 
    obj.b.obj_MEevtnotevel_back = { x =  x_offs,
                        y = y_offs +obj.entry_h ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
      if conf.dock_orientation == 1 then
        obj.b.obj_MEevtnotevel.w = obj.entry_w2/2
        obj.b.obj_MEevtnotevel_back.x= obj.entry_w2/2
        obj.b.obj_MEevtnotevel_back.y = y_offs
        obj.b.obj_MEevtnotevel_back.w = obj.entry_w2/2
        obj.b.obj_MEevtnotevel_back.frame_a = obj.frame_a_head
      end                         
      
      local vel_str = data.evts[  data.evts.first_selectednote  ].vel
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = {vel_str},
                        table_key='MEevtnotevel_ctrl',
                        x_offs= obj.b.obj_MEevtnotevel_back.x,
                        y_offs= obj.b.obj_MEevtnotevel_back.y,  
                        w_com=obj.b.obj_MEevtnotevel_back.w,
                        src_val=data.evts,
                        src_val_key= 'vel',
                        modify_func= MPL_ModifyIntVal,
                        app_func= Apply_MEevt_notevel,                         
                        mouse_scale= obj.mouse_scal_intMIDICC,
                        onRelease_ActName = data.scr_title..': Change MIDI event properties',
                        modify_wholestr = true,
                        use_mouse_drag_xAxis = data.always_use_x_axis==1,
                        })                        
    return obj.entry_w2
  end  
  function Apply_MEevt_notevel(data, obj, t_out_values, butkey, out_str_toparse, mouse)
    if not out_str_toparse then  
      
      local shift = t_out_values[ data.evts.first_selectednote  ] - data.evts[  data.evts.first_selectednote  ].vel
      RawMIDI_ChangeNoteVel(data.take_ptr, data.evts, shift, mouse)
      obj.b[butkey..1].txt = lim(t_out_values[ data.evts.first_selectednote  ],0,127)
      
     else
      -- nudge values from first item
      local out_val = tonumber(out_str_toparse)
      if out_val then
        local shift =out_val - data.evts[  data.evts.first_selectednote  ].vel
        RawMIDI_ChangeNoteVel(data.take_ptr, data.evts, shift, mouse)
        redraw = 2 
      end  
    end
  end  
  function RawMIDI_ChangeNoteVel(take, t, vel_change, mouse)
    if not take or not t then return end
    
    local str = ''
    local out_val0
    if mouse.Ctrl then out_val0 = lim(t[  t.first_selectednote  ].pitch+vel_change,0,127) end
    for i = 1, #t do      
      local str_per_msg = string.pack("i4Bs4", t[i].offset, t[i].flags , t[i].msg1)
      
      if t[i].selected and t[i].isNoteOn  then   
        local out_val = lim(t[i].vel + vel_change,0,127)
        if out_val0 then out_val = out_val0 end
        str_per_msg = string.pack("i4Bi4BBB", t[i].offset, t[i].flags, 3, 
                                  0x90| (t[i].chan-1), t[i].pitch, out_val )
                                  
                                           
      end
      
      str = str..str_per_msg
    end
    MIDI_SetAllEvts(take, str)
    MIDI_Sort(take)
  end  
  --------------------------------------------------------------  



  --------------------------------------------------------------
  function Widgets_MIDIEditor_midichan(data, obj, mouse, x_offs, widgets, conf, y_offs)    -- generate position controls 
    if not data.evts or not data.evts.first_selected or not data.evts[data.evts.first_selected]  then return  x_offs end
    if x_offs + obj.entry_w2 > obj.persist_margin then return x_offs end 
    obj.b.obj_MEevtchan = { x = x_offs,
                        y = y_offs,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'Channel'} 
    obj.b.obj_MEevtchan_back = { x =  x_offs,
                        y = y_offs +obj.entry_h ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
      if conf.dock_orientation == 1 then
        obj.b.obj_MEevtchan.w = obj.entry_w2/2
        obj.b.obj_MEevtchan_back.x= obj.entry_w2/2
        obj.b.obj_MEevtchan_back.y = y_offs
        obj.b.obj_MEevtchan_back.w = obj.entry_w2/2
        obj.b.obj_MEevtchan_back.frame_a = obj.frame_a_head
      end                         
      
      local chan_str = data.evts[  data.evts.first_selected  ].chan
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = {chan_str},
                        table_key='MEevtchan_ctrl',
                        x_offs= obj.b.obj_MEevtchan_back.x,
                        y_offs= obj.b.obj_MEevtchan_back.y,  
                        w_com=obj.b.obj_MEevtchan_back.w,
                        src_val=data.evts,
                        src_val_key= 'chan',
                        modify_func= MPL_ModifyIntVal,
                        app_func= Apply_MEevt_chan,                         
                        mouse_scale= obj.mouse_scal_intMIDIchan,
                        onRelease_ActName = data.scr_title..': Change MIDI event properties',
                        modify_wholestr = true,
                        use_mouse_drag_xAxis = data.always_use_x_axis==1,
                        })                        
    return obj.entry_w2
  end  
  function Apply_MEevt_chan(data, obj, t_out_values, butkey, out_str_toparse, mouse)
    if not out_str_toparse then  
      local chan_out = lim(t_out_values[ data.evts.first_selected  ],1,16)
      RawMIDI_ChangeMIDIchan(data.take_ptr, data.evts, chan_out)
      obj.b[butkey..1].txt = chan_out
      
     else
      -- nudge values from first item
      local chan_out = tonumber(out_str_toparse)
      if chan_out then
        RawMIDI_ChangeMIDIchan(data.take_ptr, data.evts, chan_out)
        redraw = 2 
      end  
    end
  end  
  function RawMIDI_ChangeMIDIchan(take, t, chan_out)
    if not take or not t then return end
    local chan_out = lim(chan_out, 0, 15)
    local str = ''
    for i = 1, #t-1 do      
      local str_per_msg = string.pack("i4Bs4", t[i].offset, t[i].flags , t[i].msg1)
      if t[i].selected then 
        
          str_per_msg = string.pack("i4Bi4BBB", t[i].offset, t[i].flags, 3, 
                                  t[i].msg1:byte(1) - t[i].chan + chan_out, 
                                  t[i].msg1:byte(2), 
                                  t[i].msg1:byte(3)  )
        
                                  
                                           
      end
      
      str = str..str_per_msg
    end
    str = str..string.pack("i4Bs4", t[#t].offset, t[#t].flags , t[#t].msg1)
    MIDI_SetAllEvts(take, str)
    MIDI_Sort(take)
  end  
  --------------------------------------------------------------    
  






  --------------------------------------------------------------
  function Widgets_MIDIEditor_notelen(data, obj, mouse, x_offs, widgets, conf, y_offs)    -- generate position controls 
    if not data.evts or data.evts.cnt_sel_notes == 0 then return   end
    if x_offs + obj.entry_w2 > obj.persist_margin then return x_offs end 
    obj.b.obj_MEevtnotelen = { x = x_offs,
                        y = y_offs,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'NoteLength'} 
    obj.b.obj_MEevtnotelen_back = { x =  x_offs,
                        y = y_offs +obj.entry_h ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
      if conf.dock_orientation == 1 then
        obj.b.obj_MEevtnotelen.w = obj.entry_w2/2
        obj.b.obj_MEevtnotelen_back.x= obj.entry_w2/2
        obj.b.obj_MEevtnotelen_back.y = y_offs
        obj.b.obj_MEevtnotelen_back.w = obj.entry_w2/2
        obj.b.obj_MEevtnotelen_back.frame_a = obj.frame_a_head
      end                        
      
      local notelen_str = data.evts[  data.evts.first_selectednote  ].notelen_format
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = MPL_GetTableOfCtrlValues(notelen_str),
                        table_key='MEnotelen_ctrl',
                        x_offs= obj.b.obj_MEevtnotelen_back.x,
                        y_offs= obj.b.obj_MEevtnotelen_back.y,   
                        w_com= obj.b.obj_MEevtnotelen_back.w,
                        src_val=data.evts,
                        src_val_key= 'notelen_sec',
                        modify_func= MPL_ModifyTimeVal,
                        app_func= Apply_MEevt_Len,                         
                        mouse_scale= obj.mouse_scal_time2,
                        onRelease_ActName = data.scr_title..': Change MIDI event properties',
                        use_mouse_drag_xAxis = data.always_use_x_axis==1,
                        rul_format = conf.ruleroverride })
    return obj.entry_w2
  end  
  
  function Apply_MEevt_Len(data, obj, t_out_values, butkey, out_str_toparse, mouse)
    if not out_str_toparse then  
      local notelen_sec = t_out_values[ data.evts.first_selectednote  ]
      local sec_adjust = notelen_sec - data.evts[  data.evts.first_selectednote  ].notelen_sec      
      local ppq_newend = MIDI_GetPPQPosFromProjTime( data.take_ptr, 
                                                    sec_adjust 
                                                    + data.evts[  data.evts.first_selectednote  ].pos_sec
                                                    + data.evts[  data.evts.first_selectednote  ].notelen_sec
                                                    ) 
      local ppq_shift = math.floor(data.evts[  data.evts.first_selectednote  ].ppq_pos + data.evts[  data.evts.first_selectednote  ].notelen - ppq_newend)
      
      RawMIDI_adjustendppq(data.take_ptr, data.evts, ppq_shift, mouse)
      local new_str = format_timestr_len(notelen_sec+sec_adjust, '', 0, data.ruleroverride ) 
      local new_str_t = MPL_GetTableOfCtrlValues(new_str)
      for i = 1, #new_str_t do
        obj.b[butkey..i].txt = new_str_t[i]
      end
     else
      -- nudge values from first item
      local notelen_sec =  reaper.parse_timestr_len( out_str_toparse, 0, data.ruleroverride )
      local sec_adjust = notelen_sec - data.evts[  data.evts.first_selectednote  ].notelen_sec      
      local ppq_newend = MIDI_GetPPQPosFromProjTime( data.take_ptr, 
                                                    sec_adjust 
                                                    + data.evts[  data.evts.first_selectednote  ].pos_sec
                                                    + data.evts[  data.evts.first_selectednote  ].notelen_sec
                                                    ) 
      local ppq_shift = math.floor(data.evts[  data.evts.first_selectednote  ].ppq_pos + data.evts[  data.evts.first_selectednote  ].notelen - ppq_newend)
      
      RawMIDI_adjustendppq(data.take_ptr, data.evts, ppq_shift, mouse)    
      redraw = 2   
    end
  end  
  -------------------------------------------------------------- 
  function RawMIDI_adjustendppq(take, t0, ppq_shift, mouse)
    if not take or not t0 or ppq_shift == 0 then return end    
    local str = ''
    local t = CopyTable(t0)
    local ppq_shift0 = 0
    for i = 1, #t do      
      local str_per_msg = string.pack("i4Bs4", t[i].offset, t[i].flags , t[i].msg1)
      
      if t[i].selected and t[i].isNoteOff then 
        ppq_shift0 = ppq_shift
        t[i].offset = t[i].offset - ppq_shift0 
       else
          t[i].offset = t[i].offset + ppq_shift0 
          ppq_shift0 = 0   
      end
      
      str_per_msg = string.pack("i4Bs4", t[i].offset,  t[i].flags , t[i].msg1)
      str = str..str_per_msg
    end
    MIDI_SetAllEvts(take, str)
    MIDI_Sort(take)
  end
  --------------------------------------------------------------
