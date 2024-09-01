-- @description Check if multichannel item has mono source, convert to mono item if need 
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # VF independent
--    # change name

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
    for i = 1, CountSelectedMediaItems(0) do
      local item =  reaper.GetSelectedMediaItem( 0, i-1)
      local take = GetActiveTake(item)
      if take then 
        local ismono = MonoCheck(item, take)
        if ismono then SetMediaItemTakeInfo_Value( take, 'I_CHANMODE' , 3) reaper.UpdateItemInProject( item ) end
      end
    end
  end
  ----------------------------------------------------------------------
  function MonoCheck(item, take)
    local accessor = CreateTakeAudioAccessor( take )
    local it_len = reaper.GetMediaItemInfo_Value( item, 'D_LENGTH' )
    local src  = reaper.GetMediaItemTake_Source( take )
    local SR =  reaper.GetMediaSourceSampleRate( src )
    local test_chan = reaper.GetMediaSourceNumChannels( src )
    
    local diff_com = 0
    
    local test_dist = it_len / 5
    local threshold_lin = 0.0001 -- -80db
    --threshold_dB = WDL_VAL2DB(threshold_lin)
    
    --local threshold_dB = -80
    for pos = 0, it_len, test_dist do 
      local samplebuffer = new_array(test_chan);
      GetAudioAccessorSamples( accessor, SR, test_chan, pos, 1, samplebuffer )
      for i = 2, test_chan do
        local diff =math.abs(samplebuffer[i]-samplebuffer[1])
        if diff > threshold_lin then diff_com = diff_com + math.abs(diff ) end
      end
      samplebuffer.clear()
    end
    DestroyAudioAccessor( accessor )   
    if diff_com == 0 then return true end
  end   
  ----------------------------------------------------------------------
  if VF_CheckReaperVrs(5.9,true) then 
    Undo_BeginBlock2( 0 )
    main()
    Undo_EndBlock( 'Check is multichannel item mono sourced, convert to mono if need', 0xFFFFFFFF )
  end  
  
  
  