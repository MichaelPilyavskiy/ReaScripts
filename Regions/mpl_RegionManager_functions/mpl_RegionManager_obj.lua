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
    obj.fillback_a_list = 0.6
    
    
    -- colors    
    obj.GUIcol = { grey =    {0.5, 0.5,  0.5 },
                   white =   {1,   1,    1   },
                   red =     {1,   0.4,    0.4   },
                   red1 =     {0.8,   0.2,    0.2   },
                   red2 =     {0.6,   0.1,    0.1   },                   
                   green =   {0.5,   0.9,    0.6   },
                   black =   {0,0,0 }
                   }    
    
    
  end
---------------------------------------------------
  function OBJ_Update(conf, obj, data, refresh, mouse) 
    -- other
    obj.parsed_t = {}
    local str_parse = conf.sort_rows
    for val in str_parse:gmatch('[^%s]+') do 
      obj.parsed_t[#obj.parsed_t+1] = {name = val:match('#([A-Z,a-z]+)') , width = val:match('%d+')}
    end
    
    -- font
    obj.GUI_font = 'Calibri'
    obj.GUI_fontsz = 19 
    obj.GUI_fontsz2 = conf.GUI_fontsz2 
    obj.GUI_fontsz5 = 17
    obj.GUI_fontsz3 = 13
    obj.GUI_fontsz_tooltip = 13
    if GetOS():find("OSX") then 
      obj.GUI_fontsz = obj.GUI_fontsz - 6 
      obj.GUI_fontsz2 = obj.GUI_fontsz2 - 5 
      obj.GUI_fontsz5 = obj.GUI_fontsz5 - 5 
      obj.GUI_fontsz3 = obj.GUI_fontsz3 - 4
      obj.GUI_fontsz_tooltip = obj.GUI_fontsz_tooltip - 4
    end 
    
    
    -- define
    for key in pairs(obj) do if type(obj[key]) == 'table' and obj[key].clear then obj[key] = {} end end  
   
    local min_w = 200
    local min_h = 100
    local reduced_view = gfx.h  <= min_h
    gfx.w  = math.max(min_w,gfx.w)
    gfx.h  = math.max(min_h,gfx.h)
    
    obj.trlistw = math.floor(gfx.w - obj.scroll_w-obj.offs)-- - obj.get_w)*0.7)
    obj.tr_listh = gfx.h-obj.menu_h-obj.offs

    obj.tr_listx = 0--obj.scroll_w
    obj.tr_listy = obj.menu_h *2
    obj.tr_listw = obj.trlistw
    
    obj.rgnroww_idx = 25
    local row_w =55
    obj.rgnroww_start = row_w
    obj.rgnroww_end = row_w
    obj.rgnroww_len = row_w
    obj.rgnroww_name = obj.tr_listw - obj.rgnroww_idx*2-obj.rgnroww_start-obj.rgnroww_end-obj.rgnroww_len
    
    
    Obj_Menu(conf, obj, data, refresh, mouse) 
    Obj_Scroll(conf, obj, data, refresh, mouse)
    Obj_TopLine(conf, obj, data, refresh, mouse)
    Obj_RegList_Head(conf, obj, data, refresh, mouse)
    Obj_SortMapping(conf, obj, data, refresh, mouse) 
    local comlist_h, realcnt = Obj_RegList(conf, obj, data, refresh, mouse, true)
    obj.realcnt = realcnt
    if comlist_h then 
      obj.comlist_h = comlist_h
      Obj_RegList(conf, obj, data, refresh, mouse)
    end
    for key in pairs(obj) do if type(obj[key]) == 'table' then  obj[key].context = key  end end    
  end
    -----------------------------------------------  
  function Obj_SortMapping(conf, obj, data, refresh, mouse)
    obj.mapping = {}  
    if conf.sort_row_key == '' then
      for i = 1, #data.regions do obj.mapping[#obj.mapping+1] = {nil,i} end
     else
      local key = conf.sort_row_key
      local tnames = {}
      for i = 1, #data.regions do table.insert(tnames, {data.regions[i][key],i} )  end
      local f = function(t,a,b) return t[b][1] > t[a][1] end
      if conf.sort_rowflag == 1 then f = function(t,a,b) return t[b][1] < t[a][1] end end
      for k,v in spairs(tnames, f) do obj.mapping[#obj.mapping+1] = tnames[k] end      
    end
  end
    -----------------------------------------------
    function Obj_Menu(conf, obj, data, refresh, mouse)
        obj.showflagreg = { clear = true,
                          x = gfx.w-obj.scroll_w,
                          y = obj.menu_h,
                          w = obj.scroll_w-1,
                          h = obj.menu_h,
                          col = 'white',
                          txt= 'R',
                          show = true,
                          fontsz = obj.GUI_fontsz5,
                          a_frame = 0,
                          is_selected=conf.showflag&1==1,
                          func =  function() 
                                    conf.showflag = BinaryToggle(conf.showflag, 0)
                                    refresh.conf = true 
                                    refresh.GUI = true
                                    --refresh.data = true
                                  end  }  
        obj.showflagmark = { clear = true,
                          x = gfx.w-obj.scroll_w,
                          y = obj.menu_h*2,
                          w = obj.scroll_w-1,
                          h = obj.menu_h,
                          col = 'white',
                          txt= 'M',
                          show = true,
                          fontsz = obj.GUI_fontsz5,
                          a_frame = 0,
                          is_selected=conf.showflag&2==2,
                          func =  function() 
                                    conf.showflag = BinaryToggle(conf.showflag, 1)
                                    refresh.conf = true 
                                    refresh.GUI = true
                                    --refresh.data = true
                                  end  }                             
        obj.menu = { clear = true,
                          x = gfx.w-obj.scroll_w,
                          y = 0,
                          w = obj.scroll_w-1,
                          h = obj.menu_h-1,
                          col = 'white',
                          txt= '>',
                          show = true,
                          fontsz = obj.GUI_fontsz5,
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
  - Enter: <see shortcuts>
  - Ctrl+Enter: <see shortcuts>
  - Shift S: search tracks
  - Name LMB: select
  - Name Alt+LMB: remove
  - Name Ctrl+LMB: add to selection
  - Name RMB: change name 
                    ]])
                  end  } ,           
        { str = '#Options'},
        { str = '>Shortcuts'},          
        
        { str = 'Enter: set edit cursor at region start',
          func = function() 
                    conf.shortcut_enter = BinaryToggle(conf.shortcut_enter, 0)
                    refresh.conf = true
                end,
          state = conf.shortcut_enter&1 == 1 },    
        { str = 'Enter: set time selection at region edges|',
          func = function() 
                    conf.shortcut_enter = BinaryToggle(conf.shortcut_enter, 1)
                    refresh.conf = true
                end,
          state = conf.shortcut_enter&2 == 2 }, 
        { str = 'Ctrl+Enter: smooth seek to regon position|',
          func = function() 
                    conf.shortcut_ctrlenter = BinaryToggle(conf.shortcut_ctrlenter, 0)
                    refresh.conf = true
                end,
          state = conf.shortcut_ctrlenter&1 == 1 },           
        { str = 'Space: play/stop',
          func = function() 
                    conf.shortcut_play2 = BinaryToggle(conf.shortcut_play2, 0)
                    refresh.conf = true
                end,
          state = conf.shortcut_play2&1 == 1 },           
        { str = 'Num0: play/stop|<',
          func = function() 
                    conf.shortcut_play2 = BinaryToggle(conf.shortcut_play2, 1)
                    refresh.conf = true
                end,
          state = conf.shortcut_play2&2 == 2 },           
        { str = 'Define Rows',
          func = function() 
                    local retval, retstr = GetUserInputs( 'Define Rows', 1, ',extrawidth=200', conf.sort_rows )
                    if retval then 
                      conf.sort_rows = retstr
                      refresh.GUI = true
                    end
                end },    
        { str = 'Reset Rows',
          func = function() 
                    conf.sort_rows = '#sel #id #realid #name230 #start80 #end60 #len60'
                    refresh.GUI = true
                    refresh.conf = true
                end },                 
        { str = 'Enable dynamic GUI refresh (takes more CPU)',
          func = function() 
                    conf.dyn_refresh = math.abs(1-conf.dyn_refresh) 
                    refresh.GUI = true
                end ,
          state = conf.dyn_refresh == 1},            
        { str = 'Change fontsize',
          func = function()       
                          local retval, fsz = GetUserInputs( 'Fontsize', 1, '', conf.GUI_fontsz2 )
                          if retval then        
                            conf.GUI_fontsz2 = fsz
                            refresh.conf = true
                            refresh.GUI = true
                          end
                end
        },
        { str = 'Use search as filter',
          func = function() 
                    conf.search_filt = math.abs(1-conf.search_filt) 
                    refresh.conf = true
                end ,
          state = conf.search_filt == 1},          
        
        
        
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
                        x = gfx.w-obj.scroll_w,
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
                        x = gfx.w-obj.scroll_w,--obj.offs,
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
  function Obj_GetMappedIdx(obj,cur_idx)
    for i = 1, #obj.mapping do if obj.mapping[i][2] == cur_idx then return i end end
  end
  -----------------------------------------------
  function Obj_Selection_NextPrev(conf, obj, data, refresh, mouse, inc) 
    local src_idx = Obj_Selection_GetFirst(conf, obj, data, refresh, mouse)
    cur_idx = Obj_GetMappedIdx(obj,src_idx)
    --[[msg(src_idx)
    msg(cur_idx)
    msg('=')]]
    if not cur_idx then 
      if obj.mapping[1] and obj.mapping[1][2] then  obj.selection[obj.mapping[1][2]] = true cur_idx = 1  end
      return 
    end 
    
    --local new_idx = lim(cur_idx + 1*inc, 1, #data.regions)
    local fin = 1 if inc > 0 then fin =  #data.regions end
    for i = cur_idx+inc, fin, inc do
      local realid = obj.mapping[i][2]
      if (conf.showflag&1==1 and data.regions[realid].isrgn == true) or (conf.showflag&2==2 and data.regions[realid].isrgn == false) then
        new_idx = obj.mapping[i][2]
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
  function Obj_RegListRow_sel(conf, obj, data, refresh, mouse, xpos, tr_y, idx, fillback, fillback_a, col0, alpha_back, realcnt_idx, show)
    obj['region_sel'..idx] = { clear = true,
          x =xpos,
          y = tr_y,
          w = obj.tr_h-1,
          h = obj.tr_h,
          fillback = fillback,
          fillback_colint = col0,--'col0,
          fillback_a = fillback_a,
          alpha_back =alpha_back,
          txt= '',
          txt_a = 1,
          align_txt = 16,
          fontsz = obj.GUI_fontsz2,
          show = show,
          is_selected = obj.selection[idx] and obj.selection[idx] == true,
          is_selected_xshift = true,
          check = data.regions[idx] and data.regions[idx].isundereditpos,
          func = function() 
                    if conf.shortcut_enter&1==1 then SetEditCurPos( data.regions[idx].rgnpos, true, true ) end
                    if conf.shortcut_enter&2==2 then GetSet_LoopTimeRange2( 0, true, true, data.regions[idx].rgnpos, data.regions[idx].rgnend, true )end
                  end,
          func_trigCtrl = function()
                    if conf.shortcut_ctrlenter&1==1 then GoToRegion( 0, data.regions[idx].rgn_idx, true ) end
                  end,
          }
    return obj.tr_h
  end 
  -----------------------------------------------
  function Obj_RegListRow_id(conf, obj, data, refresh, mouse, xpos, tr_y, idx, fillback, fillback_a, col0, alpha_back, realcnt_idx, show)
    obj['region_idx'..idx] = { clear = true,
          x =xpos,
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
    return obj.rgnroww_idx
  end    
 
  -----------------------------------------------
  function Obj_RegListRow_realid(conf, obj, data, refresh, mouse, xpos, tr_y, idx, fillback, fillback_a, col0, alpha_back, realcnt_idx, show)  
    if not data.regions[idx] then return 0 end
    local tp = 'R' 
    if data.regions[idx].isrgn == false then tp = 'M' end
    obj['region_intidx'..idx] = { clear = true,
        x =xpos,
        y = tr_y,
        w = obj.rgnroww_idx-1,
        h = obj.tr_h,
        fillback = fillback,
        fillback_colint = col0,--'col0,
        fillback_a = fillback_a,
        alpha_back =alpha_back,
        txt= tp..data.regions[idx].markrgnindexnumber,
        txt_a = 1,
        align_txt = 16,
        fontsz = obj.GUI_fontsz2,
        show = show,
        is_selected = obj.selection[idx] and obj.selection[idx] == true,
        is_selected_xshift = true
        } 
    return obj.rgnroww_idx
  end  
  -----------------------------------------------
  function Obj_RegListRow_name(conf, obj, data, refresh, mouse, xpos, tr_y, idx, fillback, fillback_a, col0, alpha_back, realcnt_idx, show, custwidth)
    if not data.regions[idx] then return 0 end
    obj['regionname'..idx] = { clear = true,
              x =xpos,
              y = tr_y,
              w = custwidth-1,
              h = obj.tr_h,
              fillback = false,
              fillback_colint = col0,--'col0,
              fillback_a = fillback_a,
              alpha_back = obj.but_aback,
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
                          local retval, new_name = GetUserInputs( 'Region name', 1, ',extrawidth=200', data.regions[idx].name )
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
    return custwidth
  end
  -----------------------------------------------
  function Obj_RegListRow_start(conf, obj, data, refresh, mouse, xpos, tr_y, idx, fillback, fillback_a, col0, alpha_back, realcnt_idx, show, custwidth)  
    if not data.regions[idx] then return 0 end
    obj['regionstart'..idx] = { clear = true,
          x =xpos,
          y = tr_y,
          w = custwidth-1,
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
    return custwidth
  end  
  -----------------------------------------------
  function Obj_RegListRow_end(conf, obj, data, refresh, mouse, xpos, tr_y, idx, fillback, fillback_a, col0, alpha_back, realcnt_idx, show, custwidth)   
    if not data.regions[idx] then return 0 end
    if data.regions[idx].isrgn == false then return 0 end
    obj['regionend'..idx] = { clear = true,
        x =xpos,
        y = tr_y,
        w = custwidth-1,
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
    return custwidth
  end   
  -----------------------------------------------
  function Obj_RegListRow_len(conf, obj, data, refresh, mouse, xpos, tr_y, idx, fillback, fillback_a, col0, alpha_back, realcnt_idx, show, custwidth)   
    if not data.regions[idx] then return 0 end
    if data.regions[idx].isrgn == false then return 0 end
    obj['regionlen'..idx] = { clear = true,
        x =xpos,
        y = tr_y,
        w = custwidth-1,
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
    return custwidth
  end   
  -----------------------------------------------
  function Obj_RegList(conf, obj, data, refresh, mouse, gethonly)
    local alpha_back = 0.1
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
    local fillback_a = 1
    -- test com_w
    local idx = 1 -- mapped
    local xpos0 = 0
    for i=1, #obj.parsed_t do
      local key = obj.parsed_t[i].name
      local custwidth = obj.parsed_t[i].width
      if _G['Obj_RegListRow_'..key] and not (key == 'sel' and conf.dyn_refresh==0 ) then
        local retw = _G['Obj_RegListRow_'..key](conf, obj, data, refresh, mouse, xpos0, tr_y, idx, fillback, fillback_a, col0, alpha_back, realcnt_idx, show, custwidth)
        xpos0 = xpos0 + retw
      end
    end
    obj.ratio_exp = obj.tr_listw / xpos0
    
    for idx0=1,#data.regions do
      local idx = obj.mapping[idx0][2] -- mapped
      if not data.regions[idx].show then goto skipnextrgn2 end
      local fillback, col0 = true, data.regions[idx].color
      if col0==0 then 
        local r = 255 col0 = ColorToNative( r, r, r ) fillback_a = 0.44 fillback = false
       --[[else
        local r, g, b = reaper.ColorFromNative( col0 )
        local pow = 1.2
        col0 = ColorToNative( math.floor(((r/255)^pow)*255), math.floor(((g/255)^pow)*255), math.floor(((b/255)^pow)*255) )]]
      end
      local show = true 
      if (tr_y < obj.tr_listy or tr_y > obj.tr_listy + obj.tr_listh) then show=false end--goto skipnextrgn end 
      if not ((conf.showflag&1==1 and data.regions[idx].isrgn == true) or (conf.showflag&2==2 and data.regions[idx].isrgn == false)) then goto skipnextrgn2 end 
      realcnt_idx = realcnt_idx + 1
      local xpos = obj.tr_listx
      
      for i=1, #obj.parsed_t do
        local key = obj.parsed_t[i].name
        local custwidth = obj.parsed_t[i].width
        if custwidth then custwidth = math.floor(custwidth*obj.ratio_exp) end
        if _G['Obj_RegListRow_'..key] and not (key == 'sel' and conf.dyn_refresh==0 ) then
          local retw = _G['Obj_RegListRow_'..key](conf, obj, data, refresh, mouse, xpos, tr_y, idx, fillback, obj.fillback_a_list, col0, alpha_back, realcnt_idx, show, custwidth)
          --if custwidth then xpos = xpos + retw*obj.ratio_exp else xpos = xpos + retw end
          xpos = xpos + retw
        end
      end
      
      ::skipnextrgn::            
      tr_y = tr_y + obj.tr_h--obj['regions'..idx].h
      ::skipnextrgn2:: 
    end 
    return   tr_y -   tr_y0, realcnt_idx  
  end 
  ------------------------------------------------------
  function Obj_MatchSearch(conf, obj, data, refresh, mouse) 
    obj.selection = {}
    if conf.search_filt == 0 then 
      if conf.search_text == '' then return end
      for i = 1, #data.regions do data.regions[i].show = true if data.regions[i].name:lower():match(conf.search_text) then obj.selection[i] = true end end
     else
      for i = 1, #data.regions do data.regions[i].show = conf.search_text == '' or (conf.search_text ~= '' and data.regions[i].name:lower():match(conf.search_text)) end
    end
  end
  ------------------------------------------------------
  function Obj_Search(conf, obj, data, refresh, mouse)
    local retval, retvals_csv = GetUserInputs( 'Search regions', 1, ',extrawidth=200', conf.search_text)-- obj.search_field_txt )
    if retval then 
      conf.search_text = retvals_csv:lower()
      Obj_MatchSearch(conf, obj, data, refresh, mouse)
      refresh.GUI = true
      refresh.conf = true
    end
  end
  ------------------------------------------------------
  function Obj_TopLine(conf, obj, data, refresh, mouse) 
    local clear_w = 100
    local add_w = 100
    local search_w = gfx.w-clear_w-obj.scroll_w-add_w
        obj.search_field = { clear = true,
              x =0,
              y = 0,
              w = search_w-1,
              h = obj.menu_h-1,
              fillback = false,
              fillback_colint = col0,--'col0,
              fillback_a = fillback_a,
              alpha_back = 0.5,
              txt= 'Search: '..conf.search_text,
              txt_a = 1,
              align_txt = 1,
              fontsz = obj.GUI_fontsz5,
              show = true,
              func = function ()Obj_Search(conf, obj, data, refresh, mouse) end
              }
        obj.search_clear = { clear = true,
              x =search_w,--obj.scroll_w+search_w,
              y = 0,
              w = clear_w-1,
              h = obj.menu_h-1,
              fillback = false,
              fillback_colint = col0,--'col0,
              fillback_a = fillback_a,
              alpha_back = 0.5,
              txt= 'Clear',
              txt_a = 1,
              --align_txt = 16,
              fontsz = obj.GUI_fontsz5,
              show = true,
              func = function ()
                      conf.search_text = ''
                      Obj_MatchSearch(conf, obj, data, refresh, mouse)
                      refresh.GUI = true
                      refresh.conf = true
                    end
              } 
        obj.add_fromts = { clear = true,
              x =search_w+clear_w,--obj.scroll_w+search_w,
              y = 0,
              w = add_w-1,
              h = obj.menu_h-1,
              fillback = false,
              fillback_colint = col0,--'col0,
              fillback_a = fillback_a,
              alpha_back = 0.5,
              txt= 'Add region',
              txt_a = 1,
              --align_txt = 16,
              fontsz = obj.GUI_fontsz5,
              show = true,
              func = function ()
                      Action(40306)--Markers: Insert region from time selection and edit...
                    end
              }               
  end
  -----------------------------------------------
  function Obj_RegListHeadRow_sel(conf, obj, data, refresh, mouse, xpos, tr_y, tr_h, fillback, fillback_a, col0, alpha_back, custwidth)
     obj['region_sel_head'] = { clear = true,
              x = xpos,
              y = tr_y,
              w = tr_h-1,
              h = tr_h,
              fillback = false,
              fillback_colint = col0,--'col0,
              fillback_a = 0.9,
              alpha_back =0,
              txt= '',
              txt_a = 1,
              align_txt = 16,
              fontsz = obj.GUI_fontsz2,
              show = true,
              --[[func = function()
                        conf.sort_row_key = ''
                        conf.sort_rowflag = 0
                        refresh.GUI = true
                        refresh.conf = true
                      end ]]             
              } 
    return tr_h+3
  end 
  -----------------------------------------------
  function Obj_RegListHeadRow_id(conf, obj, data, refresh, mouse, xpos, tr_y, tr_h, fillback, fillback_a, col0, alpha_back, custwidth)
     obj['region_idx_head'] = { clear = true,
              x = xpos,
              y = tr_y,
              w = obj.rgnroww_idx-1,
              h = tr_h,
              fillback = fillback,
              fillback_colint = col0,--'col0,
              fillback_a = 0.9,
              --alpha_back =alpha_back,
              txt= '#',
              txt_a = 1,
              align_txt = 16,
              fontsz = obj.GUI_fontsz2,
              show = true,
              func = function()
                        conf.sort_row_key = ''
                        conf.sort_rowflag = 0
                        refresh.GUI = true
                        refresh.conf = true
                      end              
              } 
    return obj.rgnroww_idx
  end    
  -----------------------------------------------
  function Obj_RegListHeadRow_realid(conf, obj, data, refresh, mouse, xpos, tr_y, tr_h, fillback, fillback_a, col0, alpha_back, custwidth)
    local addtxt = ''
    local alpha_back = obj.but_aback
    if conf.sort_row_key == 'markrgnindexnumber' then 
      alpha_back = 0.8
      if conf.sort_rowflag == 0 then addtxt = '↓' else addtxt = '↑'  end
    end
    obj['region_idxreal_head'] = { clear = true,
              x = xpos,
              y = tr_y,
              w = obj.rgnroww_idx-1,
              h = tr_h,
              fillback = fillback,
              fillback_colint = col0,--'col0,
              fillback_a = fillback_a,
              alpha_back =alpha_back,
              txt= 'rID',
              txt_a = 1,
              align_txt = 16,
              fontsz = obj.GUI_fontsz2,
              show = true,
              func = function()
                        conf.sort_row_key = 'markrgnindexnumber'
                        conf.sort_rowflag = 0
                        refresh.GUI = true
                        refresh.conf = true
                      end              
              } 
    return obj.rgnroww_idx
  end   
  -----------------------------------------------
  function Obj_RegListHeadRow_name(conf, obj, data, refresh, mouse, xpos, tr_y, tr_h, fillback, fillback_a, col0, alpha_back, custwidth)
    local addtxt = ''
    local alpha_back = obj.but_aback
    if conf.sort_row_key == 'name' then 
      alpha_back = 0.8
      if conf.sort_rowflag == 0 then addtxt = '↓' else addtxt = '↑'  end
    end
    obj['region_idxname_head'] = { clear = true,
              x = xpos,
              y = tr_y,
              w = custwidth-1,
              h = tr_h,
              fillback = fillback,
              fillback_colint = col0,--'col0,
              fillback_a = fillback_a,
              alpha_back =alpha_back,
              txt= 'Name'..addtxt,
              txt_a = 1,
              --align_txt = 16,
              fontsz = obj.GUI_fontsz2,
              show = true,
   
          func = function()
                    if conf.sort_row_key == 'name' then
                      conf.sort_rowflag = math.abs(1-conf.sort_rowflag)
                     else
                      conf.sort_row_key = 'name'
                    end
                    refresh.GUI = true
                    refresh.conf = true
                  end                      
              } 
    return custwidth
  end   
  -----------------------------------------------
  function Obj_RegListHeadRow_start(conf, obj, data, refresh, mouse, xpos, tr_y, tr_h, fillback, fillback_a, col0, alpha_back, custwidth)
    local addtxt = ''
    local alpha_back = obj.but_aback
    if conf.sort_row_key == 'rgnpos' then 
      alpha_back = 0.8
      if conf.sort_rowflag == 0 then addtxt = '↓' else addtxt = '↑'  end
    end
    obj['region_idxstart_head'] = { clear = true,
              x = xpos,
              y = tr_y,
              w = custwidth-1,
              h = tr_h,
              fillback = fillback,
              fillback_colint = col0,--'col0,
              fillback_a = fillback_a,
              alpha_back =alpha_back,
              txt= 'Start'..addtxt,
              txt_a = 1,
              --align_txt = 16,
              fontsz = obj.GUI_fontsz2,
              show = true,
   
          func = function()
                    if conf.sort_row_key == 'rgnpos' then
                      conf.sort_rowflag = math.abs(1-conf.sort_rowflag)
                     else
                      conf.sort_row_key = 'rgnpos'
                    end
                    refresh.GUI = true
                    refresh.conf = true
                  end                      
              } 
    return custwidth
  end 
  -----------------------------------------------
  function Obj_RegListHeadRow_end(conf, obj, data, refresh, mouse, xpos, tr_y, tr_h, fillback, fillback_a, col0, alpha_back, custwidth)
    local addtxt = ''
    local alpha_back = obj.but_aback
    if conf.sort_row_key == 'rgnend' then 
      alpha_back = 0.8
      if conf.sort_rowflag == 0 then addtxt = '↓' else addtxt = '↑'  end
    end
    obj['region_idxend_head'] = { clear = true,
              x = xpos,
              y = tr_y,
              w = custwidth-1,
              h = tr_h,
              fillback = fillback,
              fillback_colint = col0,--'col0,
              fillback_a = fillback_a,
              alpha_back =alpha_back,
              txt= 'End'..addtxt,
              txt_a = 1,
              --align_txt = 16,
              fontsz = obj.GUI_fontsz2,
              show = true,
   
          func = function()
                    if conf.sort_row_key == 'rgnend' then
                      conf.sort_rowflag = math.abs(1-conf.sort_rowflag)
                     else
                      conf.sort_row_key = 'rgnend'
                    end
                    refresh.GUI = true
                    refresh.conf = true
                  end                      
              } 
    return custwidth
  end   
  -----------------------------------------------
  function Obj_RegListHeadRow_len(conf, obj, data, refresh, mouse, xpos, tr_y, tr_h, fillback, fillback_a, col0, alpha_back, custwidth)
    local addtxt = ''
    local alpha_back = obj.but_aback
    if conf.sort_row_key == 'rgnlen' then 
      alpha_back = 0.8
      if conf.sort_rowflag == 0 then addtxt = '↓' else addtxt = '↑'  end
    end
    obj['region_idxlen_head'] = { clear = true,
              x = xpos,
              y = tr_y,
              w = custwidth-1,
              h = tr_h,
              fillback = fillback,
              fillback_colint = col0,--'col0,
              fillback_a = fillback_a,
              alpha_back =alpha_back,
              txt= 'Length'..addtxt,
              txt_a = 1,
              --align_txt = 16,
              fontsz = obj.GUI_fontsz2,
              show = true,
   
          func = function()
                    if conf.sort_row_key == 'rgnlen' then
                      conf.sort_rowflag = math.abs(1-conf.sort_rowflag)
                     else
                      conf.sort_row_key = 'rgnlen'
                    end
                    refresh.GUI = true
                    refresh.conf = true
                  end                      
              } 
    return custwidth
  end     
  -----------------------------------------------
  function Obj_RegList_Head(conf, obj, data, refresh, mouse)
    local fillback_a = 1
    local alpha_back_src = 0.4
    local tr_y = obj.menu_h
    local tr_h = obj.menu_h-1
    
    -- test com_w
    local idx = 1 -- mapped
    local xpos0 = 0
    for i=1, #obj.parsed_t do
      local key = obj.parsed_t[i].name
      local custwidth = obj.parsed_t[i].width
      if _G['Obj_RegListHeadRow_'..key] and not (key == 'sel' and conf.dyn_refresh==0 ) then
        local retw = _G['Obj_RegListHeadRow_'..key](conf, obj, data, refresh, mouse, xpos, tr_y, tr_h, fillback, fillback_a, col0, alpha_back, custwidth)
        xpos0 = xpos0 + retw
      end
    end
    obj.ratio_exp = obj.tr_listw / xpos0
    
    local xpos = obj.tr_listx
    for i=1, #obj.parsed_t do
      local key = obj.parsed_t[i].name
      local custwidth = obj.parsed_t[i].width
      if custwidth then custwidth = math.floor(custwidth*obj.ratio_exp) end
      if _G['Obj_RegListHeadRow_'..key] and not (key == 'sel' and conf.dyn_refresh==0 ) then
        local retw = _G['Obj_RegListHeadRow_'..key](conf, obj, data, refresh, mouse, xpos, tr_y, tr_h, fillback, fillback_a, col0, alpha_back, custwidth)
        xpos = xpos + retw
      end
    end
      
      do return end
      

      local addtxt = ''
      local alpha_back = alpha_back_src
      if conf.sort_row == 4 then  
        alpha_back = 0.8
        if conf.sort_rowflag == 0 then addtxt = '↓' else addtxt = '↑'  end
      end              
        obj['regionlen_head'] = { clear = true,
              x =obj.tr_listx+obj.rgnroww_idx + obj.rgnroww_idxreal+obj.rgnroww_name+obj.rgnroww_start+obj.rgnroww_end,
              y = tr_y,
              w = obj.rgnroww_len-1,
              h = tr_h,
              fillback = fillback,
              fillback_colint = col0,--'col0,
              fillback_a = fillback_a,
              alpha_back = alpha_back,
              txt= 'Length'..addtxt,
              txt_a = 1,
              --align_txt = 16,
              fontsz = obj.GUI_fontsz2,
              show = show,
              func = function()
                        if conf.sort_row == 4 then
                          conf.sort_rowflag = math.abs(1-conf.sort_rowflag)
                         else
                          conf.sort_row = 4
                        end
                        refresh.GUI = true
                        refresh.conf = true
                      end
              }  
  end 
