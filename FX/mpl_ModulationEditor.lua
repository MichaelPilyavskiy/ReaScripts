-- @description ModulationEditor
-- @version 1.10
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # rename action for clean modulation



  -- NOT gfx NOT reaper NOT VF NOT GUI NOT DATA NOT MAIN 
  
  --[[
    --[[{ str = '|Export learn state as XML into project path',
      func = function()  
        DATA2:ExportCSV()
      end
    },                              
    { str = 'Import learn state from XML',
      func = function()  
        DATA2:ImportCSV()
        DATA_RESERVED_ONPROJCHANGE(DATA)
      end
    },  
    
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
            ]]
            
            
  DATA2 = { aliasmap={}
          }
  ---------------------------------------------------------------------  
  function main()  
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.version = '1.10'
    DATA.extstate.extstatesection = 'MPL_ModulationEditor'
    DATA.extstate.mb_title = 'ModulationEditor'
    DATA.extstate.default = 
                          {  
                          wind_x =  100,
                          wind_y =  100,
                          wind_w =  300,
                          wind_h =  600,
                          dock =    0,
                          
                          CONF_NAME = 'default',
                          CONF_filtermode = 0,
                          
                          -- UI
                          UI_appatchange = 0, 
                          UI_enableshortcuts = 0,
                          UI_initatmouse = 0,
                          UI_showtooltips = 1,
                          UI_groupflags = 0, 
                          UI_aliasmap = '', 
                          
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
    DATA:GUIinit()
    RUN()
    DATA_RESERVED_ONPROJCHANGE(DATA)
  end
  ----------------------------------------------------------------------
  function DATA_RESERVED_DYNUPDATE()
    if DATA.GUI.wheel_trig == true then 
      if DATA.GUI.custom_scroll_off == true then return end
      if DATA.GUI.wheel_dir == true then mult = 1 else mult =  -1 end
      DATA.GUI.buttons.scroll.val = VF_lim(DATA.GUI.buttons.scroll.val + 0.1*mult)
      DATA2.scroll_list = DATA.GUI.buttons.scroll.val
      DATA.GUI.buttons.scroll.refresh = true
      GUI_nodes_init(DATA)
    end
  end
  ----------------------------------------------------------------------
  function DATA2:ProcessUndoBlock(f, name, a1,a2,a3,a4,a5,a6,a7,a8,a9,a10) 
    Undo_BeginBlock2( 0)
    defer(f(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10))
    Undo_EndBlock2( 0, name, 0xFFFFFFFF )
  end
  ---------------------------------------------------------------------  
  function DATA2:RefreshAliasMap()
    local str = ''
    for key in pairs(DATA2.aliasmap) do if DATA2.aliasmap[key] ~= '' then str = str..'[<'..key..'><'..DATA2.aliasmap[key]..'>]' end end
    DATA.extstate.UI_aliasmap = str
    DATA.UPD.onconfchange = true
  end
  ---------------------------------------------------------------------  
  function DATA2:ApplyPMOD(ctrl_key)
    param_t = DATA2.modulationstate[ctrl_key]
    local params = {
      'mod.active',
      'mod.baseline',
      'mod.visible',
      
      'plink.active',
      'plink.scale',
      'plink.offset',
      'plink.effect',
      'plink.param',
      'plink.midi_bus',
      'plink.midi_chan',
      'plink.midi_msg',
      'plink.midi_msg2',
      
      'acs.active',
      'acs.dir',
      'acs.strength',
      'acs.attack',
      'acs.release',
      'acs.dblo',
      'acs.dbhi',
      'acs.chan',
      'acs.stereo',
      'acs.x2',
      'acs.y2',
      
      'lfo.active',
      'lfo.dir',
      'lfo.phase',
      'lfo.speed',
      'lfo.strength',
      'lfo.temposync',
      'lfo.free',
      'lfo.shape',
      
      }
    local ret, track, fx = VF_GetFXByGUID(param_t.fxGUID)
    local pid = param_t.param
    if ret and pid then 
      for i = 1, #params do TrackFX_SetNamedConfigParm( track, fx, 'param.'..pid..params[i], param_t.PMOD[params[i]] ) end
    end
  end
  ---------------------------------------------------------------------
  function DATA2:Action_Dock()  
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
    
   gfx.dock(state ) 
  end
  ---------------------------------------------------------------------
  function DATA2:Action_ActiveteLastTouchedParam()   
      local retval, trackidx, itemidx, takeidx, fxidx, parm = GetTouchedOrFocusedFX( 0 )
      if not retval then return end
      local track = GetMasterTrack(0)
      if trackidx >=0 then track = GetTrack(0,trackidx) end
      TrackFX_SetNamedConfigParm( track, fxidx, 'param.'..parm..'.mod.active', 1)
      DATA_RESERVED_ONPROJCHANGE(DATA)
      DATA.UPD.onconfchange = true
  end
  --------------------------------------------------------------------
  function DATA2:Action_CleanSelectedTracksMod()    
    local ret =  MB( 'Clean selected tracks modulation', DATA.extstate.mb_title, 3 )
    if ret ~= 6 then return end
    
    for i = 1, CountSelectedTracks(0) do
      local track = GetSelectedTrack(0,i-1)
      for fx  = 1, TrackFX_GetCount( track ) do
        for parm = 1,  TrackFX_GetNumParams( track, fx -1) do
          local retval, str = TrackFX_GetNamedConfigParm( track, fx -1, 'param.'..(parm-1)..'.mod.active')
          if retval then
            TrackFX_SetNamedConfigParm( track, fx -1, 'param.'..(parm-1)..'.mod.active',0)
          end
        end
      end
    end
    
    DATA_RESERVED_ONPROJCHANGE(DATA)
    DATA.UPD.onconfchange = true
  end
  ---------------------------------------------------------------------  
  function DATA2:CollectProjectData()
    DATA2.aliasmap = {}
    if DATA.extstate.UI_aliasmap~=''then
      local mapstr = DATA.extstate.UI_aliasmap
      for block in mapstr:gmatch('%[.-%]') do
        local key,val = block:match('<(.-)><(.-)>')
        if key and val then
          DATA2.aliasmap[key] = val
        end
      end
    end
    
    DATA2.modulationstate = {}
    local cnt_tracks = CountTracks( 0 )
    for trackidx =0, cnt_tracks do
      local track =  GetTrack( 0, trackidx-1 )
      if not track then track = GetMasterTrack() end
      local fx_cnt = TrackFX_GetCount( track )
      local trcol =  GetTrackColor( track )
      local retval, trname = GetTrackName( track )
      local fxcnt = TrackFX_GetCount( track )
      for fx = 1, fxcnt do
        local retval, fxname = TrackFX_GetFXName( track, fx-1, '' )
        local parmcnt =  TrackFX_GetNumParams( track, fx-1 )
        if
        (
          DATA.extstate.CONF_filtermode == 0 or 
          (IsTrackSelected( track ) and DATA.extstate.CONF_filtermode==1) or
          ( TrackFX_GetOpen( track, fx-1 ) and DATA.extstate.CONF_filtermode==2)
        )then
          
                  for pid =0 , parmcnt-1 do
                    local retval, pname = TrackFX_GetParamName( track, fx-1, pid ) 
                    local mod_ret, modactive = TrackFX_GetNamedConfigParm( track, fx-1, 'param.'..pid..'.mod.active' )
                    if mod_ret then
                      local trGUID = GetTrackGUID( track)
                      local fxGUID = TrackFX_GetFXGUID( track, fx-1 )
                      local key = fxGUID..'_'..pid
                      
                      if not DATA2.modulationstate[key] then 
                        DATA2.modulationstate[key]={
                          trGUID = trGUID,
                          fxGUID = fxGUID,
                          param = pid,
                          fxname=fxname,
                          fxname_short = VF_ReduceFXname(fxname),
                          trname=trname,
                          pname = pname,
                          alias=alias,
                          ctrl_key=key,
                        }
                      end
                      local params = {
                        'mod.active',
                        'mod.baseline',
                        'mod.visible',
                        
                        'plink.active',
                        'plink.scale',
                        'plink.offset',
                        'plink.effect',
                        'plink.param',
                        'plink.midi_bus',
                        'plink.midi_chan',
                        'plink.midi_msg',
                        'plink.midi_msg2',
                        
                        'acs.active',
                        'acs.dir',
                        'acs.strength',
                        'acs.attack',
                        'acs.release',
                        'acs.dblo',
                        'acs.dbhi',
                        'acs.chan',
                        'acs.stereo',
                        'acs.x2',
                        'acs.y2',
                        
                        'lfo.active',
                        'lfo.dir',
                        'lfo.phase',
                        'lfo.speed',
                        'lfo.strength',
                        'lfo.temposync',
                        'lfo.free',
                        'lfo.shape',
                        
                        }
                      local params_val = {}
                      for i = 1, #params do
                        local _, str  = TrackFX_GetNamedConfigParm( track, fx-1, 'param.'..pid..params[i] )
                        params_val[params[i]]=tonumber(str) or str
                      end
                      DATA2.modulationstate[key].PMOD = params_val
                    end
          end
        end
      end
    end
    
  end
  ----------------------------------------------------------------------
  function GUI_nodes_01parameter(DATA, ctrl_t, node_yoffs) 
    local ctrl_key = ctrl_t.ctrl_key
    local frame_a = 0.5
    local infotxt = 
         ctrl_t.trname..' / '..
         ctrl_t.fxname_short..'/ '..
         ctrl_t.pname
    if DATA2.aliasmap[ctrl_key] then infotxt = DATA2.aliasmap[ctrl_key] end
    local xoffs= DATA.GUI.custom_node_x
    DATA.GUI.buttons['ctrl_'..ctrl_key] = { x=xoffs,-- +DATA.GUI.custom_base_wsingle,
                          y=node_yoffs,
                          w=DATA.GUI.custom_node_w,--DATA.GUI.custom_base_wsingle-1,
                          h=DATA.GUI.custom_node_nameh-1,
                          txt = infotxt,
                          txt_fontsz = DATA.GUI.custom_nodeparam_txtsz,
                          --txt_flags = 4,
                          onmouseclick =   function()  end,
                          hide = node_yoffs<DATA.GUI.custom_infoh,
                          ignoremouse = node_yoffs<DATA.GUI.custom_infoh,
                          refresh= true,
                          frame_a = frame_a,
                          frame_asel = frame_a,
                          onmouserelease = function()
                            local retval, retvals_csv = GetUserInputs( 'Alias', 1, ctrl_t.pname, DATA2.aliasmap[ctrl_key] or '' )
                            if retval then
                              if not DATA2.aliasmap[ctrl_key] then DATA2.aliasmap[ctrl_key] = {} end
                              DATA2.aliasmap[ctrl_key]=retvals_csv
                              DATA2:RefreshAliasMap()
                              DATA_RESERVED_ONPROJCHANGE(DATA)
                            end
                          end
                          }
  end
  ----------------------------------------------------------------------
  function GUI_nodes_02base(DATA, ctrl_t, node_yoffs)
    local ctrl_key = ctrl_t.ctrl_key
    local basekey = 'ctrl_'..ctrl_key..'base'
    local frame_a = 0
    
    local txt_a = DATA.GUI.custom_txta_OFF  if ctrl_t.PMOD['mod.active']&1==1 then txt_a = DATA.GUI.custom_txta_ON end
    local xoffs= DATA.GUI.custom_node_x
    DATA.GUI.buttons['ctrl_'..ctrl_key..'modactive'] = { x=xoffs,
                          y=node_yoffs,
                          hide = node_yoffs<DATA.GUI.custom_infoh,
                          ignoremouse = node_yoffs<DATA.GUI.custom_infoh,
                          w=DATA.GUI.custom_base_wsingle-1,
                          h=DATA.GUI.custom_node_nameh-1,
                          txt = 'Active',
                          txt_a = txt_a,
                          frame_a = 0,
                          frame_asel = 0,
                          txt_fontsz = DATA.GUI.custom_nodeparam_txtsz,
                          onmouserelease = function() 
                            ctrl_t.PMOD['mod.active']=ctrl_t.PMOD['mod.active']~1 DATA2:ApplyPMOD(ctrl_key)   
                            GUI_nodes_init(DATA)
                          end
                          } 
                          
    DATA.GUI.buttons[basekey] = { x=DATA.GUI.custom_node_x,
                          y=node_yoffs,
                          hide = node_yoffs<DATA.GUI.custom_infoh,
                          w=DATA.GUI.custom_node_w-1,
                          h=DATA.GUI.custom_node_nameh-1,
                          txt = infotxt,
                          --backgr_fill=0.3,
                          --backgr_col='#FFFFFF',
                          frame_a = 0,
                          frame_asel = 0,
                          txt_fontsz = DATA.GUI.custom_txtsz_ctrl,
                          ignoremouse = true,
                          --hide = true,
                          }
    local xoffs = DATA.GUI.custom_node_x+DATA.GUI.custom_base_wsingle
    DATA.GUI.buttons[basekey..'baseline'] = { 
                        x=xoffs,
                        y=node_yoffs,
                        hide = node_yoffs<DATA.GUI.custom_infoh,
                        ignoremouse = node_yoffs<DATA.GUI.custom_infoh,
                        w=DATA.GUI.custom_base_wsingle-1,
                        h=DATA.GUI.custom_node_nameh-1,
                        txt = 'Base',
                          frame_a = 0,
                          frame_asel = 0,
                        val = ctrl_t.PMOD['mod.baseline'],
                        val_res=DATA.GUI.custom_val_res,
                        knob_showvalueright = true,
                        txt_fontsz = DATA.GUI.custom_txtsz_ctrl,
                        back_sela = 0,
                        knob_isknob = true,
                          onmousetrig = function() DATA2.ONPARAMDRAG = true end,
                          onmousedrag =   function() 
                                            DATA2.ONPARAMDRAG = true
                                            ctrl_t.PMOD['mod.baseline']=DATA.GUI.buttons[basekey..'baseline'].val
                                            DATA.GUI.buttons[basekey..'baseline'].txt = GUI_format_val(ctrl_t.PMOD['mod.baseline'],'mod.baseline')
                                            DATA.GUI.buttons[basekey..'baseline'].refresh = true
                                            DATA2:ApplyPMOD(ctrl_key) 
                                          end,
                          onmouserelease =function()
                                            DATA2.ONPARAMDRAG = false
                                            ctrl_t.PMOD['mod.baseline']=DATA.GUI.buttons[basekey..'baseline'].val
                                            DATA.GUI.buttons[basekey..'baseline'].txt = 'Base'
                                            DATA.GUI.buttons[basekey..'baseline'].refresh = true
                                            DATA2:ApplyPMOD(ctrl_key)
                                          end,
                        }  
    xoffs = xoffs + DATA.GUI.custom_base_wsingle
    local txt_a = DATA.GUI.custom_txta_OFF  if ctrl_t.PMOD['mod.visible']&1==1 then txt_a = DATA.GUI.custom_txta_ON end
    DATA.GUI.buttons[basekey..'modvisible'] = { x=xoffs,
                          y=node_yoffs,
                          hide = node_yoffs<DATA.GUI.custom_infoh,
                          ignoremouse = node_yoffs<DATA.GUI.custom_infoh,
                          w=DATA.GUI.custom_base_wsingle-1,
                          h=DATA.GUI.custom_node_nameh-1,
                          txt = 'Visible',
                          txt_a = txt_a,
                          frame_a = 0,
                          frame_asel = 0,
                          txt_fontsz = DATA.GUI.custom_txtsz_ctrl,
                          onmouserelease = function() 
                            ctrl_t.PMOD['mod.visible']=ctrl_t.PMOD['mod.visible']~1 DATA2:ApplyPMOD(ctrl_key)   
                            GUI_nodes_init(DATA)
                          end
                          }   
                         
  end 
  ----------------------------------------------------------------------
  function GUI_format_val(x, key) 
    if key == 'mod.baseline' then return math.floor(x*100)..'%' end
  end
  ----------------------------------------------------------------------
  function GUI_nodes_03lfo(DATA, ctrl_t,  node_yoffs)   
    local ctrl_key = ctrl_t.ctrl_key
    local basekey = 'ctrl_'..ctrl_key..'lfo'
    local xoffs = DATA.GUI.custom_node_x 
    --xoffs = xoffs + DATA.GUI.custom_base_wsingle                      
    local maxspeedHz = 8 
    local txt_a = DATA.GUI.custom_txta_OFF  if ctrl_t.PMOD['lfo.active']&1==1 then txt_a = DATA.GUI.custom_txta_ON end
    DATA.GUI.buttons[basekey..'lfoactive'] = {x=xoffs,
                          y=node_yoffs,
                          hide = node_yoffs<DATA.GUI.custom_infoh,
                          ignoremouse = node_yoffs<DATA.GUI.custom_infoh,
                          w=DATA.GUI.custom_base_wsingle-1,
                          h=DATA.GUI.custom_node_nameh-1,
                          txt = 'LFO',
                          txt_a = txt_a,
                            frame_a = 0,
                            frame_asel = 0,
                          txt_fontsz = DATA.GUI.custom_txtsz_ctrl,
                          onmouserelease = function() 
                            ctrl_t.PMOD['lfo.active']=ctrl_t.PMOD['lfo.active']~1 DATA2:ApplyPMOD(ctrl_key)   
                            GUI_nodes_init(DATA)
                          end
                          } 
    if ctrl_t.PMOD['lfo.active']&1==0 then return end                       
    xoffs = DATA.GUI.custom_node_x + DATA.GUI.custom_base_wsingle                      
    DATA.GUI.buttons[basekey..'lfo.strength'] = { 
                          knob_a = txt_a/2,
                          knob_isknob = true,
                          knob_showvalueright = true,
                          val_res=DATA.GUI.custom_val_res,
                          x=xoffs,
                          y=node_yoffs,
                          hide = node_yoffs<DATA.GUI.custom_infoh,
                          ignoremouse = node_yoffs<DATA.GUI.custom_infoh,
                          w=DATA.GUI.custom_base_wsingle-1,
                          h=DATA.GUI.custom_node_nameh-1,
                          txt = 'Strength',
                          txt_a = txt_a,
                          frame_a = 0,
                          frame_asel = 0,
                          txt_fontsz = DATA.GUI.custom_txtsz_ctrl,
                          val = ctrl_t.PMOD['lfo.strength'],
                          --backgr_fill = 0,
                          onmousedrag =   function() 
                                            DATA2.ONPARAMDRAG = true
                                            ctrl_t.PMOD['lfo.strength']=DATA.GUI.buttons[basekey..'lfo.strength'].val
                                            DATA.GUI.buttons[basekey..'lfo.strength'].refresh = true
                                            DATA2:ApplyPMOD(ctrl_key) 
                                          end,
                          onmouserelease =function()
                                            DATA2.ONPARAMDRAG = false
                                            ctrl_t.PMOD['lfo.strength']=DATA.GUI.buttons[basekey..'lfo.strength'].val
                                            DATA.GUI.buttons[basekey..'lfo.strength'].refresh = true
                                            DATA2:ApplyPMOD(ctrl_key)
                                          end,
                          } 

    xoffs =xoffs + DATA.GUI.custom_base_wsingle   
    local txt = 'Sine'
    if ctrl_t.PMOD['lfo.shape'] == 1 then txt = 'Square' end
    if ctrl_t.PMOD['lfo.shape'] == 2 then txt = 'Saw L' end
    if ctrl_t.PMOD['lfo.shape'] == 3 then txt = 'Saw R' end
    if ctrl_t.PMOD['lfo.shape'] == 4 then txt = 'Triangle' end
    if ctrl_t.PMOD['lfo.shape'] == 5 then txt = 'Random' end
    DATA.GUI.buttons[basekey..'lfo.shape'] = { 
                          knob_a = txt_a/2,
                          --knob_isknob = true,
                          knob_showvalueright = true,
                          val_res=DATA.GUI.custom_val_res,
                          x=xoffs,
                          y=node_yoffs,
                          hide = node_yoffs<DATA.GUI.custom_infoh,
                          ignoremouse = node_yoffs<DATA.GUI.custom_infoh,
                          w=DATA.GUI.custom_base_wsingle-1,
                          h=DATA.GUI.custom_node_nameh-1,
                          txt = txt,
                          txt_a = txt_a,
                          frame_a = 0,
                          frame_asel = 0,
                          txt_fontsz = DATA.GUI.custom_txtsz_ctrl,
                          val = ctrl_t.PMOD['lfo.shape'],
                          --backgr_fill = 0,
                          onmouserelease =function()
                                            DATA:GUImenu(
                                              {
                                                { str = 'Sine', func = function() ctrl_t.PMOD['lfo.shape'] = 0 end},
                                                { str = 'Square', func = function() ctrl_t.PMOD['lfo.shape'] = 1 end},
                                                { str = 'Saw L', func = function() ctrl_t.PMOD['lfo.shape'] = 2 end},
                                                { str = 'Saw R', func = function() ctrl_t.PMOD['lfo.shape'] = 3 end},
                                                { str = 'Triangle', func = function() ctrl_t.PMOD['lfo.shape'] = 4 end},
                                                { str = 'Random', func = function() ctrl_t.PMOD['lfo.shape'] = 5 end},
                                              }
                                            )
                                            
                                            local txt = 'Sine'
                                            if ctrl_t.PMOD['lfo.shape'] == 1 then txt = 'Square' end
                                            if ctrl_t.PMOD['lfo.shape'] == 2 then txt = 'Saw L' end
                                            if ctrl_t.PMOD['lfo.shape'] == 3 then txt = 'Saw R' end
                                            if ctrl_t.PMOD['lfo.shape'] == 4 then txt = 'Triangle' end
                                            if ctrl_t.PMOD['lfo.shape'] == 5 then txt = 'Random' end
                                            DATA.GUI.buttons[basekey..'lfo.shape'].txt = txt
                                            DATA.GUI.buttons[basekey..'lfo.shape'].refresh = true
                                            DATA2:ApplyPMOD(ctrl_key)
                                          end,
                          }      
    xoffs =xoffs + DATA.GUI.custom_base_wsingle   
    local txt = 'Sync On' if ctrl_t.PMOD['lfo.temposync']&1~=1 then  txt = 'Sync Off' end                     
    DATA.GUI.buttons[basekey..'lfo.temposync'] = { 
                          knob_a = txt_a/2,
                          --knob_isknob = true,
                          knob_showvalueright = true,
                          val_res=DATA.GUI.custom_val_res,
                          x=xoffs,
                          y=node_yoffs,
                          hide = node_yoffs<DATA.GUI.custom_infoh,
                          ignoremouse = node_yoffs<DATA.GUI.custom_infoh,
                          w=DATA.GUI.custom_base_wsingle-1,
                          h=DATA.GUI.custom_node_nameh-1,
                          txt = txt,
                          txt_a = txt_a,
                          frame_a = 0,
                          frame_asel = 0,
                          txt_fontsz = DATA.GUI.custom_txtsz_ctrl,
                          val = ctrl_t.PMOD['lfo.temposync'],
                          --backgr_fill = 0,
                          onmouserelease =function()
                                            ctrl_t.PMOD['lfo.temposync'] = ctrl_t.PMOD['lfo.temposync']~1
                                            local txt = 'Sync On' if ctrl_t.PMOD['lfo.temposync']&1~=1 then  txt = 'Sync Off' end   
                                            DATA.GUI.buttons[basekey..'lfo.temposync'].txt = txt
                                            DATA.GUI.buttons[basekey..'lfo.temposync'].refresh = true
                                            DATA2:ApplyPMOD(ctrl_key)
                                          end,
                          }                           
                          
    if ctrl_t.PMOD['lfo.active'] == 0 then return end
    local xoffs = DATA.GUI.custom_node_x +DATA.GUI.custom_base_wsingle
    node_yoffs = node_yoffs+    DATA.GUI.custom_node_nameh   
    DATA.GUI.buttons[basekey..'lfo.speed'] = { 
                          knob_a = txt_a/2,
                          knob_isknob = true,
                          knob_showvalueright = true,
                          val_res=DATA.GUI.custom_val_res,
                          x=xoffs,
                          y=node_yoffs,
                          hide = node_yoffs<DATA.GUI.custom_infoh,
                          ignoremouse = node_yoffs<DATA.GUI.custom_infoh,
                          w=DATA.GUI.custom_base_wsingle-1,
                          h=DATA.GUI.custom_node_nameh-1,
                          txt = 'Speed',
                          txt_a = txt_a,
                          frame_a = 0,
                          frame_asel = 0,
                          txt_fontsz = DATA.GUI.custom_txtsz_ctrl,
                          val = ctrl_t.PMOD['lfo.speed']/maxspeedHz,
                          val_min=0,
                          val_max=1,
                          --backgr_fill = 0,
                          onmousedrag =   function() 
                                            DATA2.ONPARAMDRAG = true
                                            ctrl_t.PMOD['lfo.speed']=DATA.GUI.buttons[basekey..'lfo.speed'].val*maxspeedHz
                                            DATA.GUI.buttons[basekey..'lfo.speed'].refresh = true
                                            DATA2:ApplyPMOD(ctrl_key) 
                                          end,
                          onmouserelease =function()
                                            DATA2.ONPARAMDRAG = false
                                            ctrl_t.PMOD['lfo.speed']=DATA.GUI.buttons[basekey..'lfo.speed'].val*maxspeedHz
                                            DATA.GUI.buttons[basekey..'lfo.speed'].refresh = true
                                            DATA2:ApplyPMOD(ctrl_key)
                                          end,
                          } 
    
                         
    xoffs = xoffs + DATA.GUI.custom_base_wsingle                      
    DATA.GUI.buttons[basekey..'lfo.phase'] = { 
                          knob_a = txt_a/2,
                          knob_isknob = true,
                          knob_showvalueright = true,
                          val_res=DATA.GUI.custom_val_res,
                          x=xoffs,
                          y=node_yoffs,
                          hide = node_yoffs<DATA.GUI.custom_infoh,
                          ignoremouse = node_yoffs<DATA.GUI.custom_infoh,
                          w=DATA.GUI.custom_base_wsingle-1,
                          h=DATA.GUI.custom_node_nameh-1,
                          txt = 'Phase',
                          txt_a = txt_a,
                          frame_a = 0,
                          frame_asel = 0,
                          txt_fontsz = DATA.GUI.custom_txtsz_ctrl,
                          val = ctrl_t.PMOD['lfo.phase'],
                          --backgr_fill = 0,
                          onmousedrag =   function() 
                                            DATA2.ONPARAMDRAG = true
                                            ctrl_t.PMOD['lfo.phase']=DATA.GUI.buttons[basekey..'lfo.phase'].val
                                            DATA.GUI.buttons[basekey..'lfo.phase'].refresh = true
                                            DATA2:ApplyPMOD(ctrl_key) 
                                          end,
                          onmouserelease =function()
                                            DATA2.ONPARAMDRAG = false
                                            ctrl_t.PMOD['lfo.phase']=DATA.GUI.buttons[basekey..'lfo.phase'].val
                                            DATA.GUI.buttons[basekey..'lfo.phase'].refresh = true
                                            DATA2:ApplyPMOD(ctrl_key)
                                          end,
                          }                        
  end    
  ---------------------------------------------------node_yoffs------------------
  function GUI_nodes_04link(DATA, ctrl_t,  node_yoffs) 
    local ctrl_key = ctrl_t.ctrl_key
    local basekey = 'ctrl_'..ctrl_key..'plink'
    local xoffs = DATA.GUI.custom_node_x                     
    local txt_a = DATA.GUI.custom_txta_OFF  if ctrl_t.PMOD['plink.active']&1==1 then txt_a = DATA.GUI.custom_txta_ON end
    DATA.GUI.buttons[basekey..'plinkactive'] = { 
    
                          x=xoffs,
                          y=node_yoffs,
                          hide = node_yoffs<DATA.GUI.custom_infoh,
                          ignoremouse = node_yoffs<DATA.GUI.custom_infoh,
                          w=DATA.GUI.custom_base_wsingle-1,
                          h=DATA.GUI.custom_node_nameh-1,
                          txt = 'Link',
                          txt_a = txt_a,
                          frame_a = 0,
                          frame_asel = 0,
                          txt_fontsz = DATA.GUI.custom_txtsz_ctrl,
                          onmouserelease = function() 
                            ctrl_t.PMOD['plink.active']=ctrl_t.PMOD['plink.active']~1 DATA2:ApplyPMOD(ctrl_key)   
                            GUI_nodes_init(DATA)
                          end
                          }  
                           
    if ctrl_t.PMOD['plink.active']&1==0 then return end  
    --node_yoffs = node_yoffs +    DATA.GUI.custom_node_nameh     
    xoffs = xoffs + DATA.GUI.custom_base_wsingle
    local txt_a = DATA.GUI.custom_txta_OFF  if ctrl_t.PMOD['plink.active']&1==1 then txt_a = DATA.GUI.custom_txta_ON end
    DATA.GUI.buttons[basekey..'plink.offset'] = { 
                          knob_a = txt_a/2,
                          knob_isknob = true,
                          knob_showvalueright = true,
                          val_res=DATA.GUI.custom_val_res,
                          x=xoffs,
                          y=node_yoffs,
                          hide = node_yoffs<DATA.GUI.custom_infoh,
                          ignoremouse = node_yoffs<DATA.GUI.custom_infoh,
                          w=DATA.GUI.custom_base_wsingle-1,
                          h=DATA.GUI.custom_node_nameh-1,
                          txt = 'Offset',
                          txt_a = txt_a,
                          --frame_a = 0,
                          txt_fontsz = DATA.GUI.custom_txtsz_ctrl,
                          val = ctrl_t.PMOD['plink.offset'],
                          val_min=0,
                          val_max=1,
                          frame_a=0,
                          frame_asel=0,
                          onmousedrag =   function() 
                                            DATA2.ONPARAMDRAG = true
                                            ctrl_t.PMOD['plink.offset']=DATA.GUI.buttons[basekey..'plink.offset'].val
                                            DATA.GUI.buttons[basekey..'plink.offset'].refresh = true
                                            DATA2:ApplyPMOD(ctrl_key) 
                                          end,
                          onmouserelease =function()
                                            DATA2.ONPARAMDRAG = false
                                            ctrl_t.PMOD['plink.offset']=DATA.GUI.buttons[basekey..'plink.offset'].val
                                            DATA.GUI.buttons[basekey..'plink.offset'].refresh = true
                                            DATA2:ApplyPMOD(ctrl_key)
                                          end,
                          } 
                          
    xoffs = xoffs + DATA.GUI.custom_base_wsingle
    DATA.GUI.buttons[basekey..'plink.scale'] = { 
                          knob_a = txt_a/2,
                          knob_isknob = true,
                          knob_showvalueright = true,
                          val_res=DATA.GUI.custom_val_res,
                          x=xoffs,
                          y=node_yoffs,--+DATA.GUI.custom_node_nameh,
                          hide = node_yoffs<DATA.GUI.custom_infoh,
                          ignoremouse = node_yoffs<DATA.GUI.custom_infoh,
                          w=DATA.GUI.custom_base_wsingle-1,
                          h=DATA.GUI.custom_node_nameh-1,
                          txt = 'Scale',
                          txt_a = txt_a,
                          frame_a=0,
                          frame_asel=0,
                          txt_fontsz = DATA.GUI.custom_txtsz_ctrl,
                          val = ctrl_t.PMOD['plink.scale'],
                          onmousedrag =   function() 
                                            DATA2.ONPARAMDRAG = true
                                            ctrl_t.PMOD['plink.scale']=DATA.GUI.buttons[basekey..'plink.scale'].val
                                            DATA.GUI.buttons[basekey..'plink.scale'].refresh = true
                                            DATA2:ApplyPMOD(ctrl_key) 
                                          end,
                          onmouserelease =function()
                                            DATA2.ONPARAMDRAG = false
                                            ctrl_t.PMOD['plink.scale']=DATA.GUI.buttons[basekey..'plink.scale'].val
                                            DATA.GUI.buttons[basekey..'plink.scale'].refresh = true
                                            DATA2:ApplyPMOD(ctrl_key)
                                          end,
                          } 
    xoffs = DATA.GUI.custom_base_wsingle + DATA.GUI.custom_node_x 
    node_yoffs = node_yoffs +    DATA.GUI.custom_node_nameh     
    
    -- fx name
      local txt = 'Add last touched'
      if ctrl_t.PMOD['plink.effect'] >=0 then
        local tr = VF_GetMediaTrackByGUID(0,ctrl_t.trGUID)
        if tr then
          local retval, fxname = TrackFX_GetFXName( tr, ctrl_t.PMOD['plink.effect'] )
          local retval, paramname = TrackFX_GetParamName( tr, ctrl_t.PMOD['plink.effect'], ctrl_t.PMOD['plink.param'] )
          txt =  'from: '..VF_ReduceFXname(fxname)..' / '..paramname
        end
      end
    DATA.GUI.buttons[basekey..'plink.add'] = { 
                          x=xoffs,
                          y=node_yoffs,--+DATA.GUI.custom_node_nameh,
                          hide = node_yoffs<DATA.GUI.custom_infoh,
                          ignoremouse = node_yoffs<DATA.GUI.custom_infoh,
                          w=DATA.GUI.custom_base_wsingle*3,
                          h=DATA.GUI.custom_node_nameh-1,
                          txt = txt,
                          txt_a = txt_a,
                          txt_flags = 4,
                          frame_a=0,
                          --frame_asel=0,
                          txt_fontsz = DATA.GUI.custom_txtsz_ctrl,
                          onmouserelease =function()
                                            local retval, trackidx, itemidx, takeidx, fxidx, parm = reaper.GetTouchedOrFocusedFX(0)
                                            if not retval then return end
                                            if itemidx>=0 or takeidx>=0 then return end
                                            
                                            local track = GetTrack(0,trackidx)
                                            if trackidx == -1 then track = GetMasterTrack(0) end
                                            if ctrl_t.trGUID ~=  GetTrackGUID( track ) then return end
                                            
                                            ctrl_t.PMOD['plink.effect']=fxidx
                                            ctrl_t.PMOD['plink.param']=parm
                                            DATA2:ApplyPMOD(ctrl_key)
                                          end,
                          }                           
  end    
  ----------------------------------------------------------------------
  function GUI_nodes_05acs(DATA, ctrl_t,  node_yoffs)  
    local ctrl_key = ctrl_t.ctrl_key
    local basekey = 'ctrl_'..ctrl_key..'acs'
    local xoffs = DATA.GUI.custom_node_x
    local max_ar_ms = 1000
    
    local txt_a = DATA.GUI.custom_txta_OFF  if ctrl_t.PMOD['acs.active']&1==1 then txt_a = DATA.GUI.custom_txta_ON end
    DATA.GUI.buttons[basekey..'acsactive'] = { x=xoffs,
                          y=node_yoffs,
                          hide = node_yoffs<DATA.GUI.custom_infoh,
                          ignoremouse = node_yoffs<DATA.GUI.custom_infoh,
                          w=DATA.GUI.custom_base_wsingle-1,
                          h=DATA.GUI.custom_node_nameh-1,
                          txt = 'Audio',
                          txt_a = txt_a,
                          frame_a = 0,
                          frame_asel = 0,
                          txt_fontsz = DATA.GUI.custom_txtsz_ctrl,
                          onmouserelease = function() 
                            ctrl_t.PMOD['acs.active']=ctrl_t.PMOD['acs.active']~1 DATA2:ApplyPMOD(ctrl_key)   
                            GUI_nodes_init(DATA)
                          end
                          } 
    if ctrl_t.PMOD['acs.active']&1==0 then return end  
    
    xoffs = DATA.GUI.custom_node_x + DATA.GUI.custom_base_wsingle                      
    DATA.GUI.buttons[basekey..'acs.strength'] = { 
                          knob_a = txt_a/2,
                          knob_isknob = true,
                          knob_showvalueright = true,
                          val_res=DATA.GUI.custom_val_res,
                          x=xoffs,
                          y=node_yoffs,
                          hide = node_yoffs<DATA.GUI.custom_infoh,
                          ignoremouse = node_yoffs<DATA.GUI.custom_infoh,
                          w=DATA.GUI.custom_base_wsingle-1,
                          h=DATA.GUI.custom_node_nameh-1,
                          txt = 'Strength',
                          txt_a = txt_a,
                          frame_a = 0,
                          frame_asel = 0,
                          txt_fontsz = DATA.GUI.custom_txtsz_ctrl,
                          val = ctrl_t.PMOD['acs.strength'],
                          --backgr_fill = 0,
                          onmousedrag =   function() 
                                            DATA2.ONPARAMDRAG = true
                                            ctrl_t.PMOD['acs.strength']=DATA.GUI.buttons[basekey..'acs.strength'].val
                                            DATA.GUI.buttons[basekey..'acs.strength'].refresh = true
                                            DATA2:ApplyPMOD(ctrl_key) 
                                          end,
                          onmouserelease =function()
                                            DATA2.ONPARAMDRAG = false
                                            ctrl_t.PMOD['acs.strength']=DATA.GUI.buttons[basekey..'acs.strength'].val
                                            DATA.GUI.buttons[basekey..'acs.strength'].refresh = true
                                            DATA2:ApplyPMOD(ctrl_key)
                                          end,
                          } 
                          
    if ctrl_t.PMOD['acs.active'] == 0 then return end
    xoffs = xoffs + DATA.GUI.custom_base_wsingle --DATA.GUI.custom_node_x
    --node_yoffs = node_yoffs + DATA.GUI.custom_node_nameh
    DATA.GUI.buttons[basekey..'acs.attack'] = { 
                          knob_a = txt_a/2,
                          knob_isknob = true,
                          knob_showvalueright = true,
                          val_res=DATA.GUI.custom_val_res,
                          x=xoffs,
                          y=node_yoffs,
                          hide = node_yoffs<DATA.GUI.custom_infoh,
                          ignoremouse = node_yoffs<DATA.GUI.custom_infoh,
                          w=DATA.GUI.custom_base_wsingle-1,
                          h=DATA.GUI.custom_node_nameh-1,
                          txt = 'Attack',
                          txt_a = txt_a,
                          frame_a = 0,
                          frame_asel = 0,
                          txt_fontsz = DATA.GUI.custom_txtsz_ctrl,
                          val = ctrl_t.PMOD['acs.attack']/max_ar_ms,
                          onmousedrag =   function() 
                                            DATA2.ONPARAMDRAG = true
                                            ctrl_t.PMOD['acs.attack']=DATA.GUI.buttons[basekey..'acs.attack'].val*max_ar_ms
                                            DATA.GUI.buttons[basekey..'acs.attack'].refresh = true
                                            DATA2:ApplyPMOD(ctrl_key) 
                                          end,
                          onmouserelease =function()
                                            DATA2.ONPARAMDRAG = false
                                            ctrl_t.PMOD['acs.attack']=DATA.GUI.buttons[basekey..'acs.attack'].val*max_ar_ms
                                            DATA.GUI.buttons[basekey..'acs.attack'].refresh = true
                                            DATA2:ApplyPMOD(ctrl_key)
                                          end,
                          } 
                          
    xoffs = xoffs + DATA.GUI.custom_base_wsingle
    DATA.GUI.buttons[basekey..'acs.release'] = { 
                          knob_a = txt_a/2,
                          knob_isknob = true,
                          knob_showvalueright = true,
                          val_res=DATA.GUI.custom_val_res,
                          x=xoffs,
                          y=node_yoffs,
                          hide = node_yoffs<DATA.GUI.custom_infoh,
                          ignoremouse = node_yoffs<DATA.GUI.custom_infoh,
                          w=DATA.GUI.custom_base_wsingle-1,
                          h=DATA.GUI.custom_node_nameh-1,
                          txt = 'Release',
                          txt_a = txt_a,
                          frame_a = 0,
                          frame_asel = 0,
                          txt_fontsz = DATA.GUI.custom_txtsz_ctrl,
                          val = ctrl_t.PMOD['acs.release']/max_ar_ms,
                          onmousedrag =   function() 
                                            DATA2.ONPARAMDRAG = true
                                            ctrl_t.PMOD['acs.release']=DATA.GUI.buttons[basekey..'acs.release'].val*max_ar_ms
                                            DATA.GUI.buttons[basekey..'acs.release'].refresh = true
                                            DATA2:ApplyPMOD(ctrl_key) 
                                          end,
                          onmouserelease =function()
                                            DATA2.ONPARAMDRAG = false
                                            ctrl_t.PMOD['acs.release']=DATA.GUI.buttons[basekey..'acs.release'].val*max_ar_ms
                                            DATA.GUI.buttons[basekey..'acs.release'].refresh = true
                                            DATA2:ApplyPMOD(ctrl_key)
                                          end,
                          } 
                          
    xoffs = DATA.GUI.custom_base_wsingle +DATA.GUI.custom_node_x
    node_yoffs = node_yoffs + DATA.GUI.custom_node_nameh
    --xoffs = xoffs + DATA.GUI.custom_base_wsingle
    DATA.GUI.buttons[basekey..'acs.dblo'] = { 
                          knob_a = txt_a/2,
                          knob_isknob = true,
                          knob_showvalueright = true,
                          val_res=DATA.GUI.custom_val_res,
                          x=xoffs,
                          y=node_yoffs,
                          hide = node_yoffs<DATA.GUI.custom_infoh,
                          ignoremouse = node_yoffs<DATA.GUI.custom_infoh,
                          w=DATA.GUI.custom_base_wsingle-1,
                          h=DATA.GUI.custom_node_nameh-1,
                          txt = 'Min',
                          txt_a = txt_a,
                          frame_a = 0,
                          frame_asel = 0,
                          txt_fontsz = DATA.GUI.custom_txtsz_ctrl,
                          val = ctrl_t.PMOD['acs.dblo'],
                          val_min = -60,
                          val_max = ctrl_t.PMOD['acs.dbhi'],
                          onmousedrag =   function() 
                                            DATA2.ONPARAMDRAG = true
                                            ctrl_t.PMOD['acs.dblo']=DATA.GUI.buttons[basekey..'acs.dblo'].val
                                            DATA.GUI.buttons[basekey..'acs.dblo'].txt = math_q_dec(ctrl_t.PMOD['acs.dblo'],1)..'dB'
                                            DATA.GUI.buttons[basekey..'acs.dblo'].refresh = true
                                            DATA2:ApplyPMOD(ctrl_key) 
                                          end,
                          onmouserelease =function()
                                            DATA2.ONPARAMDRAG = false
                                            ctrl_t.PMOD['acs.dblo']=DATA.GUI.buttons[basekey..'acs.dblo'].val
                                            DATA.GUI.buttons[basekey..'acs.dblo'].txt = 'Min'
                                            DATA.GUI.buttons[basekey..'acs.dblo'].refresh = true
                                            DATA2:ApplyPMOD(ctrl_key)
                                          end,
                          } 
    xoffs = xoffs + DATA.GUI.custom_base_wsingle
    DATA.GUI.buttons[basekey..'acs.dbhi'] = { 
                          knob_a = txt_a/2,
                          knob_isknob = true,
                          knob_showvalueright = true,
                          val_res=DATA.GUI.custom_val_res,
                          x=xoffs,
                          y=node_yoffs,
                          hide = node_yoffs<DATA.GUI.custom_infoh,
                          ignoremouse = node_yoffs<DATA.GUI.custom_infoh,
                          w=DATA.GUI.custom_base_wsingle-1,
                          h=DATA.GUI.custom_node_nameh-1,
                          txt = 'Max',
                          txt_a = txt_a,
                          frame_a = 0,
                          frame_asel = 0,
                          txt_fontsz = DATA.GUI.custom_txtsz_ctrl,
                          val = ctrl_t.PMOD['acs.dbhi'],
                          val_min = ctrl_t.PMOD['acs.dblo'],
                          val_max = 12,
                          onmousedrag =   function() 
                                            DATA2.ONPARAMDRAG = true
                                            ctrl_t.PMOD['acs.dbhi']=DATA.GUI.buttons[basekey..'acs.dbhi'].val
                                            DATA.GUI.buttons[basekey..'acs.dbhi'].txt = math_q_dec(ctrl_t.PMOD['acs.dbhi'],1)..'dB'
                                            DATA.GUI.buttons[basekey..'acs.dbhi'].refresh = true
                                            DATA2:ApplyPMOD(ctrl_key) 
                                          end,
                          onmouserelease =function()
                                            DATA2.ONPARAMDRAG = false
                                            ctrl_t.PMOD['acs.dbhi']=DATA.GUI.buttons[basekey..'acs.dbhi'].val
                                            DATA.GUI.buttons[basekey..'acs.dbhi'].txt = 'Max'
                                            DATA.GUI.buttons[basekey..'acs.dbhi'].refresh = true
                                            DATA2:ApplyPMOD(ctrl_key)
                                          end,
                          }                           
  end     
  
  -----------------------------------------------------------------------------  
  function GUI_RESERVED_draw_data(DATA, b)
    local t = b.wiredata
    if not t then return end
    if t.y1 <DATA.GUI.custom_infoh or t.y2 <DATA.GUI.custom_infoh then return end
    gfx.a = 1
    DATA:GUIhex2rgb('#c0c0c0',true)
    local r = 3
    gfx.circle(t.x1,t.y1,r,1,1 )
    gfx.circle(t.x2,t.y2,r,1,1 )
    gfx.a = 0.8
    gfx.line(t.x1,t.y1, t.x2,t.y2)
  end
  ----------------------------------------------------------------------
  function GUI_nodes_init(DATA)
    for key in pairs(DATA.GUI.buttons) do if key:match('ctrl_') or key:match('mod_') then DATA.GUI.buttons[key] = nil end end
    if not DATA2.modulationstate then return end
    
    -- calc common h
      DATA.GUI.custom_gfxcomh = 0
      DATA.GUI.custom_gfxcomhcheck = DATA.GUI.custom_gfx_hreal-DATA.GUI.custom_infoh
      
      node_yoffs = 0
      for param in spairs(DATA2.modulationstate) do
        node_yoffs = node_yoffs + DATA.GUI.custom_node_nameh
        node_yoffs = node_yoffs + DATA.GUI.custom_node_nameh
        if DATA2.modulationstate[param].PMOD['mod.active'] == 1   then 
          node_yoffs = node_yoffs + DATA.GUI.custom_node_nameh 
          if DATA2.modulationstate[param].PMOD['lfo.active'] == 1   then node_yoffs = node_yoffs + DATA.GUI.custom_node_nameh end
          node_yoffs = node_yoffs + DATA.GUI.custom_node_nameh
          if DATA2.modulationstate[param].PMOD['acs.active'] == 1   then node_yoffs = node_yoffs + DATA.GUI.custom_node_nameh end
          node_yoffs = node_yoffs + DATA.GUI.custom_node_nameh
          if DATA2.modulationstate[param].PMOD['plink.active'] == 1   then node_yoffs = node_yoffs + DATA.GUI.custom_node_nameh end
        end
        node_yoffs = node_yoffs + DATA.GUI.custom_node_voffset 
      end
      DATA.GUI.custom_gfxcomh = node_yoffs
      
      --[[for param in spairs(DATA2.modulationstate) do
        DATA.GUI.custom_gfxcomh =DATA.GUI.custom_gfxcomh + DATA.GUI.custom_node_nameh + DATA.GUI.custom_node_voffset 
        if DATA2.modulationstate[param].PMOD then 
          DATA.GUI.custom_gfxcomh = DATA.GUI.custom_gfxcomh + DATA.GUI.custom_node_nameh*6
          if DATA2.modulationstate[param].PMOD['mod.active'] == 1   then 
            if DATA2.modulationstate[param].PMOD['lfo.active'] == 1 then DATA.GUI.custom_gfxcomh = DATA.GUI.custom_gfxcomh + DATA.GUI.custom_node_nameh end
            if DATA2.modulationstate[param].PMOD['plink.active'] == 1 then DATA.GUI.custom_gfxcomh = DATA.GUI.custom_gfxcomh + DATA.GUI.custom_node_nameh end
            if DATA2.modulationstate[param].PMOD['acs.active'] == 1 then DATA.GUI.custom_gfxcomh = DATA.GUI.custom_gfxcomh + DATA.GUI.custom_node_nameh end
           else
            DATA.GUI.custom_gfxcomh = DATA.GUI.custom_gfxcomh + DATA.GUI.custom_node_nameh
          end
        end
      end]]
      --DATA.GUI.custom_gfxcomh =math.max(DATA.GUI.custom_gfxcomh-DATA.GUI.custom_infoh - DATA.GUI.custom_node_areah,DATA.GUI.custom_gfx_hreal)
      --DATA.GUI.custom_gfxcomh =DATA.GUI.custom_gfxcomh - DATA.GUI.custom_node_areah---DATA.GUI.custom_infoh
      
    -- draw
      
      DATA.GUI.custom_gfxcomh_used =DATA.GUI.custom_gfxcomh - (DATA.GUI.custom_gfx_hreal-DATA.GUI.custom_node_nameh)
      local node_yoffs = (DATA2.scroll_list or 0) * (1-DATA.GUI.custom_gfxcomh_used) + DATA.GUI.custom_infoh 
      if DATA.GUI.custom_gfxcomh < DATA.GUI.custom_gfxcomhcheck then 
        node_yoffs = DATA.GUI.custom_infoh 
        DATA.GUI.custom_scroll_off = true 
       else 
        DATA.GUI.custom_scroll_off = false 
      end
      
      for param in spairs(DATA2.modulationstate) do
        GUI_nodes_01parameter(DATA, DATA2.modulationstate[param], node_yoffs) node_yoffs = node_yoffs + DATA.GUI.custom_node_nameh
        GUI_nodes_02base(DATA, DATA2.modulationstate[param], node_yoffs) node_yoffs = node_yoffs + DATA.GUI.custom_node_nameh
        if DATA2.modulationstate[param].PMOD['mod.active'] == 1   then 
          GUI_nodes_03lfo(DATA, DATA2.modulationstate[param], node_yoffs) node_yoffs = node_yoffs + DATA.GUI.custom_node_nameh 
          if DATA2.modulationstate[param].PMOD['lfo.active'] == 1   then node_yoffs = node_yoffs + DATA.GUI.custom_node_nameh end
          GUI_nodes_05acs(DATA, DATA2.modulationstate[param], node_yoffs) node_yoffs = node_yoffs + DATA.GUI.custom_node_nameh
          if DATA2.modulationstate[param].PMOD['acs.active'] == 1   then node_yoffs = node_yoffs + DATA.GUI.custom_node_nameh end
          GUI_nodes_04link(DATA, DATA2.modulationstate[param], node_yoffs)  node_yoffs = node_yoffs + DATA.GUI.custom_node_nameh
          if DATA2.modulationstate[param].PMOD['plink.active'] == 1   then node_yoffs = node_yoffs + DATA.GUI.custom_node_nameh end
        end
        node_yoffs = node_yoffs + DATA.GUI.custom_node_voffset 
      end
  end
  ----------------------------------------------------------------------
  function DATA_RESERVED_ONPROJCHANGE(DATA)
    DATA2:CollectProjectData()
    GUI_nodes_init(DATA)
  end
  --------------------------------------------------------------------- 
  function GUI_header_info(DATA)
    DATA.GUI.buttons.actions = { x=0,
                        y=0,
                        w=DATA.GUI.custom_gfx_wreal-1,
                        h=DATA.GUI.custom_infoh,
                        frame_a = 0,
                        frame_asel = 0,
                        
                        txt = 'Actions / Options',
                        txt_fontsz=DATA.GUI.custom_info_txtsz,
                        onmouserelease = function() 
                          DATA:GUImenu(
                          {
                            { str = '#Actions'},
                            { str = 'Enable modulation for last touched parameter', func= function() DATA2:Action_ActiveteLastTouchedParam() end} ,
                            { str = 'Deactivate all modulation for selected track', func = function() DATA2:Action_CleanSelectedTracksMod()  end} ,
                            {str='Dock', func =           function()  DATA2:Action_Dock()   end },
                            { str = '|#Filter'},
                            { str = 'No filter',
                              state =  DATA.extstate.CONF_filtermode ==0 ,
                              func = function()  
                                DATA.extstate.CONF_filtermode =0 
                                DATA_RESERVED_ONPROJCHANGE(DATA)
                                DATA.UPD.onconfchange = true
                              end
                            } ,
                            { str = 'Selected track',
                              state =  DATA.extstate.CONF_filtermode ==1 ,
                              func = function()  
                                DATA.extstate.CONF_filtermode =1 
                                DATA_RESERVED_ONPROJCHANGE(DATA)
                                DATA.UPD.onconfchange = true
                              end
                            }  ,
                            { str = 'Focused FX',
                              state =  DATA.extstate.CONF_filtermode == 2,
                              func = function()  
                                DATA.extstate.CONF_filtermode = 2
                                DATA_RESERVED_ONPROJCHANGE(DATA)
                                DATA.UPD.onconfchange = true
                              end
                            },        
                         
                            
                          })
                                    
                        end
                        }
    
  end
  --------------------------------------------------------------------- 
  function GUI_RESERVED_init(DATA)
    -- shortcuts
      DATA.GUI.shortcuts[32] = function() VF_Action(40044) end -- space to transport play 
      if not DATA.GUI.buttons then DATA.GUI.buttons = {}  end
      
    -- get globals
      DATA.GUI.custom_gfx_hreal = math.floor(gfx.h/DATA.GUI.default_scale)
      DATA.GUI.custom_gfx_wreal = math.floor(gfx.w/DATA.GUI.default_scale)
      DATA.GUI.custom_reference = 360
      DATA.GUI.custom_Xrelation = 1--VF_lim(DATA.GUI.custom_gfx_wreal/DATA.GUI.custom_reference, 0.1, 8) -- global W
      DATA.GUI.custom_offset =  math.floor(3 * DATA.GUI.custom_Xrelation)
      
      
      DATA.GUI.custom_infoh =  math.floor(40 * DATA.GUI.custom_Xrelation)
      DATA.GUI.custom_info_txtsz= math.floor(21* DATA.GUI.custom_Xrelation)
      DATA.GUI.custom_scrollw =  math.floor(10 * DATA.GUI.custom_Xrelation)
      
    -- nodes
      DATA.GUI.custom_node_x = DATA.GUI.custom_offset
      DATA.GUI.custom_node_w = DATA.GUI.custom_gfx_wreal - DATA.GUI.custom_scrollw-DATA.GUI.custom_offset*4
      DATA.GUI.custom_nodes_area_w = DATA.GUI.custom_gfx_wreal - DATA.GUI.custom_scrollw-DATA.GUI.custom_offset*2
      DATA.GUI.custom_node_areah = math.floor(90*DATA.GUI.custom_Xrelation)
      DATA.GUI.custom_node_removew = math.floor(20*DATA.GUI.custom_Xrelation) 
      DATA.GUI.custom_val_res = 0.1 
      DATA.GUI.custom_node_voffset =  math.floor(10 * DATA.GUI.custom_Xrelation)
    -- ctrls
      DATA.GUI.custom_txtsz_ctrl= math.floor(15* DATA.GUI.custom_Xrelation)
      DATA.GUI.custom_txta_OFF = 0.3
      DATA.GUI.custom_txta_ON = 1
      DATA.GUI.custom_backgr_fill2 = 0.2
      DATA.GUI.custom_backgr_col2 =0xFFFFFF
    -- name 
      DATA.GUI.custom_node_nameh = math.floor(30*DATA.GUI.custom_Xrelation)
      DATA.GUI.custom_nodeparam_txtsz= math.floor(16* DATA.GUI.custom_Xrelation)  
    -- base
      DATA.GUI.custom_base_wsingle= math.floor(DATA.GUI.custom_nodes_area_w/4)-1
      
      
    --[[ param node
      DATA.GUI.custom_nodeparam_areaw = math.floor(DATA.GUI.custom_nodes_area_w*0.25)   
      DATA.GUI.custom_nodeparam_w= math.floor(DATA.GUI.custom_nodeparam_areaw*0.9)
      DATA.GUI.custom_nodeparam_h= math.floor(DATA.GUI.custom_node_areah*0.6)
    -- info node
      DATA.GUI.custom_nodectrlblock_areaw = DATA.GUI.custom_nodes_area_w -  DATA.GUI.custom_nodeparam_areaw
      
      DATA.GUI.custom_nodectrlblock_w= math.floor(DATA.GUI.custom_nodectrlblock_areaw*0.9)
      DATA.GUI.custom_nodectrlblock_h= math.floor(DATA.GUI.custom_node_areah*0.9)
    
      DATA.GUI.custom_knob_buttonarea_w = math.floor(DATA.GUI.custom_nodectrlblock_h * 0.9)
      DATA.GUI.custom_knob_button_w = math.floor(DATA.GUI.custom_knob_buttonarea_w * 0.9)
      DATA.GUI.custom_knob_button_h= math.floor(DATA.GUI.custom_nodectrlblock_h*0.9)
      DATA.GUI.custom_knob_readout_h = math.floor(DATA.GUI.custom_nodectrlblock_h*0.2 )   
      ]]
    GUI_header_info(DATA)
    
    -- scroll
      local xscroll = math.floor(DATA.GUI.custom_gfx_wreal-DATA.GUI.custom_scrollw-DATA.GUI.custom_offset*2)
      local yscroll = math.floor(DATA.GUI.custom_offset+DATA.GUI.custom_infoh)
      DATA.GUI.buttons.scroll = { x=xscroll,
                          y=yscroll,
                          w=DATA.GUI.custom_scrollw,
                          h=DATA.GUI.custom_gfx_hreal-DATA.GUI.custom_offset*2-DATA.GUI.custom_infoh,
                          backgr_fill =  0.1,
                          frame_a = 0,
                          frame_asel = 0.1,
                          val = 0,
                          val_res = -1,
                          slider_isslider = true,
                          onmousedrag = function() 
                            if DATA.GUI.custom_scroll_off == true then return end
                            DATA2.scroll_list = DATA.GUI.buttons.scroll.val 
                            DATA.GUI.buttons.scroll.refresh = true
                            GUI_nodes_init(DATA)
                          end,
                          onmouserelease = function()  
                            if DATA.GUI.custom_scroll_off == true then return end
                            DATA.GUI.buttons.scroll.refresh = true
                          end
                          }
    GUI_nodes_init(DATA)                    
    for but in pairs(DATA.GUI.buttons) do DATA.GUI.buttons[but].key = but end
  end 
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.63) if ret then local ret2 = VF_CheckReaperVrs(6.71,true) if ret2 then main() end end