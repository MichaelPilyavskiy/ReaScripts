-- @description Move edit cursor to first note of active MIDI editor take
-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # remove SWS dependency


  
  function main()
    MIDIEditor = reaper.MIDIEditor_GetActive()
    if MIDIEditor == nil then return end
    take = reaper.MIDIEditor_GetTake(MIDIEditor)
    if take == nil then return end
    if reaper.TakeIsMIDI(take) == false then return end
    
     retval, notecnt, ccevtcnt, textsyxevtcnt = reaper.MIDI_CountEvts( take )
    if notecnt ==0 then return end
    local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote( take, 0 )
    pos = reaper.MIDI_GetProjTimeFromPPQPos(take, startppqpos)
    reaper.SetEditCurPos(pos, true, true)
  end
  
  main()