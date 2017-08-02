-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Add note beetween two selected
-- @changelog
--    + init

  function add_beetw_notes()
    local me = reaper.MIDIEditor_GetActive()
    if not me then return end
    local tk =  reaper.MIDIEditor_GetTake( me )
    if not tk then return end
    local _, notecntOut =reaper.MIDI_CountEvts( tk )
    if notecntOut < 2 then return end
    local t = {}
    for i =1 , notecntOut do 
      local _, s, _, stppq, eppq, ch, p, v = reaper.MIDI_GetNote( tk, i-1 )
      if s then t[#t+1] = {stppq=stppq, eppq=eppq, ch=ch, p=p, v=v} end
    end
    if #t < 2 then return end
    local startppq = math.floor(  (t[2].stppq -t[1].stppq)/2 + t[1].stppq  )
    local end_ppq = startppq+math.floor(t[1].eppq -t[1].stppq)
    local p = math.floor(t[1].p+(t[2].p-t[1].p)/2)
    local v = math.floor(t[1].v+(t[2].v-t[1].v)/2)
    reaper.MIDI_InsertNote( tk, true, false, startppq, end_ppq, t[1].ch, p, v, false )
  end
  
  reaper.Undo_BeginBlock()
  add_beetw_notes()
  reaper.Undo_EndBlock("Add note beetween two selected", 0) 