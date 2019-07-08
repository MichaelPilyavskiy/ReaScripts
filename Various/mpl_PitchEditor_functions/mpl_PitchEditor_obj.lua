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
    obj.analyze_w = 100
    obj.menu_h = 40
    obj.scroll_side = 15
    obj.ruler_h = 10
    
    -- font
    obj.GUI_font = 'Calibri'
    obj.GUI_fontsz = VF_CalibrateFont(21)
    obj.GUI_fontsz2 = VF_CalibrateFont( 19)
    obj.GUI_fontsz3 = VF_CalibrateFont( 15)
    obj.GUI_fontsz_tooltip = VF_CalibrateFont( 13)
    
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
    local reduced_view = gfx.h  <= min_h
    gfx.w  = math.max(min_w,gfx.w)
    gfx.h  = math.max(min_h,gfx.h)
    
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
        Obj_ScrollZoomX(conf, obj, data, refresh, mouse)
        Obj_ScrollZoomY(conf, obj, data, refresh, mouse)
        Obj_Ruler(conf, obj, data, refresh, mouse)
        Obj_Notes(conf, obj, data, refresh, mouse)
    end                    
    OBJ_MenuMain(conf, obj, data, refresh, mouse)
    for key in pairs(obj) do if type(obj[key]) == 'table' then  obj[key].context = key  end end    
  end
  ----------------------------------------------- 
  function Obj_Notes(conf, obj, data, refresh, mouse)
    local h_note0 = math.max(obj.peak_area.h / (127*data.GUI_zoomY), 25)
    local thin_h = 2
    for idx = 1, #data.extpitch do
      if data.extpitch[idx].noteOn == 1 and data.extpitch[idx].xpos2 then 
          local pos_x1 = math.floor(obj.peak_area.x + obj.peak_area.w * 1/data.it_tkrate * (data.extpitch[idx].xpos- (data.GUI_scroll*data.it_tkrate))/data.GUI_zoom)        
          local pos_x2 = math.floor(obj.peak_area.x + obj.peak_area.w * 1/data.it_tkrate * (data.extpitch[idx].xpos2- (data.GUI_scroll*data.it_tkrate))/data.GUI_zoom)
          local pitch_linval = lim((data.extpitch[idx].RMS_pitch + data.extpitch[idx].pitch_shift)/127)
          local pos_y = math.floor(obj.peak_area.y + obj.peak_area.h * ( 1- (pitch_linval- data.GUI_scrollY)/data.GUI_zoomY) )
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
          if data.extpitch[idx].pitch_shift ~= 0 and pos_x2 < (obj.peak_area.x + obj.peak_area.w) then 
            col_note = 'green' 
            
             local pitch_linval0 = lim(data.extpitch[idx].RMS_pitch/127)
             local pos_y0 = math.floor(obj.peak_area.y + obj.peak_area.h * ( 1- (pitch_linval0- data.GUI_scrollY)/data.GUI_zoomY) )
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
             
            obj['note'..idx..'fantom'] = { clear = true,
                          x = pos_x1,
                          y = pos_y0,
                          w = pos_x2-pos_x1-1,
                          h = h_note00,
                          colfill_col = 'white',
                          colfill_a = 0.1,
                          txt= '',
                          show = true,
                          ignore_mouse = true,
                          a_frame = 0.05,
                          alpha_back = 0.3,
                          is_selected = false
                          }
            
          end
          
          if pos_x2 < (obj.peak_area.x + obj.peak_area.w)  then
            obj['note'..idx] = { clear = true,
                          x = pos_x1,
                          y = pos_y,
                          w = pos_x2-pos_x1-1,
                          h = h_note,
                          colfill_col = col_note,
                          colfill_a = 0.4,
                          txt= '',
                          show = true,
                          fontsz = obj.GUI_fontsz3,
                          a_frame = 0.05,
                          alpha_back = 0.6,
                          is_selected = false,
                          func =  function()
                                    mouse.context_latch_val = data.extpitch[idx].pitch_shift
                                  end,
                        func_LD2 = function()
                                      if mouse.context_latch_val then 
                                        local out_val = lim(mouse.context_latch_val - 127*(mouse.dy/obj.peak_area.h)*data.GUI_zoomY, -data.extpitch[idx].RMS_pitch, 127-data.extpitch[idx].RMS_pitch)
                                        data.extpitch[idx].pitch_shift = out_val
                                        local pitch_linval = lim((data.extpitch[idx].RMS_pitch + out_val)/127)
                                        local pos_y = math.floor(obj.peak_area.y + obj.peak_area.h * ( 1- (pitch_linval- data.GUI_scrollY)/data.GUI_zoomY) )
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
      local rul = data.it_pos + data.it_len * (data.GUI_scroll+pos *data.GUI_zoom) +data.it_tksoffs
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
    obj.peak_area = {
                      clear = true,
                      x = 0,
                      y = obj.menu_h+obj.offs+obj.ruler_h ,
                      w = gfx.w-obj.scroll_side- obj.offs,
                      h = gfx.h-obj.menu_h-obj.scroll_side- obj.offs*2-obj.ruler_h ,
                      --a_frame = 0.15,
                      alpha_back = 0,
                      show = data.has_data,
                      func_wheel = function() Data_SetScrollZoom(conf, obj, data, refresh, mouse)  end,
                      func_mouseover =  function() 
                                          --refresh.GUI_minor = true
                                        end}  
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
                        a_frame = 0.2,
                        ignore_mouse = true,
                        func =  function()  end
                          }   
    obj.scrollx_manual = { clear = true,
                        x = sbx + (sbw-obj.scroll_side) * data.GUI_scroll,
                        y = sby,
                        w = sbw * data.GUI_zoom,
                        h = obj.scroll_side,
                        col = 'white',
                        txt= '',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        alpha_back = 0.5,
                        func =  function() 
                                  mouse.context_latch_val = data.GUI_scroll
                                end,
                        func_LD2 = function()
                                      if mouse.context_latch_val then 
                                        data.GUI_scroll = lim(mouse.context_latch_val + mouse.dx/sbw, 0, 1-data.GUI_zoom)
                                        refresh.GUI = true
                                        refresh.data = true
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
                        a_frame = 0.2,
                        ignore_mouse = true,
                        func =  function()  end
                          }                           
    obj.zoomx_manual2 = { clear = true,
                        x = sbx + (sbw-obj.scroll_side) * (1-data.GUI_zoom),
                        y = sby,
                        w = obj.scroll_side,
                        h = obj.scroll_side,
                        col = 'white',
                        txt= '',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        alpha_back = 0.5,
                        func =  function() 
                                  mouse.context_latch_t = {data.GUI_zoom,data.GUI_scroll, 0.5*data.GUI_zoom + data.GUI_scroll }
                                end,
                        func_LD2 = function()
                                      if mouse.context_latch_t then 
                                        local zoom = mouse.context_latch_t[1]
                                        local scroll = mouse.context_latch_t[2]
                                        local cur_pos = mouse.context_latch_t[3]
                                        data.GUI_zoom = lim(zoom - mouse.dx/sbw, 0.2, 1)
                                        if zoom ~= 1 then 
                                          data.GUI_scroll =lim(cur_pos - 0.5*data.GUI_zoom, 0, 1-data.GUI_zoom)
                                        end
                                        
                                        refresh.GUI = true
                                        refresh.data = true
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
                        txt= 'Analyze take',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        is_progressbar = true,
                        val = data.extcalc_progress,
                        func =  function() 
                                  Data_SetPitchExtStateParams(conf, obj, data, refresh, mouse)
                                  Action(conf.ExternalID) -- trigger EEL
                                  Data_GetPitchExtState(conf, obj, data, refresh, mouse)
                                  refresh.data = true
                                  refresh.GUI = true
                                end,
                        func_mouseover =  function() 
                                            --obj.analyze.is_selected = true
                                            --refresh.GUI_minor = true
                                          end  ,                                } 
                                
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
                        a_frame = 0.2,
                        ignore_mouse = true,
                        func =  function()  end
                          }   
    obj.scrollY_manual = { clear = true,
                        x = sbx,
                        --y = sby + (sbh-obj.scroll_side)* data.GUI_scrollY,
                        y = sby + (sbh-sbh * data.GUI_zoomY) -(sbh-obj.scroll_side)* (data.GUI_scrollY),
                        w = obj.scroll_side,
                        h = sbh * data.GUI_zoomY,
                        col = 'white',
                        txt= '',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        alpha_back = 0.5,
                        func =  function() 
                                  mouse.context_latch_val = data.GUI_scrollY
                                end,
                        func_LD2 = function()
                                      if mouse.context_latch_val then 
                                        data.GUI_scrollY = lim(mouse.context_latch_val - mouse.dy/sbh, 0, 1-data.GUI_zoomY)
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
                        a_frame = 0.2,
                        ignore_mouse = true,
                        func =  function()  end
                          }                           
    obj.zoomY_manual2 = { clear = true,
                        x = sbx,
                        y = sby + (sbh-obj.scroll_side) * (1-data.GUI_zoomY),
                        w = obj.scroll_side,
                        h = obj.scroll_side,
                        col = 'white',
                        txt= '',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        alpha_back = 0.5,
                        func =  function() 
                                  mouse.context_latch_t = {data.GUI_zoomY,data.GUI_scrollY, 0.5*data.GUI_zoomY + data.GUI_scrollY }
                                end,
                        func_LD2 = function()
                                      if mouse.context_latch_t then 
                                        local zoom = mouse.context_latch_t[1]
                                        local scroll = mouse.context_latch_t[2]
                                        local cur_pos = mouse.context_latch_t[3]
                                        data.GUI_zoomY = lim(zoom - mouse.dy/sbh, 0.2, 1)
                                        if zoom ~= 1 then 
                                          data.GUI_scrollY =lim(cur_pos - 0.5*data.GUI_zoomY, 0, 1-data.GUI_zoomY)
                                        end
                                        
                                        refresh.GUI = true
                                        refresh.data = true
                                      end
                                    end  ,
                        onrelease_L2  = function()  
                                        end,
                          }                           
  end
