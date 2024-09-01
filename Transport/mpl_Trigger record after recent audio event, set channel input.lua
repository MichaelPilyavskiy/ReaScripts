-- @description Trigger record after recent audio event, set channel input
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
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
  ---------------------------------------------------
  threshold_dB = -60
  function Run() 
    if not channels then channels = GetNumAudioInputs() end
    local tr = GetSelectedTrack(0,0)
    if tr then 
      for input_id = 1, channels do
        local activity_dB = GetInputActivityLevel(input_id-1)
        if activity_dB> threshold_dB then
          local activity_dB2 = GetInputActivityLevel(input_id)
          SetMediaTrackInfo_Value( tr, 'I_RECARM', 1 )
          SetMediaTrackInfo_Value( tr, 'I_RECINPUT', input_id-1 )
          if activity_dB2 and activity_dB2> threshold_dB then SetMediaTrackInfo_Value( tr, 'I_RECINPUT', (input_id-1)|1024 ) end -- stereo if following channel also above threshold
          CSurf_OnRecord()
          return 
        end
      end
    end 
    defer(Run)
  end
   
  ----------------------------------------------------------------------
  if VF_CheckReaperVrs(6.74,true) then Run() end