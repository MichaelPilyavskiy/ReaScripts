-- @description InstrumentRack_obj
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex




  ---------------------------------------------------
  function OBJ_Update(conf, obj, data, refresh, mouse, data_ext)
    for key in pairs(obj) do if type(obj[key]) == 'table' and obj[key].clear then obj[key] = {} end end  
    
    local min_w = 100
    local min_h = 20
    local reduced_view = gfx.h  <= min_h
    gfx.w  = math.max(min_w,gfx.w)
    gfx.h  = math.max(min_h,gfx.h)

    obj.but_small_h = 13
        
    obj.menu_h = 30
    obj.scroll_w = 15
    obj.scroll_manual_h = 15    
    
    obj.list_offs_y = 0
    obj.list_it_h = 20
    obj.list_it_yspace = 2
    
    obj.but_w = 22  
    obj.txt_inactive = 0.2
    obj.txt_active = 1
    obj.colfill_a_auto = 0.4  
      
    obj.knob_area_h = 30
    obj.knob_w = obj.but_w*2
    obj.knob_h = obj.knob_area_h
    obj.peak_w = obj.but_w/4
    
    Obj_AddFX  (conf, obj, data, refresh, mouse, data_ext)
    Obj_MenuMain  (conf, obj, data, refresh, mouse, data_ext)
    Obj_Scroll(conf, obj, data, refresh, mouse)
    Obj_GenerateRack(conf, obj, data, refresh, mouse, data_ext)
    
    for key in pairs(obj) do if type(obj[key]) == 'table' then       obj[key].context = key     end end    
  end
  -----------------------------------------------   
  function Obj_Scroll(conf, obj, data, refresh, mouse)
    local sbh = gfx.h - obj.list_offs_y- obj.menu_h*2 - obj.offs
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
  function Obj_AddFX(conf, obj, data, refresh, mouse, data_ext)
    obj.addfx = { clear = true,
                        x = gfx.w - obj.scroll_w,--obj.offs,
                        y = gfx.h - obj.menu_h*2,
                        w = obj.scroll_w,
                        h = obj.menu_h,
                        col = 'white',
                        state = false,
                        txt= '+',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        func =  function() 
                                  local  t = {}
                                  local abc = 'a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
                                  t[#t+1] = { str = '>All'}
                                  for let in abc:gmatch('[^,]') do
                                    local new_let =1
                                    local new_let_sep = ''
                                    
                                    for i = 1, #obj.plugs_data do
                                      local name = obj.plugs_data[i].name
                                      if name:sub(0,1):lower() == let then
                                        t[#t+1] = 
                                            { str = new_let_sep..obj.plugs_data[i].reduced_name,
                                              func = function() 
                                                        local tr = GetSelectedTrack(0,0)
                                                        if tr then 
                                                          local id = TrackFX_AddByName( tr, obj.plugs_data[i].name, false, 1 )
                                                          if conf.floatchain == 1 then TrackFX_Show( tr, id, 1 ) else TrackFX_Show( tr, id, 3 ) end
                                                        end
                                                    
                                                     end  }
                                        new_let = new_let + 1
                                      end
                                    end
                                  end
                                                                    
                                  for let in abc:gmatch('[^,]') do
                                    local new_let =1
                                    local new_let_sep = ''
                                    
                                    for i = 1, #obj.plugs_data do
                                      local name = obj.plugs_data[i].name
                                      if name:sub(0,1):lower() == let then
                                        if new_let == 1 then
                                          t[#t+1] = { str = '>'..let:upper()}
                                          if #t >= 3 then 
                                            t[#t-1].str = t[#t-1].str..'|<' 
                                          end
                                        end
                                        t[#t+1] = 
                                            { str = new_let_sep..obj.plugs_data[i].reduced_name,
                                              func = function() 
                                                        local tr = GetSelectedTrack(0,0)
                                                        if tr then 
                                                          local id = TrackFX_AddByName( tr, obj.plugs_data[i].name, false, 1 )
                                                          if conf.floatchain == 1 then TrackFX_Show( tr, id, 1 ) else TrackFX_Show( tr, id, 3 ) end
                                                        end
                                                    
                                                     end  }
                                        new_let = new_let + 1
                                      end
                                    end
                                  end
                                  Menu(mouse, t)  
                                  refresh.conf = true 
                                  refresh.data = true            
                                end
                      }    
  end         
  -----------------------------------------------
  function Obj_MenuMain(conf, obj, data, refresh, mouse, data_ext)
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
      { str = '>Edit'},     
      { str = 'Select and scroll to track on click',
        state = conf.scrolltotrackonedit ==1 ,
        func = function()  conf.scrolltotrackonedit = math.abs(1-conf.scrolltotrackonedit)  end  } ,   
      { str = 'Show FX chain instead floating FX|<',
        state = conf.floatchain ==1 ,
        func = function()  conf.floatchain = math.abs(1-conf.floatchain)  end  } ,                 
      { str = '>Controls'},                     
      { str = 'Show all controls',
        func = function()
                   for i = 1, #data do
                     if data[i].GUID then
                       if not data_ext[data[i].GUID] then data_ext[data[i].GUID] = {} end
                       data_ext[data[i].GUID].open = true
                      end 
                    end
                    refresh.data_ext = true
                    refresh.data = true
                    refresh.GUI = true
                end  } ,
      { str = 'Hide all controls',
        func = function()
                   for i = 1, #data do
                     if data[i].GUID then
                       if not data_ext[data[i].GUID] then data_ext[data[i].GUID] = {} end
                       data_ext[data[i].GUID].open = false
                      end 
                    end
                    refresh.data_ext = true
                    refresh.data = true
                    refresh.GUI = true
                end  } ,                    
                
      { str = 'Show only instrument TCP controls',
        state = conf.obeyyallcontrols ==0 ,
        func = function()  conf.obeyyallcontrols = math.abs(1-conf.obeyyallcontrols) refresh.GUI = true refresh.data = true  end  } ,                  
      { str = 'Allow only one FX control stay opened|<|',
        state = conf.allowonlyonectrl ==1 ,
        func = function()  conf.allowonlyonectrl = math.abs(1-conf.allowonlyonectrl)  end  } ,  
                                                             
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
  ---------------------------------------------------
  function OBJ_init(obj)  
    -- globals
    obj.reapervrs = tonumber(GetAppVersion():match('[%d%.]+')) 
    obj.offs = 2 
    obj.offs2 = 6 
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
  function Obj_GenerateRack(conf, obj, data, refresh, mouse, data_ext)
    local y_pos = obj.list_offs_y
    local com_h,last_h
    for i = 1, #data do
      local h_it = obj.but_small_h*3+obj.offs*5--obj.list_it_h * 2 
      if data[i].GUID and data_ext[data[i].GUID] and data_ext[data[i].GUID].open == true then h_it = h_it + obj.knob_area_h end        
      local a_frame = 0
      if data[i].tr_issel then a_frame = 0.3 end
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
                        a_frame = a_frame,
                        ignore_mouse = true,
                      }             
      y_pos = y_pos +  h_it + obj.list_it_yspace
      com_h = y_pos - obj.list_offs_y
      last_h = h_it+obj.list_it_yspace
    end

    for i = 1, #data do
      obj['fx_fr'..i].y = obj['fx_fr'..i].y - (com_h-last_h)*obj.scroll_value
      local x_drift = Obj_GenerateRack_Controls(conf, obj, data, refresh, mouse, data_ext, obj['fx_fr'..i], i)
      Obj_GenerateRack_Controls_name(conf, obj, data, refresh, mouse, data_ext, obj['fx_fr'..i], i) 
      Obj_GenerateRack_Controls_knobs(conf, obj, data, refresh, mouse, data_ext, obj['fx_fr'..i], i, x_drift)  
    end    
    
  end
  ------------------------------------------------------------------
  function Obj_GenerateRack_Controls(conf, obj, data, refresh, mouse, data_ext, src_t, i) 
    -- offline state
      local col_fill,colfill_a = 'white'  ,0
      if not data[i].is_offline then col_fill,colfill_a = 'red', 0.8 end
      obj['fx_off'..i] = { clear = true,
                        x = src_t.x + obj.offs2,
                        y = src_t.y + obj.offs,
                        w = obj.but_w,
                        h = obj.but_small_h,
                        colfill_col = col_fill,
                        colfill_a = colfill_a,
                        txt=  'On',
                        show = true,
                        fontsz = obj.GUI_fontsz3,
                        a_frame = 0,
                        func = function() 
                          local ret, tr, id = VF_GetFXByGUID(data[i].GUID)
                          if ret then
                            TrackFX_SetOffline(tr, id,not  data[i].is_offline )
                            refresh.data = true
                            refresh.GUI_minor = true
                          end
                        end
                      }   
      local x_drift = src_t.x + obj.but_w + obj.offs2
    -- bypass state
    local col_fill,colfill_a = 'white'  ,0
    if data[i].bypass then col_fill,colfill_a = 'green', 0.6 end
      local txt_a = obj.txt_inactive  if data[i].bypass  then txt_a = obj.txt_active end
      obj['fx_byp'..i] = { clear = true,
                        x = x_drift,
                        y = src_t.y + obj.offs,
                        w = obj.but_w*2,
                        h = obj.but_small_h,
                        txt=  'Enabled',
                        txt_a=txt_a,
                        colfill_col = col_fill,
                        colfill_a = colfill_a,
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
    x_drift = x_drift + obj.offs2 + obj.but_w*2
      local txt_a = obj.txt_inactive  if data[i].is_open  then txt_a = obj.txt_active end
      obj['fx_edit'..i] = { clear = true,
                        x = x_drift,
                        y = src_t.y + obj.offs,
                        w = obj.but_w*2,
                        h = obj.but_small_h,
                        txt=  'Edit',
                        txt_a=txt_a,
                        show = true,
                        fontsz = obj.GUI_fontsz3,
                        a_frame = 0,
                        func = function() 
                          local ret, tr, id = VF_GetFXByGUID(data[i].GUID)
                          if ret then
                            if data[i].is_open then TrackFX_Show( tr, id, 2) else 
                              if conf.floatchain == 1 then TrackFX_Show( tr, id, 1 ) else TrackFX_Show( tr, id, 3 ) end
                            end
                            if conf.scrolltotrackonedit == 1 then
                              SetMixerScroll( tr )
                              SetOnlyTrackSelected( tr )
                              Action(40913)--Track: Vertical scroll selected tracks into view
                            end
                            
                            refresh.data = true
                            refresh.GUI = true
                            UpdateArrange()
                          end
                        end
                      } 
    -- solo
    x_drift = x_drift + obj.offs2 + obj.but_w*2
      local col_fill,colfill_a = 'white' ,0
      if data[i].tr_solo then col_fill,colfill_a = 'green', 0.7 end
      obj['fx_solo'..i] = { clear = true,
                        x = x_drift,
                        y = src_t.y + obj.offs,
                        w = obj.but_w,
                        h = obj.but_small_h,
                        colfill_col = col_fill,
                        colfill_a = colfill_a,
                        txt=  'S',
                        show = true,
                        fontsz = obj.GUI_fontsz3,
                        a_frame = 0,
                        func = function() 
                          local  tr = BR_GetMediaTrackByGUID( 0, data[i].trGUID )
                          if tr then
                            local out_st = 0
                            if not data[i].tr_solo then out_st = 1 end
                            CSurf_OnSoloChange(  tr, out_st )
                            refresh.data = true
                            refresh.GUI_minor = true
                          end
                        end
                      }  
    -- mute
    x_drift = x_drift  + obj.but_w
      local col_fill,colfill_a = 'white' ,0
      if data[i].tr_mute then col_fill,colfill_a = 'red', 0.7 end
      obj['fx_mute'..i] = { clear = true,
                        x = x_drift,
                        y = src_t.y + obj.offs,
                        w = obj.but_w,
                        h = obj.but_small_h,
                        colfill_col = col_fill,
                        colfill_a = colfill_a,
                        txt=  'M',
                        show = true,
                        fontsz = obj.GUI_fontsz3,
                        a_frame = 0,
                        func = function() 
                          local  tr = BR_GetMediaTrackByGUID( 0, data[i].trGUID )
                          if tr then
                            local out_st = 0
                            if not data[i].tr_mute then out_st = 1 end
                            CSurf_OnMuteChange(  tr, out_st )
                            refresh.data = true
                            refresh.GUI_minor = true
                          end
                        end
                      }    
    -- freeze
    x_drift = x_drift + obj.offs2 + obj.but_w
      local col_fill,colfill_a = 'white' ,0
      if data[i].tr_isfreezed then col_fill,colfill_a = 'blue', 0.7 end
      obj['fx_freeze'..i] = { clear = true,
                        x = x_drift,
                        y = src_t.y + obj.offs,
                        w = obj.but_w*2,
                        h = obj.but_small_h,
                        colfill_col = col_fill,
                        colfill_a = colfill_a,
                        txt=  'Freeze',
                        show = true,
                        fontsz = obj.GUI_fontsz3,
                        a_frame = 0,
                        func = function() 
                          local  tr = BR_GetMediaTrackByGUID( 0, data[i].trGUID )
                          if tr then
                            SetOnlyTrackSelected( tr ) 
                            if not data[i].tr_isfreezed then
                              Action(41223)--Track: Unfreeze tracks (restore previously saved items and FX)
                             else
                              Action(41644)--Track: Freeze to stereo (render pre-fader, save/remove items and online FX)                              
                            end
                            
                            refresh.data = true
                            refresh.GUI_minor = true
                          end
                        end
                      }  
    -- auto trim read
    x_drift = x_drift + obj.offs2 + obj.but_w*2
      local colfill_col,colfill_a = 'white' ,0
      local txt_a = obj.txt_inactive  
      if data[i].tr_automode == 0  then txt_a = obj.txt_active colfill_a = obj.colfill_a_auto end
      obj['fx_auto'..i] = { clear = true,
                        x =x_drift,
                        y = src_t.y + obj.offs,
                        w = obj.but_w,
                        h = obj.but_small_h,
                        colfill_col = colfill_col,
                        colfill_a = colfill_a,
                        txt=  'R',
                        txt_a = txt_a,
                        show = true,
                        fontsz = obj.GUI_fontsz3,
                        a_frame = 0,
                        func = function() 
                          local  tr = BR_GetMediaTrackByGUID( 0, data[i].trGUID )
                          if tr then
                            SetMediaTrackInfo_Value( tr, 'I_AUTOMODE', 0 )
                            UpdateArrange()
                            refresh.data = true
                            refresh.GUI = true
                          end
                        end
                      }  
    -- auto touch 
    x_drift = x_drift + obj.but_w
      local colfill_col,colfill_a = 'white' ,0
      local txt_a = obj.txt_inactive  if data[i].tr_automode == 2  then txt_a = obj.txt_active colfill_a = obj.colfill_a_auto end
      obj['fx_auto2'..i] = { clear = true,
                        x = x_drift,
                        y = src_t.y + obj.offs,
                        w = obj.but_w,
                        h = obj.but_small_h,
                        txt=  'T',
                        txt_col = 'green',
                        colfill_col = colfill_col,
                        colfill_a = colfill_a,
                        txt_a = txt_a,
                        show = true,
                        fontsz = obj.GUI_fontsz3,
                        a_frame = 0,
                        func = function() 
                          local  tr = BR_GetMediaTrackByGUID( 0, data[i].trGUID )
                          if tr then
                            SetMediaTrackInfo_Value( tr, 'I_AUTOMODE', 2 )
                            UpdateArrange()
                            refresh.data = true
                            refresh.GUI = true
                          end
                        end
                      }  
    -- auto latch 
    x_drift = x_drift + obj.but_w
    local colfill_col,colfill_a = 'white' ,0
      local txt_a = obj.txt_inactive  if data[i].tr_automode == 4  then txt_a = obj.txt_active  colfill_a = obj.colfill_a_auto end
      obj['fx_auto3'..i] = { clear = true,
                        x = x_drift,
                        y = src_t.y + obj.offs,
                        w = obj.but_w,
                        h = obj.but_small_h,
                        txt=  'L',
                        txt_a = txt_a,
                        txt_col = 'blue',
                        colfill_col = colfill_col,
                        colfill_a = colfill_a,
                        show = true,
                        fontsz = obj.GUI_fontsz3,
                        a_frame = 0,
                        func = function() 
                          local  tr = BR_GetMediaTrackByGUID( 0, data[i].trGUID )
                          if tr then
                            SetMediaTrackInfo_Value( tr, 'I_AUTOMODE', 4 )
                            UpdateArrange()
                            refresh.data = true
                            refresh.GUI = true
                          end
                        end
                      }     
    -- auto latch 
    x_drift = x_drift + obj.but_w
    local colfill_col,colfill_a = 'white' ,0
      local txt_a = obj.txt_inactive  if data[i].tr_automode ==3  then txt_a = obj.txt_active colfill_a = obj.colfill_a_auto end
      obj['fx_auto4'..i] = { clear = true,
                        x = x_drift,
                        y = src_t.y + obj.offs,
                        w = obj.but_w,
                        h = obj.but_small_h,
                        colfill_col = colfill_col,
                        colfill_a = colfill_a,
                        txt=  'W',
                        txt_col = 'red',
                        txt_a = txt_a,
                        show = true,
                        fontsz = obj.GUI_fontsz3,
                        a_frame = 0,
                        func = function() 
                          local  tr = BR_GetMediaTrackByGUID( 0, data[i].trGUID )
                          if tr then
                            SetMediaTrackInfo_Value( tr, 'I_AUTOMODE',3 )
                            UpdateArrange()
                            refresh.data = true
                            refresh.GUI = true
                          end
                        end
                      }                                                                                                                                                                                  
    x_drift = x_drift + obj.but_w
    return x_drift
                        
 
  end
  ----------------------------------------------------------------
  function Obj_GenerateRack_Controls_knobs(conf, obj, data, refresh, mouse, data_ext, src_t, i, x_drift)   
    local w_knob = gfx.w- x_drift- obj.offs*3-obj.scroll_w
    if w_knob < obj.but_w*3 then return end
    if not (data[i] and data[i].tcp_params and data[i].tcp_params.cnt) then return end
    
    local kn_cnt = data[i].tcp_params.cnt
    local alpha_back = 0.15 if kn_cnt > 0  then alpha_back = 0.6 end
    -- knobs
      obj['fx_knob_setopen'..i] = { clear = true,
                        x = x_drift+ obj.offs,
                        y = src_t.y + obj.offs,
                        w = w_knob,
                        h = obj.but_small_h,
                        alpha_back = alpha_back,
                        txt=  'Controls',
                        show = true,
                        fontsz = obj.GUI_fontsz3,
                        a_frame = 0,
                        func =  function() 
                                  if data[i].GUID then
                                    if not data_ext[data[i].GUID] then data_ext[data[i].GUID] = {} end
                                    local new_state = not data_ext[data[i].GUID].open
                                    data_ext[data[i].GUID].open = new_state
                                    if conf.allowonlyonectrl == 1 and new_state == true then
                                      for GUID in pairs(data_ext) do
                                        if data[i].GUID~= GUID then
                                          data_ext[GUID].open  = false
                                        end
                                      end
                                    end
                                    
                                    refresh.data_ext = true
                                    refresh.data = true
                                    refresh.GUI = true
                                  end                                 
                                end
                      }
                      
      if not data[i].ext_t or not data[i].ext_t.open then return end
      
      --[[local s_cnt = 0
      for tcp_params_id in  pairs(data[i].tcp_params) do s_cnt = s_cnt + 1 end
      local x_sends_shift = s_cnt * obj.knob_w]]

              
      local tcp_params_id_int = 0
      for fx_id in  pairs(data[i].tcp_params) do
        if type(data[i].tcp_params[fx_id]) == 'table' then
        for tcp_params_id in  pairs(data[i].tcp_params[fx_id]) do
          
          tcp_params_id_int = tcp_params_id_int + 1 
          local val = TrackFX_GetParamNormalized( data[i].tr_ptr, fx_id, tcp_params_id ) 
                        
                        
          obj['fx_'..fx_id..'_'..i..'tcp'..tcp_params_id] = { clear = true,
                            is_knob = true,
                            knob_y_shift = 7,
                          x = src_t.x  + obj.offs2 + obj.knob_w * (tcp_params_id_int-1),
                          y = src_t.y  +src_t.h  - obj.knob_area_h,
                          w = obj.knob_w,
                          h = obj.knob_h,
                          disable_blitback = true,
                            col = 'white',
                            txt= '',
                            val = lim(val),
                            show = true,
                            fontsz = obj.GUI_fontsz2,
                            a_frame = 0,
                            func =  function()                   
                                      local val_intern = TrackFX_GetParamNormalized( data[i].tr_ptr, fx_id, tcp_params_id )                                                       
                                      mouse.context_latch_val = val_intern
                                    end,
                            func_LD2 = function()
                                          if mouse.context_latch_val then                                           
                                            local out_val = lim(mouse.context_latch_val + mouse.dx*0.0005 - mouse.dy*0.01)
                                            obj['fx_'..fx_id..'_'..i..'tcp'..tcp_params_id].val = out_val
                                            TrackFX_SetParamNormalized( data[i].tr_ptr, fx_id, tcp_params_id ,out_val) 
                                            
                                            local retval, parname = TrackFX_GetParamName( data[i].tr_ptr, fx_id, tcp_params_id ,'' )
                                            local retval, parform = TrackFX_GetFormattedParamValue( data[i].tr_ptr,fx_id, tcp_params_id ,'' )
                                            local retval, fxname = TrackFX_GetFXName(data[i].tr_ptr,fx_id,'')
                                            fxname = MPL_ReduceFXname(fxname).. ' / '
                                            if conf.obeyyallcontrols == 0 then fxname = '' end
                                            obj['fx_'..i..'tcp_val'].txt=fxname..parname..':'.. parform                              
                                            
                                            refresh.GUI_minor = true
                                          end
                                        end  ,
                            func_mouseover =  function()
                                                  local retval, parname = TrackFX_GetParamName( data[i].tr_ptr, fx_id, tcp_params_id ,'' )
                                                  local retval, parform = TrackFX_GetFormattedParamValue( data[i].tr_ptr, fx_id, tcp_params_id ,'' )
                                                  local retval, fxname = TrackFX_GetFXName(data[i].tr_ptr,fx_id,'')
                                                  fxname = MPL_ReduceFXname(fxname).. ' / '
                                                  if conf.obeyyallcontrols == 0 then fxname = '' end
                                                  obj['fx_'..i..'tcp_val'].txt=fxname..parname..':'.. parform   
                                                refresh.GUI_minor = true
                                              end  ,
                            onrelease_L2  = function()  
                                              obj['fx_'..i..'tcp_val'].txt= data[i].presetname
                                            end,
                            }  
        end
      end
    end             
    
    local xval = src_t.x  + obj.offs2 + obj.knob_w * tcp_params_id_int
    local w_val = gfx.w - xval - obj.scroll_w - obj.offs
    if w_val > 30 then
    
      obj['fx_'..i..'tcp_val'] = { clear = true,
                      x = xval,
                      y = src_t.y  +src_t.h  - obj.knob_area_h,
                      w = w_val,
                      h = obj.knob_h,
                      txt=  '',
                      show = true,
                      fontsz = obj.GUI_fontsz3,
                      a_frame = 0,
                      disable_blitback = true,
                      ignore_mouse = true,
                    }         
    end
           
  end
  ----------------------------------------------------------------
  function Obj_GenerateRack_Controls_name(conf, obj, data, refresh, mouse, data_ext, src_t, i)   
    -- FX name
      local name_x = src_t.x + obj.peak_w*2 + obj.offs2
      local txt = data[i].name
      obj['fx_name'..i] = { clear = true,
                        x = name_x,
                        y = src_t.y + obj.but_small_h + obj.offs*2,
                        w = gfx.w - name_x - obj.offs*2-obj.scroll_w,
                        h = obj.but_small_h,
                        disable_blitback = true,
                        --colfill_col = col_fill,
                        --colfill_a = 0.6,
                        txt=  '('..data[i].tr_id..') '..data[i].tr_name..' | '..MPL_ReduceFXname(txt),
                        aligh_txt = 1,
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0.4,
                        func = function() 
                        
                        end
                      }    
    -- preset prev
      --if data[i].presetname == '' then return end
      obj['fx_presmove_p'..i] = { clear = true,
                        x = name_x,
                        y = src_t.y + obj.but_small_h*2 + obj.offs*3,
                        w = obj.but_w,
                        h = obj.but_small_h,
                        --disable_blitback = true,
                        --colfill_col = col_fill,
                        --colfill_a = 0.6,
                        txt=  '<',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        func = function() 
                                  local ret, tr, id = VF_GetFXByGUID(data[i].GUID)
                                  if ret then
                                    TrackFX_NavigatePresets(tr, id, -1)
                                    refresh.data = true
                                    refresh.GUI_minor = true
                                  end
                                end,
                      }    
      obj['fx_presmove_n'..i] = { clear = true,
                        x = name_x+obj.but_w,
                        y = src_t.y + obj.but_small_h*2 + obj.offs*3,
                        w = obj.but_w,
                        h = obj.but_small_h,
                        --disable_blitback = true,
                        --colfill_col = col_fill,
                        --colfill_a = 0.6,
                        txt=  '>',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        func = function() 
                                  local ret, tr, id = VF_GetFXByGUID(data[i].GUID)
                                  if ret then
                                    TrackFX_NavigatePresets(tr, id, 1)
                                    refresh.data = true
                                    refresh.GUI_minor = true
                                  end
                                end,
                      }                       
    -- preset 
      local preset_w = 200
      local txt = data[i].presetname
      obj['fx_presname'..i] = { clear = true,
                        x = name_x+obj.but_w*2+obj.offs2,
                        y = src_t.y + obj.but_small_h*2 + obj.offs*3,
                        w = gfx.w - name_x - obj.offs*2-obj.scroll_w    -(obj.but_w*2+obj.offs2),
                        h = obj.but_small_h,
                        disable_blitback = true,
                        --colfill_col = col_fill,
                        --colfill_a = 0.6,
                        txt=  txt,
                        aligh_txt = 1,
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        ignore_mouse = true,
                      }  
                             
                            
  end  
