-- @description InteractiveToolbar_Widgets_Envelope
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex


  -- Envelope wigets for mpl_InteractiveToolbar
  
  ---------------------------------------------------
  function Obj_UpdateEnvelope(data, obj, mouse, widgets, conf)
    obj.b.obj_name = { x = obj.menu_b_rect_side + obj.offs,
                        y = obj.offs *2 +obj.entry_h,
                        w = conf.GUI_contextname_w*conf.scaling,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt_a = obj.txt_a,
                        txt = data.name,
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
        if _G['Widgets_Envelope_'..key] then
            local retX, retY = _G['Widgets_Envelope_'..key](data, obj, mouse, x_offs, widgets, conf, y_offs)
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
                            
  function Widgets_Envelope_position(data, obj, mouse, x_offs, widgets, conf, y_offs)    -- generate position controls 
    if not data.ep or not data.ep.sel_point_ID or not data.ep[data.ep.sel_point_ID] then return  0 end
    if x_offs + obj.entry_w2 > obj.persist_margin then return x_offs end 
    obj.b.obj_envpos = { x = x_offs,
                        y = y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'Position'} 
    obj.b.obj_envpos_back = { x =  x_offs,
                        y = obj.entry_h+y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
      if conf.dock_orientation == 1 then
        obj.b.obj_envpos.w = obj.entry_w2/2
        obj.b.obj_envpos_back.x= obj.entry_w2/2
        obj.b.obj_envpos_back.y = y_offs
        obj.b.obj_envpos_back.w = obj.entry_w2/2
        obj.b.obj_envpos_back.frame_a = obj.frame_a_head
      end                         
      
      local pos_str = data.ep[data.ep.sel_point_ID].pos_format
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = MPL_GetTableOfCtrlValues(pos_str),
                        table_key='position_ctrl',
                        x_offs= obj.b.obj_envpos_back.x,  
                        y_offs= obj.b.obj_envpos_back.y,  
                        w_com=obj.b.obj_envpos_back.w,
                        src_val=data.ep,
                        src_val_key= 'pos',
                        modify_func= MPL_ModifyTimeVal,
                        app_func= Apply_Envpoint_Pos,                         
                        mouse_scale= obj.mouse_scal_time,
                        onRelease_ActName = data.scr_title..': Change point properties',
                        use_mouse_drag_xAxis = data.always_use_x_axis==1})                         
    return obj.entry_w2
  end  
  function Apply_Envpoint_Pos(data, obj, t_out_values, butkey, out_str_toparse, mouse)
    if not out_str_toparse then  
      
      local temp_t = {}
      for i = 1, #t_out_values do
        if data.ep[i].selected then
          temp_t[i] = {t_out_values[i], data.ep[i].value0, data.ep[i].shape, data.ep[i].tension,  data.ep[i].selected}
         else 
          temp_t[i] = {data.ep[i].pos, data.ep[i].value0, data.ep[i].shape, data.ep[i].tension,  data.ep[i].selected}
        end
      end
      DeleteEnvelopePointRangeEx( data.env_ptr, -1, 0, math.huge )
      for i = 1, #temp_t do  
        InsertEnvelopePointEx( data.env_ptr, -1, temp_t[i][1], temp_t[i][2], temp_t[i][3], temp_t[i][4], temp_t[i][5], true ) 
      end
      
      Envelope_SortPoints( data.env_ptr )
      UpdateArrange()
      UpdateTimeline()
      local new_str = format_timestr_pos( t_out_values[ data.ep.sel_point_ID  ], '', data.ruleroverride ) 
      local new_str_t = MPL_GetTableOfCtrlValues(new_str)
      for i = 1, #new_str_t do
        obj.b[butkey..i].txt = new_str_t[i]
      end
     else
      -- nudge values from first item
      local out_val = parse_timestr_pos(out_str_toparse,data.ruleroverride)
      diff = data.ep[data.ep.sel_point_ID].pos -out_val
      
      local temp_t = {}
      for i = 1, #t_out_values do
        if data.ep[i].selected then
          temp_t[i] = {math.max(0,data.ep[i].pos - diff), data.ep[i].value0, data.ep[i].shape, data.ep[i].tension,  data.ep[i].selected}
         else 
          temp_t[i] = {data.ep[i].pos, data.ep[i].value0, data.ep[i].shape, data.ep[i].tension,  data.ep[i].selected}
        end
      end
      DeleteEnvelopePointRangeEx( data.env_ptr, -1, 0, math.huge )
      for i = 1, #temp_t do  InsertEnvelopePointEx( data.env_ptr, -1, temp_t[i][1], temp_t[i][2], temp_t[i][3], temp_t[i][4], temp_t[i][5], true ) end
      

      Envelope_SortPoints( data.env_ptr )
      UpdateArrange()
      UpdateTimeline()
      redraw = 2   
    end
  end  
  -------------------------------------------------------------- 
  
  
  
  

  --------------------------------------------------------------   
  function Widgets_Envelope_value(data, obj, mouse, x_offs, widgets, conf, y_offs) -- generate snap_offs controls
    if not data.ep or not data.ep.sel_point_ID or not data.ep[data.ep.sel_point_ID] then return 0 end
    if x_offs + obj.entry_w2 > obj.persist_margin then return x_offs end  
    obj.b.obj_envval = { x = x_offs,
                        y = y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'Value'} 
    obj.b.obj_envval_back = { x =  x_offs,
                        y = obj.entry_h+y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        fontsz= obj.fontsz_entry,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
                        
      if conf.dock_orientation == 1 then
        obj.b.obj_envval.w = obj.entry_w2/2
        obj.b.obj_envval_back.x= obj.entry_w2/2
        obj.b.obj_envval_back.y = y_offs
        obj.b.obj_envval_back.w = obj.entry_w2/2
        obj.b.obj_envval_back.frame_a = obj.frame_a_head
      end                         
      local val_str = data.ep[data.ep.sel_point_ID].value_format
     -- local modify_wholestr = data.env_isvolume
     Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = {val_str},
                        table_key='val_ctrl',
                        x_offs= obj.b.obj_envval_back.x,  
                        y_offs= obj.b.obj_envval_back.y,  
                        w_com=obj.b.obj_envval_back.w,
                        src_val=data.ep,
                        src_val_key= 'value',
                        modify_func= MPL_ModifyFloatVal,
                        modify_wholestr=true,
                        app_func= Apply_Envpoint_Val,                         
                        mouse_scale= obj.mouse_scal_float,               -- mouse scaling
                        use_mouse_drag_xAxis = data.always_use_x_axis==1, -- x
                        --ignore_fields= true
                        default_val = data.env_defValue,
                        onRelease_ActName = data.scr_title..': Change point properties'
                        })  
    return obj.entry_w2                         
  end
  
  function Apply_Envpoint_Val(data, obj, t_out_values, butkey, out_str_toparse, mouse)
    local minValue= data.minValue--0
    local maxValue = data.maxValue--1
    --if data.env_isvolume then maxValue = 1000 end
    local scaling_mode = GetEnvelopeScalingMode( data.env_ptr )
    if not out_str_toparse then
      for i = 1, #t_out_values do
        local outval
        if mouse.Ctrl then outval = lim(t_out_values[1],minValue,maxValue) else outval = lim(t_out_values[i],minValue,maxValue) end
        if data.ep[i].selected then 
          --msg(ScaleToEnvelopeMode( scaling_mode, outval))
          SetEnvelopePointEx( data.env_ptr, -1, i-1, data.ep[i].pos, ScaleToEnvelopeMode( scaling_mode, outval), data.ep[i].shape, data.ep[i].tension, true, true )
        end
      end
      Envelope_SortPoints( data.env_ptr )
      local new_str
      if not data.is_tr_env then  
        new_str = string.format("%.2f", t_out_values[ data.ep.sel_point_ID  ]) 
       else
        local v = t_out_values[ data.ep.sel_point_ID  ]
        --v = ScaleToEnvelopeMode( scaling_mode, v )
        v = WDL_VAL2DB(v)
        new_str =  string.format("%.2f", v )
      end
      obj.b[butkey..1].txt = new_str
     else --input str
      local out_val
      out_val = tonumber(out_str_toparse) 
      if not out_val then return end
      if data.is_tr_env then 
        out_val = WDL_DB2VAL( out_val ) 
        out_val = ScaleToEnvelopeMode( scaling_mode,out_val)
       else 
        out_val = ScaleToEnvelopeMode( scaling_mode, out_val)
      end
      for i = 1, #t_out_values do
        if data.ep[i].selected then 
          SetEnvelopePointEx( data.env_ptr, -1, i-1, data.ep[i].pos, out_val,
                              data.ep[i].shape, data.ep[i].tension, true, true )
        end
      end  
      Envelope_SortPoints( data.env_ptr )
      UpdateArrange()
      --UpdateTimeline()
      redraw = 2 
    end
  end  
  -------------------------------------------------------------- 






  --------------------------------------------------------------   
  function Widgets_Envelope_floatfx(data, obj, mouse, x_offs, widgets, conf, y_offs) -- generate snap_offs controls
    if data.env_parentFX == -1 then return  end
    local fxname_w = 100
    if x_offs + fxname_w > obj.persist_margin then return  end  
    local fx_name = MPL_ReduceFXname(data.env_parentFXname)
    obj.b.obj_envfloatfx = { x = x_offs,
                        y =y_offs ,
                        w = fxname_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        ignore_mouse = true,
                        txt = ''} 
    obj.b.obj_envfloatfx_back = { x =  x_offs,
                        y = y_offs+obj.entry_h ,
                        w = fxname_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true} 
    obj.b.obj_envfloatfx_but = { x =  x_offs,
                        y = y_offs,
                        w = fxname_w,
                        h = obj.entry_h*2,
                        frame_a = 0,
                        txt = fx_name,
                        fontsz = obj.fontsz_head,
                        func = function()
                                  TrackFX_Show( data.env_parenttr, data.env_parentFX, 3 )
                                end}   
      if conf.dock_orientation == 1 then
        obj.b.obj_envfloatfx_back.show = false
        obj.b.obj_envfloatfx.x= 0
        obj.b.obj_envfloatfx.y = y_offs
        obj.b.obj_envfloatfx.w = obj.entry_w2
        obj.b.obj_envfloatfx.frame_a = obj.frame_a_head
        obj.b.obj_envfloatfx_but.frame_a = 0
        obj.b.obj_envfloatfx_but.x = 0 
        obj.b.obj_envfloatfx_but.y = y_offs
        obj.b.obj_envfloatfx_but.w = obj.entry_w2
        obj.b.obj_envfloatfx_but.h = obj.entry_h
      end                                                         
    return fxname_w                    
  end
  


  --------------------------------------------------------------   
  function Widgets_Envelope_AIlooplen(data, obj, mouse, x_offs, widgets, conf, y_offs) 
    if not (data.env_AI and data.env_AI[data.env_AI_selidx]) then return x_offs end
    if x_offs + obj.entry_w2 > obj.persist_margin then return x_offs end  
    obj.b.obj_AIlooplen = { x = x_offs,
                        y = y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'AI Length'} 
    obj.b.obj_AIlooplen_back = { x =  x_offs,
                        y = obj.entry_h+y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        fontsz= obj.fontsz_entry,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
                        
    if conf.dock_orientation == 1 then
      obj.b.obj_AIlooplen.w = obj.entry_w2/2
      obj.b.obj_AIlooplen_back.x= obj.entry_w2/2
      obj.b.obj_AIlooplen_back.y = y_offs
      obj.b.obj_AIlooplen_back.w = obj.entry_w2/2
      obj.b.obj_AIlooplen_back.frame_a = obj.frame_a_head
    end     
      
                    
    local val_str = data.env_AI[data.env_AI_selidx].D_POOL_QNLEN
    Obj_GenerateCtrl(  
                        { data=data,obj=obj,  mouse=mouse,
                        t = {val_str},
                        table_key='AIlooplen_ctrl',
                        x_offs= obj.b.obj_AIlooplen_back.x,  
                        y_offs= obj.b.obj_AIlooplen_back.y,  
                        w_com=obj.b.obj_AIlooplen_back.w,
                        src_val=data.env_AI[data.env_AI_selidx].D_POOL_QNLEN,
                        modify_func= MPL_ModifyFloatVal,
                        modify_wholestr=true,
                        app_func= Apply_D_POOL_QNLEN_Val,                          
                        mouse_scale= obj.mouse_scal_float,               -- mouse scaling
                        use_mouse_drag_xAxis = data.always_use_x_axis==1, -- x
                        --ignore_fields= true
                        default_val = 4,
                        onRelease_ActName = data.scr_title..': Change point properties'
                        }
                      )
    return obj.entry_w2                
  end
  
 
  -------------------------------------------------------------- 
  function Apply_D_POOL_QNLEN_Val(data, obj, t_out_values, butkey, out_str_toparse, mouse)
    if not out_str_toparse then
      test = t_out_values
      local out_val = t_out_values
      for autoitem_idx = 0,  #data.env_AI do 
        if data.env_AI[autoitem_idx].D_UISEL ==1 then
          GetSetAutomationItemInfo( data.env_AI[autoitem_idx].par_env,  autoitem_idx, 'D_POOL_QNLEN', out_val, 1 ) 
        end
      end
      Envelope_SortPoints( data.env_ptr )
      obj.b.obj_AIlooplen_back.txt = out
     else --input str
      local out_val
      out_val = tonumber(out_str_toparse) 
      if not out_val then return end
      for autoitem_idx = 0,  #data.env_AI do 
        if data.env_AI[autoitem_idx].D_UISEL ==1 then
          GetSetAutomationItemInfo( data.env_AI[autoitem_idx].par_env,  autoitem_idx, 'D_POOL_QNLEN', out_val, 1 ) 
        end
      end
      Envelope_SortPoints( data.env_ptr )
      redraw = 2 
    end
  end  
