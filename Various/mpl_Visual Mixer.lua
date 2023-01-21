-- @description VisualMixer
-- @version 2.09
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @about Basic Izotope Neutron Visual mixer port to REAPER environment
-- @changelog
--    + GUI: improve drawing pan grid
--    + GUI: allow to show icons (require latest Various Functions)
--    + GUI: allow to hide names
--    + GUI: allow to show names only if there is no icon



  
   DATA2 = {selectedtracks={},marquee={}}
  ---------------------------------------------------------------------  
  function main()
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.version = 2.09
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
                          CONF_snapshrecalltime = 0.5,
                          CONF_invertYscale = 0,
                          CONF_action = 0,
                          CONF_randsymflags = 0,
                          CONF_csurf = 0,
                          
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
    
    DATA2:Snapshot_Read()
    DATA_RESERVED_DYNUPDATE(DATA, true)
    DATA:GUIinit()
    GUI_RESERVED_init(DATA)
    RUN()
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
    DATA.GUI.custom_tr_h =DATA.extstate.CONF_tr_rect_px 
    DATA.GUI.custom_trwidthhandleh = 5 
    DATA.GUI.custom_ctrls_w = gfx.w/DATA.GUI.default_scale-DATA.GUI.custom_offset*2
    DATA.GUI.custom_ctrl_singlew = math.floor(DATA.GUI.custom_ctrls_w/7)
    if DATA.GUI.custom_compactmode ==true then DATA.GUI.custom_ctrl_singlew = math.floor(DATA.GUI.custom_ctrls_w/4) end
    DATA.GUI.default_data_a = 0.7-- normal
    DATA.GUI.default_data_a2 = 0.2 -- ignore serach 
    DATA.GUI.custom_currentsnapshotID = 1
    
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
                            y=DATA.GUI.custom_offset,--+DATA.GUI.custom_tr_h/2
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
                                                              { str = '|Smooth recall: off',
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
      local frame_a
      if ex then frame_a = 0.7 end
      DATA.GUI.buttons['snapshots'..i] = { x=xoffs + snapshw*(i-1), 
                              y=DATA.GUI.custom_offset,--+DATA.GUI.custom_tr_h/2
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
  function DATA2:marque_selection(DATA) 
    L1x,L1y,R1x,R1y = DATA2.marquee.x,DATA2.marquee.y,DATA2.marquee.x+DATA2.marquee.w,DATA2.marquee.y+DATA2.marquee.h
    for GUID in pairs(DATA2.tracks) do
      DATA.GUI.buttons['trackrect'..GUID].sel_isselected = false
      L2x,L2y,R2x,R2y = DATA.GUI.buttons['trackrect'..GUID].x,DATA.GUI.buttons['trackrect'..GUID].y,DATA.GUI.buttons['trackrect'..GUID].x+DATA.GUI.buttons['trackrect'..GUID].w,DATA.GUI.buttons['trackrect'..GUID].y+DATA.GUI.buttons['trackrect'..GUID].h
      DATA.GUI.buttons['trackrect'..GUID].sel_isselected = iscross(L1x,L1y,R1x,R1y,L2x,L2y,R2x,R2y)
    end
  end
  --------------------------------------------------------------------- 
  function GUI_Areas(DATA)   
    local yoffs = DATA.GUI.custom_mainbuth+DATA.GUI.custom_offset*2
    if DATA.GUI.custom_compactmode == true then
      yoffs = yoffs+DATA.GUI.custom_mainbuth+DATA.GUI.custom_offset
    end
    DATA.GUI.buttons.scale = { x=DATA.GUI.custom_offset, -- link to GUI.buttons.getreference--+DATA.extstate.CONF_tr_rect_px/2
                            y=yoffs,--+DATA.GUI.custom_tr_h/2
                            w=gfx.w/DATA.GUI.default_scale-DATA.GUI.custom_offset*2,--DATA.extstate.CONF_tr_rect_px,
                            h=gfx.h/DATA.GUI.default_scale-yoffs-DATA.GUI.custom_offset,--DATA.GUI.custom_tr_h,
                            ignoremouse = true,
                            --refresh = true,
                            val_data = {tp = 0,isscale=true},
                            frame_a =0,
                            frame_asel =0,
                            }
    DATA.GUI.buttons.marquee = { x=DATA.GUI.custom_offset, -- link to GUI.buttons.getreference--+DATA.extstate.CONF_tr_rect_px/2
                            y=yoffs,--+DATA.GUI.custom_tr_h/2
                            w=gfx.w/DATA.GUI.default_scale-DATA.GUI.custom_offset*2,--DATA.extstate.CONF_tr_rect_px,
                            h=gfx.h/DATA.GUI.default_scale-yoffs-DATA.GUI.custom_offset,--DATA.GUI.custom_tr_h,
                            --refresh = true,
                            frame_a =0,
                            frame_asel =0,
                            val_data = {ismarque=true},
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
    DATA.GUI.buttons.knob = { x=xoffs,
                            y=yoffs,
                            w=ctrlw-DATA.GUI.custom_offset ,
                            h=DATA.GUI.custom_mainbuth,
                            txt = 'Size',--..math.floor(DATA.extstate.CONF_tr_rect_px)..'px',
                            txt_fontsz = DATA.GUI.custom_knobfontsz,
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
                                DATA.GUI.custom_tr_h =DATA.extstate.CONF_tr_rect_px
                                DATA2:GUI_inittracks(DATA)
                              end,
                            onmouserelease  = function()     
                              DATA.extstate.CONF_tr_rect_px = math.floor(DATA.GUI.buttons.knob.val )
                              DATA.GUI.custom_tr_h =DATA.extstate.CONF_tr_rect_px
                              DATA.UPD.onconfchange = true
                              --DATA2:tracks_init()
                            end,
                            onmousereleaseR  = function()     
                              local val_def = 50
                              DATA.extstate.CONF_tr_rect_px = val_def
                              DATA.GUI.custom_tr_h =DATA.extstate.CONF_tr_rect_px
                              DATA.GUI.buttons.knob.val=val_def
                              DATA.UPD.onconfchange = true
                              DATA2:tracks_init(true)
                              DATA2:GUI_inittracks(DATA)
                            end,
                          }
    xoffs = xoffs+ctrlw
    DATA.GUI.buttons.knob2 = { x=xoffs,
                            y=yoffs,
                            w=ctrlw-DATA.GUI.custom_offset ,
                            h=DATA.GUI.custom_mainbuth,
                            txt = 'Scale',-- Y
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
                            onmousereleaseR  = function() 
                              DATA:GUImenu({
                                { str = 'Invert Y',
                                state =  DATA.extstate.CONF_invertYscale==1,
                                func = function() DATA.extstate.CONF_invertYscale = DATA.extstate.CONF_invertYscale~1 DATA.UPD.onconfchange=true DATA2:GUI_inittracks(DATA) end},  
                              })
                            end,                           
 
                          }                          
                          
                          
    xoffs = xoffs+ctrlw
    local rclickw = math.floor(ctrlw*0.2)
    DATA.GUI.buttons.act = { x=xoffs, 
                            y=yoffs,
                            w=ctrlw-rclickw-DATA.GUI.custom_offset-1,
                            h=DATA.GUI.custom_mainbuth,
                            txt = 'Action',
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
      { str = 'Random chaotically', state =  DATA.extstate.CONF_action==0, func = function() DATA.extstate.CONF_action = 0 DATA.UPD.onconfchange=true end }, 
      { str = 'Random symmetrically', state =  DATA.extstate.CONF_action==1, func = function() DATA.extstate.CONF_action = 1 DATA.UPD.onconfchange=true end }, 
    }
    if DATA.extstate.CONF_action == 1 then  -- symmetric params
      t[#t+1] = { str = 'Reset all flags', func = function() DATA.extstate.CONF_randsymflags = 0 DATA.UPD.onconfchange=true end }
      t[#t+1] = { str = '|Pan - exclude center area', state =  DATA.extstate.CONF_randsymflags&1==1, func = function() DATA.extstate.CONF_randsymflags = DATA.extstate.CONF_randsymflags~1 DATA.UPD.onconfchange=true end }
      t[#t+1] = { str = 'Par - make more narrow|', state =  DATA.extstate.CONF_randsymflags&2==2, func = function() DATA.extstate.CONF_randsymflags = DATA.extstate.CONF_randsymflags~2 DATA.UPD.onconfchange=true end }
      t[#t+1] = { str = 'Slight pan deviations', state =  DATA.extstate.CONF_randsymflags&8==8, func = function() DATA.extstate.CONF_randsymflags = DATA.extstate.CONF_randsymflags~8 DATA.UPD.onconfchange=true end }
      t[#t+1] = { str = 'Slight volume deviations|', state =  DATA.extstate.CONF_randsymflags&16==16, func = function() DATA.extstate.CONF_randsymflags = DATA.extstate.CONF_randsymflags~16 DATA.UPD.onconfchange=true end }
      
      t[#t+1] = { str = 'Volume follow pan', state =  DATA.extstate.CONF_randsymflags&4==4, func = function() DATA.extstate.CONF_randsymflags = DATA.extstate.CONF_randsymflags~4 DATA.UPD.onconfchange=true end }
      t[#t+1] = { str = 'Inverted following', state =  DATA.extstate.CONF_randsymflags&32==32, hidden = DATA.extstate.CONF_randsymflags&4~=4, func = function() DATA.extstate.CONF_randsymflags = DATA.extstate.CONF_randsymflags~32  DATA.UPD.onconfchange=true end }
      
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
    end
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
  ------------------------------------------------------------------------------------------------------
  function DATA2:Snapshot_Recall(ID,oldID)
    if not (ID and DATA2.Snapshots and DATA2.Snapshots[ID]) then return end 
    Action(40297) -- unselect all tracks
    
    if oldID and DATA.extstate.CONF_snapshrecalltime > 0 then 
      DATA2.Recall_timer = DATA.extstate.CONF_snapshrecalltime
      DATA2.Recall_newID = ID
      DATA2.Recall_oldID = oldID
      for GUID in pairs(DATA2.Snapshots[ID]) do DATA2.Snapshots[ID][GUID].tr_ptr = nil end
      for GUID in pairs(DATA2.Snapshots[oldID]) do DATA2.Snapshots[oldID][GUID].tr_ptr = nil end
      return 
    end
    
    reaper.Undo_BeginBlock2( 0 )
    for GUID in pairs(DATA2.Snapshots[ID]) do
      local tr = VF_GetTrackByGUID(GUID)
      if tr then
        SetTrackSelected( tr, true )
        SetMediaTrackInfo_Value( tr, 'D_PAN', DATA2.Snapshots[ID][GUID].pan)
        SetMediaTrackInfo_Value( tr, 'D_VOL', DATA2.Snapshots[ID][GUID].vol)
        SetMediaTrackInfo_Value( tr, 'D_WIDTH', DATA2.Snapshots[ID][GUID].width)
        SetMediaTrackInfo_Value( tr, 'I_PANMODE', 5)
      end
    end
    reaper.Undo_EndBlock2( 0, 'Visual mixer shapshot recall', 0xFFFFFFFF )
  end
  ---------------------------------------------------
  function DATA2:Snapshot_Write()  
    for ID = 1, DATA.extstate.CONF_snapshcnt do
      if DATA2.Snapshots[ID] then 
        local str = ''
        for GUID in pairs(DATA2.Snapshots[ID]) do
          str = str..
                 GUID..' '..
                 DATA2.Snapshots[ID][GUID].vol..' '..
                 DATA2.Snapshots[ID][GUID].pan..' '..
                 DATA2.Snapshots[ID][GUID].width..'\n'
        end
        if str then SetProjExtState(0, 'MPL_VisMix', 'SNAPSHOT'..ID, str  )  end
       else
        SetProjExtState(0, 'MPL_VisMix', 'SNAPSHOT'..ID, ''  )
      end
    end
  end
  ---------------------------------------------------
  function DATA2:Snapshot_WriteCurrent(ID)
    DATA2.Snapshots[ID] = {}
    for GUID in pairs(DATA2.tracks) do
      if not DATA2.Snapshots[ID][GUID] then DATA2.Snapshots[ID][GUID] = {} end 
      DATA2.Snapshots[ID][GUID].vol = DATA2.tracks[GUID].vol
      DATA2.Snapshots[ID][GUID].pan = DATA2.tracks[GUID].pan
      DATA2.Snapshots[ID][GUID].width = DATA2.tracks[GUID].width
    end
  end
  
  
  
  -----------------------------------------------
  function GUI_Scale_GetXPosFromPan(pan)
    if not DATA.GUI.buttons.scale then return end
    local area = DATA.GUI.buttons.scale.w - DATA.extstate.CONF_tr_rect_px
    if pan then return DATA.GUI.buttons.scale.x +DATA.extstate.CONF_tr_rect_px/2+ area*0.5* (1+pan) end
  end 
  ---------------------------------------------------------------------  
  function DATA2:TrackMap_ApplyTrPan(GUID, Xval) 
    local tr = VF_GetTrackByGUID(GUID)
    if not tr then return end
    local area = DATA.GUI.buttons.scale.w - DATA.extstate.CONF_tr_rect_px
    local pan = -0.5+(Xval - DATA.GUI.buttons.scale.x) / area 
    if DATA.extstate.CONF_csurf ==1 then 
      if DATA.extstate.CONF_csurf ==1 then 
        local t = {}
        for i=1, CountSelectedTracks(0) do t[#t+1]=GetSelectedTrack(0,i-1) end
        SetOnlyTrackSelected(tr)
        CSurf_OnPanChangeEx(tr, pan*2, false, false) 
        for i= 1,#t do SetTrackSelected(t[i],true) end
      end
     else 
      SetMediaTrackInfo_Value( tr, 'D_PAN', pan*2) 
    end
  end
  
  
  
  
  -----------------------------------------------
  function GUI_Scale_GetWPosFromW(width)
    if not width then return 1 end 
    local width = math.abs(width)*(1-DATA.GUI.custom_minw_ratio) + DATA.GUI.custom_minw_ratio
    return DATA.extstate.CONF_tr_rect_px * width
  end
  ----------------------------------------------------------------------  
  function DATA2:TrackMap_ApplyTrWidth(GUID,Wval) 
    local tr = VF_GetTrackByGUID(GUID)
    if not tr then return end 
    local width = ((Wval / DATA.extstate.CONF_tr_rect_px)-DATA.GUI.custom_minw_ratio)/(1-DATA.GUI.custom_minw_ratio) 
    
    SetMediaTrackInfo_Value( tr, 'I_PANMODE', 5)
    if DATA.extstate.CONF_csurf ==1 then 
      if DATA.extstate.CONF_csurf ==1 then 
        local t = {}
        for i=1, CountSelectedTracks(0) do t[#t+1]=GetSelectedTrack(0,i-1) end
        SetOnlyTrackSelected(tr)
        CSurf_OnWidthChange( tr, width, false ) 
        for i= 1,#t do SetTrackSelected(t[i],true) end
      end
     else 
      SetMediaTrackInfo_Value( tr, 'D_WIDTH', width) 
    end
  end
  
  
  
  
  
  -----------------------------------------------
  function GUI_Scale_GetYPosFromdB(db_val)
    if not db_val then return 0 end 
    local linearval = 1-GUI_Scale_Convertion(db_val)
    if DATA.extstate.CONF_invertYscale == 1 then linearval = GUI_Scale_Convertion(db_val) end 
    local area = DATA.GUI.buttons.scale.h - DATA.GUI.custom_tr_h
    return linearval *  area + DATA.GUI.buttons.scale.y
  end
  ----------------------------------------------------------------------  
  function DATA2:TrackMap_ApplyTrVol(GUID, Yval, val0) 
    local tr = VF_GetTrackByGUID(GUID)
    if not tr then return end
    
    local val
    if not val0 then
      local area = DATA.GUI.buttons.scale.h - DATA.GUI.custom_tr_h
      val =  1-  ( Yval -  DATA.GUI.buttons.scale.y+DATA.GUI.custom_tr_h/2)/ area
      if DATA.extstate.CONF_invertYscale == 1 then val =  ( Yval -  DATA.GUI.buttons.scale.y+DATA.GUI.custom_tr_h/2)/ area end
     else
      val = val0
    end 
    
    local db_val = GUI_Scale_Convertion(nil,val  )
    local volout = VF_lim(WDL_DB2VAL(db_val),0,6)
    if DATA.extstate.CONF_csurf ==1 then 
      
      if DATA.extstate.CONF_csurf ==1 then 
        local t = {}
        for i=1, CountSelectedTracks(0) do t[#t+1]=GetSelectedTrack(0,i-1) end
        SetOnlyTrackSelected(tr)
        CSurf_OnVolumeChange( tr, volout, false, false ) 
        for i= 1,#t do SetTrackSelected(t[i],true) end
      end
     else 
      SetMediaTrackInfo_Value(tr, 'D_VOL',volout)
    end
  end
  

  
  
  ---------------------------- 
  function DATA2:GUI_inittracks_refreshXY(DATA, GUID) 
    local xpos = GUI_Scale_GetXPosFromPan (DATA2.tracks[GUID].pan)-DATA.extstate.CONF_tr_rect_px/2
    local ypos = GUI_Scale_GetYPosFromdB  (DATA2.tracks[GUID].vol_dB)   -DATA.GUI.custom_tr_h/2
    DATA.GUI.buttons['trackrect'..GUID].x=xpos
    DATA.GUI.buttons['trackrect'..GUID].y=ypos
    DATA.GUI.buttons['trackrect'..GUID].refresh = true
  end
  ---------------------------------------------------------------------  
  function DATA2:GUI_inittracks_initstuff(DATA,GUID,xpos,ypos, frame_col)  
    -- width
    if not DATA.GUI.buttons['trackrect'..GUID..'widthhandle'] then
      local wtr = GUI_Scale_GetWPosFromW   (DATA2.tracks[GUID].width)
      DATA.GUI.buttons['trackrect'..GUID..'widthhandle']={x=xpos+DATA.GUI.custom_tr_h/2-wtr/2,
                          y=ypos+DATA.GUI.custom_tr_h,
                          w=wtr,
                          h=DATA.GUI.custom_trwidthhandleh,
                          backgr_fill = 0.2,
                          backgr_col = frame_col,
                          frame_a =0.2,
                          frame_col =frame_col,
                          val=0,
                          val_xaxis = true,
                          val_res=0.05,
                          refresh = true,
                          onmouseclick = function() 
                                            DATA.GUI.buttons['trackrect'..GUID..'widthhandle'].latch_w = DATA.GUI.buttons['trackrect'..GUID..'widthhandle'].w
                                          end,
                          onmousedrag = function()
                                          DATA2.ontrackobj = true
                                          if DATA.GUI.mouse_ismoving then 
                                            local wout = VF_lim(DATA.GUI.buttons['trackrect'..GUID..'widthhandle'].latch_w + DATA.GUI.dx/DATA.GUI.default_scale, DATA.extstate.CONF_tr_rect_px*DATA.GUI.custom_minw_ratio, DATA.extstate.CONF_tr_rect_px)
                                            DATA.GUI.buttons['trackrect'..GUID..'widthhandle'].w = wout
                                            local xpos = math.floor(GUI_Scale_GetXPosFromPan (DATA2.tracks[GUID].pan)-DATA.extstate.CONF_tr_rect_px/2)
                                            DATA.GUI.buttons['trackrect'..GUID..'widthhandle'].x= xpos+DATA.extstate.CONF_tr_rect_px/2-wout/2
                                            DATA2:TrackMap_ApplyTrWidth(GUID,wout) 
                                          end
                                        end,
                          onmouserelease =  function()
                                              DATA2.ontrackobj = false
                                              DATA2:tracks_init(true)
                                              local ID = DATA.GUI.custom_currentsnapshotID or 1
                                              DATA2:Snapshot_WriteCurrent(ID)
                                              DATA2:Snapshot_Write()
                                            end
                          } 
     else 
      local wtr = GUI_Scale_GetWPosFromW   (DATA2.tracks[GUID].width)
      DATA.GUI.buttons['trackrect'..GUID..'widthhandle'].x=xpos+DATA.extstate.CONF_tr_rect_px/2-wtr/2
      DATA.GUI.buttons['trackrect'..GUID..'widthhandle'].y=ypos+DATA.GUI.custom_tr_h
      DATA.GUI.buttons['trackrect'..GUID..'widthhandle'].w=wtr
    end
    -- folder 
    if DATA2.tracks[GUID].I_FOLDERDEPTH == 1 then 
      DATA.GUI.buttons['trackrect'..GUID..'isfolder']={x=xpos+DATA.extstate.CONF_tr_rect_px-DATA.GUI.custom_foldrect,
                            y=ypos+DATA.GUI.custom_tr_h-DATA.GUI.custom_foldrect,
                            w=DATA.GUI.custom_foldrect,
                            h=DATA.GUI.custom_foldrect,
                            backgr_fill = 0.9,
                            backgr_col = '#FFFFFF',
                            frame_a =0,
                            refresh = true,
                            ignoremouse = true}
    end
    --info
    local infotxt = DATA2.tracks[GUID].name
    local w_txt = gfx.measurestr(infotxt)
    
    local txtout = ''
    if DATA.extstate.UI_showtracknames ==1 and 
      ( 
         DATA.extstate.UI_showtracknames_flags&1==0 or 
        (DATA.extstate.UI_showtracknames_flags&1==1 and not DATA2.tracks[GUID].icon_fp)) then 
          txtout = infotxt 
    end
    DATA.GUI.buttons['trackrect'..GUID..'info']={x=xpos+DATA.extstate.CONF_tr_rect_px/2-w_txt/2,
                            y=ypos+DATA.GUI.custom_tr_h+DATA.GUI.custom_trwidthhandleh,
                            w=w_txt,
                            h=DATA.GUI.custom_txtfontszinfo*DATA.GUI.default_scale,
                            frame_a =0,
                            refresh = true,
                            txt_fontsz = DATA.GUI.custom_txtfontszinfo,
                            txt_flags = 1,
                            txt = txtout,
                            ignoremouse = true}
    
    
  end
  ---------------------------------------------------------------------  
  function DATA2:GUI_inittracks(DATA) 
    for key in pairs(DATA.GUI.buttons) do if key:match('trackrect') then DATA.GUI.buttons[key] = nil end end
    if DATA.GUI.layers_refresh then DATA.GUI.layers_refresh[2] = true end -- clear buttons buffer
    
    if not (DATA and DATA.GUI.buttons and DATA2.tracks) then return end  
    for GUID in pairs(DATA2.tracks) do
      local frame_col
      if DATA2.tracks[GUID].col and DATA2.tracks[GUID].col ~= 0 then
        local r,g,b = ColorFromNative(DATA2.tracks[GUID].col)
        frame_col = string.format("#%02x%02x%02x",math.floor(r),math.floor(g),math.floor(b))
      end
      local xpos = math.floor(GUI_Scale_GetXPosFromPan (DATA2.tracks[GUID].pan)-DATA.extstate.CONF_tr_rect_px/2)
      local ypos = math.floor(GUI_Scale_GetYPosFromdB  (DATA2.tracks[GUID].vol_dB)   -DATA.GUI.custom_tr_h/2)
      DATA.GUI.buttons['trackrect'..GUID]={
                            x=xpos,
                            y=ypos,
                            w=DATA.extstate.CONF_tr_rect_px,
                            h=DATA.GUI.custom_tr_h,
                            --backgr_fill = 0,
                            frame_a =0.7,
                            frame_col = frame_col,
                            refresh = true,
                            sel_allow = true,
                            
                            --sel_isselected=true,
                            onmousematchcont = function () end,
                            onmouseclick = function() 
                                              DATA2.ontrackobj = true
                                              if DATA.GUI.Alt == true or DATA.GUI.Shift == true then 
                                                for GUID in pairs(DATA2.tracks) do 
                                                  if DATA.GUI.buttons['trackrect'..GUID].sel_isselected == true then
                                                    if DATA.GUI.Alt == true then SetMediaTrackInfo_Value(DATA2.tracks[GUID].ptr, 'D_VOL',1) end
                                                    if DATA.GUI.Shift == true then SetMediaTrackInfo_Value(DATA2.tracks[GUID].ptr, 'D_PAN',0) end
                                                  end
                                                end 
                                                
                                                local cnt = 0 for GUID in pairs(DATA2.tracks) do if DATA.GUI.buttons['trackrect'..GUID].sel_isselected == true then cnt = cnt + 1 end end
                                                if cnt  == 0 then
                                                   if DATA.GUI.Alt == true then SetMediaTrackInfo_Value(DATA2.tracks[GUID].ptr, 'D_VOL',1) end
                                                   if DATA.GUI.Shift == true then SetMediaTrackInfo_Value(DATA2.tracks[GUID].ptr, 'D_PAN',0) end
                                                end
                                                
                                                  
                                                DATA2:tracks_init(true)
                                                DATA2:GUI_inittracks(DATA) 
                                                return 
                                              end
                                              
                                              if DATA.GUI.Ctrl == false then 
                                                for GUID in pairs(DATA2.tracks) do 
                                                  DATA.GUI.buttons['trackrect'..GUID].sel_isselected = false   -- reset selection 
                                                end
                                                -- set selection to current track
                                                  DATA.GUI.buttons['trackrect'..GUID].sel_isselected = true
                                                  DATA.GUI.buttons['trackrect'..GUID].latch_x = DATA.GUI.buttons['trackrect'..GUID].x
                                                  DATA.GUI.buttons['trackrect'..GUID].latch_y = DATA.GUI.buttons['trackrect'..GUID].y
                                              end
                                              
                                              --if DATA.GUI.Ctrl == true then 
                                                for GUID in pairs(DATA2.tracks) do  
                                                  DATA.GUI.buttons['trackrect'..GUID].latch_x = DATA.GUI.buttons['trackrect'..GUID].x
                                                  DATA.GUI.buttons['trackrect'..GUID].latch_y = DATA.GUI.buttons['trackrect'..GUID].y
                                                end
                                                -- set selection to current track
                                                DATA.GUI.buttons['trackrect'..GUID].sel_isselected = true
                                                
                                            end,
                            --onmousedrag_skipotherobjects = true,
                            onmousedrag = function()
                                          
                                            if DATA.GUI.Alt == true or DATA.GUI.Shift == true then return end
                                            DATA2.ontrackobj = true
                                            if DATA.GUI.mouse_ismoving then 
                                              for GUID in pairs(DATA2.tracks) do
                                                if DATA.GUI.buttons['trackrect'..GUID].sel_isselected == true then
                                                  if DATA.GUI.buttons['trackrect'..GUID].latch_x then
                                                    DATA.GUI.buttons['trackrect'..GUID].x = VF_lim(DATA.GUI.buttons['trackrect'..GUID].latch_x + DATA.GUI.dx/DATA.GUI.default_scale, DATA.GUI.buttons.scale.x , DATA.GUI.buttons.scale.x+DATA.GUI.buttons.scale.w-DATA.extstate.CONF_tr_rect_px)
                                                    DATA.GUI.buttons['trackrect'..GUID].y = VF_lim(DATA.GUI.buttons['trackrect'..GUID].latch_y + DATA.GUI.dy/DATA.GUI.default_scale, DATA.GUI.buttons.scale.y, DATA.GUI.buttons.scale.y+DATA.GUI.buttons.scale.h-DATA.GUI.custom_tr_h)
                                                    DATA.GUI.buttons['trackrect'..GUID].refresh = true
                                                    DATA2:TrackMap_ApplyTrPan(GUID,DATA.GUI.buttons['trackrect'..GUID].x)
                                                    DATA2:TrackMap_ApplyTrVol(GUID,DATA.GUI.buttons['trackrect'..GUID].y) 
                                                    DATA2:GUI_inittracks_initstuff(DATA,GUID,DATA.GUI.buttons['trackrect'..GUID].x,DATA.GUI.buttons['trackrect'..GUID].y )
                                                  end
                                                end
                                              end
                                            end
                                          end,
                            onmouserelease =  function()
                                                if DATA.GUI.Alt == true or DATA.GUI.Shift == true then return end
                                                --[[for GUID in pairs(DATA2.tracks) do 
                                                  DATA.GUI.buttons['trackrect'..GUID].sel_isselected = false   -- reset selection 
                                                end]]
                                                --[[if DATA.GUI.Ctrl ==true then 
                                                  DATA.GUI.buttons['trackrect'..GUID].sel_isselected = true
                                                  DATA2.selectedtracks[GUID] = true
                                                  return 
                                                end]]
                                                
                                                local ID = DATA.GUI.custom_currentsnapshotID or 1 
                                                DATA2:tracks_init(true)
                                                DATA2:Snapshot_WriteCurrent(ID)
                                                DATA2:Snapshot_Write()
                                                DATA2.ontrackobj = false
                                                Undo_OnStateChangeEx2( 0, 'MPL Visual mixer change', 1, -1 )
                                              end,
                            
                            }
      if DATA.extstate.UI_showicons == 1 then DATA.GUI.buttons['trackrect'..GUID].png = DATA2.tracks[GUID].icon_fp end
      DATA2:GUI_inittracks_initstuff(DATA,GUID,xpos,ypos, frame_col)
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
        gfx.x= b.x
        gfx.drawstr(txt)         
        gfx.x= b.x+b.w-gfx.measurestr(txt)
        gfx.drawstr(txt) 
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
    
    -- marquee sel
    if DATA2.marquee and DATA2.marquee.x then
      gfx.set(1,1,1,0.4)
      gfx.rect(DATA2.marquee.x,DATA2.marquee.y,DATA2.marquee.w,DATA2.marquee.h,0)
    end
  end
  -----------------------------------------------------------------------------  
  function GUI_RESERVED_draw_data(DATA, b)
    -- scale
    local t = b.val_data
    if t and t.isscale then
      if t.tp == 0 then GUI_CTRL_header_draw_data_scale(DATA, b) end
    end
    
    
  end
  -----------------------------------------------------------------------------  
  function GUI_RESERVED_draw_data2(DATA, b)
    -- scale
    local t = b.val_data
    
    
  end
  ----------------------------------------------------------------------
  function DATA_RESERVED_ONPROJCHANGE(DATA)
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
    for i = 1, CountSelectedTracks(0) do
      local tr = GetSelectedTrack(0,i-1)
      local GUID = GetTrackGUID( tr ) 
      -- pan
      local pan = GetMediaTrackInfo_Value( tr, 'D_PAN' )
      if GetMediaTrackInfo_Value( tr, 'I_PANMODE') == 6 then 
         local L= GetMediaTrackInfo_Value( tr, 'D_DUALPANL')
         local R= GetMediaTrackInfo_Value( tr, 'D_DUALPANR')
         pan = math.max(math.min(L+R, 1), -1)
      end 
      -- vol 
      local vol = GetMediaTrackInfo_Value( tr, 'D_VOL')
      local vol_dB = WDL_VAL2DB(vol) 
      --name
      local retval, trname = GetTrackName( tr, '' ) 
      local I_FOLDERDEPTH = GetMediaTrackInfo_Value( tr, 'I_FOLDERDEPTH')
      local retval, icon_fp = reaper.GetSetMediaTrackInfo_String( tr, 'P_ICON', '', false ) if icon_fp =='' then icon_fp = nil end
      DATA2.tracks[GUID] = {  ptr = tr,
                              pan = pan,
                              vol = vol,
                              vol_dB = vol_dB,
                              icon_fp=icon_fp,
                              I_FOLDERDEPTH = I_FOLDERDEPTH,
                              name = trname,
                              width = GetMediaTrackInfo_Value( tr, 'D_WIDTH'),
                              col =  GetTrackColor( tr ),
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
    DATA2:tracks_init()
    DATA2:tracks_update_peaks()
    
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_BuildSettings(DATA)
    local readoutw_extw = 150
        
    local  t = 
    { 
      {str = 'Objects global' ,                     group = 3, itype = 'sep'}, 
        {str = 'Use Csurf API for objects movings', group = 3, itype = 'check',level = 1,  confkey = 'CONF_csurf'}, 
      {str = 'Snapshot' ,                           group = 1, itype = 'sep'}, 
        {str = 'Smooth transition' ,                group = 1, itype = 'readout', confkey = 'CONF_snapshrecalltime', level = 1, val_min = 0, val_max = 2, val_res = 0.05, val_format = function(x) return VF_math_Qdec(x,3)..'s' end, val_format_rev = function(x) return tonumber(x:match('[%d%.]+')) end},
      {str = 'UI' ,                                 group = 1, itype = 'sep'}, 
        {str = 'Background color (require restart)',group = 1, itype = 'readout', confkey = 'UI_backgrcol', level = 1, menu = {['#333333'] = 'Grey', ['#0A0A0A'] = 'Black'},func_onrelease = function ()  GUI_RESERVED_init(DATA) end},
        --{str = 'Draw side grid line',               group = 1, itype = 'check', confkey = 'UI_sidegrid', level = 1,func_onrelease = function ()  GUI_RESERVED_init(DATA) end},
        {str = 'Show track names',                  group = 1, itype = 'check', confkey = 'UI_showtracknames', level = 1,func_onrelease = function ()  GUI_RESERVED_init(DATA) end},
          {str = 'Only if there is no icons',       group = 1, itype = 'check', confkey = 'UI_showtracknames_flags', level = 2,confkeybyte  =0, func_onrelease = function ()  GUI_RESERVED_init(DATA) end},
        {str = 'Show track icons',                  group = 1, itype = 'check', confkey = 'UI_showicons', level = 1,func_onrelease = function ()  GUI_RESERVED_init(DATA) end},
        {str = 'Dock / undock',                     group = 1, itype = 'button', confkey = 'dock',  level = 1, func_onrelease = function () GUI_dock(DATA) end},
      {str = 'General' ,                            group = 4, itype = 'sep'}, 
        {str = 'Restore defaults',                  group = 4, itype = 'button', level = 1, func_onrelease = function () DATA:ExtStateRestoreDefaults()  end}
        

    } 
    return t
    
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.54) if ret then local ret2 = VF_CheckReaperVrs(6,true) if ret2 then main() end end