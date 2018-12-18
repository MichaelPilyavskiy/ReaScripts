-- @description InstrumentRack_obj
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex




  ---------------------------------------------------
  function OBJ_Update(conf, obj, data, refresh, mouse)
    for key in pairs(obj) do if type(obj[key]) == 'table' and obj[key].clear then obj[key] = {} end end  
    
    local min_w = 100
    local min_h = 20
    local reduced_view = gfx.h  <= min_h
    gfx.w  = math.max(min_w,gfx.w)
    gfx.h  = math.max(min_h,gfx.h)
    
    obj.menu_h = 30
    obj.scroll_w = 15
    obj.scroll_manual_h = 15
    obj.but_small_h = 12
    
    obj.list_offs_y = 0
    obj.list_it_h = 20
    obj.list_it_yspace = 2
    
    Obj_MenuMain  (conf, obj, data, refresh, mouse)
    Obj_Scroll(conf, obj, data, refresh, mouse)
    Obj_GenerateRack(conf, obj, data, refresh, mouse)
    
    for key in pairs(obj) do if type(obj[key]) == 'table' then       obj[key].context = key     end end    
  end
  -----------------------------------------------   
  function Obj_Scroll(conf, obj, data, refresh, mouse)
    local sbh = gfx.h - obj.list_offs_y- obj.menu_h - obj.offs
    local sbx = gfx.w  - obj.scroll_w -- obj.offs
    local sby = 0--obj.menu_h + obj.offs
    obj.scroll_bar = { clear = true,
                        x = sbx ,
                        y = sby,
                        w = obj.scroll_w,
                        h = sbh,
                        col = 'white',
                        txt= '',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        ignore_mouse = true,
                        func =  function()  end
                          }    
    obj.scroll_manual = { clear = true,
                        x = sbx,
                        y = sby + (sbh-obj.scroll_manual_h) * obj.scroll_value,
                        w = obj.scroll_w,
                        h = obj.scroll_manual_h,
                        col = 'white',
                        txt= '',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        alpha_back = 0.5,
                        func =  function() 
                                  mouse.context_latch_val = obj.scroll_value
                                end,
                        func_LD2 = function()
                                      if mouse.context_latch_val then 
                                        obj.scroll_value = lim(mouse.context_latch_val + mouse.dy/gfx.h)
                                        refresh.GUI = true
                                      end
                                    end  ,
                        onrelease_L2  = function()  
                                        end,
                          }                           
  end
  -----------------------------------------------
  function Obj_MenuMain(conf, obj, data, refresh, mouse)
            obj.menu = { clear = true,
                        x = gfx.w - obj.scroll_w,--obj.offs,
                        y = gfx.h - obj.menu_h,
                        w = obj.scroll_w,
                        h = obj.menu_h,
                        col = 'white',
                        state = fale,
                        txt= '>',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        func =  function() 
                                  Menu(mouse,               
    {
      { str = conf.mb_title..' '..conf.vrs,
        hidden = true
      },
      { str = 'Cockos Forum thread|',
        func = function() Open_URL('http://forum.cockos.com/showthread.php?t=188335') end  } , 
      { str = 'Donate to MPL',
        func = function() Open_URL('http://www.paypal.me/donate2mpl') end }  ,
      { str = 'Contact: MPL VK',
        func = function() Open_URL('http://vk.com/mpl57') end  } ,     
      { str = 'Contact: MPL SoundCloud|',
        func = function() Open_URL('http://soundcloud.com/mpl57') end  } ,     
        
      { str = '#Options'},    
        
                   
      { str = 'Dock '..'MPL '..conf.mb_title..' '..conf.vrs,
        func = function() 
                  conf.dock2 = math.abs(1-conf.dock2) 
                  gfx.quit() 
                  gfx.init('MPL '..conf.mb_title..' '..conf.vrs,
                            conf.wind_w, 
                            conf.wind_h, 
                            conf.dock2, conf.wind_x, conf.wind_y)
              end ,
        state = conf.dock2 == 1},                                                                            
    }
    )
                                  refresh.conf = true 
                                  --refresh.GUI = true
                                  --refresh.GUI_onStart = true
                                  refresh.data = true
                                end}  
  end  
  ---------------------------------------------------
  function OBJ_init(obj)  
    -- globals
    obj.reapervrs = tonumber(GetAppVersion():match('[%d%.]+')) 
    obj.offs = 2 
    obj.grad_sz = 200 
    
    obj.scroll_value = 0
     
     
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
                   black =   {0,0,0 }
                   }    
    
  end
  ---------------------------------------------------------
  function Obj_GenerateRack(conf, obj, data, refresh, mouse)
    local y_pos = obj.list_offs_y
    local com_h,last_h
    for i = 1, #data do
      local h_it = obj.list_it_h * 2 
      obj['fx_fr'..i] = { clear = true,
                        x = 0,
                        y = y_pos,
                        w = gfx.w- obj.scroll_w - obj.offs,
                        h =h_it,
                        col = 'white',
                        txt=  '',
                        aligh_txt = 1,
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        ignore_mouse = true,
                      }             
      y_pos = y_pos +  h_it + obj.list_it_yspace
      com_h = y_pos - obj.list_offs_y
      last_h = h_it+obj.list_it_yspace
    end

    for i = 1, #data do
      obj['fx_fr'..i].y = obj['fx_fr'..i].y - (com_h-last_h)*obj.scroll_value
      Obj_GenerateRack_Controls(conf, obj, data, refresh, mouse, obj['fx_fr'..i], i)   
    end    
    
  end
  ------------------------------------------------------------------
  function Obj_GenerateRack_Controls(conf, obj, data, refresh, mouse, src_t, i) 
    -- bypass state
      local byp_w = 20 
      local col_fill  if data[i].bypass then col_fill = 'green' end
      obj['fx_byp'..i] = { clear = true,
                        x = src_t.x,
                        y = src_t.y + math.floor((obj.list_it_h - obj.but_small_h)/2),
                        w = byp_w,
                        h = obj.but_small_h,
                        colfill_col = col_fill,
                        colfill_a = 0.6,
                        txt=  'B',
                        show = true,
                        fontsz = obj.GUI_fontsz3,
                        a_frame = 0,
                        func = function() 
                          local ret, tr, id = VF_GetFXByGUID(data[i].GUID)
                          if ret then
                            TrackFX_SetEnabled(tr, id, not data[i].bypass )
                            refresh.data = true
                            refresh.GUI_minor = true
                          end
                        end
                      }   
    -- edit
      local colfill_a = 0  if data[i].is_open then col_fill = 0.6 end
      obj['fx_edit'..i] = { clear = true,
                        x = src_t.x + byp_w + obj.offs,
                        y = src_t.y + math.floor((obj.list_it_h - obj.but_small_h)/2),
                        w = byp_w,
                        h = obj.but_small_h,
                        colfill_col = 'white',
                        colfill_a =colfill_a,
                        txt=  'E',
                        show = true,
                        fontsz = obj.GUI_fontsz3,
                        a_frame = 0,
                        func = function() 
                          local ret, tr, id = VF_GetFXByGUID(data[i].GUID)
                          if ret then
                            if data[i].is_open == true then TrackFX_SetOpen( tr, id, false ) else TrackFX_Show( tr, id, 3 )  end
                            refresh.data = true
                            refresh.GUI_minor = true
                          end
                        end
                      }                             
    -- FX name
      local name_w = 200
      local txt = data[i].name
      obj['fx_name'..i] = { clear = true,
                        x = src_t.x + (byp_w + obj.offs)*2,
                        y = src_t.y,
                        w = name_w,
                        h = obj.list_it_h,
                        disable_blitback = true,
                        --colfill_col = col_fill,
                        --colfill_a = 0.6,
                        txt=  '('..data[i].tr_id..') '..data[i].tr_name..' | '..MPL_ReduceFXname(txt),
                        aligh_txt = 1,
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        func = function() 
                          local ret, tr, id = VF_GetFXByGUID(data[i].GUID)
                          if ret then
                            TrackFX_SetEnabled(tr, id, not data[i].bypass )
                            refresh.data = true
                            refresh.GUI_minor = true
                          end
                        end
                      }    
    -- preset
      local preset_w = 200
      local txt = data[i].presetname
      obj['fx_presname'..i] = { clear = true,
                        x = src_t.x + (byp_w + obj.offs)*2,
                        y = src_t.y+obj.list_it_h,
                        w = preset_w,
                        h = obj.list_it_h,
                        disable_blitback = true,
                        --colfill_col = col_fill,
                        --colfill_a = 0.6,
                        txt=  txt,
                        aligh_txt = 1,
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        func = function() 
                          
                              end
                      }                                
 
  end
