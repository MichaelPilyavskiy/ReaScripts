-- @description Randomize Track FX parameters
-- @version 2.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=233358
-- @changelog
--    # fix error is no FX is presented




  -- NOT gfx NOT reaper NOT VF NOT GUI NOT DATA NOT MAIN 
  
  DATA2 = {}
  ---------------------------------------------------------------------  
  function main()
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.version = 2.01
    DATA.extstate.extstatesection = 'mpl_randomizefxparams'
    DATA.extstate.mb_title = 'MPL Randomize FX parameters'
    DATA.extstate.default = 
                          {  
                          wind_x =  100,
                          wind_y =  100,
                          wind_w =  800,
                          wind_h =  600,
                          dock =    0,
                          
                          CONF_NAME = 'default',
                          
                          UI_enableshortcuts = 0,
                          UI_initatmouse = 0,
                          UI_showtooltips = 1,
                          UI_groupflags = 0, -- show/hide setting flags
                          UI_appatchange = 1, 
                          UI_appatinit = 1, 
                          UI_mergegenmorph = 1, 
                          
                          CONF_filter_untitledparams = 1,
                          CONF_filter_system = 1,
                          CONF_filter_Keywords1str = 'dry wet bypass preview gain vol ctrl control midi upsmpl upsampl render oversamp alias input power solo mute feed auto resvd meter depr sign aud dest mix out make level peak limit velocity active master',
                          CONF_filter_Keywords1 = 1,                          
                          CONF_filter_Keywords2str = 'att dec sust rel',
                          CONF_filter_Keywords2 = 0,
                          CONF_filter_Keywords3str = 'lfo osc pitch',
                          CONF_filter_Keywords3 = 0,
                          CONF_filter_Keywords4str = 'arp eq porta chor delay unison',
                          CONF_filter_Keywords4 = 0,
                          CONF_smooth = 0,
                          
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
    
    if DATA.extstate.UI_appatinit == 1 then 
      DATA2:GetFocusedFXData() 
    end
    
    DATA:GUIinit()
    GUI_RESERVED_init(DATA)
    RUN()
  end
  --------------------------------------------------------------------- 
  function GUI_RESERVED_init_shortcuts(DATA)
    if DATA.extstate.UI_enableshortcuts == 0 then return end
    
    DATA.GUI.shortcuts[32] = function() VF_Action(40044) end -- space to transport play
    
  end
  -------------------------------------------------------------------- 
  function DATA_RESERVED_ONPROJCHANGE(DATA)
    --DATA2:GetFocusedFXData() 
    GUI_RESERVED_BuildLayer_Refresh(DATA) 
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_BuildLayer_Refresh(DATA) 
    DATA.GUI.buttons.Rlayer.refresh = true  
    local layerid = DATA.GUI.custom_layerset2
    if not (DATA2.FXdata and DATA2.FXdata.params ) then return end
    for paramid = 1, #DATA2.FXdata.params do
      if not DATA.GUI.buttons['paramsrc'..paramid] then return end
      DATA.GUI.buttons['paramsrc'..paramid].txt = DATA2.FXdata.params[paramid].name..': '.. DATA2.FXdata.params[paramid].formatparam
      DATA.GUI.buttons['paramsrc'..paramid].data = DATA2.FXdata.params[paramid]
      DATA.GUI.buttons['paramdest'..paramid].txt = DATA2.FXdata.params[paramid].name
      DATA.GUI.buttons['paramdest'..paramid].data = DATA2.FXdata.params[paramid] 
    end
  end
  -------------------------------------------------------------------- 
  function DATA2:RevertInitialValues()
    if not DATA2.FXdata.params then return end
    local ptr = DATA2.FXdata.ptr
    local fxnum = DATA2.FXdata.fxnum
    local func_str = DATA2.FXdata.func_str
    for paramid = 1, #DATA2.FXdata.params_init do  
      local out_val = DATA2.FXdata.params_init[paramid].value
      _G[func_str..'SetParamNormalized'](ptr, fxnum, paramid-1, out_val) 
      _G[func_str..'EndParamEdit'](ptr, fxnum,paramid-1 )
    end
  end
  --------------------------------------------------------------------  
  function DATA2:GetFocusedFXData() -- also update to current params
    -- get current config  
    local parse_globalfilt = {}
    if DATA.extstate.CONF_filter_Keywords1==1 and  DATA.extstate.CONF_filter_Keywords1str ~= '' then for word in DATA.extstate.CONF_filter_Keywords1str:gmatch('[^%s]+') do parse_globalfilt[#parse_globalfilt+1] = word end  end
    if DATA.extstate.CONF_filter_Keywords2==1 and  DATA.extstate.CONF_filter_Keywords2str ~= '' then for word in DATA.extstate.CONF_filter_Keywords2str:gmatch('[^%s]+') do parse_globalfilt[#parse_globalfilt+1] = word end  end
    if DATA.extstate.CONF_filter_Keywords3==1 and  DATA.extstate.CONF_filter_Keywords3str ~= '' then for word in DATA.extstate.CONF_filter_Keywords3str:gmatch('[^%s]+') do parse_globalfilt[#parse_globalfilt+1] = word end  end
    if DATA.extstate.CONF_filter_Keywords4==1 and  DATA.extstate.CONF_filter_Keywords4str ~= '' then for word in DATA.extstate.CONF_filter_Keywords4str:gmatch('[^%s]+') do parse_globalfilt[#parse_globalfilt+1] = word end  end
    
    -- get main stuff
    local retval, tracknumber, itemnumber, fxnum = reaper.GetFocusedFX2()
    local tr = CSurf_TrackFromID( tracknumber, false )
    if not ValidatePtr2( 0, tr, 'MediaTrack*' ) then return end
     local it = GetTrackMediaItem( tr, itemnumber ) 
    local func_str = 'TrackFX_'
    if retval&1 == 1 then 
      ptr = tr 
     elseif retval&2 == 2 then 
      local takeidx = (fxnum>>16)&0xFFFF 
      ptr = GetTake( it, takeidx ) 
      func_str = 'TakeFX_'
     else
      return 
    end
    local fx_GUID = _G[func_str..'GetFXGUID'](ptr, fxnum&0xFFFF)    
    local retval, buf = _G[func_str..'GetFXName'](ptr, fxnum&0xFFFF)
    local cnt_params = _G[func_str..'GetNumParams'](ptr, fxnum&0xFFFF)
    
    
    
    -- init tables
      --if DATA2.FXdata and DATA2.FXdata.fx_GUID == fx_GUID then       DATA2:RevertInitialValues()  return end
      if not DATA2.FXdata then DATA2.FXdata = {}  end
      local t = DATA2.FXdata 
      t.fx_GUID = fx_GUID
      t.fx_name = buf
      t.ptr = ptr
      t.func_str = func_str
      t.fxnum = fxnum&0xFFFF 
      local param_bypass = _G[func_str..'GetParamFromIdent']( ptr, fxnum&0xFFFF, ':bypass' )
      local param_wet = _G[func_str..'GetParamFromIdent']( ptr, fxnum&0xFFFF, ':wet' )
      local param_delta = _G[func_str..'GetParamFromIdent']( ptr, fxnum&0xFFFF, ':delta' ) 
      
      for i = 1, cnt_params do
        local value = _G[func_str..'GetParamNormalized'](ptr, fxnum&0xFFFF, i-1) 
        local retval, bufparam = _G[func_str..'GetParamName'](ptr, fxnum&0xFFFF, i-1) 
        local retval, formatparam = _G[func_str..'GetFormattedParamValue'](ptr, fxnum&0xFFFF, i-1) 
        local retval, step, smallstep, largestep, istoggle = _G[func_str..'GetParameterStepSizes'](ptr, fxnum&0xFFFF, i-1) 
        
        local ignore = false
        if DATA.extstate.CONF_filter_untitledparams == 1 and bufparam:gsub('[%s]+','') == '' then ignore = true end
        if ignore == false and DATA.extstate.CONF_filter_system == 1 and (i-1==param_bypass or  i-1==param_wet or i-1==param_delta ) then ignore = true end
        if ignore == false and #parse_globalfilt> 0 then
          for word = 1, #parse_globalfilt do
            if bufparam:lower():match(parse_globalfilt[word]:lower()) then ignore = true break end
          end
        end
        if not t.params then t.params = {} end
        if not t.params[i] then t.params[i] = {} end
        t.params[i].value = value
        t.params[i].name = bufparam
        t.params[i].formatparam = formatparam
        t.params[i].istoggle = istoggle
        t.params[i].ignore = ignore
        if not t.hasinitialparams then 
          if not t.params_init then t.params_init = {} end
          if not t.params_init[i] then t.params_init[i] = {value = value} end
        end
      end 
      
    return t
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_draw_data2(DATA, b)
    if not b.data then return end
    local x,y,w,h = b.x*DATA.GUI.default_scale,b.y*DATA.GUI.default_scale,b.w*DATA.GUI.default_scale,b.h*DATA.GUI.default_scale
    local t = b.data
    local val = t.value or 0
    if b.data_ismorph then val = t.value_morph end
    if val and not t.istoggle then  
      -- backgr fill
        DATA:GUIhex2rgb('#FFFFFF', true)
        gfx.a =0.3
        gfx.rect(x+1,y+h-3,w*val-1,2,1)
    end
    if t.istoggle then
      val = 0
      if t.value >= 0.5 then val = 1 end
      gfx.set(1,1,1,1)
      circle_r = 3
      gfx.circle(x+w- circle_r-DATA.GUI.custom_offset,math.floor(y+h/2-circle_r/2 +1) ,4,val)
    end
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_BuildLayer(DATA) 
    local boundary = DATA.GUI.buttons.Rlayer
    DATA.GUI.buttons.Rlayer.refresh = true 
    
    local layerid = DATA.GUI.custom_layerset2
    if not (DATA2.FXdata and DATA2.FXdata.params ) then return end
    
    -- clean table
    for key in spairs(DATA.GUI.buttons) do if key:match('paramsrc') or key:match('paramdest') then DATA.GUI.buttons[key] = nil end end
    
    local y_out0 = 0
    local y_out = y_out0
    local param_h = 25
    for paramid = 1, #DATA2.FXdata.params do
      DATA.GUI.buttons['paramsrc'..paramid] = 
      {
        x = boundary.x,
        y = y_out,
        w = DATA.GUI.custom_setposx/2-DATA.GUI.custom_offset,
        h = param_h-1,
        layer = layerid,
        txt = DATA2.FXdata.params[paramid].name..': '.. DATA2.FXdata.params[paramid].formatparam,
        data = DATA2.FXdata.params[paramid],
        txt_flags=4 ,
        frame_a = 0,
        hide = DATA2.FXdata.params[paramid].ignore,
        onmouserelease = function() 
                  -- collect selection
                    if DATA.GUI.Shift then 
                      DATA.GUI.buttons['paramsrc'..paramid].sel_isselected = true
                      local cnt_selection = 0
                      local cur_id = paramid
                      local min_id, max_id = math.huge,-1
                      for paramid0 = 1, #DATA2.FXdata.params do
                        if DATA.GUI.buttons['paramsrc'..paramid0] and DATA.GUI.buttons['paramsrc'..paramid0].sel_isselected == true then 
                          cnt_selection = cnt_selection + 1
                          min_id = math.min(min_id, paramid0)
                          max_id = math.max(max_id, paramid0)
                        end
                      end
                      if cnt_selection == 1 then 
                        return
                       elseif cnt_selection > 1 then 
                        if min_id < cur_id then
                          for i = min_id, cur_id do DATA.GUI.buttons['paramsrc'..i].sel_isselected = true end
                         elseif min_id >= cur_id and max_id > cur_id then
                          for i = cur_id, max_id do DATA.GUI.buttons['paramsrc'..i].sel_isselected = true end
                        end
                      end
                      DATA.GUI.buttons.Rlayer.refresh = true 
                      return
                    end
                  
                  -- toggle selection
                    DATA.GUI.buttons['paramsrc'..paramid].sel_isselected = not DATA.GUI.buttons['paramsrc'..paramid].sel_isselected  
                    DATA.GUI.buttons.Rlayer.refresh = true 
                end,
                onmousereleaseR = function() -- reset selection
                    for paramid0 = 1, #DATA2.FXdata.params do DATA.GUI.buttons['paramsrc'..paramid0].sel_isselected = false end
                    DATA.GUI.buttons.Rlayer.refresh = true 
                  end,
                sel_allow = true,
              } 
      DATA.GUI.buttons['paramdest'..paramid] = 
            {
              x = boundary.x+DATA.GUI.custom_setposx/2,
              y = y_out,
              w = DATA.GUI.custom_setposx/2-DATA.GUI.custom_offset*3-DATA.GUI.custom_scrollw,
              h = param_h-1,
              layer = layerid,
              txt = DATA2.FXdata.params[paramid].name,
              data = DATA2.FXdata.params[paramid],
              data_ismorph = true,
              txt_flags=4 ,
              frame_a = 0,
              ignoremouse_refresh = true,
              hide = DATA2.FXdata.params[paramid].ignore,
              }
      if not DATA2.FXdata.params[paramid].ignore then y_out = y_out + param_h end
    end

    return y_out-y_out0
  end
  ---------------------------------------------------------------------  
  function DATA2:GenerateRandomSnapshot()
    if not DATA2.FXdata.params then return end
    for paramid = 1, #DATA2.FXdata.params do
      DATA2.FXdata.params[paramid].value_morph = math.random()
    end
    GUI_RESERVED_BuildLayer_Refresh(DATA) 
  end  
  ----------------------------------------------------------------------  
  function DATA_RESERVED_ONCUSTSTATECHANGE(DATA)
    if DATA.morphstate and DATA.extstate.CONF_smooth >  0 then
      local cur_clock = os.clock()
      DATA2.morph_value = VF_lim((cur_clock - DATA.TS_morph+0.04) / DATA.extstate.CONF_smooth)
      if cur_clock - DATA.TS_morph > DATA.extstate.CONF_smooth then
        DATA.UPD.oncustomstatechange = false
        DATA.morphstate = nil
       else
        DATA2:Morph()
        --GUI_RESERVED_BuildLayer_Refresh(DATA) 
      end
    end
  end
  ----------------------------------------------------------------------  
  function DATA2:Morph(not_generate, slider_mode, is_init)
    if is_init then DATA2:GetFocusedFXData() end
    if not DATA.morphstate then 
      if not slider_mode then DATA2:GetFocusedFXData()  end
      if not not_generate then DATA2:GenerateRandomSnapshot() end
    end 
    
    if not DATA2.FXdata.params then return end
    
    if is_init or (DATA.extstate.CONF_smooth > 0 and not DATA.morphstate and not slider_mode) then
      DATA.morphstate = true
      DATA.morphstate_cnt = 0
      DATA.TS_morph = os.clock()
      DATA.UPD.oncustomstatechange = true
    end
    local ptr = DATA2.FXdata.ptr
    local fxnum = DATA2.FXdata.fxnum
    local func_str = DATA2.FXdata.func_str
    
    local cnt_selection = 0 
    for paramid = 1, #DATA2.FXdata.params do  
      if not DATA2.FXdata.params[paramid].ignore and DATA.GUI.buttons['paramsrc'..paramid].sel_isselected and DATA.GUI.buttons['paramsrc'..paramid].sel_isselected  == true then cnt_selection = cnt_selection + 1 end
    end
    
    for paramid = 1, #DATA2.FXdata.params do  
      if not DATA2.FXdata.params[paramid].ignore and (cnt_selection == 0 or (cnt_selection > 0 and DATA.GUI.buttons['paramsrc'..paramid].sel_isselected and DATA.GUI.buttons['paramsrc'..paramid].sel_isselected == true)) then
        if not DATA2.FXdata.params[paramid].value_morph then break end
        if (DATA2.morph_value and (DATA.extstate.CONF_smooth > 0 and DATA.morphstate_cnt and DATA.morphstate_cnt > 0)) or DATA.extstate.CONF_smooth ==0 then 
          local out_val = DATA2.FXdata.params[paramid].value - (DATA2.FXdata.params[paramid].value - DATA2.FXdata.params[paramid].value_morph ) * (DATA2.morph_value or 1)
          _G[func_str..'SetParamNormalized'](ptr, fxnum, paramid-1, out_val) 
          --_G[func_str..'EndParamEdit'](ptr, fxnum,paramid-1 )
        end
      end
    end
    
    if DATA.morphstate and DATA.morphstate_cnt then  DATA.morphstate_cnt = DATA.morphstate_cnt + 1 end
    DATA.morphstate_cnt = DATA.morphstate_cnt + 1
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_init(DATA)
    GUI_RESERVED_init_shortcuts(DATA)
    DATA.GUI.buttons = {} 
    
    DATA.GUI.custom_scrollw = 10
    DATA.GUI.custom_offset = math.floor(DATA.GUI.default_scale*DATA.GUI.default_txt_fontsz/2)
    DATA.GUI.custom_mainsepx = (gfx.w/DATA.GUI.default_scale)*0.4
    DATA.GUI.custom_mainsepxupd = 150
    DATA.GUI.custom_setposx = gfx.w/DATA.GUI.default_scale - DATA.GUI.custom_mainsepx
    DATA.GUI.custom_mainbuth = 30
    DATA.GUI.custom_setposy = (DATA.GUI.custom_offset+DATA.GUI.custom_mainbuth)*3
    DATA.GUI.custom_tracklistw = (gfx.w/DATA.GUI.default_scale- DATA.GUI.custom_mainsepx)-DATA.GUI.custom_offset
    DATA.GUI.custom_tracklisty = DATA.GUI.custom_offset*2+DATA.GUI.custom_mainbuth
    DATA.GUI.custom_tracklisth = gfx.h/DATA.GUI.default_scale - DATA.GUI.custom_tracklisty-DATA.GUI.custom_offset
    DATA.GUI.custom_matchmenu = 30--*DATA.GUI.default_scale
    DATA.GUI.custom_knobw = 90--*DATA.GUI.default_scale
    
    DATA.GUI.buttons.Rlayer = { x=DATA.GUI.custom_offset,
                           y=DATA.GUI.custom_tracklisty,
                           w=DATA.GUI.custom_tracklistw,
                           h=DATA.GUI.custom_tracklisth,
                           frame_a = 0,
                           layer = DATA.GUI.custom_layerset2,
                           ignoremouse = true,
                           hide = true,
                           }
    DATA:GUIBuildLayer()
    local fx_name ='Get focused FX'
    if DATA2.FXdata and DATA2.FXdata.fx_name then fx_name =DATA2.FXdata.fx_name end
    DATA.GUI.buttons.getFX = { x=DATA.GUI.custom_offset,
                          y=DATA.GUI.custom_offset,
                          w=DATA.GUI.custom_setposx/2-DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_mainbuth,
                          txt = fx_name,
                          txt_fontsz = DATA.GUI.default_txt_fontsz3,
                          onmouseclick =  function () 
                            DATA2:GetFocusedFXData()
                            DATA.GUI.buttons.getFX.txt = DATA2.FXdata.fx_name
                            --GUI_RESERVED_BuildLayer(DATA) 
                            DATA:GUIBuildLayer()
                          end,
                          } 
    
    local gentxt = 'Generate snapshot'
    if DATA.extstate.UI_mergegenmorph == 1 then gentxt = 'Generate / Morph snapshot' end
    DATA.GUI.buttons.generate = { x=DATA.GUI.custom_setposx/2+DATA.GUI.custom_offset,
                          y=DATA.GUI.custom_offset,
                          w=DATA.GUI.custom_setposx/2-DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_mainbuth,
                          txt = gentxt,
                          txt_short = DATA.extstate.UI_trfilter,
                          txt_fontsz = DATA.GUI.default_txt_fontsz3,
                          onmouseclick =  function () 
                                            DATA2:GenerateRandomSnapshot()
                                            if DATA.extstate.UI_mergegenmorph == 1 then 
                                              Undo_BeginBlock2( 0 )
                                              reaper.PreventUIRefresh( -1 )
                                              DATA2:Morph(true, nil, true)
                                              Undo_EndBlock2( 0,DATA.extstate.mb_title, 0xFFFFFFFF )
                                            end
                                          end,
                          } 
                          
    DATA.GUI.buttons.preset = { x=DATA.GUI.custom_setposx+DATA.GUI.custom_offset,
                            y=gfx.h/DATA.GUI.default_scale-DATA.GUI.custom_mainbuth-DATA.GUI.custom_offset,
                            w=DATA.GUI.custom_mainsepx-DATA.GUI.custom_offset*2,
                            h=DATA.GUI.custom_mainbuth,
                            txt = 'Preset: '..(DATA.extstate.CONF_NAME or ''),
                            txt_fontsz = DATA.GUI.default_txt_fontsz3,
                            onmouseclick =  function() DATA:GUIbut_preset() end}                          
    DATA.GUI.buttons.Morph = { x=DATA.GUI.custom_setposx+DATA.GUI.custom_offset,--
                          y=DATA.GUI.custom_offset,--
                          w=DATA.GUI.custom_mainsepx-DATA.GUI.custom_offset*2-DATA.GUI.custom_knobw-DATA.GUI.custom_offset,--
                          h=DATA.GUI.custom_mainbuth,--
                          txt = 'Morph',
                          txt_fontsz = DATA.GUI.default_txt_fontsz3,
                          onmouseclick =  function () 
                            Undo_BeginBlock2( 0 )
                            reaper.PreventUIRefresh( -1 )
                            DATA2:Morph(true, nil, true)
                            Undo_EndBlock2( 0, DATA.extstate.mb_title, 0xFFFFFFFF )
                          end,
                          }                                             
    DATA.GUI.buttons.knob = { x=DATA.GUI.custom_setposx+DATA.GUI.custom_mainsepx-DATA.GUI.custom_knobw-DATA.GUI.custom_offset,
                          y=DATA.GUI.custom_offset,
                          w=DATA.GUI.custom_knobw,
                          h=DATA.GUI.custom_mainbuth,
                          txt = '',
                          knob_isknob = true,
                          val_res = 0.25,
                          val = 0,
                          frame_a = DATA.GUI.default_framea_normal,
                          frame_asel = DATA.GUI.default_framea_normal,
                          back_sela = 0,
                          hide = DATA.GUI.compactmode==1,
                          ignoremouse = DATA.GUI.compactmode==1,
                          onmousedrag =     function() DATA2.morph_value = DATA.GUI.buttons.knob.val DATA2:Morph(true, true) end,
                          onmouserelease  = function() DATA2.morph_value = DATA.GUI.buttons.knob.val DATA2:Morph(true, true) Undo_OnStateChange2( 0, DATA.extstate.mb_title )  end 
                        }                          
    DATA.GUI.buttons.Rsettings = { x=DATA.GUI.custom_setposx,
                           y=DATA.GUI.custom_mainbuth+DATA.GUI.custom_offset,
                           w=DATA.GUI.custom_mainsepx,
                           h=gfx.h/DATA.GUI.default_scale - DATA.GUI.custom_mainbuth*2-DATA.GUI.custom_offset*2,
                           txt = 'Settings',
                           --txt_fontsz = DATA.GUI.default_txt_fontsz3,
                           frame_a = 0,
                           offsetframe = DATA.GUI.custom_offset,
                           offsetframe_a = 0.1,
                           ignoremouse = true,
                           }
    DATA:GUIBuildSettings() 
    
    for but in pairs(DATA.GUI.buttons) do DATA.GUI.buttons[but].key = but end
  end
  ---------------------------------------------------------------------  
  function DATA2:ProcessAtChange() 
  
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_BuildSettings(DATA)
    local readoutw_extw = 150
    local globfiltstr = 'Keywords1: '..DATA.extstate.CONF_filter_Keywords1str 
    local globfiltstr2 = 'Keywords2: '..DATA.extstate.CONF_filter_Keywords2str 
    local globfiltstr3 = 'Keywords3: '..DATA.extstate.CONF_filter_Keywords3str 
    local globfiltstr4 = 'Keywords3: '..DATA.extstate.CONF_filter_Keywords4str 
    local  t = 
    { 
      {str = 'Actions' ,                                  group = 1, itype = 'sep'}, 
        {str = 'Revert init values',                      group = 1, itype = 'button', level = 1, func_onrelease =  function()DATA2:RevertInitialValues() end},
      {str = 'Filtering params (all plugins)' ,           group = 2, itype = 'sep'}, 
        {str = 'Untitled parameters' ,                    group = 2, itype = 'check', level = 1, confkey = 'CONF_filter_untitledparams'},
        {str = 'Bypass / Wet / Delta' ,                   group = 2, itype = 'check', level = 1, confkey = 'CONF_filter_system'},
        {str = globfiltstr,                               group = 2, itype = 'button', level = 1, func_onrelease =  function()  
                                                                                                                      local retval, retvals_csv = GetUserInputs( 'Global filter', 1, 'Space separated words,extrawidth=500', DATA.extstate.CONF_filter_Keywords1str )
                                                                                                                      if retval then DATA.extstate.CONF_filter_Keywords1str = retvals_csv DATA.UPD.onconfchange = true DATA2:GetFocusedFXData() DATA:GUIBuildSettings() DATA:GUIBuildLayer() end
                                                                                                                    end},
        {str = 'Keywords1' ,                              group = 2, itype = 'check', level = 1, confkey = 'CONF_filter_Keywords1', func_onrelease = function() DATA2:GetFocusedFXData() DATA:GUIBuildLayer() end},                                                                                                                    
        {str = globfiltstr2,                              group = 2, itype = 'button', level = 1, func_onrelease =  function()  
                                                                                                                      local retval, retvals_csv = GetUserInputs( 'Global filter', 1, 'Space separated words,extrawidth=500', DATA.extstate.CONF_filter_Keywords2str )
                                                                                                                      if retval then DATA.extstate.CONF_filter_Keywords2str = retvals_csv DATA.UPD.onconfchange = true DATA2:GetFocusedFXData() DATA:GUIBuildSettings() DATA:GUIBuildLayer() end
                                                                                                                    end},
        {str = 'Keywords2' ,                              group = 2, itype = 'check', level = 1, confkey = 'CONF_filter_Keywords2', func_onrelease = function() DATA2:GetFocusedFXData() DATA:GUIBuildLayer() end},          
        {str = globfiltstr3,                              group = 2, itype = 'button', level = 1, func_onrelease =  function()  
                                                                                                                      local retval, retvals_csv = GetUserInputs( 'Global filter', 1, 'Space separated words,extrawidth=500', DATA.extstate.CONF_filter_Keywords3str )
                                                                                                                      if retval then DATA.extstate.CONF_filter_Keywords3str = retvals_csv DATA.UPD.onconfchange = true DATA2:GetFocusedFXData() DATA:GUIBuildSettings() DATA:GUIBuildLayer() end
                                                                                                                    end},
        {str = 'Keywords3' ,                              group = 2, itype = 'check', level = 1, confkey = 'CONF_filter_Keywords3', func_onrelease = function() DATA2:GetFocusedFXData() DATA:GUIBuildLayer() end},      
        {str = globfiltstr4,                              group = 2, itype = 'button', level = 1, func_onrelease =  function()  
                                                                                                                      local retval, retvals_csv = GetUserInputs( 'Global filter', 1, 'Space separated words,extrawidth=500', DATA.extstate.CONF_filter_Keywords4str )
                                                                                                                      if retval then DATA.extstate.CONF_filter_Keywords4str = retvals_csv DATA.UPD.onconfchange = true DATA2:GetFocusedFXData() DATA:GUIBuildSettings() DATA:GUIBuildLayer() end
                                                                                                                    end},
        {str = 'Keywords4' ,                              group = 2, itype = 'check', level = 1, confkey = 'CONF_filter_Keywords4', func_onrelease = function() DATA2:GetFocusedFXData() DATA:GUIBuildLayer() end},   
         --
      {str = 'UI options' ,                               group = 5, itype = 'sep'},  
        {str = 'Enable shortcuts' ,                       group = 5, itype = 'check', confkey = 'UI_enableshortcuts', level = 1},
        {str = 'Init UI at mouse position' ,              group = 5, itype = 'check', confkey = 'UI_initatmouse', level = 1},
        --{str = 'Show tootips' ,                           group = 5, itype = 'check', confkey = 'UI_showtooltips', level = 1},
        --{str = 'Process on settings change',              group = 5, itype = 'check', confkey = 'UI_appatchange', level = 1},
        {str = 'Get Focused FX at initialization',        group = 5, itype = 'check', confkey = 'UI_appatinit', level = 1},
        {str = 'Generate / Morph',                        group = 5, itype = 'check', confkey = 'UI_mergegenmorph', level = 1, func_onrelease = function() GUI_RESERVED_init(DATA) end},
        {str = 'Smooth transition' ,                      group = 5, itype = 'readout', confkey = 'CONF_smooth', level = 1, val_min = 0, val_max = 10, val_res = 0.05, val_format = function(x) return VF_math_Qdec(x,3)..'s' end, val_format_rev = function(x) return tonumber(x:match('[%d%.]+')) end, func_onrelease = function() DATA2:ProcessAtChange(DATA) end},
      
    } 
    return t
    
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.10) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then main() end end