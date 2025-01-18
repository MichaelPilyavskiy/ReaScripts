-- @description Check if multichannel item has mono source, convert to mono item if need 
-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # improve math a bit
--    # upper thresholds
--    # offset audio accessor position a bit, for some reason it doesn`t give correct results
--    + Pan mono take if source is panned mono

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
    for i = 1, CountMediaItems(0) do
      local item =  GetMediaItem( 0, i-1)
      if IsMediaItemSelected(item) then
        local take = GetActiveTake(item) 
        if take then 
          local ismono,real_ratiodiff_RMS = MonoCheck(item, take)
          if ismono==true then  
            local swap = -1
            SetMediaItemTakeInfo_Value( take, 'I_CHANMODE' , 3) 
            if real_ratiodiff_RMS then -- 1/2=50%L 1 = C 2= 50R
              if real_ratiodiff_RMS > 1 then 
                real_ratiodiff_RMS = 1/real_ratiodiff_RMS 
                swap = 1
              end
              R =  real_ratiodiff_RMS
              L =  1-real_ratiodiff_RMS
              SetMediaItemTakeInfo_Value( take, 'D_PAN' , swap*(L-0.5)*2) 
            end
            UpdateItemInProject( item ) 
          end
        end
      end
    end
  end
    ----------------------------------------------------------------------
  function WDL_DB2VAL(x) return math.exp((x)*0.11512925464970228420089957273422) end  --https://github.com/majek/wdl/blob/master/WDL/db2val.h  
  ----------------------------------------------------------------------
  function MonoCheck(item, take)
    local accessor = CreateTakeAudioAccessor( take )
    local it_len = reaper.GetMediaItemInfo_Value( item, 'D_LENGTH' )
    local src  = reaper.GetMediaItemTake_Source( take )
    local SR =  reaper.GetMediaSourceSampleRate( src )
    local test_chan = reaper.GetMediaSourceNumChannels( src ) 
    local diff_com = 0 
    local test_dist = it_len / 10
    local threshold_lin = WDL_DB2VAL(-80)--0.001 -- -80db 
    local  real_ratiodiff_t = {}
    local  real_ratiodiff_RMS = 0
    --local threshold_dB = -80
    for pos = 0.01, it_len-test_dist, test_dist do 
      local samplebuffer = new_array(test_chan);
      GetAudioAccessorSamples( accessor, SR, test_chan, pos, 1, samplebuffer )
      for i = 2, test_chan do
        local diff =math.abs(samplebuffer[i]-samplebuffer[1])
        if samplebuffer[1] ~= 0 then 
          local ratio  = samplebuffer[i]/samplebuffer[1] 
          real_ratiodiff_t[#real_ratiodiff_t+1] =ratio
          real_ratiodiff_RMS=real_ratiodiff_RMS+ratio
        end
        if diff > threshold_lin then diff_com = diff_com + 1 end
      end
      samplebuffer.clear()
    end
    DestroyAudioAccessor( accessor ) 
    
    -- no difference
    if diff_com == 0 then return true end
    
    -- closer value as channels ratio
    local real_ratiodiff_RMS = real_ratiodiff_RMS  /   #real_ratiodiff_t
    local is_pannedmono = true
    for i = 1, #real_ratiodiff_t do
      if math.abs(real_ratiodiff_t[i] - real_ratiodiff_RMS) > 0.01 then return end
    end
    if is_pannedmono == true then return true,real_ratiodiff_RMS end
  end   
  ----------------------------------------------------------------------
  if VF_CheckReaperVrs(5.9,true) then 
    Undo_BeginBlock2( 0 )
    main()
    Undo_EndBlock( 'Check is multichannel item mono sourced, convert to mono if need', 0xFFFFFFFF )
  end  
  
  
  