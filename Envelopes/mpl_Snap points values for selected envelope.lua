-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @description Snap points values for selected envelope
-- @changelog
--    + init

  local script_title = 'Snap points values for selected envelope'
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  function MathQ(val)
    if val - math.floor(val) < 0.5 then return math.floor(val) else return math.ceil(val) end
  end
  --------------------------------------------------------  
  function VericalSnap_sub(val, steps)
    val = val * (steps-1)
    val = MathQ(val) / (steps-1)
    return val
  end
  --------------------------------------------------------  
  function GetStepSize(env)
    local steps = 2
    local track, fx, param = Envelope_GetParentTrack( env )
    if track then 
      local retval, buf = TrackFX_GetParamName( track, fx, param, '' )
      if not retval then buf = 'Verical snap' end
      local r, stepOut, smallstepOut, largestepOut, istoggleOut = TrackFX_GetParameterStepSizes( track, fx, param )
      if r then 
        if istoggleOut then return 2,buf end
        if stepOut > 1 then return stepOut,buf end
      end  
      return steps,buf
    end
  end
  --------------------------------------------------------  
  function VericalSnap(env)
    local def, name = GetStepSize(env)
    if not def then return end
    local ret, steps = GetUserInputs(name, 1 , 'Vertical snap steps', def)
    if ret and tonumber(steps) and tonumber(steps)>1 then
      steps = math.ceil(tonumber(steps))
      for ptidx = 1, CountEnvelopePoints( env ) do
                          local retval, time, value, shape, tension, selected = GetEnvelopePoint( env, ptidx-1 )
        value = VericalSnap_sub(value, steps)
        SetEnvelopePoint( env, ptidx-1, time, value, shape, tension, selected, true )
      end
      Envelope_SortPoints( env)
    end
  end
  --------------------------------------------------------
  env = GetSelectedEnvelope( 0 )
  if env then 
    Undo_BeginBlock()
    VericalSnap(env) 
    Undo_EndBlock( script_title, -1 )
  end