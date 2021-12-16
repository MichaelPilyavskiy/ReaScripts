-- @description Minimize selected tracks envelopes heights
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    + internal cleanup
--    + include Master track if selected

  function SetTrackEnvelopesHeight(track, val)
    for i = 1,  reaper.CountTrackEnvelopes( track ) do
      local env = reaper.GetTrackEnvelope( track, i-1 )
      local br_env = reaper.BR_EnvAlloc( env, false )
      local active, visible, armed, inLane, laneHeight, defaultShape, _, _, _, _, faderScaling = reaper.BR_EnvGetProperties( br_env )
      reaper.BR_EnvSetProperties( br_env, 
                                active, 
                                visible, 
                                armed, 
                                inLane, 
                                val,--laneHeight, 
                                defaultShape, 
                                faderScaling )
      reaper.BR_EnvFree( br_env, true )
    end
  end
  ----------------------------------------------------
  function main(val)
    for sel_tr = 1, reaper.CountSelectedTracks(0) do
      local track = reaper.GetSelectedTrack(0,sel_tr-1)
      if track then 
        SetTrackEnvelopesHeight(track, val)
      end
    end
    if  reaper.IsTrackSelected( reaper.GetMasterTrack( 0 ) ) then SetTrackEnvelopesHeight(reaper.GetMasterTrack( 0 ), val) end 
  end
  ----------------------------------------------------
  reaper.Undo_BeginBlock2( 0 )
  main(1)
  reaper.Undo_EndBlock2( 0, 'Minimize selected tracks envelopes heights', -1 )
  