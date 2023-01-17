-- @description LearnEditor
-- @version 2.03
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # refresh GUI at wh change



 
  -- NOT gfx NOT reaper NOT VF NOT GUI NOT DATA NOT MAIN 
  
  DATA2 = { 
          }
  ---------------------------------------------------------------------  
  function main()  
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.version = '2.03'
    DATA.extstate.extstatesection = 'MPL_LearnEditor'
    DATA.extstate.mb_title = 'LearnEditor'
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
  ----------------------------------------------------------------------
  function DATA2:ImportCSV()
    --local out_fp =GetProjectPath()..'/LearNEditor_mapping.xml'
    local retval, xml = reaper.GetUserFileNameForRead('', 'LearnEditor mapping', '.xml' )
    
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
    local out_fp =GetProjectPath()..'/LearnEditor_mapping.xml'
    if not DATA2.learnstate then return end
    
    local str = ''
    for control in pairs(DATA2.learnstate) do
      str=str..'\n<control id="'..control..'">'
      str=str..'\n  <ctrl_type>'..DATA2.learnstate[control].ctrl_type..'</ctrl_type>'
      str=str..'\n  <ctrl_key>'..DATA2.learnstate[control].ctrl_key..'</ctrl_key>'
      for link = 1, #DATA2.learnstate[control] do
        str=str..'\n  <link linkid="'..link..'">'
        str=str..'\n    <trGUID>'..DATA2.learnstate[control][link].trGUID..'</trGUID>'
        str=str..'\n    <fxGUID>'..DATA2.learnstate[control][link].fxGUID..'</fxGUID>'
        str=str..'\n    <flags>'..DATA2.learnstate[control][link].flags..'</flags>'
        str=str..'\n    <mode>'..DATA2.learnstate[control][link].mode..'</mode>'
        str=str..'\n    <param>'..DATA2.learnstate[control][link].param..'</param>'
        str=str..'\n  </link>'
      end
      str=str..'\n</control>'
    end
    
    str=str..'\n<LearnEditor_vrs>'..DATA.extstate.version..'</LearnEditor_vrs>'
    str=str..'\n<ts>'..os.date()..'</ts>'
    
    local f = io.open(out_fp,'wb')
    if f then 
      f:write(str)
      f:close()
    end
    MB('Export successfully to '..out_fp,DATA.extstate.mb_title,0)
  end
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
  function DATA2:ModLearn(ctrl_t, linkid,remove, toggleflag, mode)
    local trGUID = ctrl_t[linkid].trGUID
    local track = VF_GetMediaTrackByGUID(0, trGUID)
    local fxGUID = ctrl_t[linkid].fxGUID
    local ret, tr, fx = VF_GetFXByGUID(fxGUID, track) 
    local pid = ctrl_t[linkid].param
    
    -- remove
    if remove then 
      if ctrl_t.ctrl_type == 0 then
        TrackFX_SetNamedConfigParm( track, fx,'param.'..pid..'.learn.midi1' ,'')
        TrackFX_SetNamedConfigParm( track, fx,'param.'..pid..'.learn.midi2' ,'')
       elseif ctrl_t.ctrl_type == 1 then
        TrackFX_SetNamedConfigParm( track, fx,'param.'..pid..'.learn.osc' ,'')
      end
    end
    
    if toggleflag then 
      TrackFX_SetNamedConfigParm( track, fx,'param.'..pid..'.learn.flags' ,ctrl_t[linkid].flags~toggleflag)
    end
    
    if mode then 
      TrackFX_SetNamedConfigParm( track, fx,'param.'..pid..'.learn.mode' ,mode)
    end
    
    
  end
  ---------------------------------------------------------------------  
  function DATA2:RefreshAliasMap()
    local str = ''
    for key in pairs(DATA2.aliasmap) do if DATA2.aliasmap[key] ~= '' then str = str..'[<'..key..'><'..DATA2.aliasmap[key]..'>]' end end
    DATA.extstate.UI_aliasmap = str
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
    
    DATA2.learnstate = {}
    local cnt_tracks = CountTracks( 0 )
    for trackidx =0, cnt_tracks do
      local track =  GetTrack( 0, trackidx-1 )
      if not track then track = GetMasterTrack() end
      local fx_cnt = TrackFX_GetCount( track )
      local trcol =  reaper.GetTrackColor( track )
      local retval, trname = reaper.GetTrackName( track )
      local fxcnt = TrackFX_GetCount( track )
      for fx = 1, fxcnt do
        local retval, fxname = reaper.TrackFX_GetFXName( track, fx-1, '' )
        local parmcnt =  TrackFX_GetNumParams( track, fx-1 )
        for pid =0 , parmcnt-1 do
          local retval, pname = reaper.TrackFX_GetParamName( track, fx-1, pid )
          local retval1, midi1 = TrackFX_GetNamedConfigParm( track, fx-1, 'param.'..pid..'.learn.midi1' )
          local retval1, midi2 = TrackFX_GetNamedConfigParm( track, fx-1, 'param.'..pid..'.learn.midi2' )
          local retval2, osc = TrackFX_GetNamedConfigParm( track, fx-1, 'param.'..pid..'.learn.osc' )
          midi1= tonumber(midi1)
          midi2= tonumber(midi2)
          
          local key
          local ctrl_type
          if midi1 and midi2 and (midi1~=0) then
            local midimsg = midi1+(midi2<<8)
            key = tostring(midimsg) --local key = #DATA2.learnstate+1
            ctrl_type = 0
           elseif osc~='' then
            key = tostring(osc)
            ctrl_type = 1
          end
          
          
          if key and 
            (
              DATA.extstate.CONF_filtermode == 0 or 
              (IsTrackSelected( track ) and DATA.extstate.CONF_filtermode==1) or
              ( TrackFX_GetOpen( track, fx-1 ) and DATA.extstate.CONF_filtermode==2)
            )
            then
            local retval1, mode = TrackFX_GetNamedConfigParm( track, fx-1, 'param.'..pid..'.learn.mode' )
            local retval1, flags = TrackFX_GetNamedConfigParm( track, fx-1, 'param.'..pid..'.learn.flags' )
            mode=tonumber(mode)
            flags=tonumber(flags)
            if not DATA2.learnstate[key] then DATA2.learnstate[key] = {ctrl_key = key,ctrl_type = ctrl_type} end
            local alias = ''
            if DATA2.aliasmap[key] then
              alias = DATA2.aliasmap[key]
            end
            DATA2.learnstate[key][#DATA2.learnstate[key]+1] = 
              {
                trGUID = GetTrackGUID( track),
                fxGUID = TrackFX_GetFXGUID( track, fx-1 ),
                param = pid,
                midi1=midi1,
                midi2=midi2,
                osc=osc,
                fxname=fxname,
                fxname_short = VF_ReduceFXname(fxname),
                trname=trname,
                pname = pname,
                mode=mode,
                flags=flags,
                alias=alias,
              }
          end
        end
      end
    end
    
  end
  ----------------------------------------------------------------------
  function GUI_nodes_ctrl(DATA, ctrl_t, node_y_offs0)  
    local ctrl_key = ctrl_t.ctrl_key or 0
    local node_x_offs = math.floor(DATA.GUI.custom_node_areaw/2-DATA.GUI.custom_nodectrl_w/2)
    local node_y_offs = node_y_offs0 + math.floor(DATA.GUI.custom_node_areah/2-DATA.GUI.custom_nodectrl_h/2)
    local node_w = DATA.GUI.custom_node_areaw
    local node_h = DATA.GUI.custom_node_areah
    
    local format = ctrl_key
    if ctrl_t.ctrl_type == 0 and tonumber(ctrl_key)then
      local ctrl_key_int = tonumber(ctrl_key)
      local msg_byte1 = ctrl_key_int&0xFF
      local msg_byte2 = (ctrl_key_int>>8)&0xFF
      if msg_byte1>>4 == 0xB then
        local chan = msg_byte1&0xF
        format = 'MIDI Chan '..(chan+1)..' CC '..msg_byte2
       elseif msg_byte1>>4 == 0x9 then
        local chan = msg_byte1&0xF
        format = 'MIDI Chan '..(chan+1)..' Note '..msg_byte2
      end
     elseif ctrl_t.ctrl_type == 1 then
      format = 'OSC '..ctrl_key
    end
    local format0 = format
    if DATA2.aliasmap[ctrl_key] then format0 = DATA2.aliasmap[ctrl_key]..'\n'..format end
    DATA.GUI.buttons['ctrl_'..ctrl_key] = { x=node_x_offs,
                          y=node_y_offs,
                          w=DATA.GUI.custom_nodectrl_w-1,
                          h=DATA.GUI.custom_nodectrl_h-1,
                          txt = format0,
                          txt_fontsz = DATA.GUI.custom_nodectrl_txtsz,
                          onmouseclick =   function()  end,
                          hide = node_y_offs<DATA.GUI.custom_infoh,
                          refresh= true,
                          onmouserelease = function()
                            local retval, retvals_csv = GetUserInputs( 'Alias', 1, format0, DATA2.aliasmap[ctrl_key] or '' )
                            if retval then
                              DATA2.aliasmap[ctrl_key]=retvals_csv
                              DATA2:RefreshAliasMap()
                              DATA_RESERVED_ONPROJCHANGE(DATA)
                            end
                          end
                          }
    return node_y_offs + DATA.GUI.custom_node_areah
  end
  ----------------------------------------------------------------------
  function GUI_nodes_modeflags(DATA, ctrl_t, linkid) 
    local ctrl_key = ctrl_t.ctrl_key
    local frame_obj = DATA.GUI.buttons['ctrl_'..ctrl_key..'link'..linkid..'flags']
    
    local node_x_offs = frame_obj.x
    local txt_offs = 5
    local txt_disabled = 0.3
    local node_y_offs = frame_obj.y
    local bh = math.floor(frame_obj.h/5)
    local hide = frame_obj.y<DATA.GUI.custom_infoh or frame_obj.y+frame_obj.h>DATA.GUI.custom_gfx_hreal 
    local flags = ctrl_t[linkid].flags
    local mode = ctrl_t[linkid].mode
    
    local txt_a = txt_disabled if flags&2==2 then txt_a = nil end 
    DATA.GUI.buttons['ctrl_'..ctrl_key..'link'..linkid..'modeflags_ST'] = { x=node_x_offs+txt_offs,
                          y=node_y_offs,
                          hide = hide,
                          w=frame_obj.w-txt_offs,
                          h=bh-1,
                          backgr_col = '#333333',
                          backgr_fill = 1,
                          back_sela = 0,
                          frame_a = 0,
                          frame_asel = 0,
                          txt = 'Soft takeover',
                          txt_flags = 4,
                          txt_fontsz = DATA.GUI.custom_nodeinfo_txtsz,
                          txt_a = txt_a,
                          onmouseclick = function()  
                            local f = function(ctrl_t, linkid) DATA2:ModLearn(ctrl_t, linkid, nil, 2)  end
                            DATA2:ProcessUndoBlock(f, 'Modify learn flags', ctrl_t, linkid) 
                            GUI_nodes_init(DATA)
                          end,
                          }
                          
    node_y_offs = node_y_offs + bh
    local txt_a = txt_disabled if flags&1==1 then txt_a = nil end 
    DATA.GUI.buttons['ctrl_'..ctrl_key..'link'..linkid..'modeflags_SelTr'] = { x=node_x_offs+txt_offs,
                          y=node_y_offs,
                          hide = hide,
                          w=frame_obj.w-txt_offs,
                          h=bh-1,
                          backgr_col = '#333333',
                          backgr_fill = 1,
                          back_sela = 0,
                          frame_a = 0,
                          frame_asel = 0,
                          txt = 'Selected track only',
                          txt_flags = 4,
                          txt_fontsz = DATA.GUI.custom_nodeinfo_txtsz,
                          txt_a = txt_a,
                          onmouseclick = function()  
                            local f = function(ctrl_t, linkid) DATA2:ModLearn(ctrl_t, linkid, nil, 1)  end
                            DATA2:ProcessUndoBlock(f, 'Modify learn flags', ctrl_t, linkid) 
                            GUI_nodes_init(DATA)
                          end,
                          }
    node_y_offs = node_y_offs + bh
    local txt_a = txt_disabled if flags&4==4 then txt_a = nil end 
    DATA.GUI.buttons['ctrl_'..ctrl_key..'link'..linkid..'modeflags_focused'] = { x=node_x_offs+txt_offs,
                          y=node_y_offs,
                          hide = hide,
                          w=frame_obj.w-txt_offs,
                          h=bh-1,
                          backgr_col = '#333333',
                          backgr_fill = 1,
                          back_sela = 0,
                          frame_a = 0,
                          frame_asel = 0,
                          txt = 'Focused FX only',
                          txt_flags = 4,
                          txt_fontsz = DATA.GUI.custom_nodeinfo_txtsz,
                          txt_a = txt_a,
                          onmouseclick = function()  
                            local f = function(ctrl_t, linkid) DATA2:ModLearn(ctrl_t, linkid, nil, 4)  end
                            DATA2:ProcessUndoBlock(f, 'Modify learn flags', ctrl_t, linkid) 
                            GUI_nodes_init(DATA)
                          end,
                          }   
    node_y_offs = node_y_offs + bh
    local txt_a = txt_disabled if flags&16==16 then txt_a = nil end 
    DATA.GUI.buttons['ctrl_'..ctrl_key..'link'..linkid..'modeflags_visible'] = { x=node_x_offs+txt_offs,
                          y=node_y_offs,
                          hide = hide,
                          w=frame_obj.w-txt_offs,
                          h=bh-1,
                          backgr_col = '#333333',
                          backgr_fill = 1,
                          back_sela = 0,
                          frame_a = 0,
                          frame_asel = 0,
                          txt = 'Visible FX only',
                          txt_flags = 4,
                          txt_fontsz = DATA.GUI.custom_nodeinfo_txtsz,
                          txt_a = txt_a,
                          onmouseclick = function()  
                            local f = function(ctrl_t, linkid) DATA2:ModLearn(ctrl_t, linkid, nil, 16)  end
                            DATA2:ProcessUndoBlock(f, 'Modify learn flags', ctrl_t, linkid) 
                            GUI_nodes_init(DATA)
                          end,
                          }    
    node_y_offs = node_y_offs + bh
    local txt_a = txt_disabled if mode~=0 then txt_a = nil end 
    if mode == 0 then mode='Absolute'
    elseif mode == 1 then mode='127=-1,1=+1'
    elseif mode == 2 then mode='63=-1, 65=+1'
    elseif mode == 3 then mode='65=-1, 1=+1'
    elseif mode == 4 then mode='toggle' end
    DATA.GUI.buttons['ctrl_'..ctrl_key..'link'..linkid..'modeflags_mode'] = { x=node_x_offs+txt_offs,
                          y=node_y_offs,
                          hide = hide,
                          w=frame_obj.w-txt_offs,
                          h=bh-1,
                          backgr_col = '#333333',
                          backgr_fill = 1,
                          back_sela = 0,
                          frame_a = 0,
                          frame_asel = 0,
                          txt = 'Mode: '..mode,
                          txt_flags = 4,
                          txt_fontsz = DATA.GUI.custom_nodeinfo_txtsz,
                          txt_a=txt_a,
                          onmouseclick = function()  
                            DATA:GUImenu({
                                {str = 'Absolute',
                                 func = function()
                                          local f = function(ctrl_t, linkid) DATA2:ModLearn(ctrl_t, linkid, nil, nil, 0)  end
                                          DATA2:ProcessUndoBlock(f, 'Modify learn mode', ctrl_t, linkid) 
                                          GUI_nodes_init(DATA)
                                        end
                                },
                                {str = '127=-1,1=+1',
                                 func = function()
                                          local f = function(ctrl_t, linkid) DATA2:ModLearn(ctrl_t, linkid, nil, nil, 1)  end
                                          DATA2:ProcessUndoBlock(f, 'Modify learn mode', ctrl_t, linkid) 
                                          GUI_nodes_init(DATA)
                                        end
                                },
                                {str = '63=-1, 65=+1',
                                 func = function()
                                          local f = function(ctrl_t, linkid) DATA2:ModLearn(ctrl_t, linkid, nil, nil, 2)  end
                                          DATA2:ProcessUndoBlock(f, 'Modify learn mode', ctrl_t, linkid) 
                                          GUI_nodes_init(DATA)
                                        end
                                },
                                {str = '65=-1, 1=+1',
                                 func = function()
                                          local f = function(ctrl_t, linkid) DATA2:ModLearn(ctrl_t, linkid, nil, nil, 3)  end
                                          DATA2:ProcessUndoBlock(f, 'Modify learn mode', ctrl_t, linkid) 
                                          GUI_nodes_init(DATA)
                                        end
                                },
                                {str = 'toggle',
                                 func = function()
                                          local f = function(ctrl_t, linkid) DATA2:ModLearn(ctrl_t, linkid, nil, nil, 4)  end
                                          DATA2:ProcessUndoBlock(f, 'Modify learn mode', ctrl_t, linkid) 
                                          GUI_nodes_init(DATA)
                                        end
                                },                                
                              })
                          end,
                          }                          
    
  end
  ----------------------------------------------------------------------
  function GUI_nodes_info(DATA, ctrl_t, linkid, node_y_offs0)  
    local ctrl_key = ctrl_t.ctrl_key
    local linkid = linkid
    local node_x_offs = DATA.GUI.custom_node_areaw + math.floor(DATA.GUI.custom_node_areaw/2-DATA.GUI.custom_nodeinfo_w/2)
    local node_y_offs = node_y_offs0 + math.floor(DATA.GUI.custom_node_areah/2-DATA.GUI.custom_nodeinfo_h/2)
    local node_w = DATA.GUI.custom_node_areaw
    local node_h = DATA.GUI.custom_node_areah
    
    local infotxt = 
      ctrl_t[linkid].trname..'\n'..
      ctrl_t[linkid].fxname_short..'\n'..
      ctrl_t[linkid].pname
    
    DATA.GUI.buttons['ctrl_'..ctrl_key..'link'..linkid..'info'] = { x=node_x_offs,
                          y=node_y_offs,
                          hide = node_y_offs<DATA.GUI.custom_infoh,
                          w=DATA.GUI.custom_nodeinfo_w-1,
                          h=DATA.GUI.custom_nodeinfo_h-1,
                          txt = infotxt,
                          txt_fontsz = DATA.GUI.custom_nodeinfo_txtsz,
                          ignoremouse = true,
                          }
    DATA.GUI.buttons['ctrl_'..ctrl_key..'link'..linkid..'info_remove'] = { x=node_x_offs+DATA.GUI.custom_nodeinfo_w-DATA.GUI.custom_node_removew,
                          y=node_y_offs,
                          hide = node_y_offs<DATA.GUI.custom_infoh,
                          w=DATA.GUI.custom_node_removew-1,
                          h=DATA.GUI.custom_node_removew-1,
                          txt = 'X',
                          txt_flags = 1|4,
                          txt_fontsz = DATA.GUI.custom_nodeinfo_txtsz,
                          frame_a = 0,
                          frame_asel = 0.3,
                          onmouseclick =   function() 
                            local f = function(ctrl_t, linkid) DATA2:ModLearn(ctrl_t, linkid, true)  end
                            DATA2:ProcessUndoBlock(f, 'Remove learn', ctrl_t, linkid) 
                            GUI_nodes_init(DATA)
                          end,
                          }                      
                          
                          
    local node_x_offs = DATA.GUI.custom_node_areaw*2 + math.floor(DATA.GUI.custom_node_areaw/2-DATA.GUI.custom_nodeinfo_w/2)
    DATA.GUI.buttons['ctrl_'..ctrl_key..'link'..linkid..'flags'] = { x=node_x_offs,
                          y=node_y_offs,
                          hide = node_y_offs<DATA.GUI.custom_infoh,
                          w=DATA.GUI.custom_nodeinfo_w-1,
                          h=DATA.GUI.custom_nodeinfo_h-1,
                          txt = '',
                          backgr_col = '#333333',
                          backgr_fill = 1,
                          back_sela = 0,
                          frame_asel = 0.3,
                          onmouseclick =   function()  end,
                          }
   
                          
    -- wires
    DATA.GUI.buttons['ctrl_'..ctrl_key..'link'..linkid..'wire'] = { x=0,y=0,w=0,h=0,
                          txt = '',
                          backgr_col = '#333333',
                          backgr_fill = 0,
                          frame_a = 0,
                          frame_asel = 0,
                          wiredata = {  x1 = DATA.GUI.buttons['ctrl_'..ctrl_key].x+DATA.GUI.buttons['ctrl_'..ctrl_key].w,
                                        x2 = DATA.GUI.buttons['ctrl_'..ctrl_key].x+DATA.GUI.buttons['ctrl_'..ctrl_key].w + DATA.GUI.buttons['ctrl_'..ctrl_key..'link'..linkid..'info'].x - DATA.GUI.buttons['ctrl_'..ctrl_key].x-DATA.GUI.buttons['ctrl_'..ctrl_key].w,
                                        y1=DATA.GUI.buttons['ctrl_'..ctrl_key].y+math.floor(DATA.GUI.buttons['ctrl_'..ctrl_key].h/2),
                                        y2=DATA.GUI.buttons['ctrl_'..ctrl_key..'link'..linkid..'info'].y+math.floor(DATA.GUI.buttons['ctrl_'..ctrl_key..'link'..linkid..'info'].h/2)
                                  },
                          }  
    DATA.GUI.buttons['ctrl_'..ctrl_key..'link'..linkid..'wire2'] = { x=0,y=0,w=0,h=0,
                          txt = '',
                          backgr_col = '#333333',
                          backgr_fill = 0,
                          frame_a = 0,
                          frame_asel = 0,
                          wiredata = {  x1 = DATA.GUI.buttons['ctrl_'..ctrl_key..'link'..linkid..'info'].x+DATA.GUI.buttons['ctrl_'..ctrl_key..'link'..linkid..'info'].w,
                                        x2 = DATA.GUI.buttons['ctrl_'..ctrl_key..'link'..linkid..'flags'].x,
                                        y1=DATA.GUI.buttons['ctrl_'..ctrl_key..'link'..linkid..'info'].y+math.floor(DATA.GUI.buttons['ctrl_'..ctrl_key..'link'..linkid..'info'].h/2),
                                        y2=DATA.GUI.buttons['ctrl_'..ctrl_key..'link'..linkid..'info'].y+math.floor(DATA.GUI.buttons['ctrl_'..ctrl_key..'link'..linkid..'info'].h/2)
                                  },
                          }                           
                          
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
    for key in pairs(DATA.GUI.buttons) do if key:match('ctrl_') then DATA.GUI.buttons[key] = nil end end
    if not DATA2.learnstate then return end
    -- calc common h
      local node_comh = 0
      for control in spairs(DATA2.learnstate) do
        for link =1,#DATA2.learnstate[control] do
          node_comh =node_comh + DATA.GUI.custom_node_areah
        end
      end
      node_comh =math.max(node_comh-DATA.GUI.custom_infoh - DATA.GUI.custom_node_areah,DATA.GUI.custom_gfx_hreal)
    
    local node_y_offs = (DATA2.scroll_list or 0) * (1-node_comh) + DATA.GUI.custom_infoh
    --if node_comh+DATA.GUI.custom_infoh <= DATA.GUI.custom_gfx_hreal then node_y_offs = DATA.GUI.custom_infoh end
    for control in spairs(DATA2.learnstate) do
      GUI_nodes_ctrl(DATA, DATA2.learnstate[control], node_y_offs)  
      for link =1,#DATA2.learnstate[control] do
        node_y_offs = GUI_nodes_info(DATA, DATA2.learnstate[control],link, node_y_offs) 
        GUI_nodes_modeflags(DATA, DATA2.learnstate[control], link) 
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
                            { str = '|Export learn state as XML into project path',
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
      DATA.GUI.custom_nodes_area_w = DATA.GUI.custom_gfx_wreal - DATA.GUI.custom_scrollw
      DATA.GUI.custom_node_areaw = math.floor(DATA.GUI.custom_nodes_area_w/3)
      DATA.GUI.custom_node_areah = math.floor(80*DATA.GUI.custom_Yrelation)
      DATA.GUI.custom_node_removew = math.floor(20*DATA.GUI.custom_Yrelation)
    -- ctrl node
      DATA.GUI.custom_nodectrl_txtsz= math.floor(20* DATA.GUI.custom_Yrelation)
      DATA.GUI.custom_nodectrl_w= math.floor(DATA.GUI.custom_node_areaw*0.8)
      DATA.GUI.custom_nodectrl_h= math.floor(DATA.GUI.custom_node_areah*0.7)
    -- info node
      DATA.GUI.custom_nodeinfo_txtsz= math.floor(15* DATA.GUI.custom_Yrelation)
      DATA.GUI.custom_nodeinfo_w= math.floor(DATA.GUI.custom_node_areaw*0.9)
      DATA.GUI.custom_nodeinfo_h= math.floor(DATA.GUI.custom_node_areah*0.9)
    
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