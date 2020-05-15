-- @description MappingPanel_obj
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex
  
  
  ---------------------------------------------------
  function OBJ_init(conf, obj, data, refresh, mouse) 
    -- globals
    obj.reapervrs = tonumber(GetAppVersion():match('[%d%.]+')) 
    obj.offs = 5 
    obj.grad_sz = 200 
    
    obj.strategy_frame = 0
     
     
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
    obj.menu_h = 40
    obj.offs = 2
    obj.menu_w = 15
    obj.knob_w = lim((gfx.w - obj.menu_w - obj.offs)/(conf.slot_cnt+1), 38, 45)
    obj.rect_side = 8
    obj.glass_h = math.floor(obj.menu_h*0.8)-1
    obj.name_w = 200
    obj.infoline_h = 25
    OBJ_InfoLine(conf, obj, data, refresh, mouse) 
  end
  ---------------------------------------------------
  function OBJ_Update(conf, obj, data, refresh, mouse) 
    for key in pairs(obj) do if type(obj[key]) == 'table' and obj[key].clear then obj[key] = {} end end  
    
    local min_w = 350
    local min_h = 250
    local reduced_view = gfx.h  <= min_h
    gfx.w  = math.max(min_w,gfx.w)
    gfx.h  = math.max(min_h,gfx.h)
    
    
    OBJ_MenuMain (conf, obj, data, refresh, mouse)
    OBJ_Knobs(conf, obj, data, refresh, mouse) 
    OBJ_Knob_Childrens(conf, obj, data, refresh, mouse) 
    
    for key in pairs(obj) do if type(obj[key]) == 'table' then  obj[key].context = key  end end    
  end
  -----------------------------------------------
  function OBJ_InfoLine(conf, obj, data, refresh, mouse) 
      obj.infoline = { clear = false,
                        x =obj.offs*2,
                        y = obj.menu_h + obj.offs,
                        w = gfx.w - obj.offs*4,
                        h = obj.infoline_h,
                        col = 'white',
                        txt= '[info]',
                        show = true,
                        fontsz = obj.GUI_fontsz3,
                        alpha_back = 0.2,
                        func =  function()  
                                  
                                end,
                        func_mouseover = function() 
                                          
                                          refresh.GUI_minor = true
                                        end                                  
                               
                        }  
  end
  -----------------------------------------------
  function OBJ_Knob_Childrens_SlideCtrl(conf, obj, data, refresh, mouse, i, slotchild_sliderarea)  
    local areax,areay,areaw,areah = 
      slotchild_sliderarea.x,
      slotchild_sliderarea.y,
      slotchild_sliderarea.w,
      slotchild_sliderarea.h
    local glass_y = areay--math.floor(areay + areah/2 - obj.glass_h/2)
    local p1_x = areax-math.floor(obj.rect_side/2) + areaw* data.slots[conf.activeknob][i].hexarray_lim_min
    local p1_y = glass_y-math.floor(obj.rect_side/2) + areah*(1-data.slots[conf.activeknob][i].hexarray_scale_min)--obj.glass_h 
    obj['slotchild_p1'..i] = { clear = true,
                  x = p1_x,
                  y = p1_y,
                  w = obj.rect_side,
                  h = obj.rect_side,
                  col = 'white',
                  txt = '',
                  show = true,
                  a_frame = 0.05,
                  alpha_back = 0.1,
                  customslider_ctrl = true,
                  customslider_ctrl_rot = 0,
                  func =  function()  
                            mouse.context_latch_t = {obj['slotchild_p1'..i].x, data.slots[conf.activeknob][i].hexarray_lim_min,
                                                     obj['slotchild_p1'..i].y, data.slots[conf.activeknob][i].hexarray_scale_min}
                          end,
                  func_LD2 =function()
                              if mouse.context_latch_t then 
                                local mult = 1 if mouse.Ctrl_state then mult = 0.01 end
                                local out_val1 = lim(mouse.context_latch_t[2] + mult*mouse.dx/areaw)
                                local out_val2 = lim(mouse.context_latch_t[4] - mult*mouse.dy/areah)
                                if out_val1 >= 1- data.slots[conf.activeknob][i].hexarray_lim_max then out_val1 = 1- data.slots[conf.activeknob][i].hexarray_lim_max-0.01 end
                                obj['slotchild_p1'..i].x, 
                                obj['slotchild_p1'..i].y = 
                                  areax -math.floor(obj.rect_side/2)+ areaw* out_val1,
                                  glass_y -math.floor(obj.rect_side/2)+ areah *(1-out_val2)--obj.glass_h 
                                data.slots[conf.activeknob][i].hexarray_lim_min = out_val1
                                data.slots[conf.activeknob][i].hexarray_scale_min = out_val2
                                Data_ApplyHex(conf, obj, data, refresh, mouse, conf.activeknob, i)
                                
                                obj.infoline.txt = 'x1='..math_q_dec(out_val1, 4)..', y1='..math_q_dec(out_val2, 4)
                                
                                refresh.GUI_minor = true
                                refresh.data_minor = true
                              end
                             end ,
                  func_R = function()
                              local retval, retvals_csv = GetUserInputs( conf.mb_title, 2, 'X1,Y1,extrawidth=100', 
                                data.slots[conf.activeknob][i].hexarray_lim_min..','..data.slots[conf.activeknob][i].hexarray_scale_min )
                              if retval then 
                                t = {}
                                for val in retvals_csv:gmatch('[^%,]+') do if tonumber(val) then t[#t+1] = lim(tonumber(val)) end end
                                if #t ~= 2 then return end
                                data.slots[conf.activeknob][i].hexarray_lim_min,data.slots[conf.activeknob][i].hexarray_scale_min = t[1],t[2]
                                Data_ApplyHex(conf, obj, data, refresh, mouse, conf.activeknob, i)
                                refresh.GUI_minor = true
                                refresh.data_minor = true
                              end
                            end,
                  func_mouseover = function() 
                                          refresh.GUI_minor = true
                                        end                               
                }
    local p2_x = areax-math.floor(obj.rect_side/2) + areaw*  (1-data.slots[conf.activeknob][i].hexarray_lim_max)
    local p2_y = glass_y-math.floor(obj.rect_side/2) + areah *data.slots[conf.activeknob][i].hexarray_scale_max--obj.glass_h 
    obj['slotchild_p2'..i] = { clear = true,
                  x = p2_x,
                  y = p2_y,
                  w = obj.rect_side,
                  h = obj.rect_side,
                  col = 'white',
                  txt = '',
                  show = true,
                  a_frame = 0.05,
                  alpha_back = 0.1,
                  customslider_ctrl = true,
                  customslider_ctrl_rot = 0,
                  func =  function()  
                            mouse.context_latch_t = {obj['slotchild_p2'..i].x, data.slots[conf.activeknob][i].hexarray_lim_max,
                                                     obj['slotchild_p2'..i].y, data.slots[conf.activeknob][i].hexarray_scale_max}
                          end,
                  func_LD2 =function()
                              if mouse.context_latch_t then
                                local mult = 1 if mouse.Ctrl_state then mult = 0.01 end 
                                local out_val1 = lim(mouse.context_latch_t[2] - mult*mouse.dx/areaw)
                                local out_val2 = lim(mouse.context_latch_t[4] +mult* mouse.dy/areah)
                                if (1-out_val1)<= data.slots[conf.activeknob][i].hexarray_lim_min then out_val1 = 1- data.slots[conf.activeknob][i].hexarray_lim_min-0.01 end
                                obj['slotchild_p2'..i].x, obj['slotchild_p2'..i].y = 
                                  areax-math.floor(obj.rect_side/2) + areaw*  (1-out_val1),
                                  glass_y-math.floor(obj.rect_side/2) + areah *out_val2--obj.glass_h 
                                data.slots[conf.activeknob][i].hexarray_lim_max = out_val1
                                data.slots[conf.activeknob][i].hexarray_scale_max = out_val2
                                Data_ApplyHex(conf, obj, data, refresh, mouse, conf.activeknob, i)
                                
                                obj.infoline.txt = 'y1='..math_q_dec(out_val1, 4)..', y2='..math_q_dec(out_val2, 4)
                                
                                refresh.GUI_minor = true
                                refresh.data_minor = true
                              end
                             end ,
                  func_R = function()
                              local retval, retvals_csv = GetUserInputs( conf.mb_title, 2, 
                                'X1,Y1,extrawidth=100', 
                                (1-data.slots[conf.activeknob][i].hexarray_lim_max)..','..(1-data.slots[conf.activeknob][i].hexarray_scale_max ))
                              if retval then 
                                t = {}
                                for val in retvals_csv:gmatch('[^%,]+') do if tonumber(val) then t[#t+1] = lim(tonumber(val)) end end
                                if #t ~= 2 then return end
                                data.slots[conf.activeknob][i].hexarray_lim_max,data.slots[conf.activeknob][i].hexarray_scale_max = (1-t[1]),(1-t[2])
                                Data_ApplyHex(conf, obj, data, refresh, mouse, conf.activeknob, i)
                                refresh.GUI_minor = true
                                refresh.data_minor = true
                              end
                            end,                             
                        func_mouseover = function() 
                                          refresh.GUI_minor = true
                                        end                                 
                }                
                                                                                                                                            
  end                
  -----------------------------------------------
  function OBJ_Knob_Childrens(conf, obj, data, refresh, mouse) 
    if not data.slots or not data.slots[conf.activeknob] then return end
    local slotchilds_cnt = #data.slots[conf.activeknob]
    local child_h = 55
    local but_w = 20
    local but_cnt = 3
 
    for i = 1, slotchilds_cnt do
      if data.slots[conf.activeknob][i] then
        local areax,areay,areaw,areah = obj.offs*2 ,
                                        obj.menu_h + obj.offs*2 + (child_h +obj.offs)* (i-1) + obj.infoline_h,
                                        gfx.w - obj.offs*4,
                                        child_h
        local slider_w = areaw-areax-obj.name_w -but_w*but_cnt
        obj['slotchildarea'..i] = { clear = true,
                        x = areax,
                        y = areay,
                        w = areaw,
                        h = areah,
                        col = 'white',
                        txt = '',
                        show = false,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0.05,
                        alpha_back = 0,
                        ignore_mouse = false,
                  func_L_Alt =  function()  
                            mouse.context_latch_t = {obj['slotchild_sliderarea_tension'..i].y, data.slots[conf.activeknob][i].flags_tension}
                          end,
                  func_altLD =function()
                              if mouse.context_latch_t then 
                                local out_val = lim(mouse.context_latch_t[2]  - 0.1*mouse.dy/areah, 0, 1 )
                                obj['slotchild_sliderarea_tension'..i].y = areay + (areah - obj.rect_side)*(1-out_val)
                                data.slots[conf.activeknob][i].flags_tension = out_val
                                Data_ApplyHex(conf, obj, data, refresh, mouse, conf.activeknob, i)
                                local txt_type = math.floor(out_val*16)
                                if out_val ==0 then txt_type = 'linear' end
                                obj.infoline.txt = 'tension type: '..txt_type
                                
                                refresh.GUI_minor = true
                                refresh.data_minor = true
                              end
                             end                                    
                                    
                                    }
        local txt_name =  (data.slots[conf.activeknob][i].JSFX_paramid+1)..' ← '..data.slots[conf.activeknob][i].trname..'\n'..
                          '   ('..(data.slots[conf.activeknob][i].Slave_FXid+1)..') '..MPL_ReduceFXname(data.slots[conf.activeknob][i].Slave_FXname)..
                          '\n   ('..(data.slots[conf.activeknob][i].Slave_paramid+1)..') '..data.slots[conf.activeknob][i].Slave_paramname..'\n'..
                          '   '..data.slots[conf.activeknob][i].Slave_paramformatted:gsub('%s+', ' ')
        obj['slotchild_name'..i] = { clear = true,
                        x = areax,
                        y = areay,
                        w = obj.name_w,
                        h = areah,
                        col = 'white',
                        txt = txt_name,
                        aligh_txt = 17,
                        txt_xshift = 5,
                        txt_yshift = 1,
                        show = true,
                        fontsz = obj.GUI_fontsz3,
                        --a_frame = 0.05,
                        alpha_back = 0.1,
                        func = function() 
                          local tr = VF_GetTrackByGUID(data.slots[conf.activeknob][i].trGUID)
                          local fxid = data.slots[conf.activeknob][i].Slave_FXid
                          TrackFX_Show( tr, fxid, 3 )
                        end}   
        obj['slotchild_sliderarea'..i] = { clear = true,
                        x = areax + obj.name_w + obj.offs + math.floor(obj.rect_side/2),
                        y = areay,
                        w = slider_w-obj.rect_side,
                        h = areah-1,
                        col = 'white',
                        txt = '',
                        val_t = data.slots[conf.activeknob][i],
                        aligh_txt = 17,
                        txt_yshift = 1,
                        show = true,
                        fontsz = obj.GUI_fontsz3,
                        a_frame = 0.05,
                        alpha_back = 0,
                        ignore_mouse = true,
                        customslider = true}    
        OBJ_Knob_Childrens_SlideCtrl(conf, obj, data, refresh, mouse, i, 
          obj['slotchild_sliderarea'..i])                         

    local tension_y = areay + (areah - obj.rect_side)*(1-data.slots[conf.activeknob][i].flags_tension)
    obj['slotchild_sliderarea_tension'..i] = { clear = true,
                  x = areax + obj.name_w + slider_w + obj.offs*2 + but_w*0,
                  y = tension_y,
                  w = but_w,
                  h = obj.rect_side,
                  col = 'white',
                  txt = '',
                  show = true,
                  a_frame = 0.05,
                  alpha_back = 0.1,
                  customslider_ctrl = true,
                  customslider_ctrl_rot = -1,
                  func =  function()  
                            mouse.context_latch_t = {obj['slotchild_sliderarea_tension'..i].y, data.slots[conf.activeknob][i].flags_tension}
                          end,
                  func_LD2 =function()
                              if mouse.context_latch_t then 
                                local out_val = lim(mouse.context_latch_t[2]  - mouse.dy/areah, 0, 1 )
                                obj['slotchild_sliderarea_tension'..i].y = areay + (areah - obj.rect_side)*(1-out_val)
                                data.slots[conf.activeknob][i].flags_tension = out_val
                                Data_ApplyHex(conf, obj, data, refresh, mouse, conf.activeknob, i)
                                local txt_type = math.floor(out_val*16)
                                if out_val ==0 then txt_type = 'linear' end
                                obj.infoline.txt = 'tension type: '..txt_type
                                
                                refresh.GUI_minor = true
                                refresh.data_minor = true
                              end
                             end  
                }   
    obj['slotchild_sliderarea_tensionback'..i] = { clear = true,
                  x = areax + obj.name_w + slider_w + obj.offs*2 + but_w*0,
                  y = areay,
                  w = but_w,
                  h = areah,
                  col = 'white',
                  txt = '',
                  show = true,
                  a_frame = 0.05,
                  alpha_back = 0.1,
                  ignore_mouse = true
                }                                                     
                                        
        local colfill_a = 0.2
        if data.slots[conf.activeknob][i].flags_mute == true then colfill_a= 0.6 end
        obj['slotchild_mute'..i] = { clear = true,
                        x = areax + obj.name_w + slider_w + obj.offs*2 + but_w*1,
                        y = areay,
                        w = but_w,
                        h = areah,
                        col = 'white',
                        txt = 'M',
                        txt_xshift = -1,
                        --aligh_txt = 17,
                        --txt_yshift = 1,
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        colfill_col = 'red',
                        colfill_a = colfill_a,
                        alpha_back = 0.4,
                        func =  function()
                                  data.slots[conf.activeknob][i].flags_mute = not data.slots[conf.activeknob][i].flags_mute
                                  Data_ApplyHex(conf, obj, data, refresh, mouse, conf.activeknob, i)
                                  refresh.data = true
                                  refresh.GUI = true
                                end,
                        func_mouseover = function() 
                                          obj.infoline.txt = 'Mute link'
                                          obj['slotchild_mute'..i].is_selected = true
                                          refresh.GUI_minor = true
                                        end }  

        obj['slotchild_del'..i] = { clear = true,
                        x = areax + obj.name_w + slider_w + obj.offs*2 + but_w*2,
                        y = areay,
                        w = but_w,
                        h = areah,
                        col = 'white',
                        txt = 'X',
                        txt_xshift = -1,
                        --aligh_txt = 17,
                        --txt_yshift = 1,
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        colfill_col = 'red',
                        colfill_a = 0.6,
                        alpha_back = 0.4,
                        func = function()
                          local ret = MB('Remove link?', conf.mb_title, 4)
                          if ret == 6 then 
                            Data_RemoveLink(conf, obj, data, refresh, mouse, conf.activeknob, i)
                            refresh.data = true
                            refresh.GUI = true
                          end
                        end,
                        func_mouseover = function() 
                                          obj.infoline.txt = 'Remove link'
                                          obj['slotchild_del'..i].is_selected = true
                                          refresh.GUI_minor = true
                                        end                            
                        }                                                                                                                                      
      end                  
    end
  end

  -----------------------------------------------
  function OBJ_Knobs(conf, obj, data, refresh, mouse)
   if data.masterJSFX_isvalid == true then 
    local knob_y_shift =4
    for knobid = 1, conf.slot_cnt do
      local disable_blitback,knob_a, ignore_selection = false, 0.3, false
      if conf.activeknob == knobid then
        disable_blitback = true
        knob_a = 0.8
        ignore_selection = true
      end
      local knob_x = obj.menu_w + obj.offs + obj.knob_w*(knobid-1)
      if knob_x + obj.knob_w > gfx.w - obj.knob_w then break end
      obj['knob'..knobid] = { clear = true,
                        ignore_selection = ignore_selection,
                        is_knob = true,
                        knob_y_shift = knob_y_shift,
                        x = knob_x,
                        y = 0,
                        w = obj.knob_w,
                        h = obj.menu_h,
                        col = 'white',
                        txt= math.floor(data.slots[knobid].val*100)..'%',
                        txt_yshift = knob_y_shift+10,
                        val = data.slots[knobid].val,
                        show = true,
                        fontsz = obj.GUI_fontsz3,
                        a_frame = 0,
                        knob_a = knob_a,
                        knob_haspoint = #data.slots[knobid] > 0,
                        disable_blitback = disable_blitback,
                        func =  function()  
                                  mouse.context_latch_val = data.slots[knobid].val
                                  conf.activeknob = knobid
                                  refresh.GUI = true
                                end,
                        func_R = function()
                                      Menu(mouse, {
                                                    { str='Show/hide track envelope for this knob',
                                                      func = function()
                                                                local track = VF_GetTrackByGUID(data.masterJSFX_trGUID)
                                                                SetMixerScroll( track )
                                                                TrackFX_EndParamEdit( track, data.masterJSFX_FXid, knobid-1 )
                                                                Action(41142)--FX: Show/hide track envelope for last touched FX parameter
                                                              end
                                                    },
                                                    { str='Arm track envelope for this knob',
                                                      func = function()
                                                                local track = VF_GetTrackByGUID(data.masterJSFX_trGUID)
                                                                TrackFX_EndParamEdit( track, data.masterJSFX_FXid, knobid-1 )
                                                                Action(41984) --FX: Arm track envelope for last touched FX parameter
                                                              end
                                                    },      
                                                    { str='Activate/bypass track envelope for this knob',
                                                      func = function()
                                                                local track = VF_GetTrackByGUID(data.masterJSFX_trGUID)
                                                                TrackFX_EndParamEdit( track, data.masterJSFX_FXid, knobid-1 )
                                                                Action(41983) --FX: Activate/bypass track envelope for last touched FX parameter
                                                              end
                                                    },          
                                                    { str='Set MIDI learn for this knob',
                                                      func = function()
                                                                local track = VF_GetTrackByGUID(data.masterJSFX_trGUID)
                                                                TrackFX_EndParamEdit( track, data.masterJSFX_FXid, knobid-1 )
                                                                Action(41144) --FX: Set MIDI learn for last touched FX parameter
                                                              end
                                                    },   
                                                    { str='Show parameter modulation/link for this knob',
                                                      func = function()
                                                                local track = VF_GetTrackByGUID(data.masterJSFX_trGUID)
                                                                TrackFX_EndParamEdit( track, data.masterJSFX_FXid, knobid-1 )
                                                                Action(41143) --FX: Show parameter modulation/link for last touched FX parameter
                                                              end
                                                    },                                                    
                                                    
                                                    
                                                  })
                                    end  ,                                   
                        func_LD2 = function()
                                      if mouse.context_latch_val then 
                                        local out_val = lim(mouse.context_latch_val + mouse.dx*0.001 - mouse.dy*0.01)
                                        obj['knob'..knobid].val = out_val
                                        obj['knob'..knobid].txt= math.floor(out_val*100)..'%',
                                        gmem_write(knobid, out_val)
                                        data.slots[knobid].val = out_val
                                        gmem_write(100, 1)
                                        conf.activeknob = knobid
                                        refresh.GUI_minor = true
                                        refresh.data_minor = true
                                      end
                                    end  ,
                        func_wheel = function()
                                        local add = 0.01
                                        if mouse.wheel_trig > 0 then 
                                          --add = 0.001 
                                         elseif mouse.wheel_trig < 0 then 
                                          add = -add
                                         else return 
                                        end
                                        local out_val = lim(data.slots[knobid].val + add)
                                        obj['knob'..knobid].val = out_val
                                        obj['knob'..knobid].txt= math.floor(out_val*100)..'%',
                                        gmem_write(knobid, out_val)
                                        data.slots[knobid].val = out_val
                                        gmem_write(100, 1)
                                        conf.activeknob = knobid
                                        refresh.GUI = true
                                        refresh.data = true                                        
                                      end,
                        func_mouseover =  function() 
                                            obj['knob'..knobid].is_selected = true
                                            refresh.GUI_minor = true
                                          end  ,
                        onrelease_L = function() 
                                        refresh.GUI = true
                                        refresh.data = true
                                      end ,
                               
                        }
      end
      obj.addparam = { clear = true,
                        ignore_selection = false,
                        x = gfx.w - obj.knob_w,
                        y = 0,
                        w = obj.knob_w,
                        h = obj.menu_h,
                        col = 'white',
                        txt= '+',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        knob_a = knob_a,
                        disable_blitback = disable_blitback,
                        func =  function()  
                                  Data_AddLink(conf, obj, data, refresh, mouse) 
                                  refresh.data = true
                                  refresh.GUI = true
                                end,
                        func_mouseover =  function() 
                                            if data.LTP_hasLTP and data.LTP_isvalid then
                                              obj.infoline.txt = 'Add link: '..data.LTP_trname..' / '..data.LTP_fxname..' / '..data.LTP_paramname
                                            end
                                            obj.addparam.is_selected = true
                                            refresh.GUI_minor = true
                                          end  
                        }
                        
     else -- not found master JSFX
            obj.replace_knob = { clear = true,
                        x = obj.menu_w + obj.offs,
                        y = 0,
                        w = gfx.w-obj.menu_w,
                        h = obj.menu_h,
                        col = 'white',
                        state = fale,
                        txt= '[ MappingPanel_master.jsfx not found ]',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        func =  function() 
                                  local ret = MB("Add MappingPanel master JSFX to selected track?", conf.mb_title, 4)
                                  if ret == 6 then 
                                    local tr = GetSelectedTrack(0,0)
                                    if tr then
                                      TrackFX_AddByName( tr, 'JS:MappingPanel_master.jsfx', false, 1 )
                                      refresh.data = true
                                      refresh.GUI = true
                                    end
                                  end
                                end}
      
    end
  end
  -----------------------------------------------
  function OBJ_MenuMain(conf, obj, data, refresh, mouse)
            obj.menu = { clear = true,
                        x = 0,
                        y = 0,
                        w = obj.menu_w,
                        h = obj.menu_h-obj.offs,
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
                                end}  
  end
