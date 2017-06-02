-- @version 1.0
-- @author MPL
-- @changelog
--   + init
-- @description Quantize item and note postions to project grid
-- @website http://forum.cockos.com/member.php?u=70694


-- there is almost same action by Fingers(SWS), but it seems broken in some situations

  function main(it)
    if not it then return end
    local it_pos =  reaper.GetMediaItemInfo_Value( it, 'D_POSITION'  )
    pos_shift = reaper.BR_GetClosestGridDivision( it_pos ) - it_pos
    local take = reaper.GetActiveTake(it)
    if not take then return end
    if reaper.TakeIsMIDI(take ) then
      local fng_tk = reaper.FNG_AllocMidiTake( take )
      for i = 1,  reaper.FNG_CountMidiNotes( fng_tk ) do
        nt = reaper.FNG_GetMidiNote( fng_tk, i-1 )
        reaper.FNG_SetMidiNoteIntProperty( nt, 'POSITION',  math.floor(reaper.MIDI_GetPPQPosFromProjTime( take, reaper.BR_GetClosestGridDivision( reaper.MIDI_GetProjTimeFromPPQPos( take, reaper.FNG_GetMidiNoteIntProperty( nt, 'POSITION') ) )-pos_shift )))
      end
      reaper.FNG_FreeMidiTake( fng_tk )
    end
    reaper.SetMediaItemInfo_Value( it, 'D_POSITION', it_pos + pos_shift  )
    reaper.UpdateItemInProject( it )
  end


  reaper.Undo_BeginBlock()
  for i =1, reaper.CountSelectedMediaItems(0) do 
    main(reaper.GetSelectedMediaItem(0,i-1)) 
  end
  reaper.Undo_EndBlock("Quantize item and note postions to project grid", 0) 