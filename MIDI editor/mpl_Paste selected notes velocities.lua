-- @version 1.0
-- @author MPL
-- @changelog
--   + init
-- @description Paste selected notes velocities
-- @website http://forum.cockos.com/member.php?u=70694
  
function PasteVelocitiesToSelectedNotes()
    local midieditor =  reaper.MIDIEditor_GetActive()
    if not midieditor then return end
    local take =  reaper.MIDIEditor_GetTake( midieditor )
    if not take or not reaper.TakeIsMIDI(take) then return end
    local _, notecnt = reaper.MIDI_CountEvts( take )    
    str = reaper.GetExtState('mplCopyVel', 'buf')
    if str == '' then return end
    t = {}
    for num in str:gmatch('[%d]+') do t[#t+1] = tonumber(num) end    
    for i = 1, notecnt do
      retval, sel, m, s, e, c, p, v = reaper.MIDI_GetNote( take, i-1 )
      if sel == true then reaper.MIDI_SetNote( take, i-1, true, m, s, e, c, p, t[i%#t], true ) end    
    end  
    reaper.MIDI_Sort(take)     
  end  
PasteVelocitiesToSelectedNotes()