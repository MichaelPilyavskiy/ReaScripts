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
    obj.fillback_a_rem = 0.2
    obj.fillback_a_remoff = 0.8
    obj.tr_h = 18 
    obj.param_w_ratio = 0.4
    obj.remove_b_wide_w=60
    
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
        { str = 'Donate to MPL',
          func = function() Open_URL('http://www.paypal.me/donate2mpl') end }  ,
        { str = 'Cockos Forum thread',
          func = function() Open_URL('http://forum.cockos.com/showthread.php?t=235521') end  } , 
        { str = 'MPL on VK',
          func = function() Open_URL('http://vk.com/mpl57') end  } ,     
        { str = 'MPL on SoundCloud|',
          func = function() Open_URL('http://soundcloud.com/mpl57') end  } ,  
          
        { str = '#Actions'},   
        { str   = 'Show and arm envelopes with learn and parameter modulation for selected tracks',
          func  = function() Data_Actions_SHOWARMENV(conf, obj, data, refresh, mouse, 'Show and arm envelopes with learn/pmod', true) end },
        { str   = 'Show and arm envelopes with learn and parameter modulation for all tracks',
          func  = function() Data_Actions_SHOWARMENV(conf, obj, data, refresh, mouse, 'Show and arm envelopes with learn/pmod', false) end },     
        { str   = 'Remove selected track MIDI mappings',
          func  = function() Data_Actions_REMOVELEARN(conf, obj, data, refresh, mouse, 'Remove selected track MIDI mappings', false) end },          
        { str   = 'Remove selected track OSC mappings',
          func  = function() Data_Actions_REMOVELEARN(conf, obj, data, refresh, mouse, 'Remove selected track OSC mappings', true) end },
        { str   = 'Remove selected track parameter modulation',
          func  = function() Data_Actions_REMOVEMOD(conf, obj, data, refresh, mouse, 'Remove selected track parameter modulation', true) end },          
        { str   = 'Link last two touched FX parameters',
          func  = function() Data_Actions_LINKLTPRAMS(conf, obj, data, refresh, mouse, 'Link last two touched FX parameters', true) end },  
        { str   = 'Show TCP controls for mapped parameters|',
          func  = function() Data_Actions_SHOWTCP(conf, obj, data, refresh, mouse, 'Show TCP controls for mapped parameters', true) end },            
          
        --[[{ str   = 'Apply default mapping to focused FX|',
          func  = function() 
                    local retval, tracknumber, itemnumber, fxnumber = reaper.GetFocusedFX()
                    if retval ==1 then
                      Data_Actions_DEFMAPAPP(conf, obj, data, refresh, mouse, 'Apply default mapping to focused FX', tracknumber, fxnumber)  
                    end
                  end }, ]]         
                                --[[str = 'Save mapping to default / slotX (current right table)',
                                    {str = 'Apply to all FX instances on selected tracks',
                                    {str = 'Change MIDI mappings to specific channel',
                                    {str = 'Build mapping by incrementing OSC address',
                                    {str = 'Build mapping by incrementing MIDI CC',
                                    remove duplicas
                                    copy paste lfo

                                  ]]
                                  
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
              fillback_a = 0.9,
              alpha_back = 1,
              txt= trackid..': '..data.paramdata[trackid].trname,
              txt_a = 1,
              align_txt = 1,
              fontsz = obj.GUI_fontsz2,
              show = true,
              } 
            
            local fillback_a_rem = obj.fillback_a_rem if data.paramdata[trackid].has_learn then fillback_a_rem = obj.fillback_a_remoff end
            obj['paramdatalearn'..trackid..'_removefx'] = { clear = true,
                    x =obj.tr_listx+obj.tr_listw-obj.remove_b_wide_w,
                    y = tr_y,
                    w = obj.remove_b_wide_w,
                    h = obj.tr_h,
                    fillback = true,
                    fillback_colstr = 'red',
                    fillback_a = fillback_a_rem,
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
            local fillback_a_rem =obj.fillback_a_rem if data.paramdata[trackid].has_mod then fillback_a_rem = obj.fillback_a_remoff end
            obj['paramdatamod'..trackid..'_removefx'] = { clear = true,
                    x =obj.tr_listx+obj.tr_listw-obj.remove_b_wide_w*2,
                    y = tr_y,
                    w = obj.remove_b_wide_w,
                    h = obj.tr_h,
                    fillback = true,
                    fillback_colstr = 'red',
                    fillback_a = fillback_a_rem,
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
            local fillback_a_rem =obj.fillback_a_rem if data.paramdata[trackid][fxid].has_learn then fillback_a_rem = obj.fillback_a_remoff end    
            obj['paramdatalearn'..trackid..'_'..fxid..'_removefx'] = { clear = true,
                    x =obj.tr_listx+obj.tr_listw-obj.remove_b_wide_w,
                    y = tr_y,
                    w = obj.remove_b_wide_w,
                    h = obj.tr_h,
                    fillback = true,
                    fillback_colstr = 'red',
                    fillback_a = fillback_a_rem,
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
            local fillback_a_rem =obj.fillback_a_rem if data.paramdata[trackid][fxid].has_mod then fillback_a_rem = obj.fillback_a_remoff end  
            obj['paramdatamod'..trackid..'_'..fxid..'_removefx'] = { clear = true,
                    x =obj.tr_listx+obj.tr_listw-obj.remove_b_wide_w*2,
                    y = tr_y,
                    w = obj.remove_b_wide_w,
                    h = obj.tr_h,
                    fillback = true,
                    fillback_colstr = 'red',
                    fillback_a = fillback_a_rem,
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
              if data.paramdata[trackid][fxid][param].has_learn == true and  conf.showflag&1==1 then 
                obj['paramdatamod2'..trackid..'_'..fxid..'_'..param] = { clear = true,
                    x =obj.tr_listx+tr_x_ind,
                    y = tr_y,
                    w = tr_w,
                    h = obj.tr_h,
                    --fillback = true,
                    fillback_colint = data.paramdata[trackid].trcol,--'col0,
                    fillback_a = 0.2,
                    alpha_back = 0.3,
                    txt= param..': '..data.paramdata[trackid][fxid][param].paramname..' (ParamMod)',
                    txt_a = 1,
                    align_txt = 1,
                    fontsz = obj.GUI_fontsz2,
                    alpha_back = 0.4,
                    show = true,
                    func = function()
                                       local valpar = TrackFX_GetParam(  data.paramdata[trackid].tr_ptr, fxid-1, param-1 ) 
                                       TrackFX_EndParamEdit( data.paramdata[trackid].tr_ptr, fxid-1, param-1, valpar)
                                       Action(41143)
                                       refresh.data = true
                                     end,                  
                    }
                  obj['paramdata'..trackid..'_'..fxid..'_'..param].txt= param..': '..data.paramdata[trackid][fxid][param].paramname..' (Learn)'
               else
                obj['paramdata'..trackid..'_'..fxid..'_'..param].func =
                                  function()
                                     local valpar = TrackFX_GetParam(  data.paramdata[trackid].tr_ptr, fxid-1, param-1 ) 
                                     TrackFX_EndParamEdit( data.paramdata[trackid].tr_ptr, fxid-1, param-1, valpar)
                                     Action(41143)
                                     refresh.data = true
                                   end                
              end
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
    obj['paramdata_mod'..trackid..'_'..fxid..'_'..param..'remove'] = { clear = true,
                    x =params_x-obj.but_remove_w,
                    y = params_y,
                    w = obj.but_remove_w,
                    h = obj.tr_h,
                    fillback = true,
                    fillback_colstr = 'red',
                    fillback_a = obj.fillback_a_remoff,
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
    local enable_w = math.floor(params_w*0.1)
    local aud_w = math.floor(params_w*0.3)
    local lfo_w = math.floor(params_w*0.3)
    local link_w = math.floor(params_w*0.3) 
    local modt = data.paramdata[trackid][fxid][param].modulation
    
    
    local state_txt = '□'
    if modt.PROGRAMENV2==0 then state_txt = '■' end
    obj['prm_mod_enable'..trackid..'_'..fxid..'_'..param] = { clear = true,
          x = params_x,
          y = params_y,
          w = enable_w,
          h = obj.tr_h,
          --fillback = true,
          --fillback_colint = colint,--'col0,
          --fillback_a = 0.4,
          alpha_back = obj.entr_alpha1,
          txt= 'On '..state_txt,
          txt_a =1,
          show = true,
          fontsz = obj.GUI_fontsz3,
          func = function() 
                      data.paramdata[trackid][fxid][param].modulation.PROGRAMENV2 = math.abs(1-data.paramdata[trackid][fxid][param].modulation.PROGRAMENV2)
                      Data_ModifyMod(conf, data, trackid, fxid, param)
                      refresh.data = true
                      refresh.GUI = true          
          
                end}   
                
    local state_txt = '□'
    if modt.AUDIOCTL1==1 then state_txt = '■' end
    obj['prm_mod_au'..trackid..'_'..fxid..'_'..param] = { clear = true,
          x = params_x+enable_w,
          y = params_y,
          w = aud_w,
          h = obj.tr_h,
          --fillback = true,
          --fillback_colint = colint,--'col0,
          --fillback_a = 0.4,
          alpha_back = obj.entr_alpha1,
          txt= 'AUDIOCTRL '..state_txt,
          txt_a =1,
          show = true,
          fontsz = obj.GUI_fontsz3,
          func = function() 
                      data.paramdata[trackid][fxid][param].modulation.AUDIOCTL1 = math.abs(1-data.paramdata[trackid][fxid][param].modulation.AUDIOCTL1)
                      Data_ModifyMod(conf, data, trackid, fxid, param)
                      refresh.data = true
                      refresh.GUI = true 
                end}    
                
    local state_txt = '□'
    if modt.LFO1==1 then state_txt = '■' end
    obj['prm_mod_lfo'..trackid..'_'..fxid..'_'..param] = { clear = true,
          x = params_x+enable_w+aud_w,
          y = params_y,
          w = lfo_w,
          h = obj.tr_h,
          --fillback = true,
          --fillback_colint = colint,--'col0,
          --fillback_a = 0.4,
          alpha_back = obj.entr_alpha1,
          txt= 'LFO '..state_txt,
          txt_a =1,
          show = true,
          fontsz = obj.GUI_fontsz3,
          func = function() 
                      data.paramdata[trackid][fxid][param].modulation.LFO1 = math.abs(1-data.paramdata[trackid][fxid][param].modulation.LFO1)
                      Data_ModifyMod(conf, data, trackid, fxid, param)
                      refresh.data = true
                      refresh.GUI = true 
                end}   
                
    local state_txt = '□'
    if modt.PLINK1==1 then state_txt = '■' end
    obj['prm_mod_plink'..trackid..'_'..fxid..'_'..param] = { clear = true,
          x = params_x+enable_w+aud_w+lfo_w,
          y = params_y,
          w = link_w,
          h = obj.tr_h,
          --fillback = true,
          --fillback_colint = colint,--'col0,
          --fillback_a = 0.4,
          alpha_back = obj.entr_alpha1,
          txt= 'PLINK '..state_txt,
          txt_a =1,
          show = true,
          fontsz = obj.GUI_fontsz3,
          func = function() 
                      data.paramdata[trackid][fxid][param].modulation.PLINK1 = math.abs(1-data.paramdata[trackid][fxid][param].modulation.PLINK1)
                      Data_ModifyMod(conf, data, trackid, fxid, param)
                      refresh.data = true
                      refresh.GUI = true 
                end}                 
  end                       
  -----------------------------------------------
  function Obj_ParamList_LearnSubEntry(conf, obj, data, refresh, mouse, params_x,params_y,params_w, trackid, fxid, param)
            obj['paramdatalearn'..trackid..'_'..fxid..'_'..param..'remove'] = { clear = true,
                    x =params_x-obj.but_remove_w,
                    y = params_y,
                    w = obj.but_remove_w,
                    h = obj.tr_h,
                    fillback = true,
                    fillback_colstr = 'red',
                    fillback_a =obj.fillback_a_remoff,
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
      str = 'MIDI Ch '..(data.paramdata[trackid][fxid][param].MIDI_Ch)..' CC '..data.paramdata[trackid][fxid][param].MIDI_CC
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
          func = function()
                    local ret, str = GetUserInputs('Modify MIDI/OSC', 4, 'MIDI Ch (1-16),MIDI CC / byte2 (0-127),MIDI_type (CC=11,PC=12 etc),OSC (remove MIDI learn)',(data.paramdata[trackid][fxid][param].MIDI_Ch)..','..
                                                                                     data.paramdata[trackid][fxid][param].MIDI_CC..','..
                                                                                     data.paramdata[trackid][fxid][param].MIDI_msgtype..','..
                                                                                     data.paramdata[trackid][fxid][param].OSC_str)
                    if ret then
                      local t = {}
                      local shift = 1
                      for val in str:gmatch('[^,]+') do if tonumber(val) then val=tonumber(val) end t[#t+1] = val end
                      if #t< 2+shift then return end
                      if not t[3+shift] then t[3+shift] = '' end
                      local OSC_str = t[3+shift]
                      if OSC_str == '' then  
                        data.paramdata[trackid][fxid][param].MIDI_Ch = t[1]
                        data.paramdata[trackid][fxid][param].MIDI_CC = t[2]
                        data.paramdata[trackid][fxid][param].MIDI_msgtype = t[3]
                       else
                        data.paramdata[trackid][fxid][param].MIDI_Ch = -1
                        data.paramdata[trackid][fxid][param].MIDI_CC = -1
                        data.paramdata[trackid][fxid][param].MIDI_msgtype = -1
                      end
                      data.paramdata[trackid][fxid][param].OSC_str = OSC_str
                      Data_ModifyLearn(conf, data, trackid, fxid, param)
                      refresh.data = true
                      refresh.GUI = true
                    end
                  end
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
          func = function()
                    Menu(mouse, {
                                  { str = 'Enable if track or item is selected',
                                    state = data.paramdata[trackid][fxid][param].flags&1==1,
                                    func = function()
                                              local flags = data.paramdata[trackid][fxid][param].flags
                                              data.paramdata[trackid][fxid][param].flags = BinaryToggle(flags, 0, 1)
                                              Data_ModifyLearn(conf, data, trackid, fxid, param)
                                              refresh.data = true
                                              refresh.GUI = true
                                            end
                                  },
                                  { str = 'Enable if FX is focused',
                                    state = data.paramdata[trackid][fxid][param].flags==4,--&4==4,
                                    func = function()
                                              local flags = data.paramdata[trackid][fxid][param].flags
                                              data.paramdata[trackid][fxid][param].flags = 4--BinaryToggle(flags, 3, 1)
                                              Data_ModifyLearn(conf, data, trackid, fxid, param)
                                              refresh.data = true
                                              refresh.GUI = true
                                            end
                                  },
                                  { str = 'Enable if FX is visible',
                                    state = data.paramdata[trackid][fxid][param].flags==20,--&20==20,
                                    func = function()
                                              local flags = data.paramdata[trackid][fxid][param].flags
                                              data.paramdata[trackid][fxid][param].flags = 20--BinaryToggle(flags, 2, 1) = BinaryToggle(flags, 4, 1)
                                              Data_ModifyLearn(conf, data, trackid, fxid, param)
                                              refresh.data = true
                                              refresh.GUI = true
                                            end
                                  },
                                })
                  
                  end
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
          txt= 'ST: '..sto_txt,
          txt_a =1,
          show = true,
          fontsz = obj.GUI_fontsz3,
          func = function()
                  local flags = data.paramdata[trackid][fxid][param].flags
                  data.paramdata[trackid][fxid][param].flags = BinaryToggle(flags, 1)
                  Data_ModifyLearn(conf, data, trackid, fxid, param)
                  refresh.data = true
                  refresh.GUI = true
                end} 
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
          func = function()
                    Menu(mouse, {
                                  { str = 'Absolute',
                                    state = data.paramdata[trackid][fxid][param].flagsMIDI==0,
                                    func = function()
                                              data.paramdata[trackid][fxid][param].flagsMIDI = 0
                                              Data_ModifyLearn(conf, data, trackid, fxid, param)
                                              refresh.data = true
                                              refresh.GUI = true
                                            end
                                  },   
                                  { str = 'Relative 1 (127=-1, 1 = +1)',
                                    state = data.paramdata[trackid][fxid][param].flagsMIDI==4,
                                    func = function()
                                              data.paramdata[trackid][fxid][param].flagsMIDI = 4
                                              Data_ModifyLearn(conf, data, trackid, fxid, param)
                                              refresh.data = true
                                              refresh.GUI = true
                                            end
                                  },   
                                  { str = 'Relative 2 (63=-1, 65 = +1)',
                                    state = data.paramdata[trackid][fxid][param].flagsMIDI==8,
                                    func = function()
                                              data.paramdata[trackid][fxid][param].flagsMIDI = 8
                                              Data_ModifyLearn(conf, data, trackid, fxid, param)
                                              refresh.data = true
                                              refresh.GUI = true
                                            end
                                  }, 
                                  { str = 'Relative 3 (65=-1, 1 = +1)',
                                    state = data.paramdata[trackid][fxid][param].flagsMIDI==12,
                                    func = function()
                                              data.paramdata[trackid][fxid][param].flagsMIDI = 12
                                              Data_ModifyLearn(conf, data, trackid, fxid, param)
                                              refresh.data = true
                                              refresh.GUI = true
                                            end
                                  },  
                                  { str = 'Toggle (>0==toggle)',
                                    state = data.paramdata[trackid][fxid][param].flagsMIDI==16,
                                    func = function()
                                              data.paramdata[trackid][fxid][param].flagsMIDI = 16
                                              Data_ModifyLearn(conf, data, trackid, fxid, param)
                                              refresh.data = true
                                              refresh.GUI = true
                                            end
                                  },                                  
                                })
                  
                  end          
          }               
  end
