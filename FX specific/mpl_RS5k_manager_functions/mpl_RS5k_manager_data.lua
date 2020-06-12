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
      local refresh_time = 0.2
      local ret = HasWindXYWHChanged(obj)
      if ret == 1 then 
        if not refresh.conf_timestamp or os.clock() - refresh.conf_timestamp > refresh_time then
          refresh.conf = true 
          refresh.data = true
          refresh.GUI_onStart = true 
          refresh.GUI_WF = true  
          refresh.conf_timestamp = os.clock()
        end
     
       elseif ret == 2 then 
        if not refresh.conf_timestamp or os.clock() - refresh.conf_timestamp > refresh_time then
          refresh.conf = true
          refresh.data = true
          refresh.conf_timestamp = os.clock()
        end
      end
  end
  function MoveSourceMedia(DRstr)
    local buf = reaper.GetProjectPathEx( 0, '' )
    if GetOS():lower():match('win') then
      local spl_name = GetShortSmplName(DRstr) 
      local cmd = 'copy "'..DRstr..'" "'..buf..'/RS5k_samples/'..spl_name..'"'
      cmd = cmd:gsub('\\', '/')
      os.execute(cmd)
      msg(cmd)
      return buf..'/RS5k_samples/'..spl_name
    end
    return DRstr
  end
  ---------------------------------------------------
  function Choke_Save(conf, data)
    local str = ''
    for i = 1, 127 do
      if not data.choke_t[i] then val = 0 else val = data.choke_t[i] end
      str = str..','..val
    end
    SetProjExtState( 0, conf.ES_key, 'CHOKE', str )
  end
  ---------------------------------------------------
  function Choke_Load(conf, data)
    data.choke_t = {}
    local ret, str = GetProjExtState( 0, conf.ES_key, 'CHOKE','') 
    if ret < 1 then 
      for i = 1, 127 do data.choke_t[i] = 0  end
     else
      local i = 0
      for val in str:gmatch('[^,]+') do i = i + 1 data.choke_t[i] = tonumber(val ) end
    end
  end
  ---------------------------------------------------
  function Choke_Apply(conf, obj, data, refresh, mouse, pat)
    if not data.jsfxtrack_exist or not data.validate_params then return end
    local max_cnt = 8
    
    -- reset
    for cnt = 0, max_cnt-1 do
      TrackFX_SetParamNormalized( data.parent_track, 0, 1+cnt*2, 0  )
      TrackFX_SetParamNormalized( data.parent_track, 0, 2+cnt*2, 0  )
    end
    
    cnt  = 0
    for i = 1, 127 do
      if cnt+1 >max_cnt then break end
      if data.choke_t[i] > 0 then 
        TrackFX_SetParamNormalized( data.parent_track, 0, 1+cnt*2, i/128  )
        TrackFX_SetParamNormalized( data.parent_track, 0, 2+cnt*2, data.choke_t[i] /128  )
        cnt = cnt + 1
      end
    end
  end
  ---------------------------------------------------
  function GetRS5kData(data, tr) 
    local MIDIpitch_lowest
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
      local MIDI_name = GetTrackMIDINoteNameEx( 0, tr, MIDIpitch, 0)
      local attack_ms = ({TrackFX_GetFormattedParamValue( tr, fxid-1, 9, '' )})[2]
      if tonumber(attack_ms) >= 1000 then 
        attack_ms = string.format('%.0f', attack_ms)
       else
        attack_ms = string.format('%.1f', attack_ms)
      end
      local delay_pos, del, del_ms = TrackFX_AddByName( tr, 'time_adjustment', false, 0 )
      if delay_pos >=0 then  
        del = TrackFX_GetParamNormalized( tr, delay_pos, 0) 
        local ms_val = ((del -0.5)*200)
        if ms_val >= 50 then
          del_ms = string.format('%.0f',ms_val)..'ms'
         else
          del_ms = string.format('%.1f',ms_val)..'ms'
        end
       else 
        del = 0.5
        del_ms = 0
      end
      
      local sample_short = GetShortSmplName(fn)
      local pat_reduceext = '(.*)%.[%a]+'
      if sample_short and sample_short:match(pat_reduceext) then 
        sample_short = sample_short:match(pat_reduceext) 
       else
        sample_short = fn
      end      
      if not MIDIpitch_lowest then data.MIDIpitch_lowest = MIDIpitch end
      data[MIDIpitch] [#data[MIDIpitch]+1] = {rs5k_pos = fxid-1,
                        pitch    =math.floor(({TrackFX_GetFormattedParamValue( tr, fxid-1, 3, '' )})[2]),
                        MIDIpitch_normal =        TrackFX_GetParamNormalized( tr, fxid-1, 3),
                        pitch_semitones =    ({TrackFX_GetFormattedParamValue( tr, fxid-1, 15, '' )})[2],
                        pitch_offset =        TrackFX_GetParamNormalized( tr, fxid-1, 15),
                        gain=                 TrackFX_GetParamNormalized( tr, fxid-1, 0),
                        gain_dB =           ({TrackFX_GetFormattedParamValue( tr, fxid-1, 0, '' )})[2],
                        trackGUID =           GetTrackGUID( tr ),
                        tr_ptr = tr,
                        pan=                  TrackFX_GetParamNormalized( tr, fxid-1,1),
                        attack =              TrackFX_GetParamNormalized( tr, fxid-1,9),
                        attack_ms =         attack_ms,
                        decay =              TrackFX_GetParamNormalized( tr, fxid-1,24),
                        decay_ms =         ({TrackFX_GetFormattedParamValue( tr, fxid-1, 24, '' )})[2],  
                        sust =              TrackFX_GetParamNormalized( tr, fxid-1,25),
                        sust_dB =         ({TrackFX_GetFormattedParamValue( tr, fxid-1, 25, '' )})[2],
                        rel =              TrackFX_GetParamNormalized( tr, fxid-1,10),
                        rel_ms =         ({TrackFX_GetFormattedParamValue( tr, fxid-1, 10, '' )})[2],   
                        sample = fn ,
                        sample_short =    sample_short,
                        GUID =            TrackFX_GetFXGUID( tr, fxid-1 ) ,
                        src_track = tr  ,
                        src_track_col = int_col,
                        offset_start =      TrackFX_GetParamNormalized( tr, fxid-1, 13)   ,      
                        offset_end =      TrackFX_GetParamNormalized( tr, fxid-1, 14)   ,    
                        bypass_state =    TrackFX_GetEnabled(tr, fxid-1)   , 
                        MIDI_name =        MIDI_name  ,
                        obeynoteoff =     TrackFX_GetParamNormalized( tr, fxid-1,11),
                        del = del,
                        del_ms = del_ms,
                        delay_pos=delay_pos,
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
    
    --collect FX data
    local FXChaindata = GetRS5kData_FX(tr)
    for note in pairs(data) do
      if tonumber(note) then
        for spl in pairs(data[note]) do
          if tonumber(spl) then
            if data[note][spl].tr_ptr == tr then
              data[note].FXChaindata = FXChaindata -- forced to note levelinstead of data[note][spl]
            end
          end
        end
      end    
    end
  end
  ---------------------------------------------------
  function GetRS5kData_FX(tr)
    local t = {}
    for fxid = 1,  TrackFX_GetCount( tr ) do
      -- validate RS5k by param names
      local retval, p3 = TrackFX_GetParamName( tr, fxid-1, 3, '' )
      local retval, p4 = TrackFX_GetParamName( tr, fxid-1, 4, '' )
      local isRS5k = retval and p3:match('range')~= nil and p4:match('range')~= nil
      if isRS5k then goto skipRS5k end
      
      local retval, fxname = TrackFX_GetFXName( tr,fxid-1, '' )
      t[#t+1] = { tr_ptr = tr,
                  fxname = fxname,
                  bypass = TrackFX_GetEnabled(  tr,fxid-1 ),
                  id = fxid-1}
      
      ::skipRS5k::
    end
    return t
  end
  ---------------------------------------------------
  function SearchSample(fn, dir_next )
    fn = fn:gsub('\\', '/')
    local path = fn:reverse():match('[%/]+.*'):reverse():sub(0,-2)
    local cur_file =     fn:reverse():match('.-[%/]'):reverse():sub(2)
    -- get files list
      local files = {}
      local i = 0
      repeat
      local file = reaper.EnumerateFiles( path, i )
      if file then
        if IsMediaExtension( file:match('.*%.(.*)'), false ) and not file:lower():match('%.rpp') then files[#files+1] = file end
      end
      i = i+1
      until file == nil
      
    -- search file list
      local trig_file
      if #files < 2 then return fn end
      local i_st, i_end, i_step, i_coeff, i_ret
      if dir_next then 
      i_st = 2
      i_end = #files
      i_step = 1
      i_coeff = -1
      i_ret = 1
      else
      i_st = #files-1
      i_end = 1
      i_step = -1
      i_coeff = 1
      i_ret = #files
      end
      for i = i_st,i_end,i_step   do
        if files[i+1*i_coeff] == cur_file then 
          trig_file = path..'/'..files[i] 
          break 
         elseif i == i_end then trig_file = path..'/'..files[i_ret] 
        end
      end  
    return trig_file
  end
  ---------------------------------------------------
  function SetRS5kData(data, conf, track, note, spl_id, add_new_data_entry, force_delay) 
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
        
        if force_delay == true and track ~= data.parent_track then  
          local delay_pos = TrackFX_AddByName( track, 'time_adjustment', false, 1 )
          if delay_pos >=0 then 
            data[note][spl_id].delay_pos = delay_pos
            local del_val = 0.5
            if data[note][spl_id].del then del_val = data[note][spl_id].del end
            TrackFX_SetParamNormalized( track, delay_pos, 0, del_val)
          end
        end
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
    local tr
    
    Choke_Load(conf, data)
    if conf.pintrack == 1 then 
      local ret, trGUID = GetProjExtState( 0, 'MPLRS5KMANAGE', 'PINNEDTR' )
      tr = BR_GetMediaTrackByGUID( 0, trGUID )
      if not (tr and ValidatePtr2(0,tr,'MediaTrack*' ))  then 
        local ret = MB('Pinned parent track not found, please redefine it or switch off via Menu/Project-related options.\nDisable pinned track? ', conf.mb_title, 3)
        if ret == 6 then
          conf.pintrack = 0
          refresh.conf = true
        end
        return 
      end
      data.parent_track = tr
     else
      tr = GetSelectedTrack(0,0)
      if not (tr and ValidatePtr2(0,tr,'MediaTrack*' ))  then return end
      data.parent_track = tr
    end
    
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
    
    if data.parent_track then 
      local retval, buf = reaper.TrackFX_GetFXName( data.parent_track, 0, '' )
      data.jsfxtrack_exist = buf:match('RS5K_Manager_tracker') ~= nil
      data.validate_params = false
      if data.jsfxtrack_exist == true then
        data.validate_params =  reaper.TrackFX_GetNumParams(data.parent_track, 0 ) > 0
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
      if src_len > 15 then return end
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
    if mode_override == 0  then -- VK
      SetMediaTrackInfo_Value( tr, 'I_RECINPUT', 4096+(62<<5) )-- VK
     else
      SetMediaTrackInfo_Value( tr, 'I_RECINPUT', 4096+(63<<5) ) -- all 
    end
    SetMediaTrackInfo_Value( tr, 'I_RECMON', 1) -- monitor input
    SetMediaTrackInfo_Value( tr, 'I_RECARM', 1) -- arm track 
    SetMediaTrackInfo_Value( tr, 'I_RECMODE',0) -- record MIDI out
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
    local val
    
    if data[note] and data[note][1] then 
      track = data[note][1].src_track
      if conf.allow_multiple_spls_per_pad == 0 then
        TrackFX_SetNamedConfigParm(  track, data[note][1].rs5k_pos, 'FILE0', filepath)
        TrackFX_SetNamedConfigParm(  track, data[note][1].rs5k_pos, 'DONE', '')
        val= 1
        goto rename_note 
       else
        ExportItemToRS5K_defaults(data,conf,refresh,note,filepath, start_offs, end_offs, track)  
        val= #data[note]+1
        goto rename_note               
      end
     else
       ExportItemToRS5K_defaults(data,conf,refresh,note,filepath, start_offs, end_offs, track)
       val= 1
       goto rename_note
    end
    
    ::rename_note::
    -- rename note in ME
      local MIDI_notename = GetShortSmplName(filepath)
      if MIDI_notename and MIDI_notename ~= '' and track then
        MIDI_notename = MIDI_notename:match('(.*)%.')
          SetTrackMIDINoteNameEx( 0, track, note, 0, MIDI_notename)
          SetTrackMIDINoteNameEx( 0,track, note, 0, MIDI_notename)
      end
    
    return val
    
  end
  ----------------------------------------------------------------------- 
  function ExportItemToRS5K_defaults(data,conf,refresh,note,filepath, start_offs, end_offs, track)
    local last_inst
    for fx = 1, TrackFX_GetCount( track ) do
      local retval, buf = TrackFX_GetFXName( track, fx-1, '' )
      if buf:match('RS5K') or buf:match('ReaSamplomatic5000') then
        last_inst = fx-1
      end
    end
    local rs5k_pos = TrackFX_AddByName( track, 'ReaSamplomatic5000', false, -1 )
    if conf.closefloat == 1 then reaper.TrackFX_Show( track, rs5k_pos, -2 ) end
    if last_inst then 
      TrackFX_CopyToTrack( track, rs5k_pos, track, last_inst+1,true )
      rs5k_pos = last_inst+1
    end
    TrackFX_SetNamedConfigParm(  track, rs5k_pos, 'FILE0', filepath)
    TrackFX_SetNamedConfigParm(  track, rs5k_pos, 'DONE', '')      
    TrackFX_SetParamNormalized( track, rs5k_pos, 2, 0) -- gain for min vel
    TrackFX_SetParamNormalized( track, rs5k_pos, 3, note/127 ) -- note range start
    TrackFX_SetParamNormalized( track, rs5k_pos, 4, note/127 ) -- note range end
    TrackFX_SetParamNormalized( track, rs5k_pos, 5, 0.5 ) -- pitch for start
    TrackFX_SetParamNormalized( track, rs5k_pos, 6, 0.5 ) -- pitch for end
    TrackFX_SetParamNormalized( track, rs5k_pos, 8, 0 ) -- max voices = 0
    TrackFX_SetParamNormalized( track, rs5k_pos, 9, 0 ) -- attack
    TrackFX_SetParamNormalized( track, rs5k_pos, 11, conf.obeynoteoff_default ) -- obey note offs
    if start_offs and end_offs then
      TrackFX_SetParamNormalized( track, rs5k_pos, 13, start_offs ) -- attack
      TrackFX_SetParamNormalized( track, rs5k_pos, 14, end_offs )   
    end  
  end
  ----------------------------------------------------------------------- 
  function ShowRS5kChain(data, conf, note, spl)
    if not data[note] or not data[note][1] then return end
    if not spl then spl = 1 end
    if not data[note][spl] then return end
    if data[note][spl].src_track == data.parent_track then
      local ret_com
      if conf.dontaskforcreatingrouting == 1 then 
        ret_com = true 
       else
        local ret = MB('Create MIDI send routing for this sample?', conf.scr_title, 4)
        if ret == 6  then ret_com = true  end
      end
      if ret_com then
        Undo_BeginBlock()                          
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
        Undo_EndBlock( 'Build RS5k MIDI routing for note '..note..' sample '..spl, 0 )
        return new_tr
        
      end
     else
      TrackFX_Show( data[note][spl].src_track, 0, 1 )
    end
  end
  
  ----------------------------------------------------------------------- 
  
  function AddFXChainToTrack_ExtractBlock(str)
    local s = ''
    local count = 1
    count_lines = 0
    for line in str:gmatch('[^\n]+') do
      count_lines = count_lines + 1
      s = s..'\n'..line
      if line:find('<') then count = count +1 end
      if line:find('>') then count = count -1 end 
      if count == 1 then return s, count_lines end     
    end
  end   
  function AddFXChainToTrack(track, chain_fp)
    -- get some chain file, ex. from GetUserFileForRead()
      local file = io.open(chain_fp)
      if not file then return end
      local external_FX_chain_content = file:read('a')
      file:close()  

    -- get track chunk
      local chunk = eugen27771_GetObjStateChunk(track) 
      if not chunk then return end   
    -- split chunk by lines into table
      local t = {} 
      for line in chunk:gmatch('[^\n]+') do       if line:find('<FXCHAIN') then fx_chain_id0 = #t end       t[#t+1] = line     end 
    --  find size of FX chain and where it placed
      local _, cnt_lines = AddFXChainToTrack_ExtractBlock(chunk:match('<FXCHAIN.*'))
      local fx_chain_id1 = fx_chain_id0 + cnt_lines -1
    -- insert FX chain
      local new_chunk = table.concat(t,'\n',  1, fx_chain_id1)..'\n'..
                external_FX_chain_content..
                table.concat(t,'\n',  fx_chain_id1)     
    -- apply new chunk                
      SetTrackStateChunk(track, new_chunk, false) 
  end
  
