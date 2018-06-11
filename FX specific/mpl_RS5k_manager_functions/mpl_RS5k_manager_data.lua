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
                        GUID =            TrackFX_GetFXGUID( tr, fxid-1 ) ,
                        src_track = tr  ,
                        src_track_col = int_col,
                        offset_start =      TrackFX_GetParamNormalized( tr, fxid-1, 13)   ,      
                        offset_end =      TrackFX_GetParamNormalized( tr, fxid-1, 14)   ,    
                        bypass_state =    TrackFX_GetEnabled(tr, fxid-1)                                                    
                        }
      ::skipFX::
    end  
  end
  
  ---------------------------------------------------
  function SetRS5kData(data, conf, track, note) 
    local spl_id = 1
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
  function DefineParentTrack(conf, data, refresh)
    local tr = GetSelectedTrack(0,0)
    if not tr then return end
    
    data.parent_track = tr 
    data.parent_track_GUID = GetTrackGUID( tr )    
    GetSetMediaTrackInfo_String( data.parent_track, 'P_NAME', conf.parent_tr_name, 1 ) -- hard link to name
    
    BuildTrackTemplate_MIDISendMode(conf, data, refresh)
    
    refresh.data = true
    refresh.conf = true
    refresh.GUI_onStart = true
    refresh.projExtData = true                     
  end
  ---------------------------------------------------
  function Data_ValidateTrackConfig(conf, obj, data, refresh, mouse, pat)
    
    do return end
    -- check parent track
    local c = data.parent_track 
              and ValidatePtr2( 0, data.parent_track, 'MediaTrack*' )
              and data.parent_track_GUID
              and BR_GetMediaTrackByGUID(0,data.parent_track_GUID)
              and ValidatePtr2( 0, BR_GetMediaTrackByGUID(0,data.parent_track_GUID), 'MediaTrack*' )
      
      if c == false then 
        data.parent_track = nil
        data.parent_track_GUID = nil         
       else         
         if data.parent_track and GetSetMediaTrackInfo_String( data.parent_track, 'P_NAME', '', 0 ) == conf.parent_tr_name and conf.global_mode==1 or conf.global_mode==2 then
           BuildTrackTemplate_MIDISendMode(conf, data, refresh)
         end  
        return true
      end 
      
      
          
  end
  ---------------------------------------------------
  function Data_Update(conf, obj, data, refresh, mouse, pat)
    local tr = GetSelectedTrack(0,0)
    if not tr  then return end
    data.parent_track = tr
    GetRS5kData(data, tr)
    GetNoteNames(data, tr)
    for sid = 1,  GetTrackNumSends( tr, 0 ) do
      local srcchan = GetTrackSendInfo_Value( tr, 0, sid-1, 'I_SRCCHAN' )
      local dstchan = GetTrackSendInfo_Value( tr, 0, sid-1, 'I_DSTCHAN' )
      local midiflags = GetTrackSendInfo_Value( tr, 0, sid-1, 'I_MIDIFLAGS' )
      if srcchan == -1 and dstchan ==0 and midiflags == 0 then
        local desttr = BR_GetMediaTrackSendInfo_Track( tr, 0, sid-1, 1 )
        GetRS5kData(data, desttr)
        GetNoteNames(data, desttr)
      end
    end
  end 
  ---------------------------------------------------  
  function GetNoteNames(data, tr)
    for pitch = 0, 128 do
      if not data[pitch] then data[pitch] = {} end
      local name = GetTrackMIDINoteNameEx( 0, tr, pitch, 1)
      local out_name
      if name and name ~= pitch then
        if data[pitch] and data[pitch][1] then
          for i = 1, #data[pitch] do
            local sh_name =  GetShortSmplName(data[pitch][i].sample)
            if sh_name:match(literalize(name)) then goto skip_next_note end
          end
         else
          out_name = name
        end
      end
      if out_name then data[pitch].MIDInotename = out_name end
      ::skip_next_note::
    end
  end
  ---------------------------------------------------
    --[[local ret = Data_ValidateTrackConfig(conf, obj, data, refresh, mouse, pat) 
    if not ret then return end
    
    -- do stuff
    local tr = data.parent_track
    if not tr then return end
    local temp = {}
    local p_offs = {}    
    ---------    
    if conf.global_mode == 0 then
      GetSetMediaTrackInfo_String( tr, 'P_NAME', conf.parent_tr_name, 1 )
      local ex = false
      if ex and conf.prepareMIDI == 1 then MIDI_prepare(tr)   end
      for i =1, #temp do 
        if not data[ temp[i].pitch]  then data[ temp[i].pitch] = {} end
        data[ temp[i].pitch][#data[ temp[i].pitch]+1] = temp[i] 
      end
    end
    ---------   
    if conf.global_mode==1   then
      
      local ex = false
      local tr_id = CSurf_TrackToID( tr, false )      
      if GetMediaTrackInfo_Value( tr, 'I_FOLDERDEPTH' ) == 1 then      
        for i = tr_id+1, CountTracks(0) do
          local child_tr =  GetTrack( 0, i-1 )
          if ({GetSetMediaTrackInfo_String(child_tr, 'P_NAME', '', false)})[2] == MIDItr_name then data.parent_trackMIDI = child_tr end
          local lev = GetMediaTrackInfo_Value( child_tr, 'I_FOLDERDEPTH')
          GetRS5kData(child_tr,temp,p_offs)   
          if lev < 0 then break end
        end
      end
      ---------- add from stored data
      for i =1, #temp do 
        if not data[ temp[i].pitch]  then data[ temp[i].pitch] = {} end
        data[ temp[i].pitch][#data[ temp[i].pitch]+1] = temp[i] 
      end        
    end
    ----------
    if conf.global_mode==2   then
      GetSetMediaTrackInfo_String( tr, 'P_NAME', conf.parent_tr_name, 1 )
      local ex = false
      local tr_id = CSurf_TrackToID( tr, false )
      --if GetMediaTrackInfo_Value( tr, 'I_FOLDERDEPTH' ) == 1 then      
        for i = tr_id, CountTracks(0) do
          local child_tr =  GetTrack( 0, i-1 )
          if ({GetSetMediaTrackInfo_String(child_tr, 'P_NAME', '', false)})[2] == MIDItr_name then data.parent_trackMIDI = child_tr end
          local lev = GetMediaTrackInfo_Value( child_tr, 'I_FOLDERDEPTH' )
          if lev < 0 then break end
          GetRS5kData(child_tr,temp,p_offs)   
      
        end
      --end
      ---------- add from stored data
      for i =1, #temp do 
        if not data[ temp[i].pitch]  then data[ temp[i].pitch] = {} end
        data[ temp[i].pitch][#data[ temp[i].pitch]+1] = temp[i] 
      end        
    end
    ------------------------    
    local is_diff = false
    local last_val
    for i = 1, #p_offs do 
      if last_val and last_val ~= p_offs[i] then is_diff = true break end
      last_val = p_offs[i]
    end
    if is_diff then data.global_pitch_offset = 0.5 else data.global_pitch_offset = last_val end]]
  ---------------------------------------------------
  function GetDestTrackByNote(data, conf, main_track, note, insert_new)
    if not main_track then return end
    local tr_id = CSurf_TrackToID( main_track, false ) - 1
    local ex = false
    local last_id
    
    -- search track
    if GetMediaTrackInfo_Value( main_track, 'I_FOLDERDEPTH' ) == 1 then
      for i = tr_id+1, CountTracks(0) do        
        local child_tr =  GetTrack( 0, i-1 )
        local lev = GetMediaTrackInfo_Value( child_tr, 'I_FOLDERDEPTH' )
        for fxid = 1,  TrackFX_GetCount( child_tr ) do
          local retval, buf =TrackFX_GetFXName( child_tr, fxid-1, '' )
          if buf:lower():match('rs5k') or buf:lower():match(conf.preview_name) then
            local cur_pitch = TrackFX_GetParamNormalized( child_tr, fxid-1, 3 )
            if math_q_dec(cur_pitch, 5) == math_q_dec(note/127,5) then
              ex = true   
              return child_tr
            end              
          end
        end
        if lev < 0 then 
          last_id = i-1
          break 
        end
      end   
    end
      
    -- insert new if not exists
    if not ex and insert_new then  
      local insert_id
      if last_id then insert_id = last_id+1 else insert_id = tr_id+1 end
      local new_ch = InsertTrack(insert_id)  
      -- set params 
      --MIDI_prepare(new_ch, true)
      SetMediaTrackInfo_Value( GetTrack(0, CSurf_TrackToID(new_ch,false)-2), 'I_FOLDERDEPTH',0 )
      --SetMediaTrackInfo_Value( new_ch, 'I_FOLDERDEPTH',-1 )
      if conf.global_mode == 1 then CreateMIDISend(data, new_ch) end
      return new_ch
    end
  end
  
  ---------------------------------------------------------------------------------------------------------------------
  function GetPeaks(data, note)
    if note and data[note] and data[note][1] then   
      local file_name = data[note][1].sample
      local src = PCM_Source_CreateFromFileEx( data[note][1].sample, true )
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
      NormalizeT(peaks, 1) 
      --SmoothT(peaks, .9)
      --ScaleT(peaks, .9)
      data.current_spl_peaks = peaks
      return spl_cnt
    end
  end 
