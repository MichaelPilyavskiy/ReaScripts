retval, duplicate_x_s = reaper.GetUserInputs("", 1, "How much times copy?", "")
if retval ~= nil then
 act_editor = reaper.MIDIEditor_GetActive()
 if act_editor ~= nil then
  take = reaper.MIDIEditor_GetTake(act_editor)
  if take ~= nil then
    item = reaper.GetMediaItemTake_Item(take)
    item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    
    channel = reaper.MIDIEditor_GetSetting_int(act_editor, "default_note_chan")
    retval, notecnt, ccevtcnt, textsyxevtcnt = reaper.MIDI_CountEvts(take)
    if notecnt ~= nil then
      startppqpos_min = reaper.MIDI_GetPPQPosFromProjTime(take, item_len)
      endppqpos_max = 0
      for i = 1, notecnt do
        retval, selected, muted, startppqpos, endppqpos, chan, pitchOut, vel = reaper.MIDI_GetNote(take, i-1)
        if selected == true and chan == channel then
          startppqpos_min = math.min(startppqpos_min, startppqpos)
          endppqpos_max = math.max(endppqpos_max, endppqpos)
        end
      end
    end    
    delta = endppqpos_max - startppqpos_min
    duplicate_x = tonumber(duplicate_x_s)    
    if notecnt ~= nil then       
      for i = 1, notecnt do
        retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, i-1)
        if selected == true and chan == channel then          
          for j = 1, duplicate_x do
            reaper.MIDI_InsertNote(take, false, false, startppqpos+delta*j, endppqpos+delta*j, channel, pitch, vel, false)
          end 
        end    
      end    
    end
    --reaper.MIDI_Sort(take)
  end
 end
end
