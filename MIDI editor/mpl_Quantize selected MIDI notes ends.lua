-- @version 1.10
-- @author MPL
-- @description Quantize selected MIDI notes ends
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    # refactoring for using PPQ-ProjTime-Beats convertion
--    + Undo History point

  function main()   
    local ME = reaper.MIDIEditor_GetActive()
    if not ME then return end
    local take = reaper.MIDIEditor_GetTake(ME)
    if not take or not reaper.TakeIsMIDI(take) then return end
    local ME_grid, swing = reaper.MIDI_GetGrid( take )
    local _, notecnt = reaper.MIDI_CountEvts( take )
    for i = 1, notecnt do
      local _, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote( take, i-1 )
      if selected then
        local proj_time = reaper.MIDI_GetProjTimeFromPPQPos( take, endppqpos )
        local _, _, _, fullbeatsOutOptional = reaper.TimeMap2_timeToBeats( proj, proj_time )
        local q_mult = fullbeatsOutOptional / ME_grid
        local int, div = math.modf(q_mult)
        if div >= swing then outval = int + 1 else outval = int end
        local sw_check = outval % 2
        local outval = outval * ME_grid 
        if sw_check == 1 then outval = outval +ME_grid*swing/2 end        
        local out_projTime = reaper.TimeMap2_beatsToTime( 0, outval)
        local endppqpos = reaper.MIDI_GetPPQPosFromProjTime( take, out_projTime )
        reaper.MIDI_SetNote( take, i-1, true, muted, startppqpos, endppqpos, chan, pitch, vel, true )
      end
    end
    reaper.MIDI_Sort( take )
  end
  
  reaper.Undo_BeginBlock()
  main()
  reaper.Undo_EndBlock('Quantize selected MIDI notes ends', 0)
