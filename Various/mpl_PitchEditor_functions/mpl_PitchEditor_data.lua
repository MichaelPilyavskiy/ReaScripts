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
    
    return true
  end
  ---------------------------------------------------     
  function Data_SetScrollZoom(conf, obj, data, refresh, mouse) 
    if mouse.wheel_trig ~= 0 then 
    
      -- H zoom/scroll
      if mouse.Ctrl_state == false then
        local inc = 0.1
        local mult = mouse.wheel_trig / math.abs(mouse.wheel_trig)
        
        mouse_pos = (mouse.x-obj.peak_area.x) / obj.peak_area.w
        cur_pos = mouse_pos*data.GUI_zoom + data.GUI_scroll 
        
        new_zoom = lim(data.GUI_zoom * (1-inc*mult), 0.2, 1)
        new_scroll =lim(cur_pos - mouse_pos*new_zoom, 0, 1-new_zoom)
        
        data.GUI_zoom = new_zoom
        data.GUI_scroll = new_scroll
        refresh.data = true
        refresh.GUI = true
      end
      
      -- V zoom/scroll
      if mouse.Ctrl_state == true then
        local inc = 0.1
        local mult = mouse.wheel_trig / math.abs(mouse.wheel_trig)
        
        mouse_pos = (mouse.y-obj.peak_area.y) / obj.peak_area.h
        cur_pos = mouse_pos*data.GUI_zoomY + data.GUI_scrollY
        
        new_zoom = lim(data.GUI_zoomY * (1-inc*mult), 0.2, 1)
        new_scroll =lim(cur_pos - mouse_pos*new_zoom, 0, 1-new_zoom)
        
        data.GUI_zoomY = new_zoom
        data.GUI_scrollY = new_scroll
        refresh.data = true
        refresh.GUI = true
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
    SetProjExtState( 0, conf.ES_key, 'buf_freqdiff_octshift', conf.freqdiff_octshift  ) 
    SetProjExtState( 0, conf.ES_key, 'buf_TDslice_minwind', conf.TDslice_minwind  )
    SetProjExtState( 0, conf.ES_key, 'buf_TDfreq', conf.TDfreq  )
  end
  ------------------------------------------------------------------
  function Data_SetPitchExtState (conf, obj, data, refresh, mouse)  
  --pos, freq, RMS, trig_note = line:match('PT ([%.%-%d]+) ([%.%d]+) ([%.%d]+) ([%d]+)')
    local ret, str = GetProjExtState( 0, conf.ES_key, data.it_tkGUID )
    str_out = str:match('(.-<POINTDATA)')
    str_out = str_out..'\n'
    for i = 1, #data.extpitch do
      str_out = str_out..'PT '
        ..data.extpitch[i].pos..' '
        ..data.extpitch[i].freq..' '
        ..data.extpitch[i].RMS..' '
        ..data.extpitch[i].noteOn..' '
        ..data.extpitch[i].pitch_shift..'\n'
    end
    str_out = str_out..'>'
    SetProjExtState( 0, conf.ES_key, data.it_tkGUID, str_out, true )
    --msg(str_out:sub(5000,7000))
  end
  ------------------------------------------------------------------
  function Data_GetPitchExtState (conf, obj, data, refresh, mouse)   
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
    
    local RMS_pitch = 0
    local RMS_pitch_cnt = 0
    local idx_noteon
    local soffs= data.it_tksoffs
    if soffs >= data.it_len then soffs = soffs - data.srclen end
    local lastpos =0
    
    for line in str:gmatch('[^\r\n]+') do
      if line:match('PT') then
        --local pos, freq, RMS, trig_note = line:match('PT ([%.%-%d]+) ([%.%d]+) ([%.%d]+) ([%d]+)')
        local t = {}
        for val in line:gmatch('[%.%-%d]+') do t[#t+1] = tonumber(val) end
        local pos, 
              freq, 
              RMS, 
              noteOn, 
              pitch_shift = t[1], t[2], t[3], t[4], t[5]
        if not pitch_shift then pitch_shift = 0 end
        local pitch = lim(69 + 12*math.log(freq/440,2),0,127)
        local prev_noteOff = 0
        --if (last_noteOn_pos and pos - last_noteOn_pos > data.extpitch_WINDOW) then noteOn = 1 end        
        
        if noteOn ~= 1 then
          RMS_pitch = RMS_pitch + pitch
          RMS_pitch_cnt = RMS_pitch_cnt +1
         else 
          --if idx_noteon - idx == 1 then data.extpitch[idx_noteon].RMS_pitch = pitch end
          if idx_noteon then 
            data.extpitch[idx_noteon].xpos2 = (pos-soffs) / (data.it_len)
            data.extpitch[idx_noteon].RMS_pitch = RMS_pitch / RMS_pitch_cnt 
          end
          idx_noteon = idx
          RMS_pitch = pitch
          RMS_pitch_cnt = 1
        end
        local xpos = 0
        if data.it_pos and data.it_len and data.it_tksoffs then
          xpos =  (pos-soffs) / (data.it_len) 
        end
        data.extpitch[idx]  = {pos=pos, 
                              freq=tonumber(freq), 
                              pitch = pitch,
                              RMS=tonumber(RMS),
                              noteOn = noteOn,
                              xpos = xpos,
                              pitch_shift = pitch_shift,
                              idx_noteon = idx_noteon}
        idx = idx +1
        lastpos= pos
      end  
      
      if data.extpitch[idx_noteon] then 
        data.extpitch[idx_noteon].xpos2 = (lastpos-soffs) / (data.it_len)
        data.extpitch[idx_noteon].RMS_pitch = RMS_pitch / RMS_pitch_cnt 
      end
         
    end
  end
  ------------------------------------------------------------------
  function Data_GetTakePeaks(conf, obj, data, refresh, mouse) 
    data.peaks = {}
    
    if not ValidatePtr2( 0, data.it_tk, 'MediaItem_Take*' ) then return end
    local idx = 0
    local w_step = math.max((data.it_len*data.GUI_zoom) /obj.peak_area.w, .001)
    
    local accessor =  CreateTrackAudioAccessor(  data.parent_trptr )
    
    for seek_pos = data.it_pos+ data.it_len*data.GUI_scroll, data.it_pos+ data.it_len*data.GUI_scroll
      +data.it_len*data.GUI_zoom, w_step do
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
        data.peaks[idx] = {spl_pos= seek_pos,
                         peak = buf[1]
                         }                                       
      
       else 
        break 
      end
    
    end
    DestroyAudioAccessor( accessor )
    return true
  end
  ------------------------------------------------------------------
  function Data_ApplyPitchToTake(conf, obj, data, refresh, mouse) 
    local take = data.it_tk
    local envelope =  GetTakeEnvelopeByName( take, 'Pitch' )
    if not envelope or not ValidatePtr2(0, envelope, 'TrackEnvelope*') then 
      Action(41612) --Take: Toggle take pitch envelope
    end
    DeleteEnvelopePointRange( envelope, 0,data.it_len)
    for idx = 1, #data.extpitch do
      local t_edit = data.extpitch[idx]
      local par_note = data.extpitch[idx].idx_noteon
      local par_note_shift = data.extpitch[par_note].pitch_shift
      InsertEnvelopePoint( envelope, t_edit.pos - data.it_tksoffs, par_note_shift, 0, 0, false, true )
    end
    Envelope_SortPointsEx( envelope, -1 )
  end
  ------------------------------------------------------------------
  function Data_Update (conf, obj, data, refresh, mouse) 
    data.zoomlev = GetHZoomLevel()
    data.cur_pos = GetCursorPosition()
    local ret = Data_GetTake(conf, obj, data, refresh, mouse) 
    if ret then data.has_take = true end
    if data.has_take == true and (refresh.data or refresh.data_minor) then 
      Data_GetTakePeaks(conf, obj, data, refresh, mouse) 
      Data_GetPitchExtState(conf, obj, data, refresh, mouse) 
      refresh.data_minor = nil
    end
  end
  


