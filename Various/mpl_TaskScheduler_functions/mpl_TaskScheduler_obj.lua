-- @description TaskScheduler_obj
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex
  
  
  ---------------------------------------------------
  function OBJ_init(conf, obj, data, refresh, mouse) 
    -- globals
    obj.reapervrs = tonumber(GetAppVersion():match('[%d%.]+')) 
    obj.build_t = {}
    
    obj.offs = 2 
    obj.grad_sz = 200 
    obj.scroll_val = 0
    obj.scroll_w = 35
    obj.menu_h = 20
    obj.but_aback = 0.2
    obj.removeb_w = 20
    
    obj.del_w = obj.removeb_w
    obj.num_w = obj.removeb_w
    obj.timeshed_w = 120
    obj.comlist_h = 0
    
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
                   red =     {1,   0.4,    0.4   },
                   red1 =     {0.8,   0.2,    0.2   },
                   red2 =     {0.6,   0.1,    0.1   },                   
                   green =   {0.5,   0.9,    0.6   },
                   black =   {0,0,0 }
                   }    
    
    -- other
  end
---------------------------------------------------
  function OBJ_Update(conf, obj, data, refresh, mouse) 
    for key in pairs(obj) do if type(obj[key]) == 'table' and obj[key].clear then obj[key] = {} end end  
   
    local min_w = 600
    local min_h = 100
    local reduced_view = gfx.h  <= min_h
    gfx.w  = math.max(min_w,gfx.w)
    gfx.h  = math.max(min_h,gfx.h)
    
    
    obj.trlistw = math.floor(gfx.w - obj.scroll_w-obj.offs)-- - obj.get_w)*0.7)
    obj.tr_listh = gfx.h-obj.menu_h-obj.offs--obj.bottom_line_h
    --obj.tr_listxindend = 12
    --obj.botline_h = gfx.h - (obj.menu_h + obj.tr_listh)

    obj.tr_listx = obj.scroll_w  + 1
    obj.tr_listy = obj.menu_h 
    obj.tr_h = 20
    
    obj.actID_w = (obj.trlistw-(obj.del_w+obj.num_w+obj.timeshed_w)) * 0.6
    obj.comment_w= (obj.trlistw-(obj.del_w+obj.num_w+obj.timeshed_w)) * 0.4
    
    Obj_Menu(conf, obj, data, refresh, mouse) 
    Obj_Scroll(conf, obj, data, refresh, mouse)
    local comlist_h = Obj_ParamList(conf, obj, data, refresh, mouse, true)
    if comlist_h then 
      obj.comlist_h = comlist_h
      Obj_ParamList(conf, obj, data, refresh, mouse)
    end
    for key in pairs(obj) do if type(obj[key]) == 'table' then  obj[key].context = key  end end    
  end
    -----------------------------------------------
    function Obj_Menu(conf, obj, data, refresh, mouse)
        obj.menu = { clear = true,
                          x = 0,
                          y = 0,
                          w = obj.scroll_w-1,
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
        { str = '|#Info'},
        { str = 'Donate to MPL',
          func = function() Open_URL('http://www.paypal.me/donate2mpl') end }  ,
        { str = 'Cockos Forum thread',
          func = function() Open_URL('http://forum.cockos.com/showthread.php?t=188335') end  } , 
        { str = 'MPL on VK',
          func = function() Open_URL('http://vk.com/mpl57') end  } ,     
        { str = 'MPL on SoundCloud|',
          func = function() Open_URL('http://soundcloud.com/mpl57') end  } ,     
          
        { str = '#Options'},                
        { str = 'Dock '..'MPL '..conf.mb_title..' '..conf.vrs,
          func = function() 
                    conf.dock = math.abs(1-conf.dock) 
                    gfx.quit() 
                    gfx.init('MPL '..conf.mb_title..' '..conf.vrs,
                              conf.wind_w, 
                              conf.wind_h, 
                              conf.dock, conf.wind_x, conf.wind_y)
                end ,
          state = conf.dock == 1},                                                                            
      }
      )
                                    refresh.conf = true 
                                    refresh.GUI = true
                                    refresh.data = true
                                    --refresh.GUI_onStart = true
                                    refresh.data = true
                                  end}     
        obj.addevent = { clear = true,
                          --blit = true,
                          x = obj.scroll_w,
                          y = 0,
                          w = obj.removeb_w*2,
                          h = obj.menu_h,
                          col = 'white',
                          txt= '+',
                          show = true,
                          fontsz = obj.GUI_fontsz2,
                          a_frame = 0,
                          func = function()
                            -- get time
                              local timeshed = data.time_shed_default
                              local evtID = 0
                              local comment = ''
                              local sep = '|'
                              local retval, retvals_csv = reaper.GetUserInputs( 'Add event', 8, 'Actionlist ID,Day,Month,Year,Hour,Minute,Second,Comment,separator='..sep, 
                                                                                tostring(0)..sep..
                                                                                os.date("%d",data.time_shed_default)..sep..
                                                                                os.date("%m",data.time_shed_default)..sep..
                                                                                os.date("%Y",data.time_shed_default)..sep..
                                                                                os.date("%H",data.time_shed_default)..sep..
                                                                                os.date("%M",data.time_shed_default)..sep..
                                                                                os.date("%S",data.time_shed_default)..sep..
                                                                                ' ')
                              if retval then
                                local parse_str = {}
                                for val in retvals_csv:gmatch('[^|]+') do parse_str [#parse_str+1]=val end
                                if #parse_str~= 8 then return end
                                local t_shift = 1
                                local datetime = { year = parse_str[3+t_shift],
                                                   month = parse_str[2+t_shift],
                                                   day = parse_str[1+t_shift],
                                                   hour = parse_str[4+t_shift],
                                                   min = parse_str[5+t_shift],
                                                   sec = parse_str[6+t_shift]
                                                  }
                                timeshed=os.time(datetime)
                                evtID = parse_str[1]
                                comment = parse_str[8]
                              end
                            
                            data.list[#data.list+1] = { evtID = 0, 
                                                        timeshed = timeshed, 
                                                        flags=0,
                                                        stringargs = '',
                                                        comment =comment}
                            DataUpdate2_StoreCurrentList(conf, obj, data, refresh, mouse) 
                            refresh.data = true
                            --refresh.GUI = true
                          end
                        }      
        obj.act_names = { clear = true,
                          --blit = true,
                          x = obj.tr_listx+obj.num_w+obj.removeb_w,
                          y = 0,
                          w = obj.actID_w-1,
                          h = obj.menu_h,
                          col = 'white',
                          txt= 'Actions',
                          show = true,
                          fontsz = obj.GUI_fontsz2,
                          a_frame = 0,
                        }    
        obj.timedate = { clear = true,
                          --blit = true,
                          x = obj.tr_listx+obj.num_w+obj.removeb_w+obj.actID_w,
                          y = 0,
                          w = obj.timeshed_w-1,
                          h = obj.menu_h,
                          col = 'white',
                          txt= data.date,
                          show = true,
                          fontsz = obj.GUI_fontsz2,
                          a_frame = 0,
                        }   
        obj.comment_top = { clear = true,
                          --blit = true,
                          x = obj.tr_listx+obj.num_w+obj.removeb_w+obj.actID_w+obj.timeshed_w,
                          y = 0,
                          w = obj.comment_w-1,
                          h = obj.menu_h,
                          col = 'white',
                          txt= 'Comments',
                          show = true,
                          fontsz = obj.GUI_fontsz2,
                          a_frame = 0,
                        }                           
    
    end
  --------------------------------------------------- 
  function Obj_Scroll(conf, obj, data, refresh, mouse)
    local pat_scroll_h = gfx.h - obj.menu_h -- obj.menu_h
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
  function Obj_ParamList(conf, obj, data, refresh, mouse, gethonly)
    obj.paramlist = { clear = true,
              x =obj.tr_listx-1,--math.floor(gfx.w/2),
              y = obj.tr_listy,
              w = obj.tr_listw,
              h = obj.tr_listh,
              col = 'white',
              --colfill_col = col0,
              --colfill_a = 0.5,
              txt= '',
              aligh_txt = 16,
              show = true,
              fontsz = obj.GUI_fontsz2,
              --ignore_mouse = true,
              disable_blitback = true,
              func_wheel =  function() 
                local mult
                if mouse.wheel_trig > 0 then mult = -1 else mult = 1 end
                obj.scroll_val = lim(obj.scroll_val + (50/obj.comlist_h)*mult) 
                refresh.GUI = true 
              end}    
              
    -- loop thr data
    if not data.list then return end 
    local tr_y0 = obj.tr_listy - obj.comlist_h * obj.scroll_val 
    local tr_y = tr_y0   
    for listid=1,#data.list do
      --[[obj['list'..listid] = { clear = true,
              x =obj.tr_listx,
              y = tr_y,
              w = obj.tr_listw,
              h = obj.tr_h,
              fillback = true,
              fillback_colstr = 'green',
              fillback_a = 0.7,
              alpha_back = 0.3,
              txt= listid..': '..data.list[listid].evtID,
              txt_a = 1,
              align_txt = 1,
              fontsz = obj.GUI_fontsz2,
              alpha_back = 0.7,
              show = tr_y>=obj.tr_listy and tr_y <=obj.tr_listy+obj.tr_listh,
              } ]]
      Obj_ParamList_Sub(conf, obj, data, refresh, mouse, listid, tr_y)
      tr_y = tr_y + obj.tr_h
    end 
    return   tr_y -   tr_y0  
  end 
  -----------------------------------------------
  function Obj_ParamList_Sub(conf, obj, data, refresh, mouse, listid, tr_y)
    local fillback_a = 0.7
    if data.list[listid].timeshed < data.time then fillback_a = 0.3 end
    obj['list_del'..listid] = { clear = true,
              x =obj.tr_listx,
              y = tr_y,
              w = obj.removeb_w-1,
              h = obj.tr_h,
              fillback = true,
              fillback_colstr = 'red',
              fillback_a = fillback_a,
              alpha_back = 0.3,
              txt= '-',
              txt_a = 1,
              align_txt = 16,
              fontsz = obj.GUI_fontsz2,
              alpha_back = 0.7,
              show = tr_y>=obj.tr_listy and tr_y <=obj.tr_listy+obj.tr_listh,
              func = function()
                      table.remove(data.list,listid)
                      DataUpdate2_StoreCurrentList(conf, obj, data, refresh, mouse) 
                      refresh.data = true
                    end
              }    
    obj['list_num'..listid] = { clear = true,
              x =obj.tr_listx+obj.removeb_w,
              y = tr_y,
              w = obj.num_w-1,
              h = obj.tr_h,
              fillback = true,
              fillback_colstr = 'green',
              fillback_a = fillback_a,
              alpha_back = 0.3,
              txt= listid,
              txt_a = 1,
              align_txt = 16,
              fontsz = obj.GUI_fontsz2,
              alpha_back = 0.7,
              show = tr_y>=obj.tr_listy and tr_y <=obj.tr_listy+obj.tr_listh,
              } 
    local evtname = '' if data.list[listid].evtname then evtname = data.list[listid].evtname end
    obj['list_act'..listid] = { clear = true,
              x =obj.tr_listx+obj.num_w+obj.removeb_w,
              y = tr_y,
              w = obj.actID_w-1,
              h = obj.tr_h,
              fillback = true,
              fillback_colstr = 'green',
              fillback_a = fillback_a,
              alpha_back = 0.3,
              txt= evtname,
              txt_a = 1,
              align_txt = 16,
              fontsz = obj.GUI_fontsz3,
              alpha_back = 0.7,
              show = tr_y>=obj.tr_listy and tr_y <=obj.tr_listy+obj.tr_listh,
              func = function()
                        Menu(mouse,               
                              { 
                                { str = 'Action list ID',
                                  func = function() 
                                            local retval, retvals_csv = reaper.GetUserInputs( 'Action list ID', 1, '', data.list[listid].evtID )
                                            if retval then
                                              data.list[listid].evtID=retvals_csv
                                              DataUpdate2_StoreCurrentList(conf, obj, data, refresh, mouse) 
                                              refresh.data = true
                                            end
                                        end }  ,   
                                { str = 'Play current tab project',
                                  func = function() 
                                            local retval, projfn = EnumProjects( -1 )
                                            data.list[listid].evtID=-1
                                            data.list[listid].stringargs = projfn
                                            DataUpdate2_StoreCurrentList(conf, obj, data, refresh, mouse) 
                                            refresh.data = true
                                        end }  ,                                                                                                               
                                }
                              )
                          
                      end
              }
    obj['list_shedtime'..listid] = { clear = true,
              x =obj.tr_listx+obj.num_w+obj.removeb_w+obj.actID_w,
              y = tr_y,
              w = obj.timeshed_w-1,
              h = obj.tr_h,
              fillback = true,
              fillback_colstr = 'green',
              fillback_a = fillback_a,
              alpha_back = 0.3,
              txt= os.date('%c', data.list[listid].timeshed),
              txt_a = 1,
              align_txt = 16,
              fontsz = obj.GUI_fontsz3,
              alpha_back = 0.7,
              show = tr_y>=obj.tr_listy and tr_y <=obj.tr_listy+obj.tr_listh,
              func =  function()
                        local retval, retvals_csv = reaper.GetUserInputs( 'Scheduled time', 6, 'Day,Month,Year,Hour,Minute,Second', 
                                                                          os.date("%d",data.list[listid].timeshed )..','..
                                                                          os.date("%m",data.list[listid].timeshed )..','..
                                                                          os.date("%Y",data.list[listid].timeshed )..','..
                                                                          os.date("%H",data.list[listid].timeshed )..','..
                                                                          os.date("%M",data.list[listid].timeshed )..','..
                                                                          os.date("%S",data.list[listid].timeshed ))
                        if retval then
                          local parse_str = {}
                          for val in retvals_csv:gmatch('[^,]+') do parse_str [#parse_str+1]=val end
                          if #parse_str~= 6 then return end
                          local datetime = { year = parse_str[3],
                                             month = parse_str[2],
                                             day = parse_str[1],
                                             hour = parse_str[4],
                                             min = parse_str[5],
                                             sec = parse_str[6]
                                            }
                          data.list[listid].timeshed=os.time(datetime)
                          DataUpdate2_StoreCurrentList(conf, obj, data, refresh, mouse) 
                          refresh.data = true
                        end
                      end
              } 
    obj['list_comment'..listid] = { clear = true,
              x =obj.tr_listx+obj.num_w+obj.removeb_w+obj.actID_w+obj.timeshed_w,
              y = tr_y,
              w = obj.comment_w-1,
              h = obj.tr_h,
              fillback = true,
              fillback_colstr = 'green',
              fillback_a = fillback_a,
              alpha_back = 0.3,
              txt= data.list[listid].comment,
              txt_a = 1,
              align_txt = 16,
              fontsz = obj.GUI_fontsz3,
              alpha_back = 0.7,
              show = tr_y>=obj.tr_listy and tr_y <=obj.tr_listy+obj.tr_listh,
              func =  function()
                        local retval, comment = reaper.GetUserInputs( 'comment', 1, '', data.list[listid].comment)
                        if retval then
                          data.list[listid].comment=comment
                          DataUpdate2_StoreCurrentList(conf, obj, data, refresh, mouse) 
                          refresh.data = true
                        end
                      end
              }                                              
  end
