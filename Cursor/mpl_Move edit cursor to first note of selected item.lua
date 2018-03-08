-- @description Move edit cursor to first note of selected item
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # ReaPack header, name 

  
  function main()
    item = reaper.GetSelectedMediaItem(0,0)
    if item == nil then return end
    take = reaper.GetActiveTake(item)
    if take == nil then return end
    if reaper.TakeIsMIDI(take) == false then return end
    fngtake = reaper.FNG_AllocMidiTake(take)
    note = reaper.FNG_GetMidiNote(fngtake, 0)
    note_pos = reaper.FNG_GetMidiNoteIntProperty(note, 'POSITION')
    pos = reaper.MIDI_GetProjTimeFromPPQPos(take, note_pos)
    reaper.SetEditCurPos(pos, true, true)
  end
  
  main()