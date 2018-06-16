-- @description RS5k_manager_data
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
        --if conf.dev_mode == 1 then msg(obj.SCC..'2') end
        refresh.data = true
        refresh.GUI = true
        refresh.GUI_WF = true
      end 
      obj.lastSCC = obj.SCC
      
    -- window size
      local ret = HasWindXYWHChanged(obj)
      if ret == 1 then 
        refresh.conf = true 
        refresh.data = true
        refresh.GUI_onStart = true 
        refresh.GUI_WF = true       
       elseif ret == 2 then 
        refresh.conf = true
        refresh.data = true
      end
  end
  ---------------------------------------------------
  function GetRS5kData(data, tr) 
    for fxid = 1,  TrackFX_GetCount( tr ) do
      -- validate RS5k by param names
      local retval, p3 = TrackFX_GetParamName( tr, fxid-1, 3, '' )
      local retval, p4 = TrackFX_GetParamName( tr, fxid-1, 4, '' )
      local isRS5k = retval and p3:match('range')~= nil and p4:match('range')~= nil
      if not isRS5k then goto skipFX end
      local MIDIpitch = math.floor(TrackFX_GetParamNormalized( tr, fxid-1, 3)*128)
      local retval, fn = TrackFX_GetNamedConfigParm( tr, fxid-1, 'FILE' )
      if not data[MIDIpitch] then data[MIDIpitch] = {} end
      local int_col = GetTrackColor( tr )
      if int_col == 0 then int_col = nil end
      local MIDI_name = GetTrackMIDINoteNameEx( 0, tr, MIDIpitch, 1)
      data[MIDIpitch] [#data[MIDIpitch]+1] = {rs5k_pos = fxid-1,
                        pitch    =math.floor(({TrackFX_GetFormattedParamValue( tr, fxid-1, 3, '' )})[2]),
                        MIDIpitch_normal =        TrackFX_GetParamNormalized( tr, fxid-1, 3),
                        pitch_semitones =    ({TrackFX_GetFormattedParamValue( tr, fxid-1, 15, '' )})[2],
                        pitch_offset =        TrackFX_GetParamNormalized( tr, fxid-1, 15),
                        gain=                 TrackFX_GetParamNormalized( tr, fxid-1, 0),
                        gain_dB =           ({TrackFX_GetFormattedParamValue( tr, fxid-1, 0, '' )})[2],
                        trackGUID =           GetTrackGUID( tr ),
                        pan=                  TrackFX_GetParamNormalized( tr, fxid-1,1),
                        attack =              TrackFX_GetParamNormalized( tr, fxid-1,9),
                        attack_ms =         ({TrackFX_GetFormattedParamValue( tr, fxid-1, 9, '' )})[2],
                        decay =              TrackFX_GetParamNormalized( tr, fxid-1,24),
                        decay_ms =         ({TrackFX_GetFormattedParamValue( tr, fxid-1, 24, '' )})[2],  
                        sust =              TrackFX_GetParamNormalized( tr, fxid-1,25),
                        sust_dB =         ({TrackFX_GetFormattedParamValue( tr, fxid-1, 25, '' )})[2],
                        rel =              TrackFX_GetParamNormalized( tr, fxid-1,10),
                        rel_ms =         ({TrackFX_GetFormattedParamValue( tr, fxid-1, 10, '' )})[2],   
                        sample = fn ,
                        sample_short =    GetShortSmplName(fn),
                        GUID =            TrackFX_GetFXGUID( tr, fxid-1 ) ,
                        src_track = tr  ,
                        src_track_col = int_col,
                        offset_start =      TrackFX_GetParamNormalized( tr, fxid-1, 13)   ,      
                        offset_end =      TrackFX_GetParamNormalized( tr, fxid-1, 14)   ,    
                        bypass_state =    TrackFX_GetEnabled(tr, fxid-1)   , 
                        MIDI_name =        MIDI_name                 
                        }
      ::skipFX::
    end  
    -- force solo state
    local glob_bypass_state_cnt = 0
    local glob_sol
    for MIDIpitch =0, 128 do
      if data[MIDIpitch] then
      
        if data[MIDIpitch][1] and data[MIDIpitch][1].bypass_state == true then
          glob_bypass_state_cnt  = glob_bypass_state_cnt+1
          glob_sol = MIDIpitch
        end
        
        local bypass_state_cnt = 0
        local sol_spl
        for spl = 1, #data[MIDIpitch] do
          if data[MIDIpitch][spl].bypass_state == true then 
            bypass_state_cnt  = bypass_state_cnt+1
            sol_spl = spl
          end
        end
        if bypass_state_cnt == 1 and sol_spl and #data[MIDIpitch] > 1 then
          data[MIDIpitch][sol_spl].solo_state = true
        end
      end
    end
    if glob_bypass_state_cnt == 1 and glob_sol and #data>1  then  data[glob_sol].solo_state = true end
    
    
  end
  
  ---------------------------------------------------
  function SetRS5kData(data, conf, track, note, spl_id) 
    if not spl_id then spl_id = 1 end
    if data[note][spl_id] then 
        local rs5k_pos = TrackFX_AddByName( track, 'ReaSamplomatic5000', false, -1 )                
        TrackFX_SetNamedConfigParm(  track, rs5k_pos, 'FILE0', data[note][spl_id].sample)
        TrackFX_SetNamedConfigParm(  track, rs5k_pos, 'DONE', '')  
        
        TrackFX_SetParamNormalized( track, rs5k_pos, 0, data[note][spl_id].gain) -- gain
        TrackFX_SetParamNormalized( track, rs5k_pos, 1, data[note][spl_id].pan) -- pan
        
        TrackFX_SetParamNormalized( track, rs5k_pos, 2, 0) -- gain for min vel
        TrackFX_SetParamNormalized( track, rs5k_pos, 3, data[note][spl_id].MIDIpitch_normal ) -- note range start
        TrackFX_SetParamNormalized( track, rs5k_pos, 4, data[note][spl_id].MIDIpitch_normal ) -- note range end
        TrackFX_SetParamNormalized( track, rs5k_pos, 5, 0.5 ) -- pitch for start
        TrackFX_SetParamNormalized( track, rs5k_pos, 6, 0.5 ) -- pitch for end
        
        TrackFX_SetParamNormalized( track, rs5k_pos, 8, 0 ) -- max voices = 0
        TrackFX_SetParamNormalized( track, rs5k_pos, 11, 0 ) -- obey note offs
                
        TrackFX_SetParamNormalized( track, rs5k_pos, 9, data[note][spl_id].attack ) -- adsr
        TrackFX_SetParamNormalized( track, rs5k_pos, 24, data[note][spl_id].decay )
        TrackFX_SetParamNormalized( track, rs5k_pos, 25, data[note][spl_id].sust )
        TrackFX_SetParamNormalized( track, rs5k_pos, 10, data[note][spl_id].rel )
        
        TrackFX_SetParamNormalized( track, rs5k_pos, 13, data[note][spl_id].offset_start ) -- attack
        TrackFX_SetParamNormalized( track, rs5k_pos, 14, data[note][spl_id].offset_end ) -- obey note offs   
      end
  end  
  ---------------------------------------------------
  function GetSampleNameByNote(data, note)
    local str = ''
    for key in pairs(data) do
      if key == note then 
        --local fn = ''
        --for i = 1, #data[key] do
          local fn = GetShortSmplName(data[key][1].fn)
          local fn_full = data[key][1].fn          
        --end
        if not fn then fn = fn_full end
        return fn, true, fn_full
      end
    end
    return str
  end

  ---------------------------------------------------
  function Data_Update(conf, obj, data, refresh, mouse, pat)
    local tr = GetSelectedTrack(0,0)
    if not tr  then return end
    data.parent_track = tr
    GetRS5kData(data, tr)
    for sid = 1,  GetTrackNumSends( tr, 0 ) do
      local srcchan = GetTrackSendInfo_Value( tr, 0, sid-1, 'I_SRCCHAN' )
      local dstchan = GetTrackSendInfo_Value( tr, 0, sid-1, 'I_DSTCHAN' )
      local midiflags = GetTrackSendInfo_Value( tr, 0, sid-1, 'I_MIDIFLAGS' )
      if srcchan == -1 and dstchan ==0 and midiflags == 0 then
        local desttr = BR_GetMediaTrackSendInfo_Track( tr, 0, sid-1, 1 )
        GetRS5kData(data, desttr)
      end
    end
  end 

  ---------------------------------------------------------------------------------------------------------------------
  function GetPeaks(data, note, spl)
    if note and data[note] and data[note][spl] then   
      local file_name = data[note][spl].sample
      local src = PCM_Source_CreateFromFileEx( data[note][spl].sample, true )
      if not src then return end
      local peakrate = 5000
      local src_len =  GetMediaSourceLength( src )
      local n_spls = math.floor(src_len*peakrate)
      if n_spls < 10 then return end 
      local n_ch = 1
      local want_extra_type = 0--115  -- 's' char
      local buf = new_array(n_spls * n_ch * 3) -- min, max, spectral each chan(but now mono only)
        -------------
      local retval =  PCM_Source_GetPeaks(    src, 
                                        peakrate, 
                                        0,--starttime, 
                                        n_ch,--numchannels, 
                                        n_spls, 
                                        want_extra_type, 
                                        buf )
      local spl_cnt  = (retval & 0xfffff)        -- sample_count
      local peaks = {}
      for i=1, spl_cnt do  peaks[#peaks+1] = buf[i]  end
      buf.clear()
      PCM_Source_Destroy( src )
      NormalizeT(peaks) 
      --SmoothT(peaks, .9)
      --ScaleT(peaks, .9)
      data.current_spl_peaks = peaks
      return spl_cnt
    end
  end 
