-- @description Strum selected notes
-- @version 1.0
-- @author MPL
-- @about Shift selected notes positions by user defined PPQ amount
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

  function main() 
    local tickoffs = reaper.GetExtState( 'MPL_STRUMSELNOTES', 'tickoffs' )
    if tickoffs == '' then tickoffs = 10 else tickoffs = tonumber(tickoffs) or 10 end
    local retval, retvals_csv = reaper.GetUserInputs( 'Strum selected notes', 1, 'PPQ offset', tickoffs )
    if not retval then return end
    tickoffs = tonumber(retvals_csv)
    if not tickoffs then return end
    SetExtState('MPL_STRUMSELNOTES', 'tickoffs', tickoffs, true )
    
    local ME = reaper.MIDIEditor_GetActive()
    if not ME then return end
    local take = reaper.MIDIEditor_GetTake(ME)
    if not take or not TakeIsMIDI(take) then return end
    
    -- collect chord data
      local notes = {}
      local first_note_pos 
      local _, notecnt = reaper.MIDI_CountEvts( take )
      
      for i = 1, notecnt do
        local _, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote( take, i-1 )
        if i==1 then first_note_pos = startppqpos end
        if selected then --and math.abs(startppqpos - first_note_pos ) < noteshift*2 then
          notes[pitch] = {
                              muted=muted,
                              startppqpos=startppqpos,
                              endppqpos=endppqpos,
                              chan=chan,
                              vel=vel}
              
        end
      end
      
    -- delete chord notes
      for i = notecnt,1,-1 do
        local _, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote( take, i-1 ) 
        if selected then  MIDI_DeleteNote( take, i-1 ) end
      end
      
    -- re add 
      local offs = 0
      for pitch in spairs(notes, function(t,a,b) if tickoffs < 0 then return b > a else return b < a end end ) do
        MIDI_InsertNote( take, true, notes[pitch].muted, first_note_pos+offs, notes[pitch].endppqpos+offs,notes[pitch].chan, pitch, notes[pitch].vel, true )
        offs = offs + math.abs(tickoffs)
      end
    MIDI_Sort( take ) 
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.14) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then 
    Undo_BeginBlock()
    main() 
    Undo_EndBlock('mpl Strum selected notes', 0xFFFFFFFF) 
  end end