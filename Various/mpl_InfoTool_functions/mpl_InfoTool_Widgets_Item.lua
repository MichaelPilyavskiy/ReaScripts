-- @description InfoTool_Widgets_Item
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex


  -- Item wigets for mpl_InfoTool
  
  ---------------------------------------------------
  function Obj_UpdateItem(data, obj, mouse, widgets)
    obj.b.obj_name = { x = obj.offs,
                        y = obj.offs *2 +obj.entry_h,
                        w = obj.entry_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt_a = obj.txt_a,
                        txt = data.it[1].name,
                        fontsz = obj.fontsz_entry,
                        func_DC = 
                          function ()
                            if data.it[1].name then
                              local retval0, retvals_csv = GetUserInputs( 'Rename', 1, 'New Name, extrawidth=220', data.it[1].name )
                              if not retval0 then return end
                              if data.it[1].obj_type_int == 0  or data.it[1].obj_type_int == 1 then
                                if data.it[1].ptr_take and ValidatePtr2(0, data.it[1].ptr_take,'MediaItem_Take*') then
                                  GetSetMediaItemTakeInfo_String( data.it[1].ptr_take, 'P_NAME', retvals_csv,true )
                                  redraw = 1
                                end
                              end
                            end
                          end} 
    local x_offs = obj.offs + obj.entry_w 
    
    
    
  --------------------------------------------------------------  
    local tp_ID = data.obj_type_int
    local widg_key = widgets.types_t[tp_ID+1]
    if widgets[widg_key] then      
      for i = 1, #widgets[widg_key] do
        local key = widgets[widg_key][i]
        if _G['Widgets_Item_'..key] then
          _G['Widgets_Item_'..key](data, obj, mouse, modify_func, x_offs) 
          x_offs = x_offs + obj.offs + obj.entry_w2
        end
      end  
    end
  end
  -------------------------------------------------------------- 







  --------------------------------------------------------------
  function Widgets_Item_position(data, obj, mouse, modify_func, x_offs)    -- generate position controls 
    obj.b.obj_pos = { x = x_offs,
                        y = obj.offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'Position'} 
    obj.b.obj_pos_back = { x =  x_offs,
                        y = obj.offs *2 +obj.entry_h ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
                        
                        
      local pos_str = data.it[1].item_pos_format
      Obj_GenerateCtrl( data,obj, mouse,
                         MPL_GetTableOfCtrlValues(pos_str), 
                        'position_ctrl',
                         x_offs, obj.entry_w2,
                         data.it,
                         'item_pos',
                         MPL_ModifyTimeVal,
                         t_out_values,
                         Apply_Item_Pos,
                         true)  -- positive_only
  end  
  function Apply_Item_Pos(data, obj, t_out_values, butkey, out_str_toparse)
    if not out_str_toparse then    
      for i = 1, #t_out_values do
        SetMediaItemInfo_Value( data.it[i].ptr_item, 'D_POSITION', t_out_values[i] )
        UpdateItemInProject( data.it[i].ptr_item )                                
      end
      local new_str = format_timestr_pos( t_out_values[1], '', -1 ) 
      local new_str_t = MPL_GetTableOfCtrlValues(new_str)
      for i = 1, #new_str_t do
        obj.b[butkey..i].txt = new_str_t[i]
      end
     else
      -- nudge values from first item
      local out_val = parse_timestr_pos(out_str_toparse,-1) 
      local diff = out_val - data.it[1].item_pos
      for i = 1, #t_out_values do
        SetMediaItemInfo_Value( data.it[i].ptr_item, 'D_POSITION', t_out_values[i] + diff )
        UpdateItemInProject( data.it[i].ptr_item )                                
      end
      redraw = 2   
    end
  end  
  -------------------------------------------------------------- 







  --------------------------------------------------------------   
  function Widgets_Item_snap(data, obj, mouse, modify_func, x_offs) -- generate snap_offs controls  
    obj.b.obj_snap_offs = { x = x_offs,
                        y = obj.offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'Snap'} 
    obj.b.obj_snap_offs_back = { x =  x_offs,
                        y = obj.offs *2 +obj.entry_h ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
                
      local snap_offs_str = data.it[1].snap_offs_format
      Obj_GenerateCtrl( data,obj,  mouse,
                        MPL_GetTableOfCtrlValues(snap_offs_str),
                        'snap_offs_ctrl',
                         x_offs,  obj.entry_w2,
                         data.it,
                         'snap_offs',
                         MPL_ModifyTimeVal,
                         t_out_values,
                         Apply_Item_SnapOffs,                         
                         true)    -- positive_only
  end
  
  function Apply_Item_SnapOffs(data, obj, t_out_values, butkey, out_str_toparse)
    if not out_str_toparse then    
      for i = 1, #t_out_values do
        SetMediaItemInfo_Value( data.it[i].ptr_item, 'D_SNAPOFFSET', t_out_values[i] )
        UpdateItemInProject( data.it[i].ptr_item )                                
      end
      local new_str = format_timestr_pos( t_out_values[1], '', -1 ) 
      local new_str_t = MPL_GetTableOfCtrlValues(new_str)
      for i = 1, #new_str_t do
        obj.b[butkey..i].txt = new_str_t[i]
      end
     else
      -- directly set value from first item
      local out_val = parse_timestr_pos(out_str_toparse,-1) 
      for i = 1, #t_out_values do
        SetMediaItemInfo_Value( data.it[i].ptr_item, 'D_SNAPOFFSET', out_val )
        UpdateItemInProject( data.it[i].ptr_item )                                
      end   
      redraw = 2   
    end
  end  
  -------------------------------------------------------------- 







  --------------------------------------------------------------   
  function Widgets_Item_length(data, obj, mouse, modify_func, x_offs) -- generate snap_offs controls  
    obj.b.obj_len = { x = x_offs,
                        y = obj.offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'Length'} 
    obj.b.obj_len_back = { x =  x_offs,
                        y = obj.offs *2 +obj.entry_h ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
                
      local len_str = data.it[1].item_len_format
      Obj_GenerateCtrl( data, obj, mouse,
                        MPL_GetTableOfCtrlValues(len_str),
                        'len_ctrl',
                         x_offs,  obj.entry_w2,
                         data.it,
                         'item_len',
                         MPL_ModifyTimeVal,
                         t_out_values,
                         Apply_Item_Length,                         
                         true)    -- positive_only
  end
  
  function Apply_Item_Length(data, obj, t_out_values, butkey, out_str_toparse)
    if not out_str_toparse then    
      for i = 1, #t_out_values do
        SetMediaItemInfo_Value( data.it[i].ptr_item, 'D_LENGTH', t_out_values[i] )
        UpdateItemInProject( data.it[i].ptr_item )                                
      end
      local new_str = format_timestr_len( t_out_values[1],'', 1, -1 ) 
      local new_str_t = MPL_GetTableOfCtrlValues(new_str)
      for i = 1, #new_str_t do
        obj.b[butkey..i].txt = new_str_t[i]
      end
     else
      -- nudge values from first item
      local out_val = parse_timestr_len(out_str_toparse,1,-1) 
      local diff = data.it[1].item_len - out_val
      for i = 1, #t_out_values do
        SetMediaItemInfo_Value( data.it[i].ptr_item, 'D_LENGTH', t_out_values[i] - diff )
        UpdateItemInProject( data.it[i].ptr_item )                                
      end
      redraw = 2   
    end
  end  
  -------------------------------------------------------------- 







  --------------------------------------------------------------
  function Widgets_Item_offset(data, obj, mouse, modify_func, x_offs)    -- generate position controls 
    obj.b.obj_start_offs = { x = x_offs,
                        y = obj.offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'Offset'} 
    obj.b.obj_start_offs_back = { x =  x_offs,
                        y = obj.offs *2 +obj.entry_h ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
                        
                        
      local start_offs_str = data.it[1].start_offs_format
      Obj_GenerateCtrl( data, obj, mouse,
                         MPL_GetTableOfCtrlValues(start_offs_str), 
                        'start_offs_ctrl',
                         x_offs, obj.entry_w2,
                         data.it,
                         'start_offs',
                         MPL_ModifyTimeVal,
                         t_out_values,
                         Apply_Item_Offset,
                         false)  -- positive_only
  end  
  function Apply_Item_Offset(data, obj, t_out_values, butkey, out_str_toparse)
    if not out_str_toparse then    
      for i = 1, #t_out_values do
        SetMediaItemTakeInfo_Value( data.it[i].ptr_take, 'D_STARTOFFS', t_out_values[i] )
        UpdateItemInProject( data.it[i].ptr_item )                                
      end
      local new_str = format_timestr_len( t_out_values[1], '',1, -1 ) 
      local new_str_t = MPL_GetTableOfCtrlValues(new_str)
      for i = 1, #new_str_t do
        obj.b[butkey..i].txt = new_str_t[i]
      end
     else
      -- nudge values from first item
      local out_val = parse_timestr_len(out_str_toparse,1,-1) 
      local diff = data.it[1].start_offs - out_val
      for i = 1, #t_out_values do
        SetMediaItemTakeInfo_Value( data.it[i].ptr_take, 'D_STARTOFFS', t_out_values[i] - diff )
        UpdateItemInProject( data.it[i].ptr_item )                                
      end
      redraw = 2   
    end
  end    
  --------------------------------------------------------------  
  
  
