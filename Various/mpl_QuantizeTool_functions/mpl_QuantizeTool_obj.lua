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
    
    obj.strategy_frame = 0
    
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
    obj.grid_area = 10
    
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
    local ref_showpos_txt =  'Show\npattern'
    local ref_showpos_h = obj.strategy_h/2
    if strategy.ref_pattern&1 ==1 then ref_showpos_h = (obj.strategy_h - obj.pat_h-obj.offs) end
      
    local cnt = 0
    if data.ref and strategy.ref_pattern&1 ~=1  then ref_showpos_txt = 'Show\nreference\n('..#data.ref..')'  end                
    obj.ref_showpos =  { clear = true,
                        x = obj.strategy_w + obj.offs,
                        y = obj.tab_h+obj.offs,
                        w = gfx.w - obj.strategy_w - obj.offs*2,
                        h = ref_showpos_h,
                        col = 'green',
                        txt= ref_showpos_txt,
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
    if strategy.ref_pattern&1 ~=1 then
      obj.ref_catch =  { clear = true,
                        x = obj.strategy_w + obj.offs,
                        y = obj.tab_h+obj.offs +ref_showpos_h,
                        w = gfx.w - obj.strategy_w - obj.offs*2,
                        h = ref_showpos_h,
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
    local ref_strtUI = {  { name = 'Positions',
                            state = strategy.ref_positions,
                            show = true,
                            has_blit = true,
                            level = 0,
                            func =  function()
                                      if strategy.ref_positions&1 ~= 1 then 
                                        strategy.ref_pattern = BinaryCheck(strategy.ref_pattern, 0, 1)
                                        strategy.ref_positions = BinaryCheck(strategy.ref_positions, 0, 0)
                                       else
                                        strategy.ref_positions = BinaryCheck(strategy.ref_positions, 0, 1)                       
                                      end 
                                      refresh.GUI = true
                                    end,                            
                          },
                            { name = 'Items',
                              state = strategy.ref_selitems,
                              show = strategy.act_action&1==1 and strategy.ref_pattern&1~=1,
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
                              show = strategy.act_action&1==1 and strategy.ref_pattern&1~=1 ,
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
                            --state_cnt = 2,
                            show = true,
                            has_blit = true,
                            level = 0,
                            func =  function()
                                      if strategy.ref_values&1 ~= 1 then 
                                        strategy.ref_pattern = BinaryCheck(strategy.ref_pattern, 0, 1)
                                        strategy.ref_values = BinaryCheck(strategy.ref_values, 0, 0)
                                       else
                                        strategy.ref_values = BinaryCheck(strategy.ref_values, 0, 1)                               
                                      end 
                                      refresh.GUI = true
                                    end,                                  
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
                            state = strategy.ref_pattern,
                            show = true,
                            has_blit = true,
                            level = 0,
                              func =  function()
                                      if strategy.ref_pattern&1 ~= 1 then 
                                        strategy.ref_pattern = BinaryCheck(strategy.ref_pattern, 0, 0)
                                        strategy.ref_positions = BinaryCheck(strategy.ref_positions, 0, 1)
                                        strategy.ref_values = BinaryCheck(strategy.ref_values, 0, 1)
                                       else
                                        strategy.ref_pattern = BinaryCheck(strategy.ref_pattern, 0, 1) 
                                        strategy.ref_positions = BinaryCheck(strategy.ref_positions, 0, 0)
                                        strategy.ref_values = BinaryCheck(strategy.ref_values, 0, 0)                               
                                      end 
                                      refresh.GUI = true
                                    end                             
                          }, 
                          
  
                            { name = 'Groove name: '..strategy.ref_pattern_name,
                              show = strategy.ref_pattern&1 == 1,
                              prevent_app = true,
                              level = 1,
                            },
                            { name = '',
                              show = strategy.ref_pattern&1 == 1,
                              -- prevent_app = true,
                              level = 2,              
                              follow_obj = {
                                              { clear = true,
                                                w = obj.strategy_itemh*3,
                                                col = 'white',
                                                txt= '< prev',
                                                show = true,
                                                fontsz = obj.GUI_fontsz2,
                                                func = function()
                                                          local prev_fp = Data_GetListedFile(GetResourcePath()..'/Grooves/', strategy.ref_pattern_name..'.rgt', -1)
                                                          
                                                          if prev_fp then 
                                                            local f,content = io.open(GetResourcePath()..'/Grooves/'..prev_fp, 'r')
                                                            if f then 
                                                              content = f:read('a')
                                                              f:close()
                                                            end
                                                            if content then
                                                              data.ref_pat = {}
                                                              Data_PatternParseRGT(data, strategy, content, true)
                                                              strategy.ref_pattern_name = prev_fp:gsub('%.rgt', '')
                                                              SaveStrategy(conf, strategy, 1, true)
                                                              refresh.GUI = true
                                                            end
                                                          end
                                                       end
                                                },
                                              { clear = true,
                                                w = obj.strategy_itemh*3,
                                                col = 'white',
                                                txt= 'next >',
                                                show = true,
                                                fontsz = obj.GUI_fontsz2,
                                                func = function()
                                                          local next_fp = Data_GetListedFile(GetResourcePath()..'/Grooves/', strategy.ref_pattern_name..'.rgt', 1)
                                                          
                                                          if next_fp then 
                                                            local f,content = io.open(GetResourcePath()..'/Grooves/'..next_fp, 'r')
                                                            if f then 
                                                              content = f:read('a')
                                                              f:close()
                                                            end
                                                            if content then
                                                              data.ref_pat = {}
                                                              Data_PatternParseRGT(data, strategy, content, true)
                                                              strategy.ref_pattern_name = next_fp:gsub('%.rgt', '')
                                                              SaveStrategy(conf, strategy, 1, true)
                                                              refresh.GUI = true
                                                            end
                                                          end
                                                       end
                                                },   
                                                
                                              { clear = true,
                                                w = obj.strategy_itemh*4,
                                                col = 'white',
                                                txt= 'rename',
                                                show = true,
                                                fontsz = obj.GUI_fontsz2,
                                                func = function()
                                                          local ret, str_input = GetUserInputs(conf.mb_title, 1, 'Rename groove,extrawidth=200' , strategy.ref_pattern_name)
                                                          if ret then 
                                                            strategy.ref_pattern_name = str_input
                                                            refresh.GUI = true
                                                          end
                                                       end
                                                }, 
                                                
                                         { clear = true,
                                                w = obj.strategy_itemh*4,
                                                col = 'white',
                                                txt= 'save',
                                                show = true,
                                                fontsz = obj.GUI_fontsz2,
                                                func = function()
                                                          Data_ExportPattern(conf, obj, data, refresh, mouse, strategy, false)
                                                       end
                                                },                                                                                                                                                             
                                            },
                            },                         
                            { name = 'Length (beats): '..strategy.ref_pattern_len,
                              prevent_app = true,
                              show = strategy.ref_pattern&1 == 1,
                              level = 1,
                              follow_obj = {
                                              { clear = true,
                                                w = obj.strategy_itemh,
                                                col = 'white',
                                                txt= '-',
                                                show = true,
                                                fontsz = obj.GUI_fontsz2,
                                                func = function()
                                                          strategy.ref_pattern_len = lim(strategy.ref_pattern_len -1, 2, 16)
                                                          SaveStrategy(conf, strategy, 1, true)
                                                          refresh.GUI = true
                                                       end
                                                },
                                              { clear = true,
                                                w = obj.strategy_itemh,
                                                col = 'white',
                                                txt= '+',
                                                show = true,
                                                fontsz = obj.GUI_fontsz2,
                                                func = function()
                                                          strategy.ref_pattern_len = lim(strategy.ref_pattern_len +1, 2, 16)
                                                          SaveStrategy(conf, strategy, 1, true)
                                                          refresh.GUI = true
                                                       end
                                                }                                                                                               
                                            },
                            },                                          
                        }
    local y_offs = Obj_Strategy_GenerateTable(conf, obj, data, refresh, mouse, ref_strtUI, 'ref_strtUI_it', 1)
    if strategy.ref_pattern&1==1 then 
      obj.pat_x = obj.offs
      obj.pat_y = obj.tab_h + y_offs+obj.offs*2
      obj.pat_w = gfx.w-obj.offs*2--obj.strategy_w-
      obj.pat_h =  obj.strategy_h - y_offs-obj.offs
      Obj_TabRef_Pattern(conf, obj, data, refresh, mouse, strategy) 
    end
  end
  -----------------------------------------------
  function Data_GetListedFile(path, fname_check, position)
    -- get files list
     files = {}
    local i = 0
    repeat
    local file = reaper.EnumerateFiles( path, i )
    if file then
      files[#files+1] = file
    end
    i = i+1
    until file == nil
    
  -- search file list
    for i = 1, #files do
      --if files[i]:gsub('%%',''):lower():match(literalize(fname_check:lower():gsub('%%',''))) then 
      local ref_file = deliteralize(files[i]:lower())
      local test_file = deliteralize(fname_check:lower())
      if ref_file:match(test_file) then 
        if position == -1 then -- prev
          if i ==1 then return files[#files] else return files[i-1] end
         elseif position == 1 then -- next
          if i ==#files then return files[1] else return files[i+1] end
        end
      end
    end
    return files[1]
  end
  -----------------------------------------------
  function Obj_TabRef_Pattern(conf, obj, data, refresh, mouse, strategy)  
  
    obj.pat_workarea = { clear = true,
                        disable_blitback = true,
                        --alpha_back = 0.05,
                        x = obj.pat_x,
                        y = obj.pat_y,
                        w = obj.pat_w,
                        h = obj.pat_h - obj.grid_area,
                        col = 'white',
                        txt= '',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0.05,
                        func = function()
                                -- get XY
                                  local X = (mouse.x - obj.pat_workarea.x) / obj.pat_workarea.w
                                  local Y = 1-(mouse.y - obj.pat_workarea.y) / obj.pat_workarea.h
                                -- convert to pattern values
                                  local beat_pos = strategy.ref_pattern_len * X
                                  local val = Y
                                -- add to pattern table  
                                  if not data.ref_pat then data.ref_pat = {} end
                                  data.ref_pat  [#data.ref_pat + 1] = { pos = math_q_dec( beat_pos, 6),
                                                                        val = math_q_dec( val, 6) }
                                -- sort pattern table                         
                                  local t_sorted = {}
                                  for _, key in ipairs(getKeysSortedByValue(data.ref_pat, function(a, b) return a < b end, 'pos')) do t_sorted[#t_sorted+1] = data.ref_pat[key]  end
                                  data.ref_pat = t_sorted
                                  refresh.GUI_minor = true
                                  Data_ExportPattern(conf, obj, data, refresh, mouse, strategy, true)
                                end,
                        func_RD = function()
                                    local X = (mouse.x - obj.pat_workarea.x) / obj.pat_workarea.w
                                    local beat_pos = strategy.ref_pattern_len * X
                                    
                                    for i = #data.ref_pat, 1, -1 do
                                      if math.abs(data.ref_pat[i].pos - beat_pos) < 0.005*strategy.ref_pattern_len then 
                                        table.remove(data.ref_pat, i) 
                                        
                                      end
                                    end
                                    refresh.GUI_minor = true
                                    Data_ExportPattern(conf, obj, data, refresh, mouse, strategy, true)
                                end
                        }       
                      
  end  
  -----------------------------------------------   
  function Obj_Strategy_GenerateTable(conf, obj, data, refresh, mouse, ref_strtUI, name, strategytype) 
    obj[name..'_frame'] = { clear = true,
                      disable_blitback = true,
                        x = 0,obj.offs,
                        y = obj.tab_h,--+obj.offs,
                        w = obj.strategy_w,
                        h = obj.strategy_h,
                        col = 'white',
                        txt= '',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = obj.strategy_frame,
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
                        x = obj.offs + ref_strtUI[i].level *obj.strat_x_ind ,
                        y = obj.tab_h + obj.offs + y_offs,
                        w = obj.strategy_w - obj.offs - ref_strtUI[i].level *obj.strat_x_ind ,
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
                                if conf.app_on_strategy_change == 1 and strategytype == 1 and not ref_strtUI[i].prevent_app then Data_ApplyStrategy_reference(conf, obj, data, refresh, mouse, strategy) end
                                if conf.app_on_strategy_change == 1 and strategytype == 2 and not ref_strtUI[i].prevent_app then Data_ApplyStrategy_source(conf, obj, data, refresh, mouse, strategy) end
                                obj.is_strategy_dirty = true
                                SaveStrategy(conf, strategy, 1, true)
                              end,
                        func_R = function()  
                                  if ref_strtUI[i].func_R then ref_strtUI[i].func_R() end
                                  if conf.app_on_strategy_change == 1 and strategytype == 1 and not ref_strtUI[i].prevent_app then Data_ApplyStrategy_reference(conf, obj, data, refresh, mouse, strategy) end
                                  if conf.app_on_strategy_change == 1 and strategytype == 2 and not ref_strtUI[i].prevent_app then Data_ApplyStrategy_source(conf, obj, data, refresh, mouse, strategy) end
                                  obj.is_strategy_dirty = true
                                  SaveStrategy(conf, strategy, 1, true)
                                end
                        } 
        if ref_strtUI[i].follow_obj then
          local y_off_followobj_offs = 2
          local last_it_w = obj.strategy_itemh
          for i_obj =1, #ref_strtUI[i].follow_obj do
            gfx.setfont(1, obj.GUI_font, obj[name..i].fontsz )
            local str_len = gfx.measurestr(obj[name..i].txt)
            obj[name..i..'_folobj_'..i_obj] = CopyTable(ref_strtUI[i].follow_obj[i_obj])
            obj[name..i..'_folobj_'..i_obj].x = obj.offs + ref_strtUI[i].level *obj.strat_x_ind    + str_len  + last_it_w
            obj[name..i..'_folobj_'..i_obj].y = obj.tab_h + obj.offs + y_offs +1
            obj[name..i..'_folobj_'..i_obj].h = obj.strategy_itemh - 1
            last_it_w = last_it_w + obj[name..i..'_folobj_'..i_obj].w + 1
          end
        end
        y_offs = y_offs + obj.strategy_itemh
      end 
    end
    return y_offs
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
                        x = obj.strategy_w + obj.offs,
                        y = obj.tab_h+obj.offs,
                        w = gfx.w - obj.strategy_w - obj.offs*2,
                        h = obj.strategy_h/2 ,
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
                        x = obj.strategy_w + obj.offs,
                        y = obj.tab_h+obj.offs +obj.strategy_h/2,
                        w = gfx.w - obj.strategy_w - obj.offs*2,
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
    local x_offs = obj.strategy_w + obj.offs
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
                        x = x_offs,
                        y = obj.tab_h +obj.offs ,
                        w = gfx.w - x_offs - obj.offs,
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
                        x = x_offs,
                        y = obj.tab_h+obj.offs+h_buts,
                        w = gfx.w - x_offs - obj.offs,
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
                        x = x_offs,
                        y = obj.tab_h+obj.offs +h_buts*2,
                        w = gfx.w - x_offs - obj.offs,
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
                        x = x_offs,
                        y = obj.tab_h+obj.offs+h_buts*3,
                        w = gfx.w - x_offs - obj.offs,
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
                        x = x_offs,
                        y = obj.tab_h+obj.offs +h_buts*4,
                        w = gfx.w - x_offs - obj.offs,
                        h = h_buts+obj.offs,
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
                        w = knob_w,
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
