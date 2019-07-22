-- @description PitchEditor_obj
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex
  
  
  ---------------------------------------------------
  function OBJ_init(conf, obj, data, refresh, mouse)  
    -- globals
    obj.reapervrs = tonumber(GetAppVersion():match('[%d%.]+')) 
    obj.offs = 5 
    obj.grad_sz = 200 
    
    obj.offs = 2
    obj.menu_w = 15
    obj.analyze_w = 80
    obj.menu_h = 45
    obj.scroll_side = 15
    obj.ruler_h = 10
    obj.scrollframe_a = 0.1
    
    -- font
    obj.GUI_font = 'Calibri'
    obj.GUI_fontsz = VF_CalibrateFont(21)
    obj.GUI_fontsz2 = VF_CalibrateFont( 19)
    obj.GUI_fontsz3 = VF_CalibrateFont( 15)
    obj.GUI_fontsz_tooltip = VF_CalibrateFont( 13)
    
    obj.knob_w = 48
    
    -- colors    
    obj.GUIcol = { grey =    {0.5, 0.5,  0.5 },
                   white =   {1,   1,    1   },
                   red =     {0.85,   0.35,    0.37   },
                   green =   {0.35,   0.75,    0.45   },
                   green_marker =   {0.2,   0.6,    0.2   },
                   blue =   {0.35,   0.55,    0.85   },
                   blue_marker =   {0.2,   0.5,    0.8   },
                   yellow =   {0.6,   0.7,    0.35   },
                   black =   {0,0,0 }
                   } 
                     
    OBJ_DefinePeakArea(conf, obj, data, refresh, mouse)
  end
  ---------------------------------------------------
  function OBJ_Update(conf, obj, data, refresh, mouse) 
    for key in pairs(obj) do if type(obj[key]) == 'table' and obj[key].clear then obj[key] = {} end end  
    
    local min_w = 400
    local min_h = 200
    --local reduced_view = gfx.h  <= min_h
    --gfx.w  = math.max(min_w,gfx.w)
    --gfx.h  = math.max(min_h,gfx.h)
    
    OBJ_DefinePeakArea(conf, obj, data, refresh, mouse)
    
      if not data.has_data then                          
            obj.replace_ctrl = { clear = true,
                        x = obj.menu_w + obj.offs,
                        y = 0,
                        w = gfx.w-obj.menu_w,
                        h = obj.menu_h,
                        col = 'white',
                        state = fale,
                        txt= '[ Valid item/take is not selected ]',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        func =  function() 
                                end,
                                }
      else 
        OBJ_Ctrl(conf, obj, data, refresh, mouse)
        if obj.current_page == 0 then 
          Obj_ScrollZoomX(conf, obj, data, refresh, mouse)
          Obj_ScrollZoomY(conf, obj, data, refresh, mouse)
          Obj_Ruler(conf, obj, data, refresh, mouse)
          Obj_Notes(conf, obj, data, refresh, mouse)
         else
          Obj_Options(conf, obj, data, refresh, mouse)
        end
    end                    
    OBJ_MenuMain(conf, obj, data, refresh, mouse)
    for key in pairs(obj) do if type(obj[key]) == 'table' then  obj[key].context = key  end end    
  end
  ----------------------------------------------- 
  function Obj_Notes(conf, obj, data, refresh, mouse)
    if  not data.extpitch then return end
    local h_note0 = math.max(obj.peak_area.h / (127*conf.GUI_zoomY), 12)
    local thin_h = 2
    --msg(1)
    for idx = 1, #data.extpitch do
      if data.extpitch[idx].noteOn == 1 and data.extpitch[idx].len_blocks ~= 0 then 
        local len_blocks = data.extpitch[idx].len_blocks
        local xpos2 = 1
        if data.extpitch[idx+len_blocks] then xpos2 = data.extpitch[idx+len_blocks].xpos end
        local pos_x1 = math.floor(obj.peak_area.x + 
            obj.peak_area.w * 1/data.it_tkrate * (                           data.extpitch[idx].xpos - (conf.GUI_scroll*data.it_tkrate))/conf.GUI_zoom)        
        local pos_x2 = math.floor(obj.peak_area.x + 
            obj.peak_area.w * 1/data.it_tkrate * (xpos2 - (conf.GUI_scroll*data.it_tkrate))/conf.GUI_zoom)
        local pitch_linval = lim((data.extpitch[idx].RMS_pitch + data.extpitch[idx].pitch_shift)/127)
        local pos_y = math.floor(obj.peak_area.y + obj.peak_area.h * ( 1- (pitch_linval- conf.GUI_scrollY)/conf.GUI_zoomY) )-- h_note0/2
        -- if pos_y > obj.peak_area.y + obj.peak_area.h then msg(idx) end
        local h_note = h_note0
        if pos_y-h_note/2 < obj.peak_area.y then 
            h_note = thin_h 
            pos_y = obj.peak_area.y --h_note/2
           elseif pos_y+h_note/2 > obj.peak_area.y + obj.peak_area.h then
            h_note = thin_h
            pos_y = obj.peak_area.y +obj.peak_area.h - thin_h+h_note
           else
            pos_y = pos_y-h_note/2
        end
        local col_note = 'white'
        local w_note = pos_x2-pos_x1-1
        
        local pos_x1_src = pos_x1
        local pos_y0_src = pos_y0
        local w_note_src = w_note
        
        if pos_x1 + w_note > obj.peak_area.x + obj.peak_area.w then w_note = obj.peak_area.x + obj.peak_area.w - pos_x1 end
        if data.extpitch[idx].pitch_shift ~= 0 and pos_x1+w_note >= obj.peak_area.x and pos_x1 < (obj.peak_area.x + obj.peak_area.w) then 
          col_note = 'green' 
              
          local pitch_linval0 = lim(data.extpitch[idx].RMS_pitch/127)
          local pos_y0 = math.floor(obj.peak_area.y + obj.peak_area.h * ( 1- (pitch_linval0- conf.GUI_scrollY)/conf.GUI_zoomY) ) -- h_note0/2
          -- if pos_y > obj.peak_area.y + obj.peak_area.h then msg(idx) end
          local h_note00 = h_note0
          if pos_y0-h_note00/2 < obj.peak_area.y then 
                 h_note00 = thin_h 
                 pos_y0 = obj.peak_area.y --h_note/2
                elseif pos_y0+h_note00/2 > obj.peak_area.y + obj.peak_area.h then
                 h_note00 = thin_h
                 pos_y0 = obj.peak_area.y +obj.peak_area.h - thin_h+h_note00
                else
                 pos_y0 = pos_y0-h_note00/2
          end
          if pos_x1 < obj.peak_area.x then  
              w_note = pos_x1 + w_note -obj.peak_area.x 
              pos_x1 = obj.peak_area.x 
            end 
            obj['note'..idx..'fantom'] = { clear = true,
                          x = pos_x1,
                          y = pos_y0,
                          w = w_note,
                          h = h_note00,
                          colfill_col = 'white',
                          col = 'white',
                          colfill_a = 0.1,
                          txt= '',
                          show = true,
                          ignore_mouse = true,
                          a_frame = 0.05,
                          --alpha_back = 0.3,
                          is_selected = false
                          }
            
          end
          
          if pos_x1+w_note >= obj.peak_area.x  and pos_x1 < (obj.peak_area.x + obj.peak_area.w)  then
            if pos_x1 < obj.peak_area.x then  
              w_note = pos_x1 + w_note -obj.peak_area.x 
              pos_x1 = obj.peak_area.x 
            end 
            obj['note'..idx] = { clear = true,
                          x = pos_x1,
                          y = pos_y,
                          w = w_note,
                          h = h_note,
                          colfill_col = col_note,
                          colfill_a = 0.4,
                          txt= '',--data.extpitch[idx].noteOff_idx,
                          show = true,
                          fontsz = obj.GUI_fontsz3,
                          a_frame = 0.3,
                          col = 'green',
                          is_selected = obj.selected_note and obj.selected_note == idx,
                          --alpha_back = 0.6,
                          funcDC = function()
                                        for i1 = idx,  idx + data.extpitch[idx].len_blocks-1 do
                                          data.extpitch[i1].pitch_shift = 0
                                        end  
                                        Data_ApplyPitchToTake(conf, obj, data, refresh, mouse)   
                                        Data_SetPitchExtState (conf, obj, data, refresh, mouse)     
                                        refresh.GUI = true
                                        refresh.data = true                             
                                    end,
                          func_trigCtrl = function()
                                      local pos = (mouse.x - obj.peak_area.x) / obj.peak_area.w 
                                      local pos_sec = data.it_len * (conf.GUI_scroll+pos *conf.GUI_zoom) +data.it_tksoffs
                                      Data_SplitNote(conf, obj, data, refresh, mouse, idx, pos_sec) 
                                      Data_PostProcess_CalcRMSPitch(conf, obj, data, refresh, mouse)
                                      Data_ApplyPitchToTake(conf, obj, data, refresh, mouse) 
                                      Data_SetPitchExtState (conf, obj, data, refresh, mouse)     
                                      refresh.GUI = true
                                      refresh.data = true                           
                                          end,
                          func_L_Alt = function()
                                    local pos = (mouse.x - obj.peak_area.x) / obj.peak_area.w 
                                      local pos_sec = data.it_len * (conf.GUI_scroll+pos *conf.GUI_zoom) +data.it_tksoffs
                                      Data_JoinNote(conf, obj, data, refresh, mouse, idx, pos_sec) 
                                      Data_PostProcess_CalcRMSPitch(conf, obj, data, refresh, mouse)
                                      Data_ApplyPitchToTake(conf, obj, data, refresh, mouse) 
                                      Data_SetPitchExtState (conf, obj, data, refresh, mouse)     
                                      refresh.GUI = true
                                      refresh.data = true        
                                          end,
                          func =  function()
                                    mouse.context_latch_val = data.extpitch[idx].pitch_shift
                                    obj.selected_note = idx
                                    if obj.edit_mode == 1 then -- split mode
                                      local pos = (mouse.x - obj.peak_area.x) / obj.peak_area.w 
                                      local pos_sec = data.it_len * (conf.GUI_scroll+pos *conf.GUI_zoom) +data.it_tksoffs
                                      Data_SplitNote(conf, obj, data, refresh, mouse, idx, pos_sec) 
                                      Data_PostProcess_CalcRMSPitch(conf, obj, data, refresh, mouse)
                                      Data_ApplyPitchToTake(conf, obj, data, refresh, mouse) 
                                      Data_SetPitchExtState (conf, obj, data, refresh, mouse)     
                                      refresh.GUI = true
                                      refresh.data = true  
                                    end 
                                    
                                    if obj.edit_mode == 2 then -- join mode
                                      local pos = (mouse.x - obj.peak_area.x) / obj.peak_area.w 
                                      local pos_sec = data.it_len * (conf.GUI_scroll+pos *conf.GUI_zoom) +data.it_tksoffs
                                      Data_JoinNote(conf, obj, data, refresh, mouse, idx, pos_sec) 
                                      Data_PostProcess_CalcRMSPitch(conf, obj, data, refresh, mouse)
                                      Data_ApplyPitchToTake(conf, obj, data, refresh, mouse) 
                                      Data_SetPitchExtState (conf, obj, data, refresh, mouse)     
                                      refresh.GUI = true
                                      refresh.data = true  
                                    end 
                                  end,
                          func_LD3 = function()
                                      if mouse.context_latch_val then 
                                        local mouse_mult = 1
                                        if mouse.Alt_state then mouse_mult = 0.125 end
                                        local out_val = lim(mouse.context_latch_val - 127*(mouse_mult * mouse.dy/obj.peak_area.h)*conf.GUI_zoomY, -data.extpitch[idx].RMS_pitch, 127-data.extpitch[idx].RMS_pitch)
                                        if mouse.Ctrl_state then out_val = math.modf(out_val) end
                                        data.extpitch[idx].pitch_shift = out_val
                                        for i = idx, idx + data.extpitch[idx].len_blocks-1 do
                                          data.extpitch[i].pitch_shift = out_val
                                        end
                                        
                                        local pitch_linval = lim((data.extpitch[idx].RMS_pitch + out_val)/127)
                                        local pos_y = math.floor(obj.peak_area.y + obj.peak_area.h * ( 1- (pitch_linval- conf.GUI_scrollY)/conf.GUI_zoomY) )
                                        local h_note = h_note0
                                        if pos_y < obj.peak_area.y then 
                                          pos_y = obj.peak_area.y 
                                          h_note = thin_h 
                                         elseif pos_y > obj.peak_area.y + obj.peak_area.h then
                                          pos_y = obj.peak_area.y +obj.peak_area.h - thin_h
                                          h_note = thin_h
                                        end
                                        obj['note'..idx].y = pos_y-h_note/2
                                        obj['note'..idx].h = h_note
                                        obj['note'..idx].colfill_col = 'green'
                                        refresh.GUI_minor = true
                                        Data_ApplyPitchToTake(conf, obj, data, refresh, mouse) 
                                        --refresh.data = true
                                      end
                                    end  ,
                        func_mouseover =  function() 
                                            --obj['note'..idx].is_selected = true
                                            --refresh.GUI_minor = true
                                          end  ,  
                        onrelease_L2 = function ()
                                          Data_SetPitchExtState (conf, obj, data, refresh, mouse) 
                                          --msg(data.extpitch[1].pitch_shift)
                                          reaper.Undo_OnStateChange( 'Pitch Editor: note edit' )
                                          refresh.GUI = true
                                          refresh.data = true
                                        end                                                                      
                                  } 
        end
      end
    end
  end
  ----------------------------------------------- 
  function Obj_Ruler(conf, obj, data, refresh, mouse)
    local ruler_item_w = 20
    local step_w = 50
    for i = obj.peak_area.x, obj.peak_area.w, step_w do
      local pos = i / obj.peak_area.w 
      local rul = data.it_pos + data.it_len * (conf.GUI_scroll+pos *conf.GUI_zoom) +data.it_tksoffs
      rul= math_q_dec(rul  , 2)
      obj['ruler'..i] = { clear = true,
                        x = i,
                        y = obj.menu_h+obj.offs ,
                        w = ruler_item_w,
                        h = obj.ruler_h ,
                        col = 'white',
                        txt= rul,
                        aligh_txt = 1,
                        show = true,
                        fontsz = obj.GUI_fontsz3,
                        a_frame = 0,
                        disable_blitback = true,
                        is_ruleritem = true,
                        func =  function() 
                                end,
                                } 
    end
  end
  ----------------------------------------------- 
  function OBJ_DefinePeakArea(conf, obj, data, refresh, mouse)
    local pa_w = gfx.w-obj.scroll_side- obj.offs
    local pa_h = gfx.h-obj.menu_h-obj.scroll_side- obj.offs*2-obj.ruler_h
    obj.peak_area = {
                      clear = true,
                      x = 0,
                      y = obj.menu_h+obj.offs+obj.ruler_h ,
                      w = pa_w,
                      h = pa_h,
                      --a_frame = 0.15,
                      alpha_back = 0,
                      show = data.has_data,
                      func_wheel = function() Data_SetScrollZoom(conf, obj, data, refresh, mouse)  end,
                      func_mouseover =  function() 
                                          --refresh.GUI_minor = true
                                        end,
                      funcM = function() 
                                mouse.context_latch_t = {conf.GUI_scroll, conf.GUI_scrollY, conf.GUI_zoom, conf.GUI_zoomY}
                              end,
                      func_MD2 = function() 
                                conf.GUI_scroll = lim(mouse.context_latch_t[1] - mouse.context_latch_t[3]*mouse.dx/pa_w, 0, 1-conf.GUI_zoom)
                                conf.GUI_scrollY = lim(mouse.context_latch_t[2] +mouse.context_latch_t[4]*mouse.dy/pa_h, 0, 1-conf.GUI_zoomY)
                                refresh.GUI = true
                                refresh.data = true
                                refresh.conf = true
                              end
                      }  
  end 
  -----------------------------------------------   
  function Obj_ScrollZoomX(conf, obj, data, refresh, mouse)
    local sbw = math.floor(gfx.w*0.7)
    local sbx = 0
    local sby = gfx.h - obj.scroll_side
    local sbh = obj.scroll_side
    obj.scroll_bar1 = { clear = true,
                        x = sbx ,
                        y = sby,
                        w = sbw,
                        h = sbh,
                        col = 'white',
                        txt= '',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = obj.scrollframe_a,
                        ignore_mouse = true,
                        func =  function()  end
                          }   
    obj.scrollx_manual = { clear = true,
                        x = sbx + (sbw-obj.scroll_side) * conf.GUI_scroll,
                        y = sby,
                        w = sbw * conf.GUI_zoom,
                        h = obj.scroll_side,
                        col = 'white',
                        txt= '',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        alpha_back = 0.5,
                        func =  function() 
                                  mouse.context_latch_val = conf.GUI_scroll
                                end,
                        func_LD2 = function()
                                      if mouse.context_latch_val then 
                                        conf.GUI_scroll = lim(mouse.context_latch_val + mouse.dx/sbw, 0, 1-conf.GUI_zoom)
                                        refresh.GUI = true
                                        refresh.data = true
                                        refresh.conf= true
                                      end
                                    end  ,
                        onrelease_L2  = function()  
                                        end,
                          }  
                          
                                                    
    local sbx = math.floor(gfx.w*0.7)+ obj.offs
    local sby = gfx.h - obj.scroll_side
    local sbw = gfx.w - math.floor(gfx.w*0.7) - obj.offs
    local sbh = obj.scroll_side              
    obj.zoom_bar2 = { clear = true,
                        x = sbx ,
                        y = sby,
                        w = sbw,
                        h = sbh,
                        col = 'white',
                        txt= '',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = obj.scrollframe_a,
                        ignore_mouse = true,
                        func =  function()  end
                          }                           
    obj.zoomx_manual2 = { clear = true,
                        x = sbx + (sbw-obj.scroll_side) * (1-conf.GUI_zoom),
                        y = sby,
                        w = obj.scroll_side,
                        h = obj.scroll_side,
                        col = 'white',
                        txt= '',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        alpha_back = 0.5,
                        func =  function() 
                                  mouse.context_latch_t = {conf.GUI_zoom,conf.GUI_scroll, 0.5*conf.GUI_zoom + conf.GUI_scroll }
                                end,
                        func_LD2 = function()
                                      if mouse.context_latch_t then 
                                        local zoom = mouse.context_latch_t[1]
                                        local scroll = mouse.context_latch_t[2]
                                        local cur_pos = mouse.context_latch_t[3]
                                        conf.GUI_zoom = lim(zoom - mouse.dx/sbw, 0.1, 1)
                                        if zoom ~= 1 then 
                                          data.GUI_scroll =lim(cur_pos - 0.5*conf.GUI_zoom, 0, 1-conf.GUI_zoom)
                                        end
                                        
                                        refresh.GUI = true
                                        refresh.data = true
                                        refresh.conf = true
                                      end
                                    end  ,
                        onrelease_L2  = function()  
                                        end,
                          }                           
  end
  -----------------------------------------------
  function OBJ_Ctrl(conf, obj, data, refresh, mouse)
    obj.analyze = { clear = true,
                        x = obj.menu_w+  obj.offs,
                        y = 0,
                        w = obj.analyze_w,
                        h = obj.menu_h,
                        col = 'white',
                        state = fale,
                        txt= 'Analyze\ntake',
                        txt_col = 'red',
                        txt_a = 1,
                        aligh_txt = 16,
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        is_progressbar = true,
                        val = data.extcalc_progress,
                        func =  function() 
                                  obj.current_page = 0
                                  Data_SetPitchExtStateParams(conf, obj, data, refresh, mouse)
                                  Action(conf.ExternalID) -- trigger EEL
                                  Data_GetPitchExtState(conf, obj, data, refresh, mouse)
                                  refresh.data = true
                                  refresh.GUI = true
                                end,
                        func_mouseover =  function() 
                                            --obj.analyze.is_selected = true
                                            --refresh.GUI_minor = true
                                          end  , } 
                                          
    obj.actions = { clear = true,
                        x = obj.menu_w+  obj.offs*2+obj.analyze_w,
                        y = 0,
                        w = obj.analyze_w,
                        h = obj.menu_h,
                        col = 'white',
                        txt= 'Actions',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        is_progressbar = true,
                        val = data.extcalc_progress,
                        func =  function() 
                                  Menu(mouse,               
    {
      --[[{ str = 'Dump analyzed data to new MIDI item',
        func = function() 
                  Undo_BeginBlock2( 0 )
                  Data_DumpToMIDI(conf, obj, data, refresh, mouse)
                  Undo_EndBlock2( 0, 'Pitch Editor: dump data to new MIDI item', -1 )
                end 
      },]]
      { str = 'Post process analyzed pitch data',
        func = function() 
                  --Data_GetPitchExtState(conf, obj, data, refresh, mouse)
                  Data_PostProcess_ClearStuff(conf, obj, data, refresh, mouse)
                  Data_PostProcess_GetNotes(conf, obj, data, refresh, mouse)
                  Data_PostProcess_CalcRMSPitch(conf, obj, data, refresh, mouse)
                  Data_SetPitchExtState (conf, obj, data, refresh, mouse)
                  refresh.data = true
                  refresh.GUI = true
                end 
      },      
      { str = 'Reset pitch changes',
        func = function() 
                  --Data_GetPitchExtState(conf, obj, data, refresh, mouse)
                  Data_ResetPitchChanges(conf, obj, data, refresh, mouse)
                  Data_SetPitchExtState (conf, obj, data, refresh, mouse)
                  Data_ApplyPitchToTake(conf, obj, data, refresh, mouse) 
                  refresh.data = true
                  refresh.GUI = true
                end 
      },  
      { str = 'Clear note modulations',
        func = function() 
                  Data_PostProcess_ClearMod(conf, obj, data, refresh, mouse)
                  Data_SetPitchExtState (conf, obj, data, refresh, mouse)
                  Data_ApplyPitchToTake(conf, obj, data, refresh, mouse) 
                  refresh.data = true
                  refresh.GUI = true
                end 
      },      
      { str = 'Clear note separation|',
        func = function() 
                  Data_PostProcess_ClearStuff(conf, obj, data, refresh, mouse)
                  Data_PostProcess_CalcRMSPitch(conf, obj, data, refresh, mouse)
                  Data_SetPitchExtState (conf, obj, data, refresh, mouse)
                  Data_ApplyPitchToTake(conf, obj, data, refresh, mouse) 
                  refresh.data = true
                  refresh.GUI = true
                end 
      },         
      
      
      { str = '#View'},
      { str = 'Reset scroll / zoom',
        func = function() 
                  conf.GUI_zoom = 1
                  conf.GUI_scroll = 0
                  conf.GUI_zoomY = 1
                  conf.GUI_scrollY = 0
                  refresh.conf = true
                  refresh.data = true
                  refresh.GUI = true
                end 
      },       
 
      
    })
                                  refresh.conf = true 
                                  --refresh.GUI = true
                                  --refresh.GUI_onStart = true
                                  refresh.data = true
                          end,
                        func_mouseover =  function() 
                                            --obj.menu.is_selected = true
                                            --refresh.GUI_minor = true
                                          end  ,                                 } 
    obj.options = { clear = true,
                        x = obj.menu_w+  obj.offs*3+obj.analyze_w*2,
                        y = 0,
                        w = obj.analyze_w,
                        h = obj.menu_h,
                        col = 'white',
                        txt= 'Options',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        is_progressbar = true,
                        val = data.extcalc_progress,
                        func =  function() 
                                  obj.current_page = math.abs(obj.current_page-1)
                                  refresh.data = true
                                  refresh.GUI = true
                                end}   
--[[    if obj.edit_mode == 0 then 
    local mode_h = obj.menu_h / 3
    obj.mode1 = { clear = true,
                        x = obj.menu_w+  obj.offs*4+obj.analyze_w*3,
                        y = 0,
                        w = obj.analyze_w,
                        h = mode_h,
                        col = 'white',
                        txt= 'Edit',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        is_selected = obj.edit_mode == 0 ,
                        func =  function() 
                                  obj.edit_mode = obj.edit_mode + 1
                                  if obj.edit_mode == 3 then obj.edit_mode = 0 end
                                  refresh.data = true
                                  refresh.GUI = true
                                end}   
    obj.mode2 = { clear = true,
                        x = obj.menu_w+  obj.offs*4+obj.analyze_w*3,
                        y = mode_h,
                        w = obj.analyze_w,
                        h = mode_h,
                        col = 'white',
                        txt= 'Split',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        is_selected = obj.edit_mode == 1 ,
                        func =  function() 
                                  obj.edit_mode = obj.edit_mode + 1
                                  if obj.edit_mode == 3 then obj.edit_mode = 0 end
                                  refresh.data = true
                                  refresh.GUI = true
                                end}  
    obj.mode3 = { clear = true,
                        x = obj.menu_w+  obj.offs*4+obj.analyze_w*3,
                        y = mode_h*2,
                        w = obj.analyze_w,
                        h = mode_h,
                        col = 'white',
                        txt= 'Join',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        is_selected = obj.edit_mode == 2 ,
                        func =  function() 
                                  obj.edit_mode = obj.edit_mode + 1
                                  if obj.edit_mode == 3 then obj.edit_mode = 0 end
                                  refresh.data = true
                                  refresh.GUI = true
                                end}  ]]                                                                                                                                   
      if obj.selected_note and data.extpitch[obj.selected_note] then 
        obj.mod_knob = { clear = true,
                        is_knob = true,
                        is_centered_knob = true,
                        knob_y_shift = 3,
                        x = obj.menu_w+  obj.offs*4+obj.analyze_w*3,
                        y =  0,
                        w = obj.knob_w,
                        h = obj.menu_h,
                        col = 'white',
                        txt= 'Mod',
                        txt_yshift = 14,
                        val = data.extpitch[obj.selected_note].mod_pitch,
                        show = true,
                        fontsz = obj.GUI_fontsz3,
                        a_frame = 0,
                        func =  function() 
                                  mouse.context_latch_val = data.extpitch[obj.selected_note].mod_pitch
                                end,
                        func_LD2 = function()
                                      if mouse.context_latch_val then  
                                        local out_val = lim(mouse.context_latch_val - mouse.dy/100)
                                        data.extpitch[obj.selected_note].mod_pitch = out_val
                                        Data_ApplyPitchToTake(conf, obj, data, refresh, mouse) 
                                        refresh.GUI = true
                                      end
                                    end   ,
                        onrelease_L2 = function ()
                                          Data_SetPitchExtState (conf, obj, data, refresh, mouse) 
                                          --msg(data.extpitch[1].pitch_shift)
                                          refresh.GUI = true
                                          refresh.data = true
                                        end                                              
                        }
    end
                                
  end
  -----------------------------------------------
  function OBJ_MenuMain(conf, obj, data, refresh, mouse)
            obj.menu = { clear = true,
                        x = 0,
                        y = 0,
                        w = obj.menu_w,
                        h = obj.menu_h,
                        col = 'white',
                        state = fale,
                        txt= '>',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        func_mouseover = function() end,
                        func =  function() 
                        
                                  Menu(mouse,               
    {
      { str = conf.mb_title..' '..conf.vrs,
        hidden = true
      },
      { str = 'Donate to MPL',
        func = function() Open_URL('http://www.paypal.me/donate2mpl') end }  ,
      { str = 'Contact: MPL VK',
        func = function() Open_URL('http://vk.com/mpl57') end  } ,     
      { str = 'Contact: MPL SoundCloud|',
        func = function() Open_URL('http://soundcloud.com/mpl57') end  } ,     
        
      --[[{ str = '#Options'},    
      { str = 'test|',
        func = function() 
                conf.test = math.abs(1-conf.test) 
              end,
        state = conf.test == 1}, 
        ]]
                   
      { str = 'Dock '..'MPL '..conf.mb_title..' '..conf.vrs,
        func = function() 
                  if conf.dock > 0 then conf.dock = 0 else conf.dock = 1 end
                  gfx.quit() 
                  gfx.init('MPL '..conf.mb_title..' '..conf.vrs,
                            conf.wind_w, 
                            conf.wind_h, 
                            conf.dock, conf.wind_x, conf.wind_y)
              end ,
        state = conf.dock > 0},                                                                            
    }
    )
                                  refresh.conf = true 
                                  --refresh.GUI = true
                                  --refresh.GUI_onStart = true
                                  refresh.data = true
                                end,
                        func_mouseover =  function() 
                                            --obj.menu.is_selected = true
                                            --refresh.GUI_minor = true
                                          end  ,                                 }  
                                
                             
  end
  -----------------------------------------------   
  function Obj_ScrollZoomY(conf, obj, data, refresh, mouse)
    local sbw = obj.scroll_side
    local sbx = gfx.w - obj.scroll_side
    local sby = obj.peak_area.y
    local sbh = math.floor(obj.peak_area.h *0.7)
    obj.scrollY_bar1 = { clear = true,
                        x = sbx ,
                        y = sby,
                        w = sbw,
                        h = sbh,
                        col = 'white',
                        txt= '',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = obj.scrollframe_a,
                        ignore_mouse = true,
                        func =  function()  end
                          }   
    obj.scrollY_manual = { clear = true,
                        x = sbx,
                        --y = sby + (sbh-obj.scroll_side)* data.GUI_scrollY,
                        y = sby + (sbh-sbh * conf.GUI_zoomY) -(sbh-obj.scroll_side)* (conf.GUI_scrollY),
                        w = obj.scroll_side,
                        h = sbh * conf.GUI_zoomY,
                        col = 'white',
                        txt= '',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        alpha_back = 0.5,
                        func =  function() 
                                  mouse.context_latch_val = conf.GUI_scrollY
                                end,
                        func_LD2 = function()
                                      if mouse.context_latch_val then 
                                        conf.GUI_scrollY = lim(mouse.context_latch_val - mouse.dy/sbh, 0, 1-conf.GUI_zoomY)
                                        refresh.GUI = true
                                        refresh.data = true
                                      end
                                    end  ,
                        onrelease_L2  = function()  
                                        end,
                          }  
                          
    local sbw = obj.scroll_side
    local sbx = gfx.w - obj.scroll_side
    local sby = obj.peak_area.y + math.floor(obj.peak_area.h *0.7) + obj.offs
    local sbh = obj.peak_area.h - math.floor(obj.peak_area.h *0.7) - obj.offs
    obj.zoomY_bar2 = { clear = true,
                        x = sbx ,
                        y = sby,
                        w = sbw,
                        h = sbh,
                        col = 'white',
                        txt= '',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = obj.scrollframe_a,
                        ignore_mouse = true,
                        func =  function()  end
                          }                           
    obj.zoomY_manual2 = { clear = true,
                        x = sbx,
                        y = sby + (sbh-obj.scroll_side) * (1-conf.GUI_zoomY),
                        w = obj.scroll_side,
                        h = obj.scroll_side,
                        col = 'white',
                        txt= '',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        alpha_back = 0.5,
                        func =  function() 
                                  mouse.context_latch_t = {conf.GUI_zoomY,conf.GUI_scrollY, 0.5*conf.GUI_zoomY + conf.GUI_scrollY }
                                end,
                        func_LD2 = function()
                                      if mouse.context_latch_t then 
                                        local zoom = mouse.context_latch_t[1]
                                        local scroll = mouse.context_latch_t[2]
                                        local cur_pos = mouse.context_latch_t[3]
                                        conf.GUI_zoomY = lim(zoom - mouse.dy/sbh, conf.minzoomY, 1)
                                        if zoom ~= 1 then 
                                          conf.GUI_scrollY =lim(cur_pos - 0.5*conf.GUI_zoomY, 0, 1-conf.GUI_zoomY)
                                        end
                                        
                                        refresh.GUI = true
                                        refresh.data = true
                                        refresh.conf = true
                                      end
                                    end  ,
                        onrelease_L2  = function()  
                                        end,
                          }                           
  end
  -----------------------------------------------
  function Obj_Options(conf, obj, data, refresh, mouse)
    local x_shift = obj.peak_area.x
    local y_shift = obj.peak_area.y
    local entry_w_name = 300
    local entry_h = 20
    local indent_w = 20
    local t = ExtState_Def()
    local params_t = 
      {
        { name = 'YIN-based pitch detection algorithm' ,
          is_group = 1},
        { name = 'Maximum take length: '..conf.max_len..'s (default='..t.max_len..'s)',
          nameI = 'Maximum take length',
          indent = 1,
          lim_min = 1,
          lim_max = 600,
          param_key = 'max_len'},
        { name = 'Window step: '..conf.window_step..'s (default='..t.window_step..'s)',
          nameI = 'Window step',
          indent = 1,
          lim_min = .01,
          lim_max = .1,
          param_key = 'window_step'},  
        { name = 'Window overlap: '..conf.overlap..'x (default='..t.overlap..'x)',
          nameI = 'Window overlap',
          indent = 1,
          lim_min = 1,
          lim_max = 8,
          is_int = true,
          param_key = 'overlap'},  
        { name = 'Minimum frequency: '..conf.minF..'Hz (default='..t.minF..'Hz)',
          nameI = 'Minimum frequency',
          indent = 1,
          lim_min = 10,
          lim_max = 1000,
          param_key = 'minF'},     
        { name = 'Maximum frequency: '..conf.maxF..'Hz (default='..t.maxF..'Hz)',
          nameI = 'Maximum frequency',
          indent = 1,
          lim_min = 10,
          lim_max = 1000,
          param_key = 'maxF'},      
        { name = 'Absolute threshold (YIN, st.4): '..conf.YINthresh..' (default='..t.YINthresh..')',
          nameI = 'Absolute threshold',
          indent = 1,
          lim_min = 0.01,
          lim_max = 0.9,
          param_key = 'YINthresh'}, 
        { name = 'RMS Threshold: '..conf.lowRMSlimit_dB..'dB (default='..t.lowRMSlimit_dB..'dB)',
          nameI = 'RMS threshold',
          indent = 1,
          lim_min = -100,
          lim_max = -5,
          param_key = 'lowRMSlimit_dB'},     

        { name = 'Post processing algorithm' ,
          is_group = 1},
        { name = 'MIDI Pitch difference: '..conf.post_note_diff..' (default='..t.post_note_diff..')',
          nameI = 'MIDI Pitch difference',
          indent = 1,
          lim_min = 0.2,
          lim_max = 3,
          param_key = 'post_note_diff'},   
        { name = 'Linear RMS difference: '..conf.RMS_diff_linear..' (default='..t.RMS_diff_linear..')',
          nameI = 'Windows count between slices',
          indent = 1,
          lim_min = 0.01,
          lim_max = 0.5,
          param_key = 'RMS_diff_linear'},   
--[[        { name = 'NoteOff negative offset: '..conf.noteoff_offsetblock..' (default='..t.noteoff_offsetblock..')',
          nameI = '',
          indent = 1,
          lim_min = 0,
          lim_max = 10,
          is_int = true,
          param_key = 'noteoff_offsetblock'}, ]] 
        { name = 'Minimal block length: '..conf.min_block_len..' (default='..t.min_block_len..')',
          nameI = 'blocks',
          indent = 1,
          lim_min = 2,
          lim_max = 20,
          is_int = true,
          param_key = 'min_block_len'},            
          
                     
        --[[{ name = '2nd pass RMS pitch: '..conf.secondpassRMSpitch..' (default='..t.secondpassRMSpitch..')',
          nameI = ' slices',
          indent = 1,
          lim_min = 0,
          lim_max = 10,
          is_int = true,
          param_key = 'secondpassRMSpitch'},  ]]            
          
      }
                
    for i = 1, #params_t do
      if not params_t[i].indent then params_t[i].indent = 0 end
      local txt_a = 0.8
      local alpha_back = 0
      if params_t[i].is_group == 1 then txt_a = 0.4 alpha_back = 0.15 end
      obj['params'..i] = { clear = true,
                          x = x_shift + obj.offs + params_t[i].indent * indent_w,
                          y = y_shift + entry_h*(i-1),
                          w = entry_w_name,
                          h = entry_h,
                          col = 'white',
                          txt_a = txt_a,
                          txt= params_t[i].name,
                          aligh_txt = 1,
                          show = true,
                          fontsz = obj.GUI_fontsz2,
                          alpha_back = alpha_back,
                          func =  function() 
                            local retval, retvals_csv = GetUserInputs( conf.mb_title, 1, params_t[i].nameI, conf[params_t[i].param_key] )
                            if retval and retvals_csv and tonumber(retvals_csv) then
                              retvals_csv = tonumber(retvals_csv)
                              if  params_t[i].is_int then retvals_csv = math.floor(retvals_csv) end
                              conf[params_t[i].param_key] = lim(retvals_csv, params_t[i].lim_min, params_t[i].lim_max)
                              refresh.GUI = true
                              refresh.data = true
                            end
                          end}
    end   
  end
