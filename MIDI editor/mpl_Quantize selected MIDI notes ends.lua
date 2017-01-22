-- @version 1.01
-- @author MPL
-- @description Quantize selected MIDI notes ends
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--   + init release
--   # release note: need an API to perform SnapToGrid() for MIDI Editor (relative to time signature denominator and ME timebase)


  function main()   
    local ME, take, fng_take,count_notes,note, sel, pos, len,ME_grid, swing,pos_sec
    ME = reaper.MIDIEditor_GetActive()
    if not ME then return end
    take = reaper.MIDIEditor_GetTake(ME)
    if not take or not reaper.TakeIsMIDI(take) then return end
    ME_grid, swing = reaper.MIDI_GetGrid( take )
    fng_take = reaper.FNG_AllocMidiTake(take)
    count_notes = reaper.FNG_CountMidiNotes(fng_take)
    for i = 1, count_notes do
      note = reaper.FNG_GetMidiNote(fng_take, i-1)
      sel = reaper.FNG_GetMidiNoteIntProperty(note, "SELECTED")          
      pos = reaper.FNG_GetMidiNoteIntProperty(note, "POSITION")
      len = reaper.FNG_GetMidiNoteIntProperty(note, "LENGTH")
      pos_sec = reaper.MIDI_GetProjTimeFromPPQPos(take, pos+len )
      if sel == 1 then
        snap_time_sec = Snap2Grid(pos_sec, ME_grid, swing)
        if snap_time_sec then
          ppq2 = reaper.MIDI_GetPPQPosFromProjTime(take, snap_time_sec) 
          out_pos = math.floor(ppq2-pos)
          reaper.FNG_SetMidiNoteIntProperty(note, "LENGTH", out_pos)  
        end  
      end
    end
    reaper.FNG_FreeMidiTake(fng_take)
  end
  --------------------------------------------------------------------
  function Snap2Grid(pos_sec, grid, swing)
    -- detect timesig for pattern
      local timesig_num
      local tempo_marker_ID = reaper.FindTempoTimeSigMarker( 0, pos_sec )
      if tempo_marker_ID >= 0 then
        _, _, _, _, _, timesig_num = reaper.GetTempoTimeSigMarker( 0, tempo_marker_ID )
       else  _, timesig_num = reaper.GetProjectTimeSignature2( 0 )
      end
    -- form pattern table
      beat_pat = {}
      for i = 0,timesig_num, grid do
        local gr
        if i % 2 == 1 then gr = i + swing else gr = i end
        if gr < timesig_num then  beat_pat[#beat_pat+1] = gr end
      end
      beat_pat[#beat_pat+1] = timesig_num
        
    pos_beats, measures  = reaper.TimeMap2_timeToBeats( 0, pos_sec )
    for i = 2, #beat_pat do
      if pos_beats > beat_pat[#beat_pat] then break end
      if pos_beats == beat_pat[#beat_pat] then ret_beats = beat_pat[#beat_pat] break end
      if pos_beats > beat_pat[i-1] and pos_beats < beat_pat[i] then
        diff1 = pos_beats - beat_pat[i-1]
        diff2 =  beat_pat[i] - pos_beats
        if diff1 < diff2 then ret_beats = beat_pat[i-1] else ret_beats = beat_pat[i] end
        break
      end
    end
    if ret_beats then 
      local out_val = reaper.TimeMap2_beatsToTime( 0, ret_beats, measures ) 
      return out_val
    end
  end
  
  main()
