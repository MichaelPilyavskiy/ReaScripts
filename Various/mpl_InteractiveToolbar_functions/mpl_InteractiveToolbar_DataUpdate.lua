-- @description InteractiveToolbar_DataUpdate
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex

  -- update obj/project data for 
  
  
  ---------------------------------------------------
  function DataUpdate(data, mouse, widgets, obj, conf)
    DataUpdate_RulerGrid(data) 
    DataUpdate_TimeSelection(data)
    DataUpdate_PlayState(data)
    DataUpdate_TempoTimeSignature(data)
    DataUpdate_LastTouchedFX(data)
    
    -- reset buttons data
      obj.b = {}
    -- persisten widgets
      obj.persist_margin = Obj_UpdatePersist(data, obj, mouse, widgets) -- MUST be before DataUpdate_Context for passing persist_margin
    -- context widgets  
      DataUpdate_Context(data, mouse, widgets, obj, conf) 
    -- update com butts
      Obj_UpdateCom(data, mouse, obj, widgets, conf) 
    -- reset name if overlap persist
      if obj.b.type_name.x + obj.b.type_name.w > obj.persist_margin then
        obj.b.type_name = nil
        obj.b.obj_name = nil
      end  
  end
  ---------------------------------------------------  
  function DataUpdate_RulerGrid(data)  
    data.rul_format = MPL_GetCurrentRulerFormat()
    data.SR = tonumber(reaper.format_timestr_pos(1, '', 4))
    data.FR = TimeMap_curFrameRate( 0 )
    data.grid_val, data.grid_val_format, data.grid_istriplet = MPL_GetFormattedGrid()
    data.grid_isactive =  GetToggleCommandStateEx( 0, 1157 )==1
  end
  ---------------------------------------------------
  function DataUpdate_Context(data, mouse, widgets, obj, conf)    
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
        
        -8 note
        -9 cc
        -10 ruler evt
        -
    ]]  
    data.obj_type = 'No object selected'
    data.obj_type_int = -1  
    local item = GetSelectedMediaItem(0,0)
    local env = GetSelectedEnvelope( 0 )
    local tr = GetSelectedTrack(0,0)
    --local ME = MIDIEditor_GetActive()
          
    --[[if ME then
      DataUpdate_MIDIEditor(data, ME )
     else
     ]]if env then    
      DataUpdate_Envelope(data, env)
      Obj_UpdateEnvelope(data, obj, mouse, widgets)
     elseif item then 
      DataUpdate_Item(data) 
      Obj_UpdateItem(data, obj, mouse, widgets)
     elseif tr then
      DataUpdate_Track(data, tr)
      Obj_UpdateTrack(data, obj, mouse, widgets)        
    end
  end
  ---------------------------------------------------
  function DataUpdate_TimeSelection(data)
    local TS_st, TSend = GetSet_LoopTimeRange2( 0, false, false, -1, -1, false )
    data.timeselectionstart, data.timeselectionend = TS_st, TSend    
    data.timeselectionstart_format = format_timestr_pos( data.timeselectionstart, '', -1 ) 
    data.timeselectionend_format = format_timestr_pos( data.timeselectionend, '', -1 )
  end
  ---------------------------------------------------
    
  function DataUpdate_PlayState(data)
    local int_playstate = GetPlayStateEx( 0 )
    data.play = int_playstate&1==1
    data.pause = int_playstate&2==2
    data.record = int_playstate&4==4
    data.editcur_pos = GetCursorPositionEx( 0 )
  end
  
  ---------------------------------------------------
    
  function DataUpdate_LastTouchedFX(data)
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
  end
  
  ---------------------------------------------------
  function DataUpdate_TempoTimeSignature(data)
    local int_TM = FindTempoTimeSigMarker( 0, data.editcur_pos )
    data.TempoMarker_ID = int_TM
    if int_TM == -1 then 
      local bpm= Master_GetTempo()
      local _, timesig_num = GetProjectTimeSignature2( 0 )
      local _, _, _, _, timesig_denom = TimeMap2_timeToBeats( 0, 0 )
      data.TempoMarker_timesig1 = math.floor(timesig_num)
      data.TempoMarker_timesig2 = math.floor(timesig_denom)
      data.TempoMarker_bpm= bpm
     else
      local _, timepos, measureposOut, beatposOut, bpm, timesig_num, timesig_denom, lineartempoOut = GetTempoTimeSigMarker( 0, int_TM )
      data.TempoMarker_bpm= bpm
      data.TempoMarker_lineartempochange = lineartempoOut
      data.TempoMarker_timepos = timepos
      data.TempoMarker_timesig_num = timesig_num
      data.TempoMarker_timesig_denom = timesig_denom
      if timesig_num > 0 and timesig_denom > 0  then
        data.TempoMarker_timesig1 = math.floor(timesig_num)
        data.TempoMarker_timesig2 = math.floor(timesig_denom)
       else
        local _, timesig_num = GetProjectTimeSignature2( 0 )
        local _, _, _, _, timesig_denom = TimeMap2_timeToBeats( 0, 0 )
        data.TempoMarker_timesig1 = math.floor(timesig_num)
        data.TempoMarker_timesig2 = math.floor(timesig_denom)
      end
    end
  end
  ---------------------------------------------------
  function DataUpdate_Item(data, item)
    data.name = ''  
    data.it={}
    
    local obj_type
    local cnt_selected = 0
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
      --data.it[i].vol_format = string.format("%.2f", data.it[i].vol)
      
      --local dBval = dBFromReaperVal(data.it[i].vol)
      --if not tonumber(dBval) then dBval = -math.huge end
      --local real = reaper.DB2SLIDER(dBval )/1000
      data.it[i].vol_format = dBFromReaperVal(data.it[i].vol)..'dB'
      
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
        data.it[i].pitch_format = math.floor(data.it[i].pitch *100) / 100
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
          data.obj_type = 'Items ('..#data.it..')'
          data.obj_type_int = 3
      end    
  end  
------------------------------------------------------------------------
  function DataUpdate_Envelope(data, env)
    data.name = ''  
    data.ep={}
    data.env_ptr = env
    local tr, env_FXid, env_paramid = Envelope_GetParentTrack( env )
   
    
    -- get val limits
      local BR_env = BR_EnvAlloc( env, false )
      local _, _, _, _, _, _, minValue, maxValue, centr = BR_EnvGetProperties( BR_env )
      BR_EnvFree( BR_env, false )
      data.minValue, data.maxValue, data.env_defValue= minValue, maxValue, centr
    
    local obj_type, first_selected, env_hasselpoint
    local cnt_selected_pts = 0
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
      if selected then cnt_selected_pts = cnt_selected_pts +1 end
      if not first_selected and selected then 
        data.ep.sel_point_ID = i
        first_selected = true
      end
      --[[if selected then 
        if env_hasselpoint and env_hasselpoint == 1 and not env_hasselpoint == 2 then 
          env_hasselpoint = 2 
        end
        env_hasselpoint = 1        
      end]]
    end
    
    
    if tr then 
      if cnt_selected_pts > 0 then 
         data.obj_type = 'Envelope points ('..cnt_selected_pts..' selected)'
        else 
         data.obj_type = 'Envelope'
      end
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
  -------------------------------------------------
  function DataUpdate_MIDIEditor(data, ME)
    data.name = ''  
    data.ep={}
    data.ME_ptr = ME
    
    data.obj_type = 'MIDI Editor'
    data.obj_type_int = 8
    
    local take= MIDIEditor_GetTake( ME )
    data.take = take 
    local retval, notecnt, ccevtcnt = MIDI_CountEvts( take )
    local obj_type
    data.note = {}
    for i = 1, notecnt do
      --data.note[i] ={table.unpack({MIDI_GetNote( take, i-1 )})}
      data.note[i] ={}
      local _, selected, muted, startppqpos, endppqpos, chan, pitch, vel = MIDI_GetNote( take, i-1 )
      
      data.note[i].selected, data.note[i].muted, data.note[i].startppqpos, data.note[i].endppqpos, data.note[i].chan, data.note[i].pitch, data.note[i].vel = 
      selected, muted, startppqpos, endppqpos, chan, pitch, vel
    end
  end
  ----------------------------------------------------------------------
  function DataUpdate_Track(data, tr)
    data.name = ''  
    data.tr = {}
    local cnt = CountSelectedTracks(0)
    if cnt > 1 then 
      data.obj_type = 'Tracks ('..cnt..')'
     else 
      data.obj_type = 'Track'
    end
    data.obj_type_int = 7
    if not data.curent_trFXID then data.curent_trFXID = 1 end
    for i = 1, cnt do
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
      data.tr[i].vol_format = dBFromReaperVal(data.tr[i].vol)..'dB'
      
      -- get delay
        data.tr[i].delay = 0
        local delayFX_pos = TrackFX_AddByName( tr, 'time_adjustment', false, 0 )
        if delayFX_pos >=0 then
          data.tr[i].delay_FXpos = delayFX_pos
          local val = TrackFX_GetParamNormalized( tr, delayFX_pos, 0 )
          data.tr[i].delay = (val-0.5)*0.2
        end
        data.tr[i].delay_format = format_timestr_len( data.tr[i].delay, '', 0,3 ) 
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
  
