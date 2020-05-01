-- @description LearnEditor_obj
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
    obj.but_remove_w = 20
    --[[obj.get_w = 60
    obj.collapsed_states = {}
    
    obj.menu_w = 120
    --obj.bottom_line_h = 30
    obj.y_shift = 0]]
    obj.x_indent = 10
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
    obj.tr_listy = 0--obj.menu_h 
    obj.tr_listw = obj.trlistw-1
    obj.tr_h = 20
    
    obj.param_w_ratio = 0.4
    obj.remove_b_wide_w=50
    
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
  --[[function Obj_ParamList1(conf, obj, data, refresh, mouse, build_t)
    local alpha_back_entries = 0.3
    -- h - obj.menu_h from  top and bottom
    
    local r_count = 0
    for i = 1, #build_t do
      if build_t[i].show > 0 then r_count = r_count + build_t[i].show end
    end
    local y_shift = 0
    local com_list_h = obj.tr_h *(r_count-1)
    if com_list_h > obj.tr_listh then 
      obj.y_shift = obj.scroll_val * com_list_h
    end
    
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
                obj.scroll_val = lim(obj.scroll_val + (50/com_list_h)*mult) refresh.GUI = true 
              end}    
              do return end
    local i_real = 1
    local ind_w = 10
    
    for i = 1, #build_t do
      local tr_y = obj.tr_listy - y_shift+ obj.offs + obj.tr_h*(i_real-1)
      local r = 90 
      local show_cond= (tr_y > obj.tr_listy and  tr_y + obj.tr_h < obj.tr_listy + obj.tr_listh) and build_t[i].show > 0
      if build_t[i].show then i_real = i_real + build_t[i].show end
      local tr_x_ind = build_t[i].level * ind_w
      local tr_w = math.floor(obj.tr_listw)-tr_x_ind
      if build_t[i].tpobj==3 and build_t[i].collapsed == false then tr_w = math.floor(obj.tr_listw) - tr_x_ind - obj.trw_area1_com end
      if show_cond then
        local disable_blitback,colint = true
        if build_t[i].colint then
          disable_blitback = false
          colint = build_t[i].colint
        end
        local tr_w0 = tr_w if build_t[i].level == 2 then tr_w = tr_w-obj.but_remove_w end
        obj['paramdata'..i] = { clear = true,
              x =obj.tr_listx+tr_x_ind,
              y = tr_y,
              w = tr_w0-1,
              h = math.ceil(obj.tr_h*build_t[i].show),
              fillback = true,
              fillback_colint = colint,--'col0,
              fillback_a = 0.7,
              alpha_back = build_t[i].alpha_back,
              txt= build_t[i].txt,
              txt_a = build_t[i].txt_a,
              txt_col = build_t[i].txt_col,
              txt_colint =build_t[i].txt_colint,
              show = show_cond,
              fontsz = build_t[i].font, 
              aligh_txt = build_t[i].align_txt,
              func =  build_t[i].func,
              is_selected = build_t[i].is_selected ,
              --disable_blitback = disable_blitback,
              }
        if build_t[i].level == 2 then         
          obj['paramdata_remove'..i] = { clear = true,
              x =obj.tr_listx+tr_x_ind+tr_w,
              y = tr_y,
              w = obj.but_remove_w,
              h = math.ceil(obj.tr_h*build_t[i].show),
              fillback = true,
              fillback_colstr = 'red',--'col0,
              fillback_a = 0.3,
              alpha_back = build_t[i].alpha_back,
              txt= 'X',
              txt_a = build_t[i].txt_a,
              show = show_cond,
              fontsz = build_t[i].font, 
              
              is_selected = build_t[i].is_selected ,
              func =  function() 
                        Undo_BeginBlock2( 0 )
                        Data_ModifyLearn(conf, data, build_t[i].data_trid,build_t[i].data_fxid,build_t[i].data_paramid, true )
                        Data_ModifyMod(conf, data, build_t[i].data_trid,build_t[i].data_fxid,build_t[i].data_paramid, true )
                        if conf.refresh_on_psc ==0 then DataReadProject(conf, obj, data, refresh, mouse) end
                        Undo_EndBlock2( 0,conf.mb_title..': Remove Learn', -1 )
                        refresh.data = true
                        refresh.GUI = false
                      end
              }
        end              
        if build_t[i].tpobj ~= 3 or build_t[i].collapsed == true then goto skip_to_nextparam   end
        if not build_t[i].has_learn then goto skip_to_parammod   end
        
        -- table entries
        local entr_id = 0
        entr_id = Obj_ParamList_SubEntry(conf, obj, data, refresh, mouse, build_t, 1, entr_id, i, show_cond, tr_y,
                                        build_t[i].txt_MIDI,
                                        build_t[i].func_MIDI,
                                        'MIDI')
        entr_id = Obj_ParamList_SubEntry(conf, obj, data, refresh, mouse, build_t, 2, entr_id, i, show_cond, tr_y,
                                        build_t[i].txt_OSC,
                                        build_t[i].func_OSC,
                                        'OSC') 
        local flags_txt = '-'
        if build_t[i].flags_learn&1==1 then 
          flags_txt = 'selected track'
         elseif build_t[i].flags_learn&4==4 then 
          flags_txt = 'focused FX'
         elseif build_t[i].flags_learn&20==20 then 
          flags_txt = 'visible FX' 
        end
        entr_id = Obj_ParamList_SubEntry(conf, obj, data, refresh, mouse, build_t, 4, entr_id, i, show_cond, tr_y,
                                        flags_txt,
                                        build_t[i].func_flags1,
                                        'flagvisible')  
        local flags_txt = '-'
        if build_t[i].flags_learn&2==2 then 
          flags_txt = 'Soft takeover'
         else  flags_txt = '-'
        end                                                                                 
        entr_id = Obj_ParamList_SubEntry(conf, obj, data, refresh, mouse, build_t, 8, entr_id, i, show_cond, tr_y,
                                        flags_txt,
                                        build_t[i].func_flags2,
                                        'flagST')  
        local flagsMIDI_txt = '-'
        if build_t[i].flagsMIDI==0  then 
          flagsMIDI_txt = 'Absolute'
         elseif build_t[i].flagsMIDI==4 then 
          flagsMIDI_txt = 'Relative 1'
         elseif build_t[i].flagsMIDI==8 then 
          flagsMIDI_txt = 'Relative 2'    
         elseif build_t[i].flagsMIDI==12 then 
          flagsMIDI_txt = 'Relative 3'    
         elseif build_t[i].flagsMIDI==16 then 
          flagsMIDI_txt = 'Toggle'                            
        end                                                                                 
        entr_id = Obj_ParamList_SubEntry(conf, obj, data, refresh, mouse, build_t, 16, entr_id, i, show_cond, tr_y,
                                        flagsMIDI_txt,
                                        build_t[i].func_flagsMIDI,
                                        'func_flagsMIDI') 
        ::skip_to_parammod::                                        
        ::skip_to_nextparam::              
      end
    end
  end    ]]
    -----------------------------------------------
    function Obj_Menu(conf, obj, data, refresh, mouse)
      --showflag
        obj.showflaglearn = { clear = true,
                          x = 0,
                          y = obj.menu_h,
                          w = obj.scroll_w-1,
                          h = obj.menu_h,
                          col = 'white',
                          txt= 'LRN',
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
        obj.showflagmod = { clear = true,
                          x = 0,
                          y = obj.menu_h*2,
                          w = obj.scroll_w-1,
                          h = obj.menu_h,
                          col = 'white',
                          txt= 'MOD',
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
        { str = '|Info'},
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
                        x = 0,
                        y = obj.menu_h*3 + obj.scroll_val * (pat_scroll_h -scroll_handle_h)+2 ,
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
    if not data.paramdata then return end 
    local tr_x_ind = 0   
    local tr_y0 = obj.tr_listy - obj.comlist_h * obj.scroll_val 
    local tr_y = tr_y0   
    for trackid=1,data.cnt_tracks do
      if not data.paramdata[trackid] 
        or not (data.paramdata[trackid]  and 
              (
                (data.paramdata[trackid].has_learn==true and conf.showflag&1==1) or 
                (data.paramdata[trackid].has_mod==true and conf.showflag&2==2)
              )
            )
          then goto skipnextrack 
      end
      tr_x_ind = 0  
      local tr_w = math.floor(obj.tr_listw)-tr_x_ind 
      obj['paramdata'..trackid] = { clear = true,
              x =obj.tr_listx+tr_x_ind,
              y = tr_y,
              w = math.floor(obj.tr_listw)-tr_x_ind -obj.remove_b_wide_w*2,
              h = obj.tr_h,
              fillback = true,
              fillback_colint = data.paramdata[trackid].trcol,--'col0,
              fillback_a = 0.7,
              alpha_back = 0.3,
              txt= trackid..': '..data.paramdata[trackid].trname,
              txt_a = 1,
              align_txt = 1,
              fontsz = obj.GUI_fontsz2,
              alpha_back = 0.7,
              show = true,
              } 
              
            obj['paramdatalearn'..trackid..'_removefx'] = { clear = true,
                    x =obj.tr_listx+obj.tr_listw-obj.remove_b_wide_w,
                    y = tr_y,
                    w = obj.remove_b_wide_w,
                    h = obj.tr_h,
                    fillback = true,
                    fillback_colstr = 'red',
                    fillback_a = 0.6,
                    txt= 'X Learn',
                    txt_a = 1,
                    --align_txt = 16,
                    fontsz = obj.GUI_fontsz3,
                    show = true,
                    func = function()
                          Undo_BeginBlock2( 0 )
                          --[[for trackid=1,data.cnt_tracks do
                            if data.paramdata[trackid] then]]
                              for fxid=1,data.paramdata[trackid].fx_cnt do
                                if data.paramdata[trackid][fxid] then 
                                  for param in pairs(data.paramdata[trackid][fxid]) do      
                                    if type(param) == 'number' then 
                                      Data_ModifyLearn(conf, data, trackid, fxid, param, true )
                                    end
                                  end
                                end
                              end
                            --[[end
                          end]]
                          DataReadProject(conf, obj, data, refresh, mouse)
                          Undo_EndBlock2( 0,conf.mb_title..': Remove Learn', -1 )
                          refresh.data = true
                          refresh.GUI = false
                        end
                } 
            obj['paramdatamod'..trackid..'_removefx'] = { clear = true,
                    x =obj.tr_listx+obj.tr_listw-obj.remove_b_wide_w*2,
                    y = tr_y,
                    w = obj.remove_b_wide_w,
                    h = obj.tr_h,
                    fillback = true,
                    fillback_colstr = 'red',
                    fillback_a = 0.6,
                    txt= 'X Mod',
                    txt_a = 1,
                    --align_txt = 16,
                    fontsz = obj.GUI_fontsz3,
                    show = true,
                    func = function()
                          Undo_BeginBlock2( 0 )
                          --[[for trackid=1,data.cnt_tracks do
                            if data.paramdata[trackid] then]]
                              for fxid=1,data.paramdata[trackid].fx_cnt do
                                if data.paramdata[trackid][fxid] then 
                                  for param in pairs(data.paramdata[trackid][fxid]) do      
                                    if type(param) == 'number' then 
                                      Data_ModifyMod(conf, data, trackid, fxid, param, true )
                                    end
                                  end
                                end
                              end
                            --[[end
                          end]]
                          DataReadProject(conf, obj, data, refresh, mouse)
                          Undo_EndBlock2( 0,conf.mb_title..': Remove Learn', -1 )
                          refresh.data = true
                          refresh.GUI = false
                        end
                }                 
                             
      tr_y = tr_y + obj['paramdata'..trackid].h
      
 
      
      for fxid in pairs(data.paramdata[trackid]) do      
        --if not type(fxid) ~= 'number'then goto skipnexfx  end
        if type(fxid) ~= 'number'
          or not (type(fxid) == 'number'  and 
                (
                  (data.paramdata[trackid][fxid].has_learn==true and conf.showflag&1==1) or 
                  (data.paramdata[trackid][fxid].has_mod==true and conf.showflag&2==2)
                )
              )
            then goto skipnexfx 
        end        
        tr_x_ind = obj.x_indent  
        local tr_w = math.floor(obj.tr_listw)-tr_x_ind 
        obj['paramdata'..trackid..'_'..fxid] = { clear = true,
                x =obj.tr_listx+tr_x_ind,
                y = tr_y,
                w = math.floor(obj.tr_listw)-tr_x_ind-obj.remove_b_wide_w*2 ,
                h = obj.tr_h,
                fillback = true,
                fillback_colint = data.paramdata[trackid].trcol,--'col0,
                fillback_a = 0.7,
                alpha_back = 0.3,
                txt= fxid..': '..MPL_ReduceFXname(data.paramdata[trackid][fxid].fxname),
                txt_a = 1,
                align_txt = 1,
                fontsz = obj.GUI_fontsz2,
                alpha_back = 0.7,
                show = true,
                func = function()
                  local is_float = reaper.TrackFX_GetOpen(data.paramdata[trackid].tr_ptr, fxid-1)
                  if is_float == false then
                     reaper.TrackFX_Show(data.paramdata[trackid].tr_ptr, fxid-1, 3)
                   else
                     reaper.TrackFX_Show(data.paramdata[trackid].tr_ptr, fxid-1, 2)
                  end
                end
                }        
                
            obj['paramdatalearn'..trackid..'_'..fxid..'_removefx'] = { clear = true,
                    x =obj.tr_listx+obj.tr_listw-obj.remove_b_wide_w,
                    y = tr_y,
                    w = obj.remove_b_wide_w,
                    h = obj.tr_h,
                    fillback = true,
                    fillback_colstr = 'red1',
                    fillback_a = 0.6,
                    txt= 'X Learn',
                    txt_a = 1,
                    --align_txt = 16,
                    fontsz = obj.GUI_fontsz3,
                    show = true,
                    func = function()
                          Undo_BeginBlock2( 0 )
                          --[[for trackid=1,data.cnt_tracks do
                            if data.paramdata[trackid] then
                              for fxid0=1,data.paramdata[trackid].fx_cnt do
                                if data.paramdata[trackid][fxid0] then ]]
                                  for param in pairs(data.paramdata[trackid][fxid]) do      
                                    if type(param) == 'number' then 
                                      Data_ModifyLearn(conf, data, trackid, fxid, param, true )
                                    end
                                  end
                                --[[end
                              end
                            end
                          end]]
                          DataReadProject(conf, obj, data, refresh, mouse)
                          Undo_EndBlock2( 0,conf.mb_title..': Remove Learn', -1 )
                          refresh.data = true
                          refresh.GUI = false
                        end
                }                 
            obj['paramdatamod'..trackid..'_'..fxid..'_removefx'] = { clear = true,
                    x =obj.tr_listx+obj.tr_listw-obj.remove_b_wide_w*2,
                    y = tr_y,
                    w = obj.remove_b_wide_w,
                    h = obj.tr_h,
                    fillback = true,
                    fillback_colstr = 'red1',
                    fillback_a = 0.6,
                    txt= 'X Mod',
                    txt_a = 1,
                    --align_txt = 16,
                    fontsz = obj.GUI_fontsz3,
                    show = true,
                    func = function()
                          Undo_BeginBlock2( 0 )
                          --[[for trackid=1,data.cnt_tracks do
                            if data.paramdata[trackid] then
                              for fxid0=1,data.paramdata[trackid].fx_cnt do
                                if data.paramdata[trackid][fxid0] then ]]
                                  for param in pairs(data.paramdata[trackid][fxid]) do      
                                    if type(param) == 'number' then 
                                      Data_ModifyMod(conf, data, trackid, fxid, param, true )
                                    end
                                  end
                                --[[end
                              end
                            end
                          end]]
                          DataReadProject(conf, obj, data, refresh, mouse)
                          Undo_EndBlock2( 0,conf.mb_title..': Remove Learn', -1 )
                          refresh.data = true
                          refresh.GUI = false
                        end
                }                 
                
                
        tr_y = tr_y +   obj['paramdata'..trackid..'_'..fxid].h
        
        
        
        
        for param in pairs(data.paramdata[trackid][fxid]) do      
          if type(param) ~= 'number' then goto skipnexparam end
          tr_x_ind = obj.x_indent  *2
          
          local tr_w = math.floor(obj.tr_listw*obj.param_w_ratio)-tr_x_ind 
          if (data.paramdata[trackid][fxid][param].has_learn==true and conf.showflag&1==1)
            or (data.paramdata[trackid][fxid][param].has_mod==true and conf.showflag&2==2)
            then           
            obj['paramdata'..trackid..'_'..fxid..'_'..param] = { clear = true,
                  x =obj.tr_listx+tr_x_ind,
                  y = tr_y,
                  w = tr_w,
                  h = obj.tr_h,
                  --fillback = true,
                  fillback_colint = data.paramdata[trackid].trcol,--'col0,
                  fillback_a = 0.2,
                  alpha_back = 0.3,
                  txt= param..': '..data.paramdata[trackid][fxid][param].paramname,
                  txt_a = 1,
                  align_txt = 1,
                  fontsz = obj.GUI_fontsz2,
                  alpha_back = 0.4,
                  show = true,
                  func = function()
                                     local valpar = TrackFX_GetParam(  data.paramdata[trackid].tr_ptr, fxid-1, param-1 ) 
                                     TrackFX_EndParamEdit( data.paramdata[trackid].tr_ptr, fxid-1, param-1, valpar)
                                     Action(41144)
                                     refresh.data = true
                                   end,                  
                  }
            local params_x = obj.tr_listx+tr_x_ind+tr_w  +obj.but_remove_w
            local params_y = tr_y
            local params_w = gfx.w - params_x
            if data.paramdata[trackid][fxid][param].has_learn==true and conf.showflag&1==1 then 
              Obj_ParamList_LearnSubEntry(conf, obj, data, refresh, mouse, params_x,params_y,params_w, trackid, fxid, param)
              tr_y = tr_y +  obj['paramdata'..trackid..'_'..fxid..'_'..param].h   
            end
            if data.paramdata[trackid][fxid][param].has_mod==true and conf.showflag&2==2 then 
              Obj_ParamList_ModSubEntry(conf, obj, data, refresh, mouse, params_x,tr_y,params_w, trackid, fxid, param)
              tr_y = tr_y +  obj['paramdata'..trackid..'_'..fxid..'_'..param].h  
            end            
          end
          
          local h0 = 0
          if obj['paramdata'..trackid..'_'..fxid..'_'..param] and obj['paramdata'..trackid..'_'..fxid..'_'..param].h then 
            h0 = obj['paramdata'..trackid..'_'..fxid..'_'..param].h  
          end
          --tr_y = tr_y +  h0     
          ::skipnexparam::
        end
          
        ::skipnexfx::
      end
      
      if data.focus and data.focus.trid and data.focus.trid == trackid then 
        obj['trarea_sel'..trackid] = { clear = true,
                      x = obj['paramdata'..trackid].x,
                      y = obj['paramdata'..trackid].y,
                      w = obj.tr_listw,
                      h = math.abs(tr_y -obj['paramdata'..trackid].y ),
                      alpha_back = 0.5,
                      a_frame = 0.5,
                      col = 'white',
                      ignore_mouse = true,
                      show = true,
                      } 
      end      
      
      ::skipnextrack:: 
    end 
    return   tr_y -   tr_y0  
  end 
  -----------------------------------------------
  function Obj_ParamList_ModSubEntry(conf, obj, data, refresh, mouse, params_x,params_y,params_w, trackid, fxid, param)
            obj['paramdatamod'..trackid..'_'..fxid..'_'..param..'remove'] = { clear = true,
                    x =params_x-obj.but_remove_w,
                    y = params_y,
                    w = obj.but_remove_w,
                    h = obj.tr_h,
                    fillback = true,
                    fillback_colstr = 'red2',
                    fillback_a = 0.6,
                    txt= 'X',
                    txt_a = 1,
                    --align_txt = 16,
                    fontsz = obj.GUI_fontsz3,
                    show = true,
                    func = function()
                          Undo_BeginBlock2( 0 )
                          --if data.paramdata[trackid][fxid][param].has_learn then Data_ModifyLearn(conf, data, trackid, fxid, param, true ) end
                          if data.paramdata[trackid][fxid][param].has_mod then Data_ModifyMod(conf, data, trackid, fxid, param, true ) end
                          DataReadProject(conf, obj, data, refresh, mouse)
                          Undo_EndBlock2( 0,conf.mb_title..': Remove Learn', -1 )
                          refresh.data = true
                          refresh.GUI = false
                        end
                }           
    obj['prm_learn'..trackid..'_'..fxid..'_'..param] = { clear = true,
          x = params_x,
          y = params_y,
          w = params_w,
          h = obj.tr_h,
          --fillback = true,
          --fillback_colint = colint,--'col0,
          --fillback_a = 0.4,
          alpha_back = obj.entr_alpha1,
          txt= '<param mod>',
          txt_a =1,
          show = true,
          fontsz = obj.GUI_fontsz3,
          func = function() Action (41143) end
          }              
  end                       
  -----------------------------------------------
  function Obj_ParamList_LearnSubEntry(conf, obj, data, refresh, mouse, params_x,params_y,params_w, trackid, fxid, param)
            obj['paramdatalearn'..trackid..'_'..fxid..'_'..param..'remove'] = { clear = true,
                    x =params_x-obj.but_remove_w,
                    y = params_y,
                    w = obj.but_remove_w,
                    h = obj.tr_h,
                    fillback = true,
                    fillback_colstr = 'red2',
                    fillback_a = 0.6,
                    txt= 'X',
                    txt_a = 1,
                    --align_txt = 16,
                    fontsz = obj.GUI_fontsz3,
                    show = true,
                    func = function()
                          Undo_BeginBlock2( 0 )
                          if data.paramdata[trackid][fxid][param].has_learn then Data_ModifyLearn(conf, data, trackid, fxid, param, true ) end
                          --if data.paramdata[trackid][fxid][param].has_mod then Data_ModifyMod(conf, data, trackid, fxid, param, true ) end
                          DataReadProject(conf, obj, data, refresh, mouse)
                          Undo_EndBlock2( 0,conf.mb_title..': Remove Learn', -1 )
                          refresh.data = true
                          refresh.GUI = false
                        end
                }  
    local flags = data.paramdata[trackid][fxid][param].flags
    local flagsMIDI = data.paramdata[trackid][fxid][param].flagsMIDI
    local cccol_w = math.floor(params_w*0.4)
    local flags_w = math.floor(params_w*0.3)
    local stov_w = math.floor(params_w*0.1)
    local MIDIfl_w = math.floor(params_w*0.2)
    local str = ''
    if data.paramdata[trackid][fxid][param].isMIDI then 
      str = 'MIDI Ch '..data.paramdata[trackid][fxid][param].MIDI_Ch..' CC '..data.paramdata[trackid][fxid][param].MIDI_CC
     else
      str = 'OSC '..data.paramdata[trackid][fxid][param].OSC_str
    end
    obj['prm_midicc'..trackid..'_'..fxid..'_'..param] = { clear = true,
          x = params_x,
          y = params_y,
          w = cccol_w,
          h = obj.tr_h,
          --fillback = true,
          --fillback_colint = colint,--'col0,
          --fillback_a = 0.4,
          alpha_back = obj.entr_alpha1,
          txt= str,
          txt_a =1,
          show = true,
          fontsz = obj.GUI_fontsz3,
          }
    local flags_txt = '-'
    if flags&1==1 then 
      flags_txt = 'selected track'
     elseif flags==4 then 
      flags_txt = 'focused FX'
     elseif flags==20 then 
      flags_txt = 'visible FX' 
    end          
    obj['prm_flags'..trackid..'_'..fxid..'_'..param] = { clear = true,
          x = params_x+cccol_w,
          y = params_y,
          w = flags_w,
          h = obj.tr_h,
          --fillback = true,
          --fillback_colint = colint,--'col0,
          --fillback_a = 0.4,
          alpha_back = obj.entr_alpha2,
          txt= flags_txt,
          txt_a =1,
          show = true,
          fontsz = obj.GUI_fontsz3,
          }  
    local sto_txt = '□'
    if flags&2==2 then sto_txt = '■' end
    obj['prm_stov'..trackid..'_'..fxid..'_'..param] = { clear = true,
          x = params_x+cccol_w+flags_w,
          y = params_y,
          w = stov_w,
          h = obj.tr_h,
          --fillback = true,
          --fillback_colint = colint,--'col0,
          --fillback_a = 0.4,
          alpha_back = obj.entr_alpha1,
          txt= sto_txt,
          txt_a =1,
          show = true,
          fontsz = obj.GUI_fontsz3,
          } 
    local flagsMIDI_txt = '-'
        if flagsMIDI==0  then 
          flagsMIDI_txt = 'Absolute'
         elseif flagsMIDI==4 then 
          flagsMIDI_txt = 'Relative 1'
         elseif flagsMIDI==8 then 
          flagsMIDI_txt = 'Relative 2'    
         elseif flagsMIDI==12 then 
          flagsMIDI_txt = 'Relative 3'    
         elseif flagsMIDI==16 then 
          flagsMIDI_txt = 'Toggle'                            
        end            
    obj['prm_midiflv'..trackid..'_'..fxid..'_'..param] = { clear = true,
          x = params_x+cccol_w+flags_w+stov_w,
          y = params_y,
          w = MIDIfl_w,
          h = obj.tr_h,
          --fillback = true,
          --fillback_colint = colint,--'col0,
          --fillback_a = 0.4,
          alpha_back = obj.entr_alpha1,
          txt= flagsMIDI_txt,
          txt_a =1,
          show = true,
          fontsz = obj.GUI_fontsz3,
          }               
  end                  
            --  do return end
    --[[local i_real = 1
    local ind_w = 10
    
    for i = 1, #build_t do
      local tr_y = obj.tr_listy - y_shift+ obj.offs + obj.tr_h*(i_real-1)
      local r = 90 
      local show_cond= (tr_y > obj.tr_listy and  tr_y + obj.tr_h < obj.tr_listy + obj.tr_listh) and build_t[i].show > 0
      if build_t[i].show then i_real = i_real + build_t[i].show end
      local tr_x_ind = build_t[i].level * ind_w
      local tr_w = math.floor(obj.tr_listw)-tr_x_ind
      if build_t[i].tpobj==3 and build_t[i].collapsed == false then tr_w = math.floor(obj.tr_listw) - tr_x_ind - obj.trw_area1_com end
      if show_cond then
        local disable_blitback,colint = true
        if build_t[i].colint then
          disable_blitback = false
          colint = build_t[i].colint
        end
        local tr_w0 = tr_w if build_t[i].level == 2 then tr_w = tr_w-obj.but_remove_w end
        obj['paramdata'..i] = { clear = true,
              x =obj.tr_listx+tr_x_ind,
              y = tr_y,
              w = tr_w0-1,
              h = math.ceil(obj.tr_h*build_t[i].show),
              fillback = true,
              fillback_colint = colint,--'col0,
              fillback_a = 0.7,
              alpha_back = build_t[i].alpha_back,
              txt= build_t[i].txt,
              txt_a = build_t[i].txt_a,
              txt_col = build_t[i].txt_col,
              txt_colint =build_t[i].txt_colint,
              show = show_cond,
              fontsz = build_t[i].font, 
              aligh_txt = build_t[i].align_txt,
              func =  build_t[i].func,
              is_selected = build_t[i].is_selected ,
              --disable_blitback = disable_blitback,
              }
        if build_t[i].level == 2 then         
          obj['paramdata_remove'..i] = { clear = true,
              x =obj.tr_listx+tr_x_ind+tr_w,
              y = tr_y,
              w = obj.but_remove_w,
              h = math.ceil(obj.tr_h*build_t[i].show),
              fillback = true,
              fillback_colstr = 'red',--'col0,
              fillback_a = 0.3,
              alpha_back = build_t[i].alpha_back,
              txt= 'X',
              txt_a = build_t[i].txt_a,
              show = show_cond,
              fontsz = build_t[i].font, 
              
              is_selected = build_t[i].is_selected ,
              func =  function() 
                        Undo_BeginBlock2( 0 )
                        Data_ModifyLearn(conf, data, build_t[i].data_trid,build_t[i].data_fxid,build_t[i].data_paramid, true )
                        Data_ModifyMod(conf, data, build_t[i].data_trid,build_t[i].data_fxid,build_t[i].data_paramid, true )
                        if conf.refresh_on_psc ==0 then DataReadProject(conf, obj, data, refresh, mouse) end
                        Undo_EndBlock2( 0,conf.mb_title..': Remove Learn', -1 )
                        refresh.data = true
                        refresh.GUI = false
                      end
              }
        end              
        if build_t[i].tpobj ~= 3 or build_t[i].collapsed == true then goto skip_to_nextparam   end
        if not build_t[i].has_learn then goto skip_to_parammod   end
        
        -- table entries
        local entr_id = 0
        entr_id = Obj_ParamList_SubEntry(conf, obj, data, refresh, mouse, build_t, 1, entr_id, i, show_cond, tr_y,
                                        build_t[i].txt_MIDI,
                                        build_t[i].func_MIDI,
                                        'MIDI')
        entr_id = Obj_ParamList_SubEntry(conf, obj, data, refresh, mouse, build_t, 2, entr_id, i, show_cond, tr_y,
                                        build_t[i].txt_OSC,
                                        build_t[i].func_OSC,
                                        'OSC') 
        local flags_txt = '-'
        if build_t[i].flags_learn&1==1 then 
          flags_txt = 'selected track'
         elseif build_t[i].flags_learn&4==4 then 
          flags_txt = 'focused FX'
         elseif build_t[i].flags_learn&20==20 then 
          flags_txt = 'visible FX' 
        end
        entr_id = Obj_ParamList_SubEntry(conf, obj, data, refresh, mouse, build_t, 4, entr_id, i, show_cond, tr_y,
                                        flags_txt,
                                        build_t[i].func_flags1,
                                        'flagvisible')  
        local flags_txt = '-'
        if build_t[i].flags_learn&2==2 then 
          flags_txt = 'Soft takeover'
         else  flags_txt = '-'
        end                                                                                 
        entr_id = Obj_ParamList_SubEntry(conf, obj, data, refresh, mouse, build_t, 8, entr_id, i, show_cond, tr_y,
                                        flags_txt,
                                        build_t[i].func_flags2,
                                        'flagST')  
        local flagsMIDI_txt = '-'
        if build_t[i].flagsMIDI==0  then 
          flagsMIDI_txt = 'Absolute'
         elseif build_t[i].flagsMIDI==4 then 
          flagsMIDI_txt = 'Relative 1'
         elseif build_t[i].flagsMIDI==8 then 
          flagsMIDI_txt = 'Relative 2'    
         elseif build_t[i].flagsMIDI==12 then 
          flagsMIDI_txt = 'Relative 3'    
         elseif build_t[i].flagsMIDI==16 then 
          flagsMIDI_txt = 'Toggle'                            
        end                                                                                 
        entr_id = Obj_ParamList_SubEntry(conf, obj, data, refresh, mouse, build_t, 16, entr_id, i, show_cond, tr_y,
                                        flagsMIDI_txt,
                                        build_t[i].func_flagsMIDI,
                                        'func_flagsMIDI') 
        ::skip_to_parammod::                                        
        ::skip_to_nextparam::              
      end
    end]]
