-- @description Hide all track envelopes except envelope under mouse cursor
-- @version 1.0
-- @author mpl
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    + init release


function msg(s) reaper.ShowConsoleMsg(s..'\n') end

function main()
  reaper.BR_GetMouseCursorContext()
  env_MC = reaper.BR_GetMouseCursorContext_Envelope()
  if not env_MC then return end
  for tr = 1, reaper.CountTracks(0) do
    local track = reaper.GetTrack(0,tr-1)
    if track then 
      for i = 1,  reaper.CountTrackEnvelopes( track ) do
        local env = reaper.GetTrackEnvelope( track, i-1 )
        if env == env_MC then visible = true else visible = false end
        local br_env = reaper.BR_EnvAlloc( env, false )
        local active, _, armed, inLane, laneHeight, defaultShape, _, _, _, _, faderScaling = reaper.BR_EnvGetProperties( br_env )
        reaper.BR_EnvSetProperties( br_env, 
                                  active, 
                                  visible, 
                                  armed, 
                                  inLane, 
                                  laneHeight, 
                                  defaultShape, 
                                  faderScaling )
        reaper.BR_EnvFree( br_env, true )
      end
    end
  end  
end

main()
