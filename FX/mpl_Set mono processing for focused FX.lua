-- @description Set mono processing for focused FX
-- @version 1.0
-- @author MPL
-- @about Set plugins bus size to 1 channel if available, share left to right channel
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + fork from mpl_Set mono processing for selected tracks

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  
  ---------------------------------------------------
  function VF_CheckReaperVrs(rvrs, showmsg) 
    local vrs_num =  GetAppVersion() vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then  if showmsg then reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0) end return else return true end
  end
  ---------------------------------------------------
  
  function main()
    local retval, trackidx, itemidx, takeidx, fxnumber, parm = reaper.GetTouchedOrFocusedFX( 1 )
    if not retval then return end
    
    local track = GetTrack(-1,trackidx)
    if trackIdxOut == -1 then track = reaper.GetMasterTrack() end
    
    local APIname = 'TrackFX_'
    local ptr = track
    if itemidx>= 0 then 
      APIname = 'TakeFX_'
      item = reaper.GetMediaItem(-1,itemidx)
      ptr = GetTake( item, takeidx )
    end
    
    if _G[APIname..'GetOffline']( ptr, fxnumber ) == false and _G[APIname..'GetEnabled']( ptr, fxnumber ) == true then
      local retval, inputPins, outputPins = _G[APIname..'GetIOSize']( ptr, fxnumber )
      local pins = math.max(inputPins, outputPins)
      for pin = 0, pins do
        local val = 0
        if pin ==0 then val = 1 end
        _G[APIname..'SetPinMappings']( ptr, fxnumber, 0, pin, val, 0 )
      end 
      _G[APIname..'SetPinMappings']( ptr, fxnumber, 1, 0, 1, 0 )
      _G[APIname..'SetPinMappings']( ptr, fxnumber, 1, 1, 1, 0 )
      _G[APIname..'SetNamedConfigParm']( ptr, fxnumber, 'channel_config', 1) 
      
      inputPins2, outputPins2 = _G[APIname..'GetIOSize']( ptr, fxnumber )
      
    end
        
  end
  --------------------------------------------------------------------  
  if VF_CheckReaperVrs(7.43,true) then  
    Undo_BeginBlock2( 0 )
    local ret0 = main()
    if ret0 then Undo_EndBlock2( 0, 'Set mono processing for focused FX', 0xFFFFFFFF ) end
  end 