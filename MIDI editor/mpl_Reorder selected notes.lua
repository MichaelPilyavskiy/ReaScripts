-- @description Reorder selected notes
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  function ReorderNotes(percent)   
    local ME = MIDIEditor_GetActive()
    if not ME then return end
    local take = MIDIEditor_GetTake(ME)
    if not take or not TakeIsMIDI(take) then return end
    local last_t
    for i = 1, ({MIDI_CountEvts( take )})[2] do
      local _, selected, muted, startppqpos, endppqpos, chan, pitch, vel = MIDI_GetNote( take, i-1 )
      if selected and i > 1 then  
        local len = endppqpos- startppqpos
        startppqpos = last_t.endppqpos + 1 
        endppqpos = startppqpos + len
        MIDI_SetNote( take, i-1, true, muted, startppqpos,endppqpos, chan, pitch, vel, true )
      end
      last_t={startppqpos=startppqpos, endppqpos=endppqpos}
    end
    MIDI_Sort( take )
  end
  
  Undo_BeginBlock()
  ReorderNotes()
  Undo_EndBlock('Reorder notes', 0)