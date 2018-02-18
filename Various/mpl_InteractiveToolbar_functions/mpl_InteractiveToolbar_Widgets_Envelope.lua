-- @description InteractiveToolbar_Widgets_Envelope
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex


  -- Envelope wigets for mpl_InteractiveToolbar
  
  ---------------------------------------------------
  function Obj_UpdateEnvelope(data, obj, mouse, widgets)
    obj.b.obj_name = { x = obj.menu_b_rect_side + obj.offs,
                        y = obj.offs *2 +obj.entry_h,
                        w = obj.entry_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt_a = obj.txt_a,
                        txt = data.name,
                        fontsz = obj.fontsz_entry} 
    local x_offs = obj.menu_b_rect_side + obj.offs + obj.entry_w 
    
    
    
  --------------------------------------------------------------  
    local tp_ID = data.obj_type_int
    local widg_key = widgets.types_t[tp_ID+1] -- get key of current mapped table
    if widgets[widg_key] then    
      for i = 1, #widgets[widg_key] do
        local key = widgets[widg_key][i]
        if _G['Widgets_Envelope_'..key] then
            local ret = _G['Widgets_Envelope_'..key](data, obj, mouse, x_offs, widgets) 
            if ret then x_offs = x_offs + obj.offs + ret end
        end
      end  
    end
  end
  -------------------------------------------------------------- 







  --------------------------------------------------------------
  function Widgets_Envelope_position(data, obj, mouse, x_offs)    -- generate position controls 
    if not data.ep or not data.ep.sel_point_ID or not data.ep[data.ep.sel_point_ID] then return  x_offs end
    if x_offs + obj.entry_w2 > obj.persist_margin then return x_offs end 
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
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = MPL_GetTableOfCtrlValues(pos_str),
                        table_key='position_ctrl',
                        x_offs= x_offs,  
                        w_com=obj.entry_w2,--obj.entry_w2,
                        src_val=data.ep,
                        src_val_key= 'pos',
                        modify_func= MPL_ModifyTimeVal,
                        app_func= Apply_Envpoint_Pos,                         
                        mouse_scale= obj.mouse_scal_time})                         
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
      DeleteEnvelopePointRangeEx( data.env_ptr, -1, 0, math.huge )
      for i = 1, #temp_t do  InsertEnvelopePointEx( data.env_ptr, -1, temp_t[i][1], temp_t[i][2], temp_t[i][3], temp_t[i][4], temp_t[i][5], true ) end
      
      Envelope_SortPoints( data.env_ptr )
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
      DeleteEnvelopePointRangeEx( data.env_ptr, -1, 0, math.huge )
      for i = 1, #temp_t do  InsertEnvelopePointEx( data.env_ptr, -1, temp_t[i][1], temp_t[i][2], temp_t[i][3], temp_t[i][4], temp_t[i][5], true ) end
      

      Envelope_SortPoints( data.env_ptr )
      UpdateArrange()
      redraw = 2   
    end
  end  
  -------------------------------------------------------------- 
  
  
  
  

  --------------------------------------------------------------   
  function Widgets_Envelope_value(data, obj, mouse, x_offs) -- generate snap_offs controls
    if not data.ep or not data.ep.sel_point_ID or not data.ep[data.ep.sel_point_ID] then return  x_offs end
    if x_offs + obj.entry_w2 > obj.persist_margin then return x_offs end  
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
                        fontsz= obj.fontsz_entry,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
      local val_str = data.ep[data.ep.sel_point_ID].value_format
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = MPL_GetTableOfCtrlValues2(val_str),
                        table_key='val_ctrl',
                        x_offs= x_offs,  
                        w_com=obj.entry_w2,--obj.entry_w2,
                        src_val=data.ep,
                        src_val_key= 'value',
                        modify_func= MPL_ModifyFloatVal,
                        app_func= Apply_Envpoint_Val,                         
                        mouse_scale= obj.mouse_scal_vol,               -- mouse scaling
                        use_mouse_drag_xAxis= nil, -- x
                        --ignore_fields= true
                        default_val = data.env_defValue
                        })                         
    return obj.entry_w2                         
  end
  
  function Apply_Envpoint_Val(data, obj, t_out_values, butkey, out_str_toparse)
    if not out_str_toparse then    
      for i = 1, #t_out_values do
        if data.ep[i].selected then 
          SetEnvelopePointEx( data.env_ptr, -1, i-1, data.ep[i].pos, lim(t_out_values[i],data.minValue,data.maxValue), data.ep[i].shape, data.ep[i].tension, true, true )
        end
      end
      Envelope_SortPoints( data.env_ptr )
      UpdateArrange()
      local new_str = string.format("%.2f", t_out_values[ data.ep.sel_point_ID  ], '', -1 ) 
      local new_str_t = MPL_GetTableOfCtrlValues2(new_str)
      if new_str_t then 
        for i = 1, #new_str_t do
          obj.b[butkey..i].txt = new_str_t[i]
        end
        --obj.b.obj_envval_back.txt = dBFromReaperVal(t_out_values[ data.ep.sel_point_ID])..'dB'
      end
     else
      local out_val = tonumber(out_str_toparse) 
      for i = 1, #t_out_values do
        if data.ep[i].selected then 
          SetEnvelopePointEx( data.env_ptr, -1, i-1, data.ep[i].pos, lim(out_val,data.minValue,data.maxValue), data.ep[i].shape, data.ep[i].tension, true, true )
        end
      end
      Envelope_SortPoints( data.env_ptr )
      UpdateArrange()
      redraw = 2   
    end
  end  
  -------------------------------------------------------------- 






  --------------------------------------------------------------   
  function Widgets_Envelope_floatfx(data, obj, mouse, x_offs) -- generate snap_offs controls
    if data.env_parentFX == -1 then return  end
    local fxname_w = 100
    if x_offs + fxname_w > obj.persist_margin then return  end  
    local fx_name = MPL_ReduceFXname(data.env_parentFXname)
    obj.b.obj_envfloatfx = { x = x_offs,
                        y = obj.offs ,
                        w = fxname_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        ignore_mouse = true,
                        txt = ''} 
    obj.b.obj_envfloatfx_back = { x =  x_offs,
                        y = obj.offs *2 +obj.entry_h ,
                        w = fxname_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true} 
    obj.b.obj_envfloatfx_but = { x =  x_offs,
                        y = obj.offs,
                        w = fxname_w,
                        h = obj.entry_h*2,
                        frame_a = 0,
                        txt = fx_name,
                        fontsz = obj.fontsz_head,
                        func = function()
                                  TrackFX_Show( data.env_parenttr, data.env_parentFX, 3 )
                                end}                         
    return fxname_w                    
  end
