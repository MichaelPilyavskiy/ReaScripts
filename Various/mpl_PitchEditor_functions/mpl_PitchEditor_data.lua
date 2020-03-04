-- @description PitchEditor_data
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex

  
  ---------------------------------------------------  
  function CheckUpdates(obj, conf, refresh)
  
    -- force by proj change state
      obj.SCC =  GetProjectStateChangeCount( 0 ) 
      if not obj.lastSCC then 
        refresh.GUI_onStart = true  
        refresh.data = true
       elseif obj.lastSCC and obj.lastSCC ~= obj.SCC then 
        refresh.data = true
        refresh.GUI = true
        refresh.GUI_WF = true
      end 
      obj.lastSCC = obj.SCC
      
    -- window size
      local ret = HasWindXYWHChanged(obj)
      if ret == 1 then 
        refresh.conf = true 
        --refresh.data = true
        refresh.GUI_onStart = true 
        refresh.GUI_WF = true       
       elseif ret == 2 then 
        refresh.conf = true
        --refresh.data = true
      end
  end
  ------------------------------------------------------------------  
  function Data_GetTake(conf, obj, data, refresh, mouse) 
    data.has_data = false
    local it = GetSelectedMediaItem(0,0)
    if not it then return end
    data.parent_trptr =  GetMediaItem_Track( it)
    data.it_ptr = it
    data.it_pos = GetMediaItemInfo_Value( it, 'D_POSITION' )
    data.it_len = GetMediaItemInfo_Value( it, 'D_LENGTH' )
    data.it_tk = GetActiveTake(it)
    if TakeIsMIDI(data.it_tk) then return end
    data.it_tkGUID = BR_GetMediaItemTakeGUID( data.it_tk )
    data.it_tksoffs = GetMediaItemTakeInfo_Value( data.it_tk, 'D_STARTOFFS' )
    data.it_tkrate = GetMediaItemTakeInfo_Value( data.it_tk, 'D_PLAYRATE' )
    data.src = GetMediaItemTake_Source( data.it_tk )
    data.srclen = GetMediaSourceLength( data.src )
    data.src_SR =  GetMediaSourceSampleRate( data.src )
    data.has_data = true
    
    if data.lastit_tkGUID and data.lastit_tkGUID ~= data.it_tkGUID then
      conf.GUI_zoom = 1
      conf.GUI_scroll = 0
      conf.GUI_zoomY = 1
      conf.GUI_scrollY = 0
      refresh.conf = true
    end
    data.lastit_tkGUID = data.it_tkGUID
    return true
  end
  ---------------------------------------------------     
  function Data_SetScrollZoom(conf, obj, data, refresh, mouse) 
    local new_scroll, new_zoom, mouse_pos, cur_pos
    if mouse.wheel_trig ~= 0 then 
    
      -- H zoom/scroll
      if mouse.Ctrl_state == false then
        local inc = 0.1
        local mult = mouse.wheel_trig / math.abs(mouse.wheel_trig)
        
        mouse_pos = (mouse.x-obj.peak_area.x) / obj.peak_area.w
        cur_pos = mouse_pos*conf.GUI_zoom + conf.GUI_scroll 
        
        new_zoom = lim(conf.GUI_zoom * (1-inc*mult), 0.1, 1)
        new_scroll =lim(cur_pos - mouse_pos*new_zoom, 0, 1-new_zoom)
        
        conf.GUI_zoom = new_zoom
        conf.GUI_scroll = new_scroll
        refresh.data_minor = true
        refresh.GUI = true
        refresh.conf = true
      end
      
      -- V zoom/scroll
      if mouse.Ctrl_state == true then
        local inc = 0.1
        local mult = mouse.wheel_trig / math.abs(mouse.wheel_trig)
        
        mouse_pos = (mouse.y-obj.peak_area.y) / obj.peak_area.h
        cur_pos = mouse_pos*conf.GUI_zoomY + conf.GUI_scrollY
        
        new_zoom = lim(conf.GUI_zoomY * (1-inc*mult), conf.minzoomY, 1)
        new_scroll =lim(cur_pos - mouse_pos*new_zoom, 0, 1-new_zoom)
        
        conf.GUI_zoomY = new_zoom
        conf.GUI_scrollY = new_scroll
        refresh.data_minor = true
        refresh.GUI = true
        refresh.conf = true
      end
      
    end
  end
  ------------------------------------------------------------------
  function Data_SetPitchExtStateParams(conf, obj, data, refresh, mouse)
    SetProjExtState( 0, conf.ES_key, 'buf_GUID', data.it_tkGUID )
  
    SetProjExtState( 0, conf.ES_key, 'buf_overlap', conf.overlap)
    SetProjExtState( 0, conf.ES_key, 'buf_lowRMSlimit_dB', conf.lowRMSlimit_dB)
    SetProjExtState( 0, conf.ES_key, 'buf_window_step', conf.window_step)
    SetProjExtState( 0, conf.ES_key, 'buf_minF', conf.minF )
    SetProjExtState( 0, conf.ES_key, 'buf_maxF', conf.maxF )
    SetProjExtState( 0, conf.ES_key, 'buf_maxlen', conf.max_len )
    SetProjExtState( 0, conf.ES_key, 'buf_YINthresh', conf.YINthresh )
  end
  ------------------------------------------------------------------
  function Data_SetPitchExtState (conf, obj, data, refresh, mouse)  
  --pos, freq, RMS, trig_note = line:match('PT ([%.%-%d]+) ([%.%d]+) ([%.%d]+) ([%d]+)')
    local ret, str = GetProjExtState( 0, conf.ES_key, data.it_tkGUID )
    local str_out = str:match('(.-<POINTDATA)')
    str_out = str_out..'\n'
    for i = 1, #data.extpitch do
      str_out = str_out..'PT '
        ..i..' '
        ..data.extpitch[i].pos..' '
        ..data.extpitch[i].freq..' '
        ..data.extpitch[i].RMS..' '
        ..data.extpitch[i].noteOn..' '
        ..data.extpitch[i].pitch_shift..' '
        ..data.extpitch[i].RMS_pitch..' '
        ..data.extpitch[i].len_blocks..' '
        ..data.extpitch[i].mod_pitch..' '
        ..'\n'
    end
    str_out = str_out..'>'
    local rpd = str_out:match('RAWPITCHDATA%s+(%d+)')
    if not rpd then 
      str_out = str_out:gsub('<POINTDATA', 'RAWPITCHDATA 0\n<POINTDATA')
     else
      str_out = str_out:gsub('RAWPITCHDATA%s+(%d+)', 'RAWPITCHDATA 0')
    end
    SetProjExtState( 0, conf.ES_key, data.it_tkGUID, str_out, true )
    --msg(str_out:sub(-1000))
  end
  ------------------------------------------------------------------
  function Data_ResetPitchChanges(conf, obj, data, refresh, mouse)
    for i = 1, #data.extpitch do
      data.extpitch[i].pitch_shift = 0
    end  
  end
  ------------------------------------------------------------------
  function Data_PostProcess(conf, obj, data, refresh, mouse)
    Data_PostProcess_ClearStuff(conf, obj, data, refresh, mouse)
    Data_PostProcess_ClearMod(conf, obj, data, refresh, mouse)
    Data_PostProcess_GetNotes(conf, obj, data, refresh, mouse)
    Data_PostProcess_CalcRMSPitch(conf, obj, data, refresh, mouse)
  end
  -----------------------------
  function Data_PostProcess_ClearMod(conf, obj, data, refresh, mouse)
    for i = 1, #data.extpitch do
      data.extpitch[i].mod_pitch = 0.5
    end
  end
  -----------------------------
  function Data_PostProcess_ClearStuff(conf, obj, data, refresh, mouse)
    for i = 1, #data.extpitch do
      if i == 1 then data.extpitch[i].noteOn = 1 else data.extpitch[i].noteOn = 0 end
      data.extpitch[i].RMS_pitch = -1
      data.extpitch[i].pitch_shift = 0
      data.extpitch[i].len_blocks = 0
    end
  end
  ----------------------------- 
  function Data_PostProcess_GetNotes(conf, obj, data, refresh, mouse)
    local last_noteon_id, last_RMS, last_pos, last_pitch
    if #data.extpitch < 2 then return end
    for i = 1, #data.extpitch do
      local cur_pitch = data.extpitch[i].pitch
      local pos = data.extpitch[i].pos
      local RMS = data.extpitch[i].RMS
      
      -- trigger first noteOn
      if i == 1 then 
        data.extpitch[i].noteOn = 1
        last_noteon_id = i
      end
      
      -- middle stuff
      if i > 1 and i < #data.extpitch then 
        if math.abs(cur_pitch - last_pitch) > conf.post_note_diff 
          or (last_RMS and RMS - last_RMS > conf.RMS_diff_linear)
          or (last_pos and pos - last_pos > data.extpitch_WINDOW)
          then
          if last_noteon_id and i-last_noteon_id > conf.min_block_len then
            data.extpitch[i].noteOn = 1--lim(i-conf.noteoff_offsetblock,1,#data.extpitch)
            last_noteon_id = i
          end
        end 
      end
            
      last_RMS = RMS
      last_pos = pos
      last_pitch = cur_pitch
    end
  end
  ------------------------------------------------------------------
  function Data_PostProcess_CalcRMSPitch(conf, obj, data, refresh, mouse)
    local RMS_pitch, RMS_pitch_cnt, last_noteon_id = 0, 0
    for i = 1, #data.extpitch do
      if data.extpitch[i].noteOn == 1 then 
      
        if last_noteon_id then
          data.extpitch[last_noteon_id].RMS_pitch= RMS_pitch / RMS_pitch_cnt--Data_PostProcess_CalcRMSPitch_sub(conf, obj, data, refresh, mouse, last_noteon_id, RMS_pitch / RMS_pitch_cnt, RMS_pitch_cnt)
          data.extpitch[last_noteon_id].len_blocks = RMS_pitch_cnt
        end
        
        RMS_pitch = 0
        RMS_pitch_cnt = 0
        last_noteon_id = i 
      end
    
      RMS_pitch = RMS_pitch + data.extpitch[i].pitch
      RMS_pitch_cnt = RMS_pitch_cnt + 1
      
      if i == #data.extpitch then
        if last_noteon_id then
          data.extpitch[last_noteon_id].RMS_pitch= RMS_pitch / RMS_pitch_cnt--Data_PostProcess_CalcRMSPitch_sub(conf, obj, data, refresh, mouse, last_noteon_id, RMS_pitch / RMS_pitch_cnt, RMS_pitch_cnt)
          data.extpitch[last_noteon_id].len_blocks = RMS_pitch_cnt
        end      
      end
      
    end 
  end
  ------------------------------------------------------------------
  function Data_PostProcess_CalcRMSPitch_sub(conf, obj, data, refresh, mouse, last_noteon_id, RMS_pitch, len_blocks)
    local RMS_pitch_tested= RMS_pitch
    local RMS_pitch_tested_cnt = 0
    for i = last_noteon_id, last_noteon_id + len_blocks-1 do
      if math.abs(data.extpitch[i].pitch-RMS_pitch) <= conf.secondpassRMSpitch then
        RMS_pitch_tested = RMS_pitch_tested + data.extpitch[i].pitch
        RMS_pitch_tested_cnt = RMS_pitch_tested_cnt + 1
      end
    end
    if RMS_pitch_tested_cnt > 1 then 
      return RMS_pitch_tested / RMS_pitch_tested_cnt
     else
      return RMS_pitch
    end
  end
  ------------------------------------------------------------------
  function Data_SplitNote(conf, obj, data, refresh, mouse, idx, pos_sec) 
    if not data.extpitch[idx] then return end
    local par_block = Data_GetParentBlockId(data, idx)
    for i = par_block+1, par_block + data.extpitch[idx].len_blocks do
      if data.extpitch[i].pos>=pos_sec  and  data.extpitch[i+1].pos<=pos_sec +data.extpitch_WINDOW then
        data.extpitch[i].noteOn = 1
        return
      end
    end
  end
  ------------------------------------------------------------------
  function Data_JoinNote(conf, obj, data, refresh, mouse, idx, pos_sec) 
    if not data.extpitch[idx] then return end
    local par_block = Data_GetParentBlockId(data, idx)
    data.extpitch[par_block].noteOn = 0
  end
  
  ------------------------------------------------------------------
  function Data_GetPitchExtState (conf, obj, data, refresh, mouse) 
    local lastpos  , xpos
    local tol = 0.2
    if not data.extpitch_refresh and (data.extpitch_GUID and data.extpitch_GUID == data.it_tkGUID) then return end
    data.extpitch = {}
    data.extpitch_refresh = false
    data.extpitch_GUID = data.it_tkGUID
    local idx = 1
    local ret, str = GetProjExtState( 0, conf.ES_key, data.it_tkGUID )
    --msg(str:sub(0,300))
    if ret < 1 then return end
    data.extpitch_WINDOW = tonumber(str:match('WINDOW%s+([%.%d]+)'))
    data.extpitch_BUFSZ = tonumber(str:match('BUFSZ%s+(%d+)'))
    local raw = str:match('RAWPITCHDATA%s+(%d+)')
    local is_raw =  not raw or (raw and tonumber(raw) and tonumber(raw) == 1) 
    
    
    local soffs= data.it_tksoffs
    if soffs >= data.it_len then soffs = soffs - data.srclen end
    
    for line in str:gmatch('[^\r\n]+') do
      if line:match('PT') then
        local t = {}
        for val in line:gmatch('[%.%-%d]+') do t[#t+1] = tonumber(val) end
        local id, pos, 
              freq, 
              RMS, 
              noteOn, 
              pitch_shift,
              RMS_pitch,
              len_blocks,
              mod_pitch= t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8], t[9]
        
        if not RMS then RMS = 0 end
        if not noteOn then noteOn = 0 end
        if not RMS_pitch then RMS_pitch = -1 end
        if not len_blocks then len_blocks = 0 end
        if is_raw then noteOn = 0 end
        if not pitch_shift then pitch_shift = 0 end
        if not mod_pitch then mod_pitch = 0.5 end
        local pitch = lim(69 + 12*math.log(freq/440,2),0,127)
        if data.it_pos and data.it_len and data.it_tksoffs then xpos =  (pos-soffs) / (data.it_len)  end
        data.extpitch[idx]  = {pos=pos, 
                              freq=tonumber(freq), 
                              pitch = pitch,
                              RMS=tonumber(RMS),
                              noteOn = noteOn,
                              xpos = xpos,
                              pitch_shift = pitch_shift,
                              len_blocks = len_blocks,
                              RMS_pitch = RMS_pitch,
                              mod_pitch = mod_pitch}
        idx = idx +1
        lastpos= pos
      end   
    end
    return is_raw
  end
  ------------------------------------------------------------------
  function Data_GetTakePeaks(conf, obj, data, refresh, mouse) 
    data.peaks = {}
    
    if not ValidatePtr2( 0, data.it_tk, 'MediaItem_Take*' ) then return end
    local idx = 0
    local w_step = math.max((data.it_len*conf.GUI_zoom) /obj.peak_area.w, .001)
    
    local accessor =  CreateTrackAudioAccessor(  data.parent_trptr )
    local max_peak = 0
    
    for seek_pos = data.it_pos+ data.it_len*conf.GUI_scroll, data.it_pos+ data.it_len*conf.GUI_scroll
      +data.it_len*conf.GUI_zoom, w_step do
      local buf = new_array(2);
      local rv = GetMediaItemTake_Peaks( data.it_tk,--take, 
                                        200,--peakrate, 
                                        seek_pos,--starttime, 
                                        1,--numchannels, 
                                        1,--numsamplesperchannel, 
                                        0,--115,--want_extra_type, 
                                        buf )
      if rv then
        idx = idx +1
        max_peak = math.max(max_peak, math.abs(buf[1]))
        data.peaks[idx] = {spl_pos= seek_pos,
                         peak = math.abs(buf[1])
                         }                                       
      
       else 
        break 
      end
    
    end
    DestroyAudioAccessor( accessor )
    
    for i = 1,  #data.peaks do data.peaks[i].peak = data.peaks[i].peak / max_peak end
    return true
  end
  function Data_GetParentBlockId(data, idx)
    for i = idx, 1, -1 do
      if data.extpitch[i].noteOn == 1 then return i end
    end
  end
  ------------------------------------------------------------------
  function Data_ApplyPitchToTake(conf, obj, data, refresh, mouse) 
    local take = data.it_tk
    local t_edit_prev
    local envelope =  GetTakeEnvelopeByName( take, 'Pitch' )
    if not envelope or not ValidatePtr2(0, envelope, 'TrackEnvelope*') then 
      Action(41612) --Take: Toggle take pitch envelope
      return
    end
    DeleteEnvelopePointRange( envelope, 0,data.it_len)
    local last_pitch
    for idx = 1, #data.extpitch do
      local t_edit = data.extpitch[idx]
      if idx > 1 then t_edit_prev = data.extpitch[idx-1] end
      local parent = Data_GetParentBlockId(data, idx) 
      local parRMSpitch = data.extpitch[parent].RMS_pitch
      local curpitch = data.extpitch[idx].pitch
      local pitch = data.extpitch[idx].pitch_shift - 2*(data.extpitch[parent].mod_pitch-0.5)*(parRMSpitch-curpitch)
        
      if not last_pitch or  (last_pitch and  last_pitch ~= pitch) then
        if last_pitch then 
          InsertEnvelopePoint( envelope, t_edit_prev.pos - data.it_tksoffs, last_pitch, 0, 0, false, true ) 
        end
        InsertEnvelopePoint( envelope, t_edit.pos - data.it_tksoffs, pitch, 0, 0, false, true )
      end
      last_pitch = pitch
    end
    Envelope_SortPointsEx( envelope, -1 )
  end
  ------------------------------------------------------------------
  function Data_DumpToMIDI(conf, obj, data, refresh, mouse)
    local tr_idx =  CSurf_TrackToID( data.parent_trptr, false )
    --InsertTrackAtIndex( tr_idx, false )
    local new_tr = GetTrack(0,tr_idx)
    local item  =  CreateNewMIDIItemInProj( new_tr, data.it_pos, data.it_pos+data.it_len, false )
    local take = GetActiveTake(item)
    --MIDI_SetItemExtents( item,  TimeMap_timeToQN( data.it_pos ),  TimeMap_timeToQN( data.it_pos+data.it_len ) )
    local MIDI_chan = 1
    if take then
      local str = ''
      local last_ppq = 0
      local ppq = 0
      
      for idx = 1, #data.extpitch do 
        local par_note = data.extpitch[idx].idx_noteon
        
        local par_note_pitch = math.floor(data.extpitch[par_note].RMS_pitch)
        local par_note_shift = data.extpitch[par_note].pitch_shift  
        
        local noteOn = data.extpitch[idx].noteOn
        if last_noteOn == 0 and noteOn == 1 and noteOn_idx then
          startppqpos = MIDI_GetPPQPosFromProjTime( take, data.extpitch[noteOn_idx].pos + data.it_pos - data.it_tksoffs )
          endppqpos = MIDI_GetPPQPosFromProjTime( take, data.extpitch[idx].pos + data.it_pos - data.it_tksoffs )
          str_per_msg = string.pack("i4Bi4BBB", math.floor(startppqpos - last_ppq), 0, 3, 0x90| MIDI_chan-1, par_note_pitch, 120 ) -- noteOn
          str = str..str_per_msg
          str_per_msg = string.pack("i4Bi4BBB", math.floor(endppqpos - startppqpos), 0, 3, 0x80| MIDI_chan-1, par_note_pitch, 0 )
          str = str..str_per_msg
          ppq = endppqpos
          --MIDI_InsertNote( take, false, false, startppqpos, endppqpos, MIDI_chan, pitch, vel, true )
        end
        
        
        if noteOn == 1 then 
          noteOn_idx = idx  
          --[[
         else
          local out_val_12f = data.extpitch[idx].pitch + data.extpitch[idx].pitch_shift - par_note_pitch
          out_val = math.floor(2^13 * (out_val_12f/12) + 2^13)
          low = out_val & 0x7F
          high = (out_val >> 7) & 0x7F
          pw_ppq = math.floor(MIDI_GetPPQPosFromProjTime( take, data.extpitch[idx].pos + data.it_pos - data.it_tksoffs ))
          str = str..string.pack("i4Bi4BBB", math.floor(pw_ppq - last_ppq), 0, 3, 0xE0| MIDI_chan-1, low, high, 0)
          ppq = pw_ppq
        ]]
        end
        
        last_noteOn = noteOn
        last_ppq = ppq
      end
      str = str..string.pack("i4Bi4BBB", math.floor(MIDI_GetPPQPosFromProjTime( take, data.it_pos + data.it_len) - last_ppq), 0, 3, 0xB0, 123, 0)
      MIDI_SetAllEvts(take, str)
      --MIDI_Sort(take)
    end
    UpdateArrange()
  end
  ------------------------------------------------------------------
  function Data_Update (conf, obj, data, refresh, mouse) 
    data.zoomlev = GetHZoomLevel()
    local ret = Data_GetTake(conf, obj, data, refresh, mouse) 
    if ret then data.has_take = true end
    if data.has_take == true  then 
      Data_GetTakePeaks(conf, obj, data, refresh, mouse) 
      local is_raw = Data_GetPitchExtState(conf, obj, data, refresh, mouse) 
      if is_raw then 
        Data_PostProcess(conf, obj, data, refresh, mouse) 
        if refresh.data_minor == false then 
          Data_SetPitchExtState (conf, obj, data, refresh, mouse)  
        end
      end
    end
  end
  


