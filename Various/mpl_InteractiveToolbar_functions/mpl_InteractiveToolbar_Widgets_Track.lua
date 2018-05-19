-- @description InteractiveToolbar_Widgets_Track
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex


  -- track wigets for mpl_InteractiveToolbar
  
  ---------------------------------------------------
  function Obj_UpdateTrack(data, obj, mouse, widgets, conf)
    obj.b.obj_name = { x = obj.menu_b_rect_side + obj.offs,
                        y = obj.offs *2 +obj.entry_h,
                        w = conf.GUI_contextname_w,
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
    local x_offs = obj.menu_b_rect_side + obj.offs + conf.GUI_contextname_w 
    
    
    
  --------------------------------------------------------------  
    local tp_ID = data.obj_type_int
    local widg_key = widgets.types_t[tp_ID+1] -- get key of current mapped table
    if widgets[widg_key] then      
      for i = 1, #widgets[widg_key] do
        local key = widgets[widg_key][i]
        if _G['Widgets_Track_'..key] then
            local ret = _G['Widgets_Track_'..key](data, obj, mouse, x_offs, widgets, conf) 
            if ret then x_offs = x_offs + obj.offs + ret end
        end
      end  
    end
  end
  -------------------------------------------------------------- 







  --------------------------------------------------------------  
  function Widgets_Track_buttons(data, obj, mouse, x_offs0, widgets)
    local frame_a, x_offs, y_offs
    --if x_offs0 + obj.entry_w2*2 > obj.persist_margin then return x_offs0 end  -- reduce buttons when more than regular wx2
    local last_x1,last_x2 = x_offs0, x_offs0
    local tp_ID = data.obj_type_int
    local widg_key = widgets.types_t[tp_ID+1] -- get key of current mapped table
    if widgets[widg_key] and widgets[widg_key].buttons  then  
      for i = 1, #widgets[widg_key].buttons do 
        local key = widgets[widg_key].buttons[i]
        if _G['Widgets_Track_buttons_'..key] then  
          if i%2 == 1 then 
            x_offs = last_x1
            frame_a = obj.frame_a_head
            y_offs = 0
           elseif i%2 == 0 then   
            x_offs = last_x2 
            frame_a = obj.frame_a_entry
            y_offs = obj.entry_h
          end
          local next_w = _G['Widgets_Track_buttons_'..key](data, obj, mouse, x_offs, y_offs, frame_a)
          if i%2 == 1 then last_x1 = last_x1+next_w elseif i%2 == 0 then last_x2 = last_x2+next_w end
        end
        
      end
    end
    return math.max(last_x1,last_x2) - x_offs0
  end 
  --------------------------------------------------------------   
  
  
  
  
  
  
  
  
  --------------------------------------------------------------
  function Widgets_Track_buttons_polarity(data, obj, mouse, x_offs, y_offs, frame_a)
    local w = 50*obj.entry_ratio
    obj.b.obj_trpol = {  x = x_offs,
                        y = obj.offs+y_offs ,
                        w = w,
                        h = obj.entry_h,
                        frame_a = frame_a,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_toolbar,
                        txt = 'Ø',
                        fontsz = obj.fontsz_entry,
                        state = data.tr[1].pol==1,
                        state_col = 'green',
                        func =  function()
                                  for i = 1, #data.tr do
                                    SetMediaTrackInfo_Value( data.tr[i].ptr, 'B_PHASE', math.abs(data.tr[1].pol-1))
                                  end
                                  redraw = 1                              
                                end}
    return w
  end  
  --------------------------------------------------------------
  function Widgets_Track_buttons_parentsend(data, obj, mouse, x_offs, y_offs, frame_a)
    local w = 50*obj.entry_ratio
    obj.b.obj_trparsend = {  x = x_offs,
                        y = obj.offs+y_offs ,
                        w = w,
                        h = obj.entry_h,
                        frame_a = frame_a,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_toolbar,
                        txt = 'Parent',
                        fontsz = obj.fontsz_entry,
                        state = data.tr[1].parsend==1,
                        state_col = 'green',
                        func =  function()
                                  for i = 1, #data.tr do
                                    SetMediaTrackInfo_Value( data.tr[i].ptr, 'B_MAINSEND', math.abs(data.tr[1].parsend-1))
                                  end
                                  redraw = 1                              
                                end}
    return w
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

      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = {data.tr[1].pan_format},
                        table_key='tr_pan_ctrl',
                        x_offs= x_offs,  
                        w_com=pan_w,--obj.entry_w2,
                        src_val=data.tr,
                        src_val_key= 'pan',
                        modify_func= MPL_ModifyFloatVal,
                        app_func= Apply_Track_pan,                    
                        mouse_scale= obj.mouse_scal_pan,               -- mouse scaling
                        use_mouse_drag_xAxis= true,
                        parse_pan_tags = true,
                        default_val = 0,
                        onRelease_ActName = data.scr_title..': Change track properties'})                         
    return pan_w--obj.entry_w2                         
  end
  
  function Apply_Track_pan(data, obj, t_out_values, butkey, out_str_toparse, mouse)
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
      local out_val = MPL_ParsePanVal(out_str_toparse)
      --[[nudge
        local diff = data.it[1].pan - out_val
        for i = 1, #t_out_values do
          SetMediaItemTakeInfo_Value( data.it[i].ptr_take, 'D_PAN', lim(t_out_values[i] - diff,-1,1) )
          UpdateItemInProject( data.it[i].ptr_item )                                
        end   ]]
      --set
        for i = 1, #data.tr do
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
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = {data.tr[1].vol_format},
                        table_key='trvol_ctrl',
                        x_offs= x_offs,  
                        w_com=vol_w,--obj.entry_w2,
                        src_val=data.tr,
                        src_val_key= 'vol',
                        modify_func= MPL_ModifyFloatVal,
                        app_func= Apply_Track_vol,                    
                        mouse_scale= obj.mouse_scal_vol,               -- mouse scaling
                        use_mouse_drag_xAxis = data.always_use_x_axis==1,
                        --ignore_fields= true, -- same tolerance change
                        y_offs= nil,
                        dont_draw_val = nil,
                        default_val = 1,
                        modify_wholestr = true,
                        onRelease_ActName = data.scr_title..': Change track properties'})
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
          if obj.b[butkey..i] then obj.b[butkey..i].txt = '' end--new_str_t[i]
        end
        obj.b.obj_trvol_back.txt = WDL_VAL2DB(t_out_values[1], true)..'dB'
      end
      
     else
      local out_val = ParseDbVol(out_str_toparse)
      if not out_val then return end
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




  function Widgets_Track_delay(data, obj, mouse, x_offs)    -- generate position controls 
    local del_w = 60
    if x_offs + del_w > obj.persist_margin then return x_offs end 
    obj.b.obj_trdelay = { x = x_offs,
                        y = obj.offs ,
                        w = del_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'Delay'} 
    obj.b.obj_trdelay_back = { x =  x_offs,
                        y = obj.offs *2 +obj.entry_h ,
                        w = del_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = data.tr[1].delay_format..'s',
                        fontsz = obj.fontsz_entry,
                        ignore_mouse = true}  
                        
                        
      local delay_str = data.tr[1].delay_format
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = {delay_str},
                        table_key='delay_ctrl',
                        x_offs= x_offs,  
                        w_com=del_w,
                        src_val=data.tr,
                        src_val_key= 'delay',
                        modify_func= MPL_ModifyTimeVal,
                        app_func= Apply_Track_delay,                         
                        mouse_scale= obj.mouse_scal_time,
                        default_val=0,
                        modify_wholestr = true,
                        dont_draw_val = true,
                        onRelease_ActName = data.scr_title..': Change track properties',
                        use_mouse_drag_xAxis = data.always_use_x_axis==1})                            
    return del_w                       
  end  
  function Apply_Track_delay(data, obj, t_out_values, butkey, out_str_toparse, mouse)
    if not out_str_toparse then    
      for i = 1, #t_out_values do
        local fx_pos = TrackFX_AddByName( data.tr[i].ptr, 'time_adjustment', false, 1 )
        local value = lim(0.5 + t_out_values[i] / 0.2)
        if mouse.Ctrl then value = lim(0.5 + t_out_values[1] / 0.2) end
        TrackFX_SetParamNormalized(data.tr[i].ptr, fx_pos, 0, value )
      end
      local new_str = format_timestr_len( t_out_values[1], '', 0, 3 )
      obj.b.obj_trdelay_back.txt = new_str..'s'
     else
      -- nudge values from first item
      local out_val = parse_timestr_len(out_str_toparse,0,3) 
      local diff = data.tr[1].delay - out_val
      for i = 1, #t_out_values do
        local out = t_out_values[i] - diff
        local fx_pos = TrackFX_AddByName( data.tr[i].ptr, 'time_adjustment', false, 1 )
        local value = lim(0.5 + out / 0.2)
        TrackFX_SetParamNormalized(data.tr[i].ptr, fx_pos, 0, value ) 
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
    obj.b.obj_fxlist_back1 = { x = x_offs,
                        y = obj.offs ,
                        w = fxlist_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = '',
                        func_wheel =  function() Apply_TrackFXListChange(data, mouse.wheel_trig) end}
                            --    func = function () Apply_TrackFXListChange_floatFX(data, mouse, data.tr[1].fx_names[fxid].is_enabled) end     
    obj.b.obj_fxlist_back2 = { x =  x_offs,
                        y = obj.offs *2 +obj.entry_h ,
                        w = fxlist_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt ='',
                        fontsz = obj.fontsz_entry,
                        func_wheel =  function() Apply_TrackFXListChange(data, mouse.wheel_trig) end} 
                          --      func = function () Apply_TrackFXListChange_floatFX(data, mouse, data.tr[1].fx_names[fxid].is_enabled) end  }                           
    
    local h_entr= obj.fontsz_entry
    for i = 1, #data.tr[1].fx_names do
      local txt_a = 0.2
      if data.curent_trFXID and i == lim(math.modf(data.curent_trFXID),1, #data.tr[1].fx_names) then txt_a = obj.txt_a end
      local i_shift if data.curent_trFXID then i_shift = lim(math.modf(data.curent_trFXID),1, #data.tr[1].fx_names)-1 else  i_shift= 0 end
      local txt_col = obj.txt_col_header
      if not data.tr[1].fx_names[i].is_enabled then txt_col = 'red'end
      obj.b['obj_fxlist_val'..i] = { x =  x_offs+fxlist_state,
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
        txt =i 
        txt_col = obj.txt_col_header
      end     
        obj.b['obj_fxlist_val'..i..'state'] = { x =  x_offs,
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
----------------------------------------------------------- 


  
  
  
-----------------------------------------------------------   
  function Widgets_Track_sendto(data, obj, mouse, x_offs)
    local send_but = 20
    local vol_w = 60 
    local send_w = send_but + vol_w 
    if x_offs + send_w > obj.persist_margin then return x_offs end 
    obj.b.obj_sendto_back1 = { x = x_offs,
                        y = obj.offs ,
                        w = send_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        ignore_mouse = true} 
    obj.b.obj_sendto_back2 = { x = x_offs,
                        y = obj.offs+obj.entry_h ,
                        w = send_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        ignore_mouse = true}  
    obj.b.obj_sendto_but = { x = x_offs+send_w-send_but,
                        y = obj.offs ,
                        w = send_but,--obj.entry_w2,
                        h = obj.entry_h*2,
                        frame_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = '->',
                        func = function() SendTracksTo(data, mouse) end }     
    obj.b.obj_sendto_vol = { x = x_offs,
                        y = obj.offs ,
                        w = vol_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = 0,
                        frame_rect_a = 0.1,
                        fontsz = obj.fontsz_entry,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        txt = 'SendVol',
                        ignore_mouse=true,
                        val = data.defsendvol_slider,
                        is_slider = true,
                        sider_col = obj.txt_col_entry,
                        slider_a = 0.4}  
      local svol_str = data.defsendvol_format
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = MPL_GetTableOfCtrlValues2(svol_str),
                        table_key='svol_ctrl',
                        x_offs= x_offs,  
                        w_com=vol_w,--obj.entry_w2,
                        src_val=data.defsendvol,
                        modify_func= MPL_ModifyFloatVal,
                        app_func= Apply_STrack_vol,                         
                        mouse_scale= obj.mouse_scal_vol,               -- mouse scaling
                        use_mouse_drag_xAxis= true, -- x
                        ignore_fields= true, -- same tolerance change
                        y_offs= obj.offs,
                        dont_draw_val = true,
                        default_val = tonumber(({BR_Win32_GetPrivateProfileString( 'REAPER', 'defsendvol', '0',  get_ini_file() )})[2])})
    obj.b.obj_sendto_pan = { x = x_offs,
                        y = obj.offs +obj.entry_h,
                        w = vol_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = 0,
                        frame_rect_a = 0.1,
                        fontsz = obj.fontsz_entry,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        txt = 'SendPan',
                        ignore_mouse=true,
                        val = data.defsendpan_slider,
                        is_slider = true,
                        sider_col = obj.txt_col_entry,
                        slider_a = 0.4,
                        centered_slider = true}                         
      local span_str = data.defsendpan_format
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = MPL_GetTableOfCtrlValues2(span_str),
                        table_key='span_ctrl',
                        x_offs= x_offs,  
                        w_com=vol_w,--obj.entry_w2,
                        src_val=data.defsendpan,
                        --src_val_key= '',
                        modify_func= MPL_ModifyFloatVal,
                        app_func= Apply_STrack_pan,                         
                        mouse_scale= obj.mouse_scal_pan,               -- mouse scaling
                        use_mouse_drag_xAxis= true, -- x
                        ignore_fields= true, -- same tolerance change
                        y_offs= obj.offs+obj.entry_h,
                        dont_draw_val = true,
                        default_val = 0})
    return send_w 
  end
  function Apply_STrack_vol(data, obj, t_out_values, butkey, out_str_toparse)
    if not out_str_toparse then 
      data.defsendvol = lim(t_out_values,-1,1)
      local new_str = string.format("%.2f", t_out_values)
      local new_str_t = MPL_GetTableOfCtrlValues2(new_str)
      if new_str_t then 
        for i = 1, #new_str_t do
          obj.b[butkey..i].txt = ''--new_str_t[i]
        end
        obj.b.obj_sendto_vol.txt = dBFromReaperVal(t_out_values)..'dB'
      end
      
      local dBval = dBFromReaperVal(data.defsendvol)
      if not tonumber(dBval) then dBval = -math.huge end
      local real = reaper.DB2SLIDER(dBval )/1000
      data.defsendvol_slider = real
      obj.b.obj_sendto_vol.val = real
      
      redraw =  2 
     else
      local out_val = tonumber(out_str_toparse) 
      out_val = ReaperValfromdB(out_val)
      out_val = math.max(0,out_val) 
      data.defsendvol =out_val  
      redraw = 2   
    end
  end  
  function Apply_STrack_pan(data, obj, t_out_values, butkey, out_str_toparse, mouse)
    if not out_str_toparse then    
      
      local out_val = lim(t_out_values,-1,1) 
      data.defsendpan =out_val
      local new_str = MPL_FormatPan(out_val)
      obj.b.obj_sendto_pan.txt = new_str
      data.defsendpan_format = MPL_FormatPan(data.defsendpan)
      data.defsendpan_slider = data.defsendpan
      obj.b.obj_sendto_pan.val = data.defsendpan_slider
      redraw = 2
     else
      local out_val = 0
      if out_str_toparse:lower():match('r') then side = 1 
          elseif out_str_toparse:lower():match('l') then side = -1 
          elseif out_str_toparse:lower():match('c') then side = 1
          else side = 0
      end 
      local val = out_str_toparse:match('%d+')
      if not val then return end
      local out_val = side * val/100
      out_val = lim(out_val,-1,1)
      data.defsendpan= out_val
      redraw = 2   
    end
  end  
  ---------------------------------------------------------
  function SendTracksTo(data,mouse) 
    local GUID  =GetTrackGUID( data.tr[1].ptr )
    local is_predefSend = data.PreDefinedSend_GUID[GUID] ~= nil
    local t = {
          {str = '#Send '..#data.tr..' selected track(s)'}  
        }  
        
    local unpack_prefed = ({table.unpack(SendTracksTo_CollectPreDef(data))})
    for i = 1, #unpack_prefed do table.insert(t, unpack_prefed[i]) end
    --[[local unpack_fold = ({table.unpack(SendTracksTo_CollectTopFold(data))})
    for i = 1, #unpack_fold do table.insert(t, unpack_fold[i]) end]]
    t[#t+1] ={str = '|Mark as predefined send bus',
             func = function ()
                      for i = 1, #data.tr do
                        local GUID  =GetTrackGUID( data.tr[i].ptr )
                        if not is_predefSend then 
                          data.PreDefinedSend_GUID[GUID] = 1
                          UpdatePreDefGUIDs(data)
                         else 
                          data.PreDefinedSend_GUID[GUID] = nil
                          UpdatePreDefGUIDs(data)
                        end
                      end
                    end,
             state = is_predefSend}
    Menu( mouse, t )
  end
  ---------------------------------------------------------
  function UpdatePreDefGUIDs(data)
    local str = ''
    for GUID in pairs(data.PreDefinedSend_GUID) do str = str..' '..GUID end
    SetProjExtState( 0, 'MPL_InfoTool', 'PreDefinedSend_GUID', str )
  end
  ---------------------------------------------------------
  function SendTracksTo_CollectTopFold(data)
    local out_t = {{str = '|#Top parent folders'}}
    for i = 1, CountTracks(0) do
      local tr = GetTrack(0,i-1)
      if GetTrackDepth( tr ) == 0 then
        out_t[#out_t+1] = { str =  ({GetTrackName( tr, '' )})[2],
                            func =  function() SendTracksTo_AddSend(data,tr) end}
      end
    end
    return out_t     
  end
  ---------------------------------------------------------
  function SendTracksTo_CollectPreDef(data)
    local out_t1 = {{str = '|#PreDefined sends list'}}
      for GUID in pairs(data.PreDefinedSend_GUID) do 
      local tr = BR_GetMediaTrackByGUID( 0, GUID )
      if tr then
        out_t1[#out_t1+1] = { str =  ({GetTrackName( tr, '' )})[2],
                            func =  function() SendTracksTo_AddSend(data, tr) end}
      end
    end
    return out_t1   
  end
  ---------------------------------------------------------
  function SendTracksTo_AddSend(data, dest_tr_ptr)
      if not dest_tr_ptr then return end
      local chan_id = 1
      for i = 1, #data.tr do
        local src_tr =  data.tr[i].ptr
        local ch_src = GetMediaTrackInfo_Value( src_tr, 'I_NCHAN')
        local ch_dest = GetMediaTrackInfo_Value( dest_tr_ptr, 'I_NCHAN')
        if ch_dest < ch_src then SetMediaTrackInfo_Value( dest_tr_ptr, 'I_NCHAN', ch_src) end
        
        local new_id = CreateTrackSend( src_tr, dest_tr_ptr )
        SetTrackSendInfo_Value( src_tr, 0, new_id, 'D_VOL', data.defsendvol)
        SetTrackSendInfo_Value( src_tr, 0, new_id, 'D_PAN', data.defsendpan) 
        SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_SENDMODE', data.defsendflag)
           
        SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_SRCCHAN', 0)
        --SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_DSTCHAN',5)
      end
  end
-----------------------------------------------------------   







-----------------------------------------------------------   
  function Widgets_Track_chsendmixer(data, obj, mouse, x_offs)
    if data.tr_cnt_sends + data.tr_cnt_sendsHW == 0 then return end
    local send_name_w = 120
    local ch_w = 12  
    local send_w = send_name_w + (data.tr_cnt_sends + data.tr_cnt_sendsHW) * ch_w
  
    
    if x_offs + send_w > obj.persist_margin then return x_offs end 
    obj.b.obj_sendmix_back1 = { x = x_offs,
                        y = obj.offs ,
                        w = send_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        --txt = 'test',
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        ignore_mouse = true}  
    obj.b.obj_sendmix_back2 = { x = x_offs,
                        y = obj.offs+obj.entry_h ,
                        w = send_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        ignore_mouse = true} 
                       
    local ch_w = 12
    local ch_h = math.floor(obj.entry_h*1.8)
    local ch_y = obj.offs + (obj.entry_h*2-math.floor(obj.entry_h*1.8))/2
    for i = 1, data.tr_cnt_sends + data.tr_cnt_sendsHW do
      local slider_a if data.active_context_id and data.active_context_id == i then slider_a = 0.5 else slider_a = 0.2 end
      obj.b['obj_sendmix_ch'..i] = { x = x_offs + 3 + math.floor(ch_w * (i-1)),
                        y = ch_y,
                        w = ch_w,--obj.entry_w2,
                        h = ch_h,
                        frame_a = 0,
                        frame_rect_a = 0.1,
                        fontsz = obj.fontsz_entry,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        --ignore_mouse=true,
                        val = lim(data.tr_send[i].s_vol_slider),
                        is_slider = true,
                        is_vertical_slider = true,
                        sider_col = obj.txt_col_entry,
                        slider_a =slider_a,
                        func =  function()
                                  mouse.temp_val = data.tr_send[i].s_vol
                                  mouse.temp_val2 = data.tr_send
                                end,
                          func_DC =     function() 
                                                if data.MM_doubleclick == 0 then
                                                  Apply_SendMix_vol_input(data.tr_send[data.active_context_id].s_vol_dB)
                                                 elseif data.MM_doubleclick == 1 then
                                                  Apply_SendMix_vol_reset()
                                                end
                                              end,
                          func_R =      function()
                                                if data.MM_rightclick == 0 then 
                                                  Apply_SendMix_vol_reset()
                                                 elseif data.MM_rightclick == 1 then
                                                  Apply_SendMix_vol_input(data.tr_send[data.active_context_id].s_vol_dB)
                                                end
                                              end ,                               
                        func_onRelease = function() Undo_OnStateChange( data.scr_title..': Change track send properties' ) end,
                        func_wheel = function()
                                      mouse.temp_val = data.tr_send[i].s_vol
                                      local real = Apply_SendMix_vol(data, mouse, i, mouse.wheel_trig/10, mouse.temp_val)
                                      data.active_context_id = i 
                                      data.active_context_sendmixer =      data.tr_send[i].s_name  
                                      data.active_context_sendmixer_val =      lim(real,0,4)                         
                                      redraw = 2  
                                      end,
                        func_drag = function() 
                                      if not mouse.temp_val or not data.tr[1] then return end
                                      local mouse_shift = 0
                                      if data.use_mouse_drag_xAxis == 1 then mouse_shift = -mouse.dx else mouse_shift = mouse.dy end  
                                      local real = Apply_SendMix_vol(data, mouse, i, mouse_shift/obj.mouse_scal_sendmixvol, mouse.temp_val)
                                      data.active_context_id = i 
                                      data.active_context_sendmixer =      data.tr_send[i].s_name  
                                      data.active_context_sendmixer_val =      lim(real,0,4)                         
                                      redraw = 2 
                                    end,
                        func_drag_Ctrl = function()
                                            if not mouse.temp_val2 or not data.tr[1] then return end
                                            local mouse_shift = 0
                                            if data.use_mouse_drag_xAxis == 1 then mouse_shift = -mouse.dx else mouse_shift = mouse.dy end 
                                            local real
                                            for s_id = 1, data.tr_cnt_sends + data.tr_cnt_sendsHW do
                                              local real0 = Apply_SendMix_vol(data, mouse, s_id, mouse_shift/obj.mouse_scal_sendmixvol, mouse.temp_val2[s_id].s_vol )
                                              if s_id == i then real = real0 end
                                            end       
                                            data.active_context_id = i 
                                            data.active_context_sendmixer =      data.tr_send[i].s_name  
                                            data.active_context_sendmixer_val =      lim(real,0,4)                
                                            redraw = 2                                           
                                          end,
                        func_matchonly = function()
                                            data.active_context_id = i 
                                            data.active_context_sendmixer =      data.tr_send[i].s_name  
                                            data.active_context_sendmixer_val =      data.tr_send[i].s_vol 
                                            redraw = 2
                                          end}
    end
    local mix_fields = (data.tr_cnt_sends + data.tr_cnt_sendsHW) * ch_w
    local txt = ''
    if data.active_context_sendmixer then txt = '-> '..data.active_context_sendmixer end
    obj.b.obj_sendmix_tr_name = { x = x_offs+mix_fields,
                        y = obj.offs ,
                        w = send_name_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = 0,
                        txt = txt,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        ignore_mouse = true,
                        fontsz = obj.fontsz_entry} 
    if data.active_context_sendmixer_val then

      obj.b.obj_sendmix_tr_s_vol = { x = x_offs+mix_fields,
                          y = obj.offs+obj.entry_h ,
                          w = send_name_w,
                          h = obj.entry_h,
                          frame_a = 0,
                          txt = WDL_VAL2DB(data.active_context_sendmixer_val, true)..'dB',
                          txt_a = obj.txt_a,
                          txt_col = obj.txt_col_entry,
                          --ignore_mouse = true,
                          fontsz = obj.fontsz_entry,
                          func_DC =     function() 
                                                if data.MM_doubleclick == 0 then
                                                  Apply_SendMix_vol_input(data.tr_send[data.active_context_id].s_vol_dB)
                                                 elseif data.MM_doubleclick == 1 then
                                                  Apply_SendMix_vol_reset()
                                                end
                                              end,
                          func_R =      function()
                                                if data.MM_rightclick == 0 then 
                                                  Apply_SendMix_vol_reset()
                                                 elseif data.MM_rightclick == 1 then
                                                  Apply_SendMix_vol_input(data.tr_send[data.active_context_id].s_vol_dB)
                                                end
                                              end
                      } 
    end                                                                       
    return send_w
  end
  -------------------
  function Apply_SendMix_vol_input(srcval)
    local ret, outstr = GetUserInputs( 'Edit', 1, '', srcval )
    if not ret then return end
    local out_val = ParseDbVol(outstr)
    if not data.tr[1] or not data.active_context_id or not out_val then return end
    SetTrackSendInfo_Value( data.tr[1].ptr, 0, data.active_context_id-1-data.tr_cnt_sendsHW, 'D_VOL', out_val )
    data.active_context_sendmixer_val = out_val
    redraw = 2   
  end
  -------------------
  function Apply_SendMix_vol_reset()
    if not data.tr[1] or not data.active_context_id then return end
    SetTrackSendInfo_Value( data.tr[1].ptr, 0, data.active_context_id-1-data.tr_cnt_sendsHW, 'D_VOL', 1 )
    data.active_context_sendmixer_val = 1
    redraw = 2   
  end
  ------------------
  function Apply_SendMix_vol(data, mouse, idx, shift, srcval)                                   
    local dBval = WDL_VAL2DB(srcval)
    dBval = lim(dBval+shift,-90,12)
    local real = WDL_DB2VAL(dBval)
    SetTrackSendInfo_Value( data.tr[1].ptr, 0, idx-1-data.tr_cnt_sendsHW, 'D_VOL', lim(real,0,4) ) 
    return real 
  end
----------------------------------------------------------- 








----------------------------------------------------------- 
  function Widgets_Track_chrecvmixer(data, obj, mouse, x_offs)
    if data.tr_cnt_receives == 0 then return end
    local recv_name_w = 120
    local ch_w = 12  
    local recv_w = recv_name_w + data.tr_cnt_receives * ch_w
    
    if x_offs + recv_w > obj.persist_margin then return x_offs end 
    obj.b.obj_recvmix_back1 = { x = x_offs,
                        y = obj.offs ,
                        w = recv_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        --txt = 'test',
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        ignore_mouse = true}  
    obj.b.obj_recvmix_back2 = { x = x_offs,
                        y = obj.offs+obj.entry_h ,
                        w = recv_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        ignore_mouse = true} 
                       
    local ch_w = 12
    local ch_h = math.floor(obj.entry_h*1.8)
    local ch_y = obj.offs + (obj.entry_h*2-math.floor(obj.entry_h*1.8))/2
    local mix_fields = recv_w-data.tr_cnt_receives * ch_w - 6
    for i = 1, data.tr_cnt_receives do
      local slider_a if data.active_context_id2 and data.active_context_id2 == i then slider_a = 0.5 else slider_a = 0.2 end
      obj.b['obj_recvmix_ch'..i] = { x = mix_fields+x_offs + 3 + math.floor(ch_w * (i-1)),
                        y = ch_y,
                        w = ch_w,--obj.entry_w2,
                        h = ch_h,
                        frame_a = 0,
                        frame_rect_a = 0.1,
                        fontsz = obj.fontsz_entry,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        --ignore_mouse=true,
                        val = lim(data.tr_recv[i].r_vol_slider),
                        is_slider = true,
                        is_vertical_slider = true,
                        sider_col = obj.txt_col_entry,
                        slider_a =slider_a,
                        func =  function()
                                  mouse.temp_val = data.tr_recv[i].r_vol
                                  mouse.temp_val2 = data.tr_recv
                                end,
                          func_DC =     function() 
                                                if data.MM_doubleclick == 0 then
                                                  Apply_RecvMix_vol_input(data.tr_recv[data.active_context_id2].r_vol_dB)
                                                 elseif data.MM_doubleclick == 1 then
                                                  Apply_RecvMix_vol_reset()
                                                end
                                              end,
                          func_R =      function()
                                                if data.MM_rightclick == 0 then 
                                                  Apply_RecvMix_vol_reset()
                                                 elseif data.MM_rightclick == 1 then
                                                  Apply_RecvMix_vol_input(data.tr_recv[data.active_context_id2].r_vol_dB)
                                                end
                                              end  ,                              
                        func_onRelease = function() Undo_OnStateChange( data.scr_title..': Change track receive properties' ) end,
                        func_wheel = function()
                                      mouse.temp_val = data.tr_recv[i].r_vol
                                      local real = Apply_RecvMix_vol(data, mouse, i, mouse.wheel_trig/10, mouse.temp_val)
                                      data.active_context_id2 = i 
                                      data.active_context_sendmixer2 =      data.tr_recv[i].r_name  
                                      data.active_context_sendmixer_val2=      lim(real,0,4)                         
                                      redraw = 2  
                                      end,
                        func_drag = function() 
                                      if not mouse.temp_val or not data.tr[1] then return end
                                      local mouse_shift = 0
                                      if data.use_mouse_drag_xAxis == 1 then mouse_shift = -mouse.dx else mouse_shift = mouse.dy end  
                                      local real = Apply_RecvMix_vol(data, mouse, i, mouse_shift/obj.mouse_scal_sendmixvol, mouse.temp_val)
                                      data.active_context_id2 = i 
                                      data.active_context_sendmixer2 =      data.tr_recv[i].r_name  
                                      data.active_context_sendmixer_val2 =      lim(real,0,4)                         
                                      redraw = 2 
                                    end,
                        func_drag_Ctrl = function()
                                            if not mouse.temp_val2 or not data.tr[1] then return end
                                            local mouse_shift = 0
                                            if data.use_mouse_drag_xAxis == 1 then mouse_shift = -mouse.dx else mouse_shift = mouse.dy end 
                                            local real
                                            for r_id = 1, data.tr_cnt_receives do
                                              local real0 = Apply_RecvMix_vol(data, mouse, r_id, mouse_shift/obj.mouse_scal_sendmixvol, mouse.temp_val2[r_id].r_vol )
                                              if r_id == i then real = real0 end
                                            end       
                                            data.active_context_id2 = i 
                                            data.active_context_sendmixer2 =      data.tr_recv[i].r_name  
                                            data.active_context_sendmixer_val2 =      lim(real,0,4)                
                                            redraw = 2                                           
                                          end,
                        func_matchonly = function()
                                            data.active_context_id2 = i 
                                            data.active_context_sendmixer2 =      data.tr_recv[i].r_name  
                                            data.active_context_sendmixer_val2 =      data.tr_recv[i].r_vol 
                                            redraw = 2
                                          end}
    end
    
    local txt = ''
    if data.active_context_sendmixer2 then txt = data.active_context_sendmixer2..' ->' end
    obj.b.obj_recvmix_tr_name = { x = x_offs,
                        y = obj.offs ,
                        w = recv_name_w,
                        h = obj.entry_h,
                        frame_a = 0,
                        txt = txt,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        ignore_mouse = true,
                        fontsz = obj.fontsz_entry} 
    if data.active_context_sendmixer_val2 then

      obj.b.obj_recvmix_tr_s_vol = { x = x_offs,
                          y = obj.offs+obj.entry_h ,
                          w = recv_name_w,
                          h = obj.entry_h,
                          frame_a = 0,
                          txt = WDL_VAL2DB(data.active_context_sendmixer_val2, true)..'dB',
                          txt_a = obj.txt_a,
                          txt_col = obj.txt_col_entry,
                          --ignore_mouse = true,
                          fontsz = obj.fontsz_entry,
                          func_DC =     function() 
                                                if data.MM_doubleclick == 0 then
                                                  Apply_RecvMix_vol_input(data.tr_recv[data.active_context_id2].r_vol_dB)
                                                 elseif data.MM_doubleclick == 1 then
                                                  Apply_RecvMix_vol_reset()
                                                end
                                              end,
                          func_R =      function()
                                                if data.MM_rightclick == 0 then 
                                                  Apply_RecvMix_vol_reset()
                                                 elseif data.MM_rightclick == 1 then
                                                  Apply_RecvMix_vol_input(data.tr_recv[data.active_context_id2].r_vol_dB)
                                                end
                                              end
                      } 
    end                                                                       
    return recv_w
  end
  -------------------
  function Apply_RecvMix_vol_input(srcval)
    local ret, outstr = GetUserInputs( 'Edit', 1, '', srcval )
    if not ret then return end
    local out_val = ParseDbVol(outstr)
    if not data.tr[1] or not data.active_context_id2 or not out_val then return end
    SetTrackSendInfo_Value( data.tr[1].ptr, -1, data.active_context_id2-1, 'D_VOL', out_val )
    data.active_context_sendmixer_val2 = out_val
    redraw = 2   
  end
  -------------------
  function Apply_RecvMix_vol_reset()
    if not data.tr[1] or not data.active_context_id2 then return end
    SetTrackSendInfo_Value( data.tr[1].ptr, -1, data.active_context_id2-1, 'D_VOL', 1 )
    data.active_context_sendmixer_val2 = 1
    redraw = 2   
  end
  ------------------
  function Apply_RecvMix_vol(data, mouse, idx, shift, srcval)                                   
    local dBval = WDL_VAL2DB(srcval)
    dBval = lim(dBval+shift,-90,12)
    local real = WDL_DB2VAL(dBval)
    SetTrackSendInfo_Value( data.tr[1].ptr, -1, idx-1, 'D_VOL', lim(real,0,4) ) 
    return real 
  end
----------------------------------------------------------- 





  
  
  
----------------------------------------------------------- 
  function Widgets_Track_fxcontrols(data, obj, mouse, x_offs, widgets, conf)
    local ch_w = 12
    local fxctrl_menu_w = 20
    local fxctrl_name_w = 100
    local fxctrl_w
    local mix_fields = 0
    if data.tr_FXCtrl[data.tr[1].GUID] then 
      mix_fields = #data.tr_FXCtrl[data.tr[1].GUID] * ch_w
      fxctrl_w = mix_fields + fxctrl_menu_w + fxctrl_name_w
     else
      fxctrl_w = fxctrl_menu_w
    end
    
    if x_offs + fxctrl_w > obj.persist_margin then return x_offs end 
    obj.b.obj_fxctrl_back1 = { x = x_offs,
                        y = obj.offs ,
                        w = fxctrl_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        --txt = 'test',
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        ignore_mouse = true}  
    obj.b.obj_fxctrl_back2 = { x = x_offs,
                        y = obj.offs+obj.entry_h ,
                        w = fxctrl_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        ignore_mouse = true} 
    obj.b.obj_fxctrl_app = {x = x_offs + fxctrl_w- fxctrl_menu_w,
                          y =  obj.entry_h,
                          w = fxctrl_menu_w,
                          h = obj.entry_h,
                          frame_a = 0,--,
                          --frame_rect_a = 1,
                          txt_a = obj.txt_a,
                          txt_col = 'white',
                          txt = '->',
                          func =        function()
                                          Menu(mouse,
                                              { { str = '#FX controls|'},
                                                { str = 'Add last touched parameter to FX controls',
                                                  func =  function()
                                                            local linktrGUID = data.tr[1].GUID
                                                            local retval, tracknumberOut, fxnumberOut, paramnumberOut = GetLastTouchedFX()
                                                            if not retval then return end
                                                            local track = CSurf_TrackFromID( tracknumberOut, false )
                                                            local trackGUID = GetTrackGUID( track )
                                                            local FX_GUID = TrackFX_GetFXGUID( track, fxnumberOut )
                                                            UpdateFXCtrls(linktrGUID, trackGUID, FX_GUID, paramnumberOut, 0, 1 )
                                                          end
                                                },
                                                { str = 'Clear linked controls|',
                                                  func =  function()
                                                            local linktrGUID = data.tr[1].GUID
                                                            data.tr_FXCtrl[linktrGUID] = nil
                                                            TrackFXCtrls_Save(data) 
                                                            redraw = 2
                                                          end
                                                }  ,
                                                { str = 'Use deductive brutforce for input parameter',
                                                  state = conf.trackfxctrl_use_brutforce == 1,
                                                  func =  function()
                                                            conf.trackfxctrl_use_brutforce = math.abs(-1+conf.trackfxctrl_use_brutforce) ExtState_Save(conf) redraw = 2
                                                          end
                                                }  ,                                            
                                              
                                              })
                                        end
                      }  
    if not data.tr_FXCtrl[data.tr[1].GUID] then return fxctrl_w end                      
    local ch_h = math.floor(obj.entry_h*1.8)
    local ch_y = obj.offs + (obj.entry_h*2-math.floor(obj.entry_h*1.8))/2
    local mix_fields = #data.tr_FXCtrl[data.tr[1].GUID] * ch_w
    for i = 1, #data.tr_FXCtrl[data.tr[1].GUID] do
      local slider_a if data.active_context_id3 and data.active_context_id3 == i then slider_a = 0.5 else slider_a = 0.2 end
      obj.b['fxctrl_ch'..i] = { x = x_offs + 3 + math.floor(ch_w * (i-1)),
                        y = ch_y,
                        w = ch_w,--obj.entry_w2,
                        h = ch_h,
                        frame_a = 0,
                        frame_rect_a = 0.1,
                        fontsz = obj.fontsz_entry,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        val = data.tr_FXCtrl[data.tr[1].GUID][i].val,
                        is_slider = true,
                        is_vertical_slider = true,
                        sider_col = obj.txt_col_entry,
                        slider_a =slider_a,
                        func =  function()
                                  mouse.temp_val = data.tr_FXCtrl[data.tr[1].GUID][i].val
                                end,
                        func_DC =     function() 
                                               if data.MM_doubleclick == 0 then
                                                  Apply_FXCtrl_input(data, conf, mouse,  data.tr_FXCtrl[data.tr[1].GUID][i] )
                                                 --elseif data.MM_doubleclick == 1 then
                                                  --reset()
                                                end
                                              end,
                        func_R =      function()
                                        Menu(mouse, {
                                                      {str = 'Remove from controls',
                                                       func = function()
                                                                local linktrGUID = data.tr[1].GUID
                                                                table.remove(data.tr_FXCtrl[linktrGUID], i)
                                                                TrackFXCtrls_Save(data) 
                                                                redraw = 2
                                                              end
                                                        }
                                                    })
                                      end  ,                              
                        func_onRelease = function() 
                                            Undo_OnStateChange( data.scr_title..': Change FX parameter' ) 
                                          end,
                        func_wheel = function()
                                      mouse.temp_val = data.tr_FXCtrl[data.tr[1].GUID][i].val
                                      Apply_FXCtrl(data, mouse, mouse.wheel_trig/obj.mouse_scal_FXCtrl, mouse.temp_val, data.tr_FXCtrl[data.tr[1].GUID][i] )
                                      data.active_context_id3 = i 
                                      data.active_context_fxctrl =      data.tr_FXCtrl[data.tr[1].GUID][i].paramname
                                      data.active_context_fxctrl_val =  data.tr_FXCtrl[data.tr[1].GUID][i].paramformat                  
                                      redraw = 2 
                                      end,
                        func_drag = function() 
                                      if not mouse.temp_val or not data.tr_FXCtrl[data.tr[1].GUID] then return end
                                      local mouse_shift = 0
                                      if data.use_mouse_drag_xAxis == 1 then mouse_shift = -mouse.dx else mouse_shift = mouse.dy end  
                                      Apply_FXCtrl(data, mouse, mouse_shift/obj.mouse_scal_FXCtrl2, mouse.temp_val, data.tr_FXCtrl[data.tr[1].GUID][i] )
                                      data.active_context_id3 = i 
                                      data.active_context_fxctrl =      data.tr_FXCtrl[data.tr[1].GUID][i].paramname
                                      data.active_context_fxctrl_val =  data.tr_FXCtrl[data.tr[1].GUID][i].paramformat                         
                                      redraw = 2 
                                    end,
                        func_matchonly = function()
                                            data.active_context_id3 = i 
                                            data.active_context_fxctrl =      data.tr_FXCtrl[data.tr[1].GUID][i].paramname
                                            data.active_context_fxctrl_val =  data.tr_FXCtrl[data.tr[1].GUID][i].paramformat
                                            redraw = 2
                                          end}
    end
    
    local fxctrl_name_txt,fxctrl_val_txt,fxname,tr_ID = '','','',''
    if data.active_context_id3 and data.tr_FXCtrl[data.tr[1].GUID][data.active_context_id3] then 
      fxname = data.tr_FXCtrl[data.tr[1].GUID][data.active_context_id3].fxname
      tr_ID = data.tr_FXCtrl[data.tr[1].GUID][data.active_context_id3].tr_ID
      fxname = '['..tr_ID..'] '..MPL_ReduceFXname(fxname)
      fxctrl_val_txt =  data.tr_FXCtrl[data.tr[1].GUID][data.active_context_id3].paramformat
      fxctrl_name_txt = data.tr_FXCtrl[data.tr[1].GUID][data.active_context_id3].paramname      
     else
      return fxctrl_w
    end
    obj.b.fxctrl_fxname = { x = x_offs + mix_fields+4,
                        y = -2,
                        w = fxctrl_w - mix_fields -4,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = 0,
                        txt = fxname,
                        txt_a = obj.txt_a,
                        aligh_txt = 1,
                        txt_col = obj.txt_col_entry,
                        fontsz = obj.fontszFXctrl,
                        func = function () 
                                  Apply_FXCtrl_FloatFX(data.tr_FXCtrl[data.tr[1].GUID][data.active_context_id3])
                                end} 
    obj.b.fxctrl_name = { x = x_offs + mix_fields+4,
                        y = -2+obj.fontszFXctrl-1 ,
                        w = fxctrl_w - mix_fields -4,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = 0,
                        txt = fxctrl_name_txt,
                        txt_a = obj.txt_a,
                        aligh_txt = 1,
                        txt_col = obj.txt_col_entry,
                        fontsz = obj.fontszFXctrl,
                        func_DC =     function() 
                                              if data.MM_doubleclick == 0 then
                                                Apply_FXCtrl_input(data, conf, mouse,  data.tr_FXCtrl[data.tr[1].GUID][data.active_context_id3] )
                                               elseif data.MM_doubleclick == 1 then
                                                --reset()
                                              end
                                            end,
                        func_R =      function()
                                              if data.MM_rightclick == 0 then 
                                                --reset()
                                               elseif data.MM_rightclick == 1 then
                                                Apply_FXCtrl_input(data, conf, mouse,  data.tr_FXCtrl[data.tr[1].GUID][data.active_context_id3] )
                                              end
                                            end} 
    obj.b.fxctrl_val = { x = x_offs + mix_fields+4,
                          y =-2+ obj.fontszFXctrl*2-2 ,
                          w = fxctrl_w - mix_fields -4 - fxctrl_menu_w,--obj.entry_w2,
                          h = obj.entry_h,
                          frame_a = 0,
                          txt = fxctrl_val_txt,
                          txt_a = obj.txt_a,
                          txt_col = obj.txt_col_entry,
                          aligh_txt = 1,
                          fontsz = obj.fontszFXctrl,
                          func_DC =     function() 
                                                if data.MM_doubleclick == 0 then
                                                  Apply_FXCtrl_input(data, conf, mouse,  data.tr_FXCtrl[data.tr[1].GUID][data.active_context_id3] )
                                                 elseif data.MM_doubleclick == 1 then
                                                  --reset()
                                                end
                                              end,
                          func_R =      function()
                                                if data.MM_rightclick == 0 then 
                                                  --reset()
                                                 elseif data.MM_rightclick == 1 then
                                                  Apply_FXCtrl_input(data, conf, mouse,  data.tr_FXCtrl[data.tr[1].GUID][data.active_context_id3] )
                                                end
                                              end
                      }                                                                      
    return fxctrl_w
  end  
  ---------------------------------------------------------------
  function UpdateFXCtrls(linktrGUID, trackGUID, FX_GUID, paramnum, lim1, lim2)
    if not data.tr_FXCtrl then data.tr_FXCtrl = {} end
    if not data.tr_FXCtrl[linktrGUID] then data.tr_FXCtrl[linktrGUID] = {} end
    for i = 1, #data.tr_FXCtrl[linktrGUID] do
      local t = data.tr_FXCtrl[linktrGUID][i]
      if t.FX_GUID == FX_GUID and t.paramnum==paramnum then return end
    end
    table.insert(data.tr_FXCtrl[linktrGUID],  {trackGUID = trackGUID,
                                               FX_GUID=FX_GUID,
                                               paramnum=paramnum,
                                               lim1 = lim1,
                                               lim2 = lim2})
    TrackFXCtrls_Save(data) 
  end
  -------------------------------------------------------------------
  function TrackFXCtrls_Save(data)                            
    -- store ext chunk
    local out_extchunk = ''
    for linktrGUID in pairs(data.tr_FXCtrl) do
      out_extchunk = out_extchunk..'LINK_TR '..linktrGUID..'\n'
      for i = 1, #data.tr_FXCtrl[linktrGUID] do
        out_extchunk = out_extchunk..'SLOT '..i..' '..data.tr_FXCtrl[linktrGUID][i].trackGUID
                        ..' '..data.tr_FXCtrl[linktrGUID][i].FX_GUID
                        ..' '..data.tr_FXCtrl[linktrGUID][i].paramnum
                        ..' '..data.tr_FXCtrl[linktrGUID][i].lim1
                        ..' '..data.tr_FXCtrl[linktrGUID][i].lim2..'\n'
      end
    end
    SetProjExtState( 0, 'MPL_InfoTool', 'FXCtrl', out_extchunk )
  end
----------------------------------------------------------------
  function Apply_FXCtrl(data, mouse, shift, srcval, t )
    local tr = BR_GetMediaTrackByGUID(0, t.trackGUID)
    if not tr then return end
    local fxid = GetFXByGUID(tr, t.FX_GUID)
    local param = t.paramnum
    local outval = lim(srcval + shift, 0, 1)
    TrackFX_SetParamNormalized( tr, fxid, param, outval )
  end    
  ----------------------------------------------------------------                    
  function Apply_FXCtrl_input(data, conf, mouse, t )
    local tr = BR_GetMediaTrackByGUID(0, t.trackGUID)
    if not tr then return end
    local fx = GetFXByGUID(tr, t.FX_GUID)
    local param = t.paramnum
    if conf.trackfxctrl_use_brutforce == 1 then 
        local ReaperVal = MPL_BFPARAM_main(tr,fx, param) 
        if out_val then
          TrackFX_SetParamNormalized( tr, fx, param, ReaperVal )
          redraw = 2
        end   
      elseif conf.trackfxctrl_use_brutforce == 0 then
       local retval, paramnorm = GetUserInputs( 'Input normalized param', 1, 'value,extrawidth=200', TrackFX_GetParamNormalized( tr , fx, param, '' ) )
       if not retval or not tonumber(paramnorm) then return end
       TrackFX_SetParamNormalized( tr, fx, param, paramnorm )
       
    end
  end  
  ---------------------------------------------------------------- 
  function Apply_FXCtrl_FloatFX(t)
    local tr = BR_GetMediaTrackByGUID(0, t.trackGUID)
    if not tr then return end
    local fx = GetFXByGUID(tr, t.FX_GUID)
    TrackFX_Show( tr, fx, 3 )
  end        
    




  --------------------------------------------------------------
  function Widgets_Track_freeze(data, obj, mouse, x_offs) 
    local w = 80
    if not data.tr or not data.tr.freezecnt_format then return end
    if x_offs + w > obj.persist_margin then return x_offs end 
    obj.b.obj_tr_freeze = { x = x_offs,
                        y = obj.offs ,
                        w = w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        fontsz = obj.fontsz_entry,
                        state_col = 'blue_bright',
                        state =true,
                        txt_a = obj.txt_a,
                        txt_col = 'white',
                        txt = 'Frz '..data.tr.freezecnt_format,
                        func = function () Action(41223) end} 
    obj.b.obj_tr_unfreeze = { x =  x_offs,
                        y = obj.offs *2 +obj.entry_h ,
                        w = w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        fontsz = obj.fontsz_entry,
                        state_col = 'red',
                        state =true,
                        txt_a = obj.txt_a,
                        txt_col = 'white',
                        txt = 'Unfreeze',
                        func = function() Action(41644) end} 
    return w
  end
