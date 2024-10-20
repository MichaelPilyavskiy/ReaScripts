-- @description Strum selected notes
-- @version 1.02
-- @author MPL
-- @about Shift selected notes positions by user defined PPQ amount
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # VF independent

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------
  function VF_CheckReaperVrs(rvrs, showmsg) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      if showmsg then reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0) end
      return
     else
      return true
    end
  end
  ---------------------------------------------------
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
  ---------------------------------------------------
  function spairs(t, order) --http://stackoverflow.com/questions/15706270/sort-a-table-in-lua
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end
    if order then table.sort(keys, function(a,b) return order(t, a, b) end)  else  table.sort(keys) end
    local i = 0
    return function()
              i = i + 1
              if keys[i] then return keys[i], t[keys[i]] end
           end
  end
  --------------------------------------------------------------------  
  if VF_CheckReaperVrs(5.975,true) then 
    Undo_BeginBlock()
    main() 
    Undo_EndBlock('mpl Strum selected notes', 0xFFFFFFFF) 
  end 