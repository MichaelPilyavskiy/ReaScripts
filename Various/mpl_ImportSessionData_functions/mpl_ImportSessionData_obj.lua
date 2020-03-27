-- @description ImportSessionData_obj
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex
  
  
  ---------------------------------------------------
  function OBJ_init(conf, obj, data, refresh, mouse)  
    -- globals
    obj.reapervrs = tonumber(GetAppVersion():match('[%d%.]+')) 
    obj.offs = 5 
    obj.grad_sz = 200 
    obj.scroll_val = 0
    obj.get_w = 60
     
    -- font
    obj.GUI_font = 'Calibri'
    obj.GUI_fontsz = VF_CalibrateFont(21)
    obj.GUI_fontsz2 = VF_CalibrateFont( 19)
    obj.GUI_fontsz3 = VF_CalibrateFont( 15)
    obj.GUI_fontsz_tooltip = VF_CalibrateFont( 13)
    
    obj.strat_x_ind = 7
    obj.strategy_itemh = 13
    
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
  ---------------------------------------------------
  function OBJ_Update(conf, obj, data, refresh, mouse, strategy) 
    for key in pairs(obj) do if type(obj[key]) == 'table' and obj[key].clear then obj[key] = {} end end  
    
    local min_w = 300
    local min_h = 200
    local reduced_view = gfx.h  <= min_h
    gfx.w  = math.max(min_w,gfx.w)
    gfx.h  = math.max(min_h,gfx.h)
    
    obj.menu_w = 20
    obj.menu_h = 40
    obj.bottom_line_h = 20
    obj.scroll_w = 20
    obj.trlistw = math.floor((gfx.w - obj.menu_w - obj.get_w)*0.6)
    obj.tr_listh = gfx.h-obj.menu_h-obj.bottom_line_h
    
    Obj_MenuMain  (conf, obj, data, refresh, mouse)
    Obj_TopLine(conf, obj, data, refresh, mouse)
    if data.tr_chunks then 
      Obj_Tracklist(conf, obj, data, refresh, mouse, strategy) 
      Obj_Scroll(conf, obj, data, refresh, mouse)
      Obj_Strategy(conf, obj, data, refresh, mouse, strategy)
    end
    for key in pairs(obj) do if type(obj[key]) == 'table' then  obj[key].context = key  end end    
  end
  -----------------------------------------------
  function Obj_MenuMain(conf, obj, data, refresh, mouse)
            obj.menu = { clear = true,
                        x = 0,
                        y = 0,
                        w = obj.menu_w-1,
                        h = obj.menu_h,
                        col = 'white',
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
      { str = 'Contact: MPL SoundCloud',
        func = function() Open_URL('http://soundcloud.com/mpl57') end  } ,     
      
        
                                                    
    }
    )
                                  refresh.conf = true 
                                  --refresh.GUI = true
                                  --refresh.GUI_onStart = true
                                  refresh.data = true
                                end}  
  end
  
  -----------------------------------------------
  function Obj_TopLine(conf, obj, data, refresh, mouse)
    
    local but_w = math.floor(gfx.w - obj.menu_w - obj.get_w)
    local txt = 'Browse for RPP session...'
    if conf.lastrppsession ~= '' then txt = conf.lastrppsession end
    obj.deffiel = { clear = true,
              x = obj.menu_w,
              y = 0,
              w = but_w-1,
              h = obj.menu_h,
              alpha_back = 0.2,
              txt= txt,
              show = true,
              fontsz = obj.GUI_fontsz2,
              a_frame = 0,
              func =  function() 
                        Data_DefineFile(conf, obj, data, refresh, mouse)
                        Run_Init(conf, obj, data, refresh, mouse) 
                      end}
    local col0 = 'red' if data.hasRPPdata == true then col0 = 'green' end
    obj.parse = { clear = true,
              x =gfx.w - obj.get_w-1,
              y = 0,
              w = obj.get_w,
              h = obj.menu_h,
              fillback = true,
              fillback_colstr = col0,
              fillback_a = 0.5,
              txt= 'Read\nRPP',
              aligh_txt = 16,
              show = true,
              fontsz = obj.GUI_fontsz2,
              func =  function() 
                        Data_ParseRPP(conf, obj, data, refresh, mouse) 
                      end}                       
    --[[local prname = ''
    if data.cur_project then prname = data.cur_project end
    obj.refrcuproject = { clear = true,
              x = obj.menu_w + but_w+obj.get_w,
              y = 0,
              w = but_w,
              h = obj.menu_h,
              alpha_back = 0.2,
              txt= '(click to refresh actual project in current tab)\n--> '..prname,
              aligh_txt = 16,
              show = true,
              fontsz = obj.GUI_fontsz2,
              a_frame = 0,
              func =  function() 
                        Data_CollectProjectTracks(conf, obj, data, refresh, mouse)
                        refresh.GUI = true
                      end}  ]]            
             
  end
  --------------------------------------------------- 
  function Obj_Scroll(conf, obj, data, refresh, mouse)
    local pat_scroll_h = obj.trlist.h -- obj.menu_h
    local scroll_handle_h = 50
        obj.scroll_pat = 
                      { clear = true,
                        x = 0,
                        y = obj.menu_h,
                        w = obj.scroll_w-1,
                        h = pat_scroll_h,
                        txt = '',
                        state = 1,
                        show = true,
                        is_but = true,
                        ignore_mouse = true,
                        alpha_back = 0.05,
                        fontsz = conf.GUI_padfontsz,--obj.GUI_fontsz2,  
                      }
        obj.scroll_pat_handle = 
                      { clear = true,
                        x = 0,
                        y = obj.menu_h + obj.scroll_val * (pat_scroll_h -scroll_handle_h)+2 ,
                        w = obj.scroll_w-1,
                        h = scroll_handle_h-1,
                        txt = '',
                        col = 'white',
                        show = true,
                        is_but = true,
                        alpha_back = 0.6,
                        a_frame = 0,
                        fontsz = conf.GUI_padfontsz,--obj.GUI_fontsz2, 
                      func =  function() 
                        mouse.context_latch_val = obj.scroll_val
                      end,
              func_LD2 = function () 
                          if not mouse.context_latch_val then return end 
                          local dragratio = 1
                          local out_val = lim(mouse.context_latch_val + (mouse.dy/(pat_scroll_h -obj.scroll_w))*dragratio, 0, 1)
                          if not out_val then return end
                          obj.scroll_val = out_val
                          refresh.GUI = true 
                        end,             
                         
                      }                      
  end  
  -----------------------------------------------
  function Obj_Tracklist(conf, obj, data, refresh, mouse, strategy)
    local tr_listx, tr_listy, tr_listw = obj.scroll_w  + 1, obj.menu_h+1, obj.trlistw-1
    -- h - obj.menu_h from  top and bottom
    local tr_h = 20
    local com_list_h = tr_h * (#data.tr_chunks-1)
    local y_shift = obj.scroll_val * com_list_h
    obj.trlist = { clear = true,
              x =tr_listx-1,--math.floor(gfx.w/2),
              y = tr_listy,
              w = tr_listw,
              h = obj.tr_listh,
              col = 'white',
              --colfill_col = col0,
              --colfill_a = 0.5,
              txt= '',
              aligh_txt = 16,
              show = true,
              fontsz = obj.GUI_fontsz2,
              ignore_mouse = true,
              a_frame = 0.1,
              alpha_back = 0,
              func =  function() end}    
              
    for i = 1, #data.tr_chunks do
      local tr_y = tr_listy - y_shift+ obj.offs + tr_h*(i-1)
      local r = 90
      local col0, tr_name = ColorToNative( r, r, r ), ' (untitled)'
      
      if data.tr_chunks[i] then
        if data.tr_chunks[i].tr_col then col0 = data.tr_chunks[i].tr_col end
        if data.tr_chunks[i].tr_name and data.tr_chunks[i].tr_name ~= '' then tr_name = data.tr_chunks[i].tr_name end
      end
      if tr_y > tr_listy and  tr_y + tr_h < tr_listy + obj.tr_listh then
        obj['trsrc'..i] = { clear = true,
              x =tr_listx,
              y = tr_y,
              w = tr_listw/2-1,
              h = tr_h-1,
              fillback = true,
              fillback_colint = col0,
              fillback_a = 0.9,
              txt= i..': '..tr_name,
              show = true,
              fontsz = obj.GUI_fontsz2, 
              ignore_mouse = true,
              func =  function() 
                                      
                      
                      end}     
      end     
    end 
    
    for i = 1, #data.tr_chunks do
      if data.tr_chunks[i] then
        local tr_y = tr_listy - y_shift+ obj.offs + tr_h*(i-1)
        if tr_y > tr_listy and  tr_y + tr_h < tr_listy + obj.tr_listh then
          local txt = '(none)'
          local tr_col, fillback
          if type(data.tr_chunks[i].dest) == 'string' and data.tr_chunks[i].dest ~= '' then
            ret, txt0, tr_col0 = Data_GetParamsFromGUID(data, data.tr_chunks[i].dest)
            if ret then
              txt, tr_col = txt0, tr_col0 
              fillback = true
            end
           elseif data.tr_chunks[i].dest == -1 then 
            txt, tr_col = 'New track at tracklist end', 0
          end
          obj['trdest'..i] = { clear = true,
                x =tr_listx + tr_listw/2,
                y = tr_y,
                w = tr_listw/2,
                h = tr_h-1,
                fillback = true,
                fillback_colint = tr_col,
                fillback_a = 0.9,
                alpha_back = 0.05,
                txt= txt,
                show = true,
                fontsz = obj.GUI_fontsz2,
                func =  function() 
                          Data_CollectProjectTracks(conf, obj, data, refresh, mouse)
                          local t = {
                            { str = 'none',
                              func =  function() 
                                        data.tr_chunks[i].dest = ''
                                      end
                            },
                            { str = 'New track at the end of tracklist|',
                              func =  function() 
                                        data.tr_chunks[i].dest = -1
                                      end
                            },                          
                          }
                          if data.cur_tracks then 
                            for i2 = 1, #data.cur_tracks do
                              t[#t+1] = 
                              { str =data.cur_tracks[i2].tr_name,
                                 func =  function() 
                                           data.tr_chunks[i].dest = data.cur_tracks[i2].GUID
                                          
                                         end
                               }
                            end
                          end
                          Menu(mouse, t) 
                          refresh.GUI = true             
                        end}     
        end
      end     
    end 
    obj.import_action = { clear = true,
              x = obj.menu_w + obj.trlistw,
              y = obj.menu_h+1,
              w = obj.get_w,
              h = gfx.h - obj.menu_h,
              fillback = true,
              fillback_colstr = 'red',
              fillback_a = 0.2,
              txt= 'Import\n>>',
              aligh_txt = 16,
              show = true,
              fontsz = obj.GUI_fontsz2,
              func =  function() 
                        Data_Import(conf, obj, data, refresh, mouse, strategy)  
                      end} 
  end
  -----------------------------------------------   
  function Obj_Strategy_GenerateTable(conf, obj, data, refresh, mouse, ref_strtUI, strategy) 
    local wstr = gfx.w - (obj.menu_w + obj.trlistw + obj.get_w) -2
    local x_str = obj.menu_w + obj.trlistw + obj.get_w + 1
    local y_str = obj.menu_h+1
    local name = 'str_tree'
    obj.strframe = { clear = true,
                      disable_blitback = true,
                        x = x_str,
                        y = y_str,
                        w = wstr,
                        h = obj.tr_listh,
                        col = 'white',
                        txt= '',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0.1,
                        ignoremouse = true
                        }   
    local y_offs = 10
    local x_offs = 10  
    for i = 1, #ref_strtUI do
      if ref_strtUI[i].show then
        local disable_blitback if not ref_strtUI[i].has_blit then disable_blitback = true end
        local col_str 
        if ref_strtUI[i].col_str then col_str = ref_strtUI[i].col_str end
        local txt_a,ignore_mouse
        if ref_strtUI[i].hidden then
          txt_a = 0.4
          --ignore_mouse = true
        end
        obj[name..i] =  { clear = true,
                        x = x_offs+x_str + ref_strtUI[i].level *obj.strat_x_ind ,
                        y =y_str + y_offs,
                        w = wstr - obj.offs - ref_strtUI[i].level *obj.strat_x_ind ,
                        h = obj.strategy_itemh,
                        col = col_str,
                        check = ref_strtUI[i].state,
                        check_state_cnt = ref_strtUI[i].state_cnt,
                        txt= ref_strtUI[i].name,
                        txt_a = txt_a,
                        ignore_mouse = ignore_mouse,
                        show = true,
                        fontsz = obj.GUI_fontsz3,
                        a_frame = 0,
                        aligh_txt = 1,
                        disable_blitback = disable_blitback,
                        func = function() 
                                if ref_strtUI[i].func then ref_strtUI[i].func() end
                                SaveStrategy(conf, strategy, 1, true)
                                refresh.GUI = true
                              end,
                        func_R = function()  
                                  if ref_strtUI[i].func_R then ref_strtUI[i].func_R() end
                                  SaveStrategy(conf, strategy, 1, true)
                                  refresh.GUI = true
                                end
                        } 
        y_offs = y_offs + obj.strategy_itemh
      end 
      
    end
    y_offs = y_offs + obj.strategy_itemh
    return y_offs
  end    
  -----------------------------------------------
  function Obj_Strategy(conf, obj, data, refresh, mouse, strategy)
    local act_strtUI = {  
                      
                          { name = 'RAW track data (chunk)',
                            state = strategy.comchunk==1,
                            hidden = strategy.comchunk==0,
                            show = true,
                            has_blit = false,
                            level = 0,
                            func =  function()
                                      strategy.comchunk = math.abs(1-strategy.comchunk)
                                    end,             
                          } ,  
                          { name = 'Copy FX chain',
                            state = strategy.fxchain&1==1,
                            show = true,
                            hidden = strategy.comchunk==1,
                            has_blit = false,
                            level = 0,
                            func =  function()
                                      strategy.comchunk = 0
                                      strategy.fxchain = BinaryToggle(strategy.fxchain, 0)
                                    end,             
                          } ,                            
                          { name = 'Track Properties',
                            state = strategy.trparams&1==1,
                            show = true,
                            hidden = strategy.comchunk==1,
                            has_blit = false,
                            level = 0,
                            func =  function()
                                      strategy.comchunk = 0
                                      strategy.trparams = BinaryToggle(strategy.trparams, 0)
                                    end,             
                          } , 
                          { name = 'Volume',
                            state = strategy.trparams&2==2,
                            show =  strategy.comchunk==0 and strategy.trparams&1==0 ,
                            hidden = strategy.comchunk==1,
                            has_blit = false,
                            level = 1,
                            func =  function()
                                      strategy.comchunk = 0
                                      strategy.trparams = BinaryToggle(strategy.trparams, 0, 0)
                                      strategy.trparams = BinaryToggle(strategy.trparams, 1)
                                    end,             
                          } , 
                          { name = 'Pan/Width/Panlaw/DualPan/Panmode',
                            state = strategy.trparams&4==4,
                            show = strategy.comchunk==0 and strategy.trparams&1==0,
                            hidden = strategy.comchunk==1,
                            has_blit = false,
                            level = 1,
                            func =  function()
                                      strategy.comchunk = 0
                                      strategy.trparams = BinaryToggle(strategy.trparams, 0, 0)
                                      strategy.trparams = BinaryToggle(strategy.trparams, 2)
                                    end,             
                          } ,                                                                               
                                                                            
                        }
    Obj_Strategy_GenerateTable(conf, obj, data, refresh, mouse, act_strtUI, strategy )  
  end  
