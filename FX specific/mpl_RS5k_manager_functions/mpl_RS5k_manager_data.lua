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
      data.hasanydata = true
      local MIDIpitch = math.floor(TrackFX_GetParamNormalized( tr, fxid-1, 3)*128)
      local retval, fn = TrackFX_GetNamedConfigParm( tr, fxid-1, 'FILE' )
      --msg(TrackFX_GetParamNormalized( tr, fxid-1, 3)*128)
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
                        MIDI_name =        MIDI_name  ,
                        obeynoteoff =     TrackFX_GetParamNormalized( tr, fxid-1,11),
                        }
      ::skipFX::
    end  
    
    -- get solo state
    local glob_bypass_state_cnt = 0
    local glob_sol, keys_active_cnt = nil, 0
    for MIDIpitch =0, 128 do
      if data[MIDIpitch] then 
        keys_active_cnt = keys_active_cnt + 1
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
    if glob_bypass_state_cnt == 1 and glob_sol and keys_active_cnt > 1 then  data[glob_sol].solo_state = true end
    
    -- get common gain
    for MIDIpitch =0, 128 do
      if data[MIDIpitch] then  
        local com_gain,com_pan = 0  ,0 
        for spl = 1, #data[MIDIpitch] do
          com_gain = com_gain + data[MIDIpitch][spl].gain
          com_pan = com_pan + data[MIDIpitch][spl].pan
        end
        data[MIDIpitch].com_gain = lim(com_gain/#data[MIDIpitch],0,2)
        data[MIDIpitch].com_pan = lim(com_pan/#data[MIDIpitch],0,1)
      end
    end      
          
  end
  
  ---------------------------------------------------
  function SetRS5kData(data, conf, track, note, spl_id, add_new_data_entry) 
    if not spl_id then spl_id = 1 end
    if data[note][spl_id] then 
        local rs5k_pos = data[note][spl_id].rs5k_pos
        if add_new_data_entry then 
          rs5k_pos = TrackFX_AddByName( track, 'ReaSamplomatic5000', false, -1 )  
        end              
        TrackFX_SetNamedConfigParm(  track, rs5k_pos, 'FILE0', data[note][spl_id].sample)
        TrackFX_SetNamedConfigParm(  track, rs5k_pos, 'DONE', '')  
        
        TrackFX_SetParamNormalized( track, rs5k_pos, 0, lim(data[note][spl_id].gain,0,2)) -- gain
        TrackFX_SetParamNormalized( track, rs5k_pos, 1, data[note][spl_id].pan) -- pan
        
        TrackFX_SetParamNormalized( track, rs5k_pos, 2, 0) -- gain for min vel
        TrackFX_SetParamNormalized( track, rs5k_pos, 4, data[note][spl_id].MIDIpitch_normal) -- note range start
        TrackFX_SetParamNormalized( track, rs5k_pos, 3, data[note][spl_id].MIDIpitch_normal) -- note range end
        TrackFX_SetParamNormalized( track, rs5k_pos, 5, 0.5 ) -- pitch for start
        TrackFX_SetParamNormalized( track, rs5k_pos, 6, 0.5 ) -- pitch for end
        TrackFX_SetParamNormalized( track, rs5k_pos, 15, data[note][spl_id].pitch_offset)
        
        TrackFX_SetParamNormalized( track, rs5k_pos, 8, 0 ) -- max voices = 0
        TrackFX_SetParamNormalized( track, rs5k_pos, 11, data[note][spl_id].obeynoteoff ) -- obey note offs
                
        TrackFX_SetParamNormalized( track, rs5k_pos, 9, data[note][spl_id].attack ) -- adsr
        TrackFX_SetParamNormalized( track, rs5k_pos, 24, data[note][spl_id].decay )
        TrackFX_SetParamNormalized( track, rs5k_pos, 25, data[note][spl_id].sust )
        TrackFX_SetParamNormalized( track, rs5k_pos, 10, data[note][spl_id].rel )
        
        TrackFX_SetParamNormalized( track, rs5k_pos, 13, lim(data[note][spl_id].offset_start, 0, data[note][spl_id].offset_end ) )
        TrackFX_SetParamNormalized( track, rs5k_pos, 14, lim(data[note][spl_id].offset_end,   data[note][spl_id].offset_start, 1 )  )
        TrackFX_SetEnabled(track, rs5k_pos, data[note][spl_id].bypass_state)
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
  function Data_Update(conf, obj, data, refresh, mouse)
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
-- @description RS5k_manager_trackfunc 
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex

  ---------------------------------------------------
  function InsertTrack(tr_id)
    InsertTrackAtIndex(tr_id, true)
    TrackList_AdjustWindows( false )
    return CSurf_TrackFromID( tr_id+1, false )
  end
  ---------------------------------------------------
  function MIDI_prepare(data, conf, mode_override)
    local tr = GetSelectedTrack(0,0)
    if not tr then return end
    if conf.prepareMIDI2 == 0 then return end
    if conf.prepareMIDI2 == 1 or (mode_override and mode_override == 0 ) then -- VK
      SetMediaTrackInfo_Value( tr, 'I_RECINPUT', 4096+(62<<5) )
      SetMediaTrackInfo_Value( tr, 'I_RECMON', 1) -- monitor input
      SetMediaTrackInfo_Value( tr, 'I_RECARM', 1) -- arm track 
      SetMediaTrackInfo_Value( tr, 'I_RECMODE',0) -- record MIDI out
    end
    if conf.prepareMIDI2 == 2 or (mode_override and mode_override == 1 ) then -- all midi
      SetMediaTrackInfo_Value( tr, 'I_RECINPUT', 4096+(63<<5) )
      SetMediaTrackInfo_Value( tr, 'I_RECMON', 1) -- monitor input
      SetMediaTrackInfo_Value( tr, 'I_RECARM', 1) -- arm track 
      SetMediaTrackInfo_Value( tr, 'I_RECMODE',0) -- record MIDI out
    end    
  end
  ------------------------------------------------------------------------
  function ExplodeRS5K_Extract_rs5k_tChunks(tr)
    local _, chunk = GetTrackStateChunk(tr, '', false)
    local t = {}
    for fx_chunk in chunk:gmatch('BYPASS(.-)WAK') do 
      if fx_chunk:match('<(.*)') and fx_chunk:match('<(.*)'):match('reasamplomatic.dll') then 
        t[#t+1] = 'BYPASS 0 0 0\n<'..fx_chunk:match('<(.*)') ..'WAK 0'
      end
    end
    return t
  end
    ------------------------------------------------------------------------  
    function ExplodeRS5K_AddChunkToTrack(tr, chunk) -- add empty fx chain chunk if not exists
      local _, chunk_ch = GetTrackStateChunk(tr, '', false)
      -- add fxchain if not exists
      if not chunk_ch:match('FXCHAIN') then 
        chunk_ch = chunk_ch:sub(0,-3)..[=[
  <FXCHAIN
  SHOW 0
  LASTSEL 0
  DOCKED 0
  >
  >]=]
      end
      if chunk then chunk_ch = chunk_ch:gsub('DOCKED %d', chunk) end
      SetTrackStateChunk(tr, chunk_ch, false)
    end
    ------------------------------------------------------------------------  
    function ExplodeRS5K_RenameTrAsFirstInstance(track)
      if not track then return end
      local fx_count =  TrackFX_GetCount(track)
      if fx_count >= 1 then
        local retval, fx_name =  TrackFX_GetFXName(track, 0, '')      
        local fx_name_cut = fx_name:match(': (.*)')
        if fx_name_cut then fx_name = fx_name_cut end
        GetSetMediaTrackInfo_String(track, 'P_NAME', fx_name, true)
      end
    end
  ------------------------------------------------------------------------  
  function ExplodeRS5K_main(tr)
    if tr then 
      local tr_id = CSurf_TrackToID( tr,false )
      SetMediaTrackInfo_Value( tr, 'I_FOLDERDEPTH', 1 )
      Undo_BeginBlock2( 0 )      
      local ch = ExplodeRS5K_Extract_rs5k_tChunks(tr)
      if ch and #ch > 0 then 
        for i = #ch, 1, -1 do 
          InsertTrackAtIndex( tr_id, false )
          local child_tr = GetTrack(0,tr_id)
          ExplodeRS5K_AddChunkToTrack(child_tr, ch[i])
          ExplodeRS5K_RenameTrAsFirstInstance(child_tr)
          local ch_depth if i == #ch then ch_depth = -1 else ch_depth = 0 end
          SetMediaTrackInfo_Value( child_tr, 'I_FOLDERDEPTH', ch_depth )
          SetMediaTrackInfo_Value( child_tr, 'I_FOLDERCOMPACT', 1 ) 
        end
      end
      SetOnlyTrackSelected( tr )
      Main_OnCommand(40535,0 ) -- Track: Set all FX offline for selected tracks
      Undo_EndBlock2( 0, 'Explode selected track RS5k instances to new tracks', 0 )
    end
  end     
  -----------------------------------------------------------------------
  function SetFXName(track, fx, new_name)
    if not new_name then return end
    local edited_line,edited_line_id, segm
    -- get ref guid
      if not track or not tonumber(fx) then return end
      local FX_GUID = reaper.TrackFX_GetFXGUID( track, fx )
      if not FX_GUID then return else FX_GUID = FX_GUID:gsub('-',''):sub(2,-2) end
      local plug_type = reaper.TrackFX_GetIOSize( track, fx )
    -- get chunk t
      local _, chunk = reaper.GetTrackStateChunk( track, '', false )
      local t = {} for line in chunk:gmatch("[^\r\n]+") do t[#t+1] = line end
    -- find edit line
      local search
      for i = #t, 1, -1 do
        local t_check = t[i]:gsub('-','')
        if t_check:find(FX_GUID) then search = true  end
        if t[i]:find('<') and search and not t[i]:find('JS_SER') then
          edited_line = t[i]:sub(2)
          edited_line_id = i
          break
        end
      end
    -- parse line
      if not edited_line then return end
      local t1 = {}
      for word in edited_line:gmatch('[%S]+') do t1[#t1+1] = word end
      local t2 = {}
      for i = 1, #t1 do
        segm = t1[i]
        if not q then t2[#t2+1] = segm else t2[#t2] = t2[#t2]..' '..segm end
        if segm:find('"') and not segm:find('""') then if not q then q = true else q = nil end end
      end
  
      if plug_type == 2 then t2[3] = '"'..new_name..'"' end -- if JS
      if plug_type == 3 then t2[5] = '"'..new_name..'"' end -- if VST
  
      local out_line = table.concat(t2,' ')
      t[edited_line_id] = '<'..out_line
      local out_chunk = table.concat(t,'\n')
      --msg(out_chunk)
      reaper.SetTrackStateChunk( track, out_chunk, false )
      reaper.UpdateArrange()
  end

  ---------------------------------------------------
  function ExportItemToRS5K(data,conf,refresh,note,filepath, start_offs, end_offs)
    if not data.parent_track or not note or not filepath then return end
    local track = data.parent_track
    if data[note] and data[note][1] then 
      track = data[note][1].src_track
      if conf.allow_multiple_spls_per_pad == 0 then
        TrackFX_SetNamedConfigParm(  track, data[note][1].rs5k_pos, 'FILE0', filepath)
        TrackFX_SetNamedConfigParm(  track, data[note][1].rs5k_pos, 'DONE', '')  
       else
        ExportItemToRS5K_defaults(data,conf,refresh,note,filepath, start_offs, end_offs, track)        
      end
     else
       ExportItemToRS5K_defaults(data,conf,refresh,note,filepath, start_offs, end_offs, track)
    end
    
  end
  ----------------------------------------------------------------------- 
  function ExportItemToRS5K_defaults(data,conf,refresh,note,filepath, start_offs, end_offs, track)
    local rs5k_pos = TrackFX_AddByName( track, 'ReaSamplomatic5000', false, -1 )
    TrackFX_SetNamedConfigParm(  track, rs5k_pos, 'FILE0', filepath)
    TrackFX_SetNamedConfigParm(  track, rs5k_pos, 'DONE', '')      
    TrackFX_SetParamNormalized( track, rs5k_pos, 2, 0) -- gain for min vel
    TrackFX_SetParamNormalized( track, rs5k_pos, 3, note/127 ) -- note range start
    TrackFX_SetParamNormalized( track, rs5k_pos, 4, note/127 ) -- note range end
    TrackFX_SetParamNormalized( track, rs5k_pos, 5, 0.5 ) -- pitch for start
    TrackFX_SetParamNormalized( track, rs5k_pos, 6, 0.5 ) -- pitch for end
    TrackFX_SetParamNormalized( track, rs5k_pos, 8, 0 ) -- max voices = 0
    TrackFX_SetParamNormalized( track, rs5k_pos, 9, 0 ) -- attack
    TrackFX_SetParamNormalized( track, rs5k_pos, 11, 0 ) -- obey note offs
    if start_offs and end_offs then
      TrackFX_SetParamNormalized( track, rs5k_pos, 13, start_offs ) -- attack
      TrackFX_SetParamNormalized( track, rs5k_pos, 14, end_offs ) -- obey note offs      
    end  
  end
  ----------------------------------------------------------------------- 
  function ShowRS5kChain(data, conf, note, spl)
    if not data[note] or not data[note][1] then return end
    if not spl then spl = 1 end
    if not data[note][spl] then return end
    if data[note][spl].src_track == data.parent_track then
      local ret = MB('Create MIDI send routing for this sample?', conf.scr_title, 4)
      if ret == 6  then
        local tr_id = CSurf_TrackToID( data.parent_track, false )
        InsertTrackAtIndex( tr_id, true)
        local new_tr = CSurf_TrackFromID( tr_id+1, false )
        local send_id = CreateTrackSend( data.parent_track, new_tr)
        SetTrackSendInfo_Value( data.parent_track, 0, send_id, 'I_SRCCHAN' , -1 )
        SetTrackSendInfo_Value( data.parent_track, 0, send_id, 'I_DSTCHAN' , 0 )
        SetTrackSendInfo_Value( data.parent_track, 0, send_id, 'I_MIDIFLAGS' , 0 )
        SNM_MoveOrRemoveTrackFX( data.parent_track, data[note][spl].rs5k_pos, 0 )
        SetRS5kData(data, conf, new_tr, note, spl, true)
        GetSetMediaTrackInfo_String( new_tr, 'P_NAME', data[note][spl].sample_short, 1 )
        TrackList_AdjustWindows( false )
        TrackFX_Show( new_tr, 0, 1 )
      end
     else
      TrackFX_Show( data[note][spl].src_track, 0, 1 )
    end
  end
