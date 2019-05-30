-- @description Scale focused ReaEQ bands gain down
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @noindex
-- @changelog
--      #header
  
  ratio = 0.9
  
  
  -- NOT reaper NOT gfx
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  function msg(s) if s then ShowConsoleMsg(s..'\n') end end
  -----------------------------------------------------------------------------
  function MPL_ScaleReaEqBand(ratio)
    local  retval, tracknumber, itemnumber, fx = GetFocusedFX()
    if not (retval ==1 and fx >= 0) then return end
    local tr = CSurf_TrackFromID( tracknumber, false )
    local isReaEQ = TrackFX_GetEQParam( tr, fx, 0 )
    if not isReaEQ then return end
    local num_params = TrackFX_GetNumParams( tr, fx )
    ClearConsole()
    for param = 1, num_params - 2, 3 do
      local gain = TrackFX_GetParamNormalized( tr, fx, param  )
      local out_gain = gain
      if gain >0.5 then
        out_gain = gain - (gain - 0.5)*(1-ratio)
       elseif gain < 0.5 then 
        out_gain = gain + (0.5-gain)*(1-ratio)
      end
      TrackFX_SetParamNormalized( tr, fx, param, math.max(0,math.min(1, out_gain ) ))
    end
  end
  ----------------------------------------------------------------------------- 
  MPL_ScaleReaEqBand(ratio)