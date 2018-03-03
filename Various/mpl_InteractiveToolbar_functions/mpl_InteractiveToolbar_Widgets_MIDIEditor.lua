-- @description InteractiveToolbar_Widgets_MIDIEditor
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex


  -- MIDI wigets for mpl_InteractiveToolbar
  
  ---------------------------------------------------
  function Obj_UpdateMIDIEditor(data, obj, mouse, widgets)
    obj.b.obj_name = { x = obj.menu_b_rect_side + obj.offs,
                        y = obj.offs *2 +obj.entry_h,
                        w = obj.entry_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt_a = obj.txt_a,
                        txt = data.take_name,
                        fontsz = obj.fontsz_entry} 
    local x_offs = obj.menu_b_rect_side + obj.offs + obj.entry_w 
    
    
    
  --------------------------------------------------------------  
    local tp_ID = data.obj_type_int
    local widg_key = widgets.types_t[tp_ID+1] -- get key of current mapped table
    if widgets[widg_key] then    
      for i = 1, #widgets[widg_key] do
        local key = widgets[widg_key][i]
        if _G['Widgets_MIDIEditor_'..key] then
            local ret = _G['Widgets_MIDIEditor_'..key](data, obj, mouse, x_offs, widgets) 
            if ret then x_offs = x_offs + obj.offs + ret end
        end
      end  
    end
  end
  -------------------------------------------------------------- 







  --------------------------------------------------------------
  function Widgets_MIDIEditor_position(data, obj, mouse, x_offs)    -- generate position controls 
    if not data.evts or not data.evts.first_selected or not data.evts[  data.evts.first_selected  ] then return  x_offs end
    if x_offs + obj.entry_w2 > obj.persist_margin then return x_offs end 
    obj.b.obj_MEevtpos = { x = x_offs,
                        y = obj.offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'Position'} 
    obj.b.obj_MEevtpos_back = { x =  x_offs,
                        y = obj.offs *2 +obj.entry_h ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
                        
      
      local pos_str = data.evts[  data.evts.first_selected  ].pos_sec_format
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = MPL_GetTableOfCtrlValues(pos_str),
                        table_key='MEentposition_ctrl',
                        x_offs= x_offs,  
                        w_com=obj.entry_w2,--obj.entry_w2,
                        src_val=data.evts,
                        src_val_key= 'pos_sec',
                        modify_func= MPL_ModifyTimeVal,
                        app_func= Apply_MEevt_Pos,                         
                        mouse_scale= obj.mouse_scal_time,
                        onRelease_ActName = data.scr_title..': Change MIDI event properties'})                        
    return obj.entry_w2
  end  
  
  function Apply_MEevt_Pos(data, obj, t_out_values, butkey, out_str_toparse, mouse)
    if not out_str_toparse then  
      
      local sec_shift = t_out_values[ data.evts.first_selected  ] - data.evts[  data.evts.first_selected  ].pos_sec
      local ppq_shift = math.floor(MIDI_GetPPQPosFromProjTime( data.take_ptr, sec_shift+data.item_pos ))
      local pos_sec = t_out_values[ data.evts.first_selected  ]
      RawMIDI_shiftppq(data.take_ptr, data.evts, ppq_shift, mouse)
      local new_str = format_timestr_pos( pos_sec, '', data.ruleroverride ) 
      local new_str_t = MPL_GetTableOfCtrlValues(new_str)
      for i = 1, #new_str_t do
        obj.b[butkey..i].txt = new_str_t[i]
      end
     else
      -- nudge values from first item
      local out_val = parse_timestr_pos(out_str_toparse,data.ruleroverride)
      local sec_shift = out_val - t_out_values[ data.evts.first_selected  ] 
      local ppq_shift = math.floor(MIDI_GetPPQPosFromProjTime( data.take_ptr, sec_shift+data.item_pos ))
      local pos_sec = t_out_values[ data.evts.first_selected  ]
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
  function Widgets_MIDIEditor_CCval(data, obj, mouse, x_offs)    -- generate position controls 
    if not data.evts or data.evts.cnt_sel_CC == 0 then return end
    if x_offs + obj.entry_w2 > obj.persist_margin then return end 
    obj.b.obj_MEevtCC = { x = x_offs,
                        y = obj.offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'CC value'} 
    obj.b.obj_MEevtCC_back = { x =  x_offs,
                        y = obj.offs *2 +obj.entry_h ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
                        
      
      local CCval_str = data.evts[  data.evts.first_selectedCC  ].CCval
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = {CCval_str},
                        table_key='MEevtCCval_ctrl',
                        x_offs= x_offs,  
                        w_com=obj.entry_w2,--obj.entry_w2,
                        src_val=data.evts,
                        src_val_key= 'CCval',
                        modify_func= MPL_ModifyIntVal,
                        app_func= Apply_MEevt_CCval,                         
                        mouse_scale= obj.mouse_scal_intMIDICC,
                        onRelease_ActName = data.scr_title..': Change MIDI event properties',
                        modify_wholestr = true
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
      
      if t[i].selected and t[i].CClane >=0 and t[i].CClane <=127 then   
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
  function Widgets_MIDIEditor_notepitch(data, obj, mouse, x_offs)    -- generate position controls 
    if not data.evts or data.evts.cnt_sel_notes == 0 then return  x_offs end
    if x_offs + obj.entry_w2 > obj.persist_margin then return x_offs end 
    obj.b.obj_MEevtnotepitch = { x = x_offs,
                        y = obj.offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'Note pitch'} 
    obj.b.obj_MEevtnotepitch_back = { x =  x_offs,
                        y = obj.offs *2 +obj.entry_h ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
                        
      
      local pitch_str = data.evts[  data.evts.first_selectednote  ].pitch
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = {pitch_str},
                        table_key='MEevtnotepitch_ctrl',
                        x_offs= x_offs,  
                        w_com=obj.entry_w2,--obj.entry_w2,
                        src_val=data.evts,
                        src_val_key= 'pitch',
                        modify_func= MPL_ModifyIntVal,
                        app_func= Apply_MEevt_notepitch,                         
                        mouse_scale= obj.mouse_scal_intMIDICC,
                        onRelease_ActName = data.scr_title..': Change MIDI event properties',
                        modify_wholestr = true
                        })                        
    return obj.entry_w2
  end  
  function Apply_MEevt_notepitch(data, obj, t_out_values, butkey, out_str_toparse, mouse)
    if not out_str_toparse then  
      
      local shift = t_out_values[ data.evts.first_selectednote  ] - data.evts[  data.evts.first_selectednote  ].pitch
      RawMIDI_ChangeNotePitch(data.take_ptr, data.evts, shift, mouse)
      obj.b[butkey..1].txt = lim(t_out_values[ data.evts.first_selectednote  ],0,127)
      
     else
      -- nudge values from first item
      local out_val = tonumber(out_str_toparse)
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
  
  
