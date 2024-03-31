-- @description InteractiveToolbar_Widgets_Item
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex


  -- Item wigets for mpl_InteractiveToolbar
  
  ---------------------------------------------------
  function Obj_UpdateItem(data, obj, mouse, widgets, conf)
    obj.b.obj_name = { x = obj.menu_b_rect_side + obj.offs,
                        y = obj.offs *2 +obj.entry_h,
                        w = conf.GUI_contextname_w*conf.scaling,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt_a = obj.txt_a,
                        txt = data.it[1].name,
                        fontsz = obj.fontsz_entry,
                        func_wheel =  function()
                                        if  mouse.wheel_trig >= 1 then
                                          Main_OnCommand(40125,0) --Take: Switch items to next take
                                         elseif  mouse.wheel_trig <= -1 then
                                          Main_OnCommand(40126,0) -- Take: Switch items to previous take
                                        end
                                        redraw = 2
                                      end,
                        func_DC = 
                          function ()
                            if data.it[1].name then
                              local retval0, retvals_csv = GetUserInputs( 'Rename', 1, 'New Name, extrawidth=220', data.it[1].name )
                              if not retval0 then return end
                              if      data.it[1].obj_type_int == 0  
                                  or  data.it[1].obj_type_int == 1 
                                  or  data.it[1].obj_type_int == 2 then
                                if data.it[1].ptr_take and ValidatePtr2(0, data.it[1].ptr_take,'MediaItem_Take*') then
                                  GetSetMediaItemTakeInfo_String( data.it[1].ptr_take, 'P_NAME', retvals_csv, true )
                                  redraw = 1
                                end
                              end
                            end
                          end} 
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
        if _G['Widgets_Item_'..key] then
            local retX, retY = _G['Widgets_Item_'..key](data, obj, mouse, x_offs, widgets, conf, y_offs) 
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
  function Widgets_Item_position(data, obj, mouse, x_offs, widgets, conf, y_offs)     -- generate position controls 
    if not data.it then return end
    if x_offs + obj.entry_w2 > obj.persist_margin then return x_offs end 
    obj.b.obj_pos = { x = x_offs,
                        y = y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'Position'} 
    obj.b.obj_pos_back = { x =  x_offs,
                        y = obj.entry_h+y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
      if conf.dock_orientation == 1 then
        obj.b.obj_pos.w = obj.entry_w2/2
        obj.b.obj_pos_back.x= obj.entry_w2/2
        obj.b.obj_pos_back.y = y_offs
        obj.b.obj_pos_back.w = obj.entry_w2/2
        obj.b.obj_pos_back.frame_a = obj.frame_a_head
      end                  
                        
      local pos_str =  data.it[1].item_pos_format
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = MPL_GetTableOfCtrlValues(pos_str),
                        table_key='position_ctrl',
                        x_offs= obj.b.obj_pos_back.x,
                        y_offs = obj.b.obj_pos_back.y,
                        w_com=obj.b.obj_pos_back.w,--obj.entry_w2,
                        src_val=data.it,
                        src_val_key= 'item_pos',
                        modify_func= MPL_ModifyTimeVal,
                        app_func= Apply_Item_Pos,                         
                        mouse_scale= obj.mouse_scal_time,
                        onRelease_ActName = data.scr_title..': Change item properties',
                        use_mouse_drag_xAxis = data.always_use_x_axis==1,})                         
    return obj.entry_w2, obj.entry_h
  end  
  function Apply_Item_Pos(data, obj, t_out_values, butkey, out_str_toparse, mouse)
    if not out_str_toparse then    
      
        for i = 1, #t_out_values do
          local outv
          if mouse.Ctrl then outv = math.max(0,t_out_values[1]) else outv = math.max(0,t_out_values[i]) end
          SetMediaItemInfo_Value( data.it[i].ptr_item, 'D_POSITION',outv)
          UpdateItemInProject( data.it[i].ptr_item )                                
        end  
        
      local new_str = format_timestr_pos( t_out_values[1], '',data.ruleroverride ) 
      local new_str_t = MPL_GetTableOfCtrlValues(new_str)
      for i = 1, #new_str_t do
        obj.b[butkey..i].txt = new_str_t[i]
      end
     else
      -- nudge values from first item
      local out_val = parse_timestr_pos(out_str_toparse,data.ruleroverride) 
      local diff = out_val - data.it[1].item_pos
        for i = 1, #t_out_values do
          SetMediaItemInfo_Value( data.it[i].ptr_item, 'D_POSITION', math.max(0,t_out_values[i] + diff ))
          UpdateItemInProject( data.it[i].ptr_item )                                
        end
      redraw = 2   
    end
  end  
  -------------------------------------------------------------- 





  function Widgets_Item_endedge(data, obj, mouse, x_offs, widgets, conf, y_offs)     -- generate position controls 
    if not data.it then return end
    if x_offs + obj.entry_w2 > obj.persist_margin then return x_offs end 
    obj.b.obj_endedge = { x = x_offs,
                        y = y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'End'} 
    obj.b.obj_endedge_back = { x =  x_offs,
                        y = obj.entry_h+y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
      if conf.dock_orientation == 1 then
        obj.b.obj_endedge.w = obj.entry_w2/2
        obj.b.obj_endedge_back.x= obj.entry_w2/2
        obj.b.obj_endedge_back.y = y_offs
        obj.b.obj_endedge_back.w = obj.entry_w2/2
        obj.b.obj_endedge_back.frame_a = obj.frame_a_head
      end                         
                        
      local pos_str =  data.it[1].item_end_format
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = MPL_GetTableOfCtrlValues(pos_str),
                        table_key='endedge_ctrl',
                        x_offs= obj.b.obj_endedge_back.x,  
                        y_offs = obj.b.obj_endedge_back.y ,
                        w_com=obj.b.obj_endedge_back.w,--obj.entry_w2,
                        src_val=data.it,
                        src_val_key= 'item_end',
                        modify_func= MPL_ModifyTimeVal,
                        use_mouse_drag_xAxis = data.always_use_x_axis==1,
                        app_func= Apply_Item_Pos2,                         
                        mouse_scale= obj.mouse_scal_time,
                        onRelease_ActName = data.scr_title..': Change item properties'})                         
    return obj.entry_w2,obj.entry_h
  end  
  function Apply_Item_Pos2(data, obj, t_out_values, butkey, out_str_toparse, mouse)
    if not out_str_toparse then    
      
        for i = 1, #t_out_values do
          local outv
          if mouse.Ctrl then outv = math.max(0,t_out_values[1]) else outv = math.max(0,t_out_values[i]) end
          SetMediaItemInfo_Value( data.it[i].ptr_item, 'D_POSITION',outv-data.it[i].item_len)
          UpdateItemInProject( data.it[i].ptr_item )                                
        end  
        
      local new_str = format_timestr_pos( t_out_values[1], '', data.ruleroverride ) 
      local new_str_t = MPL_GetTableOfCtrlValues(new_str)
      for i = 1, #new_str_t do
        obj.b[butkey..i].txt = new_str_t[i]
      end
     else
      -- nudge values from first item
      local out_val = parse_timestr_pos(out_str_toparse,data.ruleroverride) 
      local diff = out_val - (data.it[1].item_pos +data.it[1].item_len)
        for i = 1, #t_out_values do
          SetMediaItemInfo_Value( data.it[i].ptr_item, 'D_POSITION', math.max(0,t_out_values[i] + diff-data.it[i].item_len))
          UpdateItemInProject( data.it[i].ptr_item )                                
        end
      redraw = 2   
    end
  end  
  -------------------------------------------------------------- 
  
  
  
  
  
  
  
  
  
  --------------------------------------------------------------   
  function Widgets_Item_snap(data, obj, mouse, x_offs, widgets, conf, y_offs) -- generate snap_offs controls  
    if x_offs + obj.entry_w2 > obj.persist_margin then return x_offs end 
    obj.b.obj_snap_offs = { x = x_offs,
                       y =y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'Snap'} 
    obj.b.obj_snap_offs_back = { x =  x_offs,
                        y = obj.entry_h+y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
      if conf.dock_orientation == 1 then
        obj.b.obj_snap_offs.w = obj.entry_w2/2
        obj.b.obj_snap_offs_back.x= obj.entry_w2/2
        obj.b.obj_snap_offs_back.y = y_offs
        obj.b.obj_snap_offs_back.w = obj.entry_w2/2
        obj.b.obj_snap_offs_back.frame_a = obj.frame_a_head
      end                  
      local snap_offs_str = data.it[1].snap_offs_format
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = MPL_GetTableOfCtrlValues(snap_offs_str),
                        table_key='snap_offs_ctrl',
                        x_offs= obj.b.obj_snap_offs_back.x,  
                        y_offs = obj.b.obj_snap_offs_back.y,
                        w_com=obj.b.obj_snap_offs_back.w,--obj.entry_w2,
                        src_val=data.it,
                        src_val_key= 'snap_offs',
                        modify_func= MPL_ModifyTimeVal,
                        app_func= Apply_Item_SnapOffs,                         
                        mouse_scale= obj.mouse_scal_time,
                        default_val=0,
                        onRelease_ActName = data.scr_title..': Change item properties',
                        use_mouse_drag_xAxis = data.always_use_x_axis==1,})                           
    return obj.entry_w2,obj.entry_h                        
  end
  
  function Apply_Item_SnapOffs(data, obj, t_out_values, butkey, out_str_toparse)
    if not out_str_toparse then    
      for i = 1, #t_out_values do
        SetMediaItemInfo_Value( data.it[i].ptr_item, 'D_SNAPOFFSET', math.max(0,t_out_values[i] ))
        UpdateItemInProject( data.it[i].ptr_item )                                
      end
      local new_str = format_timestr_len( t_out_values[1], '',0,data.ruleroverride ) 
      local new_str_t = MPL_GetTableOfCtrlValues(new_str)
      for i = 1, #new_str_t do
        obj.b[butkey..i].txt = new_str_t[i]
      end
     else
      -- directly set value from first item
      local out_val = parse_timestr_len(out_str_toparse,1,data.ruleroverride) 
      for i = 1, #t_out_values do
        SetMediaItemInfo_Value( data.it[i].ptr_item, 'D_SNAPOFFSET', math.max(0,out_val ))
        UpdateItemInProject( data.it[i].ptr_item )                                
      end   
      redraw = 2   
    end
  end  
  -------------------------------------------------------------- 







  -------------------------------------------------------------- 
  function Widgets_Item_pan(data, obj, mouse, x_offs, widgets, conf, y_offs) -- generate snap_offs controls  
    local pan_w = 60
    if conf.dock_orientation == 1 then 
     pan_w = obj.entry_w2
    end
    if x_offs + pan_w > obj.persist_margin then return x_offs end 
    obj.b.obj_it_pan = { x = x_offs,
                        y =y_offs ,
                        w = pan_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'Pan'} 
    obj.b.obj_it_pan_back = { x =  x_offs,
                        y = obj.entry_h+y_offs ,
                        w = pan_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
      if conf.dock_orientation == 1 then
        obj.b.obj_it_pan.w = obj.entry_w2/2
        obj.b.obj_it_pan_back.x= obj.entry_w2/2
        obj.b.obj_it_pan_back.y = y_offs
        obj.b.obj_it_pan_back.w = obj.entry_w2/2
        obj.b.obj_it_pan_back.frame_a = obj.frame_a_head
      end                 
      local it_pan_str = data.it[1].pan_format
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = {data.it[1].pan_format},
                        table_key='it_pan_ctrl',
                        x_offs= obj.b.obj_it_pan_back.x,  
                        y_offs = obj.b.obj_it_pan_back.y,
                        w_com=obj.b.obj_it_pan_back.w,--obj.entry_w2,
                        src_val=data.it,
                        src_val_key= 'pan',
                        modify_func= MPL_ModifyFloatVal,
                        app_func= Apply_Item_pan,                         
                        mouse_scale= obj.mouse_scal_pan,
                        use_mouse_drag_xAxis = true,
                        parse_pan_tags = true,
                        default_val=0,
                        onRelease_ActName = data.scr_title..': Change item properties'})                          
    return pan_w,obj.entry_h                    
  end
  
  function Apply_Item_pan(data, obj, t_out_values, butkey, out_str_toparse)
    if not out_str_toparse then    
      for i = 1, #t_out_values do        
        local out_val = math_q(t_out_values[i]*100)/100
        SetMediaItemTakeInfo_Value( data.it[i].ptr_take, 'D_PAN', lim(out_val,-1,1) )
        UpdateItemInProject( data.it[i].ptr_item )                                
      end
      t_out_values[1] = lim(t_out_values[1], -1,1)
      local out_val = math_q(t_out_values[1]*100)/100
      local new_str = MPL_FormatPan(out_val)
      obj.b[butkey..1].txt = new_str
      redraw = 1
     else
      local out_val = MPL_ParsePanVal(out_str_toparse)
      --[[nudge
        local diff = data.it[1].pan - out_val
        for i = 1, #t_out_values do
          SetMediaItemTakeInfo_Value( data.it[i].ptr_take, 'D_PAN', lim(t_out_values[i] - diff,-1,1) )
          UpdateItemInProject( data.it[i].ptr_item )                                
        end   ]]
      --set
        for i = 1, # data.it do
          local out_val = math_q(out_val*100)/100
          SetMediaItemTakeInfo_Value( data.it[i].ptr_take, 'D_PAN', lim(out_val,-1,1) )
          UpdateItemInProject( data.it[i].ptr_item )                                
        end     
      redraw = 2   
    end
  end  
  --------------------------------------------------------------




  --------------------------------------------------------------   
  function Widgets_Item_length(data, obj, mouse, x_offs, widgets, conf, y_offs) -- generate snap_offs controls  
    if x_offs + obj.entry_w2 > obj.persist_margin then return x_offs end 
    obj.b.obj_len = { x = x_offs,
                       y = y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'Length'} 
    obj.b.obj_len_back = { x =  x_offs,
                        y = obj.entry_h+y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
      if conf.dock_orientation == 1 then
        obj.b.obj_len.w = obj.entry_w2/2
        obj.b.obj_len_back.x= obj.entry_w2/2
        obj.b.obj_len_back.y = y_offs
        obj.b.obj_len_back.w = obj.entry_w2/2
        obj.b.obj_len_back.frame_a = obj.frame_a_head
      end                 
      local len_str = data.it[1].item_len_format
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = MPL_GetTableOfCtrlValues(len_str),
                        table_key='len_ctrl',
                        x_offs= obj.b.obj_len_back.x,  
                        y_offs = obj.b.obj_len_back.y ,
                        w_com=obj.b.obj_len_back.w,--obj.entry_w2,
                        src_val=data.it,
                        src_val_key= 'item_len',
                        modify_func= MPL_ModifyTimeVal,
                        app_func= Apply_Item_Length,                         
                        mouse_scale= obj.mouse_scal_time,
                        onRelease_ActName = data.scr_title..': Change item properties',
                        use_mouse_drag_xAxis = data.always_use_x_axis==1,})                          
    return obj.entry_w2,obj.entry_h
  end
  
  function Apply_Item_Length(data, obj, t_out_values, butkey, out_str_toparse, mouse)
    if not out_str_toparse then    
      
        for i = 1, #t_out_values do
          local out_len
          if mouse.Ctrl then out_len = math.max(0.001,t_out_values[1]) else out_len = math.max(0.001,t_out_values[i]) end
          SetMediaItemInfo_Value( data.it[i].ptr_item, 'D_LENGTH', out_len )
          if data.it[i].isMIDI then
              local start_qn =  TimeMap2_timeToQN( 0, data.it[i].item_pos )
            local end_qn = TimeMap2_timeToQN(0, data.it[i].item_pos + out_len)
            MIDI_SetItemExtents(data.it[i].ptr_item, start_qn, end_qn)
            SetMediaItemInfo_Value( data.it[i].ptr_item, 'B_LOOPSRC',data.it[i].loop)
            SetMediaItemTakeInfo_Value( data.it[i].ptr_take, 'D_STARTOFFS', data.it[i].start_offs )
          end
          UpdateItemInProject( data.it[i].ptr_item ) 
        end
           
      local new_str = format_timestr_len( t_out_values[1],'', 1,data.ruleroverride ) 
      local new_str_t = MPL_GetTableOfCtrlValues(new_str)
      for i = 1, #new_str_t do
        obj.b[butkey..i].txt = new_str_t[i]
      end
     else
      -- nudge values from first item
      local out_val = parse_timestr_len(out_str_toparse,1,data.ruleroverride) 
      
      if data.relative_it_len == 1 then
        local diff = data.it[1].item_len - out_val
        for i = 1, #t_out_values do
          local out_len = math.max(0.001,t_out_values[i] - diff )
          SetMediaItemInfo_Value( data.it[i].ptr_item, 'D_LENGTH', out_len)
          if data.it[i].isMIDI then
              local start_qn =  TimeMap2_timeToQN( 0, data.it[i].item_pos )
            local end_qn = TimeMap2_timeToQN(0, data.it[i].item_pos + out_len)
            MIDI_SetItemExtents(data.it[i].ptr_item, start_qn, end_qn)
            SetMediaItemInfo_Value( data.it[i].ptr_item, 'B_LOOPSRC',data.it[i].loop)
            SetMediaItemTakeInfo_Value( data.it[i].ptr_take, 'D_STARTOFFS', data.it[i].start_offs )
          end        
          --UpdateItemInProject( data.it[i].ptr_item )                                
        end
        
       else
       
        for i = 1, #t_out_values do
          SetMediaItemInfo_Value( data.it[i].ptr_item, 'D_LENGTH', out_val)
          if data.it[i].isMIDI then
              local start_qn =  TimeMap2_timeToQN( 0, data.it[i].item_pos )
            local end_qn = TimeMap2_timeToQN(0, data.it[i].item_pos + out_val)
            MIDI_SetItemExtents(data.it[i].ptr_item, start_qn, end_qn)
            SetMediaItemInfo_Value( data.it[i].ptr_item, 'B_LOOPSRC',data.it[i].loop)
            SetMediaItemTakeInfo_Value( data.it[i].ptr_take, 'D_STARTOFFS', data.it[i].start_offs )
          end        
          --UpdateItemInProject( data.it[i].ptr_item )                                
        end        
        
      end
      redraw = 2   
    end
  end  
  -------------------------------------------------------------- 






  --------------------------------------------------------------   
  function Widgets_Item_srclen(data, obj, mouse, x_offs, widgets, conf, y_offs) -- generate snap_offs controls  
    if x_offs + obj.entry_w2 > obj.persist_margin then return x_offs end 
    obj.b.obj_srclen = { x = x_offs,
                        y = y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'SRC Length'} 
    obj.b.obj_srclen_back = { x =  x_offs,
                        y = obj.entry_h+y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
      if conf.dock_orientation == 1 then
        obj.b.obj_srclen.w = obj.entry_w2/2
        obj.b.obj_srclen_back.x= obj.entry_w2/2
        obj.b.obj_srclen_back.y = y_offs
        obj.b.obj_srclen_back.w = obj.entry_w2/2
        obj.b.obj_srclen_back.frame_a = obj.frame_a_head
      end                
      local srclen_str = data.it[1].srclen_format
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = MPL_GetTableOfCtrlValues(srclen_str),
                        table_key='srclen_ctrl',
                        x_offs= obj.b.obj_srclen_back.x,  
                        y_offs = obj.b.obj_srclen_back.y,
                        w_com=obj.b.obj_srclen_back.w,--obj.entry_w2,
                        src_val=data.it,
                        src_val_key= 'srclen',
                        modify_func= MPL_ModifyTimeVal,
                        app_func= Apply_Item_SrcLength,                         
                        mouse_scale= obj.mouse_scal_time,
                        onRelease_ActName = data.scr_title..': Change item properties',
                        use_mouse_drag_xAxis = data.always_use_x_axis==1,})                          
    return obj.entry_w2,obj.entry_h
  end
  
  function Apply_Item_SrcLength(data, obj, t_out_values, butkey, out_str_toparse, mouse)
    if not out_str_toparse then    
      
        for i = 1, #t_out_values do
          local out_len
          if mouse.Ctrl then out_len = math.max(0.001,t_out_values[1]) else out_len = math.max(0.001,t_out_values[i]) end
          BR_SetMediaSourceProperties( data.it[i].ptr_take, true, data.it[i].src_start, out_len, data.it[i].src_fade, data.it[i].src_reverse)
          UpdateItemInProject( data.it[i].ptr_item ) 
        end
        --Main_OnCommand(40441, 0) --Peaks: Rebuild peaks for selected items
        --UpdateArrange() 
           
      local new_str = format_timestr_len( t_out_values[1],'', 1,data.ruleroverride ) 
      local new_str_t = MPL_GetTableOfCtrlValues(new_str)
      for i = 1, #new_str_t do
        obj.b[butkey..i].txt = new_str_t[i]
      end
     else
      -- nudge values from first item
      local out_val = parse_timestr_len(out_str_toparse,1,data.ruleroverride) 
      local diff = data.it[1].item_len - out_val
      for i = 1, #t_out_values do
        local out_len = math.max(0.001,t_out_values[i] - diff )
        BR_SetMediaSourceProperties( data.it[i].ptr_take, true, data.it[i].src_start, out_len, data.it[i].src_fade, data.it[i].src_reverse)
        --UpdateItemInProject( data.it[i].ptr_item )   
      end
      --Main_OnCommand(40441, 0) --Peaks: Rebuild peaks for selected items 
      redraw = 2
      --UpdateArrange()   
    end
  end  
  -------------------------------------------------------------- 
  
  
  
  
  
  
  
  
  
  --------------------------------------------------------------
  function Widgets_Item_offset(data, obj, mouse, x_offs, widgets, conf, y_offs)    -- generate position controls 
    if x_offs + obj.entry_w2 > obj.persist_margin then return x_offs end 
    obj.b.obj_start_offs = { x = x_offs,
                        y = y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'Offset'} 
    obj.b.obj_start_offs_back = { x =  x_offs,
                        y = obj.entry_h+y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
                        
      if conf.dock_orientation == 1 then
        obj.b.obj_start_offs.w = obj.entry_w2/2
        obj.b.obj_start_offs_back.x= obj.entry_w2/2
        obj.b.obj_start_offs_back.y = y_offs
        obj.b.obj_start_offs_back.w = obj.entry_w2/2
        obj.b.obj_start_offs_back.frame_a = obj.frame_a_head
      end                          
      local start_offs_str = data.it[1].start_offs_format
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = MPL_GetTableOfCtrlValues(start_offs_str),
                        table_key='start_offs_ctrl',
                        x_offs= obj.b.obj_start_offs_back.x,  
                        y_offs = obj.b.obj_start_offs_back.y,
                        w_com=obj.b.obj_start_offs_back.w,--obj.entry_w2,
                        src_val=data.it,
                        src_val_key= 'start_offs',
                        modify_func= MPL_ModifyTimeVal,
                        app_func= Apply_Item_Offset,                         
                        mouse_scale= obj.mouse_scal_time,
                        default_val=0,
                        onRelease_ActName = data.scr_title..': Change item properties',
                        use_mouse_drag_xAxis = data.always_use_x_axis==1,})                            
    return obj.entry_w2,obj.entry_h                        
  end  
  function Apply_Item_Offset(data, obj, t_out_values, butkey, out_str_toparse)
    if not out_str_toparse then    
      for i = 1, #t_out_values do
        SetMediaItemTakeInfo_Value( data.it[i].ptr_take, 'D_STARTOFFS', t_out_values[i] )
        UpdateItemInProject( data.it[i].ptr_item )                                
      end
      local new_str = format_timestr_len( t_out_values[1], '',1, data.ruleroverride ) 
      local new_str_t = MPL_GetTableOfCtrlValues(new_str)
      for i = 1, #new_str_t do
        obj.b[butkey..i].txt = new_str_t[i]
      end
     else
      -- nudge values from first item
      local out_val = parse_timestr_len(out_str_toparse,1,data.ruleroverride) 
      local diff = data.it[1].start_offs - out_val
      for i = 1, #t_out_values do
        SetMediaItemTakeInfo_Value( data.it[i].ptr_take, 'D_STARTOFFS', t_out_values[i] - diff )
        UpdateItemInProject( data.it[i].ptr_item )                                
      end
      redraw = 2   
    end
  end    
  -------------------------------------------------------------- 

  --------------------------------------------------------------
  function Widgets_Item_leftedge(data, obj, mouse, x_offs, widgets, conf, y_offs)    -- generate position controls 
    if x_offs + obj.entry_w2 > obj.persist_margin then return x_offs end 
    obj.b.obj_leftedge = { x = x_offs,
                        y = y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'LeftEdge'} 
    obj.b.obj_leftedge_back = { x =  x_offs,
                        y = obj.entry_h+y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
                        
      if conf.dock_orientation == 1 then
        obj.b.obj_leftedge.w = obj.entry_w2/2
        obj.b.obj_leftedge_back.x= obj.entry_w2/2
        obj.b.obj_leftedge_back.y = y_offs
        obj.b.obj_leftedge_back.w = obj.entry_w2/2
        obj.b.obj_leftedge_back.frame_a = obj.frame_a_head
      end                          
      local start_offs_str = data.it[1].start_offs_format
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = MPL_GetTableOfCtrlValues(start_offs_str),
                        table_key='leftedge_ctrl',
                        x_offs= obj.b.obj_leftedge_back.x,  
                        y_offs = obj.b.obj_leftedge_back.y,
                        w_com=obj.b.obj_leftedge_back.w,--obj.entry_w2,
                        src_val=data.it,
                        src_val_key= 'start_offs',
                        modify_func= MPL_ModifyTimeVal,
                        app_func= Apply_Item_Offset2,                         
                        mouse_scale= obj.mouse_scal_time,
                        default_val=0,
                        onRelease_ActName = data.scr_title..': Change item properties',
                        use_mouse_drag_xAxis = data.always_use_x_axis==1,})                              
    return obj.entry_w2,obj.entry_h                        
  end  
  function Apply_Item_Offset2(data, obj, t_out_values, butkey, out_str_toparse)
    if not out_str_toparse then    
      for i = 1, #t_out_values do
        local cur_offs = GetMediaItemTakeInfo_Value( data.it[i].ptr_take, 'D_STARTOFFS') 
        local pos = GetMediaItemInfo_Value( data.it[i].ptr_item, 'D_POSITION')
        local len = GetMediaItemInfo_Value( data.it[i].ptr_item, 'D_LENGTH')
        SetMediaItemTakeInfo_Value( data.it[i].ptr_take, 'D_STARTOFFS', t_out_values[i] )
        SetMediaItemInfo_Value( data.it[i].ptr_item, 'D_POSITION',pos - (cur_offs - t_out_values[i]))
        SetMediaItemInfo_Value( data.it[i].ptr_item, 'D_LENGTH',len + (cur_offs - t_out_values[i]))
        UpdateItemInProject( data.it[i].ptr_item )                                
      end
      local new_str = format_timestr_len( t_out_values[1], '',1, data.ruleroverride ) 
      local new_str_t = MPL_GetTableOfCtrlValues(new_str)
      for i = 1, #new_str_t do
        obj.b[butkey..i].txt = new_str_t[i]
      end
     else
      -- nudge values from first item
      local out_val = parse_timestr_len(out_str_toparse,1,data.ruleroverride) 
      local diff = data.it[1].start_offs - out_val
      for i = 1, #t_out_values do
        local cur_offs = GetMediaItemTakeInfo_Value( data.it[i].ptr_take, 'D_STARTOFFS') 
        local pos = GetMediaItemInfo_Value( data.it[i].ptr_item, 'D_POSITION')
        local len = GetMediaItemInfo_Value( data.it[i].ptr_item, 'D_LENGTH')
        SetMediaItemTakeInfo_Value( data.it[i].ptr_take, 'D_STARTOFFS', t_out_values[i] - diff )
        SetMediaItemInfo_Value( data.it[i].ptr_item, 'D_POSITION',pos - (cur_offs - (t_out_values[i]- diff)))
        SetMediaItemInfo_Value( data.it[i].ptr_item, 'D_LENGTH',len + (cur_offs - (t_out_values[i]- diff)))
        UpdateItemInProject( data.it[i].ptr_item )                                
      end
      redraw = 2   
    end
  end    
  -------------------------------------------------------------- 




  --------------------------------------------------------------   
  function Widgets_Item_fadein(data, obj, mouse, x_offs, widgets, conf, y_offs) -- generate snap_offs controls  
    if x_offs + obj.entry_w2 > obj.persist_margin then return x_offs end 
    obj.b.obj_fadein = { x = x_offs,
                        y = y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'FadeIn'} 
    obj.b.obj_fadein_back = { x =  x_offs,
                        y = obj.entry_h+y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
      if conf.dock_orientation == 1 then
        obj.b.obj_fadein.w = obj.entry_w2/2
        obj.b.obj_fadein_back.x= obj.entry_w2/2
        obj.b.obj_fadein_back.y = y_offs
        obj.b.obj_fadein_back.w = obj.entry_w2/2
        obj.b.obj_fadein_back.frame_a = obj.frame_a_head
      end                 
      local fadein_str = data.it[1].fadein_len_format
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = MPL_GetTableOfCtrlValues(fadein_str),
                        table_key='fadein_ctrl',
                        x_offs= obj.b.obj_fadein_back.x,  
                        y_offs = obj.b.obj_fadein_back.y ,
                        w_com=obj.b.obj_fadein_back.w,--obj.entry_w2,
                        src_val=data.it,
                        src_val_key= 'fadein_len',
                        modify_func= MPL_ModifyTimeVal,
                        app_func= Apply_Item_fadein,                         
                        mouse_scale= obj.mouse_scal_time,
                        default_val=0,
                        onRelease_ActName = data.scr_title..': Change item properties',
                        use_mouse_drag_xAxis = data.always_use_x_axis==1,})                         
    return obj.entry_w2,obj.entry_h
  end
  
  function Apply_Item_fadein(data, obj, t_out_values, butkey, out_str_toparse)
    if not out_str_toparse then    
      for i = 1, #t_out_values do
        SetMediaItemInfo_Value( data.it[i].ptr_item, 'D_FADEINLEN', math.max(0,t_out_values[i] ))
        UpdateItemInProject( data.it[i].ptr_item )                                
      end
      local new_str = format_timestr_len( t_out_values[1], '', 0, data.ruleroverride ) 
      local new_str_t = MPL_GetTableOfCtrlValues(new_str)
      for i = 1, #new_str_t do
        obj.b[butkey..i].txt = new_str_t[i]
      end
     else
      -- directly set value from first item
      local out_val = parse_timestr_len(out_str_toparse,1,data.ruleroverride) 
      for i = 1, #t_out_values do
        SetMediaItemInfo_Value( data.it[i].ptr_item, 'D_FADEINLEN',math.max(0, out_val ))
        UpdateItemInProject( data.it[i].ptr_item )                                
      end   
      redraw = 2   
    end
  end  
  -------------------------------------------------------------- 







  --------------------------------------------------------------   
  function Widgets_Item_fadeout(data, obj, mouse, x_offs, widgets, conf, y_offs) -- generate snap_offs controls  
    if x_offs + obj.entry_w2 > obj.persist_margin then return x_offs end 
    obj.b.obj_fadeout = { x = x_offs,
                        y = y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'FadeOut'} 
    obj.b.obj_fadeout_back = { x =  x_offs,
                        y = obj.entry_h+y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
      if conf.dock_orientation == 1 then
        obj.b.obj_fadeout.w = obj.entry_w2/2
        obj.b.obj_fadeout_back.x= obj.entry_w2/2
        obj.b.obj_fadeout_back.y = y_offs
        obj.b.obj_fadeout_back.w = obj.entry_w2/2
        obj.b.obj_fadeout_back.frame_a = obj.frame_a_head
      end                  
      local fadeout_str = data.it[1].fadeout_len_format
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = MPL_GetTableOfCtrlValues(fadeout_str),
                        table_key='fadeout_ctrl',
                        x_offs= obj.b.obj_fadeout_back.x,  
                        y = obj.b.obj_fadeout_back.y ,
                        w_com=obj.b.obj_fadeout_back.w,--obj.entry_w2,
                        src_val=data.it,
                        src_val_key= 'fadeout_len',
                        modify_func= MPL_ModifyTimeVal,
                        app_func= Apply_Item_fadeout,                         
                        mouse_scale= obj.mouse_scal_time,
                        default_val=0,
                        onRelease_ActName = data.scr_title..': Change item properties',
                        use_mouse_drag_xAxis = data.always_use_x_axis==1,})                          
    return obj.entry_w2
  end
  
  function Apply_Item_fadeout(data, obj, t_out_values, butkey, out_str_toparse)
    if not out_str_toparse then    
      for i = 1, #t_out_values do
        SetMediaItemInfo_Value( data.it[i].ptr_item, 'D_FADEOUTLEN', math.max(0,t_out_values[i] ))
        UpdateItemInProject( data.it[i].ptr_item )                                
      end
      local new_str = format_timestr_len( t_out_values[1], '', 0, data.ruleroverride ) 
      local new_str_t = MPL_GetTableOfCtrlValues(new_str)
      for i = 1, #new_str_t do
        obj.b[butkey..i].txt = new_str_t[i]
      end
     else
      -- directly set value from first item
      local out_val = parse_timestr_len(out_str_toparse,1,data.ruleroverride) 
      for i = 1, #t_out_values do
        SetMediaItemInfo_Value( data.it[i].ptr_item, 'D_FADEOUTLEN',math.max(0, out_val ))
        UpdateItemInProject( data.it[i].ptr_item )                                
      end   
      redraw = 2   
    end
  end  
  -------------------------------------------------------------- 







  --------------------------------------------------------------   
  function Widgets_Item_vol(data, obj, mouse, x_offs, widgets, conf, y_offs) -- generate snap_offs controls 
    local vol_w = 60 *conf.scaling
    if conf.dock_orientation == 1 then 
     vol_w = obj.entry_w2
    end
    if x_offs + vol_w > obj.persist_margin then return x_offs end 
    obj.b.obj_vol = { x = x_offs,
                        y = y_offs ,
                        w = vol_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'Volume'} 
    obj.b.obj_vol_back = { x =  x_offs,
                        y = obj.entry_h+y_offs ,
                        w = vol_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        fontsz = obj.fontsz_entry,
                        ignore_mouse = true}  
      if conf.dock_orientation == 1 then
        obj.b.obj_vol.w = obj.entry_w2/2
        obj.b.obj_vol_back.x= obj.entry_w2/2
        obj.b.obj_vol_back.y = y_offs
        obj.b.obj_vol_back.w = obj.entry_w2/2
        obj.b.obj_vol_back.frame_a = obj.frame_a_head
      end                  
      local vol_str = data.it[1].vol_format
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = {vol_str},
                        table_key='vol_ctrl',
                        x_offs= obj.b.obj_vol_back.x,  
                        y = obj.b.obj_vol_back.y ,
                        w_com=obj.b.obj_vol_back.w,--obj.entry_w2,
                        src_val=data.it,
                        src_val_key= 'vol',
                        modify_func= MPL_ModifyFloatVal,
                        app_func= Apply_Item_vol,                         
                        mouse_scale= obj.mouse_scal_vol,
                        ignore_fields = true,
                        default_val = 1,
                        modify_wholestr = true,
                        onRelease_ActName = data.scr_title..': Change item properties',
                        use_mouse_drag_xAxis = data.always_use_x_axis==1,})                           
    return vol_w--obj.entry_w2                         
  end
  
  function Apply_Item_vol(data, obj, t_out_values, butkey, out_str_toparse, mouse)
    if not out_str_toparse then    
      for i = 1, #t_out_values do
        local val = math.max(0,t_out_values[i] )
        if mouse.Ctrl then val = math.max(0,t_out_values[1] ) end
        SetMediaItemInfo_Value( data.it[i].ptr_item, 'D_VOL', val)
        UpdateItemInProject( data.it[i].ptr_item )                                
      end
      if t_out_values[1] < 0 then return end
      local new_str = string.format("%.2f", t_out_values[1])
      local new_str_t = MPL_GetTableOfCtrlValues2(new_str)
      if new_str_t then 
        for i = 1, #new_str_t do
          if obj.b[butkey..i] then obj.b[butkey..i].txt = '' end--new_str_t[i]
        end
        obj.b.obj_vol_back.txt = WDL_VAL2DB(t_out_values[1], true)..'dB'
      end
     else
      --[[local floatdB = out_str_toparse:match('[%d%p]+')
      --local out_val = tonumber(out_str_toparse) 
      out_val = ReaperValfromdB(floatdB)
      out_val = math.max(0,out_val) ]]
      --[[nudge
        local diff = data.it[1].vol - out_val
        for i = 1, #t_out_values do
          SetMediaItemInfo_Value( data.it[i].ptr_item, 'D_VOL', math.max(0,t_out_values[i] - diff ))
          UpdateItemInProject( data.it[i].ptr_item )                                
        end   ]]
      --set
        local out_val = ParseDbVol(out_str_toparse)
        if not out_val then return end
        for i = 1, #t_out_values do
          SetMediaItemInfo_Value( data.it[i].ptr_item, 'D_VOL', math.max(0,out_val ))
          UpdateItemInProject( data.it[i].ptr_item )                                
        end     
      redraw = 2   
    end
  end  
  -------------------------------------------------------------- 







  --------------------------------------------------------------   
  function Widgets_Item_transpose(data, obj, mouse, x_offs, widgets, conf, y_offs)
    local pitch_w = 60
    if conf.dock_orientation == 1 then 
     pitch_w = obj.entry_w2
    end
    if x_offs + pitch_w > obj.persist_margin then return x_offs end 
    obj.b.obj_pitch = { x = x_offs,
                        y = y_offs ,
                        w = pitch_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'Pitch'} 
    obj.b.obj_pitch_back = { x =  x_offs,
                        y = obj.entry_h+y_offs ,
                        w = pitch_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
 if conf.dock_orientation == 1 then
   obj.b.obj_pitch.w = obj.entry_w2/2
   obj.b.obj_pitch_back.x= obj.entry_w2/2
   obj.b.obj_pitch_back.y = y_offs
   obj.b.obj_pitch_back.w = obj.entry_w2/2
   obj.b.obj_pitch_back.frame_a = obj.frame_a_head
 end                 
      local pitch_str = data.it[1].pitch_format
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = MPL_GetTableOfCtrlValues2(pitch_str),
                        table_key='pitch_ctrl',
                        x_offs= obj.b.obj_pitch_back.x,  
                        y = obj.b.obj_pitch_back.y,
                        w_com=obj.b.obj_pitch_back.w,--obj.entry_w2,
                        src_val=data.it,
                        src_val_key= 'pitch',
                        modify_func= MPL_ModifyFloatVal3,
                        app_func= Apply_Item_transpose,                         
                        mouse_scale= obj.mouse_scal_pitch,
                        pow_tolerance = -3,
                        default_val=0,
                        --modify_wholestr = true,
                        onRelease_ActName = data.scr_title..': Change item properties',
                        use_mouse_drag_xAxis = data.always_use_x_axis==1,
                        pow_tolerance2 = 0})                          
    return pitch_w--obj.entry_w2                         
  end
  
  function Apply_Item_transpose(data, obj, t_out_values, butkey, out_str_toparse)
    if not out_str_toparse then    
      for i = 1, #t_out_values do
        SetMediaItemTakeInfo_Value( data.it[i].ptr_take, 'D_PITCH', t_out_values[i])
        UpdateItemInProject( data.it[i].ptr_item )                                
      end
      local new_str_t = MPL_GetTableOfCtrlValues2(t_out_values[1])
      if new_str_t then 
        for i = 1, #new_str_t do
          obj.b[butkey..i].txt = new_str_t[i]
        end
      end
     else
      local out_val = tonumber(out_str_toparse) 
      if not out_val then return end
      local diff = data.it[1].pitch - out_val
      for i = 1, #t_out_values do
        SetMediaItemTakeInfo_Value( data.it[i].ptr_take, 'D_PITCH', t_out_values[i] - diff )
        UpdateItemInProject( data.it[i].ptr_item )                                
      end   
      redraw = 2   
    end
  end  
  -------------------------------------------------------------- 





  
  
  --------------------------------------------------------------  
  function Widgets_Item_buttons(data, obj, mouse, x_offs0, widgets, conf, y_offs0)
    local frame_a, x_offs
    local y_offs = 0
    if conf.dock_orientation == 0 and x_offs0 + obj.entry_w2*2 > obj.persist_margin then return x_offs0 end  -- reduce buttons when more than regular wx2
    local last_x1,last_x2 = x_offs0, x_offs0
    local tp_ID = data.obj_type_int
    local widg_key = widgets.types_t[tp_ID+1] -- get key of current mapped table
    if widgets[widg_key] and widgets[widg_key].buttons  then  
      for i = 1, #widgets[widg_key].buttons do 
        local key = widgets[widg_key].buttons[i]
        if _G['Widgets_Item_buttons_'..key] then  
          if conf.dock_orientation == 0 then  
            if i%2 == 1 then 
              x_offs = last_x1
              frame_a = obj.frame_a_head
              y_offs = 0
             elseif i%2 == 0 then   
              x_offs = last_x2 
              frame_a = obj.frame_a_entry
              y_offs = obj.entry_h
            end
           
           else
            frame_a = obj.frame_a_head
            x_offs = last_x1
          end
          local next_w = _G['Widgets_Item_buttons_'..key](data, obj, mouse, x_offs, y_offs+y_offs0, frame_a, conf)
          if conf.dock_orientation == 0 then  
            if i%2 == 1 then last_x1 = last_x1+next_w elseif i%2 == 0 then last_x2 = last_x2+next_w end 
           else
            last_x1 = last_x1+next_w
            if last_x1 +80> gfx.w then 
              y_offs = y_offs + obj.entry_h
              last_x1 = 0
            end
          end
        end
        
      end
    end
    return math.max(last_x1,last_x2) - x_offs0, y_offs + obj.entry_h
  end           --[[elseif key:match('s(%d+)') then 
          local sp = tonumber(key:match('s(%d+)'))
          if i%2 == 1 then last_x1 = last_x1+sp elseif i%2 == 0 then last_x2 = last_x2+sp end]]
  -------------------------------------------------------------- 
  function Widgets_Item_buttons_lock(data, obj, mouse, x_offs, y_offs, frame_a)
    local w = 40*obj.entry_ratio
    obj.b.obj_itlock = {  x = x_offs,
                        y = y_offs ,
                        w = w,
                        h = obj.entry_h,
                        frame_a = frame_a,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_toolbar,
                        txt = 'Lock',
                        fontsz = obj.fontsz_entry,
                        state = data.it[1].lock==1,
                        state_col = 'red',
                        func =  function()
                                  for i = 1, #data.it do
                                    SetMediaItemInfo_Value( data.it[i].ptr_item, 'C_LOCK', math.abs(data.it[1].lock-1))
                                    UpdateItemInProject( data.it[i].ptr_item )                                
                                  end
                                  redraw = 1                              
                                end,
                        func_R =  function()
                                    Main_OnCommand(40277,0) --  Options: Show lock settings                        
                                  end,                                
                                
                                }
    return w
  end
  -------------------------------------------------------------- 
  function Widgets_Item_buttons_bwfsrc(data, obj, mouse, x_offs, y_offs, frame_a)
    local w = 40*obj.entry_ratio
    obj.b.obj_bwfsrc = {  x = x_offs,
                        y =y_offs ,
                        w = w,
                        h = obj.entry_h,
                        frame_a = frame_a,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_toolbar,
                        txt = 'BWF',
                        fontsz = obj.fontsz_entry,
                        func =  function()
                                  Main_OnCommand(40299,0) --Item: Move to source preferred position (used by BWF)                   
                                  end,                                
                                
                                }
    return w
  end
  --------------------------------------------------------------
  function Widgets_Item_buttons_loop(data, obj, mouse, x_offs, y_offs, frame_a)
    local w = 40*obj.entry_ratio
    obj.b.obj_loop = {  x = x_offs,
                        y = obj.offs+y_offs ,
                        w = w,
                        h = obj.entry_h,
                        frame_a = frame_a,
                        txt_a = obj.txt_a,
                        fontsz = obj.fontsz_entry,
                        txt_col = obj.txt_col_toolbar,
                        txt = 'Loop',
                        state = data.it[1].loop==1,
                        state_col = 'green',
                        func =  function()
                                  for i = 1, #data.it do                                    
                                    SetMediaItemInfo_Value( data.it[i].ptr_item, 'B_LOOPSRC', math.abs(data.it[1].loop-1))
                                    UpdateItemInProject( data.it[i].ptr_item )                                
                                  end
                                  redraw = 1                              
                                end}
    return w
  end 
  --------------------------------------------------------------
  function Widgets_Item_buttons_srcreverse(data, obj, mouse, x_offs, y_offs, frame_a)
    local w = 50*obj.entry_ratio
    obj.b.obj_srcreverse = {  x = x_offs,
                        y = obj.offs+y_offs ,
                        w = w,
                        h = obj.entry_h,
                        frame_a = frame_a,
                        txt_a = obj.txt_a,
                        fontsz = obj.fontsz_entry,
                        txt_col = obj.txt_col_toolbar,
                        txt = 'Reverse',
                        state = data.it[1].src_reverse,
                        state_col = 'green',
                        func =  function()
                                  for i = 1, #data.it do                                    
                                    local retval, section, start, length, fade, reverse  = BR_GetMediaSourceProperties( data.it[i].ptr_take )
                                    BR_SetMediaSourceProperties( data.it[i].ptr_take, section, start, length, fade, not data.it[1].src_reverse )                            
                                  end
                                  Action(40441) --Peaks: Rebuild peaks for selected items 
                                  redraw = 1                              
                                end}
    return w
  end   
    
  
  --------------------------------------------------------------
  function Widgets_Item_buttons_preservepitch(data, obj, mouse, x_offs, y_offs, frame_a)
    local w = 90*obj.entry_ratio
    obj.b.obj_preservepitch = {  x = x_offs,
                        y = obj.offs+y_offs ,
                        w = w,
                        h = obj.entry_h,
                        frame_a = frame_a,
                        txt_a = obj.txt_a,
                        fontsz = obj.fontsz_entry,
                        txt_col = obj.txt_col_toolbar,
                        txt = 'Preserve Pitch',
                        state = data.it[1].preservepitch==1,
                        state_col = 'green',
                        func =  function()
                                  for i = 1, #data.it do
                                    SetMediaItemTakeInfo_Value( data.it[i].ptr_take, 'B_PPITCH', math.abs(data.it[1].preservepitch-1))
                                    UpdateItemInProject( data.it[i].ptr_item )                                
                                  end
                                  redraw = 1                              
                                end}
    return w
  end  
  
  --------------------------------------------------------------
  function Widgets_Item_buttons_mute(data, obj, mouse, x_offs, y_offs, frame_a)
    local w = 40*obj.entry_ratio
    obj.b.obj_itmute = {  x = x_offs,
                        y = obj.offs+y_offs ,
                        w = w,
                        h = obj.entry_h,
                        frame_a = frame_a,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_toolbar,
                        txt = 'Mute',
                        fontsz = obj.fontsz_entry,
                        state = data.it[1].mute==1,
                        state_col = 'red',
                        func =  function()
                                  for i = 1, #data.it do
                                    SetMediaItemInfo_Value( data.it[i].ptr_item, 'B_MUTE', math.abs(data.it[1].mute-1))
                                    UpdateItemInProject( data.it[i].ptr_item )                                
                                  end
                                  redraw = 1                              
                                end}
    return w
  end
  --------------------------------------------------------------
  function Widgets_Item_buttons_chanmode(data, obj, mouse, x_offs, y_offs, frame_a)
    local w = 100*obj.entry_ratio
    local txt = '-'
    if data.it[1].chanmode == 0 then 
      txt = 'ChMode: Norm'
     elseif data.it[1].chanmode == 1 then 
      txt = 'ChMode: Rev'     
     elseif data.it[1].chanmode == 2 then 
      txt = 'ChMode: L+R'
     elseif data.it[1].chanmode == 3 then 
      txt = 'ChMode: L'   
     elseif data.it[1].chanmode == 4 then 
      txt = 'ChMode: R'                     
    end
    obj.b.obj_itchanmode = {  x = x_offs,
                        y = obj.offs+y_offs ,
                        w = w,
                        h = obj.entry_h,
                        frame_a = frame_a,
                        txt_a = obj.txt_a,
                        fontsz = obj.fontsz_entry,
                        txt_col = obj.txt_col_toolbar,
                        txt = txt,
                        func =  function()
                                                    
                                  Menu(mouse, {
                                          {str = 'Channel mode: Normal',
                                          func = function() Apply_Item_ChanMode(data, 0) end},
                                          {str = 'Channel mode: Reverse',
                                          func = function() Apply_Item_ChanMode(data, 1) end},
                                          {str = 'Channel mode: Downmix',
                                          func = function() Apply_Item_ChanMode(data, 2) end},
                                          {str = 'Channel mode: Left',
                                          func = function() Apply_Item_ChanMode(data, 3) end},
                                          {str = 'Channel mode: Right',
                                          func = function() Apply_Item_ChanMode(data, 4) end},                                                                                                                                                                                                               
                                         
                                        })
                                                              
                                end
                          }
    return w
  end
  -------------------------------------------------------------- 
  function Apply_Item_ChanMode(data, app_val)
    for i = 1, #data.it do
      SetMediaItemTakeInfo_Value( data.it[i].ptr_take, 'I_CHANMODE', app_val)
      UpdateItemInProject( data.it[i].ptr_item )                                
    end
    redraw = 1 
  end




  function Widgets_Item_color(data, obj, mouse, x_offs, widgets, conf, y_offs)    -- generate position controls 
    local col_w = 20*conf.scaling
    if x_offs + col_w > obj.persist_margin then return end 
    if not data.it[1].col then return end
    local a = 0.5
    if data.it[1].col == 0 then a = 0.35 end
    obj.b.obj_itcolor = { x = x_offs,
                        y = y_offs ,
                        w = col_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        state = data.it[1].col ~= 0,
                        state_col = data.it[1].col,
                        state_a = a,
                        func = function() Apply_ItemCol(data, conf) end} 
    if conf.dock_orientation == 0 then             
     obj.b.obj_itcolor_back = { x =  x_offs,
                        y = obj.entry_h+y_offs ,
                        w = col_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        state = data.it[1].col ~= 0,
                        state_col = data.it[1].col,
                        state_a = a,
                        func = function() Apply_ItemCol(data, conf) end
                        } 
     else
      obj.b.obj_itcolor.w = gfx.w         
    end                      
    return col_w                       
  end  
  
  function Apply_ItemCol(data, conf)
    if conf.use_custom_color_editor ~= '' then  
      Action(conf.use_custom_color_editor)
     else
      local retval, colorOut = GR_SelectColor( '' )
      if retval == 0 then return end
      for i = 1, #data.it do
        local it= data.it[i].ptr_item
        SetMediaItemInfo_Value( it, 'I_CUSTOMCOLOR', colorOut )
      end
    end
  end




  --------------------------------------------------------------
  function Widgets_Item_rate(data, obj, mouse, x_offs, widgets, conf, y_offs)    -- generate position controls 
    if x_offs + obj.entry_w2 > obj.persist_margin then return x_offs end 
    obj.b.obj_itrate = { x = x_offs,
                        y =y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'Playrate'} 
    obj.b.obj_itrate_back = { x =  x_offs,
                        y = obj.entry_h+y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
 if conf.dock_orientation == 1 then
   obj.b.obj_itrate.w = obj.entry_w2/2
   obj.b.obj_itrate_back.x= obj.entry_w2/2
   obj.b.obj_itrate_back.y = y_offs
   obj.b.obj_itrate_back.w = obj.entry_w2/2
   obj.b.obj_itrate_back.frame_a = obj.frame_a_head
 end                         
                        
      local rate_str = data.it[1].rate_format
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = MPL_GetTableOfCtrlValues2(rate_str,4),
                        table_key='rate_ctrl',
                        x_offs= obj.b.obj_itrate_back.x,  
                        y = obj.b.obj_itrate_back.y ,
                        w_com=obj.b.obj_itrate_back.w,--obj.entry_w2,
                        src_val=data.it,
                        src_val_key= 'rate',
                        modify_func= MPL_ModifyFloatVal,
                        app_func= Apply_Item_Rate,                         
                        mouse_scale= obj.mouse_scal_rate,
                        pow_tolerance = -4,
                        default_val=1,
                        onRelease_ActName = data.scr_title..': Change item properties',
                        use_mouse_drag_xAxis = data.always_use_x_axis==1,
                        --dont_draw_val = true
                        })                            
    return obj.entry_w2                         
  end  
  function Apply_Item_Rate(data, obj, t_out_values, butkey, out_str_toparse)
    if not out_str_toparse then    
      for i = 1, #t_out_values do
        local val = lim(t_out_values[i], 0.1, 10)
        SetMediaItemTakeInfo_Value( data.it[i].ptr_take, 'D_PLAYRATE', val )
        SetMediaItemInfo_Value( data.it[i].ptr_item, 'D_LENGTH', data.it[i].item_len * (data.it[1].rate/val))
        
        UpdateItemInProject( data.it[i].ptr_item )                                
      end
      local new_str_t = MPL_GetTableOfCtrlValues2(lim(t_out_values[1], 0.1, 10),4)
      if new_str_t then 
        for i = 1, #new_str_t do
          obj.b[butkey..i].txt = new_str_t[i]
        end
      end
     else
      -- nudge values from first item
      local diff = data.it[1].rate - out_str_toparse
      for i = 1, #t_out_values do
        SetMediaItemTakeInfo_Value( data.it[i].ptr_take, 'D_PLAYRATE', lim(t_out_values[i] - diff, 0.1, 10) )
        UpdateItemInProject( data.it[i].ptr_item )                                
      end
      redraw = 2   
    end
  end    
  -------------------------------------------------------------- 
  --------------------------------------------------------------
  function Widgets_Item_buttons_timebase(data, obj, mouse, x_offs, y_offs, frame_a)
    local w = 100*obj.entry_ratio
    local txt = '-'
    --tbmode
    --tbmode_auto
    if data.it[1].tbmode == -1 then 
      txt = 'TB:default'
     elseif data.it[1].tbmode == 1 and data.it[1].tbmode_auto == 1 then 
      txt = 'TB:beats (auto)'     
     elseif data.it[1].tbmode == 1 then 
      txt = 'TB: beats'
     elseif data.it[1].tbmode == 2 then 
      txt = 'TB: beats(pos. only)'   
     elseif data.it[1].tbmode == 0 then 
      txt = 'TB: time'                     
    end
    obj.b.obj_timebase = {  x = x_offs,
                        y = obj.offs+y_offs ,
                        w = w,
                        h = obj.entry_h,
                        frame_a = frame_a,
                        txt_a = obj.txt_a,
                        fontsz = obj.fontsz_entry,
                        txt_col = obj.txt_col_toolbar,
                        txt = txt,
                        func =  function() 
                                  if data.it[1].tbmode == 0 then 
                                    Apply_Item_timebase(data, 2, 0) -- time >> beats pos only
                                    elseif data.it[1].tbmode == 2 and data.it[1].tbmode_auto == 0 then 
                                      Apply_Item_timebase(data, 1, 0) -- beats pos only >> beats all
                                    elseif data.it[1].tbmode == 1 and data.it[1].tbmode_auto == 0 then 
                                      Apply_Item_timebase(data, 1, 1) -- beats all >> beats all auto
                                    elseif data.it[1].tbmode == 1 and data.it[1].tbmode_auto == 1 then 
                                      Apply_Item_timebase(data,0, 0) -- beats all auto >> time
                                    elseif data.it[1].tbmode == -1 then 
                                      Apply_Item_timebase(data, 2, 0) -- default >> beats pos only
                                  end
                                end,
                        func_R =  function()
                                    Apply_Item_timebase(data, -1) -- default 
                                  end                                
                          }
    return w
  end
  -------------------------------------------------------------- 
  function Apply_Item_timebase(data, tb, tb_auto)
    for i = 1, #data.it do
      SetMediaItemInfo_Value( data.it[i].ptr_item, 'C_BEATATTACHMODE', tb)
      if tb_auto then SetMediaItemInfo_Value( data.it[i].ptr_item, 'C_AUTOSTRETCH', tb_auto) end
      UpdateItemInProject( data.it[i].ptr_item )                                
    end
    redraw = 1 
  end

  --------------------------------------------------------------   
  function Widgets_Item_itemcomlen(data, obj, mouse, x_offs, widgets, conf, y_offs) -- generate snap_offs controls  
    if x_offs + obj.entry_w2 > obj.persist_margin then return x_offs end 
    obj.b.obj_itemcomlen = { x = x_offs,
                       y =y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'Com length'} 
    obj.b.obj_itemcomlen_back = { x =  x_offs,
                        y = obj.entry_h+y_offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = data.it_comlen_format,
                        ignore_mouse = true}  
      if conf.dock_orientation == 1 then
        obj.b.obj_itemcomlen.w = obj.entry_w2/2
        obj.b.obj_itemcomlen_back.x= obj.entry_w2/2
        obj.b.obj_itemcomlen_back.y = y_offs
        obj.b.obj_itemcomlen_back.w = obj.entry_w2/2
        obj.b.obj_itemcomlen_back.frame_a = obj.frame_a_head
      end                        
    return obj.entry_w2,obj.entry_h                        
  end
