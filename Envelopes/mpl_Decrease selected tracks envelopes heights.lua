-- @description Decrease selected tracks envelopes heights
-- @version 1.0
-- @author mpl
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    + init release

difference = -10

function main()
  for sel_tr = 1, reaper.CountSelectedTracks(0) do
    local track = reaper.GetSelectedTrack(0,sel_tr-1)
    if track then 
      for i = 1,  reaper.CountTrackEnvelopes( track ) do
        local env = reaper.GetTrackEnvelope( track, i-1 )
        local br_env = reaper.BR_EnvAlloc( env, false )
        local active, visible, armed, inLane, laneHeight, defaultShape, _, _, _, _, faderScaling = reaper.BR_EnvGetProperties( br_env )
        reaper.BR_EnvSetProperties( br_env, 
                                  active, 
                                  visible, 
                                  armed, 
                                  inLane, 
                                  laneHeight + difference, 
                                  defaultShape, 
                                  faderScaling )
        reaper.BR_EnvFree( br_env, true )
      end
    end
  end
  
end

main()
