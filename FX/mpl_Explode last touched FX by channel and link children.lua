-- @description Explode last touched FX by channel and link children
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init
  
  ---------------------------------------------------
  function VF_CheckReaperVrs(rvrs, showmsg) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      if showmsg then reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0) end
      return
     else
      return true
    end
  end
  
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------  
  function main() 
    local retval, trackidx, itemidx, takeidx, fxidx, parm = GetTouchedOrFocusedFX( 0 ) 
    if not retval then return end
    local track if trackidx == -1 then track = GetMasterTrack(-1) else track = GetTrack(0-1,trackidx) end
    if itemidx ~= -1 then return end
    
    local I_NCHAN = GetMediaTrackInfo_Value( track, 'I_NCHAN' ) 
    local ret, fxname =TrackFX_GetNamedConfigParm( track, fxidx, 'fx_name' ) 
    local cntparams = TrackFX_GetNumParams( track, fxidx )
    local retval, inputPins, outputPins = reaper.TrackFX_GetIOSize( track, fxidx )
    
    -- pinmap master
    TrackFX_SetPinMappings( track, fxidx, 0, 0, 1, 0 )
    TrackFX_SetPinMappings( track, fxidx, 1, 0, 1, 0 )
    for pin = 2, inputPins do TrackFX_SetPinMappings( track, fxidx, 0, pin-1, 0, 0 ) end
    for pin = 2, outputPins do TrackFX_SetPinMappings( track, fxidx, 1, pin-1, 0, 0 ) end
    
    -- pinmap/link children
    for chan = I_NCHAN,2,-1 do
      TrackFX_CopyToTrack(track, fxidx, track, fxidx, false) 
      destID = fxidx + 1 
      local outname = fxname..' ch'..math.floor(chan)
      TrackFX_SetNamedConfigParm( track, destID, 'renamed_name', outname )
      
      TrackFX_SetPinMappings( track, destID, 0, 0, 1<<(chan-1), 0 )
      TrackFX_SetPinMappings( track, destID, 1, 0, 1<<(chan-1), 0 )
      for pin = 2, inputPins do TrackFX_SetPinMappings( track, destID, 0, pin-1, 0, 0 ) end
      for pin = 2, outputPins do TrackFX_SetPinMappings( track, destID, 1, pin-1, 0, 0 ) end
      for param = 0, cntparams-1  do
        TrackFX_SetNamedConfigParm( track, destID, 'param.'..param..'.plink.active', 1 )
        TrackFX_SetNamedConfigParm( track, destID, 'param.'..param..'.plink.effect', fxidx )
        TrackFX_SetNamedConfigParm( track, destID, 'param.'..param..'.plink.param', param )
      end
    end
    
  end
  ---------------------------------------------------  
  if VF_CheckReaperVrs(7.0) then
    Undo_BeginBlock2(-1)
    main() 
    Undo_EndBlock2(-1, 'Explode last touched FX by channel and link children', 0xFFFFFFFF)
  end