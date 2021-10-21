-- @description Minimize all tracks envelopes heights
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # obey master track


function main()
  for sel_tr = 0, reaper.CountTracks(0) do
    local track = reaper.GetTrack(0,sel_tr-1)
    if sel_tr == 0 then track = reaper.GetMasterTrack(0) end
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
                                  1,--laneHeight, 
                                  defaultShape, 
                                  faderScaling )
        reaper.BR_EnvFree( br_env, true )
      end
    end
  end
  
end

main()