-- @description Show envelopes for last touched FX
-- @version 1.0
-- @author MPL
-- @changelog
--   + init
-- @website http://forum.cockos.com/member.php?u=70694
  
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  function Main()
    local retval, tracknumberOut, fxnumberOut =  GetLastTouchedFX()
    if not retval then return end
    local tr =  CSurf_TrackFromID( tracknumberOut, false )
    if not tr then return end
    for parameterindex = 1, TrackFX_GetNumParams( tr, fxnumberOut ) do
      local env = GetFXEnvelope( tr, fxnumberOut, parameterindex-1, false )  
      if  env then 
        local BR_env = BR_EnvAlloc( env, false )
        local active, visible, armed, inLane, laneHeight, defaultShape, _, _, _, _, faderScaling = BR_EnvGetProperties( BR_env )
        BR_EnvSetProperties( BR_env, active, true, armed, inLane, laneHeight, defaultShape, faderScaling )
        BR_EnvFree( BR_env, true )
      end
    end
  end
  Main() 