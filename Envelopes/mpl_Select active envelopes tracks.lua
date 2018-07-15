-- @description Select active envelopes tracks
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    + init release


function main()
  -- unselect
    local tr = reaper.GetTrack(0,0)
    if not tr then return end 
    reaper.SetOnlyTrackSelected( tr )
    reaper.SetTrackSelected( tr, false )
  -- loop
    for tr = 1, reaper.CountTracks(0) do
      local track = reaper.GetTrack(0,tr-1)
      if track then 
        for i = 1,  reaper.CountTrackEnvelopes( track ) do
          local env = reaper.GetTrackEnvelope( track, i-1 )
          local br_env = reaper.BR_EnvAlloc( env, false )
          local active, visible, armed, inLane, laneHeight, defaultShape, _, _, _, _, faderScaling = reaper.BR_EnvGetProperties( br_env )        
          reaper.SetTrackSelected( track, active )
          reaper.BR_EnvFree( br_env, true )
        end
      end
    end
end

reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock('Select active envelopes tracks',-1)