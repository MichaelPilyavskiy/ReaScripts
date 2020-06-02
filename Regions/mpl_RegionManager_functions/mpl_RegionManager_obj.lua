-- @description RegionManager_obj
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
    obj.scroll_w = 20
    obj.menu_h = 20
    obj.but_aback = 0.2
    obj.comlist_h = 0
    obj.tr_h = 22 
    
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
   
    local min_w = 200
    local min_h = 100
    local reduced_view = gfx.h  <= min_h
    gfx.w  = math.max(min_w,gfx.w)
    gfx.h  = math.max(min_h,gfx.h)
    
    obj.trlistw = math.floor(gfx.w - obj.scroll_w-obj.offs)-- - obj.get_w)*0.7)
    obj.tr_listh = gfx.h-obj.menu_h-obj.offs

    obj.tr_listx = obj.scroll_w
    obj.tr_listy = obj.menu_h *2
    obj.tr_listw = obj.trlistw
    
    obj.rgnroww_idx = 20
    obj.rgnroww_idxreal = 20
    if conf.show_proj_ids == 0 then obj.rgnroww_idxreal = 0 end
    local row_w =55
    obj.rgnroww_start = row_w
    obj.rgnroww_end = row_w
    obj.rgnroww_len = row_w
    obj.rgnroww_name = obj.tr_listw - obj.rgnroww_idx-obj.rgnroww_idxreal-obj.rgnroww_start-obj.rgnroww_end-obj.rgnroww_len
    
    
    Obj_Menu(conf, obj, data, refresh, mouse) 
    Obj_Scroll(conf, obj, data, refresh, mouse)
    Obj_TopLine(conf, obj, data, refresh, mouse)
    Obj_RegList_Head(conf, obj, data, refresh, mouse)
    local comlist_h, realcnt = Obj_RegList(conf, obj, data, refresh, mouse, true)
    obj.realcnt = realcnt
    if comlist_h then 
      obj.comlist_h = comlist_h
      Obj_RegList(conf, obj, data, refresh, mouse)
    end
    for key in pairs(obj) do if type(obj[key]) == 'table' then  obj[key].context = key  end end    
  end
    -----------------------------------------------
    function Obj_Menu(conf, obj, data, refresh, mouse)
        obj.showflagreg = { clear = true,
                          x = 0,
                          y = obj.menu_h,
                          w = obj.scroll_w-1,
                          h = obj.menu_h,
                          col = 'white',
                          txt= 'R',
                          show = true,
                          fontsz = obj.GUI_fontsz2,
                          a_frame = 0,
                          is_selected=conf.showflag&1==1,
                          func =  function() 
                                    conf.showflag = BinaryToggle(conf.showflag, 0)
                                    refresh.conf = true 
                                    refresh.GUI = true
                                    --refresh.data = true
                                  end  }  
        obj.showflagmark = { clear = true,
                          x = 0,
                          y = obj.menu_h*2,
                          w = obj.scroll_w-1,
                          h = obj.menu_h,
                          col = 'white',
                          txt= 'M',
                          show = true,
                          fontsz = obj.GUI_fontsz2,
                          a_frame = 0,
                          is_selected=conf.showflag&2==2,
                          func =  function() 
                                    conf.showflag = BinaryToggle(conf.showflag, 1)
                                    refresh.conf = true 
                                    refresh.GUI = true
                                    --refresh.data = true
                                  end  }                             
        obj.menu = { clear = true,
                          x = 0,
                          y = 0,
                          w = obj.scroll_w-1,
                          h = obj.menu_h-1,
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
        { str = 'Donate to MPL',
          func = function() Open_URL('http://www.paypal.me/donate2mpl') end }  ,
        { str = 'Cockos Forum thread',
          func = function() Open_URL('http://forum.cockos.com/showthread.php?t=235521') end  } , 
        { str = 'MPL on VK',
          func = function() Open_URL('http://vk.com/mpl57') end  } ,     
        { str = 'MPL on SoundCloud|',
          func = function() Open_URL('http://soundcloud.com/mpl57') end  } , 
        { str = 'Help|',
          func = function() 
                    msg([[
ShortCuts:
  - Top/Down: change selection
  - Enter: play selected region
  - Shift+Enter: smooth seek selected region
  - Shift S: search tracks
  - Name LMB: select
  - Name Alt+LMB: remove
  - Name Ctrl+LMB: add to selection
  - Name RMB: change name
  
                    ]])
                  end  } ,           
        { str = '#Options'},
        { str = 'Show markers/regions project ID',
          func = function() 
                    conf.show_proj_ids = math.abs(1-conf.show_proj_ids) 
                    refresh.GUI = true
                end ,
          state = conf.show_proj_ids == 1},            
        
        
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
    end
  --------------------------------------------------- 
  function Obj_Scroll(conf, obj, data, refresh, mouse)
    local pat_scroll_h = gfx.h - obj.menu_h*3 -- obj.menu_h
    local scroll_handle_h = 50
        obj.scroll_pat = 
                      { clear = true,
                        x = 0,
                        y = obj.menu_h*3,
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
                        x = 0,--obj.offs,
                        y = obj.menu_h*3 + obj.scroll_val * (pat_scroll_h -scroll_handle_h) ,
                        w = obj.scroll_w-1,--obj.offs,
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
  function Obj_Selection_NextPrev(conf, obj, data, refresh, mouse, inc) 
    local cur_idx = Obj_Selection_GetFirst(conf, obj, data, refresh, mouse)
    if not cur_idx then obj.selection[1] = true cur_idx = 1 end 
    
    --local new_idx = lim(cur_idx + 1*inc, 1, #data.regions)
    local fin = 1 if inc > 0 then fin =  #data.regions end
    for i = cur_idx+inc, fin, inc do
      if (conf.showflag&1==1 and data.regions[i].isrgn == true) or (conf.showflag&2==2 and data.regions[i].isrgn == false) then
        new_idx = i
        break
      end
    end
    if not new_idx then return end
    obj.selection = {[new_idx]=true}
    if not obj['region_idx'..new_idx] then return end
    if obj['region_idx'..new_idx].show == false then -- if drawn
       obj.scroll_val  = lim((obj['region_idx'..new_idx].y-obj.tr_listy) / obj.comlist_h)
    end
    refresh.GUI = true
  end
  -----------------------------------------------
  function Obj_Selection_GetFirst(conf, obj, data, refresh, mouse)
    for i = 1, #data.regions do
      if obj.selection[i] and obj.selection[i] == true  then return i end
    end
  end
  -----------------------------------------------
  function Obj_RegList(conf, obj, data, refresh, mouse, gethonly)
    local fillback_a = 0.9
    local alpha_back = 0.4
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
    if not data.regions then return end 
    local tr_x_ind = 0   
    local tr_y0 = obj.tr_listy - obj.comlist_h * obj.scroll_val 
    local tr_y = tr_y0   
    local realcnt_idx = 0
    for idx=1,#data.regions do
      local fillback, col0 = true, data.regions[idx].color
      if col0==0 then 
        local r = 255 col0 = ColorToNative( r, r, r ) fillback_a = 0.44 
       --[[else
        local r, g, b = reaper.ColorFromNative( col0 )
        local pow = 1.2
        col0 = ColorToNative( math.floor(((r/255)^pow)*255), math.floor(((g/255)^pow)*255), math.floor(((b/255)^pow)*255) )]]
      end
      local show = true 
      if (tr_y < obj.tr_listy or tr_y > obj.tr_listy + obj.tr_listh) then show=false end--goto skipnextrgn end 
      if not ((conf.showflag&1==1 and data.regions[idx].isrgn == true) or (conf.showflag&2==2 and data.regions[idx].isrgn == false)) then goto skipnextrgn2 end 
      realcnt_idx = realcnt_idx + 1
      obj['region_idx'..idx] = { clear = true,
              x =obj.tr_listx,
              y = tr_y,
              w = obj.rgnroww_idx-1,
              h = obj.tr_h,
              fillback = fillback,
              fillback_colint = col0,--'col0,
              fillback_a = fillback_a,
              alpha_back =alpha_back,
              txt= realcnt_idx,
              txt_a = 1,
              align_txt = 16,
              fontsz = obj.GUI_fontsz2,
              show = show,
              is_selected = obj.selection[idx] and obj.selection[idx] == true,
              is_selected_xshift = true
              } 
      if conf.show_proj_ids == 1 then 
        obj['region_intidx'..idx] = { clear = true,
              x =obj.tr_listx+obj.rgnroww_idx,
              y = tr_y,
              w = obj.rgnroww_idxreal-1,
              h = obj.tr_h,
              fillback = fillback,
              fillback_colint = col0,--'col0,
              fillback_a = fillback_a,
              alpha_back =alpha_back,
              txt= data.regions[idx].markrgnindexnumber,
              txt_a = 1,
              align_txt = 16,
              fontsz = obj.GUI_fontsz2,
              show = show,
              is_selected = obj.selection[idx] and obj.selection[idx] == true,
              is_selected_xshift = true
              } 
      end
      obj['regionname'..idx] = { clear = true,
              x =obj.tr_listx+obj.rgnroww_idx+obj.rgnroww_idxreal,
              y = tr_y,
              w = obj.rgnroww_name-1,
              h = obj.tr_h,
              fillback = fillback,
              fillback_colint = col0,--'col0,
              fillback_a = fillback_a,
              alpha_back = alpha_back,
              txt= data.regions[idx].name,
              txt_a = 1,
              align_txt = 17,
              fontsz = obj.GUI_fontsz2,
              show = show,
              is_selected = obj.selection[idx] and obj.selection[idx] == true,
              is_selected_xshift = true,
              func = function() 
                        obj.selection = {}
                        obj.selection[idx] = true
                        refresh.GUI = true
                      end,
              func_trigCtrl = function() 
                        obj.selection[idx] = not obj.selection[idx]
                        refresh.GUI = true
                      end,
              func_R = function() 
                          local retval, new_name = GetUserInputs( 'Region name', 1, '', data.regions[idx].name )
                          if retval then
                            Undo_BeginBlock2( 0 )
                            SetProjectMarkerByIndex2( 0, idx-1, data.regions[idx].isrgn, data.regions[idx].rgnpos, data.regions[idx].rgnend, data.regions[idx].markrgnindexnumber, new_name, data.regions[idx].color, 0 )
                            Undo_EndBlock2( 0, conf.mb_title..': Change name', -1 )
                            data.regions[idx].name = new_name
                            Obj_MatchSearch(conf, obj, data, refresh, mouse)
                            refresh.GUI = true
                            refresh.data = true
                          end
                        end,
              func_trigAlt = function()
                                Undo_BeginBlock2( 0 )
                                DeleteProjectMarkerByIndex( 0, idx-1 )
                                Undo_EndBlock2( 0, conf.mb_title..': Remove', -1 )
                                refresh.GUI = true
                                refresh.data = true
                              end,
              } 
      obj['regionstart'..idx] = { clear = true,
              x =obj.tr_listx+obj.rgnroww_idx + obj.rgnroww_idxreal+obj.rgnroww_name,
              y = tr_y,
              w = obj.rgnroww_start-1,
              h = obj.tr_h,
              fillback = fillback,
              fillback_colint = col0,--'col0,
              fillback_a = fillback_a,
              alpha_back = alpha_back,
              txt= data.regions[idx].pos_format,
              txt_a = 1,
              align_txt = 16,
              fontsz = obj.GUI_fontsz2,
              show = show,
              is_selected = obj.selection[idx] and obj.selection[idx] == true,
              is_selected_xshift = true,
              } 
      
      if data.regions[idx].isrgn == true then
        obj['regionend'..idx] = { clear = true,
              x =obj.tr_listx+obj.rgnroww_idx + obj.rgnroww_idxreal+obj.rgnroww_name+obj.rgnroww_start,
              y = tr_y,
              w = obj.rgnroww_end-1,
              h = obj.tr_h,
              fillback = fillback,
              fillback_colint = col0,--'col0,
              fillback_a = fillback_a,
              alpha_back = alpha_back,
              txt= data.regions[idx].rgnend_format,
              txt_a = 1,
              align_txt = 16,
              fontsz = obj.GUI_fontsz2,
              show = show,
              is_selected = obj.selection[idx] and obj.selection[idx] == true,
              is_selected_xshift = true,
              } 
        obj['regionlen'..idx] = { clear = true,
              x =obj.tr_listx+obj.rgnroww_idx + obj.rgnroww_idxreal+obj.rgnroww_name+obj.rgnroww_start+obj.rgnroww_end,
              y = tr_y,
              w = obj.rgnroww_len-1,
              h = obj.tr_h,
              fillback = fillback,
              fillback_colint = col0,--'col0,
              fillback_a = fillback_a,
              alpha_back = alpha_back,
              txt= data.regions[idx].rgnlen_format,
              txt_a = 1,
              align_txt = 16,
              fontsz = obj.GUI_fontsz2,
              show = show,
              is_selected = obj.selection[idx] and obj.selection[idx] == true,
              is_selected_xshift = true,
              }               
      end
              
              
      ::skipnextrgn::            
      tr_y = tr_y + obj.tr_h--obj['regions'..idx].h
      ::skipnextrgn2:: 
    end 
    return   tr_y -   tr_y0, realcnt_idx  
  end 
  ------------------------------------------------------
  function Obj_MatchSearch(conf, obj, data, refresh, mouse)
    if obj.search_field_txt == '' then obj.selection = {} return end
    obj.selection = {}
    for i = 1, #data.regions do
      if data.regions[i].name:match(obj.search_field_txt) then obj.selection[i] = true end
    end
  end
  ------------------------------------------------------
  function Obj_Search(conf, obj, data, refresh, mouse)
    local retval, retvals_csv = GetUserInputs( 'Search regions', 1, '', obj.search_field_txt )
    if retval then 
      obj.search_field_txt = retvals_csv
      Obj_MatchSearch(conf, obj, data, refresh, mouse)
      refresh.GUI = true
    end
  end
  ------------------------------------------------------
  function Obj_TopLine(conf, obj, data, refresh, mouse) 
    local clear_w = 100
    local search_w = gfx.w-clear_w-obj.scroll_w
        obj.search_field = { clear = true,
              x =obj.scroll_w,
              y = 0,
              w = search_w-1,
              h = obj.menu_h-1,
              fillback = false,
              fillback_colint = col0,--'col0,
              fillback_a = fillback_a,
              alpha_back = 0.5,
              txt= 'Search: '..obj.search_field_txt,
              txt_a = 1,
              align_txt = 1,
              fontsz = obj.GUI_fontsz2,
              show = true,
              func = function ()Obj_Search(conf, obj, data, refresh, mouse) end
              }
        obj.search_clear = { clear = true,
              x =search_w+obj.scroll_w,--obj.scroll_w+search_w,
              y = 0,
              w = clear_w-3,
              h = obj.menu_h-1,
              fillback = false,
              fillback_colint = col0,--'col0,
              fillback_a = fillback_a,
              alpha_back = 0.5,
              txt= 'Clear',
              txt_a = 1,
              --align_txt = 16,
              fontsz = obj.GUI_fontsz2,
              show = true,
              func = function ()
                      obj.search_field_txt = ''
                      Obj_MatchSearch(conf, obj, data, refresh, mouse)
                      refresh.GUI = true
                    end
              }                
  end
  -----------------------------------------------
  function Obj_RegList_Head(conf, obj, data, refresh, mouse)
    local fillback_a = 0.9
    local alpha_back = 0.4
    local show  = true
    local tr_y = obj.menu_h
    local tr_h = obj.menu_h-1
      obj['region_idx_head'] = { clear = true,
              x =obj.tr_listx,
              y = tr_y,
              w = obj.rgnroww_idx-1,
              h = tr_h,
              fillback = fillback,
              fillback_colint = col0,--'col0,
              fillback_a = fillback_a,
              alpha_back =alpha_back,
              txt= 'ID',
              txt_a = 1,
              align_txt = 16,
              fontsz = obj.GUI_fontsz2,
              show = show,
              } 
      if conf.show_proj_ids == 1 then 
        obj['region_intidx_head'] = { clear = true,
              x =obj.tr_listx+obj.rgnroww_idx,
              y = tr_y,
              w = obj.rgnroww_idxreal-1,
              h = tr_h,
              fillback = fillback,
              fillback_colint = col0,--'col0,
              fillback_a = fillback_a,
              alpha_back =alpha_back,
              txt= 'rID',
              txt_a = 1,
              align_txt = 16,
              fontsz = obj.GUI_fontsz2,
              show = show,
              } 
      end
      obj['regionname_head'] = { clear = true,
              x =obj.tr_listx+obj.rgnroww_idx+obj.rgnroww_idxreal,
              y = tr_y,
              w = obj.rgnroww_name-1,
              h = tr_h,
              fillback = fillback,
              fillback_colint = col0,--'col0,
              fillback_a = fillback_a,
              alpha_back = alpha_back,
              txt= 'Name',
              txt_a = 1,
              --align_txt = 17,
              fontsz = obj.GUI_fontsz2,
              show = show,
              } 
      obj['regionstart_head'] = { clear = true,
              x =obj.tr_listx+obj.rgnroww_idx + obj.rgnroww_idxreal+obj.rgnroww_name,
              y = tr_y,
              w = obj.rgnroww_start-1,
              h =tr_h,
              fillback = fillback,
              fillback_colint = col0,--'col0,
              fillback_a = fillback_a,
              alpha_back = alpha_back,
              txt= 'Start',
              txt_a = 1,
              --align_txt = 16,
              fontsz = obj.GUI_fontsz2,
              show = show,
              } 
      obj['regionend_head'] = { clear = true,
              x =obj.tr_listx+obj.rgnroww_idx + obj.rgnroww_idxreal+obj.rgnroww_name+obj.rgnroww_start,
              y = tr_y,
              w = obj.rgnroww_end-1,
              h = tr_h,
              fillback = fillback,
              fillback_colint = col0,--'col0,
              fillback_a = fillback_a,
              alpha_back = alpha_back,
              txt= 'End',
              txt_a = 1,
              --align_txt = 16,
              fontsz = obj.GUI_fontsz2,
              show = show,
              } 
        obj['regionlen_head'] = { clear = true,
              x =obj.tr_listx+obj.rgnroww_idx + obj.rgnroww_idxreal+obj.rgnroww_name+obj.rgnroww_start+obj.rgnroww_end,
              y = tr_y,
              w = obj.rgnroww_len-1,
              h = tr_h,
              fillback = fillback,
              fillback_colint = col0,--'col0,
              fillback_a = fillback_a,
              alpha_back = alpha_back,
              txt= 'Length',
              txt_a = 1,
              --align_txt = 16,
              fontsz = obj.GUI_fontsz2,
              show = show,
              }  
  end 
