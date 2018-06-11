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
  function MIDI_prepare(data, conf)
    local tr = GetSelectedTrack(0,0)
    if not tr then return end
    if conf.prepareMIDI2 == 0 then return end
    if conf.prepareMIDI2 == 1 then -- VK
      SetMediaTrackInfo_Value( tr, 'I_RECINPUT', 4096+(62<<5) )
      SetMediaTrackInfo_Value( tr, 'I_RECMON', 1) -- monitor input
      SetMediaTrackInfo_Value( tr, 'I_RECARM', 1) -- arm track 
      SetMediaTrackInfo_Value( tr, 'I_RECMODE',0) -- record MIDI out
    end
    if conf.prepareMIDI2 == 2 then -- all midi
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
  ----------------------------------------------------------------------------
  function Preview_Key(data,conf,refresh, p, refresh) 
    if conf.global_mode ==0 then -- single track multiple instances                                         
      ExportItemToRS5K(data,conf,refresh, p, 0, _, 1)
    end
  
    if conf.global_mode == 1 then -- use track as folder
      --BuildTrackTemplate_MIDISendMode(conf, data, refresh)
      ExportItemToRS5K(data,conf,refresh, p, 0, data.parent_trackMIDI, 1)
    end
  
    if conf.global_mode == 2 then -- dump mode, use parent track
      --BuildTrackTemplate_MIDISendMode(conf, data, refresh)
      ExportItemToRS5K(data,conf,refresh, p, 0,data.parent_track, 1)
    end
    
    StuffMIDIMessage( 0, '0x9'..string.format("%x", 0), 0,100)
    StuffMIDIMessage( 0, '0x8'..string.format("%x", 0), 0,100)
    
  end
  -----------------------------------------------------------------------  
  function BuildTrackTemplate_MIDISendMode(conf, data, refresh)
    if not data.parent_track then return end
    
    if conf.global_mode == 1 then
      if      not data.parent_trackMIDI 
          or  not ValidatePtr2( 0, data.parent_trackMIDI, 'MediaTrack*' )  then
          
        data.parent_trackMIDI = InsertTrack(CSurf_TrackToID( data.parent_track, false ))
        data.parent_trackMIDI_GUID = GetTrackGUID( data.parent_trackMIDI )
        GetSetMediaTrackInfo_String(data.parent_trackMIDI, 'P_NAME', conf.MIDItr_name, true)
        ExplodeRS5K_AddChunkToTrack(data.parent_trackMIDI)
        MIDI_prepare(data.parent_trackMIDI)
        SetOnlyTrackSelected(data.parent_trackMIDI)
        refresh.projExtData = true
      end
    end

    -- if not folder then create preview channel and set to folder
    local par_depth = GetMediaTrackInfo_Value( data.parent_track, 'I_FOLDERDEPTH')
    if conf.global_mode == 1 or conf.global_mode == 2 and (par_depth <=0) then 
      SetMediaTrackInfo_Value( data.parent_track, 'I_FOLDERDEPTH',1 ) 
    end
        
    if conf.global_mode == 0 or conf.global_mode == 2 then  MIDI_prepare(data.parent_track)  end
    
  end
  --------------------------------------------------
  function CreateMIDISend(data, new_ch)
    local send_id = CreateTrackSend( data.parent_trackMIDI, new_ch)
    SetTrackSendInfo_Value( data.parent_trackMIDI, 0, send_id, 'I_SRCCHAN' , -1 )
    SetTrackSendInfo_Value( data.parent_trackMIDI, 0, send_id, 'I_MIDIFLAGS' , 0 )
  end
  ---------------------------------------------------
  function ExportItemToRS5K(data,conf,refresh,note,filepath, start_offs, end_offs)
    if not data.parent_track or not note or not filepath then return end
    local track = data.parent_track
    
    if data[note][1] then 
      track = data[note][1].src_track
      if conf.allow_multiple_spls_per_pad == 0 then
        TrackFX_SetNamedConfigParm(  track, data[note][1].rs5k_pos, 'FILE0', filepath)
        TrackFX_SetNamedConfigParm(  track, data[note][1].rs5k_pos, 'DONE', '')  
       else
        --todo
      end
     else
      local rs5k_pos = TrackFX_AddByName( track, 'ReaSamplomatic5000', false, -1 )
      TrackFX_SetNamedConfigParm(  track, rs5k_pos, 'FILE0', filepath)
      TrackFX_SetNamedConfigParm(  track, rs5k_pos, 'DONE', '')      
      TrackFX_SetParamNormalized( track, rs5k_pos, 2, 0) -- gain for min vel
      TrackFX_SetParamNormalized( track, rs5k_pos, 3, note/128 ) -- note range start
      TrackFX_SetParamNormalized( track, rs5k_pos, 4, note/128 ) -- note range end
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
    
  end
  
  ----------------------------------------------------------------------- 
  function SetRS5KParam(data, conf, param, value, linked_note)
    if not data.parent_track then return end
    if not linked_note or not data[linked_note]then return end 
    
    for i = 1, #data[linked_note] do
      if param >= 0 then
        TrackFX_SetParamNormalized( data[linked_note][i].src_track, data[linked_note][i].rs5k_pos, param, lim(value))
       elseif param == -2 then
        TrackFX_SetEnabled(data[linked_note][i].src_track, data[linked_note][i].rs5k_pos, value )
      end
    end
  end
  ----------------------------------------------------------------------- 
  function ShowRS5kChain(data, conf, note)
    if not data[note] or not data[note][1] then return end
    
    if data[note][1].src_track == data.parent_track then
      local ret = MB('Create MIDI send routing for this sample?', conf.scr_title, 4)
      if ret == 6  then
        local tr_id = CSurf_TrackToID( data.parent_track, false )
        InsertTrackAtIndex( tr_id, true)
        local new_tr = CSurf_TrackFromID( tr_id+1, false )
        local send_id = CreateTrackSend( data.parent_track, new_tr)
        SetTrackSendInfo_Value( data.parent_track, 0, send_id, 'I_SRCCHAN' , -1 )
        SetTrackSendInfo_Value( data.parent_track, 0, send_id, 'I_DSTCHAN' , 0 )
        SetTrackSendInfo_Value( data.parent_track, 0, send_id, 'I_MIDIFLAGS' , 0 )
        SNM_MoveOrRemoveTrackFX( data.parent_track, data[note][1].rs5k_pos, 0 )
        SetRS5kData(data, conf, new_tr, note)
        TrackList_AdjustWindows( false )
        TrackFX_Show( new_tr, 0, 1 )
      end
     else
      TrackFX_Show( data[note][1].src_track, 0, 1 )
    end
  end
