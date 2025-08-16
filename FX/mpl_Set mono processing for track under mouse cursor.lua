-- @description Set mono processing for track under mouse cursor
-- @version 1.0
-- @author MPL
-- @about Set plugins bus size to 1 channel if available, duplicate left to right channel for last FX
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  
  ---------------------------------------------------
  function VF_CheckReaperVrs(rvrs, showmsg) 
    local vrs_num =  GetAppVersion() vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then  if showmsg then reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0) end return else return true end
  end
  ---------------------------------------------------
  function VF_GetTrackUnderMouseCursor()
    local screen_x, screen_y = GetMousePosition()
    local retval, info = reaper.GetTrackFromPoint( screen_x, screen_y )
    return retval
  end
  --------------------------------------------------- 
  function main()
    local tr = VF_GetTrackUnderMouseCursor()
    if not tr then return end
    local fx_cnt = reaper.TrackFX_GetCount(tr)
    for fxnumber = 1, fx_cnt do 
      local retval, inputPins, outputPins = reaper.TrackFX_GetIOSize( tr, fxnumber-1 )
      local pins = math.max(inputPins, outputPins)
      for pin = 0, pins do
        local val = 0
        if pin ==0 then val = 1 end
        reaper.TrackFX_SetPinMappings( tr, fxnumber-1, 0, pin, val, 0 )
        reaper.TrackFX_SetPinMappings( tr, fxnumber-1, 1, pin, val, 0 )
      end
      TrackFX_SetNamedConfigParm( tr, fxnumber-1, 'channel_config', 1) 
      if fxnumber == fx_cnt then 
        -- share left to right for last fx
        reaper.TrackFX_SetPinMappings( tr, fxnumber-1, 1, 0, 3, 0 )
      end
    end 
    return true
  end
  --------------------------------------------------------------------  
  if VF_CheckReaperVrs(7.43,true) then  
    Undo_BeginBlock2( 0 )
    local ret0 = main()
    if ret0 then Undo_EndBlock2( 0, 'Set mono processing for track under mouse cursor', 0xFFFFFFFF ) end
  end 