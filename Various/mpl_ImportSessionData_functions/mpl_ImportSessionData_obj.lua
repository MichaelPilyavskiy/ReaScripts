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
    obj.but_aback = 0.4
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
    
    local min_w = 600
    local min_h = 200
    local reduced_view = gfx.h  <= min_h
    gfx.w  = math.max(min_w,gfx.w)
    gfx.h  = math.max(min_h,gfx.h)
    
    obj.menu_w = 120
    obj.menu_h = 35
    obj.bottom_line_h = 30
    obj.scroll_w = 20
    obj.trlistw = math.floor((gfx.w - obj.scroll_w - obj.get_w)*0.7)
    obj.tr_listh = gfx.h-obj.menu_h-obj.bottom_line_h
    obj.tr_listxindend = 12
    obj.botline_h = gfx.h - (obj.menu_h + obj.tr_listh)
    
    Obj_MenuMain  (conf, obj, data, refresh, mouse, strategy)
    Obj_TopLine(conf, obj, data, refresh, mouse)
    if data.tr_chunks and conf.lastrppsession ~=  '' then 
      Obj_Tracklist(conf, obj, data, refresh, mouse, strategy) 
      Obj_Scroll(conf, obj, data, refresh, mouse)
      Obj_Strategy(conf, obj, data, refresh, mouse, strategy)
      Obj_trlistActions(conf, obj, data, refresh, mouse, strategy) 
    end
    for key in pairs(obj) do if type(obj[key]) == 'table' then  obj[key].context = key  end end    
  end
  -----------------------------------------------
  function Obj_MenuMain(conf, obj, data, refresh, mouse, strategy)
            obj.menu = { clear = true,
                        x = 0,
                        y = 0,
                        w = obj.menu_w-1,
                        h = obj.menu_h,
                        col = 'white',
                        txt= 'Menu / actions >',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        alpha_back = obj.but_aback,
                        func =  function() 
                                  Menu(mouse,               
                          {
                            { str = conf.mb_title..' '..conf.vrs..'|',
                              hidden = true
                            },
                            { str = 'Donate to MPL',
                              func = function() Open_URL('http://www.paypal.me/donate2mpl') end }  ,
                            { str = 'Contact: Cockos Forum thread',
                              func = function() Open_URL('https://forum.cockos.com/showthread.php?t=233358') end  } ,                              
                            { str = 'Contact: MPL VK',
                              func = function() Open_URL('http://vk.com/mpl57') end  } ,     
                            { str = 'Contact: MPL SoundCloud|',
                              func = function() Open_URL('http://soundcloud.com/mpl57') end  } ,     
                            { str = 'Reset import strategy to default',
                              func = function() 
                                LoadStrategy(conf, strategy, true)
                                refresh.GUI = true 
                                refresh.data = true end  } ,                               
                            { str = 'Reset filename|',
                              func = function() 
                                conf.lastrppsession = '' 
                                Run_Init(conf, obj, data, refresh, mouse) 
                                refresh.GUI = true 
                                refresh.data = true end  } ,  
                            { str = '#Track list actions'},                             
                            { str = 'Match source tracks, import them to new tracks',
                              func = function() 
                                      Data_CollectProjectTracks(conf, obj, data, refresh, mouse)
                                      Data_ClearDest(conf, obj, data, refresh, mouse, strategy)  
                                      Data_MatchDest(conf, obj, data, refresh, mouse, strategy, true) 
                                    end ,
                            },
                            { str = 'Mark all source tracks for import to new tracks',
                              func = function() 
                                      Data_ClearDest(conf, obj, data, refresh, mouse, strategy, true)  
                                      refresh.GUI = true 
                                                                      refresh.data = true
                                    end ,
                            } ,                        
                            { str = 'Mark selected source tracks for import to new tracks|',
                              func = function() 
                                      for i = 1, #data.tr_chunks do if data.tr_chunks[i].selected then data.tr_chunks[i].dest = -1  end end   
                                    end ,
                            }, 
                            { str = '#Match algorithm'},    
                            { str = 'Match only by full name',
                              state = conf.match_flags&1==1,
                              func = function() 
                                      conf.match_flags = BinaryToggle(conf.match_flags, 0)
                                    end ,
                            } ,
                            { str = 'Case sensitive',
                              state = conf.match_flags&2==2,
                              hidden = conf.match_flags&1==0,
                              func = function() 
                                      conf.match_flags = BinaryToggle(conf.match_flags, 1)
                                    end ,
                            }                                                                                   
                            }
    )
                                  refresh.conf = true 
                                  refresh.GUI = true
                                  --refresh.GUI_onStart = true
                                  refresh.data = true
                                end}  
  end
  
  -----------------------------------------------
  function Obj_TopLine(conf, obj, data, refresh, mouse)
    if not data.cur_project then return end
    local but_w = math.floor(gfx.w - obj.menu_w - obj.get_w)
    local txt = 'Destination: '..data.cur_project..'\nSource: '
    if conf.lastrppsession ~= '' then txt = txt..conf.lastrppsession else txt = txt..'Browse for RPP session...' end
    obj.deffiel = { clear = true,
              x = obj.menu_w,
              y = 0,
              w = but_w-1,
              h = obj.menu_h,
              alpha_back = obj.but_aback,
              txt= txt,
              aligh_txt = 16,
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
              txt= 'Update\nsrc/dest',
              alpha_back = obj.but_aback,
              aligh_txt = 16,
              show = true,
              fontsz = obj.GUI_fontsz2,
              func =  function() 
                        Run_Init(conf, obj, data, refresh, mouse)
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
                        disable_blitback = true,
                        fontsz = conf.GUI_padfontsz,--obj.GUI_fontsz2,  
                      }
        obj.scroll_pat_handle = 
                      { clear = true,
                        x = 0,
                        y = obj.menu_h + obj.scroll_val * (pat_scroll_h -scroll_handle_h)+2 ,
                        w = obj.scroll_w-1,
                        h = scroll_handle_h-1,
                        txt = '',
                        fillback = true,
                        fillback_colstr = 'white',
                        show = true,
                        --is_but = true,
                        fillback_a = obj.but_aback,
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
    
    local r_count = 0
    for i = 1, #data.tr_chunks do
      local tr_name = data.tr_chunks[i].tr_name
      local cond = (strategy.tr_filter == '' or (strategy.tr_filter ~= '' and tostring(tr_name):match(strategy.tr_filter)))
      data.tr_chunks[i].tr_show = cond
      if cond==true then r_count = r_count +1 end
    end
    local y_shift = 0
    local com_list_h = tr_h *(r_count-1)
    if com_list_h > obj.tr_listh then 
      y_shift = obj.scroll_val * com_list_h
    end
    
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
              --ignore_mouse = true,
              a_frame =0,
              alpha_back = 0,
              func_wheel =  function() 
                local mult
                if mouse.wheel_trig > 0 then mult = -1 else mult = 1 end
                obj.scroll_val = lim(obj.scroll_val + (50/com_list_h)*mult) refresh.GUI = true 
              end}    
              
    local tr_x_ind= 0
    local i_real = 1
    
    
    for i = 1, #data.tr_chunks do
      local tr_y = tr_listy - y_shift+ obj.offs + tr_h*(i_real-1)
      local r = 90
      local col0, tr_name = ColorToNative( r, r, r ), ' (untitled)'
      if data.tr_chunks[i] then
        if data.tr_chunks[i].tr_col then col0 = data.tr_chunks[i].tr_col end
        if data.tr_chunks[i].tr_name and data.tr_chunks[i].tr_name ~= '' then tr_name = data.tr_chunks[i].tr_name end
      end
      local show_cond= (tr_y > tr_listy and  tr_y + tr_h < tr_listy + obj.tr_listh) and data.tr_chunks[i].tr_show
      if data.tr_chunks[i].tr_show then i_real = i_real + 1 end
      local tr_w = math.floor(tr_listw/2)
      if show_cond then
        local sel = data.tr_chunks[i].selected
        obj['trsrc'..i] = { clear = true,
              x =tr_listx+tr_x_ind,
              y = tr_y,
              w = tr_w-tr_x_ind-1,
              h = tr_h-1,
              fillback = true,
              fillback_colint = col0,
              fillback_a = 0.9,
              txt= i..': '..tr_name,
              show = show_cond,
              fontsz = obj.GUI_fontsz2, 
              --ignore_mouse = true,
              selected = sel,
              func =  function() 
                        data.tr_chunks[i].selected = true
                        obj.cur_trlistitem = i
                        refresh.GUI = true
                      end,
              --[[func_LD2 = function()
                            if not mouse.context then return end
                            local tr_id = mouse.context:match('%d+')
                            if tr_id then tr_id = tonumber(tr_id) end
                            if tr_id and data.tr_chunks[tr_id] then 
                              data.tr_chunks[tr_id].selected = true
                              --refresh.data = true
                              refresh.GUI = true
                            end
                          end,
              onrelease_L2 = function() refresh.GUI = true end]]
              func_trigShift = function()
                                  if obj.cur_trlistitem then 
                                    st_sel = obj.cur_trlistitem
                                    end_sel = i
                                    if end_sel > st_sel then
                                      for i = st_sel, end_sel do data.tr_chunks[i].selected = true end
                                     else
                                      for i = end_sel, st_sel  do data.tr_chunks[i].selected = true end
                                    end
                                  end
                                  refresh.GUI = true
                                end
              }  
      end
      if data.tr_chunks[i].I_FOLDERDEPTH then tr_x_ind = tr_x_ind + (data.tr_chunks[i].I_FOLDERDEPTH * obj.tr_listxindend)  end 
    
      
        if tr_y > tr_listy and  tr_y + tr_h < tr_listy + obj.tr_listh then
          local txt = '(none)'
          local tr_col, fillback,ret, txt0, tr_col0
          if type(data.tr_chunks[i].dest) == 'string' and data.tr_chunks[i].dest ~= '' then
            ret, txt0, tr_col0 = Data_GetParamsFromGUID(data, data.tr_chunks[i].dest)
            if ret then
              txt, tr_col = txt0, tr_col0 
              fillback = true
            end
           elseif data.tr_chunks[i].dest == -1 then 
            txt, tr_col = 'New track at tracklist end', 0
           elseif data.tr_chunks[i].dest == -2 then 
            local imported_src_tr = VF_GetTrackByGUID(data.tr_chunks[i].destGUID)  
            if imported_src_tr then 
              local retval, tr_name = reaper.GetTrackName( imported_src_tr )
              txt, tr_col = '<Remap only> '..i..': '..tr_name, 0            
            end
          end
          local tr_w = math.floor(tr_listw/2)
          obj['trdest'..i] = { clear = true,
                x = tr_listx + tr_w,
                y = tr_y,
                w = tr_w,
                h = tr_h-1,
                fillback = true,
                fillback_colint = tr_col,
                fillback_a = 0.9,
                alpha_back = 0.01,
                txt= txt,
                show = data.tr_chunks[i].tr_show,
                fontsz = obj.GUI_fontsz2,
                disable_blitback = true,
                func =  function() 
                          Data_CollectProjectTracks(conf, obj, data, refresh, mouse)
                          Data_DefineUsedTracks(conf, obj, data, refresh, mouse)
                          local t = {
                            { str = 'none',
                              func =  function() 
                                        data.tr_chunks[i].dest = ''
                                      end
                            },
                            { str = 'New track at the end of tracklist',
                              func =  function() 
                                        data.tr_chunks[i].dest = -1
                                      end
                            },      
                             
                            { str = 'Match|',
                              func =  function() 
                                        Data_MatchDest(conf, obj, data, refresh, mouse, strategy, nil, i) 
                                      end
                            },                            
                                               
                          }
                          if data.cur_tracks then 
                            local sep = 20
                            for i2 = 1, #data.cur_tracks do
                              local sub = ''
                              
                              if i2>= sep and i2%sep == 0 then
                                if i2> sep then t[#t].str = t[#t].str..'|<' end
                                t[#t+1] =  { str ='>Tracks '..i2..'-'..i2+sep}                      
                              end
                              t[#t+1] = 
                              { str =i2..': '..data.cur_tracks[i2].tr_name,
                                 func =  function() 
                                            if data.cur_tracks[i2].used and data.cur_tracks[i2].used ~= i then 
                                              local name = data.tr_chunks[data.cur_tracks[i2].used].tr_name
                                              ret = MB('Track already used by ('..data.cur_tracks[i2].used..') '..name..', ignore old source?', '', 3)
                                              if ret == 6 then 
                                                data.tr_chunks[data.cur_tracks[i2].used].dest = ''
                                                data.tr_chunks[i].dest = data.cur_tracks[i2].GUID
                                              end
                                             else
                                              data.tr_chunks[i].dest = data.cur_tracks[i2].GUID 
                                            end
                                         end
                               }
                            end
                          end
                          
                          if #data.cur_tracks > 0 then
                          t[#t].str = t[#t].str..'|'
                          t[#t+1] = { str = 'Only remap sends from this track',
                            state = data.tr_chunks[i].dest==-2,
                            func =  function() 
                                      data.tr_chunks[i].destGUID = data.tr_chunks[i].dest
                                      data.tr_chunks[i].dest = -2
                                    end
                          }
                          end
                          Menu(mouse, t) 
                          Data_CollectProjectTracks(conf, obj, data, refresh, mouse)
                          Data_DefineUsedTracks(conf, obj, data, refresh, mouse)
                          refresh.GUI = true             
                        end}  
      end     
    end 
  end

  ----------------------------------------------- 
  function Obj_trlistActions(conf, obj, data, refresh, mouse, strategy) 
    local bw = math.ceil(gfx.w/4) --math.ceil((obj.menu_w + obj.get_w+obj.trlistw)/4)
    local bw_red= 2
    local by = obj.menu_h + obj.tr_listh+2
    
    --[[obj.menu_trlistctrl = { clear = true,
              x = 0,
              y = by,
              w = bw-bw_red,
              h = obj.botline_h,
              txt= 'Menu / actions >',
              aligh_txt = 16,
              show = true,
              fontsz = obj.GUI_fontsz2,
              alpha_back = obj.but_aback,
              func =  function() 
                        Menu(mouse,               
                          {
                            { str = conf.mb_title..' '..conf.vrs,
                              hidden = true
                            },
                            { str = 'Donate to MPL',
                              func = function() Open_URL('http://www.paypal.me/donate2mpl') end }  ,
                            { str = 'Contact: Cockos Forum thread|',
                              func = function() Open_URL('https://forum.cockos.com/showthread.php?t=233358') end  } ,                              
                            { str = 'Contact: MPL VK',
                              func = function() Open_URL('http://vk.com/mpl57') end  } ,     
                            { str = 'Contact: MPL SoundCloud|',
                              func = function() Open_URL('http://soundcloud.com/mpl57') end  } ,     
                            { str = 'Reset filename|',
                              func = function() 
                                conf.lastrppsession = '' 
                                Run_Init(conf, obj, data, refresh, mouse) 
                                refresh.GUI = true 
                                refresh.data = true end  } ,  
                            { str = '#Track list actions'},                             
                            { str = 'Match source tracks, import them to new tracks',
                              func = function() 
                                      Data_CollectProjectTracks(conf, obj, data, refresh, mouse)
                                      Data_ClearDest(conf, obj, data, refresh, mouse, strategy)  
                                      Data_MatchDest(conf, obj, data, refresh, mouse, strategy, true) 
                                    end ,
                            },
                            { str = 'Mark all source tracks for import to new tracks',
                              func = function() 
                                      Data_ClearDest(conf, obj, data, refresh, mouse, strategy, true)  
                                    end ,
                            } ,
                            { str = 'Mark selected source tracks for import to new tracks',
                              func = function() 
                                      for i = 1, #data.tr_chunks do if data.tr_chunks[i].selected then data.tr_chunks[i].dest = -1  end end   
                                    end ,
                            }                            
                            }
                          )
                        refresh.GUI = true
                        refresh.conf = true 
                      end}  ]]
                          
    local filt = strategy.tr_filter
    if filt == '' then filt = '(empty)' end
   obj.trfilt = { clear = true,
             x = 0,
             y = by,
             w = bw-bw_red,
             h = obj.botline_h,
             --[[fillback = true,
             fillback_colstr = 'red',
             fillback_a = 0.2,]]
             txt= 'Filter: '..filt,
             aligh_txt = 16,
             show = true,
             fontsz = obj.GUI_fontsz2,
             alpha_back = obj.but_aback,
             func =  function() 
                        retval, retvals_csv = GetUserInputs('Set filter for tracklist', 1, '', strategy.tr_filter  )
                        if retval then 
                          strategy.tr_filter = retvals_csv
                          SaveStrategy(conf, strategy, 1, true)
                          refresh.GUI = true
                        end
                     end}     
   obj.reset = { clear = true,
             x = bw,
             y = by,
             w = bw-bw_red,
             h = obj.botline_h,
             --[[fillback = true,
             fillback_colstr = 'red',
             fillback_a = 0.2,]]
             txt= 'Reset',
             aligh_txt = 16,
             show = true,
             fontsz = obj.GUI_fontsz2,
             alpha_back = obj.but_aback,
             func =  function() 
                       Data_ClearDest(conf, obj, data, refresh, mouse, strategy)  
                       for i = 1, #data.tr_chunks do data.tr_chunks[i].selected = nil end
                       refresh.GUI = true
                     end} 
    
    local has_selected = '' for i = 1, #data.tr_chunks do if data.tr_chunks[i].selected then has_selected = ' selected' break end end
    obj.match = { clear = true,
              x = bw*2,
              y = by,
              w = bw-bw_red,
              h = obj.botline_h,
              --[[fillback = true,
              fillback_colstr = 'red',
              fillback_a = 0.2,]]
              txt= 'Match'..has_selected,
              aligh_txt = 16,
              show = true,
              fontsz = obj.GUI_fontsz2,
              alpha_back = obj.but_aback,
              func =  function() 
                        if has_selected == '' then
                          Data_CollectProjectTracks(conf, obj, data, refresh, mouse)
                          Data_ClearDest(conf, obj, data, refresh, mouse, strategy)  
                          Data_MatchDest(conf, obj, data, refresh, mouse, strategy) 
                         else
                          Data_CollectProjectTracks(conf, obj, data, refresh, mouse)
                          Data_ClearDest(conf, obj, data, refresh, mouse, strategy) 
                          for i = 1, #data.tr_chunks do if data.tr_chunks[i].selected then Data_MatchDest(conf, obj, data, refresh, mouse, strategy, nil, i)  end end
                        end
                        refresh.GUI = true
                      end}                      
    obj.import_action = { clear = true,
            x = bw*3,
            y = by,
            w = bw,
            h = obj.botline_h,
            fillback = true,
            fillback_colstr = 'red',
            fillback_a = 0.6,
            alpha_back = obj.but_aback,
            txt= 'Import',
            aligh_txt = 16,
            show = true,
            fontsz = obj.GUI_fontsz1,
            func =  function() 
                      Undo_BeginBlock2( 0 )
                      PreventUIRefresh( 1 )
                      Data_Import(conf, obj, data, refresh, mouse, strategy)  
                      PreventUIRefresh( -1 )
                      Undo_EndBlock2( 0, 'mpl_Import Session Data', -1 )
                    end}                          
  end
  -----------------------------------------------   
  function Obj_Strategy_GenerateTable(conf, obj, data, refresh, mouse, ref_strtUI, strategy) 
    local wstr = gfx.w - (obj.trlistw+obj.scroll_w ) -2
    local x_str = obj.trlistw +obj.scroll_w + 1
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
                        a_frame = 0,
                        ignoremouse = true
                        }   
    local y_offs = 10
    local x_offs = 10  
    for i = 1, #ref_strtUI do
      if ref_strtUI[i].show then
        local disable_blitback if not ref_strtUI[i].has_blit then disable_blitback = true end
        local col_str 
        if ref_strtUI[i].col_str then col_str = ref_strtUI[i].col_str end
        local txt_a,ignore_mouse=0.9
        if ref_strtUI[i].hidden then
          txt_a = 0.35
          --ignore_mouse = true
        end
        
        if y_str + y_offs+obj.strategy_itemh > gfx.h- obj.bottom_line_h then return end
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
                          --[[{ name = 'Tracks section',
                            --state = strategy.comchunk==1,
                            --hidden = strategy.comchunk==0,
                            show = true,
                            has_blit = true,
                            level = 0,       
                          } ,]]                        
                          { name = 'Track raw data (remove routing, GUIDs)',
                            state = strategy.comchunk==1,
                            hidden = strategy.comchunk==0,
                            show = true,
                            has_blit = true,
                            level = 0,
                            func =  function()
                                      strategy.comchunk = math.abs(1-strategy.comchunk)
                                    end,             
                          } ,  
                          { name = 'Track FX chain',
                            state = strategy.fxchain&1==1,
                            show = strategy.comchunk==0,
                            has_blit = false,
                            level = 1,
                            func =  function()
                                      strategy.comchunk = 0
                                      strategy.fxchain = BinaryToggle(strategy.fxchain, 0)
                                    end,             
                          } , 
                          { name = 'Copy to the end of chain instead replace',
                            state = strategy.fxchain&2==2,
                            show = strategy.comchunk&1==0 and strategy.fxchain&1==1,
                            has_blit = false,
                            level = 2,
                            func =  function()
                                      strategy.comchunk = 0
                                      strategy.fxchain = BinaryToggle(strategy.fxchain, 1)
                                    end,             
                          } ,                                                      
                          { name = 'Track Properties (LMB to all, RMB to none)',
                            state = strategy.trparams&1==1,
                            show = strategy.comchunk&1==0,
                            has_blit = false,
                            level = 1,
                            func =  function()
                                      strategy.comchunk = 0
                                      strategy.trparams = BinaryToggle(strategy.trparams, 0)
                                    end, 
                            func_R =  function()
                                      strategy.comchunk = 0
                                      strategy.trparams = 0
                                    end,                                                 
                          } ,     
                          { name = 'Volume',
                            state = strategy.trparams&2==2,
                            show = strategy.trparams&1==0 and strategy.comchunk&1==0,
                            has_blit = false,
                            level = 2,
                            func =  function()
                                      strategy.comchunk = 0
                                      strategy.trparams = BinaryToggle(strategy.trparams, 0, 0)
                                      strategy.trparams = BinaryToggle(strategy.trparams, 1)
                                    end,             
                          } , 
                          { name = 'Pan/Width/Panlaw/DualPan/Panmode',
                            state = strategy.trparams&4==4,
                            show = strategy.trparams&1==0 and strategy.comchunk&1==0,
                            has_blit = false,
                            level = 2,
                            func =  function()
                                      strategy.comchunk = 0
                                      strategy.trparams = BinaryToggle(strategy.trparams, 0, 0)
                                      strategy.trparams = BinaryToggle(strategy.trparams, 2)
                                    end,             
                          } ,  
                          { name = 'Phase',
                            state = strategy.trparams&8==8,
                            show = strategy.trparams&1==0 and strategy.comchunk&1==0,
                            has_blit = false,
                            level = 2,
                            func =  function()
                                      strategy.comchunk = 0
                                      strategy.trparams = BinaryToggle(strategy.trparams, 0, 0)
                                      strategy.trparams = BinaryToggle(strategy.trparams, 3)
                                    end,             
                          } , 
                          { name = 'Record input/mode',
                            state = strategy.trparams&16==16,
                            show = strategy.trparams&1==0 and strategy.comchunk&1==0,
                            has_blit = false,
                            level = 2,
                            func =  function()
                                      strategy.comchunk = 0
                                      strategy.trparams = BinaryToggle(strategy.trparams, 0, 0)
                                      strategy.trparams = BinaryToggle(strategy.trparams, 4)
                                    end,             
                          } , 
                          { name = 'Record monitoring/monitor items',
                            state = strategy.trparams&32==32,
                            show = strategy.trparams&1==0 and strategy.comchunk&1==0,
                            has_blit = false,
                            level = 2,
                            func =  function()
                                      strategy.comchunk = 0
                                      strategy.trparams = BinaryToggle(strategy.trparams, 0, 0)
                                      strategy.trparams = BinaryToggle(strategy.trparams, 5)
                                    end,             
                          } ,  
                          { name = 'Master/parent send + parent channels',
                            state = strategy.trparams&64==64,
                            show = strategy.trparams&1==0 and strategy.comchunk&1==0,
                            has_blit = false,
                            level = 2,
                            func =  function()
                                      strategy.comchunk = 0
                                      strategy.trparams = BinaryToggle(strategy.trparams, 0, 0)
                                      strategy.trparams = BinaryToggle(strategy.trparams, 6)
                                    end,             
                          } ,  
                          { name = 'Color',
                            state = strategy.trparams&128==128,
                            show = strategy.trparams&1==0 and strategy.comchunk&1==0,
                            has_blit = false,
                            level = 2,
                            func =  function()
                                      strategy.comchunk = 0
                                      strategy.trparams = BinaryToggle(strategy.trparams, 0, 0)
                                      strategy.trparams = BinaryToggle(strategy.trparams, 7)
                                    end,             
                          } ,                                                    
                          { name = 'Track Items RAW data',
                            state = strategy.tritems&1==1,
                            show = strategy.comchunk&1==0,
                            has_blit = false,
                            level = 1,
                            func =  function()
                                      strategy.comchunk = 0
                                      strategy.tritems = BinaryToggle(strategy.tritems, 0)
                                    end, 
                            func_R =  function()
                                      strategy.comchunk = 0
                                      strategy.tritems = 0
                                    end,                                                 
                          } ,
                          { name = 'Clear old items',
                            state = strategy.tritems&2==2,
                            show =  strategy.tritems&1==1 and strategy.comchunk&1==0,
                            has_blit = false,
                            level = 2,
                            func =  function()
                                      strategy.comchunk = 0
                                      strategy.tritems = BinaryToggle(strategy.tritems, 1)
                                    end,             
                          } ,  
                          { name = 'Correct source paths to source RPP path',
                            state = strategy.tritems&4==4,
                            show =  strategy.tritems&1==1 and strategy.comchunk&1==0,
                            has_blit = false,
                            level = 2,
                            func =  function()
                                      strategy.comchunk = 0
                                      strategy.tritems = BinaryToggle(strategy.tritems, 2)
                                      if strategy.tritems&4==4 then strategy.tritems = BinaryToggle(strategy.tritems, 4, 0) end
                                    end,             
                          } ,   
                          --[[{ name = 'Copy and remap sources to dest. RPP path',
                            state = strategy.tritems&16==16,
                            show =  strategy.tritems&1==1 and strategy.comchunk&1==0,
                            has_blit = false,
                            level = 2,
                            func =  function()
                                      strategy.comchunk = 0
                                      strategy.tritems = BinaryToggle(strategy.tritems, 4)
                                      if strategy.tritems&16==16 then strategy.tritems = BinaryToggle(strategy.tritems, 2, 0) end
                                    end,             
                          } ,         ]]                     
                          { name = 'Build any missing peaks',
                            state = strategy.tritems&8==8,
                            show =  strategy.tritems&1==1 and strategy.comchunk&1==0,
                            has_blit = false,
                            level = 2,
                            func =  function()
                                      strategy.comchunk = 0
                                      strategy.tritems = BinaryToggle(strategy.tritems, 3)
                                    end,             
                          } ,                          
                                               
                          { name = 'Track receives import logic',
                            state = -1,
                            show = strategy.comchunk&1==0,
                            has_blit = false,
                            level = 1,
                            func =  function()
                                      strategy.comchunk = 0
                                      strategy.trsend = BinaryToggle(strategy.trsend, 0)
                                    end,                                                 
                          } ,    
                          { name = 'Insert/link non-existing sources',
                            state = strategy.trsend&2==2,
                            show = strategy.comchunk&1==0,
                            has_blit = false,
                            level = 2,
                            func =  function()
                                      strategy.comchunk = 0
                                      strategy.trsend = BinaryToggle(strategy.trsend, 1)
                                    end,             
                          } ,  
                          { name = 'Link sources imported by match',
                            state = strategy.trsend&4==4,
                            show = strategy.comchunk&1==0,
                            has_blit = false,
                            level = 2,
                            func =  function()
                                      strategy.comchunk = 0
                                      strategy.trsend = BinaryToggle(strategy.trsend, 2)
                                    end,             
                          } ,  
                          { name = 'Link sources imported as new tracks',
                            state = strategy.trsend&8==8,
                            show = strategy.comchunk&1==0,
                            has_blit = false,
                            level = 2,
                            func =  function()
                                      strategy.comchunk = 0
                                      strategy.trsend = BinaryToggle(strategy.trsend, 3)
                                    end,             
                          } ,  
                          { name = 'Allow multiple src/dest receives',
                            state = strategy.trsend&16==16,
                            show = strategy.comchunk&1==0,
                            has_blit = false,
                            level = 2,
                            func =  function()
                                      strategy.comchunk = 0
                                      strategy.trsend = BinaryToggle(strategy.trsend, 4)
                                    end,             
                          } ,                                                                                                            
                                           
                          --[[{ name = '----------------------------------',
                            show = true,   
                            level = 0,           
                          }     ,   ]]                                   
                          { name = 'Project head stuff (LMB to all, RMB to none)',
                            state = strategy.master_stuff&1==1,
                            show = true,
                            --hidden = strategy.comchunk==1,
                            has_blit = true,
                            level = 0,
                            func =  function()
                                      strategy.master_stuff = BinaryToggle(strategy.master_stuff, 0)
                                    end, 
                            func_R =  function()
                                      strategy.master_stuff = 0
                                    end,                                                 
                          } ,     
                          { name = 'Master FX Chain',
                            state = strategy.master_stuff&2==2,
                            show =  true,
                            hidden = strategy.master_stuff&1==1,
                            has_blit = false,
                            level = 1,
                            func =  function()
                                      strategy.master_stuff = BinaryToggle(strategy.master_stuff, 0, 0)
                                      strategy.master_stuff = BinaryToggle(strategy.master_stuff, 1)
                                    end,             
                          } , 
                          { name = 'Tempo/Time signature envelope',
                            state = strategy.master_stuff&4==4,
                            show =  true,
                            hidden = strategy.master_stuff&1==1,
                            has_blit = false,
                            level = 1,
                            func =  function()
                                      strategy.master_stuff = BinaryToggle(strategy.master_stuff, 0, 0)
                                      strategy.master_stuff = BinaryToggle(strategy.master_stuff, 2)
                                    end,             
                          } ,                           
                          { name = 'Markers',
                            state = strategy.markers_flags&1==1,
                            show =  true,
                            hidden = strategy.master_stuff&1==1,
                            has_blit = false,
                            level = 1,
                            func =  function()
                                      strategy.markers_flags = BinaryToggle(strategy.markers_flags, 0)
                                    end,             
                          } , 
                          { name = 'Marker replace',
                            state = strategy.markers_flags&2==2,
                            show =  strategy.markers_flags&1==1,
                            has_blit = false,
                            level = 2,
                            func =  function()
                                      strategy.markers_flags = BinaryToggle(strategy.markers_flags, 1)
                                    end,             
                          } ,   
                          { name = 'Regions',
                            state = strategy.markers_flags&4==4,
                            show =  true,
                            hidden = strategy.master_stuff&1==1,
                            has_blit = false,
                            level = 1,
                            func =  function()
                                      strategy.markers_flags = BinaryToggle(strategy.markers_flags, 2)
                                    end,             
                          } , 
                          { name = 'Regions replace',
                            state = strategy.markers_flags&8==8,
                            show =  strategy.markers_flags&4==4,
                            has_blit = false,
                            level = 2,
                            func =  function()
                                      strategy.markers_flags = BinaryToggle(strategy.markers_flags, 3)
                                    end,             
                          } ,                                                                                                                                                          
                                                                                                                                  
                                                                            
                        }
    Obj_Strategy_GenerateTable(conf, obj, data, refresh, mouse, act_strtUI, strategy )  
  end  
