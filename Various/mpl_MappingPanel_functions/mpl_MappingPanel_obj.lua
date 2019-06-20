-- @description MappingPanel_obj
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex
  
  
  ---------------------------------------------------
  function OBJ_init(obj)  
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
    
  end
  ---------------------------------------------------
  function OBJ_Update(conf, obj, data, refresh, mouse, strategy) 
    for key in pairs(obj) do if type(obj[key]) == 'table' and obj[key].clear then obj[key] = {} end end  
    
    local min_w = 520
    local min_h = 250
    local reduced_view = gfx.h  <= min_h
    gfx.w  = math.max(min_w,gfx.w)
    gfx.h  = math.max(min_h,gfx.h)
    
    obj.offs = 2
    obj.menu_w = 15
    obj.menu_h = 40
    obj.knob_w = math.min((gfx.w - obj.menu_w - obj.offs)/(conf.slot_cnt+1), 45)
    obj.rect_side = 8
    obj.glass_h = math.floor(obj.menu_h*0.9)-1
    
    OBJ_MenuMain (conf, obj, data, refresh, mouse)
    OBJ_Knobs(conf, obj, data, refresh, mouse) 
    OBJ_Knob_Childrens(conf, obj, data, refresh, mouse) 
    
    for key in pairs(obj) do if type(obj[key]) == 'table' then  obj[key].context = key  end end    
  end
  -----------------------------------------------
  function OBJ_Knob_Childrens_SlideCtrl(conf, obj, data, refresh, mouse, i, areax,areay,areaw,areah)  
    local limmin_x = areax + areaw * data.slots[conf.activeknob][i].hexarray_lim_min
    obj['slotchild_sliderarealimmin'..i] = { clear = true,
                  x = limmin_x,
                  y = areay+areah/2-obj.glass_h/2,
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
                            mouse.context_latch_t = {obj['slotchild_sliderarealimmin'..i].x, data.slots[conf.activeknob][i].hexarray_lim_min}
                          end,
                  func_LD2 =function()
                              if mouse.context_latch_t then 
                                local lim1 = 0.97
                                local out_val = lim(mouse.context_latch_t[2] + mouse.dx/areaw, 0 , lim1)-- - mouse.dy*0.01)
                                obj['slotchild_sliderarealimmin'..i].x = lim(mouse.context_latch_t[1] + mouse.dx , areax, areax + areaw*lim1)
                                Data_SetHex(conf, obj, data, refresh, mouse, conf.activeknob, i, 0, out_val)
                                refresh.GUI_minor = true
                                refresh.data_minor = true
                              end
                             end  
                }
    local limmax_x = areax + areaw - areaw * data.slots[conf.activeknob][i].hexarray_lim_max-obj.rect_side-1
    obj['slotchild_sliderarealimmax'..i] = { clear = true,
                  x = limmax_x,
                  y = areay+areah/2-obj.glass_h/2,
                  w = obj.rect_side,
                  h = obj.rect_side,
                  col = 'white',
                  txt = '',
                  show = true,
                  a_frame = 0.05,
                  alpha_back = 0.1,
                  customslider_ctrl = true,
                  customslider_ctrl_rot = 90,
                  func =  function()  
                            mouse.context_latch_t = {obj['slotchild_sliderarealimmax'..i].x, data.slots[conf.activeknob][i].hexarray_lim_max}
                          end,
                  func_LD2 =function()
                              if mouse.context_latch_t then 
                                local lim1 = 0.97
                                local out_val = lim(mouse.context_latch_t[2] - mouse.dx/areaw, 0 , lim1)-- - mouse.dy*0.01)
                                obj['slotchild_sliderarealimmax'..i].x = lim(mouse.context_latch_t[1] + mouse.dx , areax + areaw*(1-lim1)-obj.rect_side, areax + areaw-obj.rect_side)
                                Data_SetHex(conf, obj, data, refresh, mouse, conf.activeknob, i, 8, out_val)
                                refresh.GUI_minor = true
                                refresh.data_minor = true
                              end
                             end  
                }                   
                
    local scalemin_x = areax + areaw * data.slots[conf.activeknob][i].hexarray_scale_min
    obj['slotchild_sliderarea_sclalemin'..i] = { clear = true,
                  x = scalemin_x,
                  y = areay+areah/2+obj.glass_h/2-obj.rect_side-1,
                  w = obj.rect_side,
                  h = obj.rect_side,
                  col = 'white',
                  txt = '',
                  show = true,
                  a_frame = 0.05,
                  alpha_back = 0.1,
                  customslider_ctrl = true,
                  customslider_ctrl_rot = 270,
                  func =  function()  
                            mouse.context_latch_t = {obj['slotchild_sliderarea_sclalemin'..i].x, data.slots[conf.activeknob][i].hexarray_scale_min}
                          end,
                  func_LD2 =function()
                              if mouse.context_latch_t then 
                                local lim1 = 0.97
                                local out_val = lim(mouse.context_latch_t[2] + mouse.dx/areaw, 0 , lim1)-- - mouse.dy*0.01)
                                obj['slotchild_sliderarea_sclalemin'..i].x = lim(mouse.context_latch_t[1] + mouse.dx , areax, areax + areaw*lim1)
                                Data_SetHex(conf, obj, data, refresh, mouse, conf.activeknob, i, 16, out_val)
                                refresh.GUI_minor = true
                                refresh.data_minor = true
                              end
                             end  
                } 
    local scalemax_x = areax + areaw - areaw * data.slots[conf.activeknob][i].hexarray_scale_max-obj.rect_side -1
    obj['slotchild_sliderarea_sclalemax'..i] = { clear = true,
                  x = scalemax_x,
                  y = areay+areah/2+obj.glass_h/2-obj.rect_side-1,
                  w = obj.rect_side,
                  h = obj.rect_side,
                  col = 'white',
                  txt = '',
                  show = true,
                  a_frame = 0.05,
                  alpha_back = 0.1,
                  customslider_ctrl = true,
                  customslider_ctrl_rot = 180,
                  func =  function()  
                            mouse.context_latch_t = {obj['slotchild_sliderarea_sclalemax'..i].x, data.slots[conf.activeknob][i].hexarray_scale_max}
                          end,
                  func_LD2 =function()
                              if mouse.context_latch_t then 
                                local lim1 = 0.97
                                local out_val = lim(mouse.context_latch_t[2] - mouse.dx/areaw, 0 , lim1)-- - mouse.dy*0.01)
                                obj['slotchild_sliderarea_sclalemax'..i].x = lim(mouse.context_latch_t[1] + mouse.dx , areax + areaw*(1-lim1)-obj.rect_side, areax + areaw-obj.rect_side)
                                Data_SetHex(conf, obj, data, refresh, mouse, conf.activeknob, i, 24, out_val)
                                refresh.GUI_minor = true
                                refresh.data_minor = true
                              end
                             end  
                }      
    local tension_y = areay + (areah-obj.glass_h)/2 + obj.glass_h - obj.rect_side - ((obj.glass_h-obj.rect_side) * data.slots[conf.activeknob][i].flags_tension)
    obj['slotchild_sliderarea_tension'..i] = { clear = true,
                  x = areax-obj.rect_side,
                  y = tension_y,
                  w = obj.rect_side,
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
                                local out_val = lim(mouse.context_latch_t[2]  - 2*mouse.dy/areaw, 0, 1 )
                                obj['slotchild_sliderarea_tension'..i].y = 
                                  areay + (areah-obj.glass_h)/2 + obj.glass_h - obj.rect_side - ((obj.glass_h-obj.rect_side) * out_val)
                                Data_ToggleFlags(conf, obj, data, refresh, mouse, conf.activeknob, i, nil, true, out_val)
                                refresh.GUI_minor = true
                                refresh.data_minor = true
                              end
                             end  
                }   
    obj['slotchild_sliderarea_tensionback'..i] = { clear = true,
                  x = areax-obj.rect_side,
                  y = areay + (areah-obj.glass_h)/2,
                  w = obj.rect_side,
                  h = obj.glass_h,
                  col = 'white',
                  txt = '',
                  show = true,
                  a_frame = 0.05,
                  alpha_back = 0.1,
                  ignore_mouse = true
                }                                                                                                                                                                                                 
  end                
  -----------------------------------------------
  function OBJ_Knob_Childrens(conf, obj, data, refresh, mouse) 
    if not data.slots or not data.slots[conf.activeknob] then return end
    local slotchilds_cnt = #data.slots[conf.activeknob]
    local child_h = 45
    local name_w = 150
    local but_w = 20
    local but_cnt = 2
    for i = 1, slotchilds_cnt do
      if data.slots[conf.activeknob][i] then
        local areax,areay,areaw,areah = obj.offs*3 ,
                                        obj.menu_h + obj.offs*2 + (child_h +obj.offs)* (i-1),
                                        gfx.w - obj.offs*6,
                                        child_h
        local slider_w = areaw - name_w - obj.offs*4 - but_w * but_cnt
        obj['slotchildarea'..i] = { clear = true,
                        x = areax,
                        y = areay,
                        w = areaw,
                        h = areah,
                        col = 'white',
                        txt = '',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0.05,
                        alpha_back = 0,
                        ignore_mouse = true}
        local txt_name =  (data.slots[conf.activeknob][i].JSFX_paramid+1)..' ← '..data.slots[conf.activeknob][i].trname..'\n'..
                          '   FX#'..(data.slots[conf.activeknob][i].Slave_FXid+1)..' / '..
                          '   '..MPL_ReduceFXname(data.slots[conf.activeknob][i].Slave_FXname)..'\n'..
                          '   Param#'..(data.slots[conf.activeknob][i].Slave_paramid+1)..' / '..data.slots[conf.activeknob][i].Slave_paramname
        obj['slotchild_name'..i] = { clear = true,
                        x = areax,
                        y = areay,
                        w = name_w-obj.rect_side-obj.offs*2,
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
                        x = areax + name_w + obj.offs,
                        y = areay,
                        w = slider_w,
                        h = areah,
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
        OBJ_Knob_Childrens_SlideCtrl(conf, obj, data, refresh, mouse, i, areax + name_w + obj.offs,areay,slider_w,areah)                         
                        
        local colfill_a = 0.2
        if data.slots[conf.activeknob][i].flags_mute == true then colfill_a= 0.6 end
        obj['slotchild_mute'..i] = { clear = true,
                        x = areax + name_w + slider_w + obj.offs*4 + but_w*0,
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
                                  Data_ToggleFlags(conf, obj, data, refresh, mouse, conf.activeknob, i, 0)
                                  refresh.data = true
                                  refresh.GUI = true
                                end}  

        obj['slotchild_del'..i] = { clear = true,
                        x = areax + name_w + slider_w + obj.offs*4 + but_w*1,
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
                        end}                                                                                                                                      
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
      obj['knob'..knobid] = { clear = true,
                        ignore_selection = ignore_selection,
                        is_knob = true,
                        knob_y_shift = knob_y_shift,
                        x = obj.menu_w + obj.offs + obj.knob_w*(knobid-1),
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
                        func_LD2 = function()
                                      if mouse.context_latch_val then 
                                        local out_val = lim(mouse.context_latch_val + mouse.dx*0.001 - mouse.dy*0.01)
                                        obj['knob'..knobid].val = out_val
                                        obj['knob'..knobid].txt= math.floor(data.slots[knobid].val*100)..'%',
                                        gmem_write(knobid, out_val)
                                        data.slots[knobid].val = out_val
                                        gmem_write(100, 1)
                                        conf.activeknob = knobid
                                        refresh.GUI_minor = true
                                        refresh.data_minor = true
                                      end
                                    end  ,
                        func_mouseover =  function() 
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
                        x = obj.menu_w + obj.offs + obj.knob_w*conf.slot_cnt,
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
                                            refresh.GUI_minor = true
                                          end  ,
                               
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
