-- @description QuantizeTool_obj
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex
  
  
  ---------------------------------------------------
  function OBJ_init(obj)  
    -- globals
    obj.reapervrs = tonumber(GetAppVersion():match('[%d%.]+')) 
    obj.offs = 5 
    obj.grad_sz = 200 
    
    
    
    -- font
    obj.GUI_font = 'Calibri'
    obj.GUI_fontsz = 19  -- 
    obj.GUI_fontsz2 = 15 -- 
    obj.GUI_fontsz3 = 13-- 
    obj.GUI_fontsz_tooltip = 13
    if GetOS():find("OSX") then 
      obj.GUI_fontsz = obj.GUI_fontsz - 6 
      obj.GUI_fontsz2 = obj.GUI_fontsz2 - 5 
      obj.GUI_fontsz3 = obj.GUI_fontsz3 - 4
      obj.GUI_fontsz_tooltip = obj.GUI_fontsz_tooltip - 4
    end 
    
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
    
    gfx.h  = math.max(300,gfx.h)
    
    obj.menu_w = 15
    obj.tab_h = 20
    obj.tab_w = math.ceil(gfx.w/3)
    obj.slider_tab_h = math.floor(obj.tab_h*2)
    obj.strategy_w = gfx.w * 0.8
    obj.strategy_h = gfx.h-obj.tab_h-obj.offs-obj.slider_tab_h - obj.tab_h
    obj.strategy_itemh = 15
    obj.strat_x_ind = 10
    obj.strat_y_ind = 20
    obj.knob_area = 0.3
    
    Obj_MenuMain  (conf, obj, data, refresh, mouse, strategy)
    Obj_TabRef    (conf, obj, data, refresh, mouse, strategy)
    Obj_TabSrc    (conf, obj, data, refresh, mouse, strategy)
    Obj_TabAct    (conf, obj, data, refresh, mouse, strategy)
    Obj_TabExecute(conf, obj, data, refresh, mouse, strategy)
    
    for key in pairs(obj) do if type(obj[key]) == 'table' then 
      obj[key].context = key 
    end end    
  end
  -----------------------------------------------
  function Obj_TabRef(conf, obj, data, refresh, mouse, strategy)

                            

    obj.TabRef = { clear = true,
                        x = 0,
                        y = 0,
                        w = obj.tab_w,
                        h = obj.tab_h,
                        col = 'white',
                        is_selected = conf.activetab == 1,
                        txt= 'Reference',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        func =  function() 
                                  conf.activetab = 1
                                  refresh.GUI = true
                                  refresh.conf = true
                                end
                        } 
    if conf.activetab ~= 1 then return end
    
                        
    Obj_TabRef_Strategy(conf, obj, data, refresh, mouse, strategy)    
    local cnt = 0
    if data.ref then cnt = #data.ref end                
    obj.ref_showpos =  { clear = true,
                        x = obj.strategy_w + obj.offs*2,
                        y = obj.tab_h+obj.offs,
                        w = gfx.w - obj.strategy_w - obj.offs*3,
                        h = obj.strategy_h/2 - obj.offs,
                        col = 'green',
                        txt= 'Show\nreference\n('..cnt..')',
                        txt_col = 'green',
                        txt_a =1,
                        aligh_txt = 16,
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame =0,
                        func =  function() 
                                  Data_ShowPointsAsMarkers(conf, obj, data, refresh, mouse, strategy, data.ref, 'green_marker') 
                                end,
                        onrelease_L = function() 
                                  Data_ClearMarkerPoints(conf, obj, data, refresh, mouse, strategy) 
                                end,
                        } 
    obj.ref_catch =  { clear = true,
                        x = obj.strategy_w + obj.offs*2,
                        y = obj.tab_h+obj.offs +obj.strategy_h/2,
                        w = gfx.w - obj.strategy_w - obj.offs*3,
                        h = obj.strategy_h/2,
                        col = 'green',
                        txt= 'Catch\nreference',
                        txt_col = 'green',
                        txt_a =1,                        
                        aligh_txt = 16,
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame =0,
                        func =  function() 
                                  Data_ApplyStrategy_reference(conf, obj, data, refresh, mouse, strategy)
                                  refresh.GUI = true
                                end
                        }                         
                        
                        
                        
  end  
  ----------------------------------------------- 
  function Obj_TabSrc_Strategy(conf, obj, data, refresh, mouse, strategy) 
    local src_strtUI = {  { name = 'Positions',
                            state = strategy.src_positions,
                            show = true,
                            has_blit = true,
                            level = 0,
                            func =  function()
                                      strategy.src_positions = BinaryCheck(strategy.src_positions, 0)
                                      refresh.GUI = true
                                    end,                            
                          },
                            { name = 'Selected items',
                              state = strategy.src_selitems,
                              show = strategy.src_positions&1==1,
                              level = 1,
                            func =  function()
                                      strategy.src_selitems = BinaryCheck(strategy.src_selitems, 0)
                                      refresh.GUI = true
                                    end,                               
                            },      
                            ------------------------   
                          { name = 'Values',
                            state = strategy.src_values,
                            state_cnt = 2,
                            show = true,
                            has_blit = true,
                            level = 0,
                            func =  function()
                                      strategy.src_values = BinaryCheck(strategy.src_values, 0)
                                      refresh.GUI = true
                                    end,                       
                          }, 
                            { name = 'Items gain',
                              state = strategy.src_val_itemvol,
                              show = strategy.src_values&1==1,
                              level = 1,
                              func =  function()
                                      strategy.src_val_itemvol = BinaryCheck(strategy.src_val_itemvol, 0)
                                      refresh.GUI = true
                                    end                              
                            },                                                                           
                        }
    Obj_Strategy_GenerateTable(conf, obj, data, refresh, mouse, src_strtUI, 'src_strtUI_it', 2)  
  end
  ----------------------------------------------- 
  function Obj_TabRef_Strategy(conf, obj, data, refresh, mouse, strategy) 
    --[[local val_str
    if strategy.ref_values&2~=2 then val_str ='Attached to positions' else val_str ='Ordered' end]]
    local ref_strtUI = {  { name = 'Positions',
                            state = strategy.ref_positions,
                            show = true,
                            has_blit = true,
                            level = 0,
                            func =  function()
                                      strategy.ref_positions = BinaryCheck(strategy.ref_positions, 0)
                                      refresh.GUI = true
                                    end,                            
                          },
                            { name = 'Items',
                              state = strategy.ref_selitems,
                              show = strategy.ref_positions&1==1,
                              level = 1,
                            func =  function()
                                      if strategy.ref_selitems&1 ~= 1 then 
                                        strategy.ref_selitems = BinaryCheck(strategy.ref_selitems, 0, 0)
                                        strategy.ref_envpoints = BinaryCheck(strategy.ref_envpoints, 0, 1)                                        
                                      end
                                      refresh.GUI = true
                                    end,                               
                            },    
                            { name = 'Envelope points',
                              state = strategy.ref_envpoints,
                              show = strategy.ref_positions&1==1,
                              level = 1,
                            func =  function()
                                      if strategy.ref_envpoints&1 ~= 1 then 
                                        strategy.ref_envpoints = BinaryCheck(strategy.ref_envpoints, 0, 0)
                                        strategy.ref_selitems = BinaryCheck(strategy.ref_selitems, 0, 1)                                        
                                      end
                                      refresh.GUI = true
                                    end,                               
                            },                             
                              
                            ------------------------   
                          { name = 'Values',
                            state = strategy.ref_values,
                            state_cnt = 2,
                            show = true,
                            has_blit = true,
                            level = 0,
                            func =  function()
                                      strategy.ref_values = BinaryCheck(strategy.ref_values, 0)
                                      refresh.GUI = true
                                    end,
                            --[[func_R = function()
                                      Menu(mouse, {
                                                    {str = '#Values'},
                                                    {str = 'Attached to positions',
                                                    state = strategy.ref_values&2~=2,
                                                    func = function() strategy.ref_values = BinaryCheck(strategy.ref_values, 1, 1) end},
                                                    {str = 'Ordered',
                                                    state = strategy.ref_values&2==2,
                                                    func = function() strategy.ref_values = BinaryCheck(strategy.ref_values, 1, 0) end},
                                                  })
                                      refresh.GUI = true
                                      
                                    end ]]                                   
                          },                           
                            { name = 'Items gain',
                              state = strategy.ref_val_itemvol,
                              show = strategy.ref_values&1==1,
                              level = 1,
                              func =  function()
                                      if strategy.ref_val_itemvol&1 ~= 1 then 
                                        strategy.ref_val_itemvol = BinaryCheck(strategy.ref_val_itemvol, 0, 0)
                                        strategy.ref_val_envpoint = BinaryCheck(strategy.ref_val_envpoint, 0, 1)                                        
                                      end 
                                      refresh.GUI = true
                                    end                              
                            },  
                            { name = 'Envelope points values',
                              state = strategy.ref_val_envpoint,
                              show = strategy.ref_values&1==1,
                              level = 1,
                              func =  function()
                                      if strategy.ref_val_envpoint&1 ~= 1 then 
                                        strategy.ref_val_envpoint = BinaryCheck(strategy.ref_val_envpoint, 0, 0)
                                        strategy.ref_val_itemvol = BinaryCheck(strategy.ref_val_itemvol, 0, 1)                                        
                                      end                              
                                      refresh.GUI = true
                                    end                              
                            },                                                        
                                                         
   
                          ------------------------                                                 
                          { name = 'Pattern',
                            state = false,
                            show = true,
                            has_blit = true,
                            level = 0
                          }, 
                            ------------------------
                            { name = 'User groove',
                              state = false,
                              show = true,
                              level = 1
                            }, 
                            ------------------------  
                            { name = 'Project grid',
                              state = false,
                              show = true,
                              level = 1
                            },                                                                           
                        }
    Obj_Strategy_GenerateTable(conf, obj, data, refresh, mouse, ref_strtUI, 'ref_strtUI_it', 1)
  end
  -----------------------------------------------  
  function Obj_Strategy_GenerateTable(conf, obj, data, refresh, mouse, ref_strtUI, name, strategytype) 
    obj[name..'_frame'] = { clear = true,
                      disable_blitback = true,
                        x = obj.offs,
                        y = obj.tab_h+obj.offs,
                        w = obj.strategy_w,
                        h = obj.strategy_h,
                        col = 'white',
                        txt= '',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0.1,
                        ignoremouse = true
                        }   
    local y_offs = 0
    local x_offs = 0    
    for i = 1, #ref_strtUI do
      if ref_strtUI[i].show then
        local disable_blitback if not ref_strtUI[i].has_blit then disable_blitback = true end
        local col_str 
        if strategytype == 1 then col_str = 'green' 
          elseif strategytype == 2 then  col_str = 'blue' 
          elseif strategytype == 3 then  col_str = 'red' 
        end
        obj[name..i] =  { clear = true,
                        x = obj.offs*2 + ref_strtUI[i].level *obj.strat_x_ind ,
                        y = obj.tab_h + obj.offs*2 + y_offs,
                        w = obj.strategy_w - obj.offs*2 - ref_strtUI[i].level *obj.strat_x_ind ,
                        h = obj.strategy_itemh,
                        col = col_str,
                        check = ref_strtUI[i].state,
                        check_state_cnt = ref_strtUI[i].state_cnt,
                        txt= ref_strtUI[i].name,
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        aligh_txt = 1,
                        disable_blitback = disable_blitback,
                        func = function() 
                                if ref_strtUI[i].func then ref_strtUI[i].func() end
                                if conf.app_on_strategy_change == 1 and strategytype == 1 then Data_ApplyStrategy_reference(conf, obj, data, refresh, mouse, strategy) end
                                if conf.app_on_strategy_change == 1 and strategytype == 2 then Data_ApplyStrategy_source(conf, obj, data, refresh, mouse, strategy) end
                                obj.is_strategy_dirty = true
                                SaveStrategy(conf, strategy, 1, true)
                              end,
                        func_R = function()  
                                  if ref_strtUI[i].func_R then ref_strtUI[i].func_R() end
                                  if conf.app_on_strategy_change == 1 and strategytype == 1 then Data_ApplyStrategy_reference(conf, obj, data, refresh, mouse, strategy) end
                                  if conf.app_on_strategy_change == 1 and strategytype == 2 then Data_ApplyStrategy_source(conf, obj, data, refresh, mouse, strategy) end
                                  obj.is_strategy_dirty = true
                                  SaveStrategy(conf, strategy, 1, true)
                                end
                        } 
        y_offs = y_offs + obj.strategy_itemh
      end 
    end
  end    
  -----------------------------------------------
  function Obj_TabSrc(conf, obj, data, refresh, mouse, strategy)
    obj.TabSrc = { clear = true,
                        x = obj.tab_w,
                        y = 0,
                        w = obj.tab_w,
                        h = obj.tab_h,
                        col = 'white',
                        is_selected = conf.activetab == 2,
                        txt= 'Source to modify',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        func =  function()
                                  conf.activetab = 2 
                                  refresh.conf = true
                                  refresh.GUI = true  
                                end
                        }  
    if conf.activetab ~= 2 then return end

    Obj_TabSrc_Strategy(conf, obj, data, refresh, mouse, strategy)   
    local cnt = 0
    if data.src then cnt = #data.src end
    obj.src_showpos =  { clear = true,
                        x = obj.strategy_w + obj.offs*2,
                        y = obj.tab_h+obj.offs,
                        w = gfx.w - obj.strategy_w - obj.offs*3,
                        h = obj.strategy_h/2 - obj.offs,
                        col = 'blue',
                        txt= 'Show\nsource\n('..cnt..')',
                        txt_col = 'blue',
                        txt_a =1,                        
                        aligh_txt = 16,
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame =0,
                        func =  function() 
                                  Data_ShowPointsAsMarkers(conf, obj, data, refresh, mouse, strategy, data.src, 'blue_marker') 
                                end,
                        onrelease_L = function() 
                                  Data_ClearMarkerPoints(conf, obj, data, refresh, mouse, strategy) 
                                end,
                        } 
    obj.src_catch =  { clear = true,
                        x = obj.strategy_w + obj.offs*2,
                        y = obj.tab_h+obj.offs +obj.strategy_h/2,
                        w = gfx.w - obj.strategy_w - obj.offs*3,
                        h = obj.strategy_h/2,
                        col = 'blue',
                        txt= 'Catch\nsource',
                        txt_col = 'blue',
                        txt_a =1,                        
                        aligh_txt = 16,
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame =0,
                        func =  function() 
                                  Data_ApplyStrategy_source(conf, obj, data, refresh, mouse, strategy)
                                  refresh.GUI = true
                                end
                        }                         
                          
  end    
  -----------------------------------------------
  function Obj_TabAct(conf, obj, data, refresh, mouse, strategy) 
            obj.TabAct = { clear = true,
                        x = obj.tab_w*2,
                        y = 0,
                        w = obj.tab_w,
                        h = obj.tab_h,
                        col = 'white',
                        is_selected = conf.activetab == 3,
                        txt= 'Action',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        func =  function() 
                                  conf.activetab = 3 
                                  refresh.GUI = true 
                                  refresh.conf = true
                                end
                        } 
    if conf.activetab ~= 3 then return end 
    
    local h_buts = math.floor(obj.strategy_h/5)
    local h_butsspace = math.floor(obj.offs/2)
    -- show/catch ref
    local cnt = 0
    if data.ref then cnt = #data.ref end
    obj.ref_catch =  { clear = true,
                        x = obj.strategy_w + obj.offs*2,
                        y = obj.tab_h +obj.offs ,
                        w = gfx.w - obj.strategy_w - obj.offs*3,
                        h = h_buts - h_butsspace,
                        col = 'green',
                        txt= 'Catch\nreference',
                        txt_col = 'green',
                        txt_a =1,
                        aligh_txt = 16,
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame =0,
                        func =  function() 
                                  Data_ApplyStrategy_reference(conf, obj, data, refresh, mouse, strategy)
                                  refresh.GUI = true
                                end
                        }                    
    obj.ref_showpos =  { clear = true,
                        x = obj.strategy_w + obj.offs*2,
                        y = obj.tab_h+obj.offs+h_buts,
                        w = gfx.w - obj.strategy_w - obj.offs*3,
                        h = h_buts - h_butsspace,
                        col = 'green',
                        txt= 'Show\nreference\n('..cnt..')',
                        txt_col = 'green',
                        txt_a =1,
                        aligh_txt = 16,
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame =0,
                        func =  function() 
                                  Data_ShowPointsAsMarkers(conf, obj, data, refresh, mouse, strategy, data.ref, 'green_marker') 
                                end,
                        onrelease_L = function() 
                                  Data_ClearMarkerPoints(conf, obj, data, refresh, mouse, strategy) 
                                end,
                        } 
   
    -- show/catch src                          
    local cnt = 0
    if data.src then cnt = #data.src end
   
    obj.src_catch =  { clear = true,
                        x = obj.strategy_w + obj.offs*2,
                        y = obj.tab_h+obj.offs +h_buts*2,
                        w = gfx.w - obj.strategy_w - obj.offs*3,
                        h = h_buts  - h_butsspace,
                        col = 'blue',
                        txt= 'Catch\nsource',
                        txt_col = 'blue',
                        txt_a =1,                          
                        aligh_txt = 16,
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame =0,
                        func =  function() 
                                  Data_ApplyStrategy_source(conf, obj, data, refresh, mouse, strategy)
                                  refresh.GUI = true
                                end
                        }    
    obj.src_showpos =  { clear = true,
                        x = obj.strategy_w + obj.offs*2,
                        y = obj.tab_h+obj.offs+h_buts*3,
                        w = gfx.w - obj.strategy_w - obj.offs*3,
                        h = h_buts - h_butsspace,
                        col = 'blue',
                        txt= 'Show\nsource\n('..cnt..')',
                        txt_col = 'blue',
                        txt_a =1,                        
                        aligh_txt = 16,
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame =0,
                        func =  function() 
                                  Data_ShowPointsAsMarkers(conf, obj, data, refresh, mouse, strategy, data.src, 'blue_marker') 
                                end,
                        onrelease_L = function() 
                                  Data_ClearMarkerPoints(conf, obj, data, refresh, mouse, strategy) 
                                end,
                        }                          
    obj.act_calc =  { clear = true,
                        x = obj.strategy_w + obj.offs*2,
                        y = obj.tab_h+obj.offs +h_buts*4,
                        w = gfx.w - obj.strategy_w - obj.offs*3,
                        h = h_buts,
                        col = 'blue',
                        txt= 'Calculate\naction\noutput',
                        txt_col = 'red',
                        txt_a =1,                          
                        aligh_txt = 16,
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame =0,
                        func =  function() 
                                  Data_ApplyStrategy_action(conf, obj, data, refresh, mouse, strategy)  
                                  refresh.GUI = true
                                end
                        }                                              
                        
     Obj_TabAct_Strategy(conf, obj, data, refresh, mouse, strategy)                      
  end 
  -----------------------------------------------
  function Obj_TabAct_Strategy(conf, obj, data, refresh, mouse, strategy)
    local act_strtUI = {  
                        { name = 'Type',
                            show = true,
                            has_blit = true,
                            level = 0             
                        },
                          { name = 'Position-based aligning',
                            state = strategy.act_action==1,
                            show = true,
                            has_blit = false,
                            level = 1,
                            func =  function()
                                      strategy.act_action = 1
                                      refresh.GUI = true
                                    end,             
                          } ,
                        { name = 'Initialization',
                            show = true,
                            has_blit = true,
                            level = 0             
                        }, 
                          { name = 'Catch reference on init',
                            state = strategy.act_initcatchref,
                            show = true,
                            has_blit = false,
                            level = 1,
                            func =  function()
                                      strategy.act_initcatchref = BinaryCheck(strategy.act_initcatchref, 0)
                                      refresh.GUI = true
                                    end,             
                          } ,   
                          { name = 'Catch source on init',
                            state = strategy.act_initcatchsrc,
                            show = true,
                            has_blit = false,
                            level = 1,
                            func =  function()
                                      strategy.act_initcatchsrc = BinaryCheck(strategy.act_initcatchsrc, 0)
                                      refresh.GUI = true
                                    end,             
                          } ,  
                          { name = 'Calculate action output on init',
                            state = strategy.act_initact&1==1,
                            show = true,
                            has_blit = false,
                            level = 1,
                            func =  function()
                                      strategy.act_initact = BinaryCheck(strategy.act_initact, 0)
                                      refresh.GUI = true
                                    end,             
                          } ,                            
                        { name = 'Options',
                            show = true,
                            has_blit = true,
                            level = 0             
                        },                           
                          { name = 'Sort positions before taking values',
                            state = strategy.ref_values&2==2,
                            show = true,
                            has_blit = false,
                            level = 1,
                            func =  function()
                                      strategy.ref_values = BinaryCheck(strategy.ref_values, 1)
                                      refresh.GUI = true
                                    end,             
                          } ,                                                                                      
                        }
    Obj_Strategy_GenerateTable(conf, obj, data, refresh, mouse, act_strtUI, 'act_strtUI_it', 3)  
  end  
  -----------------------------------------------
  function Obj_TabExecute_Align(conf, obj, data, refresh, mouse, strategy)  
    local com_exe_w = gfx.w - obj.menu_w - 1
    local knob_cnt = 2
    local knob_w = math.floor((com_exe_w * obj.knob_area)/knob_cnt)
    obj.exe_val1 = { clear = true,
                        is_knob = true,
                        x =   obj.menu_w + 1,
                        y = gfx.h - obj.slider_tab_h,
                        w = knob_w,
                        h = obj.slider_tab_h,
                        col = 'white',
                        txt= '',
                        val = strategy.exe_val1,
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        func =  function() 
                                  if conf.app_on_slider_click == 1 then Data_ApplyStrategy_action(conf, obj, data, refresh, mouse, strategy) end
                                  mouse.context_latch_val = strategy.exe_val1
                                end,
                        func_LD2 = function()
                                      if mouse.context_latch_val then 
                                        strategy.exe_val1 = lim(mouse.context_latch_val + mouse.dx*0.001 - mouse.dy*0.01)
                                        obj.exe_val1.val = strategy.exe_val1
                                        obj.knob_txt.txt = 'Align position '..FormatPercent(strategy.exe_val1)
                                        refresh.GUI_minor = true
                                        Data_Execute(conf, obj, data, refresh, mouse, strategy)
                                      end
                                    end  ,
                        func_mouseover =  function()
                                      obj.knob_txt.txt = 'Align position '..FormatPercent(strategy.exe_val1)
                                      refresh.GUI_minor = true
                                    end   
                        } 
    obj.exe_val2 = { clear = true,
                        is_knob = true,
                        x =   obj.menu_w + 1+knob_w,
                        y = gfx.h - obj.slider_tab_h,
                        w = knob_w-1,
                        h = obj.slider_tab_h,
                        col = 'white',
                        state = fale,
                        txt= '',
                        val = strategy.exe_val2,
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        func =  function() 
                                  if conf.app_on_slider_click == 1 then Data_ApplyStrategy_action(conf, obj, data, refresh, mouse, strategy) end
                                  mouse.context_latch_val = strategy.exe_val2
                                end,
                        func_LD2 = function()
                                    if mouse.context_latch_val then 
                                      strategy.exe_val2 = lim(mouse.context_latch_val + mouse.dx*0.001 - mouse.dy*0.01)
                                      obj.exe_val2.val = strategy.exe_val2
                                      obj.knob_txt.txt = 'Align value '..FormatPercent(strategy.exe_val2)
                                      refresh.GUI_minor = true
                                      Data_Execute(conf, obj, data, refresh, mouse, strategy)
                                    end
                                end ,
                        func_mouseover =  function()
                                      obj.knob_txt.txt = 'Align value '..FormatPercent(strategy.exe_val2)
                                      refresh.GUI_minor = true
                                    end                                        
                        }                           
      obj.knob_txt = { clear = true,
                        x =   obj.menu_w + 1 + com_exe_w * obj.knob_area,
                        y = gfx.h - obj.slider_tab_h,
                        w = com_exe_w - com_exe_w * obj.knob_area,
                        h = obj.slider_tab_h,
                        col = 'white',
                        txt= '',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,}                      
  end
  -----------------------------------------------
  function Obj_TabExecute(conf, obj, data, refresh, mouse, strategy)
    if strategy.act_action == 1 then Obj_TabExecute_Align(conf, obj, data, refresh, mouse, strategy) end

                         
      local name = strategy.name
      if obj.is_strategy_dirty==true then name = name..'*' end
      obj.TabExe_stratname = { clear = true,
                        disable_blitback = true,
                        x =  0,
                        y = gfx.h -obj.slider_tab_h - obj.tab_h ,
                        w = gfx.w,
                        h = obj.tab_h ,
                        col = 'white',
                        txt= name,
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        
                        func =  function() 
                                  local t = {  
                                   { str = 'Rename strategy|',
                                            func = function() 
                                                      local ret, str_input = GetUserInputs(conf.mb_title, 1, 'Rename strategy,extrawidth=200' , strategy.name)
                                                      if ret then 
                                                        strategy.name = str_input
                                                        refresh.GUI = true
                                                      end
                                                    end
                                          },                                  
                                   { str = 'Load default strategy',
                                            func = function() 
                                                      LoadStrategy_Default(strategy)
                                                      refresh.GUI = true
                                                    end
                                          },
                                          { str = 'Load strategy from file',
                                            func = function() 
                                                      local retval, qtstr_file = GetUserFileNameForRead('', 'Load strategy from file', 'qtstr' )
                                                      LoadStrategy_Parse(strategy, qtstr_file)
                                                      refresh.GUI = true
                                                    end
                                          } ,    
                                          { str = 'Save strategy to file',
                                            func = function() SaveStrategy(conf, strategy, 1 ) end
                                          }   ,                                        
                                          { str = 'Save strategy to file and action list',
                                            func = function() SaveStrategy(conf, strategy, 2) end
                                          }  ,
                                          { str = 'Open strategy path|',
                                            func = function() 
                                                    local strat_fp = '"'..obj.script_path .. 'mpl_QuantizeTool_Strategies\\"'  
                                                    Open_URL(strat_fp) 
                                                  end
                                          }  ,
                                          { str = '#Strategy list'}  ,                                                                                                                            
                                                                              
                                        }
                                  for i = 1, 100 do
                                    local fp = EnumerateFiles( obj.script_path .. 'mpl_QuantizeTool_Strategies/', i-1 )
                                    if not fp or fp == '' then break end
                                    if fp:match('%.qtstr') and not fp:match('default') and not fp:match('last saved')then
                                      t[#t+1] = { str = fp:gsub('.qtstr', ''),
                                                  func =  function() 
                                                            LoadStrategy_Parse(strategy, obj.script_path .. 'mpl_QuantizeTool_Strategies/'..fp)
                                                            refresh.GUI = true
                                                          end
                                                }
                                    end
                                  end      
                                  
                                  Menu(mouse, t)
--                                  
                                end
                        }                           
                        
                        
  end 
  -----------------------------------------------   
  function FormatPercent(val) 
    if not val then return end
    return math_q_dec(val*100, 2)..'%'
  end
  -----------------------------------------------
  function Obj_MenuMain(conf, obj, data, refresh, mouse)
            obj.menu = { clear = true,
                        x = 0,
                        y = gfx.h - obj.slider_tab_h,
                        w = obj.menu_w,
                        h = obj.slider_tab_h,
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
      { str = '|>Donate / Links / Info'},
      { str = 'Donate to MPL',
        func = function() Open_URL('http://www.paypal.me/donate2mpl') end }  ,
      { str = 'Cockos Forum thread|',
        func = function() Open_URL('http://forum.cockos.com/showthread.php?t=165672') end  } , 

      { str = 'MPL on VK',
        func = function() Open_URL('http://vk.com/mpl57') end  } ,     
      { str = 'MPL on SoundCloud|<|',
        func = function() Open_URL('http://soundcloud.com/mpl57') end  } ,     
        
      { str = '#Options'},    
      { str = 'Apply ref/src strategy on parameter change|',
        func = function() 
                conf.app_on_strategy_change = math.abs(1-conf.app_on_strategy_change) 
              end,
        state = conf.app_on_strategy_change == 1}, 
      
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
