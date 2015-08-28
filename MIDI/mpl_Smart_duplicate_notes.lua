script_title = "Smart duplicate notes"

-- There is a bug or something in MIDI Editor API.
-- When you run this script and dont close  every time you duplicate notes,
-- last selected note inserted until event length reached or inserted with 1 tick lenght.
-- Also when you already copied notes and want to move midi item edge, 
-- end of last selected note is snapping to this edge.

-- So to prevent this bug: run this script, 
-- then click on any space of midi editor to "update" it, 
-- and then run script again (if you need).

reaper.Undo_BeginBlock()

midi_editor = reaper.MIDIEditor_GetActive()
if midi_editor ~= nil then
  take = reaper.MIDIEditor_GetTake(midi_editor)
  if take ~= nil then
    item = reaper.GetMediaItemTake_Item(take)
    item_pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    item_len = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
    
    -- store selected notes to table    
    retval, notecnt = reaper.MIDI_CountEvts(take)
    if notecnt ~= nil then
      notes_2_copy_t = {}
      for i=1, notecnt do
        retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, i-1)
        if selected == true then          
          table.insert(notes_2_copy_t, {muted, startppqpos, endppqpos, chan, pitch, vel})
        end
      end
    end 
    
    -- search for limits / difference    
    if notes_2_copy_t ~= nil then    
      min_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, item_pos+item_len)
      max_ppq = 0
      for i=1, #notes_2_copy_t do        
        notes_2_copy_subt = notes_2_copy_t[i]
        min_ppq = math.min(notes_2_copy_subt[2], min_ppq)
        max_ppq = math.max(notes_2_copy_subt[3], max_ppq)
      end
    end
    ppq_dif = max_ppq - min_ppq    
    time_dif = reaper.MIDI_GetProjTimeFromPPQPos(take, ppq_dif) - item_pos
    retval, measures, cml = reaper.TimeMap2_timeToBeats(0, time_dif)
    time_of_measure = reaper.TimeMap2_beatsToTime(0, 0, 1)
    measure_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, time_of_measure)
    adjust_ppq = measure_ppq * (measures+1)
    
    -- adjust item edges  
    if notes_2_copy_t ~= nil then  
      new_item_len = item_len + time_of_measure * (measures+1)
      reaper.SetMediaItemInfo_Value(item, 'D_LENGTH', new_item_len)
    end    
    reaper.UpdateItemInProject(item)
        
    -- deselect other notes --
    retval, notecnt = reaper.MIDI_CountEvts(take)
    if notecnt ~= nil then      
      for i=1, notecnt do
        retval = reaper.MIDI_GetNote(take, i-1)
        reaper.MIDI_SetNote(take, i-1, false)
      end
    end             
        
    -- insert notes from table ---
    if notes_2_copy_t ~= nil then
      for i = 1, #notes_2_copy_t do
        notes_2_copy_subt = notes_2_copy_t[i]
        
        startppqpos_new = notes_2_copy_subt[2] + adjust_ppq
          endppqpos_new = notes_2_copy_subt[3] + adjust_ppq       
        reaper.MIDI_InsertNote(take, true,notes_2_copy_subt[1], startppqpos_new, endppqpos_new, 
          notes_2_copy_subt[4], notes_2_copy_subt[5], notes_2_copy_subt[6], false)      
      end  
    end        
    reaper.UpdateItemInProject(item)    
   
  end --take ~= nil  
end
if item ~= nil then reaper.UpdateItemInProject(item) end
reaper.UpdateArrange()
reaper.Undo_EndBlock(script_title, 0)
