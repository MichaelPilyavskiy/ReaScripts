-- @description VisualMixer
-- @version 2.27
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @about Very basic Izotope Neutron Visual mixer port to REAPER environment
-- @changelog
--    # prevent track to be both selected if placed one under another
--    + Settings: add option to handle all tracks instead selection

 
  
  DATA2 = {
    selectedtracks={},
    marquee={},
    latchctrls={},
    arrangemaps={}
  }
   
  ---------------------------------------------------------------------  
  function main()
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.version = 2.27
    DATA.extstate.extstatesection = 'MPL_VisualMixer'
    DATA.extstate.mb_title = 'Visual Mixer'
    DATA.extstate.default = 
                          {  
                          wind_x =  100,
                          wind_y =  100,
                          wind_w =  800,
                          wind_h =  600,
                          dock =    0, 
                          
                          
                          -- global
                          CONF_NAME = 'default',
                          CONF_snapshcnt = 8,
                          CONF_scalecent = 0.7,
                          CONF_tr_rect_px = 50,
                          CONF_invertYscale = 0,
                          
                          -- actions
                          CONF_action = 0, 
                          CONF_randsymflags = 0, 
                          CONF_normlufsdb = -25,--dB
                          CONF_normlufswait = 5,--sec
                          CONF_spreadflags = 0,
                          CONF_lufswaitMAP = 5,
                          
                          -- global
                          --CONF_csurf = 0,
                          CONF_snapshrecalltime = 0.5,
                          
                          UI_groupflags = 0,
                          UI_appatchange = 0,
                          UI_initatmouse = 0,
                          UI_enableshortcuts = 1,
                          UI_showtooltips = 1,
                          UI_sidegrid = 0,
                          UI_backgrcol = '#333333',
                          UI_showtracknames = 1,
                          UI_showtracknames_flags = 1,
                          UI_showicons = 1,
                          UI_showtopctrl_flags = 1|2|4, 
                            UI_extcontrol1dest = 0,--1=fisrt send volume
                          UI_extendcenter = 0.3,
                          UI_expandpeaks =1,
                          UI_showscalenumbers =1,
                          UI_showinfotooltip =1,
                          UI_ignoregrouptracks =0,
                          
                          CONF_quantizevolume = 1,
                          CONF_quantizepan = 5,
                          CONF_handlealltracks = 0,
                          
                          UI_3dmode = 0,
                          }
    DATA:ExtStateGet()
    DATA:ExtStateGetPresets() 
    if DATA.extstate.UI_initatmouse&1==1 then
      local w = DATA.extstate.wind_w
      local h = DATA.extstate.wind_h 
      local x, y = GetMousePosition()
      DATA.extstate.wind_x = x-w/2
      DATA.extstate.wind_y = y-h/2
    end
    
    local is_new_value,filename,sectionID,cmdID,mode,resolution,val,contextstr = reaper.get_action_context()
    DATA2.arrangemapsfp = filename:gsub('mpl_Visual Mixer%.lua','mpl_Visual Mixer_arrangemaps.ini')
    DATA2:Snapshot_Read()
    DATA_RESERVED_DYNUPDATE(DATA, true)
    DATA:GUIinit()
    GUI_RESERVED_init(DATA)
    RUN()
    
  end
  ---------------------------------------------------------------------  
  function DATA2:ShortcutsInfo()
  str=
[[
Object in 2D mode
  LMB drag: change volume and pan
  LMB drag+Ctrl: change volume and pan for marquee selected objects
  LMB click+Shift: reset Pan
  LMB click+Alt: reset Volume
  
]]
    MB(str,DATA.extstate.mb_title,0)
  end
  --------------------------------------------------------------------- 
  function GUI_RESERVED_init_shortcuts(DATA)
    if DATA.extstate.UI_enableshortcuts == 0 then return end 
    DATA.GUI.shortcuts[32] = function() VF_Action(40044) end -- space to transport play
  end
  ---------------------------------------------------------------------  
  function GUI_initctrls(DATA)
    if DATA.GUI.custom_compactmode==true then
      local xoffs = DATA.GUI.custom_offset +DATA.GUI.custom_ctrl_singlew
      GUI_CTRL_snapshots(DATA,xoffs) 
      GUI_CTRL_header(DATA) 
     else
      local xoffs = GUI_CTRL_header(DATA) 
      GUI_CTRL_snapshots(DATA,xoffs)  
    end
  end
  ---------------------------------------------------------------------  
  function GUI_dock(DATA)  
    local state = gfx.dock(-1)
    if state&1==1 then
      state = 0
     else
      state = DATA.extstate.dock 
      if state == 0 then state = 1 end
    end
    local title = DATA.extstate.mb_title or ''
    if DATA.extstate.version then title = title..' '..DATA.extstate.version end
    gfx.quit()
    gfx.init( title,
              DATA.extstate.wind_w or 100,
              DATA.extstate.wind_h or 100,
              state, 
              DATA.extstate.wind_x or 100, 
              DATA.extstate.wind_y or 100)
    
    
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_init(DATA)
    -- overrride VF3 GUI
    DATA.GUI.default_backgr = DATA.extstate.UI_backgrcol --black
    
    DATA.GUI.custom_mainbuth = 30
    DATA.GUI.custom_offset = math.floor(DATA.GUI.default_scale*DATA.GUI.default_txt_fontsz/2)
    DATA.GUI.custom_mainsepx = 400
    DATA.GUI.custom_gfxw_effective =gfx.w/DATA.GUI.default_scale
    DATA.GUI.custom_gfxw_compactmode =600
    DATA.GUI.custom_compactmode = DATA.GUI.custom_gfxw_effective< DATA.GUI.custom_gfxw_compactmode
    DATA.GUI.custom_mainbutw = ((gfx.w/DATA.GUI.default_scale - DATA.GUI.custom_mainsepx)-DATA.GUI.custom_offset*2) / 2
    DATA.GUI.custom_datah = (gfx.h/DATA.GUI.default_scale-DATA.GUI.custom_mainbuth*3-DATA.GUI.custom_offset*6) /2
    DATA.GUI.custom_dataw = gfx.w/DATA.GUI.default_scale - DATA.GUI.custom_mainsepx-DATA.GUI.custom_offset
    DATA.GUI.custom_minw_ratio = 0.1 -- minimum for track w
    
    DATA.GUI.custom_txtfontszinfo = 14  
    DATA.GUI.custom_knobfontsz = 14
    DATA.GUI.custom_butstuff = 12
    DATA.GUI.CONF_tr_rect_px =DATA.extstate.CONF_tr_rect_px 
    DATA.GUI.custom_trwidthhandleh = 8 /DATA.GUI.default_scale
    DATA.GUI.custom_ctrls_w = gfx.w/DATA.GUI.default_scale-DATA.GUI.custom_offset*2
    DATA.GUI.custom_ctrl_singlew = math.floor(DATA.GUI.custom_ctrls_w/7) 
    if DATA.GUI.custom_compactmode ==true then DATA.GUI.custom_ctrl_singlew = math.floor(DATA.GUI.custom_ctrls_w/4) end
    DATA.GUI.default_data_a = 0.7-- normal
    DATA.GUI.default_data_a2 = 0.2 -- ignore serach 
    DATA.GUI.custom_currentsnapshotID = 1
    DATA.GUI.custom_areaspace = 10/DATA.GUI.default_scale
    DATA.GUI.custom_foldrect = 10/DATA.GUI.default_scale
    DATA.GUI.custom_butside = 15/DATA.GUI.default_scale
    DATA.GUI.custom_backgr_fill_enabled = 0.4
    DATA.GUI.custom_backgr_fill_disabled = 0.1
    DATA.GUI.custom_3droom_sz = 200/DATA.GUI.default_scale
    DATA.GUI.custom_3droom_offs = 50/DATA.GUI.default_scale
    DATA.GUI.custom_3dminptsz = 50/DATA.GUI.default_scale
    DATA.GUI.custom_scaley = DATA.GUI.custom_mainbuth+DATA.GUI.custom_offset*3
    DATA.GUI.custom_scalew= gfx.w/DATA.GUI.default_scale-DATA. GUI.custom_offset*2 
    DATA.GUI.custom_scaleh= gfx.h/DATA.GUI.default_scale-DATA.GUI.custom_scaley-DATA.GUI.custom_offset*2
    DATA.GUI.custom_extendcenter = DATA.extstate.UI_extendcenter*DATA.GUI.custom_scalew
    
    DATA.GUI.custom_actionanmes = {
      [0] = 'Rand Chaos',
      [1] = 'Rand Sym',
      [2] = 'Norm LUFS',
      [3] = 'Reset',
      [4] = 'Spread cent',
      [5] = 'Arrange by map',
    }
    
    DATA.GUI.buttons = {}
    DATA.GUI.buttons.settingstrig = { x=DATA.GUI.custom_offset,
                            y=DATA.GUI.custom_offset,
                            w=DATA.GUI.custom_ctrl_singlew-DATA.GUI.custom_offset,
                            h=DATA.GUI.custom_mainbuth,
                            txt = 'Menu',
                            --frame_a = DATA.GUI.default_framea_normal,
                            --frame_asel = DATA.GUI.default_framea_normal,
                            back_sela = 0,
                            onmouseclick =    function()  end,
                            onmouserelease  = function()  
                              DATA.GUI.Settings_open =DATA.GUI.Settings_open~1
                              GUI_RESERVED_init(DATA)
                            end,
                          } 
                        
    if not DATA.GUI.Settings_open then DATA.GUI.Settings_open = 0  end
    if DATA.GUI.Settings_open ==0 then  
      if not DATA.GUI.layers[21] then DATA.GUI.layers[21] = {} end DATA.GUI.layers[21].a = 0 
      for key in pairs(DATA.GUI.buttons) do if key:match('Rsettings') then DATA.GUI.buttons[key] = nil end end
      GUI_initctrls(DATA)
      GUI_Areas(DATA) 
      DATA2:GUI_inittracks(DATA)   
     elseif DATA.GUI.Settings_open and DATA.GUI.Settings_open == 1 then  
      if not DATA.GUI.layers[21] then DATA.GUI.layers[21] = {} end DATA.GUI.layers[21].a = 1
      for key in pairs(DATA.GUI.buttons) do if key:match('Rsettings') then DATA.GUI.buttons[key] = nil end end
      DATA.GUI.buttons.Rsettings = { x=0,
                               y=DATA.GUI.custom_offset*2+DATA.GUI.custom_mainbuth,
                               w=gfx.w/DATA.GUI.default_scale,
                               h=gfx.h/DATA.GUI.default_scale - DATA.GUI.custom_offset*3-DATA.GUI.custom_mainbuth,
                               txt = 'Settings',
                               --txt_fontsz = DATA.GUI.default_txt_fontsz3,
                               frame_a = 0,
                               offsetframe = DATA.GUI.custom_offset,
                               offsetframe_a = 0.1,
                               ignoremouse = true,
                               refresh = true,
                               }
      DATA:GUIBuildSettings()  
      DATA.UPD.onGUIinit = true
    end
    
    
    GUI_RESERVED_init_shortcuts(DATA) 
    for but in pairs(DATA.GUI.buttons) do DATA.GUI.buttons[but].key = but end 
  end
  --------------------------------------------------------------------- 
  function GUI_CTRL_snapshots(DATA,xoffs0)
    local xoffs=xoffs0
    DATA.GUI.buttons.snapshotslabel = { x=xoffs, 
                            y=DATA.GUI.custom_offset,--+DATA.GUI.CONF_tr_rect_px/2
                            w=DATA.GUI.custom_ctrl_singlew-1 ,-- -DATA.GUI.custom_offset,
                            h=DATA.GUI.custom_mainbuth,
                            txt = 'Snapshots',
                            onmouseclick = function() DATA:GUImenu({
                                                              { str = 'Clean all snapshots',
                                                                func = function()
                                                                          DATA2.Snapshots = {}
                                                                          GUI_initctrls(DATA)
                                                                          DATA2:Snapshot_Write()  
                                                                        end},
                                                              { str = 'Clean current snapshot',
                                                                func = function()
                                                                          local ID = DATA.GUI.custom_currentsnapshotID or 1
                                                                          DATA2.Snapshots[ID] = nil
                                                                          GUI_initctrls(DATA)
                                                                          DATA2:Snapshot_Write()  
                                                                        end},                                                                        
                                                              { str = 'Reset current snapshot tracks',
                                                                func = function()
                                                                          local ID = DATA.GUI.custom_currentsnapshotID or 1
                                                                          DATA2:Snapshot_Reset(ID)  
                                                                        end},   
                                                              --[[{ str = '|Smooth recall: off',
                                                                state =  DATA.extstate.CONF_snapshrecalltime==0,
                                                                func = function() DATA.extstate.CONF_snapshrecalltime = 0 DATA.UPD.onconfchange=true end},                                                                          
                                                              { str = 'Smooth recall: 0.1sec',
                                                                state =  DATA.extstate.CONF_snapshrecalltime==0.1,
                                                                func = function() DATA.extstate.CONF_snapshrecalltime = 0.1 DATA.UPD.onconfchange=true end},    
                                                              { str = 'Smooth recall: 0.5sec',
                                                                state =  DATA.extstate.CONF_snapshrecalltime==0.5,
                                                                func = function() DATA.extstate.CONF_snapshrecalltime = 0.5 DATA.UPD.onconfchange=true end},    
                                                              { str = 'Smooth recall: 1sec',
                                                                state =  DATA.extstate.CONF_snapshrecalltime==1,
                                                                func = function() DATA.extstate.CONF_snapshrecalltime = 1 DATA.UPD.onconfchange=true end},                                                                 
                                                                 ]]
                                                                        
                                                            }) 
                                            end
                            --frame_a = 0,
                            --ignoremouse = true,
                            }    
    xoffs = xoffs + DATA.GUI.custom_ctrl_singlew
    local snapshotscnt = 8
    local snapshw = math.floor(DATA.GUI.custom_ctrl_singlew/4)
    for i = 1, snapshotscnt do
      local backgr_fill,backgr_col
      if i == DATA.GUI.custom_currentsnapshotID then 
        backgr_fill = 0.45
        backgr_col = '#FFFFFF' 
      end
      local ex = DATA2.Snapshots[i]
      local frame_a = 0.2
      if ex then frame_a = 0.5 end
      if DATA2.Snapshots and DATA2.Snapshots[i] and DATA2.Snapshots[i].col then
        backgr_col = DATA2.Snapshots[i].col
        backgr_fill = 0.7
        
        if i == DATA.GUI.custom_currentsnapshotID then backgr_fill = 0.9 frame_a = 0.8 end
      end
      DATA.GUI.buttons['snapshots'..i] = { x=xoffs + snapshw*(i-1), 
                              y=DATA.GUI.custom_offset,--+DATA.GUI.CONF_tr_rect_px/2
                              w=snapshw-1,
                              h=DATA.GUI.custom_mainbuth,
                              txt = i,
                              frame_a = frame_a,
                              backgr_fill = backgr_fill,
                              backgr_col = backgr_col,
                              onmouseclick = function()
                                              if DATA2.Snapshots[i] and DATA.GUI.Ctrl~= true then
                                                local oldID = DATA.GUI.custom_currentsnapshotID
                                                DATA.GUI.custom_currentsnapshotID = i
                                                DATA2:Snapshot_Read()
                                                DATA2:Snapshot_Recall(i,oldID)
                                                GUI_initctrls(DATA)
                                               else
                                                DATA2:Snapshot_WriteCurrent(i)
                                                DATA2:Snapshot_Write()
                                                DATA.GUI.custom_currentsnapshotID = i
                                                GUI_initctrls(DATA)
                                              end
                                              
                                            end,
                              onmouseclickR = function()
                                              DATA:GUImenu(
                                                {
                                                  { str='Set snapshot color',
                                                    func=function() 
                                                      
                                                      local retval, color = reaper.GR_SelectColor()
                                                      if not retval then return end
                                                      local r, g, b = reaper.ColorFromNative( color )
                                                      local outhex = '#'..string.format("%06X",  ColorToNative( b, g, r ))
                                                      
                                                      if not DATA2.Snapshots[i] then DATA2.Snapshots[i] = {txt=''} end
                                                      DATA2.Snapshots[i].col = outhex
                                                      DATA2:Snapshot_WriteCurrent(i)
                                                      DATA2:Snapshot_Write()
                                                      DATA.GUI.custom_currentsnapshotID = i
                                                      GUI_initctrls(DATA)
                                                    end},
                                                  { str='Set tooltip',
                                                    func=function() 
                                                      if not DATA2.Snapshots[i] then DATA2.Snapshots[i] = {txt=''} end
                                                      local retval, outtxt = reaper.GetUserInputs( 'Set tooltip for snapshot '..i, 1, ',extrawidth=400', DATA2.Snapshots[i].txt or '' ) 
                                                      if retval then
                                                        DATA2.Snapshots[i].txt = outtxt
                                                        DATA2:Snapshot_WriteCurrent(i)
                                                        DATA2:Snapshot_Write()
                                                        DATA.GUI.custom_currentsnapshotID = i
                                                        GUI_initctrls(DATA)
                                                      end
                                                    end}
                                                }                                                
                                              )
                                              
                                            end,
                            onmousematch = 
                              function() 
                                local x, y = reaper.GetMousePosition() 
                                if DATA2.Snapshots[i] and DATA2.Snapshots[i].txt and DATA2.Snapshots[i].txt ~= '' then reaper.TrackCtl_SetToolTip( 'Snapshot '..i..':\n'..DATA2.Snapshots[i].txt,x+DATA.GUI.default_tooltipxoffs, y+DATA.GUI.default_tooltipyoffs, false ) end
                              end                                            
                              }  
    end
  end
  --------------------------------------------------------------------- 
  function iscross(L1x,L1y,R1x,R1y,L2x,L2y,R2x,R2y)
    return 
      (
        (L1x > L2x and L1x < R2x)
        or (R1x > L2x and R1x < R2x)
        or (L1x < L2x and R1x > R2x)
      )
      and 
      (
        (L1y > L2y and L1y < R2y)
        or (R1y > L2y and R1y < R2y)
        or (L1y < L2y and R1y > R2y)
      )      
  end
  --------------------------------------------------------------------- 
  function DATA2:reset_selection(DATA) 
    for GUID in pairs(DATA2.tracks) do if DATA.GUI.buttons['trackrect'..GUID] then DATA.GUI.buttons['trackrect'..GUID].sel_isselected = false end end
  end
  --------------------------------------------------------------------- 
  function DATA2:count_selection(DATA) 
    local cnt = 0
    for GUID in pairs(DATA2.tracks) do if DATA.GUI.buttons['trackrect'..GUID] and DATA.GUI.buttons['trackrect'..GUID].sel_isselected == true then cnt = cnt + 1 end end
    return cnt
  end
  --------------------------------------------------------------------- 
  function DATA2:marque_selection(DATA) 
    L1x,L1y,R1x,R1y = DATA2.marquee.x,DATA2.marquee.y,DATA2.marquee.x+DATA2.marquee.w,DATA2.marquee.y+DATA2.marquee.h
    for GUID in pairs(DATA2.tracks) do
      if DATA.GUI.buttons['trackrect'..GUID] then
        L2x,L2y,R2x,R2y = DATA.GUI.buttons['trackrect'..GUID].x,DATA.GUI.buttons['trackrect'..GUID].y,DATA.GUI.buttons['trackrect'..GUID].x+DATA.GUI.buttons['trackrect'..GUID].w,DATA.GUI.buttons['trackrect'..GUID].y+DATA.GUI.buttons['trackrect'..GUID].h
        DATA.GUI.buttons['trackrect'..GUID].sel_isselected = iscross(L1x,L1y,R1x,R1y,L2x,L2y,R2x,R2y)
      end
    end
  end
  --------------------------------------------------------------------- 
  function GUI_Areas(DATA)   
    local xoffs = DATA.GUI.custom_offset
    local yoffs = DATA.GUI.custom_scaley
    local scaleh = DATA.GUI.custom_scaleh
    if DATA.GUI.custom_compactmode == true then 
      yoffs = yoffs+DATA.GUI.custom_mainbuth+DATA.GUI.custom_offset 
      scaleh = scaleh - DATA.GUI.custom_mainbuth-DATA.GUI.custom_offset 
    end
    local scalew = DATA.GUI.custom_scalew
    if DATA.extstate.UI_3dmode == 1 then
      --[[scalew = scalew-DATA.GUI.CONF_tr_rect_px
      scaleh = scaleh-DATA.GUI.CONF_tr_rect_px
      xoffs = xoffs+DATA.GUI.CONF_tr_rect_px/2
      yoffs = yoffs+DATA.GUI.CONF_tr_rect_px/2]]
    end
    DATA.GUI.buttons.scale = { x=xoffs,
                            y=yoffs,
                            w=scalew,
                            h=scaleh,
                            ignoremouse = true,
                            --refresh = true,
                            val_data = {['tp'] = 0,['isscale']=true},
                            frame_a =0.3,
                            frame_asel =0,
                            }
    DATA.GUI.buttons.marquee = { x=DATA.GUI.buttons.scale.x,
                            y=DATA.GUI.buttons.scale.y,
                            w=DATA.GUI.buttons.scale.w,
                            h=DATA.GUI.buttons.scale.h,
                            --refresh = true,
                            --backgr_fill = 0,
                            frame_a =0,
                            frame_asel =0,
                            val_data = {['ismarque']=true},
                            onmouseclick =    function() 
                             if DATA2.ontrackobj == true then return end 
                              DATA2.marquee.x = DATA.GUI.x
                              DATA2.marquee.latchx = DATA.GUI.x
                              DATA2.marquee.y = DATA.GUI.y
                              DATA2.marquee.latchy = DATA.GUI.y
                              DATA2.marquee.state = true
                            end,
                            onmousedrag =     function()  
                              if DATA2.ontrackobj == true then return end 
                              if DATA2.marquee.state ~= true then return end
                              
                              DATA2.marquee.w = DATA.GUI.x-DATA2.marquee.latchx
                              DATA2.marquee.h = DATA.GUI.y-DATA2.marquee.latchy
                              if DATA2.marquee.w < 0 then 
                                DATA2.marquee.w = math.abs(DATA2.marquee.w)
                                DATA2.marquee.x = DATA2.marquee.latchx - DATA2.marquee.w
                              end
                              if DATA2.marquee.h < 0 then 
                                DATA2.marquee.h = math.abs(DATA2.marquee.h)
                                DATA2.marquee.y = DATA2.marquee.latchy- DATA2.marquee.h
                              end
                              
                            end,
                            onmouserelease  = function()  
                              if DATA2.ontrackobj == true then return end 
                              if DATA2.marquee.state ~= true then return end
                              DATA2.marquee.state = false
                              DATA2:marque_selection(DATA) 
                              DATA2.marquee = {}
                              DATA.GUI.layers_refresh[2] = true
                            end
                            } 
    if DATA.extstate.UI_3dmode ==1 then
      DATA.GUI.buttons.scale_room = { x=DATA.GUI.custom_offset+scalew/2-DATA.GUI.custom_3droom_sz/2+DATA.GUI.custom_3droom_offs,
                            y=yoffs+scaleh/2-DATA.GUI.custom_3droom_sz/2+DATA.GUI.custom_3droom_offs*2,
                            w=DATA.GUI.custom_3droom_sz,
                            h=DATA.GUI.custom_3droom_sz,
                            frame_a =0.1,
                            backgr_fill = 0.05,
                            backgr_col = '#FFFFFF',
                            val_data = {is_room=true},
                            ignoremouse=true,
                            --refresh = true,
                            }   
    end
    
    if DATA.GUI.custom_extendcenter > 0 then
      DATA.GUI.buttons.scale_centerarea = { x=DATA.GUI.custom_offset+scalew/2-DATA.GUI.custom_extendcenter/2,
                            y=yoffs,
                            w=DATA.GUI.custom_extendcenter,
                            h=scaleh,
                            frame_a =0.1,
                            backgr_fill = 0.05,
                            backgr_col = '#FFFFFF',
                            val_data = {is_room=true},
                            ignoremouse=true,
                            --refresh = true,
                            }
    end
  end
  --------------------------------------------------------------------- 
  function GUI_CTRL_header(DATA) 
            
    local xoffs = DATA.GUI.custom_offset +DATA.GUI.custom_ctrl_singlew
    local yoffs = DATA.GUI.custom_offset
    if DATA.GUI.custom_compactmode == true then
      xoffs = DATA.GUI.custom_offset
      yoffs = DATA.GUI.custom_offset*2+DATA.GUI.custom_mainbuth
    end
    
    local ctrlw = DATA.GUI.custom_ctrl_singlew
    if DATA.GUI.custom_compactmode == true then ctrlw = math.floor(DATA.GUI.custom_ctrls_w/3) end
    local txt_a = 0.7 --if DATA.extstate.UI_3dmode ==1  then txt_a = 0.1 end
    DATA.GUI.buttons.knob = { x=xoffs,
                            y=yoffs,
                            w=ctrlw-DATA.GUI.custom_offset ,
                            h=DATA.GUI.custom_mainbuth,
                            txt = 'Size',--..math.floor(DATA.extstate.CONF_tr_rect_px)..'px',
                            txt_fontsz = DATA.GUI.custom_knobfontsz,
                            txt_a = txt_a,
                            knob_isknob = true,
                            knob_showvalueright = true,
                            val_res = 0.25,
                            val = DATA.extstate.CONF_tr_rect_px,
                            val_min = 20,
                            val_max = 150,
                            val_default = 30,
                            frame_a = DATA.GUI.default_framea_normal,
                            frame_asel = DATA.GUI.default_framea_normal,
                            back_sela = 0,
                            onmouseclick =    function()  end,
                            onmousedrag =     function() 
                                --DATA.GUI.buttons.knob.txt = 'Size: '..math.floor(DATA.GUI.buttons.knob.val )..'px'
                                DATA.extstate.CONF_tr_rect_px = math.floor(DATA.GUI.buttons.knob.val )
                                DATA.GUI.CONF_tr_rect_px =DATA.extstate.CONF_tr_rect_px
                                DATA2:GUI_inittracks(DATA)
                                if DATA.extstate.UI_3dmode ==1 then GUI_Areas(DATA) end
                              end,
                            onmouserelease  = function()     
                              DATA.extstate.CONF_tr_rect_px = math.floor(DATA.GUI.buttons.knob.val )
                              DATA.GUI.CONF_tr_rect_px =DATA.extstate.CONF_tr_rect_px
                              DATA.UPD.onconfchange = true
                              --DATA2:tracks_init()
                            end,
                            onmousereleaseR  = function()     
                              local val_def = 50
                              DATA.extstate.CONF_tr_rect_px = val_def
                              DATA.GUI.CONF_tr_rect_px =DATA.extstate.CONF_tr_rect_px
                              DATA.GUI.buttons.knob.val=val_def
                              DATA.UPD.onconfchange = true
                              DATA2:tracks_init(true)
                              DATA2:GUI_inittracks(DATA)
                            end,
                          }
    xoffs = xoffs+ctrlw
    local txt_a = 0.7 if DATA.extstate.UI_3dmode ==1  then txt_a = 0.1 end
    DATA.GUI.buttons.knob2 = { x=xoffs,
                            y=yoffs,
                            w=ctrlw-DATA.GUI.custom_offset ,
                            h=DATA.GUI.custom_mainbuth,
                            txt = 'Scale',-- Y
                            txt_a = txt_a,
                            txt_fontsz = DATA.GUI.custom_knobfontsz,
                            knob_isknob = true,
                            knob_showvalueright = true,
                            val_res = 0.05,
                            val = DATA.extstate.CONF_scalecent,
                            val_min = 0.2,
                            val_max = 0.95,
                            frame_a = DATA.GUI.default_framea_normal,
                            frame_asel = DATA.GUI.default_framea_normal,
                            back_sela = 0,
                            onmouseclick =    function()  end,
                            onmousedrag =     function() 
                                DATA.extstate.CONF_scalecent = DATA.GUI.buttons.knob2.val 
                                DATA2:GUI_inittracks(DATA)
                              end,
                            onmouserelease  = function() 
                              DATA.extstate.CONF_scalecent = DATA.GUI.buttons.knob2.val 
                              DATA.UPD.onconfchange = true
                            end,
                            --[[onmousereleaseR  = function() 
                              DATA:GUImenu({
                                { str = 'Invert Y',
                                state =  DATA.extstate.CONF_invertYscale==1,
                                func = function() DATA.extstate.CONF_invertYscale = DATA.extstate.CONF_invertYscale~1 DATA.UPD.onconfchange=true DATA2:GUI_inittracks(DATA) end},  
                              })
                            end,  ]]                         
 
                          }                          
                          
                          
    xoffs = xoffs+ctrlw
    local rclickw = math.floor(ctrlw*0.2)
    local txtact = 'Action'
    if DATA.GUI.custom_actionanmes[DATA.extstate.CONF_action] then txtact = DATA.GUI.custom_actionanmes[DATA.extstate.CONF_action] end
    DATA.GUI.buttons.act = { x=xoffs, 
                            y=yoffs,
                            w=ctrlw-rclickw-DATA.GUI.custom_offset-1,
                            h=DATA.GUI.custom_mainbuth,
                            txt = txtact,
                            onmouserelease = function() DATA2:Action() end,
                            }   
    DATA.GUI.buttons.actRC = { x=xoffs+ctrlw-rclickw-DATA.GUI.custom_offset, 
                            y=yoffs,
                            w=rclickw,
                            h=DATA.GUI.custom_mainbuth,
                            --txt_flags=0,
                            txt = '>',
                            onmouserelease  = function() DATA2:Action_Menu() end,   
                            }                             
    xoffs = xoffs+ctrlw                    
    return xoffs
  end
  ------------------------------------------------------------------------------------------------------
  function DATA2:Action_Menu()  
    local t = {
      { str = '#Action',},  
      { str = 'Spread center (only for center area enabled)', hidden = DATA.extstate.UI_extendcenter ==0, state =  DATA.extstate.CONF_action==4, func = function() DATA.extstate.CONF_action = 4 DATA.UPD.onconfchange=true GUI_RESERVED_init(DATA) end }, 
      { str = 'Reset volume and pan', state =  DATA.extstate.CONF_action==3, func = function() DATA.extstate.CONF_action = 3 DATA.UPD.onconfchange=true GUI_RESERVED_init(DATA) end }, 
      { str = 'Normalize to LUFS', state =  DATA.extstate.CONF_action==2, func = function() DATA.extstate.CONF_action = 2 DATA.UPD.onconfchange=true GUI_RESERVED_init(DATA) end }, 
      { str = 'Random chaotically', state =  DATA.extstate.CONF_action==0, func = function() DATA.extstate.CONF_action = 0 DATA.UPD.onconfchange=true GUI_RESERVED_init(DATA) end }, 
      { str = 'Random symmetrically', state =  DATA.extstate.CONF_action==1, func = function() DATA.extstate.CONF_action = 1 DATA.UPD.onconfchange=true GUI_RESERVED_init(DATA) end }, 
      { str = 'Arrange by map', state =  DATA.extstate.CONF_action==5, func = function() DATA.extstate.CONF_action = 5 DATA.UPD.onconfchange=true GUI_RESERVED_init(DATA) end }, 
      { str = '|#Settings', }, 
    }
    
    if DATA.extstate.CONF_action == 1 then  -- symmetric params
      t[#t+1] = { str = 'Reset all flags|', func = function() DATA.extstate.CONF_randsymflags = 0 DATA.UPD.onconfchange=true end }
      t[#t+1] = { str = 'Pan - exclude center area', state =  DATA.extstate.CONF_randsymflags&1==1, func = function() DATA.extstate.CONF_randsymflags = DATA.extstate.CONF_randsymflags~1 DATA.UPD.onconfchange=true end }
      t[#t+1] = { str = 'Par - make more narrow|', state =  DATA.extstate.CONF_randsymflags&2==2, func = function() DATA.extstate.CONF_randsymflags = DATA.extstate.CONF_randsymflags~2 DATA.UPD.onconfchange=true end }
      t[#t+1] = { str = 'Slight pan deviations', state =  DATA.extstate.CONF_randsymflags&8==8, func = function() DATA.extstate.CONF_randsymflags = DATA.extstate.CONF_randsymflags~8 DATA.UPD.onconfchange=true end }
      t[#t+1] = { str = 'Slight volume deviations|', state =  DATA.extstate.CONF_randsymflags&16==16, func = function() DATA.extstate.CONF_randsymflags = DATA.extstate.CONF_randsymflags~16 DATA.UPD.onconfchange=true end }
      
      t[#t+1] = { str = 'Volume follow pan', state =  DATA.extstate.CONF_randsymflags&4==4, func = function() DATA.extstate.CONF_randsymflags = DATA.extstate.CONF_randsymflags~4 DATA.UPD.onconfchange=true end }
      t[#t+1] = { str = 'Inverted following', state =  DATA.extstate.CONF_randsymflags&32==32, hidden = DATA.extstate.CONF_randsymflags&4~=4, func = function() DATA.extstate.CONF_randsymflags = DATA.extstate.CONF_randsymflags~32  DATA.UPD.onconfchange=true end } 
    end
    
    if DATA.extstate.CONF_action == 2 then  -- LUFS
      t[#t+1] = { str = '-18db', state =  DATA.extstate.CONF_normlufsdb==-18, func = function() DATA.extstate.CONF_normlufsdb = -18 DATA.UPD.onconfchange=true end }
      t[#t+1] = { str = '-23db', state =  DATA.extstate.CONF_normlufsdb==-23, func = function() DATA.extstate.CONF_normlufsdb = -23 DATA.UPD.onconfchange=true end }
      t[#t+1] = { str = 'Wait time: 1s', state =  DATA.extstate.CONF_normlufswait==1, func = function() DATA.extstate.CONF_normlufswait = 1 DATA.UPD.onconfchange=true end }
      t[#t+1] = { str = 'Wait time: 5s', state =  DATA.extstate.CONF_normlufswait==5, func = function() DATA.extstate.CONF_normlufswait = 5 DATA.UPD.onconfchange=true end }
      t[#t+1] = { str = 'Wait time: 10s', state =  DATA.extstate.CONF_normlufswait==10, func = function() DATA.extstate.CONF_normlufswait = 10 DATA.UPD.onconfchange=true end }
    end
    
    if DATA.extstate.CONF_action == 4 then  -- spread tracks at center
      t[#t+1] = { str = 'Rearrange below 0dB', state =  DATA.extstate.CONF_spreadflags&1==1, func = function() DATA.extstate.CONF_spreadflags = DATA.extstate.CONF_spreadflags~1 DATA.UPD.onconfchange=true end }
    end
    
    if DATA.extstate.CONF_action == 5 then  -- LUFS map
      t[#t+1] = { str = 'Wait time: 5s', state =  DATA.extstate.CONF_lufswaitMAP==5, func = function() DATA.extstate.CONF_lufswaitMAP = 5 DATA.UPD.onconfchange=true end }
      t[#t+1] = { str = 'Wait time: 10s', state =  DATA.extstate.CONF_lufswaitMAP==10, func = function() DATA.extstate.CONF_lufswaitMAP = 10 DATA.UPD.onconfchange=true end }
      t[#t+1] = { str = 'Open map configuration file', func = function() 
          local OS = reaper.GetOS()
          local fp= DATA2.arrangemapsfp
          if OS == "OSX32" or OS == "OSX64" then
            os.execute('open "" "' .. fp .. '"')
          else
            os.execute('start "" "' .. fp .. '"')
          end
        end }
    end
    DATA:GUImenu(t)
  end
  ------------------------------------------------------------------------------------------------------
  function shuffle(tbl) -- https://gist.github.com/Uradamus/10323382
    for i = #tbl, 2, -1 do
      local j = math.random(i)
      tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
  end
  ------------------------------------------------------------------------------------------------------
  function DATA2:Action()
    if DATA.extstate.CONF_action==0 or DATA.extstate.CONF_action==1 then 
      DATA2:Action_Random()
     elseif DATA.extstate.CONF_action==2 then
      if DATA2.lufsmeasure then DATA2.lufsmeasureSTOP = true end
      DATA2.LUFSnormMeasureRUN = true
     elseif DATA.extstate.CONF_action==3 then
      DATA2:Action_Reset()
     elseif DATA.extstate.CONF_action==4 then
      DATA2:Action_Spread()     
     elseif DATA.extstate.CONF_action==5 then
      if DATA2.lufsmeasure then DATA2.lufsmeasureSTOP = true end
      DATA2:Action_ArrangeMap()     
      DATA2.LUFSnormMeasureRUN = true
      DATA2.LUFSnormMeasureRUN_appmap = true
    end
  end
  ------------------------------------------------------------------------------------------------------ 
  function DATA2:Action_ArrangeMap_InitDefault() 
    return 
[[
[MAP1]
name="default"
track1_name="kick","bass drum","bassdrum","bd" NOT "sub"
track1_vol=-32dB
track1_pan=0

track2_name="subkick"
track2_vol=-29dB
track2_pan=0

track3_name="snare1","snare","snarehigh"
track3_vol=-36dB
track3_pan=0

track3_name="snare2","snarelow"
track3_vol=-40dB
track3_pan=0

track4_name="tom1","hightom","high tom"
track4_vol=-40dB
track4_pan=-25

track5_name="tom2","midtom","mid tom"
track5_vol=-40dB
track5_pan=15

track6_name="tom3","lowtom","low tom"
track6_vol=-40dB
track6_pan=50

track7_name="hat","close hat","cl hat"
track7_vol=-37dB
track7_pan=-40

track8_name="oh","overheads"
track8_vol=-40dB
track8_pan=0
]]
  end
  ------------------------------------------------------------------------------------------------------ 
  function DATA2:Action_ArrangeMap_Init()
    local fp = DATA2.arrangemapsfp 
    local chunk_str
    if not file_exists(fp) then 
      chunk_str = DATA2:Action_ArrangeMap_InitDefault() 
      local f = io.open(fp, 'w')
      if not f then return end
      f:write(chunk_str)
      f:close()
      --msg(chunk_str)
      --msg('write==================')
     else 
      local f = io.open(fp, 'r')
      if not f then return end
      chunk_str = f:read('a')
      f:close()
      --msg(chunk_str)
      --msg('read==================')
    end
    return true, chunk_str
  end
  ------------------------------------------------------------------------------------------------------ 
  function DATA2:Action_ArrangeMap_Parse(chunk_str)
    if not chunk_str then return end
    local mapid
    for line in chunk_str:gmatch('[^\r\n]+') do
      local is_mapid = line:match('%[MAP%d+%]') ~=nil
      if is_mapid then
        local mapid_int = line:match('%[MAP(%d+)%]')
        if tonumber(mapid_int) then mapid = tonumber(mapid_int) end
      end
      if mapid and not is_mapid then
        local trid, param, val =  line:match('track(%d+)_(.-)%=(.*)')
        if trid then trid = tonumber(trid) end
        if (trid and param and val) then
          if not DATA2.arrangemaps[mapid] then DATA2.arrangemaps[mapid] = {} end
          if not DATA2.arrangemaps[mapid][trid] then DATA2.arrangemaps[mapid][trid] = {} end
          if param=='vol' then val = tonumber( val:match('[%-%.%d]+')) end
          if param=='pan' then val = tonumber( val) end
          
          if param=='name' then  
            local exclude_t = {}
            local exclude
            if val:match('NOT') then 
              exclude = val:match('NOT(.*)') 
              val = val:match('(.-)NOT') 
            end 
            local t = {} for name in val:gmatch('"(.-)"') do t[#t+1] = name end
            val = t
            if exclude then 
              exclude_t = {} 
              for name in exclude:gmatch('"(.-)"') do exclude_t[#exclude_t+1] = name end 
            end 
            if exclude_t then DATA2.arrangemaps[mapid][trid].name_exclude=CopyTable(exclude_t )end
          end
          
          
          DATA2.arrangemaps[mapid][trid][param]=val
        end
      end
    end
  end
  ------------------------------------------------------------------------------------------------------ 
  function DATA2:Action_ArrangeMap()
    -- no maps found / add example
    local ret, chunk_str
    if not DATA2.arrangemaps or #DATA2.arrangemaps == 0 then  
      ret, chunk_str = DATA2:Action_ArrangeMap_Init() 
    end
    if ret and chunk_str then DATA2:Action_ArrangeMap_Parse(chunk_str)  end
    DATA2.arrangemaps.current_map = 1  
  end
  ------------------------------------------------------------------------------------------------------ 
  function DATA2:Action_Spread()
    if DATA.extstate.CONF_spreadflags &1==0 then -- simply random ext data
      local cnt_centertracks = 0
      for GUID in pairs(DATA2.tracks) do if DATA2.tracks[GUID].pan == 0 then cnt_centertracks = cnt_centertracks + 1 end end
      if cnt_centertracks <= 1 then return end 
      local spreadstep = 1/cnt_centertracks
      local shift = 0
      if cnt_centertracks%2==0 then 
        spreadstep = 1/(1+cnt_centertracks)
        shift = spreadstep
      end 
      if cnt_centertracks%2==1 then  shift = 0.5*spreadstep end
      for GUID in pairs(DATA2.tracks) do if DATA2.tracks[GUID].ptr and ValidatePtr2(0,DATA2.tracks[GUID].ptr, 'MediaTrack*') and DATA2.tracks[GUID].pan == 0 then 
        GetSetMediaTrackInfo_String( DATA2.tracks[GUID].ptr, 'P_EXT:MPL_VISMIX_centerarea', shift, true )
        shift = shift + spreadstep
      end end
    end
    
    if DATA.extstate.CONF_spreadflags &1==1 then -- simply random ext data
      local dvol = 0.2
      local volout = 1+dvol
      local cnt_centertracks = 3
      local spreadstep = 1/cnt_centertracks
      local shift0 = 0
      if cnt_centertracks%2==0 then 
        spreadstep = 1/(1+cnt_centertracks)
        shift0 = spreadstep
      end 
      if cnt_centertracks%2==1 then  shift0 = 0.5*spreadstep end
      local shift = shift0
      local i = 0
      for GUID in pairs(DATA2.tracks) do if DATA2.tracks[GUID].ptr and ValidatePtr2(0,DATA2.tracks[GUID].ptr, 'MediaTrack*') and DATA2.tracks[GUID].pan == 0 then  
        if i%cnt_centertracks==0 then -- next row
          volout = volout - dvol
          i = 0
          shift = shift0
        end
        i = i + 1
        GetSetMediaTrackInfo_String( DATA2.tracks[GUID].ptr, 'P_EXT:MPL_VISMIX_centerarea', shift, true )
        SetMediaTrackInfo_Value(DATA2.tracks[GUID].ptr, 'D_VOL', volout)
        shift = shift + spreadstep
      end end
    end
    
    DATA2:tracks_init(true)
    DATA2:GUI_inittracks(DATA) 
  end
  ------------------------------------------------------------------------------------------------------ 
  function DATA2:Action_Reset()
    for GUID in pairs(DATA2.tracks) do if DATA2.tracks[GUID].ptr and ValidatePtr2(0,DATA2.tracks[GUID].ptr, 'MediaTrack*') then 
      SetMediaTrackInfo_Value(DATA2.tracks[GUID].ptr, 'D_VOL', 1)
      SetMediaTrackInfo_Value(DATA2.tracks[GUID].ptr, 'D_PAN', 0)
    end end
    local ID = DATA.GUI.custom_currentsnapshotID or 1 
    DATA2:tracks_init(true)
    DATA2:Snapshot_WriteCurrent(ID)
    DATA2:Snapshot_Write()
    DATA2:GUI_inittracks(DATA) 
  end
  ------------------------------------------------------------------------------------------------------ 
  function DATA2:Action_ArrangeMap_GetDestParams(GUID) 
    if not DATA2.arrangemaps.current_map and DATA2.arrangemaps[DATA2.arrangemaps.current_map] then return end
    local map_t = DATA2.arrangemaps[DATA2.arrangemaps.current_map]
    local tr_name = DATA2.tracks[GUID].name:lower()
    for trid=1, #map_t do 
      
      local match_name
      if map_t[trid].name then
        
        for nameid = 1, #map_t[trid].name do
          if tr_name:match(map_t[trid].name[nameid]:lower()) then
            match_name = true
            if map_t[trid].name_exclude then 
              for name_excludeid=1,#map_t[trid].name_exclude do
                if tr_name:match(map_t[trid].name_exclude[name_excludeid]:lower()) then
                  match_name = nil
                end
              end
            end 
            if match_name == true then break end
          end
        end
        
      end
      
      if match_name == true then 
        return true, map_t[trid].vol, map_t[trid].pan/100
      end
    end
  end
  ------------------------------------------------------------------------------------------------------ 
  function DATA2:Action_NormalizeLUFS_persist()
    if DATA2.lufsmeasureSTOP == true then
      -- revert volumes back
      for GUID in pairs(DATA2.tracks) do 
        if DATA2.tracks[GUID].ptr and ValidatePtr2(0,DATA2.tracks[GUID].ptr, 'MediaTrack*') then 
          SetMediaTrackInfo_Value( DATA2.tracks[GUID].ptr, 'I_VUMODE',  0 )
          SetMediaTrackInfo_Value(DATA2.tracks[GUID].ptr, 'D_VOL', DATA2.tracks[GUID].vol)
        end
      end
      DATA2:tracks_init(true)
      DATA2:GUI_inittracks(DATA) 
      DATA2.lufsmeasure = nil
      DATA2.LUFSnormMeasureRUN = nil
      DATA2.LUFSnormMeasureRUN_appmap = nil
      DATA2.lufsmeasureSTOP = nil
      DATA.GUI.buttons.act.txt = DATA.GUI.custom_actionanmes[DATA.extstate.CONF_action]
      return 
    end
    
    
      if not DATA2.lufsmeasure then  
        -- init
        DATA.GUI.buttons.act.txt = '[Wait]'
        DATA2.lufsmeasure ={TS = os.clock()}
        for GUID in pairs(DATA2.tracks) do 
          if DATA2.tracks[GUID].ptr and ValidatePtr2(0,DATA2.tracks[GUID].ptr, 'MediaTrack*') then 
            SetMediaTrackInfo_Value( DATA2.tracks[GUID].ptr, 'I_VUMODE',  16 )
            SetMediaTrackInfo_Value(DATA2.tracks[GUID].ptr, 'D_VOL', 1)
          end
        end
      end
      
      
    if DATA2.lufsmeasure then
      cur = os.clock()
      
      -- in progress
      local waittime_sec = DATA.extstate.CONF_normlufswait
      if DATA2.LUFSnormMeasureRUN_appmap == true then waittime_sec = DATA.extstate.CONF_lufswaitMAP end 
      if  cur - DATA2.lufsmeasure.TS < waittime_sec then 
        local time_elapsed = math.abs(math.floor(cur - DATA2.lufsmeasure.TS - waittime_sec))
        local outtxt = '[Wait '..time_elapsed..' sec]'
        if outtxt ~= DATA.GUI.buttons.act.txt then DATA.GUI.buttons.act.txt = outtxt end
        --DATA.GUI.buttons.act.refresh = true
      end
      
      if cur - DATA2.lufsmeasure.TS > waittime_sec then 
        reaper.Undo_BeginBlock2( 0 )
        DATA2:Action_NormalizeLUFS_final()
        reaper.Undo_EndBlock2( 0, 'Visual mixer lufs measure', 0xFFFFFFFF )
      end
      
    end
    
  end
  ------------------------------------------------------------------------------------------------------ 
  function DATA2:Action_NormalizeLUFS_final()    
    -- final refresh 
    DATA.GUI.buttons.act.txt = DATA.GUI.custom_actionanmes[DATA.extstate.CONF_action]
    for GUID in pairs(DATA2.tracks) do 
      if DATA2.tracks[GUID].ptr and ValidatePtr2(0,DATA2.tracks[GUID].ptr, 'MediaTrack*') then 
        local lufs = Track_GetPeakInfo( DATA2.tracks[GUID].ptr, 1024 )
        local lufsdB = WDL_VAL2DB(lufs)  
        
        local lufs_dest = DATA.extstate.CONF_normlufsdb
        local ret = true
        local pan_dest
        local lufs_destmap, pan_destmap
        if DATA2.LUFSnormMeasureRUN_appmap == true then
          ret, lufs_destmap, pan_destmap = DATA2:Action_ArrangeMap_GetDestParams(GUID) 
          if ret == true then 
            lufs_dest = lufs_destmap 
            pan_dest = pan_destmap 
          end
        end
        
        if ret == true then 
          local lufs = Track_GetPeakInfo( DATA2.tracks[GUID].ptr, 1024 )
          local lufsdB = WDL_VAL2DB(lufs)
          local vol = GetMediaTrackInfo_Value(DATA2.tracks[GUID].ptr, 'D_VOL')
          local vol_DB = WDL_VAL2DB(vol)
          local diff_DB = lufs_dest-lufsdB
          local out_db = vol_DB + diff_DB
          local lufsout =WDL_DB2VAL(out_db)
          SetMediaTrackInfo_Value(DATA2.tracks[GUID].ptr, 'D_VOL', math.min(lufsout,3.9))
          SetMediaTrackInfo_Value( DATA2.tracks[GUID].ptr, 'I_VUMODE',  0 ) 
          if pan_dest then SetMediaTrackInfo_Value(DATA2.tracks[GUID].ptr, 'D_PAN', pan_dest) end
        end
      end
    end
    local ID = DATA.GUI.custom_currentsnapshotID or 1 
    DATA2:tracks_init(true)
    DATA2:Snapshot_WriteCurrent(ID)
    DATA2:Snapshot_Write()
    DATA2:GUI_inittracks(DATA) 
    DATA2.lufsmeasure = nil
    DATA2.LUFSnormMeasureRUN = nil
    DATA2.LUFSnormMeasureRUN_appmap = nil
    DATA2.lufsmeasureSTOP = nil
  end
  ------------------------------------------------------------------------------------------------------ 
  function DATA2:Action_Random()
    -- count tracks
      local cnttracks = 0 for GUID in pairs(DATA2.tracks) do if DATA2.tracks[GUID].ptr and ValidatePtr2(0,DATA2.tracks[GUID].ptr, 'MediaTrack*') then cnttracks = cnttracks + 1 end end
      if cnttracks <= 1 then return end
      
    -- build shuffled table
      
      local step = 2/(cnttracks-1)
      local t_rand = {}
      for i = 1, cnttracks do t_rand[i] = -1+step*(i-1)  end 
      for i = 1, cnttracks do 
        if DATA.extstate.CONF_randsymflags &1==1 then if t_rand[i] ~= 0 then t_rand[i] = math.abs(t_rand[i])^0.5 * t_rand[i]/math.abs(t_rand[i])  end end
        if DATA.extstate.CONF_randsymflags &2==2 then if t_rand[i] ~= 0 then t_rand[i] = math.abs(t_rand[i])*0.5 * t_rand[i]/math.abs(t_rand[i])  end end
      end
      shuffle(t_rand)
      
    -- randomize
      local id = 0
      for GUID in pairs(DATA2.tracks) do if DATA2.tracks[GUID].ptr and ValidatePtr2(0,DATA2.tracks[GUID].ptr, 'MediaTrack*') then 
        
        if DATA.extstate.CONF_action==0 then 
          local db_val = -20*math.random()
          SetMediaTrackInfo_Value(DATA2.tracks[GUID].ptr, 'D_VOL', WDL_DB2VAL(db_val) )
          SetMediaTrackInfo_Value(DATA2.tracks[GUID].ptr, 'D_PAN', math.random()*2-1 )
        end
        
        local db_val
        if DATA.extstate.CONF_action==1 then 
          id = id + 1
          local dBrange = 10
          if DATA.extstate.CONF_randsymflags&4==4 and DATA.extstate.CONF_randsymflags&32~=32 then
            db_val = -dBrange*math.abs(t_rand[id])
           elseif DATA.extstate.CONF_randsymflags&(4|32)==(4|32) then
            db_val = -dBrange-dBrange*-math.abs(t_rand[id])
           else
            db_val = -dBrange*math.random()
          end
          
          local panout = t_rand[id]
          local pan_rand = 0.1 if DATA.extstate.CONF_randsymflags&8==8 then panout = VF_lim(panout + math.random()*pan_rand-pan_rand/2,-1,1) end
          local db_rand = 1 if DATA.extstate.CONF_randsymflags&16==16 then db_val = db_val + math.random()*db_rand-db_rand/2 end
          local volout =  WDL_DB2VAL(db_val)
          SetMediaTrackInfo_Value(DATA2.tracks[GUID].ptr, 'D_PAN', panout)
          SetMediaTrackInfo_Value(DATA2.tracks[GUID].ptr, 'D_VOL', volout )
        end
        
      end end
      
    -- refresh
    local ID = DATA.GUI.custom_currentsnapshotID or 1 
    DATA2:tracks_init(true)
    DATA2:Snapshot_WriteCurrent(ID)
    DATA2:Snapshot_Write()
    DATA2:GUI_inittracks(DATA)
  end
  ------------------------------------------------------------------------------------------------------
  function DATA2:Snapshot_Read()
    DATA2.Snapshots = {}
    for ID = 1, DATA.extstate.CONF_snapshcnt do
      local retval, s_state = GetProjExtState(0, 'MPL_VisMix', 'SNAPSHOT'..ID  )
      if retval and s_state ~= '' then
        DATA2.Snapshots[ID] = {}
        local retval, s_col = GetProjExtState(0, 'MPL_VisMix', 'SNAPSHOT'..ID..'col'  )
        if retval and s_col ~= '' then DATA2.Snapshots[ID].col = s_col end
        local retval, txt = GetProjExtState(0, 'MPL_VisMix', 'SNAPSHOT'..ID..'txt'  )
        if retval then DATA2.Snapshots[ID].txt = txt or '' end
        for line in s_state:gmatch('[^\r\n]+') do
          local t = {}
          for val in line:gmatch('[^%s]+') do t [#t+1] = val end
          if #t == 4 then
            local GUID = t[1]
            if GUID then 
              DATA2.Snapshots[ID][GUID] = {
                                  vol = tonumber(t[2]),
                                  pan = tonumber(t[3]),
                                  width = tonumber(t[4]),
                                  }
            end
          end      
        end
        
      end
    end
  end
  ------------------------------------------------------------------------------------------------------
  function DATA2:Snapshot_Reset(ID)  
    if not DATA2.Snapshots[ID] then return end
    for GUID in pairs(DATA2.Snapshots[ID]) do
      local tr = VF_GetTrackByGUID(GUID)
      if tr then
        SetTrackSelected( tr, true )
        SetMediaTrackInfo_Value( tr, 'D_PAN', 0)
        SetMediaTrackInfo_Value( tr, 'D_VOL', 1)
        SetMediaTrackInfo_Value( tr, 'D_WIDTH', 1)
        SetMediaTrackInfo_Value( tr, 'I_PANMODE', 0)
      end
    end
  end
  ------------------------------------------------------------------------------------------------------
  function DATA2:Snapshot_Recall_persist()
    local ID = DATA2.Recall_newID
    local oldID = DATA2.Recall_oldID
    local Recall_state = DATA2.Recall_state
    for GUID in pairs(DATA2.Snapshots[ID]) do
      if GUID:match('{') then
        local tr = DATA2.Snapshots[ID][GUID].tr_ptr
        if not tr then 
          tr = VF_GetTrackByGUID(GUID)
          DATA2.Snapshots[ID][GUID].tr_ptr = tr
        end
        if tr then
          SetTrackSelected( tr, true )
          if DATA2.Snapshots[oldID][GUID] then
            SetMediaTrackInfo_Value( tr, 'D_PAN', DATA2.Snapshots[oldID][GUID].pan + (DATA2.Snapshots[ID][GUID].pan - DATA2.Snapshots[oldID][GUID].pan)*Recall_state)
            SetMediaTrackInfo_Value( tr, 'D_VOL', DATA2.Snapshots[oldID][GUID].vol + (DATA2.Snapshots[ID][GUID].vol - DATA2.Snapshots[oldID][GUID].vol)*Recall_state)
            SetMediaTrackInfo_Value( tr, 'D_WIDTH', DATA2.Snapshots[oldID][GUID].width + (DATA2.Snapshots[ID][GUID].width - DATA2.Snapshots[oldID][GUID].width)*Recall_state)
            SetMediaTrackInfo_Value( tr, 'I_PANMODE', 5)
          end
        end
      end
    end
  end
  ------------------------------------------------------------------------------------------------------
  function DATA2:Snapshot_Recall(ID,oldID)
    if not (ID and DATA2.Snapshots and DATA2.Snapshots[ID] and DATA2.Snapshots[oldID]) then return end 
    Action(40297) -- unselect all tracks
    
    if oldID and DATA.extstate.CONF_snapshrecalltime > 0 then 
      DATA2.Recall_timer = DATA.extstate.CONF_snapshrecalltime
      DATA2.Recall_newID = ID
      DATA2.Recall_oldID = oldID
      for GUID in pairs(DATA2.Snapshots[ID]) do     if GUID:match('{') then DATA2.Snapshots[ID][GUID].tr_ptr = nil end end
      for GUID in pairs(DATA2.Snapshots[oldID]) do  if GUID:match('{') then DATA2.Snapshots[oldID][GUID].tr_ptr = nil end end
      return 
    end
    
    reaper.Undo_BeginBlock2( 0 )
    for GUID in pairs(DATA2.Snapshots[ID]) do
      if GUID:match('{') then
        local tr = VF_GetTrackByGUID(GUID)
        if tr then
          SetTrackSelected( tr, true )
          SetMediaTrackInfo_Value( tr, 'D_PAN', DATA2.Snapshots[ID][GUID].pan)
          SetMediaTrackInfo_Value( tr, 'D_VOL', DATA2.Snapshots[ID][GUID].vol)
          SetMediaTrackInfo_Value( tr, 'D_WIDTH', DATA2.Snapshots[ID][GUID].width)
          SetMediaTrackInfo_Value( tr, 'I_PANMODE', 5)
        end
      end
    end
    reaper.Undo_EndBlock2( 0, 'Visual mixer shapshot recall', 0xFFFFFFFF )
  end
  ---------------------------------------------------
  function DATA2:Snapshot_Write()  
    for ID = 1, DATA.extstate.CONF_snapshcnt do
      if DATA2.Snapshots[ID] then 
        if DATA2.Snapshots[ID].col then SetProjExtState(0, 'MPL_VisMix', 'SNAPSHOT'..ID..'col', DATA2.Snapshots[ID].col  )  end
        if DATA2.Snapshots[ID].txt then SetProjExtState(0, 'MPL_VisMix', 'SNAPSHOT'..ID..'txt', DATA2.Snapshots[ID].txt  )  end
        local str = ''
        for GUID in pairs(DATA2.Snapshots[ID]) do
          if GUID:match('{') then
          str = str..
                 GUID..' '..
                 DATA2.Snapshots[ID][GUID].vol..' '..
                 DATA2.Snapshots[ID][GUID].pan..' '..
                 DATA2.Snapshots[ID][GUID].width..'\n'
          end
        end
        if str then SetProjExtState(0, 'MPL_VisMix', 'SNAPSHOT'..ID, str  )  end 
       else
        SetProjExtState(0, 'MPL_VisMix', 'SNAPSHOT'..ID, ''  )
      end
    end
  end
  ---------------------------------------------------
  function DATA2:Snapshot_WriteCurrent(ID)
    if not DATA2.Snapshots[ID] then DATA2.Snapshots[ID] = {} end
    local tremove={}
    for key in pairs(DATA2.Snapshots[ID]) do if key:match('{') then tremove[#tremove+1] = key end end
    for i=1,#tremove do DATA2.Snapshots[ID][tremove[i]] = nil end
    
    for GUID in pairs(DATA2.tracks) do
      if not DATA2.Snapshots[ID][GUID] then DATA2.Snapshots[ID][GUID] = {} end 
      DATA2.Snapshots[ID][GUID].vol = DATA2.tracks[GUID].vol
      DATA2.Snapshots[ID][GUID].pan = DATA2.tracks[GUID].pan
      DATA2.Snapshots[ID][GUID].width = DATA2.tracks[GUID].width
    end
  end
  
  
  -----------------------------------------------
  function GUI_Scale_GetXPosFromPan(pan, GUID)
    if not DATA.GUI.buttons.scale then return end
    local area = DATA.GUI.buttons.scale.w - DATA.extstate.CONF_tr_rect_px
    if pan then 
      local outx = 0
      if DATA.extstate.UI_extendcenter  == 0 then outx = DATA.GUI.buttons.scale.x + DATA.extstate.CONF_tr_rect_px/2 + area * (pan + 1) / 2 end
      if DATA.extstate.UI_extendcenter  > 0  then 
        if pan == 0 then 
          outx = DATA.GUI.buttons.scale.x + DATA.GUI.buttons.scale.w/2
          if GUID and DATA2.tracks[GUID] and DATA2.tracks[GUID].center_area then
            areaoff = DATA.GUI.custom_extendcenter * DATA2.tracks[GUID].center_area
            outx = outx -DATA.GUI.custom_extendcenter/2+ areaoff
          end
         elseif pan >0 then 
          outx = DATA.GUI.buttons.scale.x + DATA.GUI.buttons.scale.w/2 + DATA.GUI.custom_extendcenter /2 + pan * ((DATA.GUI.buttons.scale.w-DATA.GUI.custom_extendcenter)/2-DATA.extstate.CONF_tr_rect_px/2)         
         elseif pan <0 then 
          outx = DATA.GUI.buttons.scale.x + (1+pan) * ((DATA.GUI.buttons.scale.w-DATA.GUI.custom_extendcenter)/2-DATA.extstate.CONF_tr_rect_px/2)+DATA.extstate.CONF_tr_rect_px/2
        end 
      end
      return outx 
    end
  end 
  ----------------------------------------------------------------------  
  function DATA2:TrackMap_ApplyTrParam(GUID, parmname, newvalue)
    local tr = VF_GetTrackByGUID(GUID)
    if not tr then return end
    SetMediaTrackInfo_Value( tr, parmname, newvalue )
  end
  ---------------------------------------------------------------------  
  function DATA2:TrackMap_ApplyTrPan(GUID, Xval, panout) 
    local tr = VF_GetTrackByGUID(GUID)
    if not tr then return end
    if not Xval then panout = DATA2.tracks[GUID].pan end
    local pan,area,wsz
    if not panout then 
      wsz = (DATA.GUI.buttons['trackrect'..GUID].w or DATA.extstate.CONF_tr_rect_px)
      area = DATA.GUI.buttons.scale.w - wsz
      
      if DATA.extstate.UI_extendcenter  == 0  then pan = (-0.5+(Xval - DATA.GUI.buttons.scale.x) / area )*2  end
      if DATA.extstate.UI_extendcenter  > 0  then 
        local xcent = Xval + DATA.extstate.CONF_tr_rect_px/2
        if xcent >= DATA.GUI.buttons.scale.x+DATA.GUI.buttons.scale.w/2 - DATA.GUI.custom_extendcenter/2 and xcent <= DATA.GUI.buttons.scale.x+DATA.GUI.buttons.scale.w/2 + DATA.GUI.custom_extendcenter/2 then  
          pan = 0 
          Xnorm = (xcent-(DATA.GUI.buttons.scale.x+DATA.GUI.buttons.scale.w/2 - DATA.GUI.custom_extendcenter/2)) / DATA.GUI.custom_extendcenter
          GetSetMediaTrackInfo_String( tr, 'P_EXT:MPL_VISMIX_centerarea', Xnorm, true )
        end
        if xcent <= DATA.GUI.buttons.scale.x+DATA.GUI.buttons.scale.w/2 - DATA.GUI.custom_extendcenter/2 then 
          pan = (Xval-DATA.GUI.buttons.scale.x)/( (DATA.GUI.buttons.scale.w-DATA.GUI.custom_extendcenter)/2-DATA.extstate.CONF_tr_rect_px/2)-1 
        end
        if xcent >= DATA.GUI.buttons.scale.x+DATA.GUI.buttons.scale.w/2 + DATA.GUI.custom_extendcenter/2 then
          local comw = -1+(DATA.GUI.buttons.scale.w-DATA.GUI.custom_extendcenter)/2 - DATA.extstate.CONF_tr_rect_px/2
          local Xnorm = xcent - (DATA.GUI.buttons.scale.x+DATA.GUI.buttons.scale.w/2 + DATA.GUI.custom_extendcenter/2)
          pan = Xnorm/comw
        end
      end
      
      
     else
      pan = panout
    end
    
    
    if DATA.extstate.CONF_quantizepan >0 then 
        m = 100/DATA.extstate.CONF_quantizepan
        pan = pan*m
        pan=math.floor(pan)
        pan = pan/m
    end 
    SetTrackUIPan( tr, pan, false, false,1|2)
    if GetMediaTrackInfo_Value( tr, 'I_PANMODE' ) == 6 and DATA2.tracks[GUID] and DATA2.tracks[GUID].width then 
      local width = (1-math.abs(pan)) * DATA2.tracks[GUID].width
      local panL = VF_lim(pan-width,-1,1)
      local panR = VF_lim(pan+width,-1,1)
      SetTrackUIPan( tr, panL, false, false,1|2)
      SetTrackUIWidth( tr, panR, false, false,1|2)
      SetMediaTrackInfo_Value( tr, 'D_DUALPANL', panL)
      SetMediaTrackInfo_Value( tr, 'D_DUALPANR', panR) 
    end
    return pan
  end
  
  
  
  
  -----------------------------------------------
  function GUI_Scale_GetWPosFromW(GUID)
    local width = DATA2.tracks[GUID].width
    if not width then return 1 end 
    local width = math.abs(width)*(1-DATA.GUI.custom_minw_ratio) + DATA.GUI.custom_minw_ratio
    local src_w = DATA.GUI.buttons['trackrect'..GUID].w
    return src_w * width
  end
  ----------------------------------------------------------------------  
  function DATA2:TrackMap_ApplyTrWidth(GUID,Wval) 
    local tr = VF_GetTrackByGUID(GUID)
    if not tr then return end 
    local width = ((Wval / DATA.GUI.buttons['trackrect'..GUID].w)-DATA.GUI.custom_minw_ratio)/(1-DATA.GUI.custom_minw_ratio) 
    if GetMediaTrackInfo_Value( tr, 'I_PANMODE' ) == 6 then
      SetMediaTrackInfo_Value( tr, 'D_WIDTH',width)
      DATA2.tracks[GUID].width = width
      DATA2:TrackMap_ApplyTrPan(GUID)
     elseif GetMediaTrackInfo_Value( tr, 'I_PANMODE' ) == 5 then
      SetTrackUIWidth( tr, width, false, false,1|2)
    end
    return width
  end
  
  
  
  -----------------------------------------------
  function GUI_Scale_GetYPosFromdB(db_val)
    local y_calc= DATA.GUI.buttons.scale.y + DATA.GUI.custom_areaspace
    if not db_val then return 0 end 
    local linearval = 1-GUI_Scale_Convertion(db_val)
    if DATA.extstate.CONF_invertYscale == 1 then linearval = GUI_Scale_Convertion(db_val) end 
    local area = DATA.GUI.buttons.scale.h - DATA.GUI.CONF_tr_rect_px
    return linearval *  area + y_calc
  end
  ----------------------------------------------------------------------  
  function DATA2:TrackMap_ApplyTrVol(GUID, Yval, val0) 
    local tr = VF_GetTrackByGUID(GUID)
    if not tr then return end
    
    local val
    if not val0 then
      local y_calc= DATA.GUI.buttons.scale.y + DATA.GUI.custom_areaspace
      local area = DATA.GUI.buttons.scale.h - DATA.GUI.CONF_tr_rect_px
      val =  1-  ( Yval -  y_calc+DATA.GUI.CONF_tr_rect_px/2)/ area
      if DATA.extstate.CONF_invertYscale == 1 then val =  ( Yval -  y_calc+DATA.GUI.CONF_tr_rect_px/2)/ area end
     else
      val = val0
    end 
    
    local db_val = GUI_Scale_Convertion(nil,val)
    if DATA.extstate.CONF_quantizevolume >0 then 
      local q = 10^DATA.extstate.CONF_quantizevolume
      db_val=math.floor(db_val*q)/q
    end
    local volout = VF_lim(WDL_DB2VAL(db_val),0,3.99)
    SetTrackUIVolume( tr, volout, false, false,1|2)
    return db_val
  end
  

  
  
  ---------------------------- 
  function DATA2:GUI_inittracks_refreshXY(DATA, GUID) 
    local xpos = GUI_Scale_GetXPosFromPan (DATA2.tracks[GUID].pan, GUID)-DATA.extstate.CONF_tr_rect_px/2
    local ypos = GUI_Scale_GetYPosFromdB  (DATA2.tracks[GUID].vol_dB)   -DATA.GUI.CONF_tr_rect_px/2
    DATA.GUI.buttons['trackrect'..GUID].x=xpos
    DATA.GUI.buttons['trackrect'..GUID].y=ypos
    DATA.GUI.buttons['trackrect'..GUID].refresh = true
  end
  ---------------------------------------------------------------------  
  function DATA2:GUI_inittracks_initstuff(DATA,GUID)  
    local xpos = DATA.GUI.buttons['trackrect'..GUID].x
    local ypos = DATA.GUI.buttons['trackrect'..GUID].y
    local wsz = DATA.GUI.buttons['trackrect'..GUID].w
    local hsz = DATA.GUI.buttons['trackrect'..GUID].h
    local frame_col = DATA.GUI.buttons['trackrect'..GUID].frame_col
    
    -- WIDTH ctrl --
    local wtr = GUI_Scale_GetWPosFromW   (GUID)
    if not DATA.GUI.buttons['trackrect'..GUID..'widthhandle'] then
      DATA.GUI.buttons['trackrect'..GUID..'widthhandle']={x=xpos+wsz/2-wtr/2,
                          y=ypos+hsz,
                          w=wtr,
                          h=DATA.GUI.custom_trwidthhandleh,
                          backgr_fill = 0.2,
                          backgr_col = '#FFFFFF',--frame_col,
                          frame_a =0.1,
                          frame_col =frame_col,
                          val=0,
                          val_xaxis = true,
                          val_res=0.05,
                          refresh = true,
                          
                          onmouseclick = function() 
                                            DATA2.latchctrls = GUID
                                            DATA.GUI.buttons['trackrect'..GUID..'widthhandle'].latch_w = DATA.GUI.buttons['trackrect'..GUID..'widthhandle'].w
                                          end,
                          onmousedrag = function()
                                          if DATA2.latchctrls and DATA2.latchctrls ~= GUID then return end
                                          DATA2.ontrackobj = true
                                          if DATA.GUI.mouse_ismoving then 
                                            local wout = VF_lim(DATA.GUI.buttons['trackrect'..GUID..'widthhandle'].latch_w + DATA.GUI.dx/DATA.GUI.default_scale, DATA.GUI.buttons['trackrect'..GUID].w*DATA.GUI.custom_minw_ratio,DATA.GUI.buttons['trackrect'..GUID].w)
                                            DATA.GUI.buttons['trackrect'..GUID..'widthhandle'].w = wout
                                            DATA.GUI.buttons['trackrect'..GUID..'widthhandle'].x= DATA.GUI.buttons['trackrect'..GUID].x + DATA.GUI.buttons['trackrect'..GUID].w/2 - wout/2
                                            local w_ret = DATA2:TrackMap_ApplyTrWidth(GUID,wout) 
                                            DATA2.info_txt = DATA2.tracks[GUID].name..'\nWidth '..(math.floor(w_ret*1000)/10)..'%'
                                          end
                                        end,
                          onmouserelease =  function()
                                              DATA2.info_txt = nil
                                              DATA2.latchctrls = nil
                                              DATA2.ontrackobj = false
                                              DATA2:tracks_init(true)
                                              local ID = DATA.GUI.custom_currentsnapshotID or 1
                                              DATA2:Snapshot_WriteCurrent(ID)
                                              DATA2:Snapshot_Write()
                                            end
                          } 
     else 
      local wtr = GUI_Scale_GetWPosFromW   (GUID)
      DATA.GUI.buttons['trackrect'..GUID..'widthhandle'].x=xpos+wsz/2-wtr/2
      DATA.GUI.buttons['trackrect'..GUID..'widthhandle'].y=ypos+hsz
      DATA.GUI.buttons['trackrect'..GUID..'widthhandle'].w=wtr
    end
    
    -- FOLDER RECT --
    if DATA2.tracks[GUID].I_FOLDERDEPTH == 1 then 
      DATA.GUI.buttons['trackrect'..GUID..'isfolder']={x=xpos+DATA.extstate.CONF_tr_rect_px-DATA.GUI.custom_foldrect,
                            y=ypos+DATA.GUI.CONF_tr_rect_px-DATA.GUI.custom_foldrect,
                            w=DATA.GUI.custom_foldrect,
                            h=DATA.GUI.custom_foldrect,
                            backgr_fill = 0.4,
                            backgr_col = '#FFFFFF',
                            frame_a =0,
                            refresh = true,
                            ignoremouse = true}
    end
    
    -- NAME --
    local infotxt = DATA2.tracks[GUID].name
    local w_txt = gfx.measurestr(infotxt) 
    local txtout = ''
    if DATA.extstate.UI_showtracknames ==1 and (DATA.extstate.UI_showtracknames_flags&1==0 or (DATA.extstate.UI_showtracknames_flags&1==1 and not DATA2.tracks[GUID].icon_fp)) then 
        DATA.GUI.buttons['trackrect'..GUID..'info']={x=xpos+wsz/2-w_txt/2,
                            y=ypos+hsz+DATA.GUI.custom_trwidthhandleh,
                            w=w_txt,
                            h=DATA.GUI.custom_txtfontszinfo*DATA.GUI.default_scale,
                            frame_a =0,
                            refresh = true,
                            txt_fontsz = DATA.GUI.custom_txtfontszinfo,
                            txt_flags = 1,
                            txt = infotxt,
                            ignoremouse = true}
    end
    
    DATA2:GUI_inittracks_initstuff_topconrols(DATA,GUID,xpos,ypos) 
  end
    
  ---------------------------------------------------------------------  
  function DATA2:GUI_inittracks_initstuff_topconrols(DATA,GUID,xpos,ypos)  
    local xoffs= xpos
    local solosz = math.max(DATA.GUI.custom_butside,math.floor(DATA.extstate.CONF_tr_rect_px*0.25))
    -- SOLO --
    if not DATA.GUI.buttons['trackrect'..GUID..'solo'] then
      local backgr_fill  =DATA.GUI.custom_backgr_fill_disabled if DATA2.tracks[GUID].solo == true then backgr_fill = DATA.GUI.custom_backgr_fill_enabled end
      DATA.GUI.buttons['trackrect'..GUID..'solo']={x=xoffs,
                          y=ypos-solosz,
                          w=solosz-1,
                          h=solosz-1,
                          txt = 'S',
                          txt_fontsz = DATA.GUI.custom_butstuff,
                          backgr_fill = backgr_fill,
                          backgr_col = '#00FF00',
                          frame_a =0.1,
                          frame_col =frame_col,
                          refresh = true,
                          hide = DATA.extstate.UI_showtopctrl_flags&1~=1,
                          onmouserelease =  function()
                                              local solo = 2
                                              if DATA2.tracks[GUID].solo == true then solo = 0 end
                                              DATA2:TrackMap_ApplyTrParam(GUID, 'I_SOLO', solo)
                                              DATA2:tracks_init(true)
                                              DATA2:GUI_inittracks(DATA) 
                                            end
                          }
     else 
      DATA.GUI.buttons['trackrect'..GUID..'solo'].x=xpos
      DATA.GUI.buttons['trackrect'..GUID..'solo'].y=ypos-solosz
    end  
    if DATA.extstate.UI_showtopctrl_flags&1==1 then xoffs = xpos+solosz end
    
    -- MUTE --
    if not DATA.GUI.buttons['trackrect'..GUID..'mute'] then
      local backgr_fill  =DATA.GUI.custom_backgr_fill_disabled if DATA2.tracks[GUID].mute == true then backgr_fill = DATA.GUI.custom_backgr_fill_enabled end
      DATA.GUI.buttons['trackrect'..GUID..'mute']={x=xoffs,
                          y=ypos-solosz,
                          w=solosz-1,
                          h=solosz-1,
                          txt = 'M',
                          txt_fontsz = DATA.GUI.custom_butstuff,
                          backgr_fill = backgr_fill,
                          backgr_col = '#FF0F0F',
                          frame_a =0.1,
                          frame_col =frame_col,
                          refresh = true,
                          hide = DATA.extstate.UI_showtopctrl_flags&2~=2,
                          onmouserelease =  function()
                                              local mute = 1
                                              if DATA2.tracks[GUID].mute == true then mute = 0 end
                                              DATA2:TrackMap_ApplyTrParam(GUID, 'B_MUTE', mute)
                                              DATA2:tracks_init(true)
                                              DATA2:GUI_inittracks(DATA) 
                                            end
                          } 
     else 
      --if DATA.extstate.UI_showtopctrl_flags&1==1 then xoffs = xpos+solosz end
      DATA.GUI.buttons['trackrect'..GUID..'mute'].x=xoffs 
      DATA.GUI.buttons['trackrect'..GUID..'mute'].y=ypos-solosz                       
    end
    if DATA.extstate.UI_showtopctrl_flags&2==2 then xoffs = xoffs+solosz end
    
    -- FX --
    if not DATA.GUI.buttons['trackrect'..GUID..'fx'] then
      local backgr_fill  =DATA.GUI.custom_backgr_fill_disabled
      DATA.GUI.buttons['trackrect'..GUID..'fx']={x=xoffs,
                          y=ypos-solosz,
                          w=solosz-1,
                          h=solosz-1,
                          txt = 'FX',
                          txt_fontsz = DATA.GUI.custom_butstuff,
                          backgr_fill = backgr_fill,
                          --backgr_col = '#FF0F0F',
                          frame_a =0.1,
                          --frame_col =frame_col,
                          refresh = true,
                          hide = DATA.extstate.UI_showtopctrl_flags&4~=4,
                          onmouserelease =  function()
                                              reaper.TrackFX_Show( DATA2.tracks[GUID].ptr, 0, 1 )
                                            end
                          } 
     else 
      --if DATA.extstate.UI_showtopctrl_flags&2==2 then xoffs = xpos+solosz end
      DATA.GUI.buttons['trackrect'..GUID..'fx'].x=xoffs 
      DATA.GUI.buttons['trackrect'..GUID..'fx'].y=ypos-solosz                       
    end
    if DATA.extstate.UI_showtopctrl_flags&4==4 then xoffs = xoffs+solosz end
    
    -- ext1 
    if DATA.extstate.UI_showtopctrl_flags&8==8 then 
      if not DATA.GUI.buttons['trackrect'..GUID..'ext1'] then
        local backgr_fill  =DATA.GUI.custom_backgr_fill_disabled
        DATA.GUI.buttons['trackrect'..GUID..'ext1']={x=xoffs,
                            y=ypos-solosz,
                            w=solosz-1,
                            h=solosz-1,
                            val = DATA2.tracks[GUID].ext1,
                            backgr_usevalue = true,
                            backgr_fill2 = 0.5,
                            backgr_col2 = '#FFFFFF',
                            frame_a =0.1,
                            refresh = true,
                            } 
       else 
        DATA.GUI.buttons['trackrect'..GUID..'ext1'].x=xoffs 
        DATA.GUI.buttons['trackrect'..GUID..'ext1'].y=ypos-solosz                       
      end
      xoffs = xoffs+solosz 
    end
    
  end
  
  -----------------------------------------------
  function GUI_Scale3D_GetNormXPosFromPan(pan)
    return (pan+1)/2
  end 
  -----------------------------------------------
  function GUI_Scale3D_GetNormZPosFromVol(vol)
    local vol = VF_lim(vol, 0,6)  /2 
    return vol
  end
  ---------------------------------------------------------------------  
  function DATA2:GUI_inittracks_onmouseclick(DATA, GUID) 
    -- normal click 
      if not (DATA.GUI.Ctrl==true or DATA.GUI.Alt==true or DATA.GUI.Shift==true) then
        DATA2.latchctrls = GUID
        DATA2.ontrackobj = true
        --for GUID in pairs(DATA2.tracks) do if DATA.GUI.buttons['trackrect'..GUID] then DATA.GUI.buttons['trackrect'..GUID].sel_isselected = false end end -- reset selection  
        -- 31.03.24 2.27 prevent track to be both selected if placed one under another
        local cntsel = 0
        for GUID in pairs(DATA2.tracks) do 
          if DATA.GUI.buttons['trackrect'..GUID] and DATA.GUI.buttons['trackrect'..GUID].sel_isselected == true then cntsel = cntsel  +1 end  
          if cntsel > 0 then break end
        end
        if cntsel == 0 then DATA.GUI.buttons['trackrect'..GUID].sel_isselected = true end
        --DATA.GUI.buttons['trackrect'..GUID].sel_isselected = true
      end
      
    -- ctrl click
      if DATA.GUI.Ctrl==true and not (DATA.GUI.Alt==true or DATA.GUI.Shift==true) then
        DATA2.latchctrls = GUID
        DATA2.ontrackobj = true
        DATA.GUI.buttons['trackrect'..GUID].sel_isselected = true
      end    

    -- reset latch
    for GUID in pairs(DATA2.tracks) do
      if DATA.GUI.buttons['trackrect'..GUID] then
        DATA.GUI.buttons['trackrect'..GUID].latch_x = nil
        DATA.GUI.buttons['trackrect'..GUID].latch_y = nil
      end
    end
    if DATA.extstate.UI_3dmode == 1 then 
      DATA.GUI.buttons['trackrect'..GUID].latch_AXx = nil
      DATA.GUI.buttons['trackrect'..GUID].latch_AXy = nil
      DATA.GUI.buttons['trackrect'..GUID].latch_AXz = nil
    end
    
  end
  ---------------------------------------------------------------------  
  function DATA2:GUI_inittracks_onmousedrag3D(DATA, GUID) 
  
    -- normal drag
      if not (DATA.GUI.Alt ==true or DATA.GUI.Shift==true) then
        if DATA2.latchctrls and DATA2.latchctrls ~= GUID then return end
        DATA2.ontrackobj = true
        if DATA.GUI.mouse_ismoving then 
          for GUID in pairs(DATA2.tracks) do
            if DATA.GUI.buttons['trackrect'..GUID].sel_isselected == true then
            
              -- add latch if not found
              if not DATA.GUI.buttons['trackrect'..GUID].latch_AXx then
                DATA.GUI.buttons['trackrect'..GUID].latch_AXx = DATA.GUI.buttons['trackrect'..GUID].AXx
                DATA.GUI.buttons['trackrect'..GUID].latch_AXy = DATA.GUI.buttons['trackrect'..GUID].AXy
                DATA.GUI.buttons['trackrect'..GUID].latch_AXz = DATA.GUI.buttons['trackrect'..GUID].AXz
              end 
              
              
              -- move oblects
              local AXx = VF_lim(DATA.GUI.buttons['trackrect'..GUID].latch_AXx + 2*(DATA.GUI.dx/DATA.GUI.default_scale)/DATA.GUI.buttons.scale.w) 
              local AXy = 0.5
              local AXz = VF_lim(DATA.GUI.buttons['trackrect'..GUID].latch_AXz + 2*(DATA.GUI.dy/DATA.GUI.default_scale)/DATA.GUI.buttons.scale.h) 
              DATA.GUI.buttons['trackrect'..GUID].AXx = AXx
              DATA.GUI.buttons['trackrect'..GUID].AXy = AXy
              DATA.GUI.buttons['trackrect'..GUID].AXz = AXz
              DATA2:GUI3D_SetXYWHbyXYZ(DATA,GUID,AXx,AXy,AXz)
              
              --[[local ret, x,y,w,h = DATA2:GUI3D_Convertion_GetXYWHbyGUID(DATA,GUID,x0,y0,z0)
              
              DATA.GUI.buttons['trackrect'..GUID].x = x
              DATA.GUI.buttons['trackrect'..GUID].y = y
              DATA.GUI.buttons['trackrect'..GUID].w = w
              DATA.GUI.buttons['trackrect'..GUID].h = h
              DATA.GUI.buttons['trackrect'..GUID].refresh = true
              
              local val_lin, panout = DATA2:GUI3D_Convertion_GetVolPanfromXYZ(DATA,GUID,x0,y0,z0)
              
              -- apply values from objects
              local pan = DATA2:TrackMap_ApplyTrPan(GUID,DATA.GUI.buttons['trackrect'..GUID].x, nil, panout) 
              local db_val = DATA2:TrackMap_ApplyTrVol(GUID,DATA.GUI.buttons['trackrect'..GUID].y,nil,val_lin ) 
              
              DATA2:GUI_inittracks_initstuff(DATA,GUID )
              local volform = math.floor(db_val*100000)/100000
              DATA2.info_txt = DATA2.tracks[GUID].name..'\nVolume '..volform..'dB\nPan '..(math.floor(pan*10000)/100)..'%'
              ]]
            end 
          end
        end
      end
    
  end
  ---------------------------------------------------------------------  
  function DATA2:GUI_inittracks_onmousedrag(DATA, GUID) 
    DATA2.ontrackdrag = true
    -- normal drag
      if not (DATA.GUI.Alt ==true or DATA.GUI.Shift==true) then
        if DATA2.latchctrls and DATA2.latchctrls ~= GUID then return end
        if DATA.GUI.mouse_ismoving then 
          DATA2.ontrackobj = true
          for GUID in pairs(DATA2.tracks) do
            if DATA.GUI.buttons['trackrect'..GUID] then
              if DATA.GUI.buttons['trackrect'..GUID].sel_isselected == true then
              
                -- add latch if not found
                if not DATA.GUI.buttons['trackrect'..GUID].latch_x then
                  DATA.GUI.buttons['trackrect'..GUID].latch_x = DATA.GUI.buttons['trackrect'..GUID].x
                  DATA.GUI.buttons['trackrect'..GUID].latch_y = DATA.GUI.buttons['trackrect'..GUID].y
                end 
                
                -- move oblects 
                if not DATA.GUI.Ctrl then
                  DATA.GUI.buttons['trackrect'..GUID].x = VF_lim(DATA.GUI.buttons['trackrect'..GUID].latch_x + DATA.GUI.dx/DATA.GUI.default_scale, DATA.GUI.buttons.scale.x , DATA.GUI.buttons.scale.x+DATA.GUI.buttons.scale.w-DATA.extstate.CONF_tr_rect_px) 
                end
                DATA.GUI.buttons['trackrect'..GUID].y = VF_lim(DATA.GUI.buttons['trackrect'..GUID].latch_y + DATA.GUI.dy/DATA.GUI.default_scale, DATA.GUI.buttons.scale.y, DATA.GUI.buttons.scale.y+DATA.GUI.buttons.scale.h-DATA.GUI.CONF_tr_rect_px) 
                DATA.GUI.buttons['trackrect'..GUID].refresh = true
                
                -- apply values from objects
                local db_val = DATA2:TrackMap_ApplyTrVol(GUID,DATA.GUI.buttons['trackrect'..GUID].y) 
                local pan
                if not DATA.GUI.Ctrl  then
                  pan = DATA2:TrackMap_ApplyTrPan(GUID,DATA.GUI.buttons['trackrect'..GUID].x) 
                end
                DATA2:GUI_inittracks_initstuff(DATA,GUID )
                local volform = math.floor(db_val*100000)/100000
                DATA2.info_txt = DATA2.tracks[GUID].name..'\nVolume '..volform..'dB'
                if pan then DATA2.info_txt = DATA2.info_txt..'\nPan '..(math.floor(pan*10000)/100)..'%' end
                
              end 
            end
          end
        end
      end
    
  end
  ---------------------------------------------------------------------  
  function DATA2:GUI_inittracks_onwheeltrig(DATA, GUID,dir)
    if dir then dir = -1 else dir = 1 end
    if DATA.GUI.buttons['trackrect'..GUID] then 
    
      -- set ext value
      local ret,val = GetSetMediaTrackInfo_String( DATA2.tracks[GUID].ptr, 'P_EXT:MPL_VISMIX_ext1', 0, false )
      if not ret or (ret and not tonumber(val)) then val = 0 end
      local out = VF_lim(val+dir*0.025)
      GetSetMediaTrackInfo_String( DATA2.tracks[GUID].ptr, 'P_EXT:MPL_VISMIX_ext1', out, true )
      DATA.GUI.buttons['trackrect'..GUID].ext1 = out
      
      -- apply
      if DATA.extstate.UI_extcontrol1dest == 1 then
         SetTrackSendInfo_Value( DATA2.tracks[GUID].ptr, 0, 0, 'D_VOL',  WDL_DB2VAL(SLIDER2DB( (out^0.2)*920 )) )
      end
    end
    
    Undo_OnStateChangeEx2( 0, 'MPL Visual mixer change', 1, -1 )
    
    DATA2:tracks_init(true)
    DATA2:GUI_inittracks(DATA) 
    
    DATA2.latchctrls = nil
    DATA2.info_txt = nil
    local ID = DATA.GUI.custom_currentsnapshotID or 1 
    DATA2:Snapshot_WriteCurrent(ID)
    DATA2:Snapshot_Write()
    DATA2.ontrackobj = false 
    DATA2.preventrefresh = true
    
  end
    --------------------------------------------------------------------- 
  function DATA2:GUI_inittracks_onmouserelease(DATA, GUID)
    DATA2:GUI_inittracks_initstuff(DATA,GUID )
                  
    -- handle alt / shift release
      if (DATA.GUI.Alt==true or DATA.GUI.Shift==true) then
        for GUID in pairs(DATA2.tracks) do 
          if DATA.GUI.buttons['trackrect'..GUID] then
            if DATA.GUI.buttons['trackrect'..GUID].sel_isselected == true then
              if DATA.GUI.Alt == true then SetMediaTrackInfo_Value(DATA2.tracks[GUID].ptr, 'D_VOL',1) end
              if DATA.GUI.Shift == true then SetMediaTrackInfo_Value(DATA2.tracks[GUID].ptr, 'D_PAN',0) end
            end 
          end
        end 
        DATA2:tracks_init(true)
        DATA2:GUI_inittracks(DATA) 
      end

    Undo_OnStateChangeEx2( 0, 'MPL Visual mixer change', 1, -1 )
    --msg( DATA2:count_selection(DATA))
    if DATA2.ontrackdrag and  DATA2:count_selection(DATA) == 1 and not DATA.GUI.Ctrl then
      DATA2:tracks_init(true)
      DATA2:GUI_inittracks(DATA) 
      DATA2:reset_selection(DATA) 
      DATA2.ontrackdrag = nil
    end
    
    DATA2.latchctrls = nil
    DATA2.info_txt = nil
    local ID = DATA.GUI.custom_currentsnapshotID or 1 
    DATA2:Snapshot_WriteCurrent(ID)
    DATA2:Snapshot_Write()
    DATA2.ontrackobj = false 
    DATA2.preventrefresh = true
  end
  ---------------------------------------------------------------------  
  function DATA2:GUI3D_SetXYWHbyXYZ(DATA,GUID,x0,y0,z0)
    local ptsz = DATA.GUI.custom_3dminptsz
    local ptsz_max = DATA.GUI.CONF_tr_rect_px
    local scale_cut = {
      x=DATA.GUI.buttons.scale.x + DATA.GUI.CONF_tr_rect_px/2+DATA.GUI.custom_offset*2,
      y=DATA.GUI.buttons.scale.y + DATA.GUI.CONF_tr_rect_px/2+DATA.GUI.custom_offset*2,
      w=DATA.GUI.buttons.scale.w - DATA.GUI.CONF_tr_rect_px-DATA.GUI.custom_offset*4,
      h=DATA.GUI.buttons.scale.h - DATA.GUI.CONF_tr_rect_px-DATA.GUI.custom_offset*4,
      }    
    local scale_room = {
      x=DATA.GUI.buttons.scale_room.x + ptsz/2,
      y=DATA.GUI.buttons.scale_room.y + ptsz/2,
      w=DATA.GUI.buttons.scale_room.w - ptsz,
      h=DATA.GUI.buttons.scale_room.h - ptsz,
      } 
    
    local x = x0 or 0
    local y = y0 or 0
    local z = z0 or 0
    if not (x and y and z) then return end
    local ptsz_cur = ptsz+ptsz_max*z
    local xpos = scale_room.x + scale_room.w * x
    local ypos = scale_room.y + scale_room.h - scale_room.h * y-ptsz/2
    local xpos1 = scale_cut.x + scale_cut.w * x
    local ypos1 = scale_cut.y + scale_cut.h - scale_cut.h * y-ptsz_cur/2
    
    
    if DATA.GUI.buttons['trackrect'..GUID] then
      DATA.GUI.buttons['trackrect'..GUID].x = xpos + (xpos1-xpos)*z-ptsz_cur/2
      DATA.GUI.buttons['trackrect'..GUID].y = ypos + (ypos1-ypos)*z 
      DATA.GUI.buttons['trackrect'..GUID].w = ptsz_cur
      DATA.GUI.buttons['trackrect'..GUID].h = ptsz_cur
      DATA.GUI.buttons['trackrect'..GUID].AXx = x
      DATA.GUI.buttons['trackrect'..GUID].AXy = y
      DATA.GUI.buttons['trackrect'..GUID].AXz = z
    end
    
    if DATA.GUI.buttons['strackrect'..GUID..'shadow'] then
      DATA.GUI.buttons['strackrect'..GUID..'shadow'].x = xpos-ptsz/2
      DATA.GUI.buttons['strackrect'..GUID..'shadow'].y = ypos
      DATA.GUI.buttons['strackrect'..GUID..'shadow'].w = ptsz
      DATA.GUI.buttons['strackrect'..GUID..'shadow'].h = ptsz
    end
    
  end
  ---------------------------------------------------------------------  
  function DATA2:GUI3D_inittracks(DATA) 
    for GUID in pairs(DATA2.tracks) do 
      DATA.GUI.buttons['trackrect'..GUID]={
                              refresh = true,
                              sel_allow = true,
                              val_data = {['gridobject']=true},
                              onmouseclick = function() DATA2:GUI_inittracks_onmouseclick(DATA,GUID) end,
                              onmouserelease =  function()DATA2:GUI_inittracks_onmouserelease(DATA,GUID) end,
                              onmousedrag = function()DATA2:GUI_inittracks_onmousedrag3D(DATA,GUID) end,
                              }  
      DATA.GUI.buttons['strackrect'..GUID..'shadow']={
                              refresh = true,
                              ignoremouse = true,
                              frame_a = 0,
                              backgr_fill = 0.3,
                              frame_asel = 0,
                              --hide=true,
                              val_data = {shadow  = true, GUID=GUID}
                              }                               
      DATA2:GUI3D_SetXYWHbyXYZ(DATA,GUID,x,y,z)
      if DATA.extstate.UI_showicons == 1 then DATA.GUI.buttons['trackrect'..GUID].png = DATA2.tracks[GUID].icon_fp end
      DATA2:GUI_inittracks_initstuff(DATA,GUID) 
    end
  end
  ---------------------------------------------------------------------  
  function DATA2:GUI_inittracks(DATA) 
    for key in pairs(DATA.GUI.buttons) do if key:match('trackrect') then DATA.GUI.buttons[key] = nil end end
    
    
    if DATA.GUI.layers_refresh then DATA.GUI.layers_refresh[2] = true end -- clear buttons buffer
    if not (DATA and DATA.GUI.buttons and DATA2.tracks) then return end  
    
    if DATA.extstate.UI_3dmode == 1 then DATA2:GUI3D_inittracks(DATA)  return end
    
    for GUID in pairs(DATA2.tracks) do
      if GUID:match('{') then
        local frame_col
        if DATA2.tracks[GUID].col and DATA2.tracks[GUID].col ~= 0 then
          local r,g,b = ColorFromNative(DATA2.tracks[GUID].col)
          frame_col = string.format("#%02x%02x%02x",math.floor(r),math.floor(g),math.floor(b))
        end
        local wsz,hsz = DATA.extstate.CONF_tr_rect_px,DATA.GUI.CONF_tr_rect_px
        
        if DATA.extstate.UI_3dmode ==1 then 
          wsz = 100
          hsz = wsz
        end
        local xpos = math.floor(GUI_Scale_GetXPosFromPan (DATA2.tracks[GUID].pan,GUID)-wsz/2)
        local ypos = math.floor(GUI_Scale_GetYPosFromdB  (DATA2.tracks[GUID].vol_dB)-hsz/2)
        
        if not (DATA2.tracks[GUID].I_FOLDERDEPTH == 1 and DATA.extstate.UI_ignoregrouptracks ==1) then
          DATA.GUI.buttons['trackrect'..GUID]={
                              x=xpos,
                              y=ypos,
                              w=wsz,
                              h=hsz,
                              --backgr_fill = 0,
                              frame_a =0.7,
                              frame_col = frame_col,
                              refresh = true,
                              sel_allow = true,
                              val_data = {['gridobject']=true},
                              onmouseclick = function() DATA2:GUI_inittracks_onmouseclick(DATA,GUID) end,
                              onmousedrag = function()DATA2:GUI_inittracks_onmousedrag(DATA,GUID) end,
                              onmouserelease =  function()DATA2:GUI_inittracks_onmouserelease(DATA,GUID) end,
                              onwheeltrig =  function()DATA2:GUI_inittracks_onwheeltrig(DATA,GUID,DATA.GUI.wheel_dir) end,
                              onmousematchcont = function() 
                                  if DATA2.ontrackobj ~= true then
                                    DATA2.info_txt = DATA2.tracks[GUID].name
                                  end
                                end,
                              onmouselost = function() 
                                if DATA2.ontrackobj ~= true then
                                  DATA2.info_txt = nil
                                end
                              end,
                              
                              }
          if DATA.extstate.UI_showicons == 1 then DATA.GUI.buttons['trackrect'..GUID].png = DATA2.tracks[GUID].icon_fp end
          DATA2:GUI_inittracks_initstuff(DATA,GUID)
        end
      end
    end
  end
  --------------------------------------------------- 
  function GUI_Scale_Convertion(db_val, linear_val)
    local log1 = 20
    local log2 = 40
    local scale_cent = DATA.extstate.CONF_scalecent
    local scale_lim_low = -120
    local scale_lim_high = 14
    
    if db_val then 
      local y
      if db_val >= 0 then 
        y = lim(1 - (1-scale_cent) * (scale_lim_high-db_val)/scale_lim_high, 0, 1)
       elseif db_val <= scale_lim_low then 
        y = 0      
       elseif db_val >scale_lim_low and db_val < 0 then 
        y = log1^(db_val/log2) *scale_cent
      end
      if not y then y = 0 end
      return y
    end
    
    if linear_val then 
      local dB
      if not linear_val then return 0 end
      if linear_val >= scale_cent then 
        dB = scale_lim_high*(linear_val - scale_cent) / (1-scale_cent)      
       else     
        dB = log2*math.log(linear_val/scale_cent, log1)
      end
      return dB    
    end
    
  end 
  -----------------------------------------------------------------------------  
  function GUI_format_pan(pan)
    local pan_txt  = math.floor(pan*100)
    if pan_txt < 0 then 
      pan_txt = math.abs(pan_txt)..'%L' 
     elseif pan_txt > 0 then 
      pan_txt = math.abs(pan_txt)..'%R' 
     else 
      pan_txt = 'center' 
    end
    return pan_txt
  end
  -----------------------------------------------------------------------------  
  function GUI_CTRL_header_draw_data_scale(DATA, b)
    local t_val = {12, 
      --6, 
      --4, 
      0, 
      --3, 
      --6, 
      -12, 
      --8, 
      --24, 
      --18, 
      --48 
      -80
      }
    local x_plane2 = 50*DATA.GUI.default_scale
    local texta = 0.5
    
    -- values
    gfx.set(1,1,1)
    for i =1 , #t_val do
      local ypos = GUI_Scale_GetYPosFromdB(t_val[i])*DATA.GUI.default_scale
      local txt = t_val[i]..'dB'
      gfx.y = ypos-gfx.texth/2
      if gfx.y < 0 then gfx.y = 0 end
      if gfx.y + gfx.texth> gfx.h then gfx.y = gfx.h -gfx.texth  end
      gfx.a = texta 
      
      
      --if DATA.extstate.UI_sidegrid == 1 then
        local hrect = 4
        local inita = 0.5
        local dx = inita/(b.w/2)
        gfx.gradrect(b.x,ypos-hrect/2+1,b.w/2,hrect, 1,1,1,0, 0, 0, 0, dx, 0,0, 0, 0 )
        gfx.gradrect(b.x+b.w/2,ypos-hrect/2+1,b.w/2,hrect, 1,1,1,inita, 0, 0, 0, -dx, 0,0, 0, 0 )
        --gfx.line(gfx.w/2-x_plane2/2, ypos,gfx.w/2 +x_plane2/2,ypos)
        gfx.x = (DATA.GUI.buttons.scale.x+DATA.GUI.buttons.scale.w/2)*DATA.GUI.default_scale+ x_plane2/2 + 5--gfx.measurestr(txt)-2
        --gfx.drawstr(txt)
        if DATA.extstate.UI_showscalenumbers == 1 then 
          gfx.x= b.x
          gfx.drawstr(txt)         
          gfx.x= b.x+b.w-gfx.measurestr(txt)
          gfx.drawstr(txt) 
        end
       --[[else
        gfx.line(gfx.w/2-x_plane2/2, ypos,gfx.w/2 +x_plane2/2,ypos)
        gfx.x = (DATA.GUI.buttons.scale.x+DATA.GUI.buttons.scale.w/2)*DATA.GUI.default_scale+ x_plane2/2 + 5--gfx.measurestr(txt)-2
        gfx.drawstr(txt) 
      end]]
      
    end
    
    gfx.y = DATA.GUI.default_scale * (DATA.GUI.buttons.scale.y + DATA.GUI.buttons.scale.h/2)
    gfx.x = DATA.GUI.default_scale * (DATA.GUI.buttons.scale.x)
    gfx.drawstr('L')
    gfx.x = DATA.GUI.default_scale * (DATA.GUI.buttons.scale.x+DATA.GUI.buttons.scale.w-gfx.measurestr('R'))
    gfx.drawstr('R')
    
    
    gfx.a = 0.2
    gfx.line( math.floor(DATA.GUI.buttons.scale.x+DATA.GUI.buttons.scale.w/2)*DATA.GUI.default_scale,  DATA.GUI.buttons.scale.y*DATA.GUI.default_scale,
              math.floor(DATA.GUI.buttons.scale.x+DATA.GUI.buttons.scale.w/2)*DATA.GUI.default_scale,  (DATA.GUI.buttons.scale.y+DATA.GUI.buttons.scale.h)*DATA.GUI.default_scale)
    
  end
  ----------------------------------------------------------------------------- 
  function DATA2:GUI_draw_peaks()
    if not DATA2.tracks then return end
    for GUID in pairs(DATA2.tracks) do
      if DATA.GUI.buttons['trackrect'..GUID] then  
        local o = DATA.GUI.buttons['trackrect'..GUID]
        local frame_col
        if DATA2.tracks[GUID].col and DATA2.tracks[GUID].col ~= 0 then
          local r,g,b = ColorFromNative(DATA2.tracks[GUID].col)
          frame_col = string.format("#%02x%02x%02x",math.floor(r),math.floor(g),math.floor(b))
        end
        
        local x,y,w,h, txt = o.x, o.y, o.w, o.h
        local cnt_lp = math.floor(w*DATA.GUI.default_scale)
        local peakvalL, peakvalR, peakvalmid
        for i = 1, cnt_lp  do
          if DATA2.tracks[GUID].peakL and DATA2.tracks[GUID].peakL[i] then
            
            peakvalL = DATA2.tracks[GUID].peakL[i] 
            peakvalR = DATA2.tracks[GUID].peakR[i]
            
            local x0 = (x+w)*DATA.GUI.default_scale-i
            
            if peakvalL > 1 or peakvalR > 1 then 
              gfx.set(1,0.1,0.1, 0.6)
              gfx.line(x0, y*DATA.GUI.default_scale, x0, (y+h)*DATA.GUI.default_scale-1)
             else
              peakvalL = lim(peakvalL, 0,1)
              peakvalR = lim(peakvalR, 0,1)
              peakvalmid = (peakvalL + peakvalR) /2
              if DATA.extstate.UI_expandpeaks ==1 then
                peakvalmid=peakvalmid^0.4
              end
              --gfx.set(1,1,1)     
              DATA:GUIhex2rgb(frame_col,true)
              gfx.a = 0.5 * (cnt_lp-i)/cnt_lp
              gfx.line( x0,
                        (y +  h/2 -peakvalmid*h/2)*DATA.GUI.default_scale,
                        x0,
                        (y +  h/2 +peakvalmid*h/2-1)*DATA.GUI.default_scale)
             end
            
          end
        end
      end
    end
  end
  -----------------------------------------------------------------------------  
  function GUI_RESERVED_drawDYN(DATA)
    DATA2:GUI_draw_peaks()
    DATA2:GUI_draw_info() 
    -- marquee sel
    if DATA2.marquee and DATA2.marquee.x then 
      gfx.set(1,1,1,0.4)
      gfx.rect(DATA2.marquee.x,DATA2.marquee.y,DATA2.marquee.w,DATA2.marquee.h,0)
      gfx.a = 0.05
      gfx.rect(DATA2.marquee.x,DATA2.marquee.y,DATA2.marquee.w,DATA2.marquee.h,1)
    end
  end
  -----------------------------------------------------------------------------  
  function GUI_RESERVED_draw_data(DATA, b)
    -- scale
    local t = b.val_data
    if t and t.isscale and DATA.extstate.UI_3dmode ==0 then
      if t.tp == 0 then GUI_CTRL_header_draw_data_scale(DATA, b) end
    end
    
    -- grid for vol pan
    if t and t.gridobject==true then
      gfx.set(1,1,1,0.7)
      local h = 3/DATA.GUI.default_scale
      gfx.line(b.x+b.w/2,b.y,b.x+b.w/2,b.y+h)
      gfx.line(b.x+b.w,b.y+b.h/2,b.x+b.w-h,b.y+b.h/2)
    end
    
    if t and t.is_room == true then
      gfx.set(1,1,1,0.1)
      gfx.line(b.x,b.y,DATA.GUI.buttons.scale.x,DATA.GUI.buttons.scale.y)
      gfx.line(b.x+b.w,b.y,DATA.GUI.buttons.scale.x+DATA.GUI.buttons.scale.w,DATA.GUI.buttons.scale.y)
      gfx.line(b.x+b.w,b.y+b.h,DATA.GUI.buttons.scale.x+DATA.GUI.buttons.scale.w,DATA.GUI.buttons.scale.y+DATA.GUI.buttons.scale.h)
      gfx.line(b.x,b.y+b.h,DATA.GUI.buttons.scale.x,DATA.GUI.buttons.scale.y+DATA.GUI.buttons.scale.h)
      gfx.set(1,1,1,0.01)
      gfx.triangle(DATA.GUI.buttons.scale.x,DATA.GUI.buttons.scale.y+DATA.GUI.buttons.scale.h,
                    DATA.GUI.buttons.scale.x+DATA.GUI.buttons.scale.w,DATA.GUI.buttons.scale.y+DATA.GUI.buttons.scale.h,
                    b.x+b.w,b.y+b.h,
                    b.x,b.y+b.h
                    )
    end
    
    if t and t.shadow and t.GUID then
      gfx.set(1,1,1,0.05)
      local GUID = t.GUID
      local t1 = DATA.GUI.buttons['trackrect'..GUID]
      local t2 = DATA.GUI.buttons['strackrect'..GUID..'shadow']
      gfx.triangle(t1.x,t1.y+t1.h,
                  t1.x+t1.w,t1.y+t1.h,
                  t2.x+t2.w,t2.y+t2.h,
                  t2.x,t2.y+t2.h 
                  )
      gfx.triangle(t1.x,t1.y,
                  t1.x+t1.w,t1.y,
                  t2.x+t2.w,t2.y,
                  t2.x,t2.y
                  )                  
      
    end
  end
  -----------------------------------------------------------------------------  
  function GUI_RESERVED_draw_data2(DATA, b)
    -- scale
    local t = b.val_data
    
    
  end
  ----------------------------------------------------------------------
  function DATA_RESERVED_ONPROJCHANGE(DATA)
    if DATA2.preventrefresh then 
      DATA2.preventrefresh = nil return
    end
    if DATA2.ontrackobj ~= true then
      DATA2:tracks_init()
      DATA2:tracks_update_peaks()
      DATA2:GUI_inittracks(DATA)
    end
  end 
  ----------------------------------------------------------------------
  function DATA2:tracks_init(force)
    if not force and (DATA2.tracks and not DATA.UPD.onprojstatechange) then return end
    DATA2.tracks = {}
    
    local fcollect = CountSelectedTracks
    local fcollectsub = GetSelectedTrack
    if DATA.extstate.CONF_handlealltracks == 1 then
      fcollect = CountTracks
      fcollectsub = GetTrack
    end
    
    for i = 1, fcollect(0) do
      local tr = fcollectsub(0,i-1)
      local GUID = GetTrackGUID( tr ) 
      -- pan
      local pan = GetMediaTrackInfo_Value( tr, 'D_PAN' )
      local width = GetMediaTrackInfo_Value( tr, 'D_WIDTH')
      if GetMediaTrackInfo_Value( tr, 'I_PANMODE') == 6 then 
         local L= GetMediaTrackInfo_Value( tr, 'D_DUALPANL')
         local R= GetMediaTrackInfo_Value( tr, 'D_DUALPANR')
         pan = math.max(math.min((R+L)/2, 1), -1)
      end 
      -- vol 
      local vol = GetMediaTrackInfo_Value( tr, 'D_VOL')
      local vol_dB = WDL_VAL2DB(vol) 
      --name
      local retval, trname = GetTrackName( tr, '' ) 
      --if trname:match('(.-)%s+') then trname = trname:match('(.-)%s+') end -- exclude space at the end
      local I_FOLDERDEPTH = GetMediaTrackInfo_Value( tr, 'I_FOLDERDEPTH')
      local retval, icon_fp = reaper.GetSetMediaTrackInfo_String( tr, 'P_ICON', '', false ) if icon_fp =='' then icon_fp = nil end if icon_fp and not file_exists(icon_fp) then icon_fp = nli end
      local solo = GetMediaTrackInfo_Value( tr, 'I_SOLO')
      local mute = GetMediaTrackInfo_Value( tr, 'B_MUTE')
      local ret, center_area = GetSetMediaTrackInfo_String( tr, 'P_EXT:MPL_VISMIX_centerarea', '', false )
      center_area = tonumber(center_area) or 0.5 
      
      local ext1 = 0
      local ret,str = GetSetMediaTrackInfo_String( tr, 'P_EXT:MPL_VISMIX_ext1', 0, false )
      if ret and tonumber(str ) then ext1 = tonumber(str ) end
      
      DATA2.tracks[GUID] = {  ptr = tr,
                              pan = pan,
                              vol = vol,
                              vol_dB = vol_dB,
                              icon_fp=icon_fp,
                              I_FOLDERDEPTH = I_FOLDERDEPTH,
                              name = trname,
                              width = width,
                              col =  GetTrackColor( tr ),
                              solo=solo>0,
                              mute=mute>0,
                              center_area =center_area,
                              ext1 = ext1,
                             }
    end
  end
  ---------------------------------------------------------------------- 
  function DATA2:tracks_update_peaks()
    local max_peak_cnt = math.max(100,DATA.extstate.CONF_tr_rect_px)
    if not DATA2.tracks then return end
    for GUID in pairs(DATA2.tracks) do
      if DATA2.tracks[GUID].ptr and ValidatePtr2(0,DATA2.tracks[GUID].ptr, 'MediaTrack*') then
        if not DATA2.tracks[GUID].peakR then 
          DATA2.tracks[GUID].peakR = {} 
          DATA2.tracks[GUID].peakL = {} 
        end
        local id = #DATA2.tracks[GUID].peakL +1
        table.insert(DATA2.tracks[GUID].peakL, 1 , Track_GetPeakInfo( DATA2.tracks[GUID].ptr,0 ))
        table.insert(DATA2.tracks[GUID].peakR, 1 , Track_GetPeakInfo( DATA2.tracks[GUID].ptr,1 ))
        if #DATA2.tracks[GUID].peakL > max_peak_cnt then 
          table.remove(DATA2.tracks[GUID].peakL, #DATA2.tracks[GUID].peakL)
          table.remove(DATA2.tracks[GUID].peakR, #DATA2.tracks[GUID].peakL)
        end
      end
    end
  end
  ----------------------------------------------------------------------
  function  DATA_RESERVED_DYNUPDATE(DATA, trig)
    local trig_upd_s = 0.05
    
    if DATA2.Recall_timer and DATA2.Recall_timer > 0 then
      DATA2.Recall_timer = math.max(DATA2.Recall_timer - 0.04,0)
      DATA2.Recall_state = 1-(DATA2.Recall_timer / DATA.extstate.CONF_snapshrecalltime)
      if DATA2.Recall_state <1 then DATA2:Snapshot_Recall_persist() else DATA2:Snapshot_Recall(DATA2.Recall_newID) end
    end
    
    DATA2.upd_TS = os.clock()
    if not DATA2.last_upd_TS then DATA2.last_upd_TS = DATA2.upd_TS end
    if DATA2.upd_TS - DATA2.last_upd_TS > trig_upd_s or trig then 
      DATA2.last_upd_TS = DATA2.upd_TS
     else
      return
    end
    
    if DATA2.LUFSnormMeasureRUN == true then
      DATA2:Action_NormalizeLUFS_persist()
    end
    DATA2:tracks_init()
    DATA2:tracks_update_peaks()
    
  end
  ----------------------------------------------------------------------------- 
  function DATA2:GUI_draw_info()  
    if not DATA2.info_txt or DATA.extstate.UI_showinfotooltip == 0  then return end
    local mousex = DATA.GUI.x + 20/DATA.GUI.default_scale
    local mousey = DATA.GUI.y
    local custom_drrack_sideX = 120/DATA.GUI.default_scale
    local custom_drrack_sideY = 120/DATA.GUI.default_scale
    if mousex + custom_drrack_sideX > gfx.w/DATA.GUI.default_scale then mousex =gfx.w/DATA.GUI.default_scale - custom_drrack_sideX end
    if mousex < 0  then mousex = 0 end
    if mousey + custom_drrack_sideY/2 > gfx.h/DATA.GUI.default_scale then mousey =gfx.h/DATA.GUI.default_scale - custom_drrack_sideY/2 end
    if mousey < 0  then mousey = 0 end
    local txt = DATA2.info_txt
    local b =  {            x=mousex,
                            y=mousey,
                            w=custom_drrack_sideX,
                            h=custom_drrack_sideY/2,
                            txt = txt,
                            txt_fontsz = DATA.GUI.custom_drrack_pad_txtsz,
                            frame_arcborder = true,
                            frame_arcborderr = DATA.GUI.custom_drrack_arcr,
                            frame_arcborderflags = 1|2|4|8,
                            ignoreboundarylimit=true,
                            }
    DATA:GUIdraw_Button(b)
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_BuildSettings(DATA)
    local readoutw_extw = 150
        
    local  t = 
    { 
      {str = 'General' ,                            group = 4, itype = 'sep'}, 
        {str = 'Shortcuts info',                    group = 4, itype = 'button', level = 1, func_onrelease = function () DATA2:ShortcutsInfo()  end},
        {str = 'Restore defaults',                  group = 4, itype = 'button', level = 1, func_onrelease = function ()
                    DATA:ExtStateRestoreDefaults(nil,true) 
                    DATA.UPD.onconfchange = true 
                    DATA:GUIBuildSettings()
        end},
        --{str = 'Use SetTrackUI API for objects movings', group = 4, itype = 'check',level = 1,  confkey = 'CONF_csurf'}, 
        --{str = '3D mode',               group = 4, itype = 'check', confkey = 'UI_3dmode', level = 1,func_onrelease = function ()  GUI_RESERVED_init(DATA) end},  
        {str = 'Snapshot smooth transition' ,       group = 4, itype = 'readout', confkey = 'CONF_snapshrecalltime', level = 1, val_min = 0, val_max = 2, val_res = 0.05, val_format = function(x) return VF_math_Qdec(x,3)..'s' end, val_format_rev = function(x) return tonumber(x:match('[%d%.]+')) end},
        {str = 'Collect all tracks instead selected only' ,       group = 4, itype = 'check', confkey = 'CONF_handlealltracks', level = 1,},
        {str = 'Dock / undock',                     group = 4, itype = 'button', confkey = 'dock',  level = 1, func_onrelease = function () GUI_dock(DATA) end},
      {str = 'UI appearance' ,                                 group = 1, itype = 'sep'}, 
        {str = 'Background color (require restart)',group = 1, itype = 'readout', confkey = 'UI_backgrcol', level = 1, menu = {['#333333'] = 'Grey', ['#0A0A0A'] = 'Black'},func_onrelease = function ()  GUI_RESERVED_init(DATA) end},
        --{str = 'Draw side grid line',               group = 1, itype = 'check', confkey = 'UI_sidegrid', level = 1,func_onrelease = function ()  GUI_RESERVED_init(DATA) end},
        {str = 'Show track names',                  group = 1, itype = 'check', confkey = 'UI_showtracknames', level = 1,func_onrelease = function ()  GUI_RESERVED_init(DATA) end},
          {str = 'Only if there is no icons',       group = 1, itype = 'check', confkey = 'UI_showtracknames_flags', level = 2,confkeybyte  =0, func_onrelease = function ()  GUI_RESERVED_init(DATA) end},
        {str = 'Show track icons',                  group = 1, itype = 'check', confkey = 'UI_showicons', level = 1,func_onrelease = function ()  GUI_RESERVED_init(DATA) end},
        {str = 'Top controls: solo',                group = 1, itype = 'check', confkey = 'UI_showtopctrl_flags', confkeybyte  =0, level = 1,func_onrelease = function ()  GUI_RESERVED_init(DATA) end},
        {str = 'Top controls: mute',                group = 1, itype = 'check', confkey = 'UI_showtopctrl_flags', confkeybyte  =1, level = 1,func_onrelease = function ()  GUI_RESERVED_init(DATA) end},
        {str = 'Top controls: FX',                  group = 1, itype = 'check', confkey = 'UI_showtopctrl_flags', confkeybyte  =2, level = 1,func_onrelease = function ()  GUI_RESERVED_init(DATA) end},
        {str = 'Top controls: external_1',          group = 1, itype = 'check', confkey = 'UI_showtopctrl_flags', confkeybyte  =3, level = 1,func_onrelease = function ()  GUI_RESERVED_init(DATA) end},
          {str = 'External_1:first send level',        group = 1, itype = 'check', confkey = 'UI_extcontrol1dest', val_set  =1, level = 2,func_onrelease = function ()  GUI_RESERVED_init(DATA) end},
        {str = 'Show scale numbers',                  group = 1, itype = 'check', confkey = 'UI_showscalenumbers', level = 1,func_onrelease = function ()  GUI_RESERVED_init(DATA) end},
        {str = 'Show info tooltip',                  group = 1, itype = 'check', confkey = 'UI_showinfotooltip', level = 1,func_onrelease = function ()  GUI_RESERVED_init(DATA) end},
        {str = 'Hide group tracks',                  group = 1, itype = 'check', confkey = 'UI_ignoregrouptracks', level = 1,func_onrelease = function ()  GUI_RESERVED_init(DATA) end},
      {str = 'UI behaviour' ,                        group = 5, itype = 'sep'},         
        {str = 'Quantize volume off',               group = 5, itype = 'check', confkey = 'CONF_quantizevolume', isset = 0, level = 1,func_onrelease = function ()  GUI_RESERVED_init(DATA) end},   
        {str = 'Quantize volume to 0.1dB',          group = 5, itype = 'check', confkey = 'CONF_quantizevolume', isset = 1, level = 1,func_onrelease = function ()  GUI_RESERVED_init(DATA) end},
        {str = 'Quantize volume to 0.01dB',         group = 5, itype = 'check', confkey = 'CONF_quantizevolume', isset = 2, level = 1,func_onrelease = function ()  GUI_RESERVED_init(DATA) end},
        {str = 'Quantize pan off',                  group = 5, itype = 'check', confkey = 'CONF_quantizepan', isset = 0, level = 1,func_onrelease = function ()  GUI_RESERVED_init(DATA) end},
        {str = 'Quantize pan to 1%',                group = 5, itype = 'check', confkey = 'CONF_quantizepan', isset = 1, level = 1,func_onrelease = function ()  GUI_RESERVED_init(DATA) end}, 
        {str = 'Quantize pan to 5%',               group = 5, itype = 'check', confkey = 'CONF_quantizepan', isset = 5, level = 1,func_onrelease = function ()  GUI_RESERVED_init(DATA) end},
        {str = 'Quantize pan to 10%',               group = 5, itype = 'check', confkey = 'CONF_quantizepan', isset = 10, level = 1,func_onrelease = function ()  GUI_RESERVED_init(DATA) end},
      {str = 'UI / 2D view' ,                       group = 2, itype = 'sep',hide=DATA.extstate.UI_3dmode==1}, 
        {str = 'Invert Y',                          group = 1, itype = 'check', confkey = 'CONF_invertYscale', level = 1,func_onrelease = function ()  GUI_RESERVED_init(DATA) end, hide=DATA.extstate.UI_3dmode==1},
        {str = 'Extend center',                     group = 1, itype = 'readout', confkey = 'UI_extendcenter', level = 1,menu={[0]='Disabled', [0.3] = '30% area',[0.5] = '50% area'},func_onrelease = function ()  GUI_RESERVED_init(DATA) end, hide=DATA.extstate.UI_3dmode==1},
      {str = 'UI / 3D view' ,                       group = 2, itype = 'sep',hide=DATA.extstate.UI_3dmode==0},  
        

    } 
    return t
    
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.55) if ret then local ret2 = VF_CheckReaperVrs(6.71,true) if ret2 then main() end end