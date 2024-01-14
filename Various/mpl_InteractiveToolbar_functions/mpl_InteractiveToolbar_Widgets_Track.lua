-- @description InteractiveToolbar_Widgets_Track
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex


  -- track wigets for mpl_InteractiveToolbar
  -- #color #fxcontrols #buttons #vol #pan #fxlist #sendto #delay #troffs #chsendmixer #chrecvmixer #freeze 
  ---------------------------------------------------
  function Obj_UpdateTrack(data, obj, mouse, widgets, conf)
    obj.b.obj_name = { x = obj.menu_b_rect_side + obj.offs,
                        y = obj.offs *2 +obj.entry_h,
                        w = conf.GUI_contextname_w*conf.scaling,
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
        if _G['Widgets_Track_'..key] then
            local retX, retY = _G['Widgets_Track_'..key](data, obj, mouse, x_offs, widgets, conf, y_offs) 
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
  function Widgets_Track_buttons(data, obj, mouse, x_offs0, widgets, conf, y_offs0)
   local frame_a, x_offs
   local y_offs = 0
   if conf.dock_orientation == 0 and x_offs0 + obj.entry_w2*2 > obj.persist_margin then return x_offs0 end  -- reduce buttons when more than regular wx2
   local last_x1,last_x2 = x_offs0, x_offs0
   local tp_ID = data.obj_type_int
   local widg_key = widgets.types_t[tp_ID+1] -- get key of current mapped table
   if widgets[widg_key] and widgets[widg_key].buttons  then  
     for i = 1, #widgets[widg_key].buttons do 
       local key = widgets[widg_key].buttons[i]
       if _G['Widgets_Track_buttons_'..key] then  
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
         local next_w = _G['Widgets_Track_buttons_'..key](data, obj, mouse, x_offs, y_offs+y_offs0, frame_a, conf)
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
  function Widgets_Track_buttons_midiin(data, obj, mouse, x_offs, y_offs, frame_a)
    local w = 50*obj.entry_ratio
    local state = GetMediaTrackInfo_Value( data.tr[1].ptr, 'I_RECINPUT')&4096==4096 and GetMediaTrackInfo_Value( data.tr[1].ptr, 'I_RECMON') == 1
    obj.b.obj_trmidiin = {  x = x_offs,
                        y = obj.offs+y_offs ,
                        w = w,
                        h = obj.entry_h,
                        frame_a = frame_a,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_toolbar,
                        txt = 'MIDI In',
                        fontsz = obj.fontsz_entry,
                        state = state,
                        state_col = 'white',
                        func =  function()
                                  for i = 1, #data.tr do
                                    if not state then 
                                      SetMediaTrackInfo_Value( data.tr[i].ptr, 'I_RECINPUT', 4096+(63<<5))
                                      SetMediaTrackInfo_Value( data.tr[i].ptr, 'I_RECMON', 1)
                                      SetMediaTrackInfo_Value( data.tr[i].ptr, 'I_RECARM', 1) 
                                     else
                                      SetMediaTrackInfo_Value( data.tr[i].ptr, 'I_RECINPUT', -1)
                                      SetMediaTrackInfo_Value( data.tr[i].ptr, 'I_RECMON', 0)  
                                      SetMediaTrackInfo_Value( data.tr[i].ptr, 'I_RECARM', 0)                                      
                                    end        
                                  end
                                  redraw = 1                              
                                end}
    return w
  end    
  
  --------------------------------------------------------------  
  function Widgets_Track_buttons_numchan(data, obj, mouse, x_offs, y_offs, frame_a)
    local w = 50*obj.entry_ratio
    local ch = math.floor(data.tr[1].nch1)..'ch'
    obj.b.obj_traudioin = {  x = x_offs,
                        y = obj.offs+y_offs ,
                        w = w,
                        h = obj.entry_h,
                        frame_a = frame_a,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_toolbar,
                        txt = ch,
                        fontsz = obj.fontsz_entry,
                        state = state,
                        state_col = 'white',
                        func =  function()
                                  local t = {}
                                  for ch = 2, 64,2 do
                                    t[#t+1] = { str = 'Set master parent channels to '..ch,
                                                func = function() 
                                                        for i = 1, #data.tr do
                                                          SetMediaTrackInfo_Value( data.tr[i].ptr, 'I_NCHAN', ch)
                                                        end
                                                        redraw = 2
                                                      end}
                                              
                                  end
                                  Menu(mouse, t)
                                  redraw = 1                              
                                end}
    return w
  end   
  --------------------------------------------------------------  
  function Widgets_Track_buttons_audioin(data, obj, mouse, x_offs, y_offs, frame_a)
    local w = 50*obj.entry_ratio
    local state = GetMediaTrackInfo_Value( data.tr[1].ptr, 'I_RECINPUT')&4096==0 and GetMediaTrackInfo_Value( data.tr[1].ptr, 'I_RECMON') == 1
    obj.b.obj_traudioin = {  x = x_offs,
                        y = obj.offs+y_offs ,
                        w = w,
                        h = obj.entry_h,
                        frame_a = frame_a,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_toolbar,
                        txt = 'Audio In',
                        fontsz = obj.fontsz_entry,
                        state = state,
                        state_col = 'white',
                        func =  function()
                                  for i = 1, #data.tr do
                                    if not state then 
                                      SetMediaTrackInfo_Value( data.tr[i].ptr, 'I_RECINPUT', 1024)
                                      SetMediaTrackInfo_Value( data.tr[i].ptr, 'I_RECMON', 1)
                                      SetMediaTrackInfo_Value( data.tr[i].ptr, 'I_RECARM', 1)
                                     else
                                      SetMediaTrackInfo_Value( data.tr[i].ptr, 'I_RECINPUT', -1)
                                      SetMediaTrackInfo_Value( data.tr[i].ptr, 'I_RECMON', 0) 
                                      SetMediaTrackInfo_Value( data.tr[i].ptr, 'I_RECARM', 0)                                     
                                    end
                                  end
                                  redraw = 1                              
                                end}
    return w
  end   
  
  
  
  -------------------------------------------------------------- 
  function Widgets_Track_pan(data, obj, mouse, x_offs, widgets, conf, y_offs)
    local pan_w = 60*conf.scaling
    if x_offs + pan_w > obj.persist_margin then return x_offs end 
    obj.b.obj_tr_pan = { x = x_offs,
                        y = y_offs ,
                        w = pan_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'Pan'} 
    obj.b.obj_tr_pan_back = { x =  x_offs,
                        y = y_offs +obj.entry_h ,
                        w = pan_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
      if conf.dock_orientation == 1 then
        obj.b.obj_tr_pan.w = obj.entry_w2/2
        obj.b.obj_tr_pan_back.x= obj.entry_w2/2
        obj.b.obj_tr_pan_back.y = y_offs
        obj.b.obj_tr_pan_back.w = obj.entry_w2/2
        obj.b.obj_tr_pan_back.frame_a = obj.frame_a_head
      end 
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = {data.tr[1].pan_format},
                        table_key='tr_pan_ctrl',
                        x_offs= obj.b.obj_tr_pan_back.x,
                        y_offs= obj.b.obj_tr_pan_back.y,  
                        w_com=obj.b.obj_tr_pan_back.w,
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
  function Widgets_Track_vol(data, obj, mouse, x_offs, widgets, conf, y_offs) -- generate snap_offs controls 
    local vol_w = 60 *conf.scaling
    if x_offs + vol_w > obj.persist_margin then return x_offs end 
    obj.b.obj_trvol = { x = x_offs,
                        y = y_offs,
                        w = vol_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'Volume'} 
    obj.b.obj_trvol_back = { x =  x_offs,
                        y = y_offs +obj.entry_h ,
                        w = vol_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt ='',
                        fontsz = obj.fontsz_entry,
                        ignore_mouse = true}  
      if conf.dock_orientation == 1 then
        obj.b.obj_trvol.w = obj.entry_w2/2
        obj.b.obj_trvol_back.x= obj.entry_w2/2
        obj.b.obj_trvol_back.y = y_offs
        obj.b.obj_trvol_back.w = obj.entry_w2/2
        obj.b.obj_trvol_back.frame_a = obj.frame_a_head
      end                 
      local vol_str = data.tr[1].vol_format
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = {data.tr[1].vol_format},
                        table_key='trvol_ctrl',
                        x_offs= obj.b.obj_trvol_back.x,
                        y_offs= obj.b.obj_trvol_back.y,  
                        w_com=obj.b.obj_trvol_back.w,--obj.entry_w2,
                        src_val=data.tr,
                        src_val_key= 'vol',
                        modify_func= MPL_ModifyFloatVal,
                        app_func= Apply_Track_vol,                    
                        mouse_scale= obj.mouse_scal_vol,               -- mouse scaling
                        use_mouse_drag_xAxis = data.always_use_x_axis==1,
                        --ignore_fields= true, -- same tolerance change
                        --y_offs= nil,
                        dont_draw_val = nil,
                        default_val = 1,
                        modify_wholestr = true,
                        onRelease_ActName = data.scr_title..': Change track properties'})
    if conf.trackvol_slider == 1  and conf.dock_orientation ==1  then
      obj.b.trackvol_slider_back = { x = 0,
                                y = y_offs+obj.entry_h,
                                w = gfx.w,
                                h = gfx.w/2,
                        frame_a = obj.frame_a_head,
                        txt ='',
                        fontsz = obj.fontsz_entry,
                        ignore_mouse = true}  
      obj.b.trackvol_slider = { x = 0,
                                y = y_offs+obj.entry_h,
                                w = gfx.w,
                                h = gfx.w,
                                frame_a = 0,
                                txt = '',
                                txt_a = obj.txt_a,
                                fontsz = obj.fontsz_entry,
                                is_knob = true,
                                knob_yshift = 3,
                                knob_w = gfx.w/2,
                                knob_col = obj.txt_col_header,
                                val = data.tr[1].vol/2,
                                func =        function()
                                                mouse.temp_val = data.tr[1].vol
                                                redraw = 1                              
                                              end,
                                func_ctrlL =        function()
                                                mouse.temp_val = data.tr[1].vol
                                                redraw = 1                              
                                              end,                                              
                                func_wheel =  function()
                                                local out_value = MPL_ModifyFloatVal(data.tr[1].vol, 1, 1, mouse.wheel_trig, data, nil, -2)
                                                out_value = lim(out_value,0,4)
                                                SetMediaTrackInfo_Value( data.tr[1].ptr, 'D_VOL', out_value)
                                                redraw = 2          
                                              end,                                              
                                func_drag =   function(is_ctrl) 
                                                if not mouse.temp_val then return end
                                                local pow_tol = -2
                                                local out_value, mouse_shift 
                                                out_value = MPL_ModifyFloatVal(mouse.temp_val, 1, 1, math.modf((-mouse.dx/4)/obj.mouse_scal_float), data, nil, pow_tol)
                                                out_value = lim(out_value,0,4)
                                                SetMediaTrackInfo_Value( data.tr[1].ptr, 'D_VOL', out_value)
                                                redraw =2
                                              end,
                                func_drag_Ctrl =   function(is_ctrl) 
                                                if not mouse.temp_val then return end
                                                local pow_tol = -4 
                                                local out_value = MPL_ModifyFloatVal(mouse.temp_val, 1, 1, math.modf(mouse.dy/obj.mouse_scal_float), data, nil, pow_tol)
                                                out_value = lim(out_value,0,4)
                                                SetMediaTrackInfo_Value( data.tr[1].ptr, 'D_VOL', out_value)
                                                redraw = 2
                                              end,                                              
                                func_DC =     function() 
                                                local retval0,ret_str = GetUserInputs( 'Edit value', 1, ',extrawidth=100', WDL_VAL2DB(data.tr[1].vol, true))
                                                if not retval0 or not tonumber(ret_str) then return end
                                                SetMediaTrackInfo_Value( data.tr[1].ptr, 'D_VOL', ParseDbVol(ret_str))                                                               
                                              end}   
 
    end                    
    if conf.trackvol_slider == 1 and conf.dock_orientation ==1 then return  vol_w, gfx.w/2 +obj.entry_h
     else return vol_w, obj.entry_h end              
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




  function Widgets_Track_delay(data, obj, mouse, x_offs, widgets, conf, y_offs)    -- generate position controls 
    local del_w = 60*conf.scaling
    if x_offs + del_w > obj.persist_margin then return x_offs end 
    obj.b.obj_trdelay = { x = x_offs,
                        y = y_offs ,
                        w = del_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'Delay'} 
    obj.b.obj_trdelay_back = { x =  x_offs,
                        y = y_offs +obj.entry_h ,
                        w = del_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = data.tr[1].delay_format..'s',
                        fontsz = obj.fontsz_entry,
                        ignore_mouse = true}  
      if conf.dock_orientation == 1 then
        obj.b.obj_trdelay.w = obj.entry_w2/2
        obj.b.obj_trdelay_back.x= obj.entry_w2/2
        obj.b.obj_trdelay_back.y = y_offs
        obj.b.obj_trdelay_back.w = obj.entry_w2/2
        obj.b.obj_trdelay_back.frame_a = obj.frame_a_head
      end                         
                        
      local delay_str = data.tr[1].delay_format
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = {delay_str},
                        table_key='delay_ctrl',
                        x_offs= obj.b.obj_trdelay_back.x,
                        y_offs= obj.b.obj_trdelay_back.y,  
                        w_com=obj.b.obj_trdelay_back.w,
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
  function Widgets_Track_fxlist(data, obj, mouse, x_offs, widgets, conf, y_offs)
    if not data.tr[1].fx_names or #data.tr[1].fx_names < 1 then return end
    local fxlist_w = 120 *conf.scaling
    local fxlist_state = 30*conf.scaling
    if conf.dock_orientation == 1 then
      fxlist_w = gfx.w
      fxlist_state = gfx.w*0.2
    end    
    
    if x_offs + fxlist_w > obj.persist_margin then return x_offs end 
    local fxid = lim(math.modf(data.curent_trFXID),1, #data.tr[1].fx_names)
    obj.b.obj_fxlist_back1 = { x = x_offs,
                        y = y_offs ,
                        w = fxlist_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = '',
                        func_wheel =  function() Apply_TrackFXListChange(data, mouse.wheel_trig) end}
                            --    func = function () Apply_TrackFXListChange_floatFX(data, mouse, data.tr[1].fx_names[fxid].is_enabled) end     
    obj.b.obj_fxlist_back2 = { x =  x_offs,
                        y = y_offs +obj.entry_h ,
                        w = fxlist_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt ='',
                        fontsz = obj.fontsz_entry,
                        func_wheel =  function() Apply_TrackFXListChange(data, mouse.wheel_trig) end} 
                          --      func = function () Apply_TrackFXListChange_floatFX(data, mouse, data.tr[1].fx_names[fxid].is_enabled) end  }                           
    
    local h_entr= obj.fontsz_entry
    if conf.dock_orientation == 1 then h_entr= obj.fontsz_entry*0.6 end
    for i = 1, #data.tr[1].fx_names do
      local txt_a = 0.2
      if data.curent_trFXID and i == lim(math.modf(data.curent_trFXID),1, #data.tr[1].fx_names) then txt_a = obj.txt_a end
      local i_shift if data.curent_trFXID then i_shift = lim(math.modf(data.curent_trFXID),1, #data.tr[1].fx_names)-1 else  i_shift= 0 end
      local txt_col = obj.txt_col_header
      if not data.tr[1].fx_names[i].is_enabled then txt_col = 'red'end
      if not data.tr[1].fx_names[i].is_online then txt_col = 'grey'end
      if y_offs + obj.entry_h/2 + h_entr*(i-i_shift-1) > y_offs and y_offs + obj.entry_h/2 + h_entr*(i-i_shift-1)+h_entr < y_offs + obj.entry_h*2 then
        obj.b['obj_fxlist_val'..i] = { x =  x_offs+fxlist_state,
                                y = y_offs + obj.entry_h/2 + h_entr*(i-i_shift-1) ,
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
      end 
      local txt,txt_col
--[[      if not data.tr[1].fx_names[i].is_enabled or not data.tr[1].fx_names[i].is_online then 
        txt = ''
        if not data.tr[1].fx_names[i].is_enabled then txt ='B ' end
        if not data.tr[1].fx_names[i].is_online then txt = txt..'O' end
        txt_col = 'red'
       else 
        txt =i 
        txt_col = obj.txt_col_header
      end     ]]
      txt =i 
      txt_col = obj.txt_col_header
      if y_offs + obj.entry_h/2 + h_entr*(i-i_shift-1) > y_offs and y_offs + obj.entry_h/2 + h_entr*(i-i_shift-1)+h_entr < y_offs + obj.entry_h*2 then
        obj.b['obj_fxlist_val'..i..'state'] = { x =  x_offs,
                                y = y_offs + obj.entry_h/2 + h_entr*(i-i_shift-1) ,
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
    end
    return fxlist_w, obj.entry_h*2               
  end

  function Apply_TrackFXListChange(data, wheel_trig)
    local trig
    if wheel_trig > 0 then trig = 0.35 elseif wheel_trig <0 then trig = -0.35 else return  end                                                             
    data.curent_trFXID = lim( data.curent_trFXID -trig, 1 ,#data.tr[1].fx_names)
    redraw = 2  
  end
  function Apply_TrackFXListChange_floatFX(data, mouse, state)
    local fx_id = lim( math.modf(data.curent_trFXID), 1 ,#data.tr[1].fx_names)
    local vrs_num =  GetAppVersion()
    local vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    local support_FX_change =  vrs_num >= 5.95
    
    if mouse.Shift and not mouse.Ctrl then 
      TrackFX_SetEnabled( data.tr[1].ptr, fx_id-1, not state) 
     elseif support_FX_change and mouse.Ctrl and mouse.Shift then
      local offl_state = TrackFX_GetOffline(data.tr[1].ptr, fx_id-1)
      TrackFX_SetOffline(data.tr[1].ptr, fx_id-1, not offl_state)
     elseif mouse.Alt and support_FX_change then
      TrackFX_Delete( data.tr[1].ptr, fx_id-1 )
     elseif not mouse.Ctrl and not mouse.Shift and not mouse.Alt then
      local is_open = reaper.TrackFX_GetOpen(data.tr[1].ptr, fx_id-1 )
      if not is_open then TrackFX_Show( data.tr[1].ptr, fx_id-1, 3 ) else TrackFX_Show( data.tr[1].ptr, fx_id-1, 2 ) end
    end
    
  end
----------------------------------------------------------- 
  function SendTracksChannels(data,mouse, conf,mode0) 
    local mode = mode0 or 0
    local t = {}
    
    for i = 0, 63 do
      t[#t+1] = 
        {
          str = (i*2+1)..'/'..(i*2+2),
          func = function() 
                  if mode == 0 then 
                    conf.defsend_chansrc = i*2
                    redraw = 2   
                  end
                  if mode == 1 then 
                    conf.defsend_chandest = i*2
                    redraw = 2   
                  end
                  data.defsend_chansrc = conf.defsend_chansrc
                  data.defsend_chandest = conf.defsend_chandest
                  ExtState_Save(conf)  
                end
        }          
    end         
    Menu( mouse, t )
  end
-----------------------------------------------------------   
  function Widgets_Track_sendto(data, obj, mouse, x_offs, widgets, conf, y_offs)
    local send_but = 20*conf.scaling
    local vol_w = 60 *conf.scaling
    local chan_w = 80 *conf.scaling
    local send_w = send_but + vol_w  + chan_w
    if x_offs + send_w > obj.persist_margin then return x_offs end 
    
    
    -- back
    obj.b.obj_sendto_back1 = { x = x_offs,
                        y = y_offs,
                        w = send_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        --txt ='test',
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        ignore_mouse = true} 
    obj.b.obj_sendto_back2 = { x = x_offs,
                        y = y_offs+obj.entry_h ,
                        w = send_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        ignore_mouse = true} 
      if conf.dock_orientation == 1 then
        obj.b.obj_sendto_back1.w = obj.entry_w2
        obj.b.obj_sendto_back2.w = obj.entry_w2
      end       
      
      
     -- menu 
    obj.b.obj_sendto_but = { x = x_offs+send_w-send_but,
                        y = y_offs ,
                        w = send_but,--obj.entry_w2,
                        h = obj.entry_h*2,
                        frame_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = '->',
                        func = function() SendTracksTo(data, mouse) end }  
      if conf.dock_orientation == 1 then obj.b.obj_sendto_but.x = obj.entry_w2 - send_but end     
      
      
    -- channels
    local chansrc = conf.defsend_chansrc
    local chansrc_txt = (chansrc+1)..'/'..(chansrc+2) 
    local chandest = conf.defsend_chandest 
    local chandest_txt = (chandest+1)..'/'..(chandest+2)
    obj.b.obj_sendto_channels = { x = x_offs+vol_w,
                        y = y_offs ,
                        w =chan_w,
                        h = obj.entry_h,
                        frame_a = 0,
                        frame_rect_a = 0.1,
                        fontsz = obj.fontsz_entry,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        txt = 'src '..chansrc_txt,
                        func = function()SendTracksChannels(data, mouse,conf)
                          
                        end}  
    obj.b.obj_sendto_channels2 = { x = x_offs+vol_w,
                        y = y_offs +obj.entry_h,
                        w =chan_w,
                        h = obj.entry_h,
                        frame_a = 0,
                        frame_rect_a = 0.1,
                        fontsz = obj.fontsz_entry,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        txt = 'dest '..chandest_txt,
                        func = function()SendTracksChannels(data, mouse,conf,1)
                          
                        end}                     
                
                        
    -- sliders
    obj.b.obj_sendto_vol = { x = x_offs,
                        y = y_offs ,
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
      if conf.dock_orientation == 1 then
        obj.b.obj_sendto_vol.w = obj.entry_w2 - send_but
      end                         
      local svol_str = data.defsendvol_format
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = MPL_GetTableOfCtrlValues2(svol_str),
                        table_key='svol_ctrl',
                        x_offs= obj.b.obj_sendto_vol.x,  
                        y_offs= obj.b.obj_sendto_vol.y,  
                        w_com=obj.b.obj_sendto_vol.w,
                        src_val=data.defsendvol,
                        modify_func= MPL_ModifyFloatVal,
                        app_func= Apply_STrack_vol,                         
                        mouse_scale= obj.mouse_scal_vol,               -- mouse scaling
                        use_mouse_drag_xAxis= true, -- x
                        ignore_fields= true, -- same tolerance change
                        --y_offs= obj.offs,
                        dont_draw_val = true,
                        default_val = tonumber(({BR_Win32_GetPrivateProfileString( 'REAPER', 'defsendvol', '0',  get_ini_file() )})[2])})
    obj.b.obj_sendto_pan = { x = x_offs,
                        y = y_offs +obj.entry_h,
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
      if conf.dock_orientation == 1 then
        obj.b.obj_sendto_pan.w = obj.entry_w2 - send_but
      end                                                 
      local span_str = data.defsendpan_format
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = MPL_GetTableOfCtrlValues2(span_str),
                        table_key='span_ctrl',
                        x_offs= obj.b.obj_sendto_pan.x,  
                        y_offs= obj.b.obj_sendto_pan.y,  
                        w_com=obj.b.obj_sendto_pan.w,
                        src_val=data.defsendpan,
                        --src_val_key= '',
                        modify_func= MPL_ModifyFloatVal,
                        app_func= Apply_STrack_pan,                         
                        mouse_scale= obj.mouse_scal_pan,               -- mouse scaling
                        use_mouse_drag_xAxis= true, -- x
                        ignore_fields= true, -- same tolerance change
                        --y_offs= obj.offs+obj.entry_h,
                        dont_draw_val = true,
                        default_val = 0})
    return send_w , obj.entry_h*2
  end
  ------------------------------------------------------------------------------------------
  function Apply_STrack_vol(data, obj, t_out_values, butkey, out_str_toparse)
    if not out_str_toparse then 
      data.defsendvol = lim(t_out_values,-1,1)
      local new_str = string.format("%.2f", t_out_values)
      local new_str_t = MPL_GetTableOfCtrlValues2(new_str)
      if new_str_t then 
        for i = 1, #new_str_t do
          if obj.b[butkey..i] then obj.b[butkey..i].txt = '' end--new_str_t[i]
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
      out_val = ParseDbVol(out_str_toparse)
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
      local out_val = MPL_ParsePanVal(out_str_toparse)
      data.defsendpan= out_val
      redraw = 2   
    end
  end  
  ---------------------------------------------------------
  function SendTracksTo(data,mouse,conf) 
    local GUID  =GetTrackGUID( data.tr[1].ptr )
    local is_predefSend = data.PreDefinedSend_GUID[GUID] ~= nil
    local t = {
          {str = '#Send '..#data.tr..' selected track(s)'}  
        }  
    local unpack_prefed = ({table.unpack(SendTracksTo_CollectPreDef(data, GUID,conf))})
    for i = 1, #unpack_prefed do table.insert(t, unpack_prefed[i]) end
    
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
             
             
    t[#t+1] ={str = 'Select predefined send tracks',
             func = function ()
                      Action(40297)-- Track: Unselect all tracks
                      for i = 1, #unpack_prefed do
                        if unpack_prefed[i].GUID then 
                          local tr = BR_GetMediaTrackByGUID( 0, unpack_prefed[i].GUID )
                          if ValidatePtr2(0, tr, 'MediaTrack*') then SetTrackSelected( tr, true ) end
                        end
                      end
                    end}
                    
    t[#t+1] ={str = 'Reset predefined send volume/pan',
             func = function ()
                      data.defsendvol = 1
                      data.defsendpan = 0
                      redraw = 2 
                    end}                    
                   
             
                     
                          
    Menu( mouse, t )
  end
  ---------------------------------------------------------
  function UpdatePreDefGUIDs(data)
    local str = ''
    for GUID in pairs(data.PreDefinedSend_GUID) do str = str..' '..GUID end
    SetProjExtState( 0, 'MPL_InfoTool', 'PreDefinedSend_GUID', str )
  end
  ---------------------------------------------------------
  function SendTracksTo_CollectTopFold(data,conf)
    local out_t = {{str = '|#Top parent folders'}}
    for i = 1, CountTracks(0) do
      local tr = GetTrack(0,i-1)
      if GetTrackDepth( tr ) == 0 then
        out_t[#out_t+1] = { str =  ({GetTrackName( tr, '' )})[2],
                            func =  function() SendTracksTo_AddSend(data,tr,conf) end}
      end
    end
    return out_t     
  end
  ---------------------------------------------------------
  function SendTracksTo_CollectPreDef(data, GUID0,conf)
    local out_t1 = {}
    local out_t = {}
    for GUID in pairs(data.PreDefinedSend_GUID) do 
      local tr = BR_GetMediaTrackByGUID( 0, GUID )
      if tr and GUID0 ~= GUID then
        local str =  ({GetTrackName( tr, '' )})[2]
        out_t1[str] = {str = str,  
                      GUID = GUID,
                      func =  function() SendTracksTo_AddSend(data, tr,conf) end}
      end
    end
    
    for key in spairs(out_t1) do out_t[#out_t+1] = out_t1[key] end
    table.insert(out_t, 1, {str = '|#PreDefined sends list'})
    return out_t  
  end
  ---------------------------------------------------------
  function SendTracksTo_AddSend(data, dest_tr_ptr,conf)
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
           
        SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_SRCCHAN', data.defsend_chansrc)
        SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_DSTCHAN', data.defsend_chandest)
      end
  end
-----------------------------------------------------------   







-----------------------------------------------------------   
  function Widgets_Track_chsendmixer(data, obj, mouse, x_offs, widgets, conf, y_offs)
    if data.tr_cnt_sends + data.tr_cnt_sendsHW == 0 then return end
    local send_name_w = 120*conf.scaling
    local ch_w = 12  *conf.scaling
    local send_w = send_name_w + (data.tr_cnt_sends + data.tr_cnt_sendsHW) * ch_w
    if conf.dock_orientation == 1 then
      send_w = gfx.w
      send_name_w = send_w - (data.tr_cnt_sends + data.tr_cnt_sendsHW) * ch_w
    end
    
    if x_offs + send_w > obj.persist_margin then return x_offs end 
    obj.b.obj_sendmix_back1 = { x = x_offs,
                        y =y_offs,
                        w = send_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        --txt = 'test',
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        ignore_mouse = true}  
    obj.b.obj_sendmix_back2 = { x = x_offs,
                        y = y_offs+obj.entry_h ,
                        w = send_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        ignore_mouse = true} 
                       
    local ch_w = 12*conf.scaling
    local ch_h = math.floor(obj.entry_h*1.8)
    local ch_y = y_offs + (obj.entry_h*2-math.floor(obj.entry_h*1.8))/2
    for i = 1, data.tr_cnt_sends + data.tr_cnt_sendsHW do
      local slider_a if data.active_context_id and data.active_context_id == i then slider_a = 0.5 else slider_a = 0.2 end
      local val = lim(data.tr_send[i].s_vol_slider)
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
                        val = val,
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
                                                  Apply_SendMix_vol_input(data.tr_send[data.active_context_id].s_vol_dB, data)
                                                 elseif data.MM_doubleclick == 1 then
                                                  Apply_SendMix_vol_reset(data)
                                                end
                                              end,
                          func_R =      function()
                                                if data.MM_rightclick == 0 then 
                                                  Apply_SendMix_vol_reset(data)
                                                 elseif data.MM_rightclick == 1 then
                                                  Apply_SendMix_vol_input(data.tr_send[data.active_context_id].s_vol_dB, data)
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
                        y = y_offs ,
                        w = send_name_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = 0,
                        txt = txt,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        --ignore_mouse = true,
                        fontsz = obj.fontsz_entry,
                        func = function() 
                                 local send_id = data.active_context_id                                 
                                 --local str_ptr = BR_GetMediaTrackSendInfo_Track( data.tr[1].ptr, 0, send_id-1, 1 )
                                 local str_ptr = GetTrackSendInfo_Value( data.tr[1].ptr, 0, send_id-1,'P_DESTTRACK' ) 
                                 TrackFX_SetOpen( str_ptr, 0, true )
                                end} 
    if data.active_context_sendmixer_val then

      obj.b.obj_sendmix_tr_s_vol = { x = x_offs+mix_fields,
                          y = y_offs+obj.entry_h ,
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
                                                  Apply_SendMix_vol_input(data.tr_send[data.active_context_id].s_vol_dB, data)
                                                 elseif data.MM_doubleclick == 1 then
                                                  Apply_SendMix_vol_reset(data)
                                                end
                                              end,
                          func_R =      function()
                                                if data.MM_rightclick == 0 then 
                                                  Apply_SendMix_vol_reset(data)
                                                 elseif data.MM_rightclick == 1 then
                                                  Apply_SendMix_vol_input(data.tr_send[data.active_context_id].s_vol_dB, data)
                                                end
                                              end
                      } 
    end                                                                       
    return send_w, obj.entry_h*2
  end
  -------------------
  function Apply_SendMix_vol_input(srcval, data)
    local ret, outstr = GetUserInputs( 'Edit', 1, '', srcval )
    if not ret then return end
    local out_val = ParseDbVol(outstr)
    if not data.tr[1] or not data.active_context_id or not out_val then return end
    SetTrackSendInfo_Value( data.tr[1].ptr, 0, data.active_context_id-1-data.tr_cnt_sendsHW, 'D_VOL', out_val )
    data.active_context_sendmixer_val = out_val
    redraw = 2   
  end
  -------------------
  function Apply_SendMix_vol_reset(data)
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
  function Widgets_Track_chrecvmixer(data, obj, mouse, x_offs, widgets, conf, y_offs)
    if data.tr_cnt_receives == 0 then return end
    local recv_name_w = 120*conf.scaling
    local ch_w = 12  *conf.scaling
    local recv_w = recv_name_w + data.tr_cnt_receives * ch_w
    if conf.dock_orientation == 1 then
      recv_w = gfx.w
      recv_name_w = recv_w - (data.tr_cnt_sends + data.tr_cnt_sendsHW) * ch_w
    end    
    if x_offs + recv_w > obj.persist_margin then return x_offs end 
    obj.b.obj_recvmix_back1 = { x = x_offs,
                        y = y_offs ,
                        w = recv_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        --txt = 'test',
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        ignore_mouse = true}  
    obj.b.obj_recvmix_back2 = { x = x_offs,
                        y = y_offs+obj.entry_h ,
                        w = recv_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        ignore_mouse = true} 
      if conf.dock_orientation == 1 then
        obj.b.obj_recvmix_back1.w = obj.entry_w2
        obj.b.obj_recvmix_back2.w = obj.entry_w2
      end                        
    local ch_w = 12*conf.scaling
    local ch_h = math.floor(obj.entry_h*1.8)
    local ch_y = y_offs + (obj.entry_h*2-math.floor(obj.entry_h*1.8))/2
    local mix_fields = recv_w-data.tr_cnt_receives * ch_w - 6
    for i = 1, data.tr_cnt_receives do
      local slider_a 
      if data.active_context_id2 and data.active_context_id2 == i then slider_a = 0.5 else slider_a = 0.2 end
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
                                                  Apply_RecvMix_vol_input(data, data.tr_recv[data.active_context_id2].r_vol_dB)
                                                 elseif data.MM_doubleclick == 1 then
                                                  Apply_RecvMix_vol_reset(data)
                                                end
                                              end,
                          func_R =      function()
                                                if data.MM_rightclick == 0 then 
                                                  Apply_RecvMix_vol_reset(data)
                                                 elseif data.MM_rightclick == 1 then
                                                  Apply_RecvMix_vol_input(data, data.tr_recv[data.active_context_id2].r_vol_dB)
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
                        y = y_offs ,
                        w = recv_name_w,
                        h = obj.entry_h,
                        frame_a = 0,
                        txt = txt,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        --ignore_mouse = true,
                        fontsz = obj.fontsz_entry,
                        func =  function() 
                                  if data.active_context_id2 and data.tr_recv[data.active_context_id2] then
                                    SetOnlyTrackSelected(  data.tr_recv[data.active_context_id2].srctr_ptr)
                                  end
                                end  } 
    if data.active_context_sendmixer_val2 then

      obj.b.obj_recvmix_tr_s_vol = { x = x_offs,
                          y = y_offs+obj.entry_h ,
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
                                                  Apply_RecvMix_vol_input(data , data.tr_recv[data.active_context_id2].r_vol_dB)
                                                 elseif data.MM_doubleclick == 1 then
                                                  Apply_RecvMix_vol_reset(data)
                                                end
                                              end,
                          func_R =      function()
                                                if data.MM_rightclick == 0 then 
                                                  Apply_RecvMix_vol_reset(data)
                                                 elseif data.MM_rightclick == 1 then
                                                  Apply_RecvMix_vol_input(data, data.tr_recv[data.active_context_id2].r_vol_dB)
                                                end
                                              end
                      } 
    end                                                                       
    return recv_w,  obj.entry_h*2
  end
  -------------------
  function Apply_RecvMix_vol_input(data, srcval)
    local ret, outstr = GetUserInputs( 'Edit', 1, '', srcval )
    if not ret then return end
    local out_val = ParseDbVol(outstr)
    if not data.tr[1] or not data.active_context_id2 or not out_val then return end
    SetTrackSendInfo_Value( data.tr[1].ptr, -1, data.active_context_id2-1, 'D_VOL', out_val )
    data.active_context_sendmixer_val2 = out_val
    redraw = 2   
  end
  -------------------
  function Apply_RecvMix_vol_reset(data)
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
  function Widgets_Track_fxcontrols(data, obj, mouse, x_offs, widgets, conf, y_offs)
    if not data.tr_FXCtrl or not data.tr[1].GUID or not data.tr_FXCtrl[data.tr[1].GUID] then return 0,0 end
    local ch_w = 12*conf.scaling
    local fxctrl_menu_w = 20*conf.scaling
    local fxctrl_name_w = 100*conf.scaling
    
    local fxctrl_w
    local mix_fields = 0
    if data.tr_FXCtrl[data.tr[1].GUID] then 
      mix_fields = #data.tr_FXCtrl[data.tr[1].GUID] * ch_w
      fxctrl_w = mix_fields + fxctrl_menu_w + fxctrl_name_w
     else
      fxctrl_w = fxctrl_menu_w
    end
    
    if conf.dock_orientation == 1 then
      fxctrl_w = gfx.w
      mix_fields = #data.tr_FXCtrl[data.tr[1].GUID] * ch_w
      fxctrl_menu_w = (fxctrl_w - mix_fields) * 0.2
      fxctrl_name_w = (fxctrl_w - mix_fields) * 0.8
    end
    
    if x_offs + fxctrl_w > obj.persist_margin then return x_offs, obj.entry_h*2 end 
    
    obj.b.obj_fxctrl_back1 = { x = x_offs,
                        y = y_offs ,
                        w = fxctrl_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        --txt = 'test',
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        ignore_mouse = true} 
    if conf.dock_orientation == 1 then
      obj.b.obj_fxctrl_back1.x= 0
      obj.b.obj_fxctrl_back1.y = y_offs
      obj.b.obj_fxctrl_back1.w = gfx.w-fxctrl_menu_w
      obj.b.obj_fxctrl_back1.h = obj.entry_h*2
    end                         
    obj.b.obj_fxctrl_back2 = { x = x_offs,
                        y = y_offs+obj.entry_h ,
                        w = fxctrl_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        ignore_mouse = true}
    if conf.dock_orientation == 1 then
      obj.b.obj_fxctrl_back2.x= gfx.w-fxctrl_menu_w
      obj.b.obj_fxctrl_back2.y = y_offs
      obj.b.obj_fxctrl_back2.w = fxctrl_menu_w
      obj.b.obj_fxctrl_back2.h = obj.entry_h*2
      obj.b.obj_fxctrl_back2.frame_a = obj.frame_a_head
    end                        
 
                            
    obj.b.obj_fxctrl_app = {x = x_offs + fxctrl_w- fxctrl_menu_w,
                          y =  y_offs,
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
                                                            UpdateFXCtrls(data, linktrGUID, trackGUID, FX_GUID, paramnumberOut, 0, 1 )
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
    --[[if conf.dock_orientation == 1 then
      obj.b.obj_fxctrl_app.x= obj.entry_w2-fxctrl_menu_w
      obj.b.obj_fxctrl_app.y = y_offs
      obj.b.obj_fxctrl_app.w = fxctrl_menu_w
    end  ]]                     
    if not data.tr_FXCtrl[data.tr[1].GUID] then return fxctrl_w, obj.entry_h*2 end                      
    local ch_h = math.floor(obj.entry_h*1.8)
    local ch_y = y_offs + (obj.entry_h*2-math.floor(obj.entry_h*1.8))/2
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
      return fxctrl_w, obj.entry_h*2
    end
    obj.b.fxctrl_fxname = { x = x_offs + mix_fields+4,
                        y = y_offs,
                        w = fxctrl_w - mix_fields -4,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = 0,
                        txt = fxname,
                        txt_a = obj.txt_a,
                        aligh_txt = 1,
                        txt_col = obj.txt_col_entry,
                        fontsz = obj.fontszFXctrl,
                        func = function ()  Apply_FXCtrl_FloatFX(data.tr_FXCtrl[data.tr[1].GUID][data.active_context_id3]) end} 
                      
    obj.b.fxctrl_name = { x = x_offs + mix_fields+4,
                        y = y_offs+obj.fontszFXctrl-2 ,
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
                          y =y_offs+ obj.fontszFXctrl*2-3 ,
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
    return fxctrl_w, obj.entry_h*2
  end  
  ---------------------------------------------------------------
  function UpdateFXCtrls(data, linktrGUID, trackGUID, FX_GUID, paramnum, lim1, lim2)
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
  function Widgets_Track_freeze(data, obj, mouse, x_offs, widgets, conf, y_offs)
    local w = 80*conf.scaling
    if not data.tr or not data.tr.freezecnt_format then return end
    if x_offs + w > obj.persist_margin then return x_offs end 
    obj.b.obj_tr_freeze = { x = x_offs,
                        y = y_offs ,
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
                        y =y_offs+obj.entry_h ,
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
      if conf.dock_orientation == 1 then
        obj.b.obj_tr_freeze.x= 0
        obj.b.obj_tr_freeze.w = obj.entry_w2/2
        obj.b.obj_tr_freeze.x= obj.entry_w2/2
        obj.b.obj_tr_unfreeze.y = y_offs
        obj.b.obj_tr_unfreeze.w = obj.entry_w2/2
        obj.b.obj_tr_unfreeze.frame_a = obj.frame_a_head
      end                         
    return w
  end
  
  
  
  function Widgets_Track_color(data, obj, mouse, x_offs, widgets, conf, y_offs)    -- generate position controls 
    local col_w = 20*conf.scaling
    if x_offs + col_w > obj.persist_margin then return end 
    if not data.tr[1].col then return end
    local a = 0.5
    if data.tr[1].col == 0 then a = 0.35 end
    obj.b.obj_trcolor = { x = x_offs,
                        y = y_offs,
                        w = col_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        state = data.tr[1].col ~= 0,
                        state_col = data.tr[1].col,
                        state_a = a,
                        func = function() Apply_TrackCol(data, conf) end} 
    obj.b.obj_trcolor_back = { x =  x_offs,
                        y = y_offs +obj.entry_h ,
                        w = col_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        state = data.tr[1].col ~= 0,
                        state_col = data.tr[1].col,
                        state_a = a,
                        func = function() Apply_TrackCol(data, conf) end
                        }
      if conf.dock_orientation == 1 then
        obj.b.obj_trcolor.x= 0
        obj.b.obj_trcolor.y = y_offs
        obj.b.obj_trcolor.w = obj.entry_w2
        obj.b.obj_trcolor.frame_a = obj.frame_a_head
        obj.b.obj_trcolor_back = nil
      end                               
    return col_w                       
  end  
  
  function Apply_TrackCol(data, conf)
    if conf.use_custom_color_editor~='' then 
      Action(conf.use_custom_color_editor)
     else
      local retval, colorOut = GR_SelectColor( '' )
      if retval == 0 then return end
      for i = 1, #data.tr do
        local tr= data.tr[i].ptr
        SetTrackColor( tr, colorOut )
      end
    end
  end

------------------------------------------------------------------
function Widgets_Track_troffs(data, obj, mouse, x_offs, widgets, conf, y_offs)    -- generate position controls 
  if not VF_CheckReaperVrs(6.0,false) then return end 
    local del_w = 60*conf.scaling
    if x_offs + del_w > obj.persist_margin then return x_offs end 
    obj.b.obj_trdelay2 = { x = x_offs,
                        y = y_offs ,
                        w = del_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'Offset'} 
    obj.b.obj_trdelay2_back = { x =  x_offs,
                        y = y_offs+obj.entry_h ,
                        w = del_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = (data.tr[1].toffs*1000)..'ms',
                        fontsz = obj.fontsz_entry,
                        ignore_mouse = true}  
      if conf.dock_orientation == 1 then
        obj.b.obj_trdelay2.w = obj.entry_w2/2
        obj.b.obj_trdelay2_back.x= obj.entry_w2/2
        obj.b.obj_trdelay2_back.y = y_offs
        obj.b.obj_trdelay2_back.w = obj.entry_w2/2
        obj.b.obj_trdelay2_back.frame_a = obj.frame_a_head
      end                         
                        
      local troffs_str = data.tr[1].toffs
      
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = {troffs_str},
                        table_key='troffs_ctrl',
                        x_offs= obj.b.obj_trdelay2_back.x,  
                        y_offs= obj.b.obj_trdelay2_back.y,  
                        w_com=obj.b.obj_trdelay2_back.w,
                        src_val=data.tr,
                        src_val_key= 'toffs',
                        modify_func= MPL_ModifyTimeVal,
                        app_func= Apply_Track_offset,                         
                        mouse_scale= obj.mouse_scal_time,
                        default_val=0,
                        modify_wholestr = true,
                        dont_draw_val = true,
                        onRelease_ActName = data.scr_title..': Change track properties',
                        use_mouse_drag_xAxis = data.always_use_x_axis==1})                            
    return del_w                       
  end  
function Apply_Track_offset(data, obj, t_out_values, butkey, out_str_toparse, mouse)
    if not out_str_toparse then   
      test = t_out_values
      for i = 1, #t_out_values do
        local value = lim(t_out_values[i], -0.5, 0.5)
        if mouse.Ctrl then value = lim(t_out_values[1], -0.5, 0.5) end 
        if data.tr[i].toffs_flag&2==2 then value = math.floor(data.SR*value) end
        if data.tr[i].toffs_flag&1==1 then SetMediaTrackInfo_Value( data.tr[i].ptr, 'I_PLAY_OFFSET_FLAG', data.tr[i].toffs_flag-1 )  end
        SetMediaTrackInfo_Value( data.tr[i].ptr, 'D_PLAY_OFFSET', value ) 
      end
      --local new_str = format_timestr_len( t_out_values[1], '', 0, 3 )
      obj.b.obj_trdelay2_back.txt = (math.floor(t_out_values[1]*10000)/10)..'ms'
     else
      -- nudge values from first item
      local out_val = parse_timestr_len(out_str_toparse,0,3) 
      local diff = data.tr[1].toffs - out_val
      for i = 1, #t_out_values do
        local out = t_out_values[i] - diff
        local value = lim(out, -0.5, 0.5)
        if data.tr[i].toffs_flag&2==2 then value = math.ceil(data.SR*value) end
        SetMediaTrackInfo_Value( data.tr[i].ptr, 'D_PLAY_OFFSET', value )
      end
      redraw = 2   
    end
  end    
  -------------------------------------------------------------- 
