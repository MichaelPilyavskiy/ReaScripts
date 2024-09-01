-- @description Set selected tracks audio input device to Guit
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=165672
-- @changelog
--    # VF independent


  device_name = 'Guit'
  is_stereo = false
  
  
  
  
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
  ---------------------------------------------------
  function main()
    for i = 1, CountSelectedTracks(0) do
      local tr = GetSelectedTrack(0,i-1)
      SetAudioInput( tr, is_stereo, device_name )
    end
  end
  ---------------------------------------------------------------------
  function SetAudioInput(tr, is_stereo, dev_name)
    if is_stereo==true then is_stereo = 1024 else is_stereo = 0 end
    --local tr = reaper.GetSelectedTrack(0,0)
    if not tr then return end
    for i = 1,  reaper.GetNumAudioInputs() do
      nameout =  reaper.GetInputChannelName( i-1 )
      if nameout:lower():match(dev_name:lower()) then dev_id = i-1 end
    end
    if not dev_id then return end
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECINPUT',is_stereo + dev_id)
  end
---------------------------------------------------------------------
  if VF_CheckReaperVrs(5.95,true) then 
    Undo_BeginBlock()
    main()
    Undo_EndBlock("Set selected tracks audio input device", 0)  
  end