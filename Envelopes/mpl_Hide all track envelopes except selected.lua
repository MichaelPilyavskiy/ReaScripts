-- @description Hide all track envelopes except selected
-- @version 1.0
-- @author mpl
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    + init release

difference = -10

function main()
  sel_env = reaper.GetSelectedEnvelope( 0)
  env_inf = GetEnvInfo(sel_env)
  if not sel_env then return end
  for tr = 1, reaper.CountTracks(0) do
    local track = reaper.GetTrack(0,tr-1)
    if track then 
      for i = 1,  reaper.CountTrackEnvelopes( track ) do
        local env = reaper.GetTrackEnvelope( track, i-1 )
        sel_env_inf = GetEnvInfo(env)
        if sel_env_inf == env_inf then visible = true else visible = false end
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

function GetEnvInfo(env)
  inf_str = ''
  if not env then return inf_str end
  par_tr, fx_idx, par_idx = reaper.Envelope_GetParentTrack( env )
  if not par_tr then return inf_str end
  inf_str = reaper.GetTrackGUID( par_tr )
  if fx_idx >= 0 and par_idx >= 0 then 
    inf_str = inf_str..fx_idx..par_idx 
   else 
    _, env_name = reaper.GetEnvelopeName( env, '' )
    inf_str = inf_str..env_name
  end
  return inf_str
end
    
main()
