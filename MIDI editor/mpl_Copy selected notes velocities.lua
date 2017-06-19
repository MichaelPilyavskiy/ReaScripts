-- @version 1.0
-- @author MPL
-- @changelog
--   + init
-- @description Copy selected notes velocities
-- @website http://forum.cockos.com/member.php?u=70694
  
  function CopySelectedNotesVelocities()
    local midieditor =  reaper.MIDIEditor_GetActive()
    if not midieditor then return end
    local take =  reaper.MIDIEditor_GetTake( midieditor )
    if not take or not reaper.TakeIsMIDI(take) then return end
    local _, notecnt = reaper.MIDI_CountEvts( take )    
    local t = {}
    local str = ""
    for i = 1, notecnt do
      _, selectedOut, _, _, _, _, _, vel = reaper.MIDI_GetNote( take, i-1 )
      if selectedOut == true then str = str..vel..',' end    
    end    
    reaper.SetExtState('mplCopyVel', 'buf', str, false)    
  end
  
CopySelectedNotesVelocities()