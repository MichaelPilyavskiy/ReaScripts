-- @description Set selected tracks MIDI input device to TouchOSC bridge
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=165672
-- @changelog
--    # VF independent



  channel = 0-- 0 all channels
  device_name = 'touchosc'
  
  
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
  
  
  
  
  
  
  function main()
    for i = 1, CountSelectedTracks(0) do
      local tr = GetSelectedTrack(0,i-1)
      SetMidiInput( tr, channel, device_name ) 
    end
  end
---------------------------------------------------------------------  
  function SetMidiInput(tr, chan, dev_name)
    if not tr then return end
    for i = 0, 64 do
      local retval, nameout = GetMIDIInputName( i, '' )
      if nameout:lower():match(dev_name:lower()) then dev_id = i end
    end
    if not dev_id then return end
    val = 4096+ chan + ( dev_id << 5  )
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECINPUT',val)
  end 
---------------------------------------------------------------------
  if VF_CheckReaperVrs(5.95,true)  then 
    Undo_BeginBlock()
    main()
    Undo_EndBlock("Set selected tracks MIDI input device", 0)  
  end