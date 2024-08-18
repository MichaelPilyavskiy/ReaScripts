-- @description Set selected track FX outputs to incremental stereo pairs
-- @version 1.01
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # VF independent

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
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
--------------------------------------------------------------------
  function main()
    local tr = GetSelectedTrack(0,0)
    if not tr then return end
    
    cntfx =  TrackFX_GetCount(tr)
    SetMediaTrackInfo_Value( tr, 'I_NCHAN',math.min(cntfx*2,64)  )
    
    for fx = 1, cntfx do
      TrackFX_SetPinMappings( tr, fx-1, 1, 0, 2^(fx-1), 0 )
      TrackFX_SetPinMappings( tr, fx-1, 1, 1, 2^(fx-1)<<1, 0 )
    end 
  end
---------------------------------------------------------------------
  if VF_CheckReaperVrs(5.95,true)then main()end