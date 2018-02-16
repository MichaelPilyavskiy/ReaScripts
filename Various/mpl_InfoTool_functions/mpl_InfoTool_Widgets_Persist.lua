-- @description InfoTool_Widgets_Persist
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex


  -- Persistent wigets for mpl_InfoTool
  
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
                        y = obj.offs ,
                        w = grid_widg_w,
                        h = obj.entry_h*2,
                        frame_a = obj.frame_a_entry,
                        frame_rect_a = 0,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = '',
                        ignore_mouse = true} 
    obj.b.obj_pers_grid_val = { x = x_margin - grid_widg_w,
                        y = obj.offs2 ,
                        w = grid_widg_val_w,
                        h = (obj.entry_h-obj.offs2)*2,
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
                        y = obj.offs2 ,
                        w = grid_widg_w_trpl,
                        h = (obj.entry_h-obj.offs2)*2,
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
      Obj_GenerateCtrl( data,obj, mouse,
                         MPL_GetTableOfCtrlValues(TSpos_str), 
                        'timesel_position_ctrl',
                         x_margin-obj.entry_w2, obj.entry_w2,
                         data.timeselectionstart,
                         '',
                         MPL_ModifyTimeVal,
                         out_value,
                         Apply_TimeselSt,
                         obj.mouse_scal_time)
    return obj.entry_w2
  end  
  function Apply_TimeselSt(data, obj, out_value, butkey, out_str_toparse)
    if not out_str_toparse then  
      local startOut, endOut = GetSet_LoopTimeRange2( 0, false, false, -1, -1, false )  
      GetSet_LoopTimeRange2( 0, true, true, math.max(0,out_value), endOut, false )
      local new_str = format_timestr_pos( math.max(0,out_value), '', -1 ) 
      local new_str_t = MPL_GetTableOfCtrlValues(new_str)
      for i = 1, #new_str_t do
        obj.b[butkey..i].txt = new_str_t[i]
      end
     else
      -- nudge values from first item
      local out_val = parse_timestr_pos(out_str_toparse,-1) 
      local startOut, endOut = GetSet_LoopTimeRange2( 0, false, false, -1, -1, false )  
      GetSet_LoopTimeRange2( 0, true, true, math.max(0,out_value), endOut, false )
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
      Obj_GenerateCtrl( data,obj, mouse,
                         MPL_GetTableOfCtrlValues(TSposend_str), 
                        'timeselend_position_ctrl',
                         x_margin-obj.entry_w2, obj.entry_w2,
                         data.timeselectionend,
                         '',
                         MPL_ModifyTimeVal,
                         out_value,
                         Apply_Timeselend,
                         obj.mouse_scal_time)
    return obj.entry_w2
  end  
  function Apply_Timeselend(data, obj, out_value, butkey, out_str_toparse)
    if not out_str_toparse then  
      local startOut, endOut = GetSet_LoopTimeRange2( 0, false, false, -1, -1, false )  
      GetSet_LoopTimeRange2( 0, true, true, startOut, math.max(0,out_value), false )
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

