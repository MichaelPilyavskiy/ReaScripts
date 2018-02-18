-- @description InfoTool_DataUpdate
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex

  -- mpl_InfoTool_DataUpdate.lua functions for mpl_InfoTool
  
  
  ---------------------------------------------------
  function DataUpdate(data, mouse, widgets, obj, conf)
    --[[ 
      contexts for data.obj_type_int
        0 empty item
        1 MIDI item
        2 audio item
        3 multiple items 
        
        4 envelope point
        5 multiple envelope points        
        6 envelope
        
        7 track
        
    ]] 
    
    data.rul_format = MPL_GetCurrentRulerFormat()
    data.SR = tonumber(reaper.format_timestr_pos(1, '', 4))
    data.FR = TimeMap_curFrameRate( 0 )
    data.obj_type = 'No object selected'
    data.obj_type_int = -1    
    
    data.grid_val, data.grid_val_format, data.grid_istriplet = MPL_GetFormattedGrid()
    data.grid_isactive =  GetToggleCommandStateEx( 0, 1157 )==1
    
    local TS_st, TSend = GetSet_LoopTimeRange2( 0, false, false, -1, -1, false )
    data.timeselectionstart, data.timeselectionend = TS_st, TSend
    
    data.timeselectionstart_format = format_timestr_pos( data.timeselectionstart, '', -1 ) 
    data.timeselectionend_format = format_timestr_pos( data.timeselectionend, '', -1 )
     
    local int_playstate = GetPlayStateEx( 0 )
    data.play = int_playstate&1==1
    data.pause = int_playstate&2==2
    data.record = int_playstate&4==4
    data.editcur_pos = GetCursorPositionEx( 0 )
    
    data.LTFX = {}
    local ret, tr, fx, param = GetLastTouchedFX()
    if ret then
      data.LTFX.exist = true
      local tr = CSurf_TrackFromID( tr, false )
      data.LTFX_trptr = tr
      data.LTFX_fxID = fx
      data.LTFX_parID = param
      _, data.LTFX_fxname = TrackFX_GetFXName( tr, fx, '' )
      _, data.LTFX_parname = TrackFX_GetParamName( tr, fx, param, '' )
      data.LTFX_val,data.LTFX_minval,data.LTFX_maxval = TrackFX_GetParamEx( tr, fx, param )
      local _, LTFX_val_format = TrackFX_GetFormattedParamValue( tr, fx, param, '' )
      data.LTFX_val_format = LTFX_val_format:match('%d+')
    end
    
    -- reset buttons data
      obj.b = {}

    -- persisten widgets
      obj.persist_margin = Obj_UpdatePersist(data, obj, mouse, widgets)
     
    -- contexts
      local item = GetSelectedMediaItem(0,0)
      local env = GetSelectedEnvelope( 0 )
      local tr = GetSelectedTrack(0,0)
            
      if env then    
       DataUpdate_Envelope(data, env)
       Obj_UpdateEnvelope(data, obj, mouse, widgets)
       elseif item then 
        DataUpdate_Item(data) 
        Obj_UpdateItem(data, obj, mouse, widgets)
       elseif tr then
        DataUpdate_Track(data, tr)
        Obj_UpdateTrack(data, obj, mouse, widgets)        
      end

    -- update com butts
      Obj_UpdateCom(data, mouse, obj, widgets, conf) 
          
    -- reset name if overlap persist
      if obj.b.type_name.x + obj.b.type_name.w > obj.persist_margin then
        obj.b.type_name = nil
        obj.b.obj_name = nil
      end  
  end
  
  ---------------------------------------------------
  function DataUpdate_Item(data, item)
    data.name = ''  
    data.it={}
    
    local obj_type
    for i = 1, CountSelectedMediaItems(0) do
      data.it[i] = {}
      local item = GetSelectedMediaItem(0,i-1)
          
      data.it[i].ptr_item = item
          
      data.it[i].item_pos = GetMediaItemInfo_Value( item, 'D_POSITION')
      data.it[i].item_len = GetMediaItemInfo_Value( item, 'D_LENGTH')
      data.it[i].snap_offs = GetMediaItemInfo_Value( item, 'D_SNAPOFFSET')
      data.it[i].fadein_len = GetMediaItemInfo_Value( item, 'D_FADEINLEN')
      data.it[i].fadeout_len = GetMediaItemInfo_Value( item, 'D_FADEOUTLEN')       
      data.it[i].item_pos_format = format_timestr_pos( data.it[i].item_pos, '', -1 ) 
      data.it[i].item_len_format = format_timestr_len( data.it[i].item_len, '', 0, -1 ) 
      data.it[i].snap_offs_format = format_timestr_len( data.it[i].snap_offs, '', 0, -1 )
      data.it[i].fadein_len_format = format_timestr_len( data.it[i].fadein_len, '', 0, -1 )
      data.it[i].fadeout_len_format = format_timestr_len( data.it[i].fadeout_len, '', 0, -1 )
      
      data.it[i].vol = GetMediaItemInfo_Value( item, 'D_VOL')
      data.it[i].vol_format = string.format("%.2f", data.it[i].vol)
      
      local dBval = dBFromReaperVal(data.it[i].vol)
      if not tonumber(dBval) then dBval = -math.huge end
      local real = reaper.DB2SLIDER(dBval )/1000
      data.it[i].vol_format = string.format("%.2f", dBval)
      
      data.it[i].lock = GetMediaItemInfo_Value( item, 'C_LOCK')
      data.it[i].mute = GetMediaItemInfo_Value( item, 'B_MUTE')
      data.it[i].loop = GetMediaItemInfo_Value( item, 'B_LOOPSRC') 
       
        
      local take = GetActiveTake(item)
      if take then
        data.it[i].ptr_take = take
        local _, tk_name = GetSetMediaItemTakeInfo_String( take, "P_NAME", '', false )         
        data.it[i].start_offs = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
        data.it[i].start_offs_format = format_timestr_len(data.it[i].start_offs, '', 0, -1 )
        data.it[i].pitch = GetMediaItemTakeInfo_Value( take, 'D_PITCH' )
        data.it[i].pitch_format = string.format("%.2f", data.it[i].pitch)
        data.it[i].name = tk_name
        data.it[i].isMIDI = TakeIsMIDI(take)
        data.it[i].chanmode = GetMediaItemTakeInfo_Value( take, 'I_CHANMODE' )
        data.it[i].preservepitch = GetMediaItemTakeInfo_Value( take, 'B_PPITCH')
        data.it[i].pitchmode = GetMediaItemTakeInfo_Value( take, 'I_PITCHMODE' )>>16
        data.it[i].pitchsubmode = GetMediaItemTakeInfo_Value( take, 'I_PITCHMODE' )&65535
        data.it[i].pan = GetMediaItemTakeInfo_Value( take, 'D_PAN' )
        data.it[i].pan_format = MPL_FormatPan(data.it[i].pan)
      end 
      
      
      if take then 
        if TakeIsMIDI(take) then 
          data.it[i].obj_type_int = 1
          if obj_type then obj_type = 3 else obj_type = 1 end
         else 
          if obj_type then obj_type = 3 else obj_type = 2 end
          data.it[i].obj_type_int = 2
        end
       else
        if obj_type then obj_type = 3 else obj_type = 0 end
        data.it[i].obj_type_int = 0
      end
      
    end
    
    
    --  set obj type 
      if obj_type == 0 then 
          data.obj_type = 'Empty Item'
          data.obj_type_int = 0
       elseif obj_type == 1 then 
          data.obj_type = 'MIDI Item'
          data.obj_type_int = 1
       elseif obj_type == 2 then 
          data.obj_type = 'Audio Item' 
          data.obj_type_int = 2
       elseif obj_type == 3 then 
          data.obj_type = 'Items'
          data.obj_type_int = 3
      end    
  end  
------------------------------------------------------------------------
  function DataUpdate_Envelope(data, env)
    data.name = ''  
    data.ep={}
    data.env_ptr = env
    local tr, env_FXid, env_paramid = Envelope_GetParentTrack( env )
    if tr then 
      data.obj_type = 'Envelope'
      data.obj_type_int = 6
      local _, tr_name = GetTrackName( tr, '' )
      local _, env_name =  GetEnvelopeName( env, '' )
      data.name = tr_name..' | '..env_name
      data.env_parenttr = tr
      data.env_parentFX = env_FXid
      data.env_parentParam = env_paramid
      local retval, buf = TrackFX_GetFXName( tr,  env_FXid, env_paramid )
      data.env_parentFXname = buf
    end    
    
    -- get val limits
      local BR_env = BR_EnvAlloc( env, false )
      local _, _, _, _, _, _, minValue, maxValue = BR_EnvGetProperties( BR_env )
      BR_EnvFree( BR_env, false )
      data.minValue, data.maxValue = minValue, maxValue
    
    local obj_type, first_selected, env_hasselpoint
    for i = 1, CountEnvelopePoints( env ) do      
      local retval, time, value, shape, tension, selected = GetEnvelopePointEx( env, -1, i-1 )
      data.ep[i] = {}
      data.ep[i].pos = time
      data.ep[i].pos_format = format_timestr_pos( time, '', -1 ) 
      data.ep[i].value = value
      data.ep[i].value_format = string.format("%.2f", value)
      data.ep[i].shape = shape
      data.ep[i].tension = tension
      data.ep[i].selected = selected
      if not first_selected and selected then 
        data.ep.sel_point_ID = i
        first_selected = true
      end
      if selected then 
        if env_hasselpoint and env_hasselpoint == 1 then env_hasselpoint = 2 break end
        env_hasselpoint = 1        
      end
    end
    -- reaper.CountAutomationItems( env ) 
       
    --[[if env_hasselpoint == 1 then 
      data.obj_type = 'Envelope point'
      data.obj_type_int = 4  
     elseif env_hasselpoint == 2 then
      data.obj_type = 'Envelope points'
      data.obj_type_int = 5   
     else
      data.obj_type_int = 6
      data.obj_type = 'Envelope'
    end  ]]  
    return true
  end  
  

  --[[-------------------------------------------------
  f unction DataUpdate_Ruler(cur_pos)
    -- tempo/timesig
      local tempomark = FindTempoTimeSigMarker( 0, cur_pos+0.001 )
      if tempomark > 0 then
        local retval, timeposOut, measureposOut, beatposOut, bpmOut, timesig_numOut, timesig_denomOut, lineartempoOut = GetTempoTimeSigMarker( 0, tempomark )
        local diff = math.abs(timeposOut - cur_pos)
        if diff < 0.1 then
          data.obj_type = 'Ruler event' 
          data.obj_type_int = 6
          data.name = ''
          return true      
        end
      end
      
      --markeridxOut retval, regionidxOut reaper.GetLastMarkerAndCurRegion( proj, time )
    
  end

  
  ---------------------------------------------------
  
  ]]
  
  function DataUpdate_Track(data, tr)
    data.name = ''  
    data.tr = {}
    
    data.obj_type = 'Track'
    data.obj_type_int = 7
    if not data.curent_trFXID then data.curent_trFXID = 1 end
    for i = 1, CountSelectedTracks(0) do
      local tr = GetSelectedTrack(0,i-1)
      data.tr[i] = {}
      if i ==1 then
        data.tr[i].fx_names= {}
        local instr = TrackFX_GetInstrument( tr )
        for fxid = 1, TrackFX_GetCount( tr ) do          
          data.tr[i].fx_names[fxid] = {name = MPL_ReduceFXname(({TrackFX_GetFXName( tr, fxid-1, '' )})[2]),
                                        is_instr = instr==fxid-1,
                                        is_enabled =  TrackFX_GetEnabled( tr, fxid-1 )}
        end
      end
      data.tr[i].ptr = tr
      local _, tr_name = GetTrackName( tr, '' )
      local trID = CSurf_TrackToID( tr, false )
      if trID < 1 then trID = '' else trID = trID..': '  end
      data.tr[i].name = trID..tr_name
      data.tr[i].name_proj = tr_name
      data.tr[i].pan = GetMediaTrackInfo_Value( tr, 'D_PAN' )
      data.tr[i].pan_format = MPL_FormatPan(data.tr[i].pan)
      data.tr[i].vol = GetMediaTrackInfo_Value( tr, 'D_VOL' )
      
      --data.tr[i].vol_format = string.format("%.2f", data.tr[i].vol)
      local dBval = dBFromReaperVal(data.tr[i].vol)
      if not tonumber(dBval) then dBval = -math.huge end
      local real = reaper.DB2SLIDER(dBval )/1000
      data.tr[i].vol_format = string.format("%.2f", dBval)
    end
    
    if not data.defsendvol or not data.defsendpan then
      data.defsendvol = tonumber(({BR_Win32_GetPrivateProfileString( 'REAPER', 'defsendvol', '0',  get_ini_file() )})[2])
      data.defsendpan = 0
      data.defsendflag = tonumber(({BR_Win32_GetPrivateProfileString( 'REAPER', 'defsendflag', '0',  get_ini_file() )})[2])
    end
    
    if data.defsendvol then
      local dBval = dBFromReaperVal(data.defsendvol)
      if not tonumber(dBval) then dBval = -math.huge end
      data.defsendvol_format = string.format("%.2f", dBval)
      data.defsendvol_slider = reaper.DB2SLIDER(dBval )/1000
      data.defsendpan_format = MPL_FormatPan(data.defsendpan)
      data.defsendpan_slider = data.defsendpan
    end
    
    -- parse predefined sends
      data.PreDefinedSend_GUID = {}
      local retval, PreDefinedSend_GUID = GetProjExtState( 0, 'MPL_InfoTool', 'PreDefinedSend_GUID' )
      if retval > 0 then
        for GUID in PreDefinedSend_GUID:gmatch('[^%s]+') do data.PreDefinedSend_GUID[GUID] = 1 end
      end
    return true
  end  
