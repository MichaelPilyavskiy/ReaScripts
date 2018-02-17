-- @description InfoTool_Widgets_Track
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex


  -- track wigets for mpl_InfoTool
  
  ---------------------------------------------------
  function Obj_UpdateTrack(data, obj, mouse, widgets)
    obj.b.obj_name = { x = obj.menu_b_rect_side + obj.offs,
                        y = obj.offs *2 +obj.entry_h,
                        w = obj.entry_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt_a = obj.txt_a,
                        txt = data.tr[1].name,
                        fontsz = obj.fontsz_entry,
                        func_DC = 
                          function ()
                            if data.tr[1].name_proj then
                              local retval0, retvals_csv = GetUserInputs( 'Rename', 1, 'New Name, extrawidth=220', data.tr[1].name_proj )
                              if not retval0 then return end
                              if data.tr[1].ptr and ValidatePtr2(0, data.tr[1].ptr,'MediaTrack*') then
                                  GetSetMediaTrackInfo_String( data.tr[1].ptr, 'P_NAME', retvals_csv, true )
                                  redraw = 1
                              end
                            end
                          end} 
    local x_offs = obj.menu_b_rect_side + obj.offs + obj.entry_w 
    
    
    
  --------------------------------------------------------------  
    local tp_ID = data.obj_type_int
    local widg_key = widgets.types_t[tp_ID+1] -- get key of current mapped table
    if widgets[widg_key] then      
      for i = 1, #widgets[widg_key] do
        local key = widgets[widg_key][i]
        if _G['Widgets_Track_'..key] then
            local ret = _G['Widgets_Track_'..key](data, obj, mouse, x_offs, widgets) 
            if ret then x_offs = x_offs + obj.offs + ret end
        end
      end  
    end
  end
  -------------------------------------------------------------- 








  -------------------------------------------------------------- 
  function Widgets_Track_pan(data, obj, mouse, x_offs)
    local pan_w = 60
    if x_offs + pan_w > obj.persist_margin then return x_offs end 
    obj.b.obj_tr_pan = { x = x_offs,
                        y = obj.offs ,
                        w = pan_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'Pan'} 
    obj.b.obj_tr_pan_back = { x =  x_offs,
                        y = obj.offs *2 +obj.entry_h ,
                        w = pan_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
                
      local tr_pan_str = data.tr_pan_format
      Obj_GenerateCtrl( data,obj,  mouse,
                        {data.tr[1].pan_format},
                        'tr_pan_ctrl',
                         x_offs,  pan_w,--obj.entry_w2,
                         data.tr,
                         'pan',
                         MPL_ModifyFloatVal,
                         Apply_Track_pan,                         
                         obj.mouse_scal_pan,
                         true) -- use_mouse_drag_xAxis
    return pan_w--obj.entry_w2                         
  end
  
  function Apply_Track_pan(data, obj, t_out_values, butkey, out_str_toparse)
    if not out_str_toparse then    
      for i = 1, #t_out_values do        
        local out_val = math_q(t_out_values[i]*100)/100
        SetMediaTrackInfo_Value( data.tr[i].ptr, 'D_PAN', lim(out_val,-1,1) )   
      end
      t_out_values[1] = lim(t_out_values[1], -1,1)
      local out_val = math_q(t_out_values[1]*100)/100
      local new_str = MPL_FormatPan(out_val)
      obj.b[butkey..1].txt = new_str
      redraw = 1
     else
      local out_val = 0
      if out_str_toparse:lower():match('r') then side = 1 
          elseif out_str_toparse:lower():match('l') then side = -1 
          elseif out_str_toparse:lower():match('c') then side = 0
          else side = 0
      end 
      local val = out_str_toparse:match('%d+')
      if not val then return end
      out_val = side * val/100
      --[[nudge
        local diff = data.it[1].pan - out_val
        for i = 1, #t_out_values do
          SetMediaItemTakeInfo_Value( data.it[i].ptr_take, 'D_PAN', lim(t_out_values[i] - diff,-1,1) )
          UpdateItemInProject( data.it[i].ptr_item )                                
        end   ]]
      --set
        for i = 1, #t_out_values do
          local out_val = math_q(out_val*100)/100
          SetMediaTrackInfo_Value( data.tr[i].ptr, 'D_PAN', lim(out_val,-1,1) )    
        end     
      redraw = 2   
    end
  end  
  -------------------------------------------------------------- 






  --------------------------------------------------------------   
  function Widgets_Track_vol(data, obj, mouse, x_offs) -- generate snap_offs controls 
    local vol_w = 60 
    if x_offs + vol_w > obj.persist_margin then return x_offs end 
    obj.b.obj_trvol = { x = x_offs,
                        y = obj.offs ,
                        w = vol_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'Volume'} 
    obj.b.obj_trvol_back = { x =  x_offs,
                        y = obj.offs *2 +obj.entry_h ,
                        w = vol_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt ='',
                        fontsz = obj.fontsz_entry,
                        ignore_mouse = true}  
                
      local vol_str = data.tr[1].vol_format
      Obj_GenerateCtrl( data,obj,  mouse,
                        MPL_GetTableOfCtrlValues2(data.tr[1].vol_format),
                        'trvol_ctrl',
                         x_offs,  vol_w,--obj.entry_w2,
                         data.tr,
                         'vol',
                         MPL_ModifyFloatVal,
                         Apply_Track_vol,                         
                         obj.mouse_scal_vol,               -- mouse scaling
                         nil,
                         true)                      
    return vol_w--obj.entry_w2                         
  end
  
  function Apply_Track_vol(data, obj, t_out_values, butkey, out_str_toparse)
    if not out_str_toparse then 
      for i = 1, #t_out_values do
        SetMediaTrackInfo_Value( data.tr[i].ptr, 'D_VOL', math.max(0,t_out_values[i] ))
      end
      local new_str = string.format("%.2f", t_out_values[1])
      local new_str_t = MPL_GetTableOfCtrlValues2(new_str)
      if new_str_t then 
        for i = 1, #new_str_t do
          obj.b[butkey..i].txt = ''--new_str_t[i]
        end
        obj.b.obj_trvol_back.txt = dBFromReaperVal(t_out_values[1])..'dB'
      end
     else
      local out_val = tonumber(out_str_toparse) 
      out_val = ReaperValfromdB(out_val)
      --[[nudge
        local diff = data.it[1].vol - out_val
        for i = 1, #t_out_values do
          SetMediaItemInfo_Value( data.it[i].ptr_item, 'D_VOL', math.max(0,t_out_values[i] - diff ))
          UpdateItemInProject( data.it[i].ptr_item )                                
        end   ]]
      --set
        for i = 1, #t_out_values do
          SetMediaTrackInfo_Value( data.tr[i].ptr, 'D_VOL', math.max(0,out_val )) 
        end     
      redraw = 2   
    end
  end  
  -------------------------------------------------------------- 







  --------------------------------------------------------------   
  function Widgets_Track_fxlist(data, obj, mouse, x_offs)
    if not data.tr[1].fx_names or #data.tr[1].fx_names < 1 then return end
    local fxlist_w = 130 
    local fxlist_state = 20
    if x_offs + fxlist_w > obj.persist_margin then return x_offs end 
    local fxid = lim(math.modf(data.curent_trFXID),1, #data.tr[1].fx_names)
    obj.b.obj_fxlist = { x = x_offs,
                        y = obj.offs ,
                        w = fxlist_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = '',
                        func_wheel =  function() Apply_TrackFXListChange(data, mouse.wheel_trig) end}
                            --    func = function () Apply_TrackFXListChange_floatFX(data, mouse, data.tr[1].fx_names[fxid].is_enabled) end              }   
    obj.b.obj_fxlist_back = { x =  x_offs,
                        y = obj.offs *2 +obj.entry_h ,
                        w = fxlist_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt ='',
                        fontsz = obj.fontsz_entry,
                        func_wheel =  function() Apply_TrackFXListChange(data, mouse.wheel_trig) end} 
                          --      func = function () Apply_TrackFXListChange_floatFX(data, mouse, data.tr[1].fx_names[fxid].is_enabled) end              }                           
    
    local h_entr= obj.fontsz_entry
    for i = 1, #data.tr[1].fx_names do
      local txt_a = 0.3
      if data.curent_trFXID and i == lim(math.modf(data.curent_trFXID),1, #data.tr[1].fx_names) then txt_a = obj.txt_a end
      if data.curent_trFXID then i_shift = lim(math.modf(data.curent_trFXID),1, #data.tr[1].fx_names)-1 else  i_shift= 0 end
      local txt_col 
      if not data.tr[1].fx_names[i].is_enabled then txt_col = 'red' end
      obj.b['obj_fxlist'..i] = { x =  x_offs+fxlist_state,
                                y = obj.offs *2 + obj.entry_h/2 + h_entr*(i-i_shift-1) ,
                                w = fxlist_w-fxlist_state,--obj.entry_w2,
                                h = h_entr,
                                frame_a = 0,
                                txt_a = txt_a,
                                txt_col = txt_col,
                                aligh_txt = 8,
                                txt =data.tr[1].fx_names[i].name,
                                fontsz = obj.fontsz_entry,
                                func_wheel =  function() Apply_TrackFXListChange(data, mouse.wheel_trig) end, 
                                func = function () Apply_TrackFXListChange_floatFX(data, mouse, data.tr[1].fx_names[i].is_enabled) end              }   
      local txt,txt_col
      if not data.tr[1].fx_names[i].is_enabled then 
        txt ='X' 
        txt_col = 'red'
       else 
        txt ='' 
        txt_col = obj.txt_col_header
      end     
        obj.b['obj_fxlist'..i..'state'] = { x =  x_offs,
                                y = obj.offs *2 + obj.entry_h/2 + h_entr*(i-i_shift-1) ,
                                w = fxlist_state,--obj.entry_w2,
                                h = h_entr,
                                frame_a = 0,
                                txt_a = txt_a*0.7,
                                txt_col = txt_col,
                                txt =txt,
                                fontsz = obj.fontsz_entry,
                                func_wheel =  function() Apply_TrackFXListChange(data, mouse.wheel_trig) end, 
                                func = function () Apply_TrackFXListChange_floatFX(data, mouse, data.tr[1].fx_names[i].is_enabled) end              }           
    end
    return fxlist_w               
  end

  function Apply_TrackFXListChange(data, wheel_trig)
    local trig
    if wheel_trig > 0 then trig = 0.35 elseif wheel_trig <0 then trig = -0.35 else return  end                                                             
    data.curent_trFXID = lim( data.curent_trFXID -trig, 1 ,#data.tr[1].fx_names)
    redraw = 2  
  end
  function Apply_TrackFXListChange_floatFX(data, mouse, state)
    local fx_id = lim( math.modf(data.curent_trFXID), 1 ,#data.tr[1].fx_names) 
    if mouse.Shift then 
      TrackFX_SetEnabled( data.tr[1].ptr, fx_id-1, not state)
     else
      TrackFX_Show( data.tr[1].ptr, fx_id-1, 3 )
    end
  end
--
  
  
  --[[------------------------------------------------------------  
  fu nction Widgets_Item_buttons(data, obj, mouse, x_offs0, widgets)
    local frame_a, x_offs, y_offs
    if x_offs0 + obj.entry_w2*2 > obj.persist_margin then return x_offs0 end  -- reduce buttons when more than regular wx2
    local last_x1,last_x2 = x_offs0, x_offs0
    local tp_ID = data.obj_type_int
    local widg_key = widgets.types_t[tp_ID+1] -- get key of current mapped table
    if widgets[widg_key] and widgets[widg_key].buttons  then  
      for i = 1, #widgets[widg_key].buttons do 
        local key = widgets[widg_key].buttons[i]
        if _G['Widgets_Item_buttons_'..key] then  
          if i%2 == 1 then 
            x_offs = last_x1
            frame_a = obj.frame_a_head
            y_offs = 0
           elseif i%2 == 0 then   
            x_offs = last_x2 
            frame_a = obj.frame_a_entry
            y_offs = obj.entry_h
          end
          local next_w = _G['Widgets_Item_buttons_'..key](data, obj, mouse, x_offs, y_offs, frame_a)
          if i%2 == 1 then last_x1 = last_x1+next_w elseif i%2 == 0 then last_x2 = last_x2+next_w end
  
        end
        
      end
    end
    return math.max(last_x1,last_x2) - x_offs0
  end  
  -------------------------------------------------------------- 
  fu nction Widgets_Item_buttons_lock(data, obj, mouse, x_offs, y_offs, frame_a)
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
  fu nction Widgets_Item_buttons_mute(data, obj, mouse, x_offs, y_offs, frame_a)
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
  end]]
