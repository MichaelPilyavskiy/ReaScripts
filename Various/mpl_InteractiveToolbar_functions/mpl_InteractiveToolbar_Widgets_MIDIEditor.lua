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
  function RawMIDI_shiftppq(take, t, ppq_shift, mouse)
    if not take or not t then return end
    
    local str = ''
    local gate
    for i = 1, #t do if t[i] then 
      local str_per_msg = string.pack("i4Bs4", t[i].offset, t[i].flags , t[i].msg1)
      local offs
      if t[i].selected and not (t[i-1] and t[i-1].selected )then 
        offs = t[i].offset+ppq_shift
       elseif t[i].selected and (t[i-1] and t[i-1].selected )then 
        offs = t[i].offset
       elseif not t[i].selected and (t[i-1] and t[i-1].selected )then 
        offs = t[i].offset-ppq_shift        
      end
      if offs then 
        str_per_msg = string.pack("i4Bs4", offs,  t[i].flags , t[i].msg1)  
      end
      
      str = str..str_per_msg
    end end
    MIDI_SetAllEvts(take, str)
    MIDI_Sort(take)
  end
  
