-- @version 1.01
-- @description Snap selected notes to scale
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    + init
  
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  function GetPattern(root, scale)
    local pat,ex = {}
    for num in scale:gmatch('%d') do 
      pat[#pat+1] = num+root>0 
      if num+root>0 then ex = true end -- check if at least one note in pattern
    end
    if ex then return pat end
  end
  -----------------------------------------
  function Check_Scale(pitch, pat)
    local note = pitch % 12 +1
    local q_note
    for i = 1, 12 do
      if pat[i] then q_note = i end
      if pat[i] and i == note then return pitch end
      if not pat[i] and i == note then return pitch - (i-q_note) end
    end
    return pitch
  end
  -----------------------------------------
  function main()   
    local ME = MIDIEditor_GetActive()
    if not ME then return end
    local take = MIDIEditor_GetTake(ME)
    if not take or not TakeIsMIDI(take) then return end
    if MIDIEditor_GetSetting_int( ME, 'scale_enabled' )==0 then return end
    local root = MIDIEditor_GetSetting_int( ME, 'scale_root' )
    local scale= ({MIDIEditor_GetSetting_str( ME, 'scale', '' )})[2]
    local pat  = GetPattern(root, scale)
    if not pat then return end
    local _, notecnt = reaper.MIDI_CountEvts( take )
    for i = 1, notecnt do
      local _, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote( take, i-1 )
      --new_pitch = pitch % 12
      new_pitch = Check_Scale(pitch, pat)
      if selected then reaper.MIDI_SetNote( take, i-1, true, muted, startppqpos, endppqpos, chan, new_pitch, vel, true ) end
    end
    reaper.MIDI_Sort( take )
  end
  -----------------------------------------  
  reaper.Undo_BeginBlock()
  main()
  reaper.Undo_EndBlock('Snap selected notes to scale', 0)