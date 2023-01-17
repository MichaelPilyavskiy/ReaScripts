-- @description ModulationEditor
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init



 
  -- NOT gfx NOT reaper NOT VF NOT GUI NOT DATA NOT MAIN 
  
  DATA2 = { 
          }
  ---------------------------------------------------------------------  
  function main()  
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.version = '1.0'
    DATA.extstate.extstatesection = 'MPL_ModulationEditor'
    DATA.extstate.mb_title = 'ModulationEditor'
    DATA.extstate.default = 
                          {  
                          wind_x =  100,
                          wind_y =  100,
                          wind_w =  800,
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
  --[[--------------------------------------------------------------------
  function DATA2:ImportCSV()
    local retval, xml = reaper.GetUserFileNameForRead('', 'ModulationEditor mapping', '.xml' )
    
    if not (xml and xml ~= '' ) then return end
    local f = io.open(xml, 'rb')
    local content
    if f then 
      content = f:read('a')
      f:close()
     else
      return
    end 
    if not content then return end
    
    -- parse xml
    for control in content:gmatch('(<control.-<%/control>)') do
      local ctrl_type = control:match('<ctrl_type>(.-)<%/ctrl_type>')
      local ctrl_key = control:match('<ctrl_key>(.-)<%/ctrl_key>')
      for link in control:gmatch('(<link.-<%/link>)') do
        local fxGUID = link:match('<fxGUID>(.-)<%/fxGUID>')
        local pid = link:match('<param>(.-)<%/param>')
        local mode = link:match('<mode>(.-)<%/mode>')
        local flags = link:match('<flags>(.-)<%/flags>')
        local ret,track,fx = VF_GetFXByGUID(fxGUID)
        if ret then
          if tonumber(ctrl_type) == 0 then
            local midi_int = tonumber(ctrl_key)
            TrackFX_SetNamedConfigParm( track, fx, 'param.'..pid..'.learn.midi1',midi_int&0xFF )
            TrackFX_SetNamedConfigParm( track, fx, 'param.'..pid..'.learn.midi2',(midi_int&0xFF00)>>8 )
           elseif tonumber(ctrl_type) == 1 then 
            TrackFX_SetNamedConfigParm( track, fx, 'param.'..pid..'.learn.osc',ctrl_key )
          end
          TrackFX_SetNamedConfigParm( track, fx, 'param.'..pid..'.learn.mode',mode )
          TrackFX_SetNamedConfigParm( track, fx, 'param.'..pid..'.learn.flags',flags ) 
        end
      end
    end
  end
  ----------------------------------------------------------------------
  function DATA2:ExportCSV()
    local out_fp =GetProjectPath()..'/ModulationEditor_mapping.xml'
    if not DATA2.modulationstate then return end
    
    local str = ''
    for control in pairs(DATA2.modulationstate) do
      str=str..'\n<control id="'..control..'">'
      str=str..'\n  <ctrl_type>'..DATA2.modulationstate[control].ctrl_type..'</ctrl_type>'
      str=str..'\n  <ctrl_key>'..DATA2.modulationstate[control].ctrl_key..'</ctrl_key>'
      for link = 1, #DATA2.modulationstate[control] do
        str=str..'\n  <link linkid="'..link..'">'
        str=str..'\n    <trGUID>'..DATA2.modulationstate[control][link].trGUID..'</trGUID>'
        str=str..'\n    <fxGUID>'..DATA2.modulationstate[control][link].fxGUID..'</fxGUID>'
        str=str..'\n    <flags>'..DATA2.modulationstate[control][link].flags..'</flags>'
        str=str..'\n    <mode>'..DATA2.modulationstate[control][link].mode..'</mode>'
        str=str..'\n    <param>'..DATA2.modulationstate[control][link].param..'</param>'
        str=str..'\n  </link>'
      end
      str=str..'\n</control>'
    end
    
    str=str..'\n<ModulationEditor_vrs>'..DATA.extstate.version..'</ModulationEditor_vrs>'
    str=str..'\n<ts>'..os.date()..'</ts>'
    
    local f = io.open(out_fp,'wb')
    if f then 
      f:write(str)
      f:close()
    end
    MB('Export successfully to '..out_fp,DATA.extstate.mb_title,0)
  end]]
  ----------------------------------------------------------------------
  function DATA_RESERVED_DYNUPDATE()
    
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
  function GUI_nodes_01parameter(DATA, ctrl_t, node_y_offs0)  
    local ctrl_key = ctrl_t.ctrl_key
    local node_x_offs = math.floor(DATA.GUI.custom_nodeparam_areaw/2-DATA.GUI.custom_nodeparam_w/2)
    local node_y_offs = node_y_offs0 + math.floor(DATA.GUI.custom_node_areah/2-DATA.GUI.custom_nodeparam_h/2)
    local node_w = DATA.GUI.custom_nodeparam_areaw
    local node_h = DATA.GUI.custom_node_areah
    
    local infotxt = 
     ctrl_t.trname..'\n'..
     ctrl_t.fxname_short..'\n'..
     ctrl_t.pname
     
    local infotxt0 = infotxt
    local alias_ctrlkey = ctrl_t.fxname_short..'_'..ctrl_t.pname
    if DATA2.aliasmap[alias_ctrlkey] then infotxt0 = DATA2.aliasmap[alias_ctrlkey]..'\n'..infotxt end
    DATA.GUI.buttons['ctrl_'..ctrl_key] = { x=node_x_offs,
                          y=node_y_offs,
                          w=DATA.GUI.custom_nodeparam_w-1,
                          h=DATA.GUI.custom_nodeparam_h-1,
                          txt = infotxt0,
                          txt_fontsz = DATA.GUI.custom_nodeparam_txtsz,
                          onmouseclick =   function()  end,
                          hide = node_y_offs<DATA.GUI.custom_infoh,
                          refresh= true,
                          onmouserelease = function()
                            local retval, retvals_csv = GetUserInputs( 'Alias', 1, ctrl_t.pname, DATA2.aliasmap[alias_ctrlkey] or '' )
                            if retval then
                              DATA2.aliasmap[alias_ctrlkey]=retvals_csv
                              DATA2:RefreshAliasMap()
                              DATA_RESERVED_ONPROJCHANGE(DATA)
                            end
                          end
                          }
    return node_y_offs + DATA.GUI.custom_node_areah
  end
  ---------------------------------------------------------------------- 
  function GUI_CTRL(DATA, params_t) 
    local t = params_t
    local src_t = t.ctrlval_src_t 
    if not (src_t and t.ctrlval_key and src_t[t.ctrlval_key]) then return end
    -- frame
    local function format_val() 
      if t.ctrlval_format then 
        return t.ctrlval_format(src_t[t.ctrlval_key] )
       else
        return src_t[t.ctrlval_key] 
      end 
    end
    DATA.GUI.buttons[t.butkey..'frame'] = { x= t.x,
                        y=t.y ,
                        w=t.w,
                        h=t.h,
                        --ignoremouse = true,
                        hide = t.y<DATA.GUI.custom_infoh,
                        frame_a =t.frame_a or DATA.GUI.custom_framea,
                        --frame_col = '#333333',
                        backgr_col = '#333333',
                        backgr_fill = 1,
                        back_sela = 0,
                        txt='',
                        frame_arcborder = true,
                        frame_arcborderr = math.floor(DATA.GUI.custom_offset*2),
                        frame_arcborderflags = t.frame_arcborderflags or 1|2|4|8,
                        val = src_t[t.ctrlval_key],
                        
                        val_res = t.ctrlval_res,
                        val_min = t.ctrlval_min,
                        val_max = t.ctrlval_max,
                        onmousedrag = function()
                          if t.ctrlval_istoggle== true then return end
                          params_t.func_app()
                          DATA.GUI.buttons[t.butkey..'val'].txt = format_val()
                          local val_norm = src_t[t.ctrlval_key] 
                          if t.ctrlval_max and t.ctrlval_min then val_norm = (val_norm - t.ctrlval_min) / (t.ctrlval_max - t.ctrlval_min) end
                          if DATA.GUI.buttons[t.butkey..'knob'] then DATA.GUI.buttons[t.butkey..'knob'].val = val_norm end
                        end,
                        
                        
                        --[[
                        onmouseclick = function() 
                                          if not (t.butkey and DATA.GUI.buttons[t.butkey..'frame'] and DATA.GUI.buttons[t.butkey..'frame'].val) then return end
                                          local new_val = DATA.GUI.buttons[t.butkey..'frame'].val
                                          if params_t.func_atclick then params_t.func_atclick(new_val) end
                                        end,
                                        
                        onmousedrag = function()
                              DATA2.ONPARAMDRAG = true
                              if not (t.butkey and DATA.GUI.buttons[t.butkey..'frame'] and DATA.GUI.buttons[t.butkey..'frame'].val) then return end
                              local new_val = DATA.GUI.buttons[t.butkey..'frame'].val
                              params_t.func_app(new_val)
                              --params_t.func_refresh()
                              DATA.GUI.buttons[t.butkey..'val'].txt = src_t[t.ctrlval_format_key]
                                local val_norm = src_t[t.ctrlval_key] 
                                if t.ctrlval_max and t.ctrlval_min then val_norm = (val_norm - t.ctrlval_min) / (t.ctrlval_max - t.ctrlval_min) end
                                if DATA.GUI.buttons[t.butkey..'knob'] then DATA.GUI.buttons[t.butkey..'knob'].val = val_norm end
                              DATA.GUI.buttons[t.butkey..'val'].refresh = true
                            end,
                        onmousedoubleclick = function() 
                                if not t.ctrlval_default then return end
                                params_t.func_app(t.ctrlval_default)
                                --params_t.func_refresh()
                                if not (t.butkey and DATA.GUI.buttons[t.butkey..'val'] and DATA.GUI.buttons[t.butkey..'val'].txt) then return end
                                DATA.GUI.buttons[t.butkey..'val'].txt = src_t[t.ctrlval_format_key]
                                DATA.GUI.buttons[t.butkey..'val'].refresh = true
                                if DATA.GUI.buttons[t.butkey..'knob'] then 
                                  local val_norm = src_t[t.ctrlval_key] 
                                  if t.ctrlval_max and t.ctrlval_min then val_norm = (val_norm - t.ctrlval_min) / (t.ctrlval_max - t.ctrlval_min) end
                                  DATA.GUI.buttons[t.butkey..'knob'].val = val_norm
                                end
                                DATA2.ONDOUBLECLICK = true
                              end,                            
                        onmouserelease = function()
                              if not DATA2.ONDOUBLECLICK then
                                if not (t.butkey and DATA.GUI.buttons[t.butkey..'frame'] and DATA.GUI.buttons[t.butkey..'frame'].val) then return end
                                local new_val = DATA.GUI.buttons[t.butkey..'frame'].val
                                params_t.func_app(new_val)
                                --params_t.func_refresh()
                                DATA.GUI.buttons[t.butkey..'val'].txt = src_t[t.ctrlval_format_key]
                                DATA.GUI.buttons[t.butkey..'val'].refresh = true
                                DATA.GUI.buttons[t.butkey..'val'].val = src_t[t.ctrlval_key]
                                if DATA.GUI.buttons[t.butkey..'knob'] then 
                                  local val_norm = src_t[t.ctrlval_key] 
                                  if t.ctrlval_max and t.ctrlval_min then val_norm = (val_norm - t.ctrlval_min) / (t.ctrlval_max - t.ctrlval_min) end
                                  DATA.GUI.buttons[t.butkey..'knob'].val = val_norm
                                end
                                DATA2.ONPARAMDRAG = false
                                if params_t.func_atrelease then params_t.func_atrelease() end
                               else
                                DATA2.ONDOUBLECLICK = nil
                              end
                        end,
                        
                        onmousereleaseR = function()
                                if not params_t.func_formatreverse then return end
                                local retval, str = GetUserInputs( 'Set values', 1, '', src_t[t.ctrlval_format_key] )
                                if not (retval and str ~='' ) then return end  
                                new_val = params_t.func_formatreverse(str )
                                if not new_val then return end
                                params_t.func_app(new_val)
                                params_t.func_refresh()
                                DATA.GUI.buttons[t.butkey..'val'].txt = src_t[t.ctrlval_format_key]
                                DATA.GUI.buttons[t.butkey..'val'].refresh = true
                                if DATA.GUI.buttons[t.butkey..'knob'] then 
                                  local val_norm = src_t[t.ctrlval_key] 
                                  if t.ctrlval_max and t.ctrlval_min then val_norm = (val_norm - t.ctrlval_min) / (t.ctrlval_max - t.ctrlval_min) end
                                  DATA.GUI.buttons[t.butkey..'knob'].val = val_norm
                                end
                                if params_t.func_atrelease then params_t.func_atrelease() end
                        end, ]]
                        }           
    if t.ctrlval_istoggle== true then 
      DATA.GUI.buttons[t.butkey..'frame'].onmouserelease = function() 
        t.func_app() 
        GUI_nodes_init(DATA)
      end
      if src_t[t.ctrlval_key] == 0 then DATA.GUI.buttons[t.butkey..'frame'].frame_a = 0.05 end
     else 
      DATA.GUI.buttons[t.butkey..'frame'].onmouserelease =  DATA.GUI.buttons[t.butkey..'frame'].onmousedrag  
    end
    
    
    DATA.GUI.buttons[t.butkey..'name'] = { x= t.x+1+DATA.GUI.custom_offset*2,
                          y=t.y+1 ,
                          hide = t.y<DATA.GUI.custom_infoh,
                          w=t.w-2-DATA.GUI.custom_offset*4,
                          h=DATA.GUI.custom_knob_readout_h,
                          ignoremouse = true,
                          frame_a = 1,
                          frame_col = '#333333',
                          txt = t.ctrlname,
                          txt_fontsz =  DATA.GUI.custom_sampler_ctrl_txtsz,
                          txt_a = t.txt_a,
                          }  
    
    
                      
    if t.ctrlval_istoggle~= true then
      local val_norm = src_t[t.ctrlval_key] 
      if t.ctrlval_max and t.ctrlval_min then val_norm = (val_norm - t.ctrlval_min) / (t.ctrlval_max - t.ctrlval_min) end
      local knob_w = math.floor(t.w*0.8)
      DATA.GUI.buttons[t.butkey..'knob'] = { x= t.x+1+math.floor(t.w/2-knob_w/2),--+arc_shift,
                          y=t.y+DATA.GUI.custom_knob_readout_h+DATA.GUI.custom_offset-1,
                          hide = t.y<DATA.GUI.custom_infoh,
                          w=knob_w-2,---arc_shift*2,
                          h=t.h-DATA.GUI.custom_knob_readout_h*2-DATA.GUI.custom_offset*2+2,
                          ignoremouse = true,
                          frame_a =1,
                          frame_col = '#333333',
                          knob_isknob = true,
                          val = val_norm,
                          }
      DATA.GUI.buttons[t.butkey..'val'] = { x= t.x+1+DATA.GUI.custom_offset*2,
                        y=t.y+t.h-DATA.GUI.custom_knob_readout_h -1,
                        w=t.w-2-DATA.GUI.custom_offset*4,
                        hide = t.y<DATA.GUI.custom_infoh,
                        h=DATA.GUI.custom_knob_readout_h,
                        ignoremouse = true,
                        frame_a = 1,
                        frame_col = '#333333',
                        txt = format_val(),
                        txt_fontsz =  DATA.GUI.custom_sampler_ctrl_txtsz,
                        txt_a = t.txt_a,
                        }                           
    end
    
    if t.ctrlval_istoggle==true then
      local knob_w = math.floor(t.w*0.8)
      local toggeltxt,togglea = 'Off', 0.3
      if src_t[t.ctrlval_key] == 1 then toggeltxt,togglea = 'On',1 end
      DATA.GUI.buttons[t.butkey..'toggle'] = { x= t.x+1+math.floor(t.w/2-knob_w/2),--+arc_shift,
                          y=t.y+DATA.GUI.custom_knob_readout_h+DATA.GUI.custom_offset-1,
                          hide = t.y<DATA.GUI.custom_infoh,
                          w=knob_w-2,---arc_shift*2,
                          h=t.h-DATA.GUI.custom_knob_readout_h*2-DATA.GUI.custom_offset*2+2,
                          ignoremouse = true,
                          frame_col = '#333333',
                          txt_a = togglea,
                          txt = toggeltxt,
                          }
    end
    
  end
  ----------------------------------------------------------------------
  function GUI_nodes_02base(DATA, ctrl_t,  node_y_offs0) 
    local ctrl_key = ctrl_t.ctrl_key
    local node_x_offs = DATA.GUI.custom_nodeparam_areaw + math.floor(DATA.GUI.custom_nodectrlblock_areaw/2-DATA.GUI.custom_nodectrlblock_w/2)
    local node_y_offs = node_y_offs0 + math.floor(DATA.GUI.custom_node_areah/2-DATA.GUI.custom_nodectrlblock_h/2)
    local node_w = DATA.GUI.custom_nodeparam_areaw
    local node_h = DATA.GUI.custom_node_areah
    local basekey = 'ctrl_'..ctrl_key..'base'
    DATA.GUI.buttons[basekey] = { x=node_x_offs,
                          y=node_y_offs,
                          hide = node_y_offs<DATA.GUI.custom_infoh,
                          w=DATA.GUI.custom_nodectrlblock_w-1,
                          h=DATA.GUI.custom_nodectrlblock_h-1,
                          txt = infotxt,
                          frame_a = 0.4,
                          txt_fontsz = DATA.GUI.custom_nodectrlblock_txtsz,
                          ignoremouse = true,
                          frame_arcborder = true,
                          frame_arcborderr = math.floor(DATA.GUI.custom_offset),
                                                  
                          }
    -- wires
    DATA.GUI.buttons['ctrl_'..ctrl_key..'base_wire'] = { x=0,y=0,w=0,h=0,
                          txt = '',
                          hide = node_y_offs<DATA.GUI.custom_infoh,
                          backgr_col = '#333333',
                          backgr_fill = 0,
                          frame_a = 0,
                          frame_asel = 0,
                          wiredata = {  x1 = DATA.GUI.buttons['ctrl_'..ctrl_key].x+DATA.GUI.buttons['ctrl_'..ctrl_key].w,
                                        x2 = DATA.GUI.buttons['ctrl_'..ctrl_key].x+DATA.GUI.buttons['ctrl_'..ctrl_key].w + DATA.GUI.buttons[basekey].x - DATA.GUI.buttons['ctrl_'..ctrl_key].x-DATA.GUI.buttons['ctrl_'..ctrl_key].w,
                                        y1=DATA.GUI.buttons['ctrl_'..ctrl_key].y+math.floor(DATA.GUI.buttons['ctrl_'..ctrl_key].h/2),
                                        y2=DATA.GUI.buttons[basekey].y+math.floor(DATA.GUI.buttons[basekey].h/2)
                                  },
                          } 
    local ctrl_x = node_x_offs + DATA.GUI.custom_knob_buttonarea_w/2-DATA.GUI.custom_knob_button_w/2                  
    GUI_CTRL(DATA,
      {
        butkey = 'mod_mod.active'..ctrl_key,
        
        x = ctrl_x + DATA.GUI.custom_knob_buttonarea_w/2-DATA.GUI.custom_knob_button_w/2,
        y= node_y_offs+DATA.GUI.custom_nodectrlblock_h/2-DATA.GUI.custom_knob_button_h/2,
        w = DATA.GUI.custom_knob_button_w,
        h = DATA.GUI.custom_knob_button_h, 
        ctrlname = 'Enable',
        ctrlval_key = 'mod.active',
        ctrlval_format_key = 'mod.active', 
        ctrlval_istoggle = true, 
        ctrlval_src_t = ctrl_t.PMOD,
        ctrlval_res = 0.1,
        ctrlval_default = 0.5,
        func_app =            function() ctrl_t.PMOD['mod.active']=ctrl_t.PMOD['mod.active']~1 DATA2:ApplyPMOD(ctrl_key) end,
       } )   
    ctrl_x = ctrl_x + DATA.GUI.custom_knob_buttonarea_w    
    GUI_CTRL(DATA,
      {
        butkey = 'mod_mod.visible'..ctrl_key,
        
        x = ctrl_x + DATA.GUI.custom_knob_buttonarea_w/2-DATA.GUI.custom_knob_button_w/2,
        y= node_y_offs+DATA.GUI.custom_nodectrlblock_h/2-DATA.GUI.custom_knob_button_h/2,
        w = DATA.GUI.custom_knob_button_w,
        h = DATA.GUI.custom_knob_button_h, 
        ctrlname = 'Visible',
        ctrlval_key = 'mod.visible',
        ctrlval_format_key = 'mod.visible', 
        ctrlval_istoggle = true, 
        ctrlval_src_t = ctrl_t.PMOD,
        ctrlval_res = 0.1,
        ctrlval_default = 0.5,
        func_app =            function() ctrl_t.PMOD['mod.visible']=ctrl_t.PMOD['mod.visible']~1 DATA2:ApplyPMOD(ctrl_key) end,
       } )         
    ctrl_x = ctrl_x + DATA.GUI.custom_knob_buttonarea_w
    GUI_CTRL(DATA,
      {
        butkey = 'mod_lfo.active'..ctrl_key, 
        x = ctrl_x + DATA.GUI.custom_knob_buttonarea_w/2-DATA.GUI.custom_knob_button_w/2,
        y= node_y_offs+DATA.GUI.custom_nodectrlblock_h/2-DATA.GUI.custom_knob_button_h/2,
        w = DATA.GUI.custom_knob_button_w,
        h = DATA.GUI.custom_knob_button_h, 
        ctrlname = 'LFO',
        ctrlval_key = 'lfo.active',
        ctrlval_format_key = 'lfo.active',
        ctrlval_istoggle = true, 
        ctrlval_src_t = ctrl_t.PMOD,
        ctrlval_res = 0.1,
        ctrlval_default = 0.5,
        func_app =            function() ctrl_t.PMOD['lfo.active']=ctrl_t.PMOD['lfo.active']~1 DATA2:ApplyPMOD(ctrl_key) end,
       } )  
    ctrl_x = ctrl_x + DATA.GUI.custom_knob_buttonarea_w
    GUI_CTRL(DATA,
      {
        butkey = 'mod_plink.active'..ctrl_key, 
        x = ctrl_x + DATA.GUI.custom_knob_buttonarea_w/2-DATA.GUI.custom_knob_button_w/2,
        y= node_y_offs+DATA.GUI.custom_nodectrlblock_h/2-DATA.GUI.custom_knob_button_h/2,
        w = DATA.GUI.custom_knob_button_w,
        h = DATA.GUI.custom_knob_button_h, 
        ctrlname = 'Link',
        ctrlval_key = 'plink.active',
        ctrlval_format_key = 'plink.active',
        ctrlval_istoggle = true, 
        ctrlval_src_t = ctrl_t.PMOD,
        ctrlval_res = 0.1,
        ctrlval_default = 0.5,
        func_app =            function() ctrl_t.PMOD['plink.active']=ctrl_t.PMOD['plink.active']~1 DATA2:ApplyPMOD(ctrl_key) end,
       } )        
    ctrl_x = ctrl_x + DATA.GUI.custom_knob_buttonarea_w
    GUI_CTRL(DATA,
      {
        butkey = 'mod_acs.active'..ctrl_key, 
        x = ctrl_x + DATA.GUI.custom_knob_buttonarea_w/2-DATA.GUI.custom_knob_button_w/2,
        y= node_y_offs+DATA.GUI.custom_nodectrlblock_h/2-DATA.GUI.custom_knob_button_h/2,
        w = DATA.GUI.custom_knob_button_w,
        h = DATA.GUI.custom_knob_button_h, 
        ctrlname = 'Audio ctrl',
        ctrlval_key = 'acs.active',
        ctrlval_format_key = 'acs.active',
        ctrlval_istoggle = true, 
        ctrlval_src_t = ctrl_t.PMOD,
        ctrlval_res = 0.1,
        ctrlval_default = 0.5,
        func_app =            function() ctrl_t.PMOD['acs.active']=ctrl_t.PMOD['acs.active']~1 DATA2:ApplyPMOD(ctrl_key) end,
       } )
    ctrl_x = ctrl_x + DATA.GUI.custom_knob_buttonarea_w
    GUI_CTRL(DATA,
      {
        butkey = 'mod_mod.baseline'..ctrl_key, 
        x = ctrl_x + DATA.GUI.custom_knob_buttonarea_w/2-DATA.GUI.custom_knob_button_w/2,
        y= node_y_offs+DATA.GUI.custom_nodectrlblock_h/2-DATA.GUI.custom_knob_button_h/2,
        w = DATA.GUI.custom_knob_button_w,
        h = DATA.GUI.custom_knob_button_h, 
        ctrlname = 'Base',
        ctrlval_key = 'mod.baseline',
        ctrlval_format_key = 'mod.baseline',
        ctrlval_format = function(x) return (math.floor(x*1000)/10-100)..'%' end,
        ctrlval_src_t = ctrl_t.PMOD,
        ctrlval_res = 0.4,
        ctrlval_min = 0,
        ctrlval_max = 2,
        ctrlval_default = 1,
        func_app = function() ctrl_t.PMOD['mod.baseline']=DATA.GUI.buttons['mod_mod.baseline'..ctrl_key..'frame'].val DATA2:ApplyPMOD(ctrl_key) end,
       } )       
    return node_y_offs + node_h
  end    
  ----------------------------------------------------------------------
  function GUI_nodes_03lfo(DATA, ctrl_t,  node_y_offs0) 
    local ctrl_key = ctrl_t.ctrl_key
    local node_x_offs = DATA.GUI.custom_nodeparam_areaw + math.floor(DATA.GUI.custom_nodectrlblock_areaw/2-DATA.GUI.custom_nodectrlblock_w/2)
    local node_y_offs = node_y_offs0 + math.floor(DATA.GUI.custom_node_areah/2-DATA.GUI.custom_nodectrlblock_h/2)
    local node_w = DATA.GUI.custom_nodeparam_areaw
    local node_h = DATA.GUI.custom_node_areah
    local basekey = 'ctrl_'..ctrl_key..'lfo'
    DATA.GUI.buttons[basekey] = { x=node_x_offs,
                          y=node_y_offs,
                          hide = node_y_offs<DATA.GUI.custom_infoh,
                          w=DATA.GUI.custom_nodectrlblock_w-1,
                          h=DATA.GUI.custom_nodectrlblock_h-1,
                          txt = 'LFO',
                          offsetframe = DATA.GUI.custom_offset,
                          frame_a = 0.4,
                          txt_fontsz = DATA.GUI.custom_nodectrlblock_txtsz,
                          ignoremouse = true,
                          frame_arcborder = true,
                          frame_arcborderr = math.floor(DATA.GUI.custom_offset),
                                                  
                          }
    -- wires
    DATA.GUI.buttons['ctrl_'..ctrl_key..'lfo_wire'] = { x=0,y=0,w=0,h=0,
                          txt = '',
                          hide = node_y_offs<DATA.GUI.custom_infoh,
                          backgr_col = '#333333',
                          backgr_fill = 0,
                          frame_a = 0,
                          frame_asel = 0,
                          wiredata = {  x1 = DATA.GUI.buttons['ctrl_'..ctrl_key].x+DATA.GUI.buttons['ctrl_'..ctrl_key].w,
                                        x2 = DATA.GUI.buttons['ctrl_'..ctrl_key].x+DATA.GUI.buttons['ctrl_'..ctrl_key].w + DATA.GUI.buttons[basekey].x - DATA.GUI.buttons['ctrl_'..ctrl_key].x-DATA.GUI.buttons['ctrl_'..ctrl_key].w,
                                        y1=DATA.GUI.buttons['ctrl_'..ctrl_key].y+math.floor(DATA.GUI.buttons['ctrl_'..ctrl_key].h/2),
                                        y2=DATA.GUI.buttons[basekey].y+math.floor(DATA.GUI.buttons[basekey].h/2)
                                  },
                          } 
    local ctrl_x = node_x_offs + DATA.GUI.custom_knob_buttonarea_w/2-DATA.GUI.custom_knob_button_w/2      
    GUI_CTRL(DATA,
      {
        butkey = 'mod_lfo.shape'..ctrl_key, 
        x = ctrl_x + DATA.GUI.custom_knob_buttonarea_w/2-DATA.GUI.custom_knob_button_w/2,
        y= node_y_offs+DATA.GUI.custom_nodectrlblock_h/2-DATA.GUI.custom_knob_button_h/2,
        w = DATA.GUI.custom_knob_button_w,
        h = DATA.GUI.custom_knob_button_h, 
        ctrlname = 'Shape',
        ctrlval_key = 'lfo.shape',
        ctrlval_format_key = 'lfo.shape', 
        ctrlval_format = function(x) return (math.floor(x*1000)/10)..'%' end,
        ctrlval_src_t = ctrl_t.PMOD,
        ctrlval_res = 0.4,
        ctrlval_min = 0,
        ctrlval_max = 5,
        ctrlval_default = 0,
        func_app = function() ctrl_t.PMOD['lfo.shape']=DATA.GUI.buttons['mod_lfo.shape'..ctrl_key..'frame'].val DATA2:ApplyPMOD(ctrl_key) end  
      } )
    return node_y_offs + node_h
  end    
  ----------------------------------------------------------------------
  function GUI_nodes_04link(DATA, ctrl_t,  node_y_offs0) 
    local ctrl_key = ctrl_t.ctrl_key
    local node_x_offs = DATA.GUI.custom_nodeparam_areaw + math.floor(DATA.GUI.custom_nodectrlblock_areaw/2-DATA.GUI.custom_nodectrlblock_w/2)
    local node_y_offs = node_y_offs0 + math.floor(DATA.GUI.custom_node_areah/2-DATA.GUI.custom_nodectrlblock_h/2)
    local node_w = DATA.GUI.custom_nodeparam_areaw
    local node_h = DATA.GUI.custom_node_areah
    local basekey = 'ctrl_'..ctrl_key..'plink'
    DATA.GUI.buttons[basekey] = { x=node_x_offs,
                          y=node_y_offs,
                          hide = node_y_offs<DATA.GUI.custom_infoh,
                          w=DATA.GUI.custom_nodectrlblock_w-1,
                          h=DATA.GUI.custom_nodectrlblock_h-1,
                          txt = 'Link',
                          offsetframe = DATA.GUI.custom_offset,
                          frame_a = 0.4,
                          txt_fontsz = DATA.GUI.custom_nodectrlblock_txtsz,
                          ignoremouse = true,
                          frame_arcborder = true,
                          frame_arcborderr = math.floor(DATA.GUI.custom_offset),
                                                  
                          }
    -- wires
    DATA.GUI.buttons['ctrl_'..ctrl_key..'plink_wire'] = { x=0,y=0,w=0,h=0,
                          txt = '',
                          hide = node_y_offs<DATA.GUI.custom_infoh,
                          backgr_col = '#333333',
                          backgr_fill = 0,
                          frame_a = 0,
                          frame_asel = 0,
                          wiredata = {  x1 = DATA.GUI.buttons['ctrl_'..ctrl_key].x+DATA.GUI.buttons['ctrl_'..ctrl_key].w,
                                        x2 = DATA.GUI.buttons['ctrl_'..ctrl_key].x+DATA.GUI.buttons['ctrl_'..ctrl_key].w + DATA.GUI.buttons[basekey].x - DATA.GUI.buttons['ctrl_'..ctrl_key].x-DATA.GUI.buttons['ctrl_'..ctrl_key].w,
                                        y1=DATA.GUI.buttons['ctrl_'..ctrl_key].y+math.floor(DATA.GUI.buttons['ctrl_'..ctrl_key].h/2),
                                        y2=DATA.GUI.buttons[basekey].y+math.floor(DATA.GUI.buttons[basekey].h/2)
                                  },
                          } 
    local ctrl_x = node_x_offs + DATA.GUI.custom_knob_buttonarea_w/2-DATA.GUI.custom_knob_button_w/2      
    GUI_CTRL(DATA,
      {
        butkey = 'mod_plink.offset'..ctrl_key, 
        x = ctrl_x + DATA.GUI.custom_knob_buttonarea_w/2-DATA.GUI.custom_knob_button_w/2,
        y= node_y_offs+DATA.GUI.custom_nodectrlblock_h/2-DATA.GUI.custom_knob_button_h/2,
        w = DATA.GUI.custom_knob_button_w,
        h = DATA.GUI.custom_knob_button_h, 
        ctrlname = 'Offset',
        ctrlval_key = 'plink.offset',
        ctrlval_format_key = 'plink.offset', 
        ctrlval_format = function(x) return (math.floor(x*1000)/10)..'%' end,
        ctrlval_src_t = ctrl_t.PMOD,
        ctrlval_res = 0.2,
        ctrlval_min = -1,
        ctrlval_max = 1,
        ctrlval_default = 0,
        func_app = function() ctrl_t.PMOD['plink.offset']=DATA.GUI.buttons['mod_plink.offset'..ctrl_key..'frame'].val DATA2:ApplyPMOD(ctrl_key) end  
      } )
    return node_y_offs + node_h
  end    
  ----------------------------------------------------------------------
  function GUI_nodes_05acs(DATA, ctrl_t,  node_y_offs0) 
    local ctrl_key = ctrl_t.ctrl_key
    local node_x_offs = DATA.GUI.custom_nodeparam_areaw + math.floor(DATA.GUI.custom_nodectrlblock_areaw/2-DATA.GUI.custom_nodectrlblock_w/2)
    local node_y_offs = node_y_offs0 + math.floor(DATA.GUI.custom_node_areah/2-DATA.GUI.custom_nodectrlblock_h/2)
    local node_w = DATA.GUI.custom_nodeparam_areaw
    local node_h = DATA.GUI.custom_node_areah
    local basekey = 'ctrl_'..ctrl_key..'acs'
    DATA.GUI.buttons[basekey] = { x=node_x_offs,
                          y=node_y_offs,
                          hide = node_y_offs<DATA.GUI.custom_infoh,
                          w=DATA.GUI.custom_nodectrlblock_w-1,
                          h=DATA.GUI.custom_nodectrlblock_h-1,
                          txt = 'Audio control',
                          offsetframe = DATA.GUI.custom_offset,
                          frame_a = 0.4,
                          txt_fontsz = DATA.GUI.custom_nodectrlblock_txtsz,
                          ignoremouse = true,
                          frame_arcborder = true,
                          frame_arcborderr = math.floor(DATA.GUI.custom_offset),
                                                  
                          }
    -- wires
    DATA.GUI.buttons['ctrl_'..ctrl_key..'acs_wire'] = { x=0,y=0,w=0,h=0,
                          txt = '',
                          hide = node_y_offs<DATA.GUI.custom_infoh,
                          backgr_col = '#333333',
                          backgr_fill = 0,
                          frame_a = 0,
                          frame_asel = 0,
                          wiredata = {  x1 = DATA.GUI.buttons['ctrl_'..ctrl_key].x+DATA.GUI.buttons['ctrl_'..ctrl_key].w,
                                        x2 = DATA.GUI.buttons['ctrl_'..ctrl_key].x+DATA.GUI.buttons['ctrl_'..ctrl_key].w + DATA.GUI.buttons[basekey].x - DATA.GUI.buttons['ctrl_'..ctrl_key].x-DATA.GUI.buttons['ctrl_'..ctrl_key].w,
                                        y1=DATA.GUI.buttons['ctrl_'..ctrl_key].y+math.floor(DATA.GUI.buttons['ctrl_'..ctrl_key].h/2),
                                        y2=DATA.GUI.buttons[basekey].y+math.floor(DATA.GUI.buttons[basekey].h/2)
                                  },
                          } 
    local ctrl_x = node_x_offs + DATA.GUI.custom_knob_buttonarea_w/2-DATA.GUI.custom_knob_button_w/2      
    GUI_CTRL(DATA,
      {
        butkey = 'mod_acs.strength'..ctrl_key, 
        x = ctrl_x + DATA.GUI.custom_knob_buttonarea_w/2-DATA.GUI.custom_knob_button_w/2,
        y= node_y_offs+DATA.GUI.custom_nodectrlblock_h/2-DATA.GUI.custom_knob_button_h/2,
        w = DATA.GUI.custom_knob_button_w,
        h = DATA.GUI.custom_knob_button_h, 
        ctrlname = 'Strength',
        ctrlval_key = 'acs.strength',
        ctrlval_format_key = 'acs.strength', 
        ctrlval_format = function(x) return (math.floor(x*1000)/10)..'%' end,
        ctrlval_src_t = ctrl_t.PMOD,
        ctrlval_res = 0.2,
        ctrlval_min = 0,
        ctrlval_max = 1,
        ctrlval_default = 0,
        func_app = function() ctrl_t.PMOD['acs.strength']=DATA.GUI.buttons['mod_acs.strength'..ctrl_key..'frame'].val DATA2:ApplyPMOD(ctrl_key) end  
      } )
    return node_y_offs + node_h
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
      local node_comh = 0
      for control in spairs(DATA2.modulationstate) do
        for link =1,#DATA2.modulationstate[control] do
          node_comh =node_comh + DATA.GUI.custom_node_areah
        end
      end
      node_comh =math.max(node_comh-DATA.GUI.custom_infoh - DATA.GUI.custom_node_areah,DATA.GUI.custom_gfx_hreal)
    
    local node_y_offs = (DATA2.scroll_list or 0) * (1-node_comh) + DATA.GUI.custom_infoh
    for param in spairs(DATA2.modulationstate) do
      GUI_nodes_01parameter(DATA, DATA2.modulationstate[param], node_y_offs)  
      if DATA2.modulationstate[param].PMOD then
        node_y_offs = GUI_nodes_02base(DATA, DATA2.modulationstate[param], node_y_offs) 
        if DATA2.modulationstate[param].PMOD['mod.active'] == 1 then 
          if DATA2.modulationstate[param].PMOD['lfo.active'] == 1   then node_y_offs = GUI_nodes_03lfo(DATA, DATA2.modulationstate[param], node_y_offs)  end
          if DATA2.modulationstate[param].PMOD['plink.active'] == 1   then node_y_offs = GUI_nodes_04link(DATA, DATA2.modulationstate[param], node_y_offs)  end
          if DATA2.modulationstate[param].PMOD['acs.active'] == 1   then node_y_offs = GUI_nodes_05acs(DATA, DATA2.modulationstate[param], node_y_offs)  end
        end
      end
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
                        --frame_asel = 0,
                        
                        txt = 'Actions / Options',
                        txt_fontsz=DATA.GUI.custom_info_txtsz,
                        onmouserelease = function() 
                          DATA:GUImenu(
                          {
                            { str = '#Filter'},
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
                            },  ]]                           
                            {str='|Dock',
                             func =           function()  
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
                            }
                          })
                          --[[
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
      DATA.GUI.custom_reference = 800
      DATA.GUI.custom_Yrelation = VF_lim(math.max(DATA.GUI.custom_gfx_hreal,DATA.GUI.custom_gfx_wreal)/DATA.GUI.custom_reference, 0.1, 8) -- global W
      DATA.GUI.custom_offset =  math.floor(3 * DATA.GUI.custom_Yrelation)
      
      
      DATA.GUI.custom_infoh =  math.floor(40 * DATA.GUI.custom_Yrelation)
      DATA.GUI.custom_info_txtsz= math.floor(20* DATA.GUI.custom_Yrelation)
      DATA.GUI.custom_scrollw =  math.floor(20 * DATA.GUI.custom_Yrelation)
      
    -- nodes
      DATA.GUI.custom_nodes_area_w = DATA.GUI.custom_gfx_wreal - DATA.GUI.custom_scrollw-DATA.GUI.custom_offset*2
      DATA.GUI.custom_node_areah = math.floor(90*DATA.GUI.custom_Yrelation)
      DATA.GUI.custom_node_removew = math.floor(20*DATA.GUI.custom_Yrelation) 
    -- param node
      DATA.GUI.custom_nodeparam_areaw = math.floor(DATA.GUI.custom_nodes_area_w*0.25)  
      DATA.GUI.custom_nodeparam_txtsz= math.floor(17* DATA.GUI.custom_Yrelation)  
      DATA.GUI.custom_nodeparam_w= math.floor(DATA.GUI.custom_nodeparam_areaw*0.9)
      DATA.GUI.custom_nodeparam_h= math.floor(DATA.GUI.custom_node_areah*0.6)
    -- info node
      DATA.GUI.custom_nodectrlblock_areaw = DATA.GUI.custom_nodes_area_w -  DATA.GUI.custom_nodeparam_areaw
      DATA.GUI.custom_nodectrlblock_txtsz= math.floor(15* DATA.GUI.custom_Yrelation)
      DATA.GUI.custom_nodectrlblock_w= math.floor(DATA.GUI.custom_nodectrlblock_areaw*0.9)
      DATA.GUI.custom_nodectrlblock_h= math.floor(DATA.GUI.custom_node_areah*0.9)
    
      DATA.GUI.custom_knob_buttonarea_w = math.floor(DATA.GUI.custom_nodectrlblock_h * 0.9)
      DATA.GUI.custom_knob_button_w = math.floor(DATA.GUI.custom_knob_buttonarea_w * 0.9)
      DATA.GUI.custom_knob_button_h= math.floor(DATA.GUI.custom_nodectrlblock_h*0.9)
      DATA.GUI.custom_knob_readout_h = math.floor(DATA.GUI.custom_nodectrlblock_h*0.2 )   
      
    GUI_header_info(DATA)
    
    -- scroll
      DATA.GUI.buttons.scroll = { x=DATA.GUI.custom_gfx_wreal-DATA.GUI.custom_scrollw-DATA.GUI.custom_offset*2,
                          y=DATA.GUI.custom_offset+DATA.GUI.custom_infoh,
                          w=DATA.GUI.custom_scrollw-DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_gfx_hreal-DATA.GUI.custom_offset*2-DATA.GUI.custom_infoh,
                          backgr_fill =  0.2,
                          frame_a = 0.1,
                          frame_asel = 0.1,
                          val = 0,
                          val_res = -1,
                          slider_isslider = true,
                          onmousedrag = function() 
                            DATA2.scroll_list = DATA.GUI.buttons.scroll.val 
                            DATA.GUI.buttons.scroll.refresh = true
                            GUI_nodes_init(DATA)
                          end,
                          onmouserelease = function() 
                            DATA.GUI.buttons.scroll.refresh = true
                          end
                          }
    GUI_nodes_init(DATA)                    
    for but in pairs(DATA.GUI.buttons) do DATA.GUI.buttons[but].key = but end
  end 
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.42) if ret then local ret2 = VF_CheckReaperVrs(6.71,true) if ret2 then main() end end