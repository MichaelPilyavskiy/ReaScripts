-- @description InfoTool_Widgets_Envelope
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex


  -- Envelope wigets for mpl_InfoTool
  
  ---------------------------------------------------
  function Obj_UpdateEnvelope(data, obj, mouse, widgets)
    obj.b.obj_name = { x = obj.offs,
                        y = obj.offs *2 +obj.entry_h,
                        w = obj.entry_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt_a = obj.txt_a,
                        txt = data.name,
                        fontsz = obj.fontsz_entry} 
    local x_offs = obj.offs + obj.entry_w 
    
    
    
  --------------------------------------------------------------  
    local tp_ID = data.obj_type_int
    local widg_key = widgets.types_t[tp_ID+1] -- get key of current mapped table
    if widgets[widg_key] then      
      for i = 1, #widgets[widg_key] do
        local key = widgets[widg_key][i]
        if _G['Widgets_Envelope_'..key] then
            local ret = _G['Widgets_Envelope_'..key](data, obj, mouse, x_offs) 
            if ret then x_offs = x_offs + obj.offs + ret end
        end
      end  
    end
  end
  -------------------------------------------------------------- 







  --------------------------------------------------------------
  function Widgets_Envelope_position(data, obj, mouse, x_offs)    -- generate position controls 
    obj.b.obj_envpos = { x = x_offs,
                        y = obj.offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'Position'} 
    obj.b.obj_envpos_back = { x =  x_offs,
                        y = obj.offs *2 +obj.entry_h ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
                        
                        
      local pos_str = data.ep[data.ep.sel_point_ID].pos_format
      Obj_GenerateCtrl( data,obj, mouse,
                         MPL_GetTableOfCtrlValues(pos_str), 
                        'position_ctrl',
                         x_offs, obj.entry_w2,
                         data.ep,
                         'pos',
                         MPL_ModifyTimeVal,
                         t_out_values,
                         Apply_Envpoint_Pos,
                         obj.mouse_scal_time)
    return obj.entry_w2
  end  
  function Apply_Envpoint_Pos(data, obj, t_out_values, butkey, out_str_toparse)
    if not out_str_toparse then  
      
      local temp_t = {}
      for i = 1, #t_out_values do
        if data.ep[i].selected then
          temp_t[i] = {math.max(0,t_out_values[i] ), data.ep[i].value, data.ep[i].shape, data.ep[i].tension,  data.ep[i].selected}
         else 
          temp_t[i] = {data.ep[i].pos, data.ep[i].value, data.ep[i].shape, data.ep[i].tension,  data.ep[i].selected}
        end
      end
      DeleteEnvelopePointRangeEx( data.ep.env_ptr, -1, 0, math.huge )
      for i = 1, #temp_t do  InsertEnvelopePointEx( data.ep.env_ptr, -1, temp_t[i][1], temp_t[i][2], temp_t[i][3], temp_t[i][4], temp_t[i][5], true ) end
      
      Envelope_SortPoints( data.ep.env_ptr )
      UpdateArrange()
      local new_str = format_timestr_pos( t_out_values[ data.ep.sel_point_ID  ], '', -1 ) 
      local new_str_t = MPL_GetTableOfCtrlValues(new_str)
      for i = 1, #new_str_t do
        obj.b[butkey..i].txt = new_str_t[i]
      end
     else
      -- nudge values from first item
      local out_val = parse_timestr_pos(out_str_toparse,-1)
      diff = data.ep[data.ep.sel_point_ID].pos -out_val
      
      local temp_t = {}
      for i = 1, #t_out_values do
        if data.ep[i].selected then
          temp_t[i] = {math.max(0,data.ep[i].pos - diff), data.ep[i].value, data.ep[i].shape, data.ep[i].tension,  data.ep[i].selected}
         else 
          temp_t[i] = {data.ep[i].pos, data.ep[i].value, data.ep[i].shape, data.ep[i].tension,  data.ep[i].selected}
        end
      end
      DeleteEnvelopePointRangeEx( data.ep.env_ptr, -1, 0, math.huge )
      for i = 1, #temp_t do  InsertEnvelopePointEx( data.ep.env_ptr, -1, temp_t[i][1], temp_t[i][2], temp_t[i][3], temp_t[i][4], temp_t[i][5], true ) end
      

      Envelope_SortPoints( data.ep.env_ptr )
      UpdateArrange()
      redraw = 2   
    end
  end  
  -------------------------------------------------------------- 
  
  
  
  

  --------------------------------------------------------------   
  function Widgets_Envelope_value(data, obj, mouse, x_offs) -- generate snap_offs controls  
    obj.b.obj_envval = { x = x_offs,
                        y = obj.offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'Value'} 
    obj.b.obj_envval_back = { x =  x_offs,
                        y = obj.offs *2 +obj.entry_h ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
      local val_str = data.ep[data.ep.sel_point_ID].value_format
      Obj_GenerateCtrl( data,obj,  mouse,
                        MPL_GetTableOfCtrlValues2(val_str),
                        'val_ctrl',
                         x_offs,  obj.entry_w2,
                         data.ep,
                         'value',
                         MPL_ModifyFloatVal,
                         t_out_values,
                         Apply_Envpoint_Val,                         
                         obj.mouse_scal_vol)               -- mouse scaling
    return obj.entry_w2                         
  end
  
  function Apply_Envpoint_Val(data, obj, t_out_values, butkey, out_str_toparse)
    if not out_str_toparse then    
      for i = 1, #t_out_values do
        if data.ep[i].selected then 
          SetEnvelopePointEx( data.ep.env_ptr, -1, i-1, data.ep[i].pos, lim(t_out_values[i],data.minValue,data.maxValue), data.ep[i].shape, data.ep[i].tension, true, true )
        end
      end
      Envelope_SortPoints( data.ep.env_ptr )
      UpdateArrange()
      local new_str = string.format("%.2f", t_out_values[ data.ep.sel_point_ID  ], '', -1 ) 
      local new_str_t = MPL_GetTableOfCtrlValues2(new_str)
      if new_str_t then 
        for i = 1, #new_str_t do
          obj.b[butkey..i].txt = new_str_t[i]
        end
      end
     else
      local out_val = tonumber(out_str_toparse) 
      for i = 1, #t_out_values do
        if data.ep[i].selected then 
          SetEnvelopePointEx( data.ep.env_ptr, -1, i-1, data.ep[i].pos, lim(out_val,data.minValue,data.maxValue), data.ep[i].shape, data.ep[i].tension, true, true )
        end
      end
      Envelope_SortPoints( data.ep.env_ptr )
      UpdateArrange()
      redraw = 2   
    end
  end  
  -------------------------------------------------------------- 







  --------------------------------------------------------------
