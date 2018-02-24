-- @description InteractiveToolbar_Widgets_Persist
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex


  -- Persistent wigets for mpl_InteractiveToolbar
  
  ---------------------------------------------------
  function Obj_UpdatePersist(data, obj, mouse, widgets)
    local x_margin = gfx.w-obj.offs
    if widgets.Persist then
      for i = 1, #widgets.Persist do
        local key = widgets.Persist[i]
        if _G['Widgets_Persist_'..key] then
          local ret = _G['Widgets_Persist_'..key](data, obj, mouse, x_margin, widgets) 
          if ret then x_margin = x_margin - ret end
        end
      end  
    end
    return x_margin
  end
  -------------------------------------------------------------- 








------------------------------------------------------------
  function Widgets_Persist_grid(data, obj, mouse, x_margin, widgets)    -- generate position controls 
    local grid_widg_val_w = 50
    local grid_widg_w_trpl = 20
    local grid_widg_w = grid_widg_val_w+ grid_widg_w_trpl
    local frame_a = 0
    local gridwidg_xpos = gfx.w-grid_widg_w-obj.menu_b_rect_side - x_margin
    if data.grid_isactive then  frame_a = obj.frame_a_state end
    obj.b.obj_pers_grid_back = { x = x_margin - grid_widg_w,
                        y = 0 ,
                        w = grid_widg_w,
                        h = obj.entry_h*2,
                        frame_a = obj.frame_a_entry,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = '',
                        ignore_mouse = true} 
    obj.b.obj_pers_grid_val = { x = x_margin - grid_widg_w,
                        y = 0 ,
                        w = grid_widg_val_w,
                        h = obj.entry_h*2,
                        frame_a = frame_a,
                        --frame_rect_a = 1,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = data.grid_val_format,
                        func =        function()
                                        mouse.temp_val = data.grid_val
                                        mouse.temp_val2 = data.grid_istriplet
                                        redraw = 1                            
                                      end,
                        func_wheel =  function()local div
                                        if mouse.wheel_trig > 0 then div = 2 
                                          elseif mouse.wheel_trig < 0 then div = 0.5 
                                        end 
                                        local lim_max = 1
                                        if data.grid_istriplet then lim_max = 2/3 end
                                        local out_val = lim(data.grid_val*div, 0.0078125*lim_max, lim_max)
                                        GetSetProjectGrid( 0, true, out_val  )
                                        redraw = 2                           
                                      end,                                              
                        func_drag =   function() 
                                        if mouse.temp_val then 
                                          local mouse_shift = math.floor(mouse.dy/30)
                                          local div = 1
                                          
                                          if mouse_shift > 0 then div = 2^math.abs(mouse_shift)
                                           elseif mouse_shift < 0 then div = 0.5^math.abs(mouse_shift)
                                          end 
                                          
                                          if div then 
                                            local lim_max = 1
                                            if data.grid_istriplet then lim_max = 2/3 end
                                            local out_val = lim(mouse.temp_val*div, 0.0078125*lim_max, lim_max)                                         
                                            GetSetProjectGrid( 0, true, out_val  )
                                            _, obj.b.obj_pers_grid_val.txt = MPL_GetFormattedGrid()
                                            redraw = 1  
                                          end 
                                        end
                                      end,
                        func_DC =     function()
                                        Main_OnCommand(40071, 0) -- open settings
                                        redraw = 2
                                      end,
                        func_R =     function()
                                        Main_OnCommand(1157, 0) -- toggle grid
                                        redraw = 2
                                      end,                                      
                                      
                                      
                                      }
    local tripl_a = obj.frame_a_state
    if not data.grid_istriplet then  tripl_a = 0 end
    obj.b.obj_pers_grid_tripl = { x = x_margin - grid_widg_w+ grid_widg_val_w,
                        y = 0 ,
                        w = grid_widg_w_trpl,
                        h = obj.entry_h*2,
                        frame_a = tripl_a,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'T',                          
                        func =  function() 
                                  if not data.grid_istriplet then
                                    GetSetProjectGrid( 0, true, data.grid_val  * 2/3 )--
                                   else 
                                    GetSetProjectGrid( 0, true, data.grid_val  * 3/2  )
                                  end
                                  redraw = 2
                                end}                
    return grid_widg_w
  end  




  --------------------------------------------------------------
  function Widgets_Persist_timeselstart(data, obj, mouse, x_margin, widgets)    -- generate position controls 
    obj.b.obj_tsstart = { x = x_margin-obj.entry_w2,
                        y = obj.offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'TimeSelStart'} 
    obj.b.obj_tsstart_back = { x =  x_margin-obj.entry_w2,
                        y = obj.offs *2 +obj.entry_h ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
                        
                        
      local TSpos_str =  data.timeselectionstart_format

      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = MPL_GetTableOfCtrlValues(TSpos_str), 
                        table_key='timesel_position_ctrl',
                        x_offs=  x_margin-obj.entry_w2,  
                        w_com=obj.entry_w2,
                        src_val=data.timeselectionstart,
                        src_val_key= '',
                        modify_func= MPL_ModifyTimeVal,
                        app_func= Apply_TimeselSt,                         
                        mouse_scale= obj.mouse_scal_time})                         
    return obj.entry_w2
  end  
  function Apply_TimeselSt(data, obj, out_value, butkey, out_str_toparse, mouse)
    if not out_str_toparse then  
      local startOut, endOut = GetSet_LoopTimeRange2( 0, false, false, -1, -1, false )
      local nudge = startOut - math.max(0,out_value)  
      GetSet_LoopTimeRange2( 0, true, true, math.max(0,out_value), endOut-nudge, false )
      Main_OnCommand(40749,0) -- Options: Set loop points linked to time selection
      local new_str = format_timestr_pos( math.max(0,out_value), '', -1 ) 
      local new_str_t = MPL_GetTableOfCtrlValues(new_str)
      for i = 1, #new_str_t do
        obj.b[butkey..i].txt = new_str_t[i]
      end
     else
      -- nudge values from first item
      local out_val = parse_timestr_pos(out_str_toparse,-1) 
      local startOut, endOut = GetSet_LoopTimeRange2( 0, false, false, -1, -1, false )  
      local nudge = startOut - math.max(0,out_val) 
      GetSet_LoopTimeRange2( 0, true, true, math.max(0,out_val), endOut-nudge, false )
      redraw = 2   
    end
  end  
  -------------------------------------------------------------- 








  --------------------------------------------------------------
  function Widgets_Persist_timeselend(data, obj, mouse, x_margin, widgets)    -- generate position controls 
    obj.b.obj_tsend = { x = x_margin-obj.entry_w2,
                        y = obj.offs ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = 'TimeSelEnd'} 
    obj.b.obj_tsend_back = { x =  x_margin-obj.entry_w2,
                        y = obj.offs *2 +obj.entry_h ,
                        w = obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        ignore_mouse = true}  
                        
                        
      local TSposend_str =  data.timeselectionend_format
      Obj_GenerateCtrl(  { data=data,obj=obj,  mouse=mouse,
                        t = MPL_GetTableOfCtrlValues(TSposend_str), 
                        table_key='timeselend_position_ctrl',
                        x_offs= x_margin-obj.entry_w2,  
                        w_com=obj.entry_w2,--obj.entry_w2,
                        src_val=data.timeselectionend,
                        src_val_key= '',
                        modify_func= MPL_ModifyTimeVal,
                        app_func= Apply_Timeselend,                         
                        mouse_scale= obj.mouse_scal_time})                         
    return obj.entry_w2
  end  
  function Apply_Timeselend(data, obj, out_value, butkey, out_str_toparse, mouse)
    if not out_str_toparse then  
      local startOut, endOut = GetSet_LoopTimeRange2( 0, false, false, -1, -1, false )  
      GetSet_LoopTimeRange2( 0, true, true, startOut, math.max(0,out_value), false )
      Main_OnCommand(40749,0) -- Options: Set loop points linked to time selection
      local new_str = format_timestr_pos( math.max(0,out_value), '', -1 ) 
      local new_str_t = MPL_GetTableOfCtrlValues(new_str)
      for i = 1, #new_str_t do
        obj.b[butkey..i].txt = new_str_t[i]
      end
     else
      -- nudge values from first item
      local out_val = parse_timestr_pos(out_str_toparse,-1) 
      local startOut, endOut = GetSet_LoopTimeRange2( 0, false, false, -1, -1, false )  
      GetSet_LoopTimeRange2( 0, true, true, startOut, math.max(0,out_value), false )
      redraw = 2   
    end
  end  
  -------------------------------------------------------------- 






------------------------------------------------------------
  function Widgets_Persist_transport(data, obj, mouse, x_margin, widgets)    -- generate position controls 
    local transport_state_w = 60
    local frame_a = 0
    local txt = 'Stop'
    local gridwidg_xpos = gfx.w-transport_state_w-obj.menu_b_rect_side - x_margin
    obj.b.obj_pers_transport_back = { x = x_margin - transport_state_w,
                        y = obj.offs ,
                        w = transport_state_w,
                        h = obj.entry_h*2,
                        frame_a = obj.frame_a_entry,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = '',
                        ignore_mouse = true} 
    local state_col, state
    if  data.record  then
      state = true
      txt = 'Record'
      state_col = 'red'
     elseif data.play  then
      state = true
      txt = 'Play'
      state_col = 'green'
     elseif data.pause  then
      txt = 'Pause'
      state = true
      state_col = 'greendark'
     else
    end
    obj.b.obj_pers_transport_state = { x = x_margin - transport_state_w,
                        y =  0,
                        w = transport_state_w,
                        h = obj.entry_h*2,
                        frame_a = frame_a,--,
                        state_col = state_col,
                        state = state,
                        --frame_rect_a = 1,
                        txt_a = obj.txt_a,
                        txt_col = 'white',
                        txt = txt,
                        func =        function()
                                        if data.pause then
                                          Main_OnCommand(1016, 0) --Transport: Stop
                                          if data.play_editcurzeropos then SetEditCurPos( data.play_editcurzeropos, true , true ) end
                                         else
                                          Main_OnCommand(40044, 0) -- Transport: Play/stop
                                          data.play_editcurzeropos = GetCursorPositionEx( 0 )
                                        end
                                        redraw = 1                            
                                      end,   
                        func_ctrlL =   function()
                                        if not data.play then
                                          data.play_editcurzeropos = GetCursorPositionEx( 0 )
                                        end
                                        Main_OnCommand(1013, 0) -- Transport: Record                                       
                                        redraw = 1
                                      end,
                        func_R =     function()
                                        Main_OnCommand(40073, 0) -- Transport: Play/pause                                        
                                        redraw = 1
                                      end,                                      
                                      
                                      
                                      }
    return transport_state_w
  end  
  
  
  
  
  
  
  
  function Widgets_Persist_bpm(data, obj, mouse, x_margin, widgets)  
    local bpm_w = 60
    local frame_a = 0
    local gridwidg_xpos = gfx.w-bpm_w-obj.menu_b_rect_side - x_margin
    obj.b.obj_pers_bpm = { x = x_margin - bpm_w,
                        y = obj.offs ,
                        w = bpm_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        fontsz = obj.fontsz_entry,
                        txt = data.TempoMarker_bpm,
                        func =  function()  
                                  local retval0,ret_str = GetUserInputs( 'Edit BPM', 1, 'BPM', data.TempoMarker_bpm )
                                  if retval0 and tonumber (ret_str) then
                                    if data.TempoMarker_ID == -1 then 
                                      CSurf_OnTempoChange(  tonumber (ret_str) )
                                      UpdateTimeline()
                                      redraw = 2  
                                     else 
                                      SetTempoTimeSigMarker( 0, data.TempoMarker_ID, 
                                                                data.TempoMarker_timepos, 
                                                                -1, 
                                                                -1, 
                                                                tonumber (ret_str), 
                                                                data.TempoMarker_timesig_num, 
                                                                data.TempoMarker_timesig_denom, 
                                                                data.TempoMarker_lineartempochange )
                                      UpdateTimeline()
                                    end
                                  end
                                end}
    obj.b.obj_pers_timesign = { x = x_margin - bpm_w,
                        y = obj.offs +obj.entry_h,
                        w = bpm_w,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_entry,
                        fontsz = obj.fontsz_entry,
                        txt = data.TempoMarker_timesig1..'/'..data.TempoMarker_timesig2,
                        func =  function()  
                                  local retval0,ret_str = GetUserInputs( 'Edit Time signature', 2, 'Numerator,Denomerator', data.TempoMarker_timesig1..','..data.TempoMarker_timesig2 )
                                  if not retval0 then return end
                                  if not ret_str:match('(%d+)%,(%d+)') then return end
                                  local num, denom = ret_str:match('(%d+)%,(%d+)')
                                  if not tonumber(num) or not tonumber(denom) then return end
                                  if data.TempoMarker_ID ~= -1 then 
                                    SetTempoTimeSigMarker( 0, data.TempoMarker_ID, 
                                                                data.TempoMarker_timepos, 
                                                                -1, 
                                                                -1, 
                                                                data.TempoMarker_bpm, 
                                                                tonumber(num), 
                                                                tonumber(denom), 
                                                                data.TempoMarker_lineartempochange )
                                      UpdateTimeline()
                                    else 
                                    SetTempoTimeSigMarker( 0,-1, 
                                                                data.editcur_pos, 
                                                                -1, 
                                                                -1, 
                                                                data.TempoMarker_bpm, 
                                                                tonumber(num), 
                                                                tonumber(denom), 
                                                                data.TempoMarker_lineartempochange )
                                      UpdateTimeline()                                     
                                  end
                                end}                    
    return bpm_w
  end    
  
  
  
  
  
  
  
  
  
  
  
  
  ----------------------------------------------------------------------------
  function Widgets_Persist_lasttouchfx(data, obj, mouse, x_margin, widgets)
    local lasttouchfx_w = 160 
    local val_w = 50
    local knob_x_offs = 5
    if not data.LTFX.exist or data.LTFX_parname == 'Bypass' or data.LTFX_fxname == 'JS: time_adjustment' then return end
    obj.b.obj_lasttouchfx_back1 = { x = x_margin-lasttouchfx_w,
                        y = obj.offs ,
                        w = lasttouchfx_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        fontsz = obj.fontsz_entry,
                        txt = '',
                        ignore_mouse = true}    
    obj.b.obj_lasttouchfx = { x = x_margin-lasttouchfx_w,
                        y = obj.offs ,
                        w = lasttouchfx_w-val_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        fontsz = obj.fontsz_entry,
                        txt = MPL_ReduceFXname(data.LTFX_fxname),
                        func = function() 
                          TrackFX_Show( data.LTFX_trptr, data.LTFX_fxID, 3 ) 
                        end} 
    obj.b.obj_lasttouchfx_param = { x =  x_margin-lasttouchfx_w,
                        y = obj.offs *2 +obj.entry_h ,
                        w = lasttouchfx_w-val_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = 0,
                        txt = data.LTFX_parname,
                        fontsz = obj.fontsz_entry,
                        func = function () 
                                  --Main_OnCommand(41984,0)--FX: Arm track envelope for last touched FX parameter
                                  TrackFX_Show( data.LTFX_trptr, data.LTFX_fxID, 3 )
                                end} 
    obj.b.obj_lasttouchfx_param_back = { x =  x_margin-lasttouchfx_w,
                        y = obj.offs *2 +obj.entry_h ,
                        w = lasttouchfx_w,--obj.entry_w2,
                        h = obj.entry_h,
                        frame_a = obj.frame_a_entry,
                        txt = '',
                        fontsz = obj.fontsz_entry,
                        ignore_mouse = true}      
                 
    local txt_val = string.format('%.3f',data.LTFX_val)
    obj.b.obj_lasttouchfx_knobval = { x = x_margin-val_w-knob_x_offs,
                                    y = obj.offs,
                                    w = val_w,
                                    h = obj.entry_h,
                                    frame_a = 0,
                                    txt = txt_val,
                                    txt_a = obj.txt_a,
                                    fontsz = obj.fontsz_entry,
                                    ignore_mouse = true}
    obj.b.obj_lasttouchfx_knobval2 = { x = x_margin-val_w-knob_x_offs,
                                    y = obj.offs+obj.entry_h,
                                    w = val_w,
                                    h = obj.entry_h,
                                    frame_a = 0,
                                    txt = data.LTFX_val_format,
                                    txt_a = obj.txt_a,
                                    fontsz = obj.fontsz_entry,
                                    ignore_mouse = true}                                    
    obj.b.obj_lasttouchfx_knob = { x = x_margin-val_w-knob_x_offs,
                                y = obj.offs,
                                w = val_w,
                                h = obj.entry_h*2,
                                frame_a = 0,
                                txt = '',
                                txt_a = obj.txt_a,
                                fontsz = obj.fontsz_entry,
                                is_knob = true,
                                knob_col = obj.txt_col_header,
                                val = lim(data.LTFX_val),
                                func =        function()
                                                mouse.temp_val = data.LTFX_val
                                                redraw = 1                              
                                              end,
                                func_ctrlL =        function()
                                                mouse.temp_val = data.LTFX_val
                                                redraw = 1                              
                                              end,                                              
                                func_wheel =  function()
                                                local out_value = MPL_ModifyFloatVal(data.LTFX_val, 1, 1, mouse.wheel_trig, data, nil, -2)
                                                out_value = lim(out_value,data.LTFX_minval,data.LTFX_maxval)
                                                ApplyFXVal(out_value, data.LTFX_trptr, data.LTFX_fxID, data.LTFX_parID)
                                                data.LTFX_val = out_value
                                                redraw = 2          
                                              end,                                              
                                func_drag =   function(is_ctrl) 
                                                if not mouse.temp_val then return end
                                                local pow_tol = -2
                                                local out_value = MPL_ModifyFloatVal(mouse.temp_val, 1, 1, math.modf(mouse.dy/obj.mouse_scal_float), data, nil, pow_tol)
                                                out_value = lim(out_value,data.LTFX_minval,data.LTFX_maxval)
                                                ApplyFXVal(out_value, data.LTFX_trptr, data.LTFX_fxID, data.LTFX_parID)
                                                redraw =2
                                              end,
                                func_drag_Ctrl =   function(is_ctrl) 
                                                if not mouse.temp_val then return end
                                                local pow_tol = -4 
                                                local out_value = MPL_ModifyFloatVal(mouse.temp_val, 1, 1, math.modf(mouse.dy/obj.mouse_scal_float), data, nil, pow_tol)
                                                out_value = lim(out_value,data.LTFX_minval,data.LTFX_maxval)
                                                ApplyFXVal(out_value, data.LTFX_trptr, data.LTFX_fxID, data.LTFX_parID)
                                                redraw = 2
                                              end,                                              
                                func_DC =     function() 
                                                local retval0,ret_str = GetUserInputs( 'Edit value', 1, ',extrawidth=100', data.LTFX_val )
                                                if not retval0 or not tonumber(ret_str) then return end
                                                ApplyFXVal(tonumber(ret_str), data.LTFX_trptr, data.LTFX_fxID, data.LTFX_parID)                                                                 
                                              end} 
    return lasttouchfx_w                        
  end  
  ------------------------------------
  function ApplyFXVal(val, track, fx, param) 
    TrackFX_SetParam( track, fx, param, val )
  end 
